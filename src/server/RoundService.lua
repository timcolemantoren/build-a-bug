--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local RoundConfig = require(BuildABugShared.Config.RoundConfig)

local RoundService = {}
local remotes = nil
local PlayerDataService = nil
local RewardService = nil
local HazardService = nil
local ArenaService = nil

local isRoundActive = false
local roundStartedAt = 0

local function setRoundState(state: string, payload)
	if remotes and remotes.RoundStateChanged then
		remotes.RoundStateChanged:FireAllClients(state, payload or {})
	end
end

local function teleportPlayersToNest()
	local spawnPosition = ArenaService.GetSpawnPosition()
	for index, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local offset = Vector3.new((index - 1) * 3, 0, 0)
			rootPart.CFrame = CFrame.new(spawnPosition + offset)
		end
	end
end

local function clearPickups()
	local pickupsFolder = ArenaService.GetPickupsFolder()
	pickupsFolder:ClearAllChildren()
end

local function collectPickup(pickup: BasePart, player: Player)
	if not isRoundActive then
		return
	end

	local pickupType = pickup:GetAttribute("PickupType")
	if pickupType == "DNA" then
		RewardService.AwardDnaPickup(player, RoundConfig.dnaPickupReward)
	else
		RewardService.AwardCrumb(player, 1)
	end
end

local function wirePickupHitbox(hitbox: BasePart, destroyTarget: Instance)
	hitbox.Touched:Connect(function(hit)
		if hitbox:GetAttribute("Collected") then
			return
		end

		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		hitbox:SetAttribute("Collected", true)
		collectPickup(hitbox, player)
		destroyTarget:Destroy()
	end)
end

local function createCrumbPickup(position: Vector3)
	local pickupsFolder = ArenaService.GetPickupsFolder()
	local crumb = Instance.new("Part")
	crumb.Name = "Crumb"
	crumb.Size = Vector3.new(math.random(9, 16) / 10, math.random(5, 10) / 10, math.random(8, 14) / 10)
	crumb.Position = position
	crumb.Orientation = Vector3.new(math.random(0, 35), math.random(0, 180), math.random(0, 35))
	crumb.Anchored = true
	crumb.CanCollide = false
	crumb.Color = Color3.fromRGB(210 + math.random(0, 35), 165 + math.random(0, 35), 95 + math.random(0, 25))
	crumb.Material = Enum.Material.SmoothPlastic
	crumb:SetAttribute("Collected", false)
	crumb:SetAttribute("PickupType", "Crumb")
	crumb.Parent = pickupsFolder

	local crust = Instance.new("Part")
	crust.Name = "CrustEdge"
	crust.Size = Vector3.new(crumb.Size.X * 0.7, 0.18, crumb.Size.Z * 0.5)
	crust.CFrame = crumb.CFrame * CFrame.new(0, crumb.Size.Y / 2 + 0.05, 0)
	crust.Anchored = true
	crust.CanCollide = false
	crust.Color = Color3.fromRGB(145, 90, 42)
	crust.Material = Enum.Material.SmoothPlastic
	crust.Parent = crumb

	wirePickupHitbox(crumb, crumb)
end

