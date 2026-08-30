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

local function addSynthIdolAccessories(model: Model, style)
	local head = model:FindFirstChild("Head", true)
	local body = model:FindFirstChild("Thorax", true) or model:FindFirstChild("Pronotum", true) or model:FindFirstChild("Shell", true)
	if not head or not head:IsA("BasePart") then
		return
	end

	local accent = style.accent or Color3.fromRGB(226, 65, 94)
	local secondary = style.secondary or Color3.fromRGB(71, 218, 222)
	local dark = style.dark or Color3.fromRGB(44, 43, 51)

	for _, side in ipairs({ -1, 1 }) do
		createAccessory(model, head, side < 0 and "HeadsetLeft" or "HeadsetRight", Enum.PartType.Ball, Vector3.new(0.42, 0.52, 0.42), CFrame.new(side * 0.68, 0.08, 0.02), dark, Enum.Material.SmoothPlastic)
		local glow = createAccessory(model, head, side < 0 and "HeadsetGlowLeft" or "HeadsetGlowRight", Enum.PartType.Ball, Vector3.new(0.24, 0.34, 0.24), CFrame.new(side * 0.75, 0.08, -0.06), secondary, Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Name = "PremiumSkinGlow"
		light.Color = secondary
		light.Brightness = 0.55
		light.Range = 3
		light.Parent = glow
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

	if body and body:IsA("BasePart") then
		createAccessory(model, body, "BowLeft", Enum.PartType.Ball, Vector3.new(0.48, 0.24, 0.42), CFrame.new(-0.28, 0.56, -0.48) * CFrame.Angles(0, 0, math.rad(28)), accent, Enum.Material.SmoothPlastic)
		createAccessory(model, body, "BowRight", Enum.PartType.Ball, Vector3.new(0.48, 0.24, 0.42), CFrame.new(0.28, 0.56, -0.48) * CFrame.Angles(0, 0, math.rad(-28)), accent, Enum.Material.SmoothPlastic)
		createAccessory(model, body, "BowJewel", Enum.PartType.Ball, Vector3.new(0.22, 0.22, 0.22), CFrame.new(0, 0.58, -0.66), secondary, Enum.Material.Neon)
	end
end

local function addToyboxSheriffAccessories(model: Model, style)
	local head = model:FindFirstChild("Head", true)
	local body = model:FindFirstChild("Thorax", true) or model:FindFirstChild("Pronotum", true) or model:FindFirstChild("Shell", true) or model:FindFirstChild("Abdomen", true)
	if not head or not head:IsA("BasePart") then
		return
	end

	local leather = style.body or Color3.fromRGB(154, 108, 62)
	local teal = style.dark or Color3.fromRGB(38, 72, 78)
	local scarf = style.accent or Color3.fromRGB(179, 62, 45)
	local brass = style.secondary or Color3.fromRGB(230, 184, 70)

	-- Oversized toy-western hat. The broad brim is the silhouette change that
	-- makes this read as a premium character skin from normal gameplay distance.
	createAccessory(
		model,
		head,
		"SheriffHatBrim",
		Enum.PartType.Cylinder,
		Vector3.new(0.10, 1.95, 1.55),
		CFrame.new(0, 0.70, 0.10) * CFrame.Angles(0, 0, math.rad(90)),
		leather,
		Enum.Material.Fabric
	)
	createAccessory(model, head, "SheriffHatCrown", Enum.PartType.Ball, Vector3.new(1.34, 0.76, 1.02), CFrame.new(0, 1.00, 0.12), leather, Enum.Material.Fabric)
	createAccessory(model, head, "SheriffHatBand", Enum.PartType.Ball, Vector3.new(1.20, 0.16, 0.94), CFrame.new(0, 0.84, 0.10), teal, Enum.Material.SmoothPlastic)

	if body and body:IsA("BasePart") then
		-- A chunky scarf and badge give the front of the bug an immediate character
		-- read without copying any specific film costume or branded insignia.
		createAccessory(model, body, "ScarfLeft", Enum.PartType.Ball, Vector3.new(0.56, 0.24, 0.40), CFrame.new(-0.27, 0.47, -0.55) * CFrame.Angles(0, 0, math.rad(24)), scarf, Enum.Material.Fabric)
		createAccessory(model, body, "ScarfRight", Enum.PartType.Ball, Vector3.new(0.56, 0.24, 0.40), CFrame.new(0.27, 0.47, -0.55) * CFrame.Angles(0, 0, math.rad(-24)), scarf, Enum.Material.Fabric)
		createAccessory(model, body, "ScarfKnot", Enum.PartType.Ball, Vector3.new(0.26, 0.26, 0.24), CFrame.new(0, 0.48, -0.70), scarf, Enum.Material.Fabric)
		createAccessory(model, body, "SheriffBadge", Enum.PartType.Ball, Vector3.new(0.34, 0.34, 0.10), CFrame.new(0.42, 0.50, -0.70), brass, Enum.Material.Metal)

		-- Wind-up key makes the skin read as a toy even when the hat is partly hidden
		-- by camera angle. It is intentionally generic toy imagery, not a pull-string
		-- or a recreation of a specific existing character prop.
		createAccessory(model, body, "WindupStem", Enum.PartType.Cylinder, Vector3.new(0.42, 0.10, 0.10), CFrame.new(0.78, 0.06, 0.52), brass, Enum.Material.Metal)
		createAccessory(model, body, "WindupKeyTop", Enum.PartType.Ball, Vector3.new(0.18, 0.48, 0.18), CFrame.new(1.01, 0.06, 0.52), brass, Enum.Material.Metal)
		createAccessory(model, body, "WindupKeyBottom", Enum.PartType.Ball, Vector3.new(0.18, 0.48, 0.18), CFrame.new(1.20, 0.06, 0.52), brass, Enum.Material.Metal)
	end
end

local function applySkinToModel(player: Player, model: Model)
	local styleId = player:GetAttribute("SkinStyle") or "None"
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
	end

	if not style.noGlow then
		local highlight = Instance.new("Highlight")
		highlight.Name = "PremiumSkinHighlight"
		highlight.FillColor = style.glowColor or style.accent or style.body
		highlight.OutlineColor = style.glowColor or style.accent or style.body
		highlight.FillTransparency = style.kind == "character" and 0.93 or 0.88
		highlight.OutlineTransparency = style.kind == "character" and 0.34 or 0.22
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = model

		local anchor = model:FindFirstChild("Thorax") or model:FindFirstChild("Pronotum") or model:FindFirstChildWhichIsA("BasePart")
		if anchor and anchor:IsA("BasePart") then
			local light = Instance.new("PointLight")
			light.Name = "PremiumSkinGlow"
			light.Color = style.glowColor or style.accent or style.body
			light.Brightness = style.kind == "character" and 0.55 or 0.8
			light.Range = 6
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
	player:GetAttributeChangedSignal("PatternStyle"):Connect(function()
		task.delay(0.42, refresh, player)
	end)
	player:GetAttributeChangedSignal("EyeStyle"):Connect(function()
		-- EyeDetailService can create the Cat Eye slit after the skin palette has been
		-- applied. Re-run shortly after to preserve skin colors without recoloring the
		-- separately-owned eye detail pieces.
		task.delay(0.44, refresh, player)
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
