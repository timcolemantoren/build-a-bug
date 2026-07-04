--!strict

local RoundConfig = {
	lobbyCountdownSeconds = 15,
	roundDurationSeconds = 180,
	minimumPlayers = 1,
	pickupSpawnIntervalSeconds = 7,
	crumbsPerSpawn = 3,
	dnaPickupsPerSpawn = 2,
	baseDnaReward = 10,
	survivalDnaRewardPerMinute = 5,
	crumbDnaReward = 1,
	dnaPickupReward = 3,
}

-- Backward compatibility with older code paths.
RoundConfig.crumbSpawnIntervalSeconds = RoundConfig.pickupSpawnIntervalSeconds

return RoundConfig
