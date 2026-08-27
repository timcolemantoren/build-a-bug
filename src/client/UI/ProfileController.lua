--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local CosmeticStyles = require(BuildABugShared.Config.CosmeticStyles)

local ProfileController = {}

local player = Players.LocalPlayer
local gui = nil
local openButton = nil
local panel = nil
local inRound = false
local expanded = false
local currentData = nil
local selectedBodyColor = player:GetAttribute("BodyColor") or "Natural"
local colorCards = {}

local nameLabel = nil
local progressLabel = nil
local currencyLabel = nil
local statsLabel = nil
local bugLabel = nil

local DEFAULT_CARD = Color3.fromRGB(55, 62, 58)
local SELECTED_CARD = Color3.fromRGB(74, 103, 76)

local function formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds or 0))
	if seconds <= 0 then
		return "--"
	end
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function makeText(parent: Instance, name: string, text: string, position: UDim2, size: UDim2, textSize: number, bold: boolean?): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(245, 247, 245)
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.TextSize = textSize
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function refreshColorCards()
	for styleId, card in pairs(colorCards) do
		local selected = styleId == selectedBodyColor
		card.button.BackgroundColor3 = selected and SELECTED_CARD or DEFAULT_CARD
		card.stroke.Color = selected and Color3.fromRGB(143, 181, 137) or Color3.fromRGB(91, 99, 93)
		card.stroke.Thickness = selected and 2 or 1
		card.label.Text = selected and ("SELECTED\n" .. card.displayName) or card.displayName
	end
end

local function refreshProfile()
	local data = currentData or {}
	local currency = data.currency or {}
	local stats = data.stats or {}
	local progression = data.progression or {}
	local current = progression.current or {}

	local level = current.level or player:GetAttribute("BugLevel") or 1
	local title = current.title or player:GetAttribute("BugTitle") or "Fresh Hatchling"
	local dna = currency.dna or player:GetAttribute("TotalDna") or 0
	local crumbs = currency.crumbs or player:GetAttribute("TotalCrumbs") or 0
	local rounds = stats.roundsPlayed or player:GetAttribute("RoundsPlayed") or 0
	local best = stats.longestSurvival or player:GetAttribute("BestSurvival") or 0
	local food = stats.foodCollected or player:GetAttribute("FoodCollected") or 0
	local bugId = data.selectedBug or player:GetAttribute("SelectedBug") or "Ant"
	local cosmetics = data.cosmetics or {}
	selectedBodyColor = cosmetics.bodyColor or player:GetAttribute("BodyColor") or selectedBodyColor

	if nameLabel then
		nameLabel.Text = player.DisplayName
	end
	if progressLabel then
		progressLabel.Text = string.format("Level %s • %s", tostring(level), tostring(title))
	end
	if currencyLabel then
		currencyLabel.Text = string.format("DNA: %s    Crumbs: %s", tostring(dna), tostring(crumbs))
	end
	if statsLabel then
		statsLabel.Text = string.format("Rounds: %s    Best: %s    Food: %s", tostring(rounds), formatTime(best), tostring(food))
	end
	if bugLabel then
		bugLabel.Text = "Current bug: " .. tostring(bugId)
	end

	refreshColorCards()
end

local function applyVisibility()
	if openButton then
		openButton.Visible = not inRound and not expanded
	end
	if panel then
		panel.Visible = not inRound and expanded
	end
end

