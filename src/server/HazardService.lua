--!nonstrict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local HazardConfig = require(BuildABugShared.Config.HazardConfig)
local BugArchetypes = require(BuildABugShared.Config.BugArchetypes)

local HazardService = {}
local remotes = nil
local PlayerDataService = nil
local hazardGeneration = 0

local ROLLING_BALL_TRAVEL_TIME = 1.75

local hazardIds = {}
for hazardId, _ in pairs(HazardConfig) do
	table.insert(hazardIds, hazardId)
end

local HAZARD_VISUALS = {
	ShoeStomp = {
		warningColor = Color3.fromRGB(255, 72, 50),
		impactColor = Color3.fromRGB(255, 24, 18),
		instruction = "MOVE OUT OF THE STOMP ZONE!",
	},
	SprinklerBurst = {
		warningColor = Color3.fromRGB(70, 190, 255),
		impactColor = Color3.fromRGB(120, 235, 255),
		instruction = "GET OUT OF THE WATER LANE!",
	},
	BirdShadow = {
		warningColor = Color3.fromRGB(65, 65, 82),
		impactColor = Color3.fromRGB(28, 28, 38),
		instruction = "RUN OUT OF THE SHADOW!",
	},
	RollingBall = {
		warningColor = Color3.fromRGB(255, 178, 55),
		impactColor = Color3.fromRGB(255, 122, 38),
		instruction = "GET OUT OF THE BALL'S PATH!",
	},
}

local function getHazardsFolder(): Folder
	local arena = Workspace:FindFirstChild("BuildABugArena")
	if not arena then
		arena = Instance.new("Folder")
		arena.Name = "BuildABugArena"
		arena.Parent = Workspace
	end

	local hazards = arena:FindFirstChild("Hazards")
	if hazards and hazards:IsA("Folder") then
		return hazards
	end

	local folder = Instance.new("Folder")
	folder.Name = "Hazards"
	folder.Parent = arena
	return folder
end

local function clampArenaPosition(position: Vector3): Vector3
	return Vector3.new(
		math.clamp(position.X, -182, 182),
		0.75,
		math.clamp(position.Z, -168, 152)
	)
end

local function getActivePlayers()
	local active = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("InRound") == true then
			local character = player.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if rootPart and humanoid and humanoid.Health > 0 then
				table.insert(active, player)
			end
		end
	end
	return active
end

local function getRandomActivePlayer(): Player?
	local active = getActivePlayers()
	if #active == 0 then
		return nil
	end
	return active[math.random(1, #active)]
end

local function getPlayerPosition(player: Player): Vector3?
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	return rootPart and rootPart.Position or nil
end

local function getRandomArenaCenter(): Vector3
	return Vector3.new(math.random(-175, 175), 0.75, math.random(-165, 150))
end

local function makeZone(hazardId: string, requestedCenter: Vector3?)
	local center = requestedCenter and clampArenaPosition(requestedCenter) or getRandomArenaCenter()

	if hazardId == "SprinklerBurst" then
		return {
			center = center,
			size = Vector3.new(24, 0.25, 110),
		}
	elseif hazardId == "ShoeStomp" then
		return {
			center = center,
			size = Vector3.new(34, 0.25, 38),
		}
	elseif hazardId == "RollingBall" then
		return {
			center = center,
			size = Vector3.new(120, 0.25, 22),
			rollDirection = math.random() < 0.5 and -1 or 1,
		}
	else
		return {
			center = center,
			size = Vector3.new(54, 0.25, 40),
		}
	end
end

local function addWorldLabel(part: BasePart, hazard, visual)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HazardLabel"
	billboard.Size = UDim2.fromOffset(310, 72)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.8, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 120
	billboard.LightInfluence = 0
	billboard.Adornee = part
	billboard.Parent = part

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 38)
	title.BackgroundTransparency = 1
	title.Text = string.upper(hazard.displayName or hazard.id)
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextStrokeTransparency = 0.12
	title.TextStrokeColor3 = Color3.fromRGB(25, 25, 25)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 24
	title.Parent = billboard

	local instruction = Instance.new("TextLabel")
	instruction.Position = UDim2.fromOffset(0, 36)
	instruction.Size = UDim2.new(1, 0, 0, 30)
	instruction.BackgroundTransparency = 1
	instruction.Text = visual.instruction or "MOVE!"
	instruction.TextColor3 = Color3.fromRGB(255, 238, 180)
	instruction.TextStrokeTransparency = 0.18
	instruction.TextStrokeColor3 = Color3.fromRGB(25, 25, 25)
	instruction.Font = Enum.Font.GothamBold
	instruction.TextSize = 14
	instruction.Parent = billboard
end

local function createWarningPart(hazard, zone)
	local visual = HAZARD_VISUALS[hazard.id] or HAZARD_VISUALS.ShoeStomp
	local part = Instance.new("Part")
	part.Name = hazard.id .. "Warning"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Size = zone.size
	part.Position = zone.center
	part.Transparency = hazard.id == "BirdShadow" and 0.50 or 0.30
	part.Color = visual.warningColor
	part.Material = hazard.id == "BirdShadow" and Enum.Material.SmoothPlastic or Enum.Material.Neon
	part.Parent = getHazardsFolder()
	addWorldLabel(part, hazard, visual)

	if hazard.id == "BirdShadow" then
		local driftTween = TweenService:Create(
			part,
			TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Position = zone.center + Vector3.new(8, 0, 0) }
		)
		driftTween:Play()
	elseif hazard.id == "RollingBall" then
		local pulseTween = TweenService:Create(
			part,
			TweenInfo.new(0.32, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Transparency = 0.52 }
		)
		pulseTween:Play()
	end

	return part
