--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local HazardConfig = require(BuildABugShared.Config.HazardConfig)
local BugArchetypes = require(BuildABugShared.Config.BugArchetypes)

local HazardService = {}
local remotes = nil
local PlayerDataService = nil
local hazardGeneration = 0

local hazardIds = {}
for hazardId, _ in pairs(HazardConfig) do
	table.insert(hazardIds, hazardId)
end

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
	else
		return {
			center = center,
			size = Vector3.new(54, 0.25, 40),
		}
	end
end

local function createWarningPart(hazard, zone)
	local part = Instance.new("Part")
	part.Name = hazard.id .. "Warning"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Size = zone.size
	part.Position = zone.center
	part.Transparency = 0.38
	part.Color = Color3.fromRGB(255, 80, 55)
	part.Material = Enum.Material.Neon
	part.Parent = getHazardsFolder()
	return part
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

local function announceHazard(hazard)
	if not remotes or not remotes.HazardWarning then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("InRound") == true then
			remotes.HazardWarning:FireClient(player, {
				id = hazard.id,
				displayName = hazard.displayName,
				warningSeconds = hazard.warningSeconds,
				damage = hazard.damage,
				description = hazard.description,
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
	local center = options.center
	local zone = makeZone(hazardId, center)
	local warningPart = createWarningPart(hazard, zone)
	local myGeneration = hazardGeneration

	announceHazard(hazard)

	task.delay((hazard.warningSeconds or 3) * (options.warningScale or 1), function()
		if myGeneration ~= hazardGeneration then
			return
		end

		if warningPart and warningPart.Parent then
			warningPart.Transparency = 0.08
			warningPart.Color = Color3.fromRGB(255, 0, 0)
		end

		local damage = math.floor((hazard.damage or 25) * (options.damageScale or 1))
		damagePlayersInZone(zone, damage)

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
