--!nonstrict

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local BugArchetypes = require(BuildABugShared.Config.BugArchetypes)
local ProgressionConfig = require(BuildABugShared.Config.ProgressionConfig)
local CosmeticStyles = require(BuildABugShared.Config.CosmeticStyles)

local DATASTORE_NAME = "BuildABug_PlayerData_v1"

local store = nil
local dataStoreEnabled = false

local storeSuccess, storeOrError = pcall(function()
	return DataStoreService:GetDataStore(DATASTORE_NAME)
end)

if storeSuccess then
	store = storeOrError
	dataStoreEnabled = true
else
	warn("[Build a Bug] DataStore unavailable; using temporary in-memory player data for this Studio session.", storeOrError)
end

local PlayerDataService = {}
local playerDataByUserId = {}
local remotes = nil

local function makeDefaultData()
	return {
		version = 2,
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
		unlockedCosmetics = {
			[CosmeticStyles.GetUnlockKey("BodyColor", "Natural")] = true,
			[CosmeticStyles.GetUnlockKey("Eyes", "Default")] = true,
		},
		cosmetics = {
			bodyColor = "Natural",
			eyes = "Default",
		},
		savedBuilds = {
			Slot1 = {
				base = "Ant",
				color = "Natural",
				pattern = "None",
				eyes = "Default",
				shell = "Basic",
			},
		},
		stats = {
			roundsPlayed = 0,
			longestSurvival = 0,
			foodCollected = 0,
			lifetimeDna = 0,
		},
	}
end

local function markCosmeticOwned(data, slot: string, styleId: string)
	data.unlockedCosmetics = data.unlockedCosmetics or {}
	data.unlockedCosmetics[CosmeticStyles.GetUnlockKey(slot, styleId)] = true
end

local function isCosmeticOwned(data, slot: string, styleId: string): boolean
	local item = CosmeticStyles.GetItem(slot, styleId)
	if not item then
		return false
	end
	if (item.cost or 0) <= 0 then
		return true
	end
	local key = CosmeticStyles.GetUnlockKey(slot, styleId)
	return data.unlockedCosmetics and data.unlockedCosmetics[key] == true
end

local function normalizeData(data)
	data.version = 2
	data.selectedBug = BugArchetypes[data.selectedBug] and data.selectedBug or "Ant"

	data.currency = data.currency or {}
	data.currency.dna = math.max(0, data.currency.dna or 0)
	data.currency.crumbs = math.max(0, data.currency.crumbs or 0)

	data.unlockedBugs = data.unlockedBugs or {}
	data.unlockedBugs.Ant = data.unlockedBugs.Ant ~= false
	data.unlockedBugs.Beetle = data.unlockedBugs.Beetle ~= false
	data.unlockedBugs.Grasshopper = data.unlockedBugs.Grasshopper ~= false
	data.unlockedCosmetics = data.unlockedCosmetics or {}

	data.cosmetics = data.cosmetics or {}
	local bodyColor = data.cosmetics.bodyColor or "Natural"
	if not CosmeticStyles.IsValidBodyColor(bodyColor) then
		bodyColor = "Natural"
	end
	local eyes = data.cosmetics.eyes or "Default"
	if not CosmeticStyles.IsValidEyeStyle(eyes) then
		eyes = "Default"
	end
	data.cosmetics.bodyColor = bodyColor
	data.cosmetics.eyes = eyes

	-- Free defaults are always owned. Existing equipped body colors are grandfathered
	-- because they were selectable before the DNA shop existed.
	markCosmeticOwned(data, "BodyColor", "Natural")
	markCosmeticOwned(data, "Eyes", "Default")
	markCosmeticOwned(data, "BodyColor", bodyColor)
	markCosmeticOwned(data, "Eyes", eyes)

	data.savedBuilds = data.savedBuilds or {}
	data.stats = data.stats or {}
	data.stats.roundsPlayed = data.stats.roundsPlayed or 0
	data.stats.longestSurvival = data.stats.longestSurvival or 0
	data.stats.foodCollected = data.stats.foodCollected or 0

	-- Before v2 DNA was never spendable, so the current wallet is a correct migration
	-- baseline for lifetime progression.
	if data.stats.lifetimeDna == nil then
		data.stats.lifetimeDna = data.currency.dna
	end
	data.stats.lifetimeDna = math.max(data.stats.lifetimeDna, data.currency.dna)

	return data
end

local function getKey(player: Player): string
	return "player_" .. tostring(player.UserId)
end

local function applyCharacterTuning(player: Player)
	local data = playerDataByUserId[player.UserId]
	if not data then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local bug = BugArchetypes[data.selectedBug]
	if not bug then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local oldMaxHealth = humanoid.MaxHealth
		local wasFullHealth = humanoid.Health >= oldMaxHealth
		local newMaxHealth = bug.maxHealth or 100

		humanoid.WalkSpeed = bug.movementSpeed or 16
		humanoid.JumpPower = bug.jumpPower or 50
		humanoid.MaxHealth = newMaxHealth

		pcall(function()
			humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		end)

		if wasFullHealth then
			humanoid.Health = newMaxHealth
		else
			humanoid.Health = math.min(humanoid.Health, newMaxHealth)
		end
	end
end