end

local function createShoeVisual(zone, warningSeconds: number)
	local shoe = Instance.new("Part")
	shoe.Name = "IncomingShoe"
	shoe.Anchored = true
	shoe.CanCollide = false
	shoe.CanTouch = false
	shoe.CanQuery = false
	shoe.Size = Vector3.new(zone.size.X * 0.92, 10, zone.size.Z * 0.92)
	shoe.Position = zone.center + Vector3.new(0, 52, 0)
	shoe.Color = Color3.fromRGB(48, 52, 58)
	shoe.Material = Enum.Material.SmoothPlastic
	shoe.Transparency = 0.12
	shoe.Parent = getHazardsFolder()

	local sole = Instance.new("Part")
	sole.Name = "Sole"
	sole.Anchored = true
	sole.CanCollide = false
	sole.CanTouch = false
	sole.CanQuery = false
	sole.Size = Vector3.new(zone.size.X, 2.5, zone.size.Z)
	sole.Position = shoe.Position - Vector3.new(0, 6, 0)
	sole.Color = Color3.fromRGB(22, 24, 27)
	sole.Material = Enum.Material.Rubber
	sole.Parent = getHazardsFolder()

	local shoeTween = TweenService:Create(
		shoe,
		TweenInfo.new(math.max(0.25, warningSeconds), Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = zone.center + Vector3.new(0, 7.5, 0) }
	)
	local soleTween = TweenService:Create(
		sole,
		TweenInfo.new(math.max(0.25, warningSeconds), Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = zone.center + Vector3.new(0, 1.4, 0) }
	)
	shoeTween:Play()
	soleTween:Play()

	return { shoe, sole }
end

local function createSprinklerImpact(zone)
	local water = Instance.new("Part")
	water.Name = "SprinklerWaterBlast"
	water.Anchored = true
	water.CanCollide = false
	water.CanTouch = false
	water.CanQuery = false
	water.Size = Vector3.new(zone.size.X, 9, zone.size.Z)
	water.Position = zone.center + Vector3.new(0, 4.5, 0)
	water.Color = Color3.fromRGB(110, 220, 255)
	water.Material = Enum.Material.Glass
	water.Transparency = 0.28
	water.Parent = getHazardsFolder()

	TweenService:Create(water, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 0.72,
		Size = Vector3.new(zone.size.X * 1.12, 12, zone.size.Z),
	}):Play()
	Debris:AddItem(water, 0.42)
end

