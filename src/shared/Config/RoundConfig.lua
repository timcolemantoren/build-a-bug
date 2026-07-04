--!strict

local RoundConfig = {
	lobbyCountdownSeconds = 15,
	roundDurationSeconds = 180,
	minimumPlayers = 1,
	pickupSpawnIntervalSeconds = 6,
	crumbsPerSpawn = 7,
	dnaPickupsPerSpawn = 4,
	baseDnaReward = 10,
	survivalDnaRewardPerMinute = 5,
	crumbDnaReward = 1,
	dnaPickupReward = 3,
}

-- Backward compatibility with older code paths.
RoundConfig.crumbSpawnIntervalSeconds = RoundConfig.pickupSpawnIntervalSeconds

return RoundConfig
