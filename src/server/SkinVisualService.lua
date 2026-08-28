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

	-- Headset ear pieces make the skin read as a character treatment even from
	-- the low insect camera. They are intentionally chunky and toy-like.
	for _, side in ipairs({ -1, 1 }) do
		createAccessory(
			model,
			head,
			side < 0 and "HeadsetLeft" or "HeadsetRight",
			Enum.PartType.Ball,
			Vector3.new(0.42, 0.52, 0.42),
			CFrame.new(side * 0.68, 0.08, 0.02),
			dark,
			Enum.Material.SmoothPlastic
		)
		local glow = createAccessory(
			model,
			head,
			side < 0 and "HeadsetGlowLeft" or "HeadsetGlowRight",
			Enum.PartType.Ball,
			Vector3.new(0.24, 0.34, 0.24),
			CFrame.new(side * 0.75, 0.08, -0.06),
			secondary,
			Enum.Material.Neon
		)
		local light = Instance.new("PointLight")
		light.Name = "PremiumSkinGlow"
		light.Color = secondary
		light.Brightness = 0.55
		light.Range = 3
		light.Parent = glow
	end

	-- Twin spiral ornaments borrow the playful virtual-idol silhouette without
	-- reproducing a specific character. The shrinking beads create a drill/twirl
	-- shape that stays readable across every bug head size.
	for _, side in ipairs({ -1, 1 }) do
		for index = 1, 5 do
			local size = 0.46 - ((index - 1) * 0.055)
			local x = side * (0.82 + (index * 0.13))
			local y = 0.52 - ((index - 1) * 0.15)
			local z = 0.20 + ((index - 1) * 0.13)
			createAccessory(
				model,
				head,
				(side < 0 and "TwirlL" or "TwirlR") .. tostring(index),
				Enum.PartType.Ball,
				Vector3.new(size, size * 0.82, size),
				CFrame.new(x, y, z),
				(index % 2 == 0) and secondary or accent,
				index % 2 == 0 and Enum.Material.Neon or Enum.Material.SmoothPlastic
			)
		end
	end

	-- Small chest bow/jewel gives the treatment a front-facing focal detail.
	if body and body:IsA("BasePart") then
		createAccessory(model, body, "BowLeft", Enum.PartType.Ball, Vector3.new(0.48, 0.24, 0.42), CFrame.new(-0.28, 0.56, -0.48) * CFrame.Angles(0, 0, math.rad(28)), accent, Enum.Material.SmoothPlastic)
		createAccessory(model, body, "BowRight", Enum.PartType.Ball, Vector3.new(0.48, 0.24, 0.42), CFrame.new(0.28, 0.56, -0.48) * CFrame.Angles(0, 0, math.rad(-28)), accent, Enum.Material.SmoothPlastic)
		createAccessory(model, body, "BowJewel", Enum.PartType.Ball, Vector3.new(0.22, 0.22, 0.22), CFrame.new(0, 0.58, -0.66), secondary, Enum.Material.Neon)
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
			if name == "Eye" or name == "EyePupil" or name == "LadybugSpot" or string.find(name, "Pattern") then
				-- Preserve separately-selected eyes and markings.
			elseif string.find(name, "Wing") then
				descendant.Color = style.secondary or style.accent or style.body
				descendant.Material = Enum.Material.Neon
				descendant.Transparency = math.max(descendant.Transparency, 0.18)
			elseif DARK_NAMES[name] then
				descendant.Color = style.dark or style.body
			elseif BODY_NAMES[name] then
				descendant.Color = style.body or descendant.Color
			else
				descendant.Color = style.accent or style.body or descendant.Color
			end
		end
	end

	if style.accessory == "synthIdol" then
		addSynthIdolAccessories(model, style)
	end

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
		-- PatternVisualService can recreate markings after the skin was first applied.
		-- Reapply the premium palette shortly after so any new body parts remain clean.
		task.delay(0.42, refresh, player)
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