local function createBirdImpact(zone)
	local shadow = Instance.new("Part")
	shadow.Name = "BirdShadowSweep"
	shadow.Anchored = true
	shadow.CanCollide = false
	shadow.CanTouch = false
	shadow.CanQuery = false
	shadow.Size = Vector3.new(zone.size.X * 1.15, 0.18, zone.size.Z * 1.15)
	shadow.Position = zone.center + Vector3.new(-28, 0.12, 0)
	shadow.Color = Color3.fromRGB(20, 20, 28)
	shadow.Material = Enum.Material.SmoothPlastic
	shadow.Transparency = 0.30
	shadow.Parent = getHazardsFolder()

	TweenService:Create(shadow, TweenInfo.new(0.38, Enum.EasingStyle.Linear), {
		Position = zone.center + Vector3.new(28, 0.12, 0),
		Transparency = 0.55,
	}):Play()
	Debris:AddItem(shadow, 0.45)
end

local function isInsideZone(rootPart: BasePart, zone): boolean
	local relative = rootPart.Position - zone.center
	local half = zone.size / 2
	return math.abs(relative.X) <= half.X and math.abs(relative.Z) <= half.Z
end

local function getDamageForPlayer(player: Player, baseDamage: number): number
	if not PlayerDataService then
		return baseDamage
	end

	local data = PlayerDataService.GetData(player)
	local bug = data and BugArchetypes[data.selectedBug]
	if not bug then
		return baseDamage
	end

	local reduction = bug.damageReduction or 0
	local shellBlockUntil = player:GetAttribute("ShellBlockUntil") or 0
	if shellBlockUntil > os.clock() then
		reduction = math.max(reduction, 0.75)
	end

	return math.max(1, math.floor(baseDamage * (1 - reduction)))
end

local function damagePlayersInZone(zone, damage: number)
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("InRound") == true then
			local character = player.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if rootPart and humanoid and humanoid.Health > 0 and isInsideZone(rootPart, zone) then
				humanoid:TakeDamage(getDamageForPlayer(player, damage))
			end
		end
	end
end

local function createRollingBallImpact(zone, damage: number, myGeneration: number)
	local direction = zone.rollDirection or 1
	local halfTravel = zone.size.X / 2 + 12
	local startPosition = zone.center + Vector3.new(-direction * halfTravel, 7.8, 0)
	local endPosition = zone.center + Vector3.new(direction * halfTravel, 7.8, 0)

	local ball = Instance.new("Part")
	ball.Name = "RollingToyBall"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(15, 15, 15)
	ball.CFrame = CFrame.new(startPosition)
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanTouch = false
	ball.CanQuery = false
	ball.Color = Color3.fromRGB(226, 66, 68)
	ball.Material = Enum.Material.SmoothPlastic
	ball.Parent = getHazardsFolder()

	-- A contrasting patch makes the rotation readable instead of looking like a
	-- colored sphere sliding across the ground.
	local patch = Instance.new("Part")
	patch.Name = "BallPatch"
	patch.Shape = Enum.PartType.Ball
	patch.Size = Vector3.new(4.2, 4.2, 4.2)
	patch.CFrame = ball.CFrame * CFrame.new(0, 0, -6.2)
	patch.Anchored = false
	patch.Massless = true
	patch.CanCollide = false
	patch.CanTouch = false
	patch.CanQuery = false
	patch.Color = Color3.fromRGB(255, 220, 64)
	patch.Material = Enum.Material.SmoothPlastic
	patch.Parent = ball

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = ball
	weld.Part1 = patch
	weld.Parent = patch

	local travelTime = ROLLING_BALL_TRAVEL_TIME
	local endCFrame = CFrame.new(endPosition) * CFrame.Angles(0, 0, math.rad(900 * direction))
	local tween = TweenService:Create(ball, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
		CFrame = endCFrame,
	})
	local hitPlayers = {}
	tween:Play()

	task.spawn(function()
		local startedAt = os.clock()
		while ball.Parent and myGeneration == hazardGeneration and os.clock() - startedAt <= travelTime + 0.08 do
			for _, player in ipairs(Players:GetPlayers()) do
				if player:GetAttribute("InRound") == true and not hitPlayers[player.UserId] then
					local character = player.Character
					local rootPart = character and character:FindFirstChild("HumanoidRootPart")
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					if rootPart and humanoid and humanoid.Health > 0 then
						local flatDelta = Vector3.new(rootPart.Position.X - ball.Position.X, 0, rootPart.Position.Z - ball.Position.Z)
						if flatDelta.Magnitude <= 8.6 then
							hitPlayers[player.UserId] = true
							humanoid:TakeDamage(getDamageForPlayer(player, damage))
						end
					end
				end
			end
			task.wait(0.045)
		end
	end)

	Debris:AddItem(ball, travelTime + 0.15)
