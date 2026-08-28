--!strict

-- Cosmetic-only visual styles shared by server and client.
-- Prices, rarity, Robux products, and store availability live in CosmeticCatalog.
-- These styles never change movement, health, damage, rewards, or abilities.

local CosmeticStyles = {}

CosmeticStyles.BodyColors = {
	Natural = {
		id = "Natural",
		displayName = "Natural",
		previewColor = Color3.fromRGB(118, 102, 76),
		useBugPalette = true,
	},
	Ruby = {
		id = "Ruby",
		displayName = "Ruby",
		previewColor = Color3.fromRGB(145, 61, 65),
		body = Color3.fromRGB(132, 50, 55),
		dark = Color3.fromRGB(67, 27, 31),
		accent = Color3.fromRGB(178, 78, 73),
	},
	Moss = {
		id = "Moss",
		displayName = "Moss",
		previewColor = Color3.fromRGB(91, 126, 70),
		body = Color3.fromRGB(73, 112, 62),
		dark = Color3.fromRGB(37, 64, 38),
		accent = Color3.fromRGB(126, 151, 83),
	},
	Midnight = {
		id = "Midnight",
		displayName = "Midnight",
		previewColor = Color3.fromRGB(67, 74, 105),
		body = Color3.fromRGB(48, 56, 82),
		dark = Color3.fromRGB(23, 27, 43),
		accent = Color3.fromRGB(91, 101, 142),
	},
	Honey = {
		id = "Honey",
		displayName = "Honey",
		previewColor = Color3.fromRGB(225, 166, 61),
		body = Color3.fromRGB(202, 139, 42),
		dark = Color3.fromRGB(107, 70, 29),
		accent = Color3.fromRGB(245, 194, 83),
	},
	Electric = {
		id = "Electric",
		displayName = "Electric",
		previewColor = Color3.fromRGB(158, 91, 232),
		body = Color3.fromRGB(129, 67, 205),
		dark = Color3.fromRGB(59, 31, 103),
		accent = Color3.fromRGB(198, 116, 255),
	},
}

CosmeticStyles.EyeStyles = {
	Default = {
		id = "Default",
		displayName = "Classic",
		previewColor = Color3.fromRGB(20, 20, 22),
		kind = "solid",
		color = Color3.fromRGB(16, 16, 18),
		sizeMultiplier = 1,
		material = Enum.Material.SmoothPlastic,
	},
	Googly = {
		id = "Googly",
		displayName = "Googly",
		previewColor = Color3.fromRGB(235, 235, 228),
		kind = "googly",
		color = Color3.fromRGB(238, 238, 232),
		pupilColor = Color3.fromRGB(18, 18, 20),
		sizeMultiplier = 1.45,
		material = Enum.Material.SmoothPlastic,
	},
	Amber = {
		id = "Amber",
		displayName = "Amber",
		previewColor = Color3.fromRGB(226, 151, 45),
		kind = "solid",
		color = Color3.fromRGB(226, 151, 45),
		sizeMultiplier = 1.12,
		material = Enum.Material.Neon,
	},
	Neon = {
		id = "Neon",
		displayName = "Neon Blue",
		previewColor = Color3.fromRGB(73, 205, 255),
		kind = "glow",
		color = Color3.fromRGB(73, 205, 255),
		sizeMultiplier = 1.18,
		material = Enum.Material.Neon,
	},
	VictoryGold = {
		id = "VictoryGold",
		displayName = "Victory Gold",
		previewColor = Color3.fromRGB(255, 214, 65),
		kind = "glow",
		color = Color3.fromRGB(255, 214, 65),
		sizeMultiplier = 1.24,
		material = Enum.Material.Neon,
	},
	Bubblegum = {
		id = "Bubblegum",
		displayName = "Bubblegum",
		previewColor = Color3.fromRGB(255, 112, 190),
		kind = "solid",
		color = Color3.fromRGB(255, 112, 190),
		sizeMultiplier = 1.28,
		material = Enum.Material.Neon,
	},
}

CosmeticStyles.PatternStyles = {
	None = {
		id = "None",
		displayName = "No Pattern",
		previewColor = Color3.fromRGB(96, 96, 96),
		kind = "none",
	},
	BackyardStripe = {
		id = "BackyardStripe",
		displayName = "Backyard Stripe",
		previewColor = Color3.fromRGB(224, 209, 145),
		kind = "stripe",
		color = Color3.fromRGB(224, 209, 145),
	},
	Speckles = {
		id = "Speckles",
		displayName = "Speckles",
		previewColor = Color3.fromRGB(228, 226, 216),
		kind = "speckles",
		color = Color3.fromRGB(228, 226, 216),
	},
	Sunmark = {
		id = "Sunmark",
		displayName = "Golden Mark",
		previewColor = Color3.fromRGB(255, 190, 54),
		kind = "sunmark",
		color = Color3.fromRGB(255, 190, 54),
		material = Enum.Material.Neon,
	},
}

function CosmeticStyles.IsValidBodyColor(styleId: string): boolean
	return CosmeticStyles.BodyColors[styleId] ~= nil
end

function CosmeticStyles.IsValidEyeStyle(styleId: string): boolean
	return CosmeticStyles.EyeStyles[styleId] ~= nil
end

function CosmeticStyles.IsValidPatternStyle(styleId: string): boolean
	return CosmeticStyles.PatternStyles[styleId] ~= nil
end

function CosmeticStyles.GetStyle(slot: string, styleId: string)
	if slot == "BodyColor" then
		return CosmeticStyles.BodyColors[styleId]
	elseif slot == "Eyes" then
		return CosmeticStyles.EyeStyles[styleId]
	elseif slot == "Pattern" then
		return CosmeticStyles.PatternStyles[styleId]
	end
	return nil
end

return CosmeticStyles
