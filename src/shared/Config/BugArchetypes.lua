--!strict

-- Base bug types and unlockable sidegrades.
-- All bugs use 100 health so durability differences come from hazard rules and abilities.

local BugArchetypes = {
	Ant = {
		id = "Ant",
		displayName = "Ant",
		description = "A balanced worker bug that can gather extra food.",
		unlockCost = 0,
		movementSpeed = 16,
		jumpPower = 45,
		maxHealth = 100,
		hungerDrainPerSecond = 1,
		crumbCarryBonus = 2,
		ability = {
			id = "CarryMore",
			displayName = "Carry More",
			description = "Collects a little extra food from crumbs.",
			cooldownSeconds = 0,
		},
	},

	Beetle = {
		id = "Beetle",
		displayName = "Beetle",
		description = "A tough armored bug that survives mistakes but moves slower.",
		unlockCost = 0,
		movementSpeed = 12,
		jumpPower = 34,
		maxHealth = 100,
		hungerDrainPerSecond = 1.2,
		damageReduction = 0.25,
		ability = {
			id = "ShellBlock",
			displayName = "Shell Block",
			description = "Briefly reduces incoming hazard damage.",
			cooldownSeconds = 18,
			durationSeconds = 4,
		},
	},

	Grasshopper = {
		id = "Grasshopper",
		displayName = "Grasshopper",
		description = "A fragile jumper built for quick escapes.",
		unlockCost = 0,
		movementSpeed = 19,
		jumpPower = 72,
		maxHealth = 100,
		hungerDrainPerSecond = 1.4,
		ability = {
			id = "Leap",
			displayName = "Leap",
			description = "Launches forward to escape danger.",
			cooldownSeconds = 12,
		},
	},

	Ladybug = {
		id = "Ladybug",
		displayName = "Ladybug",
		description = "A quick, nimble bug with a short burst of wing-assisted speed.",
		unlockCost = 850,
		movementSpeed = 17,
		jumpPower = 48,
		maxHealth = 100,
		hungerDrainPerSecond = 1.15,
		damageReduction = 0.10,
		ability = {
			id = "WingBurst",
			displayName = "Wing Burst",
			description = "Briefly boosts ground speed to escape a bad situation.",
			cooldownSeconds = 16,
			durationSeconds = 3.5,
			boostSpeed = 25,
		},
	},

	Mantis = {
		id = "Mantis",
		displayName = "Mantis",
		description = "A precise hunter with a fast forward pounce and strong jump.",
		unlockCost = 2500,
		movementSpeed = 15,
		jumpPower = 58,
		maxHealth = 100,
		hungerDrainPerSecond = 1.25,
		ability = {
			id = "Pounce",
			displayName = "Pounce",
			description = "Dashes forward in a low, fast arc.",
			cooldownSeconds = 14,
		},
	},

	Dragonfly = {
		id = "Dragonfly",
		displayName = "Dragonfly",
		description = "A lightning-fast aerial bug built for repositioning and risky escapes.",
		unlockCost = 6000,
		movementSpeed = 20,
		jumpPower = 62,
		maxHealth = 100,
		hungerDrainPerSecond = 1.45,
		ability = {
			id = "AirDash",
			displayName = "Air Dash",
			description = "Surges forward and slightly upward in a fast wing-powered dash.",
			cooldownSeconds = 15,
		},
	},

	Pillbug = {
		id = "Pillbug",
		displayName = "Pillbug",
		description = "A slow little tank that can roll away from danger in a short armored burst.",
		unlockCost = 12000,
		movementSpeed = 13,
		jumpPower = 32,
		maxHealth = 100,
		hungerDrainPerSecond = 1.05,
		damageReduction = 0.18,
		ability = {
			id = "RollAway",
			displayName = "Roll Away",
			description = "Curls up and rockets forward for a short protected escape.",
			cooldownSeconds = 17,
			durationSeconds = 2.4,
			boostSpeed = 24,
		},
	},
}

return BugArchetypes
