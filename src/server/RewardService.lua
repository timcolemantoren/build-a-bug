--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local RoundConfig = require(BuildABugShared.Config.RoundConfig)
local BugArchetypes = require(BuildABugShared.Config.BugArchetypes)

local RewardService = {}
local PlayerDataService = nil

function RewardService.Init(playerDataService)
	PlayerDataService = playerDataService
end

local function getEffectiveCrumbAmount(player: Player, baseAmount: number): number
	if not PlayerDataService then
		return baseAmount
	end

	local data = PlayerDataService.GetData(player)
	local bug = data and BugArchetypes[data.selectedBug]
	if not bug then
		return baseAmount
	end

	return baseAmount + (bug.crumbCarryBonus or 0)
end

function RewardService.AwardCrumb(player: Player, amount: number?)
	if not PlayerDataService then
		return
	end

	local baseAmount = amount or 1
	local crumbAmount = getEffectiveCrumbAmount(player, baseAmount)
	PlayerDataService.AddCrumbs(player, crumbAmount)
	PlayerDataService.AddDna(player, RoundConfig.crumbDnaReward * crumbAmount)
end

function RewardService.AwardRoundComplete(player: Player, survivedSeconds: number)
	if not PlayerDataService then
		return
	end

	local minutesSurvived = math.floor(survivedSeconds / 60)
	local dnaEarned = RoundConfig.baseDnaReward + (minutesSurvived * RoundConfig.survivalDnaRewardPerMinute)

	PlayerDataService.AddDna(player, dnaEarned)
	PlayerDataService.TrackRoundPlayed(player, survivedSeconds)
end

return RewardService
