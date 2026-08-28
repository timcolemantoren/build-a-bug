--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local BugArchetypes = require(BuildABugShared.Config.BugArchetypes)
local CosmeticStyles = require(BuildABugShared.Config.CosmeticStyles)

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

local function snapshotCurrentLoadout(player: Player)
	local data = PlayerDataService and PlayerDataService.GetData(player)
	if not data or not BugArchetypes[data.selectedBug] then
		return
	end

	local cosmetics = data.cosmetics or {}
	local loadouts = getLoadoutTable(data)
	loadouts[data.selectedBug] = sanitizeLoadout(player, {
		bodyColor = cosmetics.bodyColor or DEFAULT_LOADOUT.bodyColor,
		eyes = cosmetics.eyes or DEFAULT_LOADOUT.eyes,
		pattern = cosmetics.pattern or DEFAULT_LOADOUT.pattern,
	})
end

local function applyLoadout(player: Player, bugId: string)
	local data = PlayerDataService and PlayerDataService.GetData(player)
	if not data then
		return
	end

	local loadouts = getLoadoutTable(data)
	local loadout = sanitizeLoadout(player, loadouts[bugId] or DEFAULT_LOADOUT)
	loadouts[bugId] = copyLoadout(loadout)

	-- Use the same validated equip path as the Profile UI so ownership rules stay
	-- centralized in PlayerDataService.
	PlayerDataService.SetCosmetic(player, "BodyColor", loadout.bodyColor)
	PlayerDataService.SetCosmetic(player, "Eyes", loadout.eyes)
	PlayerDataService.SetCosmetic(player, "Pattern", loadout.pattern)
end

function BugLoadoutService.SaveCurrentLoadout(player: Player)
	snapshotCurrentLoadout(player)
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

	if data.selectedBug == bugId then
		snapshotCurrentLoadout(player)
		return true
	end

	-- Save the species being left before changing the selected bug.
	snapshotCurrentLoadout(player)

	if not PlayerDataService.SelectBug(player, bugId) then
		return false
	end

	-- A species with no saved appearance starts from a clean default slate.
	applyLoadout(player, bugId)
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
