--!strict

-- MVP hazards should be readable, funny, and dodgeable.
-- The world can feel chaotic without every mistake being brutally punishing.
local HazardConfig = {
	BirdShadow = {
		id = "BirdShadow",
		displayName = "Bird Shadow",
		warningSeconds = 3,
		damage = 24,
		description = "A bird shadow sweeps across the backyard. Run out of the shadow.",
	},

	SprinklerBurst = {
		id = "SprinklerBurst",
		displayName = "Sprinkler Burst",
		warningSeconds = 2.2,
		damage = 18,
		description = "Water blasts across part of the map. Get out of the lane.",
	},

	ShoeStomp = {
		id = "ShoeStomp",
		displayName = "Shoe Stomp",
		warningSeconds = 2.7,
		damage = 42,
		description = "A giant shoe lands after the stomp zone appears.",
	},
}

return HazardConfig
