--!strict

-- Hazards should be readable, funny, and dodgeable.
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

	RollingBall = {
		id = "RollingBall",
		displayName = "Rolling Ball",
		warningSeconds = 2.5,
		damage = 22,
		description = "A giant toy ball rolls through the yard. Get out of its path.",
	},

	Raindrop = {
		id = "Raindrop",
		displayName = "Giant Raindrop",
		warningSeconds = 2.0,
		damage = 16,
		description = "A huge drop falls from above and splashes where the blue marker appears.",
	},
}

return HazardConfig
