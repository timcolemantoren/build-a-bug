--!strict

-- Commerce/progression metadata for cosmetics.
-- Visual appearance lives in CosmeticStyles. This catalog decides how an item is
-- earned, priced, surfaced, and eventually sold for Robux.
--
-- robuxProductId = 0 means a future optional Developer Product route is not live.
-- robuxPassId = 0 means a permanent one-time premium Skin pass is not live yet.
-- availability = "always" is the DNA shop, "rotation" is future rare stock,
-- "achievement" is gameplay-only, and "robux" is premium-only.

local CosmeticCatalog = {}

CosmeticCatalog.Slots = {
	BodyColor = {
		displayName = "Colors",
		order = { "Natural", "Ruby", "Moss", "Midnight", "Coral", "Sky", "Lavender", "Lime", "Obsidian", "Honey", "Electric", "Mint", "Royal" },
	},
	Eyes = {
		displayName = "Eyes",
		order = { "Default", "Googly", "Amber", "Neon", "Emerald", "Crimson", "Void", "Solar", "VictoryGold", "Bubblegum", "Starshine", "Frost" },
	},
	Pattern = {
		displayName = "Patterns",
		order = { "None", "BackyardStripe", "Speckles", "Sunmark", "RacingBands", "Polka", "Webline", "CircuitTrace" },
	},
	Skin = {
		displayName = "Skins",
		order = { "None", "NeonCircuit", "CandyPop", "Ember", "SynthIdol" },
	},
}

