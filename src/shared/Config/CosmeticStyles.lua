--!strict

-- Cosmetic-only visual styles shared by server and client.
-- These never change movement, health, damage, rewards, or abilities.

local CosmeticStyles = {}

CosmeticStyles.BodyColorOrder = {
	"Natural",
	"Ruby",
	"Moss",
	"Midnight",
}

CosmeticStyles.BodyColors = {
	Natural = {
		id = "Natural",
		displayName = "Natural",
		previewColor = Color3.fromRGB(118, 102, 76),
		useBugPalette = true,
		cost = 0,
	},
	Ruby = {
		id = "Ruby",
		displayName = "Ruby",
		previewColor = Color3.fromRGB(145, 61, 65),
		body = Color3.fromRGB(132, 50, 55),
		dark = Color3.fromRGB(67, 27, 31),
		accent = Color3.fromRGB(178, 78, 73),
		cost = 75,
	},
	Moss = {
		id = "Moss",
		displayName = "Moss",
		previewColor = Color3.fromRGB(91, 126, 70),
		body = Color3.fromRGB(73, 112, 62),
		dark = Color3.fromRGB(37, 64, 38),
		accent = Color3.fromRGB(126, 151, 83),
		cost = 175,
	},
	Midnight = {
		id = "Midnight",
		displayName = "Midnight",
		previewColor = Color3.fromRGB(67, 74, 105),
		body = Color3.fromRGB(48, 56, 82),
		dark = Color3.fromRGB(23, 27, 43),
		accent = Color3.fromRGB(91, 101, 142),
		cost = 350,
	},
}

CosmeticStyles.EyeStyleOrder = {
	"Default",
	"Googly",
	"Amber",
	"Neon",
}

CosmeticStyles.EyeStyles = {
	Default = {
		id = "Default",
		displayName = "Classic",
		previewColor = Color3.fromRGB(20, 20, 22),
		cost = 0,
		kind = "solid",
		color = Color3.fromRGB(16, 16, 18),
		sizeMultiplier = 1,
		material = Enum.Material.SmoothPlastic,
	},
	Googly = {
		id = "Googly",
		displayName = "Googly",
		previewColor = Color3.fromRGB(235, 235, 228),
		cost = 125,
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
		cost = 275,
		kind = "solid",
		color = Color3.fromRGB(226, 151, 45),
		sizeMultiplier = 1.12,
		material = Enum.Material.Neon,
	},
	Neon = {
		id = "Neon",
		displayName = "Neon Blue",
		previewColor = Color3.fromRGB(73, 205, 255),
		cost = 600,
		kind = "glow",
		color = Color3.fromRGB(73, 205, 255),
		sizeMultiplier = 1.18,
		material = Enum.Material.Neon,
	},
}

function CosmeticStyles.IsValidBodyColor(styleId: string): boolean
	return CosmeticStyles.BodyColors[styleId] ~= nil
end

function CosmeticStyles.IsValidEyeStyle(styleId: string): boolean
	return CosmeticStyles.EyeStyles[styleId] ~= nil
end

function CosmeticStyles.GetItem(slot: string, styleId: string)
	if slot == "BodyColor" then
		return CosmeticStyles.BodyColors[styleId]
	elseif slot == "Eyes" then
		return CosmeticStyles.EyeStyles[styleId]
	end
	return nil
end

function CosmeticStyles.GetUnlockKey(slot: string, styleId: string): string
	return slot .. ":" .. styleId
end

return CosmeticStyles
