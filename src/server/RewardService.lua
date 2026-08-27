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

local function healFromFood(player: Player, physicalPieces: number): number
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return 0
	end

	local healPercent = RoundConfig.crumbHealPercent or 0.04
	local healAmount = humanoid.MaxHealth * healPercent * physicalPieces
	local oldHealth = humanoid.Health
	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healAmount)
	local actualHeal = humanoid.Health - oldHealth

	if actualHeal > 0 then
		local highlight = Instance.new("Highlight")
		highlight.Name = "FoodHealFlash"
		highlight.FillColor = Color3.fromRGB(100, 255, 120)
		highlight.OutlineColor = Color3.fromRGB(180, 255, 190)
		highlight.FillTransparency = 0.65
		highlight.OutlineTransparency = 0.25
		highlight.Parent = character

		task.delay(0.3, function()
			if highlight and highlight.Parent then
				highlight:Destroy()
			end
		end)
	end

	return actualHeal
end

function RewardService.AwardCrumb(player: Player, amount: number?)
	if not PlayerDataService then
		return 0, 0, 0
	end

	local baseAmount = amount or 1
	local crumbAmount = getEffectiveCrumbAmount(player, baseAmount)
	local dnaAmount = RoundConfig.crumbDnaReward * crumbAmount
	local healedAmount = healFromFood(player, baseAmount)

	PlayerDataService.AddCrumbs(player, crumbAmount)
	PlayerDataService.AddDna(player, dnaAmount)
	return crumbAmount, dnaAmount, healedAmount
end

function RewardService.AwardDnaPickup(player: Player, amount: number?)
	if not PlayerDataService then
		return 0
	end

	local dnaAmount = amount or RoundConfig.dnaPickupReward or 3
	PlayerDataService.AddDna(player, dnaAmount)
	return dnaAmount
end

function RewardService.AwardRoundComplete(player: Player, survivedSeconds: number)
	if not PlayerDataService then
		return {
			completionDna = 0,
			survivedSeconds = survivedSeconds,
		}
	end

	local minutesSurvived = math.floor(survivedSeconds / 60)
	local dnaEarned = RoundConfig.baseDnaReward + (minutesSurvived * RoundConfig.survivalDnaRewardPerMinute)

	PlayerDataService.AddDna(player, dnaEarned)
	PlayerDataService.TrackRoundPlayed(player, survivedSeconds)

	return {
		completionDna = dnaEarned,
		survivedSeconds = survivedSeconds,
	}
end

return RewardService
