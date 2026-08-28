--!nonstrict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local EnvironmentMotionController = {}

local player = Players.LocalPlayer
local activeTweens = {}

local function startSway(part: BasePart, degrees: number, duration: number)
	local base = part.Orientation
	local target = Vector3.new(base.X + degrees, base.Y, base.Z - degrees * 0.45)
	local tween = TweenService:Create(
		part,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Orientation = target }
	)
	tween:Play()
	table.insert(activeTweens, tween)
end

local function addSubtleFoliageMotion(arena: Instance)
	local grassFolder = arena:FindFirstChild("GrassClumps")
	if grassFolder then
		local index = 0
		for _, item in ipairs(grassFolder:GetDescendants()) do
			if item:IsA("BasePart") and not item:GetAttribute("FallsWhenTouched") then
				index += 1
				if index % 7 == 0 then
					startSway(item, math.random(2, 5), math.random(22, 45) / 10)
				end
			end
		end
	end

	local clutter = arena:FindFirstChild("Clutter")
	if clutter then
		local index = 0
		for _, item in ipairs(clutter:GetDescendants()) do
			if item:IsA("BasePart") and string.find(item.Name, "FallenLeaf") then
				index += 1
				if index % 9 == 0 then
					startSway(item, math.random(1, 3), math.random(30, 55) / 10)
				end
			end
		end
	end
end

local function makeSplash(position: Vector3)
	local splash = Instance.new("Part")
	splash.Name = "HoseSplash"
	splash.Shape = Enum.PartType.Cylinder
	splash.Size = Vector3.new(0.08, 2.2, 2.2)
	splash.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	splash.Anchored = true
	splash.CanCollide = false
	splash.CanTouch = false
	splash.CanQuery = false
	splash.Material = Enum.Material.Neon
	splash.Color = Color3.fromRGB(145, 220, 255)
	splash.Transparency = 0.35
	splash.Parent = Workspace

	local tween = TweenService:Create(
		splash,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(0.08, 5.5, 5.5), Transparency = 1 }
	)
	tween:Play()
	tween.Completed:Connect(function()
		if splash.Parent then
			splash:Destroy()
		end
	end)
end

local function dripLoop(arena: Instance)
	local clutter = arena:FindFirstChild("Clutter")
	local hose = clutter and clutter:FindFirstChild("GardenHose")
	local nozzle = hose and hose:FindFirstChild("HoseNozzle")
	if not nozzle or not nozzle:IsA("BasePart") then
		return
	end

	task.spawn(function()
		while arena.Parent do
			task.wait(math.random(22, 42) / 10)

			local drop = Instance.new("Part")
			drop.Name = "HoseDrop"
			drop.Shape = Enum.PartType.Ball
			drop.Size = Vector3.new(1.25, 1.25, 1.25)
			drop.Position = nozzle.Position + Vector3.new(2, -1.5, 3)
			drop.Anchored = true
			drop.CanCollide = false
			drop.CanTouch = false
			drop.CanQuery = false
			drop.Material = Enum.Material.Glass
			drop.Color = Color3.fromRGB(130, 205, 255)
			drop.Transparency = 0.18
			drop.Parent = Workspace

			local landing = Vector3.new(-18, 1.05, -68)
			local tween = TweenService:Create(
				drop,
				TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = landing, Size = Vector3.new(1.6, 1.6, 1.6) }
			)
			tween:Play()
			tween.Completed:Connect(function()
				if drop.Parent then
					drop:Destroy()
				end
				makeSplash(landing)
			end)
		end
	end)
end

local function getCharacterMotionParts()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end
	return root, humanoid
end

local function applyGrassFlick(payload)
	payload = payload or {}
	local velocity = payload.velocity
	if typeof(velocity) ~= "Vector3" then
		return
	end

	local root, humanoid = getCharacterMotionParts()
	if not root or not humanoid then
		return
	end

	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	root.AssemblyLinearVelocity = velocity
	root:ApplyImpulse(velocity * root.AssemblyMass * 0.55)

	-- Reinforce on the owning client after one physics beat so normal movement input
	-- cannot erase the launch immediately.
	task.delay(0.07, function()
		if root and root.Parent and player:GetAttribute("InRound") == true then
			root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(velocity, 0.72)
		end
	end)
end

local function applyWindGust(payload)
	payload = payload or {}
	local velocity = payload.velocity
	if typeof(velocity) ~= "Vector3" then
		return
	end

	local root, humanoid = getCharacterMotionParts()
	if not root or not humanoid or player:GetAttribute("InRound") ~= true then
		return
	end

	local duration = math.clamp(tonumber(payload.duration) or 0.85, 0.25, 1.5)
	local gust = Vector3.new(velocity.X, 0, velocity.Z) * 1.35
	local startedAt = os.clock()

	-- Give the gust a clear initial shove on the client that owns the character.
	-- This makes entering the wind immediately readable instead of relying on a
	-- series of tiny velocity nudges that normal movement can erase.
	root:ApplyImpulse(gust * root.AssemblyMass * 0.22)

	-- Sustain a strong crosswind while preserving vertical motion and enough of
	-- the player's own horizontal velocity that they can still fight the gust.
	task.spawn(function()
		while root.Parent and humanoid.Health > 0 and player:GetAttribute("InRound") == true and os.clock() - startedAt < duration do
			local current = root.AssemblyLinearVelocity
			local target = Vector3.new(gust.X, current.Y, gust.Z)
			root.AssemblyLinearVelocity = current:Lerp(target, 0.58)
			root:ApplyImpulse(gust * root.AssemblyMass * 0.045)
			task.wait(0.05)
		end
	end)
end

local function applyRakeHit(payload)
	payload = payload or {}
	local velocity = payload.velocity
	if typeof(velocity) ~= "Vector3" then
		return
	end

	local root, humanoid = getCharacterMotionParts()
	if not root or not humanoid or player:GetAttribute("InRound") ~= true then
		return
	end

	-- A rake hit should feel like the moving head actually caught the bug. Give a
	-- short knock in the sweep direction without turning it into a giant launch.
	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	local current = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(
		current.X + velocity.X * 0.72,
		math.max(current.Y, velocity.Y),
		current.Z + velocity.Z * 0.72
	)
	root:ApplyImpulse(velocity * root.AssemblyMass * 0.32)
end

function EnvironmentMotionController.Init(remotes)
	local arena = Workspace:FindFirstChild("BuildABugArena") or Workspace:WaitForChild("BuildABugArena", 10)
	if arena then
		addSubtleFoliageMotion(arena)
		dripLoop(arena)
	end

	if remotes and remotes.RoundStateChanged then
		remotes.RoundStateChanged.OnClientEvent:Connect(function(state, payload)
			if state == "GrassFlick" then
				applyGrassFlick(payload)
			elseif state == "WindGustPush" then
				applyWindGust(payload)
			elseif state == "RakeHit" then
				applyRakeHit(payload)
			end
		end)
	end
end

return EnvironmentMotionController
