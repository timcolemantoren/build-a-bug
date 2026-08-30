--!nonstrict

local Players = game:GetService("Players")

local UIThemeController = {}
local player = Players.LocalPlayer

local TARGET_GUIS = {
	BuildABugBugSelect = true,
	BuildABugProfile = true,
	BuildABugCollection = true,
	BuildABugPremiumSkins = true,
	BuildABugPurchaseConfirm = true,
	BuildABugRoundEnd = true,
}

local CREAM = Color3.fromRGB(250, 246, 232)
local PANEL_STROKE = Color3.fromRGB(117, 188, 151)
local BUTTON_STROKE = Color3.fromRGB(230, 220, 187)

local COLOR_MAP = {
	["31,37,34"] = Color3.fromRGB(25, 43, 48),
	["32,38,34"] = Color3.fromRGB(25, 43, 48),
	["30,36,32"] = Color3.fromRGB(25, 43, 48),
	["31,33,38"] = Color3.fromRGB(33, 38, 55),
	["40,47,42"] = Color3.fromRGB(41, 65, 60),
	["43,49,45"] = Color3.fromRGB(50, 72, 65),
	["46,49,47"] = Color3.fromRGB(57, 61, 69),
	["48,49,48"] = Color3.fromRGB(57, 61, 69),
	["50,56,51"] = Color3.fromRGB(48, 70, 65),
	["52,57,61"] = Color3.fromRGB(51, 64, 79),
	["55,62,58"] = Color3.fromRGB(49, 82, 72),
	["55,65,58"] = Color3.fromRGB(49, 82, 72),
	["58,65,61"] = Color3.fromRGB(56, 83, 76),
	["61,73,65"] = Color3.fromRGB(56, 87, 73),
	["63,52,76"] = Color3.fromRGB(82, 60, 105),
	["64,65,71"] = Color3.fromRGB(69, 76, 88),
	["64,73,65"] = Color3.fromRGB(58, 91, 78),
	["69,82,73"] = Color3.fromRGB(61, 101, 79),
	["73,92,82"] = Color3.fromRGB(72, 119, 93),
	["74,80,76"] = Color3.fromRGB(75, 88, 92),
	["74,103,76"] = Color3.fromRGB(77, 137, 91),
	["75,82,79"] = Color3.fromRGB(73, 90, 89),
	["78,53,92"] = Color3.fromRGB(113, 73, 142),
	["78,82,79"] = Color3.fromRGB(75, 88, 92),
	["78,101,79"] = Color3.fromRGB(73, 126, 86),
	["82,109,83"] = Color3.fromRGB(81, 143, 96),
	["99,69,119"] = Color3.fromRGB(126, 77, 154),
}

local bound = setmetatable({}, { __mode = "k" })
local applyingColor = setmetatable({}, { __mode = "k" })

local function rgbKey(color: Color3): string
	return string.format(
		"%d,%d,%d",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

local function addCorner(object: Instance, radius: number)
	if not object:IsA("GuiObject") or object:FindFirstChild("BuildABugThemeCorner") then
		return
	end
	local corner = Instance.new("UICorner")
	corner.Name = "BuildABugThemeCorner"
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
end

local function addStroke(object: Instance, panelStyle: boolean)
	if not object:IsA("GuiObject") or object:FindFirstChild("BuildABugThemeStroke") then
		return
	end
	local stroke = Instance.new("UIStroke")
	stroke.Name = "BuildABugThemeStroke"
	stroke.Color = panelStyle and PANEL_STROKE or BUTTON_STROKE
	stroke.Thickness = panelStyle and 1.5 or 1
	stroke.Transparency = panelStyle and 0.30 or 0.58
	stroke.Parent = object
end

local function remapBackground(object: GuiObject)
	if applyingColor[object] then
		return
	end
	local mapped = COLOR_MAP[rgbKey(object.BackgroundColor3)]
	if mapped then
		applyingColor[object] = true
		object.BackgroundColor3 = mapped
		applyingColor[object] = nil
	end
end

local function nearWhite(color: Color3): boolean
	return color.R > 0.88 and color.G > 0.88 and color.B > 0.88
end

local function styleObject(object: Instance)
	if not object:IsA("GuiObject") then
		return
	end

	if object:IsA("TextButton") then
		object.Font = Enum.Font.FredokaOne
		if nearWhite(object.TextColor3) then
			object.TextColor3 = CREAM
		end
		addCorner(object, 10)
		if object.BackgroundTransparency < 0.75 then
			addStroke(object, false)
		end
	elseif object:IsA("TextLabel") then
		if object.Font == Enum.Font.GothamBold or object.Font == Enum.Font.GothamBlack or object.TextSize >= 17 then
			object.Font = Enum.Font.FredokaOne
		elseif object.Font == Enum.Font.Gotham or object.Font == Enum.Font.GothamMedium then
			object.Font = Enum.Font.GothamMedium
		end
		if nearWhite(object.TextColor3) then
			object.TextColor3 = CREAM
		end
		if object.BackgroundTransparency < 0.6 then
			addCorner(object, 8)
		end
	elseif object:IsA("Frame") then
		if object.BackgroundTransparency < 0.55 and object.Name ~= "OverallFill" then
			local panelStyle = string.find(string.lower(object.Name), "panel") ~= nil
			addCorner(object, panelStyle and 14 or 8)
			if panelStyle then
				addStroke(object, true)
			end
		end
	end

	remapBackground(object)
	if not bound[object] then
		bound[object] = true
		object:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
			remapBackground(object)
		end)
	end
end

local function watchGui(gui: ScreenGui)
	for _, descendant in ipairs(gui:GetDescendants()) do
		styleObject(descendant)
	end
	gui.DescendantAdded:Connect(function(descendant)
		task.defer(styleObject, descendant)
	end)
end

function UIThemeController.Init()
	local playerGui = player:WaitForChild("PlayerGui")
	for _, child in ipairs(playerGui:GetChildren()) do
		if child:IsA("ScreenGui") and TARGET_GUIS[child.Name] then
			watchGui(child)
		end
	end
	playerGui.ChildAdded:Connect(function(child)
		if child:IsA("ScreenGui") and TARGET_GUIS[child.Name] then
			task.defer(watchGui, child)
		end
	end)
end

return UIThemeController