local function ensureGui(remotes)
	if gui then
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "BuildABugProfile"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6
	gui.Parent = player:WaitForChild("PlayerGui")

	openButton = Instance.new("TextButton")
	openButton.Name = "OpenProfile"
	openButton.Size = UDim2.fromOffset(110, 36)
	openButton.Position = UDim2.new(0.5, -55, 0, 14)
	openButton.BackgroundColor3 = Color3.fromRGB(55, 65, 58)
	openButton.BackgroundTransparency = 0.08
	openButton.Text = "Profile"
	openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	openButton.Font = Enum.Font.GothamBold
	openButton.TextSize = 15
	openButton.Parent = gui
	openButton.MouseButton1Click:Connect(function()
		if inRound then
			return
		end
		expanded = true
		refreshProfile()
		applyVisibility()
	end)

	panel = Instance.new("Frame")
	panel.Name = "ProfilePanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Size = UDim2.new(0.90, 0, 0.86, 0)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(31, 37, 34)
	panel.BackgroundTransparency = 0.04
	panel.Parent = gui

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(500, 430)
	sizeConstraint.MinSize = Vector2.new(320, 300)
	sizeConstraint.Parent = panel

	makeText(panel, "Title", "Profile / Customize", UDim2.fromOffset(18, 8), UDim2.new(1, -118, 0, 38), 20, true)

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.fromOffset(76, 34)
	closeButton.Position = UDim2.new(1, -90, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(78, 82, 79)
	closeButton.Text = "Close"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 14
	closeButton.Parent = panel
	closeButton.MouseButton1Click:Connect(function()
		expanded = false
		applyVisibility()
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "ProfileScroll"
	scroll.Position = UDim2.fromOffset(0, 50)
	scroll.Size = UDim2.new(1, 0, 1, -58)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.fromOffset(0, 430)
	scroll.ScrollBarThickness = 4
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = panel

	nameLabel = makeText(scroll, "PlayerName", player.DisplayName, UDim2.fromOffset(18, 0), UDim2.new(1, -36, 0, 30), 18, true)
	progressLabel = makeText(scroll, "Progress", "Level 1 • Fresh Hatchling", UDim2.fromOffset(18, 28), UDim2.new(1, -36, 0, 26), 14, true)
	currencyLabel = makeText(scroll, "Currency", "DNA: 0    Crumbs: 0", UDim2.fromOffset(18, 56), UDim2.new(1, -36, 0, 24), 13, false)
	statsLabel = makeText(scroll, "Stats", "Rounds: 0    Best: --    Food: 0", UDim2.fromOffset(18, 82), UDim2.new(1, -36, 0, 28), 13, false)
	bugLabel = makeText(scroll, "Bug", "Current bug: Ant", UDim2.fromOffset(18, 112), UDim2.new(1, -36, 0, 28), 14, true)

	makeText(scroll, "CustomizeTitle", "Body Color", UDim2.fromOffset(18, 154), UDim2.fromOffset(240, 28), 17, true)
	makeText(scroll, "CustomizeNote", "Cosmetics change appearance only. Stats and powers stay the same.", UDim2.fromOffset(18, 180), UDim2.new(1, -36, 0, 34), 12, false)

	local colorsFrame = Instance.new("Frame")
	colorsFrame.Name = "BodyColors"
	colorsFrame.Position = UDim2.fromOffset(18, 222)
	colorsFrame.Size = UDim2.new(1, -36, 0, 140)
	colorsFrame.BackgroundTransparency = 1
	colorsFrame.Parent = scroll

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.5, -4, 0, 64)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.FillDirectionMaxCells = 2
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = colorsFrame

	for index, styleId in ipairs(CosmeticStyles.BodyColorOrder) do
		local currentStyleId = styleId
		local style = CosmeticStyles.BodyColors[currentStyleId]
		if style then
			local button = Instance.new("TextButton")
			button.Name = currentStyleId .. "Color"
			button.LayoutOrder = index
			button.BackgroundColor3 = DEFAULT_CARD
			button.BackgroundTransparency = 0.02
			button.Text = ""
			button.AutoButtonColor = false
			button.Parent = colorsFrame

			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(91, 99, 93)
			stroke.Thickness = 1
			stroke.Parent = button

			local swatch = Instance.new("Frame")
			swatch.Size = UDim2.fromOffset(38, 32)
			swatch.Position = UDim2.fromOffset(10, 16)
			swatch.BackgroundColor3 = style.previewColor
			swatch.BorderSizePixel = 0
			swatch.Parent = button

			local label = makeText(button, "Label", style.displayName, UDim2.fromOffset(56, 6), UDim2.new(1, -64, 1, -12), 12, true)

			button.MouseButton1Click:Connect(function()
				if inRound then
					return
				end
				selectedBodyColor = currentStyleId
				refreshColorCards()
				remotes.SetCosmetic:FireServer("BodyColor", currentStyleId)
			end)

			colorCards[currentStyleId] = {
				button = button,
				stroke = stroke,
				label = label,
				displayName = style.displayName,
			}
		end
	end

	makeText(scroll, "FutureSlots", "Next slots: eyes, patterns, shell or wing details, and trails.", UDim2.fromOffset(18, 374), UDim2.new(1, -36, 0, 40), 12, false)

	refreshProfile()
	applyVisibility()
end

function ProfileController.Init(remotes)
	ensureGui(remotes)

	remotes.PlayerDataChanged.OnClientEvent:Connect(function(data)
		currentData = data
		refreshProfile()
	end)

	remotes.RoundStateChanged.OnClientEvent:Connect(function(state, _payload)
		if state == "Started" then
			inRound = true
			expanded = false
		elseif state == "Ended" or state == "Eliminated" or state == "ExitedRound" or state == "Waiting" or state == "Results" or state == "MatchInProgress" then
			inRound = false
		end
		applyVisibility()
	end)

	for _, attributeName in ipairs({ "BodyColor", "BugLevel", "BugTitle", "RoundsPlayed", "BestSurvival", "FoodCollected", "TotalDna", "TotalCrumbs", "SelectedBug" }) do
		player:GetAttributeChangedSignal(attributeName):Connect(refreshProfile)
	end
end

return ProfileController
