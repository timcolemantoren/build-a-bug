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
	Mint = {
		id = "Mint",
		displayName = "Mint",
		previewColor = Color3.fromRGB(101, 220, 167),
		body = Color3.fromRGB(72, 184, 136),
		dark = Color3.fromRGB(30, 91, 68),
		accent = Color3.fromRGB(143, 239, 190),
	},
	Royal = {
		id = "Royal",
		displayName = "Royal Purple",
		previewColor = Color3.fromRGB(113, 78, 188),
		body = Color3.fromRGB(86, 52, 157),
		dark = Color3.fromRGB(39, 24, 82),
		accent = Color3.fromRGB(157, 112, 230),
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
	Starshine = {
		id = "Starshine",
		displayName = "Starshine",
		previewColor = Color3.fromRGB(255, 245, 167),
		kind = "glow",
		color = Color3.fromRGB(255, 245, 167),
		sizeMultiplier = 1.34,
		material = Enum.Material.Neon,
	},
	Frost = {
		id = "Frost",
		displayName = "Frost",
		previewColor = Color3.fromRGB(175, 232, 255),
		kind = "glow",
		color = Color3.fromRGB(175, 232, 255),
		sizeMultiplier = 1.30,
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

-- Premium skins are full-body visual treatments. They intentionally live apart
-- from mix-and-match colors/eyes/patterns and never change gameplay stats.
CosmeticStyles.SkinStyles = {
	None = {
		id = "None",
		displayName = "No Skin",
		previewColor = Color3.fromRGB(80, 84, 80),
		kind = "none",
	},
	NeonCircuit = {
		id = "NeonCircuit",
		displayName = "Neon Circuit",
		previewColor = Color3.fromRGB(45, 226, 255),
		kind = "glow",
		body = Color3.fromRGB(30, 42, 58),
		dark = Color3.fromRGB(9, 17, 28),
		accent = Color3.fromRGB(50, 221, 255),
		glowColor = Color3.fromRGB(50, 221, 255),
	},
	CandyPop = {
		id = "CandyPop",
		displayName = "Candy Pop",
		previewColor = Color3.fromRGB(255, 117, 194),
		kind = "glow",
		body = Color3.fromRGB(240, 99, 171),
		dark = Color3.fromRGB(85, 54, 116),
		accent = Color3.fromRGB(91, 224, 238),
		glowColor = Color3.fromRGB(255, 157, 218),
	},
	Ember = {
		id = "Ember",
		displayName = "Ember",
		previewColor = Color3.fromRGB(255, 115, 45),
		kind = "glow",
		body = Color3.fromRGB(73, 44, 38),
		dark = Color3.fromRGB(27, 20, 21),
		accent = Color3.fromRGB(247, 91, 36),
		glowColor = Color3.fromRGB(255, 110, 40),
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

function CosmeticStyles.IsValidSkinStyle(styleId: string): boolean
	return CosmeticStyles.SkinStyles[styleId] ~= nil
end

function CosmeticStyles.GetStyle(slot: string, styleId: string)
	if slot == "BodyColor" then
		return CosmeticStyles.BodyColors[styleId]
	elseif slot == "Eyes" then
		return CosmeticStyles.EyeStyles[styleId]
	elseif slot == "Pattern" then
		return CosmeticStyles.PatternStyles[styleId]
	elseif slot == "Skin" then
		return CosmeticStyles.SkinStyles[styleId]
	end
	return nil
end

return CosmeticStyles
