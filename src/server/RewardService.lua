--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local RoundConfig = require(BuildABugShared.Config.RoundConfig)

local RewardService = {}
local PlayerDataService = nil

function RewardService.Init(playerDataService)
	PlayerDataService = playerDataService
end

function RewardService.AwardCrumb(player: Player, amount: number?)
	if not PlayerDataService then
		return
	end

	local crumbAmount = amount or 1
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