local function publish(player: Player)
	local data = playerDataByUserId[player.UserId]
	if not data then
		return
	end

	local currency = data.currency or {}
	local stats = data.stats or {}
	local cosmetics = data.cosmetics or {}
	local dna = currency.dna or 0
	local lifetimeDna = stats.lifetimeDna or dna
	local currentProgress = ProgressionConfig.GetLevelForDna(lifetimeDna)
	local nextProgress = ProgressionConfig.GetNextLevelForDna(lifetimeDna)

	data.progression = {
		current = currentProgress,
		next = nextProgress,
		lifetimeDna = lifetimeDna,
	}

	player:SetAttribute("SelectedBug", data.selectedBug or "Ant")
	player:SetAttribute("BodyColor", cosmetics.bodyColor or "Natural")
	player:SetAttribute("EyeStyle", cosmetics.eyes or "Default")
	player:SetAttribute("BugLevel", currentProgress and currentProgress.level or 1)
	player:SetAttribute("BugTitle", currentProgress and currentProgress.title or "Fresh Hatchling")
	player:SetAttribute("RoundsPlayed", stats.roundsPlayed or 0)
	player:SetAttribute("BestSurvival", stats.longestSurvival or 0)
	player:SetAttribute("FoodCollected", stats.foodCollected or 0)
	player:SetAttribute("LifetimeDna", lifetimeDna)
	player:SetAttribute("TotalDna", dna)
	player:SetAttribute("TotalCrumbs", currency.crumbs or 0)

	applyCharacterTuning(player)

	if remotes and remotes.PlayerDataChanged then
		remotes.PlayerDataChanged:FireClient(player, data)
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

	if player:GetAttribute("InRound") == true then
		warn(player.Name .. " tried to switch bugs during an active round")
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

local function setEquippedCosmetic(data, slot: string, value: string)
	if slot == "BodyColor" then
		data.cosmetics.bodyColor = value
	elseif slot == "Eyes" then
		data.cosmetics.eyes = value
	end
end

function PlayerDataService.SetCosmetic(player: Player, slot: string, value: string): boolean
	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end

	if player:GetAttribute("InRound") == true then
		warn(player.Name .. " tried to change cosmetics during an active round")
		return false
	end

	local item = CosmeticStyles.GetItem(slot, value)
	if not item then
		warn("Unknown cosmetic selected:", slot, value)
		return false
	end

	if not isCosmeticOwned(data, slot, value) then
		warn(player.Name .. " tried to equip a locked cosmetic:", slot, value)
		return false
	end

	data.cosmetics = data.cosmetics or {}
	setEquippedCosmetic(data, slot, value)
	publish(player)
	return true
end

function PlayerDataService.PurchaseCosmetic(player: Player, slot: string, value: string): boolean
	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end

	if player:GetAttribute("InRound") == true then
		warn(player.Name .. " tried to buy cosmetics during an active round")
		return false
	end

	local item = CosmeticStyles.GetItem(slot, value)
	if not item then
		warn("Unknown cosmetic purchase:", slot, value)
		return false
	end

	if isCosmeticOwned(data, slot, value) then
		setEquippedCosmetic(data, slot, value)
		publish(player)
		return true
	end

	local cost = math.max(0, item.cost or 0)
	if (data.currency.dna or 0) < cost then
		return false
	end

	data.currency.dna -= cost
	markCosmeticOwned(data, slot, value)
	setEquippedCosmetic(data, slot, value)
	publish(player)
	return true
end

function PlayerDataService.AddDna(player: Player, amount: number)
	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end

	data.currency.dna += amount
	data.stats.lifetimeDna = (data.stats.lifetimeDna or 0) + amount
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

function PlayerDataService.RestoreRoundSnapshot(player: Player, snapshot)
	local data = PlayerDataService.GetData(player)
	if not data or not snapshot then
		return
	end

	data.currency.dna = math.max(0, snapshot.dna or data.currency.dna or 0)
	data.currency.crumbs = math.max(0, snapshot.crumbs or data.currency.crumbs or 0)
	if data.stats then
		data.stats.foodCollected = math.max(0, snapshot.foodCollected or data.stats.foodCollected or 0)
		data.stats.lifetimeDna = math.max(0, snapshot.lifetimeDna or data.stats.lifetimeDna or 0)
	end
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

	if not dataStoreEnabled or not store then
		playerDataByUserId[player.UserId] = normalizeData(defaultData)
		publish(player)
		return
	end

	local success, savedData = pcall(function()
		return store:GetAsync(getKey(player))
	end)

	if success and type(savedData) == "table" then
		playerDataByUserId[player.UserId] = normalizeData(savedData)
	else
		if not success then
			warn("Failed to load player data for", player.Name, savedData)
		end
		playerDataByUserId[player.UserId] = normalizeData(defaultData)
	end

	publish(player)
end

function PlayerDataService.SavePlayer(player: Player)
	local data = playerDataByUserId[player.UserId]
	if not data then
		return
	end

	if not dataStoreEnabled or not store then
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

	Players.PlayerAdded:Connect(function(player: Player)
		PlayerDataService.LoadPlayer(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			applyCharacterTuning(player)
		end)
	end)

	Players.PlayerRemoving:Connect(PlayerDataService.UnloadPlayer)

	remotes.SelectBug.OnServerEvent:Connect(function(player: Player, bugId: string)
		PlayerDataService.SelectBug(player, bugId)
	end)

	remotes.SetCosmetic.OnServerEvent:Connect(function(player: Player, slot: string, value: string)
		PlayerDataService.SetCosmetic(player, slot, value)
	end)

	remotes.PurchaseCosmetic.OnServerEvent:Connect(function(player: Player, slot: string, value: string)
		PlayerDataService.PurchaseCosmetic(player, slot, value)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(PlayerDataService.LoadPlayer, player)
	end
end

return PlayerDataService
