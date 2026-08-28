--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local BugArchetypes = require(BuildABugShared.Config.BugArchetypes)
local CosmeticStyles = require(BuildABugShared.Config.CosmeticStyles)
local BuildPresetConfig = require(BuildABugShared.Config.BuildPresetConfig)

local BugLoadoutService = {}
local PlayerDataService = nil
local remotes = nil

local DEFAULT_LOADOUT = {
	bodyColor = "Natural",
	eyes = "Default",
	pattern = "None",
}

local function copyLoadout(loadout)
	return {
		bodyColor = loadout.bodyColor or DEFAULT_LOADOUT.bodyColor,
		eyes = loadout.eyes or DEFAULT_LOADOUT.eyes,
		pattern = loadout.pattern or DEFAULT_LOADOUT.pattern,
	}
end

local function getLoadoutTable(data)
	data.savedBuilds = data.savedBuilds or {}
	data.savedBuilds.BugLoadouts = data.savedBuilds.BugLoadouts or {}
	return data.savedBuilds.BugLoadouts
end

local function getPresetTable(data, bugId: string)
	data.savedBuilds = data.savedBuilds or {}
	data.savedBuilds.BugPresets = data.savedBuilds.BugPresets or {}
	data.savedBuilds.BugPresets[bugId] = data.savedBuilds.BugPresets[bugId] or {}
	return data.savedBuilds.BugPresets[bugId]
end

local function sanitizeLoadout(player: Player, loadout)
	loadout = loadout or DEFAULT_LOADOUT
	local result = copyLoadout(loadout)

	if not CosmeticStyles.IsValidBodyColor(result.bodyColor) or not PlayerDataService.OwnsCosmetic(player, "BodyColor", result.bodyColor) then
		result.bodyColor = DEFAULT_LOADOUT.bodyColor
	end
	if not CosmeticStyles.IsValidEyeStyle(result.eyes) or not PlayerDataService.OwnsCosmetic(player, "Eyes", result.eyes) then
		result.eyes = DEFAULT_LOADOUT.eyes
	end
	if not CosmeticStyles.IsValidPatternStyle(result.pattern) or not PlayerDataService.OwnsCosmetic(player, "Pattern", result.pattern) then
		result.pattern = DEFAULT_LOADOUT.pattern
	end

	return result
end

local function currentAppearance(data)
	local cosmetics = data.cosmetics or {}
	return {
		bodyColor = cosmetics.bodyColor or DEFAULT_LOADOUT.bodyColor,
		eyes = cosmetics.eyes or DEFAULT_LOADOUT.eyes,
		pattern = cosmetics.pattern or DEFAULT_LOADOUT.pattern,
	}
end

local function snapshotCurrentLoadout(player: Player)
	local data = PlayerDataService and PlayerDataService.GetData(player)
	if not data or not BugArchetypes[data.selectedBug] then
		return
	end

	local loadouts = getLoadoutTable(data)
	loadouts[data.selectedBug] = sanitizeLoadout(player, currentAppearance(data))
end

local function prepareLoadout(player: Player, bugId: string)
	local data = PlayerDataService and PlayerDataService.GetData(player)
	if not data then
		return nil
	end

	local loadouts = getLoadoutTable(data)
	local loadout = sanitizeLoadout(player, loadouts[bugId] or DEFAULT_LOADOUT)
	loadouts[bugId] = copyLoadout(loadout)

	-- Put the validated appearance into the shared data before SelectBug publishes.
	-- This lets BugAvatarService rebuild the new species once with its final look.
	data.cosmetics = data.cosmetics or {}
	data.cosmetics.bodyColor = loadout.bodyColor
	data.cosmetics.eyes = loadout.eyes
	data.cosmetics.pattern = loadout.pattern
	return loadout
end

local function publishCurrentData(player: Player)
	local data = PlayerDataService and PlayerDataService.GetData(player)
	if not data or not data.selectedBug then
		return false
	end

	-- Selecting the already-active bug is a safe way to publish the updated data and
	-- rebuild the visible insect once without creating a second persistence pathway.
	return PlayerDataService.SelectBug(player, data.selectedBug)
