--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local BugArchetypes = require(BuildABugShared.Config.BugArchetypes)

local BugUnlockService = {}
local PlayerDataService = nil

function BugUnlockService.Purchase(player: Player, bugId: string): boolean
	if not PlayerDataService or player:GetAttribute("InRound") == true then
		return false
	end

	local data = PlayerDataService.GetData(player)
	local bug = BugArchetypes[bugId]
	if not data or not bug then
		return false
	end

	data.unlockedBugs = data.unlockedBugs or {}
	if data.unlockedBugs[bugId] == true then
		return true
	end

	local cost = math.max(0, bug.unlockCost or 0)
	if cost <= 0 then
		data.unlockedBugs[bugId] = true
	elseif (data.currency and data.currency.dna or 0) < cost then
		return false
	else
		data.currency.dna -= cost
		data.unlockedBugs[bugId] = true
	end

	-- Re-selecting the current bug republishes the updated data without introducing
	-- a second player-data publishing pathway.
	PlayerDataService.SelectBug(player, data.selectedBug or "Ant")
	return true
end

function BugUnlockService.Init(playerDataService, remotes)
	PlayerDataService = playerDataService
	remotes.PurchaseBug.OnServerEvent:Connect(function(player: Player, bugId: string)
		BugUnlockService.Purchase(player, bugId)
	end)
end

return BugUnlockService
