--!strict

-- Permanent achievements and their cosmetic or badge rewards.
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
	"SurvivalStreak",
	"BackyardFixture",
	"PantryRaider",
	"DnaHoarder",
	"UnstoppableBug",
	"CenturyClub",
	"CrumbLegend",
	"DnaMaster",
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

	-- Longer-range badge milestones intentionally widen out after the first
	-- cosmetic rewards. These give returning players something visible to chase
	-- without flooding the inventory with a reward every few rounds.
	SurvivalStreak = {
		id = "SurvivalStreak",
		displayName = "Still Standing",
		description = "Survive 25 full rounds.",
		kind = "fullRoundsSurvived",
		target = 25,
		rewardName = "Badge: Still Standing",
	},
	BackyardFixture = {
		id = "BackyardFixture",
		displayName = "Backyard Fixture",
		description = "Play 50 rounds.",
		kind = "roundsPlayed",
		target = 50,
		rewardName = "Badge: Backyard Fixture",
	},
	PantryRaider = {
		id = "PantryRaider",
		displayName = "Pantry Raider",
		description = "Collect 1,000 food.",
		kind = "foodCollected",
		target = 1000,
		rewardName = "Badge: Pantry Raider",
	},
	DnaHoarder = {
		id = "DnaHoarder",
		displayName = "DNA Hoarder",
		description = "Earn 7,500 Lifetime DNA.",
		kind = "lifetimeDna",
		target = 7500,
		rewardName = "Badge: DNA Hoarder",
	},
	UnstoppableBug = {
		id = "UnstoppableBug",
		displayName = "Unstoppable Bug",
		description = "Survive 50 full rounds.",
		kind = "fullRoundsSurvived",
		target = 50,
		rewardName = "Badge: Unstoppable Bug",
	},
	CenturyClub = {
		id = "CenturyClub",
		displayName = "Century Club",
		description = "Play 100 rounds.",
		kind = "roundsPlayed",
		target = 100,
		rewardName = "Badge: Century Club",
	},
	CrumbLegend = {
		id = "CrumbLegend",
		displayName = "Crumb Legend",
		description = "Collect 2,500 food.",
		kind = "foodCollected",
		target = 2500,
		rewardName = "Badge: Crumb Legend",
	},
	DnaMaster = {
		id = "DnaMaster",
		displayName = "DNA Master",
		description = "Earn 20,000 Lifetime DNA.",
		kind = "lifetimeDna",
		target = 20000,
		rewardName = "Badge: DNA Master",
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
