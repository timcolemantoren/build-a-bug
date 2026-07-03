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

local function spawnCrumb(position: Vector3)
	local crumbsFolder = ArenaService.GetCrumbsFolder()

	local crumb = Instance.new("Part")
	crumb.Name = "Crumb"
	crumb.Shape = Enum.PartType.Ball
	crumb.Size = Vector3.new(1.3, 1.3, 1.3)
	crumb.Position = position
	crumb.Anchored = true
	crumb.CanCollide = false
	crumb.Color = Color3.fromRGB(230, 205, 145)
	crumb.Material = Enum.Material.SmoothPlastic
	crumb:SetAttribute("Collected", false)
	crumb.Parent = crumbsFolder

	crumb.Touched:Connect(function(hit)
		if crumb:GetAttribute("Collected") then
			return
		end

		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		crumb:SetAttribute("Collected", true)
		RewardService.AwardCrumb(player, 1)
		crumb:Destroy()
	end)
end

local function spawnCrumbWave()
	for _ = 1, RoundConfig.crumbsPerSpawn do
		spawnCrumb(ArenaService.GetRandomCrumbPosition())
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

local function runCrumbLoop()
	while isRoundActive do
		spawnCrumbWave()
		task.wait(RoundConfig.crumbSpawnIntervalSeconds)
	end
end

function RoundService.StartRound()
	if isRoundActive then
		return
	end

	isRoundActive = true
	roundStartedAt = os.clock()

	setRoundState("Started", {
		durationSeconds = RoundConfig.roundDurationSeconds,
		startedAt = roundStartedAt,
	})

	task.spawn(runCrumbLoop)
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

	remotes.StartRoundRequest.OnServerEvent:Connect(function(_player: Player)
		RoundService.StartRound()
	end)

	-- For fast Studio testing, start the first round shortly after the server boots.
	task.delay(8, function()
		if #Players:GetPlayers() >= RoundConfig.minimumPlayers then
			RoundService.StartRound()
		end
	end)
end

return RoundService