end

function BugLoadoutService.SaveCurrentLoadout(player: Player)
	snapshotCurrentLoadout(player)
end

function BugLoadoutService.SavePreset(player: Player, presetId: string): boolean
	if not PlayerDataService or not BuildPresetConfig.IsValid(presetId) then
		return false
	end
	if player:GetAttribute("InRound") == true then
		return false
	end

	local data = PlayerDataService.GetData(player)
	if not data or not BugArchetypes[data.selectedBug] then
		return false
	end

	snapshotCurrentLoadout(player)
	local presets = getPresetTable(data, data.selectedBug)
	presets[presetId] = sanitizeLoadout(player, currentAppearance(data))
	publishCurrentData(player)
	return true
end

function BugLoadoutService.LoadPreset(player: Player, presetId: string): boolean
	if not PlayerDataService or not BuildPresetConfig.IsValid(presetId) then
		return false
	end
	if player:GetAttribute("InRound") == true then
		return false
	end

	local data = PlayerDataService.GetData(player)
	if not data or not BugArchetypes[data.selectedBug] then
		return false
	end

	local presets = getPresetTable(data, data.selectedBug)
	local saved = presets[presetId]
	if type(saved) ~= "table" then
		return false
	end

	local loadout = sanitizeLoadout(player, saved)
	presets[presetId] = copyLoadout(loadout)
	data.cosmetics = data.cosmetics or {}
	data.cosmetics.bodyColor = loadout.bodyColor
	data.cosmetics.eyes = loadout.eyes
	data.cosmetics.pattern = loadout.pattern

	-- Loading a preset also becomes the species' current remembered appearance.
	local loadouts = getLoadoutTable(data)
	loadouts[data.selectedBug] = copyLoadout(loadout)
	publishCurrentData(player)
	return true
end

function BugLoadoutService.SelectBug(player: Player, bugId: string): boolean
	if not PlayerDataService then
		return false
	end

	local data = PlayerDataService.GetData(player)
	if not data or not BugArchetypes[bugId] then
		return false
	end
	if player:GetAttribute("InRound") == true then
		return false
	end
	if not data.unlockedBugs or not data.unlockedBugs[bugId] then
		return false
	end

	if data.selectedBug == bugId then
		snapshotCurrentLoadout(player)
		return true
	end

	-- Save the species being left before changing the selected bug.
	snapshotCurrentLoadout(player)

	-- A species with no saved appearance starts from a clean default slate.
	prepareLoadout(player, bugId)
	if not PlayerDataService.SelectBug(player, bugId) then
		return false
	end

	snapshotCurrentLoadout(player)
	return true
end

local function deferSnapshot(player: Player)
	task.defer(function()
		if player.Parent == Players and player:GetAttribute("InRound") ~= true then
			snapshotCurrentLoadout(player)
		end
	end)
end

function BugLoadoutService.Init(playerDataService, remoteEvents)
	PlayerDataService = playerDataService
	remotes = remoteEvents

	remotes.SelectBugLoadout.OnServerEvent:Connect(function(player: Player, bugId: string)
		BugLoadoutService.SelectBug(player, bugId)
	end)

	remotes.BuildPreset.OnServerEvent:Connect(function(player: Player, action: string, presetId: string)
		if action == "Save" then
			BugLoadoutService.SavePreset(player, presetId)
		elseif action == "Load" then
			BugLoadoutService.LoadPreset(player, presetId)
		end
	end)

	-- Profile cosmetic actions are handled by PlayerDataService first. Snapshot on
	-- the deferred task so the newly equipped style becomes this bug's saved look.
	remotes.SetCosmetic.OnServerEvent:Connect(function(player: Player)
		deferSnapshot(player)
	end)
	remotes.PurchaseCosmetic.OnServerEvent:Connect(function(player: Player)
		deferSnapshot(player)
	end)
end

return BugLoadoutService
