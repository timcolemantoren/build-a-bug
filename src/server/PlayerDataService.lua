--!nonstrict

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local BugArchetypes = require(BuildABugShared.Config.BugArchetypes)

local DATASTORE_NAME = "BuildABug_PlayerData_v1"
local store = DataStoreService:GetDataStore(DATASTORE_NAME)

local PlayerDataService = {}
local playerDataByUserId = {}
local remotes = nil

local function makeDefaultData()
	return {
		version = 1,
		selectedBug = "Ant",
		currency = {
			dna = 0,
			crumbs = 0,
		},
		unlockedBugs = {
			Ant = true,
			Beetle = true,
			Grasshopper = true,
		},
		unlockedCosmetics = {},
		savedBuilds = {
			Slot1 = {
				base = "Ant",
				color = "Ruby",
				pattern = "None",
				eyes = "Default",
				shell = "Basic",
			},
		},
		stats = {
			roundsPlayed = 0,
			longestSurvival = 0,
			foodCollected = 0,
		},
	}
end

local function getKey(player: Player): string
	return "player_" .. tostring(player.UserId)
end

local function publish(player: Player)
	if remotes and remotes.PlayerDataChanged then
		remotes.PlayerDataChanged:FireClient(player, playerDataByUserId[player.UserId])
	end
end

function PlayerDataService.GetData(player: Player)
	return playerDataByUserId[player.UserId]
end

function PlayerDataService.SelectBug(player: Player, bugId: string): boolean
	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end

	if not BugArchetypes[bugId] then
		warn("Unknown bug selected:", bugId)
		return false
	end

	if not data.unlockedBugs[bugId] then
		warn(player.Name .. " tried to select a locked bug:", bugId)
		return false
	end

	data.selectedBug = bugId
	publish(player)
	return true
end

function PlayerDataService.AddDna(player: Player, amount: number)
	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end

	data.currency.dna += amount
	publish(player)
end

function PlayerDataService.AddCrumbs(player: Player, amount: number)
	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end

	data.currency.crumbs += amount
	data.stats.foodCollected += amount
	publish(player)
end

function PlayerDataService.TrackRoundPlayed(player: Player, survivedSeconds: number)
	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end

	data.stats.roundsPlayed += 1
	data.stats.longestSurvival = math.max(data.stats.longestSurvival, survivedSeconds)
	publish(player)
end

function PlayerDataService.LoadPlayer(player: Player)
	local defaultData = makeDefaultData()
	local success, savedData = pcall(function()
		return store:GetAsync(getKey(player))
	end)

	if success and type(savedData) == "table" then
		playerDataByUserId[player.UserId] = savedData
	else
		if not success then
			warn("Failed to load player data for", player.Name, savedData)
		end
		playerDataByUserId[player.UserId] = defaultData
	end

	publish(player)
end

function PlayerDataService.SavePlayer(player: Player)
	local data = playerDataByUserId[player.UserId]
	if not data then
		return
	end

	local success, err = pcall(function()
		store:SetAsync(getKey(player), data)
	end)

	if not success then
		warn("Failed to save player data for", player.Name, err)
	end
end

function PlayerDataService.UnloadPlayer(player: Player)
	PlayerDataService.SavePlayer(player)
	playerDataByUserId[player.UserId] = nil
end

function PlayerDataService.Init(remoteEvents)
	remotes = remoteEvents

	Players.PlayerAdded:Connect(PlayerDataService.LoadPlayer)
	Players.PlayerRemoving:Connect(PlayerDataService.UnloadPlayer)

	remotes.SelectBug.OnServerEvent:Connect(function(player: Player, bugId: string)
		PlayerDataService.SelectBug(player, bugId)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(PlayerDataService.LoadPlayer, player)
	end
end

return PlayerDataService
