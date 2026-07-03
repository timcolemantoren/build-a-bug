--!strict

-- MVP hazards should be readable, funny, and easy to dodge.
-- These are definitions only; server-side behavior lives in HazardService.

local HazardConfig = {
	BirdShadow = {
		id = "BirdShadow",
		displayName = "Bird Shadow",
		warningSeconds = 3,
		damage = 35,
		description = "A bird shadow sweeps across the backyard. Hide under cover.",
	},

	SprinklerBurst = {
		id = "SprinklerBurst",
		displayName = "Sprinkler Burst",
		warningSeconds = 2,
		damage = 25,
		description = "Water blasts across part of the map. Get out of the lane.",
	},

	ShoeStomp = {
		id = "ShoeStomp",
		displayName = "Shoe Stomp",
		warningSeconds = 2.5,
		damage = 60,
		description = "A giant shoe lands after a warning circle appears.",
	},
}

return HazardConfig
