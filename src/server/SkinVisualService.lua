--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local CosmeticStyles = require(BuildABugShared.Config.CosmeticStyles)

local SkinVisualService = {}
local VISUAL_MODEL_NAME = "BuildABugVisual"

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
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("PointLight") and descendant.Name == "PremiumSkinGlow" then
			descendant:Destroy()
		end
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
				descendant.Color = style.accent or style.body
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

	local highlight = Instance.new("Highlight")
	highlight.Name = "PremiumSkinHighlight"
	highlight.FillColor = style.glowColor or style.accent or style.body
	highlight.OutlineColor = style.glowColor or style.accent or style.body
	highlight.FillTransparency = 0.88
	highlight.OutlineTransparency = 0.22
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = model

	local anchor = model:FindFirstChild("Thorax") or model:FindFirstChild("Pronotum") or model:FindFirstChildWhichIsA("BasePart")
	if anchor and anchor:IsA("BasePart") then
		local light = Instance.new("PointLight")
		light.Name = "PremiumSkinGlow"
		light.Color = style.glowColor or style.accent or style.body
		light.Brightness = 0.8
		light.Range = 6
		light.Parent = anchor
	end
end

local function watchCharacter(player: Player, character: Model)
	local function consider(child)
		if child:IsA("Model") and child.Name == VISUAL_MODEL_NAME then
			task.delay(0.18, function()
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