local function createDnaPickup(position: Vector3)
	local pickupsFolder = ArenaService.GetPickupsFolder()
	local model = Instance.new("Model")
	model.Name = "DnaPickup"
	model.Parent = pickupsFolder

	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Shape = Enum.PartType.Ball
	hitbox.Size = Vector3.new(5, 5, 5)
	hitbox.Position = position
	hitbox.Transparency = 1
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox:SetAttribute("Collected", false)
	hitbox:SetAttribute("PickupType", "DNA")
	hitbox.Parent = model
	model.PrimaryPart = hitbox

	local strands = 7
	for i = 1, strands do
		local t = (i - 1) / (strands - 1)
		local y = -2.4 + (t * 4.8)
		local angle = t * math.pi * 2
		local offsetA = Vector3.new(math.cos(angle) * 1.1, y, math.sin(angle) * 1.1)
		local offsetB = -offsetA + Vector3.new(0, y * 2, 0)

		local orbA = Instance.new("Part")
		orbA.Name = "HelixNodeA"
		orbA.Shape = Enum.PartType.Ball
		orbA.Size = Vector3.new(0.6, 0.6, 0.6)
		orbA.Position = position + offsetA
		orbA.Anchored = true
		orbA.CanCollide = false
		orbA.Color = Color3.fromRGB(60, 220, 255)
		orbA.Material = Enum.Material.Neon
		orbA.Parent = model

		local orbB = Instance.new("Part")
		orbB.Name = "HelixNodeB"
		orbB.Shape = Enum.PartType.Ball
		orbB.Size = Vector3.new(0.6, 0.6, 0.6)
		orbB.Position = position + Vector3.new(-offsetA.X, y, -offsetA.Z)
		orbB.Anchored = true
		orbB.CanCollide = false
		orbB.Color = Color3.fromRGB(120, 150, 255)
		orbB.Material = Enum.Material.Neon
		orbB.Parent = model

		local rung = Instance.new("Part")
		rung.Name = "HelixRung"
		rung.Size = Vector3.new(2.2, 0.12, 0.12)
		rung.Position = position + Vector3.new(0, y, 0)
		rung.CFrame = CFrame.new(rung.Position) * CFrame.Angles(0, -angle, 0)
		rung.Anchored = true
		rung.CanCollide = false
		rung.Color = Color3.fromRGB(165, 235, 255)
		rung.Material = Enum.Material.Neon
		rung.Parent = model
	end

	wirePickupHitbox(hitbox, model)
end

local function spawnPickup(pickupType: string, position: Vector3)
	if pickupType == "DNA" then
		createDnaPickup(position)
	else
		createCrumbPickup(position)
	end
end

local function spawnPickupWave()
	for _ = 1, RoundConfig.crumbsPerSpawn do
		spawnPickup("Crumb", ArenaService.GetRandomGroundPickupPosition())
	end

	for _ = 1, RoundConfig.dnaPickupsPerSpawn do
		local useAir = math.random() < 0.6
		local position = useAir and ArenaService.GetRandomAirPickupPosition() or ArenaService.GetRandomGroundPickupPosition()
		spawnPickup("DNA", position)
	end
end

local function runHazardLoop()
	while isRoundActive do
		task.wait(18)
		if not isRoundActive then
			break
		end

		local hazardId = HazardService.GetRandomHazardId()
		if hazardId then
			HazardService.WarnHazard(hazardId)
		end
	end
end

local function runPickupLoop()
	while isRoundActive do
		spawnPickupWave()
		task.wait(RoundConfig.pickupSpawnIntervalSeconds or RoundConfig.crumbSpawnIntervalSeconds)
	end
end

function RoundService.StartRound()
	if isRoundActive then
		return
	end

	clearPickups()
	teleportPlayersToNest()

	isRoundActive = true
	roundStartedAt = os.clock()

	setRoundState("Started", {
		durationSeconds = RoundConfig.roundDurationSeconds,
		startedAt = roundStartedAt,
	})

	task.spawn(runPickupLoop)
	task.spawn(runHazardLoop)

	task.delay(RoundConfig.roundDurationSeconds, function()
		if isRoundActive then
			RoundService.EndRound()
		end
	end)
end

function RoundService.EndRound()
	if not isRoundActive then
		return
	end

	local survivedSeconds = math.floor(os.clock() - roundStartedAt)
	isRoundActive = false

	for _, player in ipairs(Players:GetPlayers()) do
		RewardService.AwardRoundComplete(player, survivedSeconds)
	end

	clearPickups()

	setRoundState("Ended", {
		survivedSeconds = survivedSeconds,
	})
end

function RoundService.Init(remoteEvents, playerDataService, rewardService, hazardService, arenaService)
	remotes = remoteEvents
	PlayerDataService = playerDataService
	RewardService = rewardService
	HazardService = hazardService
	ArenaService = arenaService

	clearPickups()
	setRoundState("Waiting", {})

	remotes.StartRoundRequest.OnServerEvent:Connect(function(_player: Player)
		RoundService.StartRound()
	end)
end

return RoundService
