--!strict

-- MVP hazards should be readable, funny, and easy to understand quickly.
-- These are definitions only; server-side behavior lives in HazardService.

local HazardConfig = {
	BirdShadow = {
		id = "BirdShadow",
		displayName = "Bird Shadow",
		warningSeconds = 3,
		damage = 35,
		description = "A dark bird shadow sweeps over the yard. Get out of the shadow before it strikes.",
	},

	SprinklerBurst = {
		id = "SprinklerBurst",
		displayName = "Sprinkler Burst",
		warningSeconds = 2,
		damage = 25,
		description = "A blue water lane appears before the sprinkler blasts through it. Get out of the lane.",
	},

	ShoeStomp = {
		id = "ShoeStomp",
		displayName = "Shoe Stomp",
		warningSeconds = 2.5,
		damage = 60,
		description = "A giant shoe drops toward the marked stomp zone. Move before it lands.",
	},
}

return HazardConfig
