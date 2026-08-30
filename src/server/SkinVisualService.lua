--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local CosmeticStyles = require(BuildABugShared.Config.CosmeticStyles)

local SkinVisualService = {}
local VISUAL_MODEL_NAME = "BuildABugVisual"
local ACCESSORY_PREFIX = "PremiumSkinAccessory"

local BODY_NAMES = {
	Thorax = true,
	Pronotum = true,
	Abdomen = true,
	Shell = true,
	ShellPlate = true,
	TailTip = true,
}
local DARK_NAMES = {
	Head = true,
	LegUpper = true,
	LegLower = true,
	Antenna = true,
	AntennaTip = true,
	ShellSeam = true,
}

local function rememberOriginal(part: BasePart)
	if part:GetAttribute("SkinOriginalR") ~= nil then
		return
	end
	part:SetAttribute("SkinOriginalR", part.Color.R)
	part:SetAttribute("SkinOriginalG", part.Color.G)
	part:SetAttribute("SkinOriginalB", part.Color.B)
	part:SetAttribute("SkinOriginalMaterial", part.Material.Name)
	part:SetAttribute("SkinOriginalTransparency", part.Transparency)
end

local function restorePart(part: BasePart)
	local r = part:GetAttribute("SkinOriginalR")
	local g = part:GetAttribute("SkinOriginalG")
	local b = part:GetAttribute("SkinOriginalB")
	if r ~= nil and g ~= nil and b ~= nil then
		part.Color = Color3.new(r, g, b)
	end
	local materialName = part:GetAttribute("SkinOriginalMaterial")
	if type(materialName) == "string" then
		pcall(function()
			part.Material = Enum.Material[materialName]
		end)
	end
	local transparency = part:GetAttribute("SkinOriginalTransparency")
	if type(transparency) == "number" then
		part.Transparency = transparency
	end
end

