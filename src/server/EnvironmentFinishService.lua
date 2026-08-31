--!nonstrict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local EnvironmentFinishService = {}

local rescueCooldown = {}
local RESCUE_Y = -10

local function resizeMushroom(model: Model, index: number)
	local stem = model:FindFirstChild("MushroomStem" .. index)
	local cap = model:FindFirstChild("MushroomCap" .. index)
	if not stem or not stem:IsA("BasePart") or not cap or not cap:IsA("BasePart") then
		return
	end

	-- The previous backyard pass fixed the palette but made the mushrooms read like
	-- matchsticks. Keep the earthy materials, then broaden the cap and thicken the
	-- stem so the silhouette reads as mushroom immediately from bug height.
	local baseY = 0.55
	local sizeVariation = 1 + ((index % 4) - 1.5) * 0.055
	local stemHeight = stem.Size.X * (1.16 * sizeVariation)
	local stemDiameter = math.max(1.55, stem.Size.Y * 1.48 * sizeVariation)
	local capWidth = cap.Size.X * 1.48 * sizeVariation
	local capDepth = cap.Size.Z * 1.48 * sizeVariation
	local capHeight = cap.Size.Y * 1.28

	local stemRotation = stem.CFrame.Rotation
	stem.Size = Vector3.new(stemHeight, stemDiameter, stemDiameter)
	stem.CFrame = CFrame.new(stem.Position.X, baseY + stemHeight / 2, stem.Position.Z) * stemRotation

	local capRotation = cap.CFrame.Rotation
	local capPosition = Vector3.new(cap.Position.X, baseY + stemHeight + capHeight * 0.18, cap.Position.Z)
	cap.Size = Vector3.new(capWidth, capHeight, capDepth)
	cap.CFrame = CFrame.new(capPosition) * capRotation

	local underside = model:FindFirstChild("MushroomUnderside" .. index)
	if underside and underside:IsA("BasePart") then
		underside.Size = Vector3.new(capWidth * 0.73, 0.38, capDepth * 0.73)
		underside.CFrame = CFrame.new(capPosition.X, capPosition.Y - capHeight * 0.34, capPosition.Z) * capRotation
	end

	local mark = model:FindFirstChild("MushroomCapMark" .. index)
	if mark and mark:IsA("BasePart") then
		mark.Size = Vector3.new(capWidth * 0.21, 0.18, capDepth * 0.21)
		mark.CFrame = CFrame.new(
			capPosition.X + capWidth * 0.07,
			capPosition.Y + capHeight * 0.43,
			capPosition.Z - capDepth * 0.05
		) * capRotation
	end
end

local function polishMushroomScale(arena: Instance)
	local clutter = arena:FindFirstChild("Clutter")
	if not clutter then
		return
	end

	for index = 1, 24 do
		local model = clutter:FindFirstChild("Mushroom" .. index)
		if model and model:IsA("Model") then
			resizeMushroom(model, index)
		end
	end
end

local function getPlayerFromHit(hit: Instance): Player?
	local current = hit
	while current and current ~= Workspace do
		if current:IsA("Model") then
			local player = Players:GetPlayerFromCharacter(current)
			if player then
				return player
			end
		end
		current = current.Parent
	end
	return nil
end

local function rescuePlayer(player: Player)
	local now = os.clock()
	if rescueCooldown[player.UserId] and now - rescueCooldown[player.UserId] < 1.5 then
		return
	end
	rescueCooldown[player.UserId] = now

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return
	end

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	local inRound = player:GetAttribute("InRound") == true
	local safeZ = inRound and 105 or 145
	local laneOffset = ((player.UserId % 7) - 3) * 2.2
	character:PivotTo(CFrame.new(laneOffset, 6, safeZ))
end

local function createRescuePlane(arena: Instance)
	local old = arena:FindFirstChild("OutOfBoundsRescue")
	if old then
		old:Destroy()
	end

	local plane = Instance.new("Part")
	plane.Name = "OutOfBoundsRescue"
	plane.Size = Vector3.new(470, 1, 470)
	plane.Position = Vector3.new(0, RESCUE_Y, 0)
	plane.Anchored = true
	plane.Transparency = 1
	plane.CanCollide = false
	plane.CanTouch = true
	plane.CanQuery = false
	plane.CastShadow = false
	plane.Parent = arena

	plane.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if player then
			rescuePlayer(player)
		end
	end)

	-- Touched is normally enough, but this tiny watchdog makes the safety net work
	-- even if Roblox ever skips a touch while a character is moving extremely fast.
	task.spawn(function()
		while arena.Parent do
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") and root.Position.Y < RESCUE_Y - 3 then
					rescuePlayer(player)
				end
			end
			task.wait(0.75)
		end
	end)
end

function EnvironmentFinishService.Init()
	local arena = Workspace:FindFirstChild("BuildABugArena") or Workspace:WaitForChild("BuildABugArena", 10)
	if not arena then
		warn("[Build a Bug] EnvironmentFinishService could not find arena")
		return
	end

	polishMushroomScale(arena)
	createRescuePlane(arena)

	Players.PlayerRemoving:Connect(function(player)
		rescueCooldown[player.UserId] = nil
	end)
end

return EnvironmentFinishService