end

local function announceHazard(hazard, stage: string, zone, warningSeconds: number)
	if not remotes or not remotes.HazardWarning then
		return
	end

	local visual = HAZARD_VISUALS[hazard.id] or HAZARD_VISUALS.ShoeStomp
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("InRound") == true then
			remotes.HazardWarning:FireClient(player, {
				id = hazard.id,
				displayName = hazard.displayName,
				stage = stage,
				warningSeconds = warningSeconds,
				damage = hazard.damage,
				description = hazard.description,
				instruction = visual.instruction,
				center = zone.center,
				size = zone.size,
			})
		end
	end
end

function HazardService.Init(remoteEvents, playerDataService)
	remotes = remoteEvents
	PlayerDataService = playerDataService
end

function HazardService.GetRandomHazardId(): string?
	if #hazardIds == 0 then
		return nil
	end
	return hazardIds[math.random(1, #hazardIds)]
end

function HazardService.ClearHazards()
	hazardGeneration += 1
	local folder = getHazardsFolder()
	folder:ClearAllChildren()
end

function HazardService.WarnHazard(hazardId: string, options)
	local hazard = HazardConfig[hazardId]
	if not hazard then
		warn("Unknown hazard:", hazardId)
		return
	end

	options = options or {}
	local zone = makeZone(hazardId, options.center)
	local warningPart = createWarningPart(hazard, zone)
	local myGeneration = hazardGeneration
	local warningSeconds = (hazard.warningSeconds or 3) * (options.warningScale or 1)
	local extraVisuals = {}

	if hazardId == "ShoeStomp" then
		extraVisuals = createShoeVisual(zone, warningSeconds)
	end

	announceHazard(hazard, "Warning", zone, warningSeconds)

	task.delay(warningSeconds, function()
		if myGeneration ~= hazardGeneration then
			return
		end

		local visual = HAZARD_VISUALS[hazard.id] or HAZARD_VISUALS.ShoeStomp
		local damage = math.floor((hazard.damage or 25) * (options.damageScale or 1))

		if hazardId == "RollingBall" then
			if warningPart and warningPart.Parent then
				warningPart.Color = visual.impactColor
				TweenService:Create(warningPart, TweenInfo.new(0.15), { Transparency = 1 }):Play()
				Debris:AddItem(warningPart, 0.18)
			end
			announceHazard(hazard, "Impact", zone, warningSeconds)
			createRollingBallImpact(zone, damage, myGeneration)
			return
		end

		if warningPart and warningPart.Parent then
			warningPart.Transparency = 0.05
			warningPart.Color = visual.impactColor
		end

		if hazardId == "SprinklerBurst" then
			createSprinklerImpact(zone)
		elseif hazardId == "BirdShadow" then
			createBirdImpact(zone)
		end

		announceHazard(hazard, "Impact", zone, warningSeconds)
		damagePlayersInZone(zone, damage)

		for _, part in ipairs(extraVisuals) do
			if part and part.Parent then
				TweenService:Create(part, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = part.Position + Vector3.new(0, 28, 0),
					Transparency = 0.55,
				}):Play()
				Debris:AddItem(part, 0.34)
			end
		end

		task.delay(0.55, function()
			if warningPart and warningPart.Parent then
				warningPart:Destroy()
			end
		end)
	end)
end

function HazardService.WarnHazardNearPlayer(hazardId: string?, player: Player?, radius: number?, options)
	local target = player or getRandomActivePlayer()
	if not target then
		return
	end

	local position = getPlayerPosition(target)
	if not position then
		return
	end

	local offsetRadius = radius or 7
	local angle = math.random() * math.pi * 2
	local distance = math.random() * offsetRadius
	local center = position + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
	local chosenHazardId = hazardId or HazardService.GetRandomHazardId()
	if chosenHazardId then
		local merged = options or {}
		merged.center = center
		HazardService.WarnHazard(chosenHazardId, merged)
	end
end

function HazardService.WarnRandomHazardNearActivePlayer(radius: number?, options)
	HazardService.WarnHazardNearPlayer(nil, nil, radius, options)
end

return HazardService