local function clearEffects(model: Model)
	local highlight = model:FindFirstChild("PremiumSkinHighlight")
	if highlight then
		highlight:Destroy()
	end
	local destroy = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("PointLight") and descendant.Name == "PremiumSkinGlow" then
			table.insert(destroy, descendant)
		elseif descendant:IsA("BasePart") and string.sub(descendant.Name, 1, #ACCESSORY_PREFIX) == ACCESSORY_PREFIX then
			table.insert(destroy, descendant)
		end
	end
	for _, descendant in ipairs(destroy) do
		if descendant.Parent then
			descendant:Destroy()
		end
	end
end

local function createAccessory(model: Model, anchor: BasePart, suffix: string, shape, size: Vector3, localFrame: CFrame, color: Color3, material, transparency: number?)
	local part = Instance.new("Part")
	part.Name = ACCESSORY_PREFIX .. suffix
	part.Shape = shape or Enum.PartType.Ball
	part.Size = size
	part.CFrame = anchor.CFrame * localFrame
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = anchor
	weld.Part1 = part
	weld.Parent = part
	return part
end

local function findPart(model: Model, names)
	for _, name in ipairs(names) do
		local part = model:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

local function getHead(model: Model)
	return findPart(model, { "Head" })
end

local function getBody(model: Model)
	return findPart(model, { "Thorax", "Pronotum", "Shell", "Abdomen", "ShellPlate" })
end

local function addSmallGlow(part: BasePart, color: Color3, brightness: number?, range: number?)
	local light = Instance.new("PointLight")
	light.Name = "PremiumSkinGlow"
	light.Color = color
	light.Brightness = brightness or 0.45
	light.Range = range or 3
	light.Parent = part
end

local function addSynthIdolAccessories(model: Model, style)
	local head = getHead(model)
	local body = getBody(model)
	if not head then
		return
	end

	local accent = style.accent or Color3.fromRGB(226, 65, 94)
	local secondary = style.secondary or Color3.fromRGB(71, 218, 222)
	local dark = style.dark or Color3.fromRGB(44, 43, 51)

	for _, side in ipairs({ -1, 1 }) do
		createAccessory(model, head, side < 0 and "HeadsetLeft" or "HeadsetRight", Enum.PartType.Ball, Vector3.new(0.42, 0.52, 0.42), CFrame.new(side * 0.68, 0.08, 0.02), dark, Enum.Material.SmoothPlastic)
		local glow = createAccessory(model, head, side < 0 and "HeadsetGlowLeft" or "HeadsetGlowRight", Enum.PartType.Ball, Vector3.new(0.24, 0.34, 0.24), CFrame.new(side * 0.75, 0.08, -0.06), secondary, Enum.Material.Neon)
		addSmallGlow(glow, secondary, 0.55, 3)
	end

	for _, side in ipairs({ -1, 1 }) do
		for index = 1, 5 do
			local size = 0.46 - ((index - 1) * 0.055)
			local x = side * (0.82 + (index * 0.13))
			local y = 0.52 - ((index - 1) * 0.15)
			local z = 0.20 + ((index - 1) * 0.13)
			createAccessory(model, head, (side < 0 and "TwirlL" or "TwirlR") .. tostring(index), Enum.PartType.Ball, Vector3.new(size, size * 0.82, size), CFrame.new(x, y, z), (index % 2 == 0) and secondary or accent, index % 2 == 0 and Enum.Material.Neon or Enum.Material.SmoothPlastic)
		end
	end

	if body then
		createAccessory(model, body, "BowLeft", Enum.PartType.Ball, Vector3.new(0.48, 0.24, 0.42), CFrame.new(-0.28, 0.56, -0.48) * CFrame.Angles(0, 0, math.rad(28)), accent, Enum.Material.SmoothPlastic)
		createAccessory(model, body, "BowRight", Enum.PartType.Ball, Vector3.new(0.48, 0.24, 0.42), CFrame.new(0.28, 0.56, -0.48) * CFrame.Angles(0, 0, math.rad(-28)), accent, Enum.Material.SmoothPlastic)
		createAccessory(model, body, "BowJewel", Enum.PartType.Ball, Vector3.new(0.22, 0.22, 0.22), CFrame.new(0, 0.58, -0.66), secondary, Enum.Material.Neon)
	end
end

local function addToyboxSheriffAccessories(model: Model, style)
	local head = getHead(model)
	local body = getBody(model)
	if not head then
		return
	end

	local shirt = style.body or Color3.fromRGB(218, 166, 63)
	local teal = style.dark or Color3.fromRGB(42, 91, 105)
	local scarf = style.accent or Color3.fromRGB(199, 61, 47)
	local brass = style.secondary or Color3.fromRGB(238, 194, 68)
	local leather = Color3.fromRGB(126, 79, 43)

	-- Wide, obviously western toy hat. The tall crown and oversized brim are
	-- intentionally exaggerated so it reads at bug-camera distance.
	createAccessory(model, head, "SheriffHatBrim", Enum.PartType.Cylinder, Vector3.new(0.12, 2.30, 1.72), CFrame.new(0, 0.76, 0.06) * CFrame.Angles(0, 0, math.rad(90)), leather, Enum.Material.Fabric)
	createAccessory(model, head, "SheriffHatCrown", Enum.PartType.Cylinder, Vector3.new(0.78, 1.28, 1.10), CFrame.new(0, 1.12, 0.10) * CFrame.Angles(0, 0, math.rad(90)), leather, Enum.Material.Fabric)
	createAccessory(model, head, "SheriffHatBand", Enum.PartType.Cylinder, Vector3.new(0.14, 1.34, 1.14), CFrame.new(0, 0.91, 0.10) * CFrame.Angles(0, 0, math.rad(90)), teal, Enum.Material.Fabric)
	createAccessory(model, head, "SheriffHatFront", Enum.PartType.Ball, Vector3.new(0.62, 0.20, 0.18), CFrame.new(0, 1.10, -0.52), brass, Enum.Material.SmoothPlastic)

	if body then
		-- Bright toy vest panels make the western read much stronger than the old
		-- muted coat-like treatment.
		createAccessory(model, body, "VestLeft", Enum.PartType.Ball, Vector3.new(0.60, 0.18, 0.76), CFrame.new(-0.38, 0.52, -0.42) * CFrame.Angles(0, 0, math.rad(14)), teal, Enum.Material.Fabric)
		createAccessory(model, body, "VestRight", Enum.PartType.Ball, Vector3.new(0.60, 0.18, 0.76), CFrame.new(0.38, 0.52, -0.42) * CFrame.Angles(0, 0, math.rad(-14)), teal, Enum.Material.Fabric)
		createAccessory(model, body, "ScarfLeft", Enum.PartType.Ball, Vector3.new(0.60, 0.24, 0.42), CFrame.new(-0.27, 0.60, -0.62) * CFrame.Angles(0, 0, math.rad(28)), scarf, Enum.Material.Fabric)
		createAccessory(model, body, "ScarfRight", Enum.PartType.Ball, Vector3.new(0.60, 0.24, 0.42), CFrame.new(0.27, 0.60, -0.62) * CFrame.Angles(0, 0, math.rad(-28)), scarf, Enum.Material.Fabric)
		createAccessory(model, body, "ScarfKnot", Enum.PartType.Ball, Vector3.new(0.28, 0.28, 0.24), CFrame.new(0, 0.61, -0.78), scarf, Enum.Material.Fabric)

		local badge = createAccessory(model, body, "SheriffBadge", Enum.PartType.Ball, Vector3.new(0.36, 0.36, 0.10), CFrame.new(0.42, 0.60, -0.76), brass, Enum.Material.Metal)
		createAccessory(model, badge, "BadgePointV", Enum.PartType.Block, Vector3.new(0.10, 0.46, 0.08), CFrame.new(0, 0, -0.05), brass, Enum.Material.Metal)
		createAccessory(model, badge, "BadgePointH", Enum.PartType.Block, Vector3.new(0.46, 0.10, 0.08), CFrame.new(0, 0, -0.05), brass, Enum.Material.Metal)

		createAccessory(model, body, "WindupStem", Enum.PartType.Cylinder, Vector3.new(0.44, 0.10, 0.10), CFrame.new(0.82, 0.06, 0.54), brass, Enum.Material.Metal)
		createAccessory(model, body, "WindupKeyTop", Enum.PartType.Ball, Vector3.new(0.18, 0.50, 0.18), CFrame.new(1.06, 0.06, 0.54), brass, Enum.Material.Metal)
		createAccessory(model, body, "WindupKeyBottom", Enum.PartType.Ball, Vector3.new(0.18, 0.50, 0.18), CFrame.new(1.26, 0.06, 0.54), brass, Enum.Material.Metal)
		createAccessory(model, body, "ToyButton", Enum.PartType.Ball, Vector3.new(0.16, 0.16, 0.10), CFrame.new(0, 0.55, -0.74), shirt, Enum.Material.SmoothPlastic)
	end
end

local function addNeonCircuitAccessories(model: Model, style)
	local head = getHead(model)
	local body = getBody(model)
	local cyan = style.accent or Color3.fromRGB(48, 226, 255)
	local violet = style.secondary or Color3.fromRGB(145, 90, 255)
	if head then
		local visor = createAccessory(model, head, "CyberVisor", Enum.PartType.Block, Vector3.new(1.10, 0.18, 0.16), CFrame.new(0, 0.18, -0.58), cyan, Enum.Material.Neon)
		addSmallGlow(visor, cyan, 0.45, 3)
		for _, side in ipairs({ -1, 1 }) do
			createAccessory(model, head, side < 0 and "CyberNodeL" or "CyberNodeR", Enum.PartType.Ball, Vector3.new(0.24, 0.24, 0.24), CFrame.new(side * 0.62, 0.34, -0.22), violet, Enum.Material.Neon)
		end
	end
	if body then
		for _, side in ipairs({ -1, 1 }) do
			createAccessory(model, body, side < 0 and "ArmorFinL" or "ArmorFinR", Enum.PartType.Block, Vector3.new(0.20, 0.62, 0.88), CFrame.new(side * 0.72, 0.22, 0.16) * CFrame.Angles(0, 0, math.rad(side * 18)), style.dark or Color3.fromRGB(8, 15, 26), Enum.Material.Metal)
		end
		local core = createAccessory(model, body, "CyberCore", Enum.PartType.Ball, Vector3.new(0.34, 0.34, 0.18), CFrame.new(0, 0.64, -0.34), cyan, Enum.Material.Neon)
		addSmallGlow(core, cyan, 0.65, 4)
	end
end

local function addCandyPopAccessories(model: Model, style)
	local head = getHead(model)
	local body = getBody(model)
	local pink = style.body or Color3.fromRGB(241, 105, 176)
	local aqua = style.accent or Color3.fromRGB(91, 224, 238)
	local yellow = style.secondary or Color3.fromRGB(255, 220, 91)
	if head then
		for _, side in ipairs({ -1, 1 }) do
			createAccessory(model, head, side < 0 and "CandyAntennaL" or "CandyAntennaR", Enum.PartType.Ball, Vector3.new(0.42, 0.42, 0.42), CFrame.new(side * 0.70, 0.66, -0.02), side < 0 and aqua or yellow, Enum.Material.Neon)
			createAccessory(model, head, side < 0 and "CandyStickL" or "CandyStickR", Enum.PartType.Cylinder, Vector3.new(0.48, 0.08, 0.08), CFrame.new(side * 0.52, 0.48, 0.00) * CFrame.Angles(0, 0, math.rad(side * 35)), Color3.fromRGB(247, 241, 226), Enum.Material.SmoothPlastic)
		end
	end
	if body then
		createAccessory(model, body, "CandyBowLeft", Enum.PartType.Ball, Vector3.new(0.62, 0.30, 0.52), CFrame.new(-0.32, 0.62, -0.52) * CFrame.Angles(0, 0, math.rad(25)), pink, Enum.Material.SmoothPlastic)
		createAccessory(model, body, "CandyBowRight", Enum.PartType.Ball, Vector3.new(0.62, 0.30, 0.52), CFrame.new(0.32, 0.62, -0.52) * CFrame.Angles(0, 0, math.rad(-25)), aqua, Enum.Material.SmoothPlastic)
		createAccessory(model, body, "CandyBowCenter", Enum.PartType.Ball, Vector3.new(0.28, 0.28, 0.28), CFrame.new(0, 0.64, -0.68), yellow, Enum.Material.Neon)
		for index, offset in ipairs({ -0.48, 0, 0.48 }) do
			createAccessory(model, body, "CandyCharm" .. tostring(index), Enum.PartType.Ball, Vector3.new(0.18, 0.18, 0.18), CFrame.new(offset, 0.70, 0.22), (index == 1 and aqua) or (index == 2 and yellow) or pink, Enum.Material.Neon)
		end
	end
end

local function addEmberAccessories(model: Model, style)
	local head = getHead(model)
	local body = getBody(model)
	local orange = style.accent or Color3.fromRGB(249, 83, 32)
	local gold = style.secondary or Color3.fromRGB(255, 186, 55)
	if head then
		for index, x in ipairs({ -0.30, 0, 0.30 }) do
			local height = index == 2 and 0.94 or 0.68
			local flame = createAccessory(model, head, "FlameCrest" .. tostring(index), Enum.PartType.Ball, Vector3.new(0.24, height, 0.24), CFrame.new(x, 0.72 + height * 0.25, 0.04) * CFrame.Angles(0, 0, math.rad((index - 2) * 18)), index == 2 and gold or orange, Enum.Material.Neon)
			if index == 2 then
				addSmallGlow(flame, orange, 0.55, 4)
			end
		end
	end
	if body then
		for index, z in ipairs({ -0.28, 0.20, 0.68 }) do
			createAccessory(model, body, "EmberSpine" .. tostring(index), Enum.PartType.Ball, Vector3.new(0.22, 0.62, 0.22), CFrame.new(0, 0.72, z), index % 2 == 0 and gold or orange, Enum.Material.Neon)
		end
	end
end

local function addShadowNinjaAccessories(model: Model, style)
	local head = getHead(model)
	local body = getBody(model)
	local red = style.accent or Color3.fromRGB(184, 48, 58)
	local steel = style.secondary or Color3.fromRGB(164, 176, 190)
	local dark = style.dark or Color3.fromRGB(18, 20, 27)
	if head then
		createAccessory(model, head, "NinjaMask", Enum.PartType.Ball, Vector3.new(1.18, 0.44, 0.46), CFrame.new(0, -0.15, -0.42), dark, Enum.Material.Fabric)
		createAccessory(model, head, "NinjaHeadband", Enum.PartType.Ball, Vector3.new(1.28, 0.18, 0.46), CFrame.new(0, 0.48, -0.14), red, Enum.Material.Fabric)
		createAccessory(model, head, "NinjaPlate", Enum.PartType.Block, Vector3.new(0.48, 0.22, 0.08), CFrame.new(0, 0.48, -0.52), steel, Enum.Material.Metal)
	end
	if body then
		for _, side in ipairs({ -1, 1 }) do
			createAccessory(model, body, side < 0 and "NinjaGuardL" or "NinjaGuardR", Enum.PartType.Ball, Vector3.new(0.46, 0.22, 0.64), CFrame.new(side * 0.58, 0.42, -0.18), dark, Enum.Material.SmoothPlastic)
			createAccessory(model, body, side < 0 and "ScarfTailL" or "ScarfTailR", Enum.PartType.Ball, Vector3.new(0.30, 0.18, 1.12), CFrame.new(side * 0.28, 0.38, 0.78) * CFrame.Angles(math.rad(side * 8), 0, math.rad(side * 18)), red, Enum.Material.Fabric)
		end
	end
end

local function addBloomSpriteAccessories(model: Model, style)
	local head = getHead(model)
	local body = getBody(model)
	local pink = style.accent or Color3.fromRGB(239, 130, 188)
	local gold = style.secondary or Color3.fromRGB(255, 221, 103)
	local leaf = style.body or Color3.fromRGB(116, 180, 108)
	if head then
		local petals = {
			{ -0.56, 0.58, 0.02 }, { -0.28, 0.78, -0.04 }, { 0, 0.86, -0.06 }, { 0.28, 0.78, -0.04 }, { 0.56, 0.58, 0.02 },
		}
		for index, p in ipairs(petals) do
			createAccessory(model, head, "Petal" .. tostring(index), Enum.PartType.Ball, Vector3.new(0.36, 0.56, 0.24), CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(0, 0, math.rad((index - 3) * 16)), index == 3 and gold or pink, Enum.Material.SmoothPlastic)
		end
	end
	if body then
		for _, side in ipairs({ -1, 1 }) do
			createAccessory(model, body, side < 0 and "GardenWingUpperL" or "GardenWingUpperR", Enum.PartType.Ball, Vector3.new(0.72, 0.16, 1.18), CFrame.new(side * 0.72, 0.42, 0.18) * CFrame.Angles(math.rad(12), 0, math.rad(side * 24)), Color3.fromRGB(255, 204, 231), Enum.Material.Glass, 0.28)
			createAccessory(model, body, side < 0 and "GardenWingLowerL" or "GardenWingLowerR", Enum.PartType.Ball, Vector3.new(0.58, 0.14, 0.90), CFrame.new(side * 0.64, 0.28, 0.62) * CFrame.Angles(math.rad(-8), 0, math.rad(side * 34)), Color3.fromRGB(190, 236, 176), Enum.Material.Glass, 0.30)
		end
		local jewel = createAccessory(model, body, "FlowerJewel", Enum.PartType.Ball, Vector3.new(0.28, 0.28, 0.20), CFrame.new(0, 0.66, -0.50), gold, Enum.Material.Neon)
		addSmallGlow(jewel, pink, 0.40, 3)
		createAccessory(model, body, "LeafCharm", Enum.PartType.Ball, Vector3.new(0.34, 0.16, 0.52), CFrame.new(0, 0.54, -0.24), leaf, Enum.Material.SmoothPlastic)
	end
end

local function addMechaPilotAccessories(model: Model, style)
	local head = getHead(model)
	local body = getBody(model)
	local cyan = style.accent or Color3.fromRGB(69, 211, 229)
	local gold = style.secondary or Color3.fromRGB(245, 191, 66)
	local metal = style.body or Color3.fromRGB(84, 98, 112)
	local dark = style.dark or Color3.fromRGB(31, 38, 48)
	if head then
		local visor = createAccessory(model, head, "MechaVisor", Enum.PartType.Block, Vector3.new(1.18, 0.24, 0.14), CFrame.new(0, 0.18, -0.58), cyan, Enum.Material.Neon)
		addSmallGlow(visor, cyan, 0.48, 3)
		createAccessory(model, head, "MechaBrow", Enum.PartType.Block, Vector3.new(1.30, 0.16, 0.32), CFrame.new(0, 0.48, -0.30), dark, Enum.Material.Metal)
	end
	if body then
		for _, side in ipairs({ -1, 1 }) do
			createAccessory(model, body, side < 0 and "ShoulderArmorL" or "ShoulderArmorR", Enum.PartType.Ball, Vector3.new(0.54, 0.32, 0.72), CFrame.new(side * 0.68, 0.42, -0.10), metal, Enum.Material.Metal)
			createAccessory(model, body, side < 0 and "ShoulderLightL" or "ShoulderLightR", Enum.PartType.Ball, Vector3.new(0.18, 0.18, 0.18), CFrame.new(side * 0.72, 0.58, -0.26), gold, Enum.Material.Neon)
		end
		local core = createAccessory(model, body, "MechaCore", Enum.PartType.Ball, Vector3.new(0.36, 0.36, 0.18), CFrame.new(0, 0.66, -0.48), cyan, Enum.Material.Neon)
		addSmallGlow(core, cyan, 0.60, 4)
		createAccessory(model, body, "BackPack", Enum.PartType.Block, Vector3.new(0.72, 0.40, 0.54), CFrame.new(0, 0.30, 0.58), dark, Enum.Material.Metal)
	end
end

local function activeStyleId(player: Player): string
	if player:GetAttribute("InRound") ~= true then
		local preview = player:GetAttribute("PreviewSkinStyle")
		if type(preview) == "string" and preview ~= "" then
			return preview
		end
	end
	return player:GetAttribute("SkinStyle") or "None"
end

local function applySkinToModel(player: Player, model: Model)
	local styleId = activeStyleId(player)
	local style = CosmeticStyles.SkinStyles[styleId] or CosmeticStyles.SkinStyles.None
	clearEffects(model)

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			rememberOriginal(descendant)
			restorePart(descendant)
		end
	end

	if styleId == "None" or style.kind == "none" then
		return
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local name = descendant.Name
			if name == "Eye" or name == "EyePupil" or name == "LadybugSpot" or string.find(name, "Pattern") or string.find(name, "EyeDetail") then
				-- Preserve separately-selected eyes and markings.
			elseif string.find(name, "Wing") then
				descendant.Color = style.secondary or style.accent or style.body
				descendant.Material = style.wingMaterial or (style.noGlow and Enum.Material.Glass or Enum.Material.Neon)
				descendant.Transparency = math.max(descendant.Transparency, 0.18)
			elseif DARK_NAMES[name] then
				descendant.Color = style.dark or style.body
				if style.darkMaterial then
					descendant.Material = style.darkMaterial
				end
			elseif BODY_NAMES[name] then
				descendant.Color = style.body or descendant.Color
				if style.bodyMaterial then
					descendant.Material = style.bodyMaterial
				end
			else
				descendant.Color = style.accent or style.body or descendant.Color
			end
		end
	end

	if style.accessory == "synthIdol" then
		addSynthIdolAccessories(model, style)
	elseif style.accessory == "toyboxSheriff" then
		addToyboxSheriffAccessories(model, style)
	elseif style.accessory == "neonCircuit" then
		addNeonCircuitAccessories(model, style)
	elseif style.accessory == "candyPop" then
		addCandyPopAccessories(model, style)
	elseif style.accessory == "ember" then
		addEmberAccessories(model, style)
	elseif style.accessory == "shadowNinja" then
		addShadowNinjaAccessories(model, style)
	elseif style.accessory == "bloomSprite" then
		addBloomSpriteAccessories(model, style)
	elseif style.accessory == "mechaPilot" then
		addMechaPilotAccessories(model, style)
	end

	if not style.noGlow then
		local highlight = Instance.new("Highlight")
		highlight.Name = "PremiumSkinHighlight"
		highlight.FillColor = style.glowColor or style.accent or style.body
		highlight.OutlineColor = style.glowColor or style.accent or style.body
		highlight.FillTransparency = 0.94
		highlight.OutlineTransparency = 0.35
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = model

		local anchor = getBody(model) or model:FindFirstChildWhichIsA("BasePart")
		if anchor then
			local light = Instance.new("PointLight")
			light.Name = "PremiumSkinGlow"
			light.Color = style.glowColor or style.accent or style.body
			light.Brightness = 0.40
			light.Range = 5
			light.Parent = anchor
		end
	end
end

local function watchCharacter(player: Player, character: Model)
	local function consider(child)
		if child:IsA("Model") and child.Name == VISUAL_MODEL_NAME then
			task.delay(0.36, function()
				if child.Parent then
					applySkinToModel(player, child)
				end
			end)
		end
	end
	local current = character:FindFirstChild(VISUAL_MODEL_NAME)
	if current then
		consider(current)
	end
	character.ChildAdded:Connect(consider)
end

local function refresh(player: Player)
	local character = player.Character
	local visual = character and character:FindFirstChild(VISUAL_MODEL_NAME)
	if visual and visual:IsA("Model") then
		applySkinToModel(player, visual)
	end
end

local function setupPlayer(player: Player)
	player:GetAttributeChangedSignal("SkinStyle"):Connect(function()
		task.defer(refresh, player)
	end)
	player:GetAttributeChangedSignal("PreviewSkinStyle"):Connect(function()
		task.defer(refresh, player)
	end)
	player:GetAttributeChangedSignal("PatternStyle"):Connect(function()
		task.delay(0.42, refresh, player)
	end)
	player:GetAttributeChangedSignal("EyeStyle"):Connect(function()
		task.delay(0.44, refresh, player)
	end)
	player:GetAttributeChangedSignal("InRound"):Connect(function()
		task.defer(refresh, player)
	end)
	player.CharacterAdded:Connect(function(character)
		watchCharacter(player, character)
	end)
	if player.Character then
		watchCharacter(player, player.Character)
	end
end

function SkinVisualService.Init()
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)
end

return SkinVisualService
