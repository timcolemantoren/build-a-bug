--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local AchievementConfig = require(BuildABugShared.Config.AchievementConfig)

local AchievementService = {}
local PlayerDataService = nil
local remotes = nil

local function isComplete(data, achievementId: string): boolean
	local achievements = data and data.achievements or {}
	return achievements[achievementId] == true
end

local function announce(player: Player, achievement)
	if not remotes or not remotes.RoundStateChanged then
		return
	end

	remotes.RoundStateChanged:FireClient(player, "AchievementUnlocked", {
		id = achievement.id,
		displayName = achievement.displayName,
		description = achievement.description,
		rewardSlot = achievement.rewardSlot,
		rewardId = achievement.rewardId,
		rewardName = achievement.rewardName,
	})
end

function AchievementService.Init(playerDataService, remoteEvents)
	PlayerDataService = playerDataService
	remotes = remoteEvents
end

function AchievementService.Evaluate(player: Player)
	if not PlayerDataService then
		return {}
	end

	local data = PlayerDataService.GetData(player)
	if not data then
		return {}
	end

	local unlockedNow = {}
	for _, achievementId in ipairs(AchievementConfig.Order) do
		local achievement = AchievementConfig.Get(achievementId)
		if achievement and not isComplete(data, achievementId) then
			local progress = AchievementConfig.GetProgress(achievement, data)
			if progress >= (achievement.target or 1) then
				local unlocked = PlayerDataService.UnlockAchievement(
					player,
					achievementId,
					achievement.rewardSlot,
					achievement.rewardId
				)
				if unlocked then
					table.insert(unlockedNow, achievementId)
					announce(player, achievement)
					data = PlayerDataService.GetData(player) or data
				end
			end
		end
	end

	return unlockedNow
end

return AchievementService
