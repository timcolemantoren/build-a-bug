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

local function spawnPickup(pickupType: string, position: Vector3)
	local pickupsFolder = ArenaService.GetPickupsFolder()

	local pickup = Instance.new("Part")
	pickup.Name = pickupType == "DNA" and "DnaPickup" or "Crumb"
	pickup.Shape = Enum.PartType.Ball
	pickup.Size = pickupType == "DNA" and Vector3.new(1.15, 1.15, 1.15) or Vector3.new(1.25, 1.25, 1.25)
	pickup.Position = position
	pickup.Anchored = true
	pickup.CanCollide = false
	pickup.Color = pickupType == "DNA" and Color3.fromRGB(105, 175, 255) or Color3.fromRGB(230, 205, 145)
	pickup.Material = pickupType == "DNA" and Enum.Material.Neon or Enum.Material.SmoothPlastic
	pickup:SetAttribute("Collected", false)
	pickup:SetAttribute("PickupType", pickupType)
	pickup.Parent = pickupsFolder

	pickup.Touched:Connect(function(hit)
		if pickup:GetAttribute("Collected") then
			return
		end

		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		pickup:SetAttribute("Collected", true)
		collectPickup(pickup, player)
		pickup:Destroy()
	end)
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
