--!nonstrict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local InteractiveFoliageService = {}

local connectedParts = {}
local grassBlades = {}
local nextFlickAtByUserId = {}
local random = Random.new()

local FLICK_SEARCH_RADIUS = 42
local FLICK_MIN_INTERVAL = 16
local FLICK_MAX_INTERVAL = 24
local FLICK_RETRY_SECONDS = 3
local FLICK_DAMAGE = 4
local FLICK_HORIZONTAL_SPEED = 62
local FLICK_UP_SPEED = 30

local function getArena(): Folder?
	return Workspace:FindFirstChild("BuildABugArena")
end

local function isPlayerPart(hit: BasePart): boolean
	local character = hit.Parent
	return character and Players:GetPlayerFromCharacter(character) ~= nil
end

local function fallBlade(blade: BasePart, hit: BasePart)
	if blade:GetAttribute("Fallen") or blade:GetAttribute("Flicking") then
		return
	end

	blade:SetAttribute("Fallen", true)
	blade.CanCollide = false

	local originalCFrame = blade.CFrame
	local height = blade.Size.Y
	local direction = blade.Position - hit.Position
	if direction.Magnitude < 0.1 then
		direction = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
	end
	direction = Vector3.new(direction.X, 0, direction.Z).Unit

	local yaw = math.atan2(direction.X, direction.Z)
	local fallenCFrame = CFrame.new(blade.Position - Vector3.new(0, height * 0.42, 0))
		* CFrame.Angles(0, yaw, 0)
		* CFrame.Angles(math.rad(82), 0, 0)

	TweenService:Create(
		blade,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = fallenCFrame }
	):Play()

	local recoverSeconds = blade:GetAttribute("FallRecoverSeconds") or 10
	task.delay(recoverSeconds, function()
		if blade and blade.Parent then
			TweenService:Create(
				blade,
				TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = originalCFrame }
			):Play()
			task.delay(0.8, function()
				if blade and blade.Parent then
					blade.CanCollide = true
					blade:SetAttribute("Fallen", false)
				end
			end)
		end
	end)
end

local function getHorizontalDirection(fromPosition: Vector3, toPosition: Vector3): Vector3
	local offset = Vector3.new(toPosition.X - fromPosition.X, 0, toPosition.Z - fromPosition.Z)
	if offset.Magnitude < 0.1 then
		local angle = random:NextNumber(0, math.pi * 2)
		return Vector3.new(math.cos(angle), 0, math.sin(angle))
	end
	return offset.Unit
end

local function getPivotedCFrame(originalCFrame: CFrame, height: number, direction: Vector3, angleDegrees: number): CFrame
	local localDirection = originalCFrame:VectorToObjectSpace(direction)
	local axis = Vector3.new(-localDirection.Z, 0, localDirection.X)
	if axis.Magnitude < 0.05 then
		axis = Vector3.xAxis
	else
		axis = axis.Unit
	end

	local rotation = CFrame.fromAxisAngle(axis, math.rad(angleDegrees))
	local baseFrame = originalCFrame * CFrame.new(0, -height / 2, 0)
	return baseFrame * rotation * CFrame.new(0, height / 2, 0)
end

local function playFlickSound(blade: BasePart)
	local sound = Instance.new("Sound")
	sound.Name = "GrassFlick"
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.62
	sound.PlaybackSpeed = 1.7
	sound.RollOffMaxDistance = 55
	sound.Parent = blade
	sound:Play()
	Debris:AddItem(sound, 2)
end

