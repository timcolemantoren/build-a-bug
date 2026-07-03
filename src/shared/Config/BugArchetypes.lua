--!strict

-- Base bug types for the MVP.
-- Keep these small and easy to balance until the survival loop is fun.

local BugArchetypes = {
	Ant = {
		id = "Ant",
		displayName = "Ant",
		description = "A balanced worker bug that can gather extra food.",
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
		movementSpeed = 12,
		jumpPower = 34,
		maxHealth = 150,
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
		movementSpeed = 19,
		jumpPower = 72,
		maxHealth = 80,
		hungerDrainPerSecond = 1.4,
		ability = {
			id = "Leap",
			displayName = "Leap",
			description = "Launches forward to escape danger.",
			cooldownSeconds = 12,
		},
	},
}

return BugArchetypes
