--!strict

-- Permanent achievements and their cosmetic rewards.
-- Conditions are evaluated server-side by AchievementService. The client uses
-- the same definitions to explain progress and rewards in Profile.

local AchievementConfig = {}

AchievementConfig.Order = {
	"BackyardSurvivor",
	"YardRegular",
	"SnackStack",
	"DnaCollector",
	"SeasonedSurvivor",
	"YardVeteran",
	"CrumbChampion",
	"DnaLegend",
}

AchievementConfig.Items = {
	BackyardSurvivor = {
		id = "BackyardSurvivor",
		displayName = "Backyard Survivor",
		description = "Survive a full Backyard round.",
		kind = "fullRoundsSurvived",
		target = 1,
		rewardSlot = "Eyes",
		rewardId = "VictoryGold",
		rewardName = "Victory Gold Eyes",
	},
	YardRegular = {
		id = "YardRegular",
		displayName = "Yard Regular",
		description = "Play 5 rounds.",
		kind = "roundsPlayed",
		target = 5,
		rewardSlot = "Eyes",
		rewardId = "Bubblegum",
		rewardName = "Bubblegum Eyes",
	},
	SnackStack = {
		id = "SnackStack",
		displayName = "Snack Stack",
		description = "Collect 100 food.",
		kind = "foodCollected",
		target = 100,
		rewardSlot = "BodyColor",
		rewardId = "Honey",
		rewardName = "Honey Body Color",
	},
	DnaCollector = {
		id = "DnaCollector",
		displayName = "DNA Collector",
		description = "Earn 500 Lifetime DNA.",
		kind = "lifetimeDna",
		target = 500,
		rewardSlot = "BodyColor",
		rewardId = "Electric",
		rewardName = "Electric Body Color",
	},
	SeasonedSurvivor = {
		id = "SeasonedSurvivor",
		displayName = "Seasoned Survivor",
		description = "Survive 10 full rounds.",
		kind = "fullRoundsSurvived",
		target = 10,
		rewardSlot = "Eyes",
		rewardId = "Starshine",
		rewardName = "Starshine Eyes",
	},
	YardVeteran = {
		id = "YardVeteran",
		displayName = "Yard Veteran",
		description = "Play 25 rounds.",
		kind = "roundsPlayed",
		target = 25,
		rewardSlot = "Eyes",
		rewardId = "Frost",
		rewardName = "Frost Eyes",
	},
	CrumbChampion = {
		id = "CrumbChampion",
		displayName = "Crumb Champion",
		description = "Collect 500 food.",
		kind = "foodCollected",
		target = 500,
		rewardSlot = "BodyColor",
		rewardId = "Mint",
		rewardName = "Mint Body Color",
	},
	DnaLegend = {
		id = "DnaLegend",
		displayName = "DNA Legend",
		description = "Earn 2,500 Lifetime DNA.",
		kind = "lifetimeDna",
		target = 2500,
		rewardSlot = "BodyColor",
		rewardId = "Royal",
		rewardName = "Royal Purple Body Color",
	},
}

function AchievementConfig.Get(achievementId: string)
	return AchievementConfig.Items[achievementId]
end

function AchievementConfig.GetProgress(achievement, data, context)
	if not achievement then
		return 0
	end

	data = data or {}
	context = context or {}
	local stats = data.stats or {}

	if achievement.kind == "fullRoundsSurvived" then
		return stats.fullRoundsSurvived or 0
	elseif achievement.kind == "roundsPlayed" then
		return stats.roundsPlayed or 0
	elseif achievement.kind == "foodCollected" then
		return stats.foodCollected or 0
	elseif achievement.kind == "lifetimeDna" then
		return stats.lifetimeDna or 0
	end

	return 0
end

return AchievementConfig
