--!strict

-- Commerce/progression metadata for cosmetics.
-- Visual appearance lives in CosmeticStyles. This catalog decides how an item is
-- earned, priced, surfaced, and eventually sold for Robux.
--
-- robuxProductId = 0 means the item is eligible for a future Developer Product,
-- but no live Roblox product has been configured yet.
-- availability = "always" is the current shop. "rotation" is reserved for a
-- future featured/limited-stock shop without changing ownership or rendering.

local CosmeticCatalog = {}

CosmeticCatalog.Slots = {
	BodyColor = {
		displayName = "Colors",
		order = { "Natural", "Ruby", "Moss", "Midnight" },
	},
	Eyes = {
		displayName = "Eyes",
		order = { "Default", "Googly", "Amber", "Neon" },
	},
	Pattern = {
		displayName = "Patterns",
		order = { "None", "BackyardStripe", "Speckles", "Sunmark" },
	},
}

CosmeticCatalog.Items = {
	BodyColor = {
		Natural = {
			id = "Natural",
			displayName = "Natural",
			dnaCost = 0,
			rarity = "Starter",
			availability = "always",
			robuxEligible = false,
			robuxProductId = 0,
		},
		Ruby = {
			id = "Ruby",
			displayName = "Ruby",
			dnaCost = 75,
			rarity = "Common",
			availability = "always",
			robuxEligible = true,
			robuxProductId = 0,
		},
		Moss = {
			id = "Moss",
			displayName = "Moss",
			dnaCost = 175,
			rarity = "Uncommon",
			availability = "always",
			robuxEligible = true,
			robuxProductId = 0,
		},
		Midnight = {
			id = "Midnight",
			displayName = "Midnight",
			dnaCost = 350,
			rarity = "Rare",
			availability = "always",
			robuxEligible = true,
			robuxProductId = 0,
		},
	},

	Eyes = {
		Default = {
			id = "Default",
			displayName = "Classic",
			dnaCost = 0,
			rarity = "Starter",
			availability = "always",
			robuxEligible = false,
			robuxProductId = 0,
		},
		Googly = {
			id = "Googly",
			displayName = "Googly",
			dnaCost = 125,
			rarity = "Common",
			availability = "always",
			robuxEligible = true,
			robuxProductId = 0,
		},
		Amber = {
			id = "Amber",
			displayName = "Amber",
			dnaCost = 275,
			rarity = "Uncommon",
			availability = "always",
			robuxEligible = true,
			robuxProductId = 0,
		},
		Neon = {
			id = "Neon",
			displayName = "Neon Blue",
			dnaCost = 600,
			rarity = "Epic",
			availability = "always",
			robuxEligible = true,
			robuxProductId = 0,
		},
	},

	Pattern = {
		None = {
			id = "None",
			displayName = "No Pattern",
			dnaCost = 0,
			rarity = "Starter",
			availability = "always",
			robuxEligible = false,
			robuxProductId = 0,
		},
		BackyardStripe = {
			id = "BackyardStripe",
			displayName = "Backyard Stripe",
			dnaCost = 225,
			rarity = "Uncommon",
			availability = "always",
			robuxEligible = true,
			robuxProductId = 0,
		},
		Speckles = {
			id = "Speckles",
			displayName = "Speckles",
			dnaCost = 450,
			rarity = "Rare",
			availability = "always",
			robuxEligible = true,
			robuxProductId = 0,
		},
		Sunmark = {
			id = "Sunmark",
			displayName = "Golden Mark",
			dnaCost = 900,
			rarity = "Epic",
			availability = "always",
			robuxEligible = true,
			robuxProductId = 0,
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

function CosmeticCatalog.IsVisibleInAlwaysShop(slot: string, itemId: string): boolean
	local item = CosmeticCatalog.GetItem(slot, itemId)
	return item ~= nil and item.availability == "always"
end

return CosmeticCatalog