CosmeticCatalog.Items = {
	BodyColor = {
		Natural = { id = "Natural", displayName = "Natural", dnaCost = 0, rarity = "Starter", availability = "always", robuxEligible = false, robuxProductId = 0 },
		Ruby = { id = "Ruby", displayName = "Ruby", dnaCost = 75, rarity = "Common", availability = "always", robuxEligible = true, robuxProductId = 0 },
		Moss = { id = "Moss", displayName = "Moss", dnaCost = 175, rarity = "Uncommon", availability = "always", robuxEligible = true, robuxProductId = 0 },
		Midnight = { id = "Midnight", displayName = "Midnight", dnaCost = 350, rarity = "Rare", availability = "always", robuxEligible = true, robuxProductId = 0 },
		Coral = { id = "Coral", displayName = "Coral", dnaCost = 525, rarity = "Rare", availability = "always", robuxEligible = false, robuxProductId = 0 },
		Sky = { id = "Sky", displayName = "Sky Blue", dnaCost = 800, rarity = "Rare", availability = "always", robuxEligible = false, robuxProductId = 0 },
		Lavender = { id = "Lavender", displayName = "Lavender", dnaCost = 1200, rarity = "Epic", availability = "always", robuxEligible = false, robuxProductId = 0 },
		Lime = { id = "Lime", displayName = "Lime Pop", dnaCost = 1800, rarity = "Epic", availability = "always", robuxEligible = false, robuxProductId = 0 },
		Obsidian = { id = "Obsidian", displayName = "Obsidian", dnaCost = 2750, rarity = "Legendary", availability = "always", robuxEligible = false, robuxProductId = 0 },
		Honey = {
			id = "Honey", displayName = "Honey", dnaCost = 0, rarity = "Achievement", availability = "achievement",
			unlockType = "achievement", achievementId = "SnackStack", robuxEligible = false, robuxProductId = 0,
		},
		Electric = {
			id = "Electric", displayName = "Electric", dnaCost = 0, rarity = "Achievement", availability = "achievement",
			unlockType = "achievement", achievementId = "DnaCollector", robuxEligible = false, robuxProductId = 0,
		},
		Mint = {
			id = "Mint", displayName = "Mint", dnaCost = 0, rarity = "Achievement", availability = "achievement",
			unlockType = "achievement", achievementId = "CrumbChampion", robuxEligible = false, robuxProductId = 0,
		},
		Royal = {
			id = "Royal", displayName = "Royal Purple", dnaCost = 0, rarity = "Achievement", availability = "achievement",
			unlockType = "achievement", achievementId = "DnaLegend", robuxEligible = false, robuxProductId = 0,
		},
	},

	Eyes = {
		Default = { id = "Default", displayName = "Classic", dnaCost = 0, rarity = "Starter", availability = "always", robuxEligible = false, robuxProductId = 0 },
		Googly = { id = "Googly", displayName = "Googly", dnaCost = 125, rarity = "Common", availability = "always", robuxEligible = true, robuxProductId = 0 },
		Amber = { id = "Amber", displayName = "Amber", dnaCost = 275, rarity = "Uncommon", availability = "always", robuxEligible = true, robuxProductId = 0 },
		Neon = { id = "Neon", displayName = "Neon Blue", dnaCost = 600, rarity = "Epic", availability = "always", robuxEligible = true, robuxProductId = 0 },
		Emerald = { id = "Emerald", displayName = "Emerald", dnaCost = 850, rarity = "Rare", availability = "always", robuxEligible = false, robuxProductId = 0 },
		Crimson = { id = "Crimson", displayName = "Crimson", dnaCost = 1200, rarity = "Epic", availability = "always", robuxEligible = false, robuxProductId = 0 },
		Void = { id = "Void", displayName = "Void", dnaCost = 1800, rarity = "Epic", availability = "always", robuxEligible = false, robuxProductId = 0 },
		Solar = { id = "Solar", displayName = "Solar", dnaCost = 2500, rarity = "Legendary", availability = "always", robuxEligible = false, robuxProductId = 0 },
		VictoryGold = {
			id = "VictoryGold", displayName = "Victory Gold", dnaCost = 0, rarity = "Achievement", availability = "achievement",
			unlockType = "achievement", achievementId = "BackyardSurvivor", robuxEligible = false, robuxProductId = 0,
		},
		Bubblegum = {
			id = "Bubblegum", displayName = "Bubblegum", dnaCost = 0, rarity = "Achievement", availability = "achievement",
			unlockType = "achievement", achievementId = "YardRegular", robuxEligible = false, robuxProductId = 0,
		},
		Starshine = {
			id = "Starshine", displayName = "Starshine", dnaCost = 0, rarity = "Achievement", availability = "achievement",
			unlockType = "achievement", achievementId = "SeasonedSurvivor", robuxEligible = false, robuxProductId = 0,
		},
		Frost = {
			id = "Frost", displayName = "Frost", dnaCost = 0, rarity = "Achievement", availability = "achievement",
			unlockType = "achievement", achievementId = "YardVeteran", robuxEligible = false, robuxProductId = 0,
		},
	},

	Pattern = {
		None = { id = "None", displayName = "No Pattern", dnaCost = 0, rarity = "Starter", availability = "always", robuxEligible = false, robuxProductId = 0 },
		BackyardStripe = { id = "BackyardStripe", displayName = "Backyard Stripe", dnaCost = 225, rarity = "Uncommon", availability = "always", robuxEligible = true, robuxProductId = 0 },
		Speckles = { id = "Speckles", displayName = "Speckles", dnaCost = 450, rarity = "Rare", availability = "always", robuxEligible = true, robuxProductId = 0 },
		Sunmark = { id = "Sunmark", displayName = "Golden Mark", dnaCost = 900, rarity = "Epic", availability = "always", robuxEligible = true, robuxProductId = 0 },
		RacingBands = { id = "RacingBands", displayName = "Racing Bands", dnaCost = 1250, rarity = "Epic", availability = "always", robuxEligible = false, robuxProductId = 0 },
		Polka = { id = "Polka", displayName = "Polka Dots", dnaCost = 1800, rarity = "Epic", availability = "always", robuxEligible = false, robuxProductId = 0 },
		Webline = { id = "Webline", displayName = "Webline", dnaCost = 2600, rarity = "Legendary", availability = "always", robuxEligible = false, robuxProductId = 0 },
		CircuitTrace = { id = "CircuitTrace", displayName = "Circuit Trace", dnaCost = 4000, rarity = "Legendary", availability = "always", robuxEligible = false, robuxProductId = 0 },
	},

	Skin = {
		None = {
			id = "None", displayName = "No Skin", dnaCost = 0, rarity = "Starter", availability = "always",
			robuxOnly = false, robuxPassId = 0,
		},
		NeonCircuit = {
			id = "NeonCircuit", displayName = "Neon Circuit", dnaCost = 0, rarity = "Premium", availability = "robux",
			robuxOnly = true, robuxPassId = 0,
		},
		CandyPop = {
			id = "CandyPop", displayName = "Candy Pop", dnaCost = 0, rarity = "Premium", availability = "robux",
			robuxOnly = true, robuxPassId = 0,
		},
		Ember = {
			id = "Ember", displayName = "Ember", dnaCost = 0, rarity = "Premium", availability = "robux",
			robuxOnly = true, robuxPassId = 0,
		},
		SynthIdol = {
			id = "SynthIdol", displayName = "Synth Idol", dnaCost = 0, rarity = "Premium Character", availability = "robux",
			robuxOnly = true, robuxPassId = 0,
		},
	},
}

function CosmeticCatalog.GetItem(slot: string, itemId: string)
	local slotItems = CosmeticCatalog.Items[slot]
	return slotItems and slotItems[itemId] or nil
end

function CosmeticCatalog.GetSlot(slot: string)
	return CosmeticCatalog.Slots[slot]
end

function CosmeticCatalog.GetUnlockKey(slot: string, itemId: string): string
	return slot .. ":" .. itemId
end

function CosmeticCatalog.GetItemByRobuxProductId(productId: number)
	if productId <= 0 then
		return nil
	end

	for slot, slotItems in pairs(CosmeticCatalog.Items) do
		for itemId, item in pairs(slotItems) do
			if item.robuxProductId == productId then
				return slot, itemId, item
			end
		end
	end
	return nil
end

function CosmeticCatalog.GetItemByRobuxPassId(passId: number)
	if passId <= 0 then
		return nil
	end
	for slot, slotItems in pairs(CosmeticCatalog.Items) do
		for itemId, item in pairs(slotItems) do
			if item.robuxPassId == passId then
				return slot, itemId, item
			end
		end
	end
	return nil
end

function CosmeticCatalog.IsVisibleInAlwaysShop(slot: string, itemId: string): boolean
	local item = CosmeticCatalog.GetItem(slot, itemId)
	return item ~= nil and item.availability == "always"
end

return CosmeticCatalog
