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
}

function CosmeticStyles.IsValidBodyColor(styleId: string): boolean
	return CosmeticStyles.BodyColors[styleId] ~= nil
end

return CosmeticStyles