local function resetBlade(blade: BasePart, originalCFrame: CFrame, originalColor: Color3)
	if not blade or not blade.Parent then
		return
	end

	local settleTween = TweenService:Create(
		blade,
		TweenInfo.new(0.50, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
		{ CFrame = originalCFrame, Color = originalColor }
	)
	settleTween:Play()
	settleTween.Completed:Connect(function()
		if blade and blade.Parent then
			blade:SetAttribute("Flicking", false)
		end
	end)
end

local function flickBladeAtPlayer(blade: BasePart, player: Player): boolean
	if not blade.Parent or blade:GetAttribute("Fallen") or blade:GetAttribute("Flicking") then
		return false
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return false
	end

	blade:SetAttribute("Flicking", true)
	local originalCFrame = blade.CFrame
	local originalColor = blade.Color
	local height = blade.Size.Y
	local towardPlayer = getHorizontalDirection(blade.Position, root.Position)
	local awayFromPlayer = -towardPlayer
	local warningColor = originalColor:Lerp(Color3.fromRGB(190, 235, 92), 0.60)
	local coilCFrame = getPivotedCFrame(originalCFrame, height, awayFromPlayer, 24)

	local coilTween = TweenService:Create(
		blade,
		TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = coilCFrame, Color = warningColor }
	)
	coilTween:Play()
	coilTween.Completed:Wait()

	if not blade.Parent or player:GetAttribute("InRound") ~= true then
		resetBlade(blade, originalCFrame, originalColor)
		return false
	end

	local currentCharacter = player.Character
	local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
	local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
	if not currentRoot or not currentRoot:IsA("BasePart") or not currentHumanoid or currentHumanoid.Health <= 0 then
		resetBlade(blade, originalCFrame, originalColor)
		return false
	end

	local snapDirection = getHorizontalDirection(blade.Position, currentRoot.Position)
	local snapCFrame = getPivotedCFrame(originalCFrame, height, snapDirection, 38)
	TweenService:Create(
		blade,
		TweenInfo.new(0.10, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ CFrame = snapCFrame, Color = originalColor }
	):Play()
	playFlickSound(blade)

	-- Make the flick a real launch rather than a subtle physics nudge. The second
	-- application prevents the Humanoid controller from immediately swallowing it.
	local launchVelocity = snapDirection * FLICK_HORIZONTAL_SPEED + Vector3.new(0, FLICK_UP_SPEED, 0)
	currentHumanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	currentRoot.AssemblyLinearVelocity = launchVelocity
	task.delay(0.06, function()
		if currentRoot and currentRoot.Parent and player:GetAttribute("InRound") == true then
			currentRoot.AssemblyLinearVelocity = currentRoot.AssemblyLinearVelocity:Lerp(launchVelocity, 0.65)
		end
	end)
	currentHumanoid:TakeDamage(FLICK_DAMAGE)

	task.delay(0.16, function()
		resetBlade(blade, originalCFrame, originalColor)
	end)
	return true
end

local function findNearbyFlickBlade(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end

	local candidates = {}
	for _, blade in ipairs(grassBlades) do
		if blade and blade.Parent and not blade:GetAttribute("Fallen") and not blade:GetAttribute("Flicking") and blade.Size.Y >= 8 then
			local bladeFlat = Vector3.new(blade.Position.X, 0, blade.Position.Z)
			local rootFlat = Vector3.new(root.Position.X, 0, root.Position.Z)
			local distance = (bladeFlat - rootFlat).Magnitude
			if distance <= FLICK_SEARCH_RADIUS then
				table.insert(candidates, { blade = blade, distance = distance })
			end
		end
	end

	if #candidates == 0 then
		return nil
	end

	table.sort(candidates, function(a, b)
		return a.distance < b.distance
	end)
	local sampleCount = math.min(#candidates, 6)
	return candidates[random:NextInteger(1, sampleCount)].blade
end

local function scheduleNextFlick(player: Player, retrySoon: boolean?)
	if retrySoon then
		nextFlickAtByUserId[player.UserId] = os.clock() + FLICK_RETRY_SECONDS
	else
		nextFlickAtByUserId[player.UserId] = os.clock() + random:NextNumber(FLICK_MIN_INTERVAL, FLICK_MAX_INTERVAL)
	end
end

local function startFlickLoop()
	task.spawn(function()
		while true do
			local now = os.clock()
			for _, player in ipairs(Players:GetPlayers()) do
				if player:GetAttribute("InRound") == true then
					local nextAt = nextFlickAtByUserId[player.UserId]
					if not nextAt then
						scheduleNextFlick(player)
					elseif now >= nextAt then
						local blade = findNearbyFlickBlade(player)
						if blade then
							task.spawn(function()
								local success = flickBladeAtPlayer(blade, player)
								scheduleNextFlick(player, not success)
							end)
						else
							scheduleNextFlick(player, true)
						end
					end
				else
					nextFlickAtByUserId[player.UserId] = nil
				end
			end
			task.wait(0.75)
		end
	end)
end

local function connectBlade(blade: Instance)
	if not blade:IsA("BasePart") then
		return
	end

	if not table.find(grassBlades, blade) then
		table.insert(grassBlades, blade)
	end

	if connectedParts[blade] then
		return
	end

	if not blade:GetAttribute("FallsWhenTouched") then
		return
	end

	connectedParts[blade] = true
	blade.Touched:Connect(function(hit)
		if hit and hit:IsA("BasePart") and isPlayerPart(hit) then
			fallBlade(blade, hit)
		end
	end)
end

local function connectArenaGrass()
	local arena = getArena()
	local grassFolder = arena and arena:FindFirstChild("GrassClumps")
	if not grassFolder then
		return
	end

	grassBlades = {}
	for _, child in ipairs(grassFolder:GetChildren()) do
		connectBlade(child)
	end
	grassFolder.ChildAdded:Connect(connectBlade)
end

function InteractiveFoliageService.Init()
	connectArenaGrass()
	startFlickLoop()

	Players.PlayerRemoving:Connect(function(player)
		nextFlickAtByUserId[player.UserId] = nil
	end)

	Workspace.ChildAdded:Connect(function(child)
		if child.Name == "BuildABugArena" then
			task.wait(0.25)
			connectArenaGrass()
		end
	end)
end

return InteractiveFoliageService
