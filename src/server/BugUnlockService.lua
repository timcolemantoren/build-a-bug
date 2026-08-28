--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local BugArchetypes = require(BuildABugShared.Config.BugArchetypes)
local BugLoadoutService = require(script.Parent.BugLoadoutService)

local BugUnlockService = {}
local PlayerDataService = nil
local remotes = nil

local function sendResult(player: Player, payload)
	if remotes and remotes.BugUnlockResult then
		remotes.BugUnlockResult:FireClient(player, payload)
	end
end

function BugUnlockService.Purchase(player: Player, bugId: string): boolean
	if not PlayerDataService then
		sendResult(player, { success = false, bugId = bugId, message = "Bug unlock service is unavailable." })
		return false
	end
	if player:GetAttribute("InRound") == true then
		sendResult(player, { success = false, bugId = bugId, message = "You cannot unlock bugs during a match." })
		return false
	end

	local data = PlayerDataService.GetData(player)
	local bug = BugArchetypes[bugId]
	if not data or not bug then
		sendResult(player, { success = false, bugId = bugId, message = "That bug is unavailable." })
		return false
	end

	data.unlockedBugs = data.unlockedBugs or {}
	if data.unlockedBugs[bugId] == true then
		local selected = BugLoadoutService.SelectBug(player, bugId)
		sendResult(player, {
			success = true,
			bugId = bugId,
			displayName = bug.displayName,
			alreadyOwned = true,
			selected = selected,
			cost = 0,
			balance = data.currency and data.currency.dna or 0,
		})
		return true
	end

	local cost = math.max(0, bug.unlockCost or 0)
	local balance = data.currency and data.currency.dna or 0
	if balance < cost then
		sendResult(player, {
			success = false,
			bugId = bugId,
			displayName = bug.displayName,
			message = string.format("Need %s more DNA to unlock %s.", tostring(cost - balance), bug.displayName),
			balance = balance,
			cost = cost,
		})
		return false
	end

	data.currency = data.currency or { dna = 0, crumbs = 0 }
	data.currency.dna = math.max(0, (data.currency.dna or 0) - cost)
	data.unlockedBugs[bugId] = true

	-- A successful purchase immediately becomes tangible: load the new species'
	-- clean/saved appearance and select it. This also publishes the updated wallet
	-- and unlocked-bug table to the client in the normal player-data pathway.
	local selected = BugLoadoutService.SelectBug(player, bugId)
	if not selected then
		-- The unlock itself is still valid. Republish current state if selection ever
		-- fails so the card cannot remain visually locked after currency was spent.
		PlayerDataService.SelectBug(player, data.selectedBug or "Ant")
	end

	sendResult(player, {
		success = true,
		bugId = bugId,
		displayName = bug.displayName,
		alreadyOwned = false,
		selected = selected,
		cost = cost,
		balance = data.currency.dna or 0,
	})
	return true
end

function BugUnlockService.Init(playerDataService, remoteEvents)
	PlayerDataService = playerDataService
	remotes = remoteEvents
	remotes.PurchaseBug.OnServerEvent:Connect(function(player: Player, bugId: string)
		BugUnlockService.Purchase(player, bugId)
	end)
end

return BugUnlockService
