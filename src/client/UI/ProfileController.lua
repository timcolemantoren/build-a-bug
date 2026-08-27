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
local selectedBodyColor = "Natural"
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
		statsLabel.Text = string.format("Rounds: %s    Best survival: %s    Food collected: %s", tostring(rounds), formatTime(best), tostring(food))
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
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Size = UDim2.fromOffset(500, 420)
	panel.Position = UDim2.new(0.5, 0, 0, 58)
	panel.BackgroundColor3 = Color3.fromRGB(31, 37, 34)
	panel.BackgroundTransparency = 0.06
	panel.Parent = gui

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(500, 420)
	sizeConstraint.MinSize = Vector2.new(330, 380)
	sizeConstraint.Parent = panel

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.fromOffset(76, 34)
	closeButton.Position = UDim2.new(1, -90, 0, 12)
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

	makeText(panel, "Title", "Profile / Customize", UDim2.fromOffset(18, 10), UDim2.fromOffset(300, 36), 20, true)
	nameLabel = makeText(panel, "PlayerName", player.DisplayName, UDim2.fromOffset(22, 52), UDim2.new(1, -44, 0, 30), 18, true)
	progressLabel = makeText(panel, "Progress", "Level 1 • Fresh Hatchling", UDim2.fromOffset(22, 80), UDim2.new(1, -44, 0, 26), 14, true)
	currencyLabel = makeText(panel, "Currency", "DNA: 0    Crumbs: 0", UDim2.fromOffset(22, 108), UDim2.new(1, -44, 0, 24), 13, false)
	statsLabel = makeText(panel, "Stats", "Rounds: 0    Best survival: --    Food collected: 0", UDim2.fromOffset(22, 134), UDim2.new(1, -44, 0, 30), 13, false)
	bugLabel = makeText(panel, "Bug", "Current bug: Ant", UDim2.fromOffset(22, 164), UDim2.new(1, -44, 0, 28), 14, true)

	makeText(panel, "CustomizeTitle", "Body Color", UDim2.fromOffset(22, 204), UDim2.fromOffset(240, 28), 17, true)
	makeText(panel, "CustomizeNote", "Cosmetics change appearance only. Stats and powers stay the same.", UDim2.fromOffset(22, 230), UDim2.new(1, -44, 0, 28), 12, false)

	local cardWidth = 105
	local gap = 8
	local startX = 22
	for index, styleId in ipairs(CosmeticStyles.BodyColorOrder) do
		local style = CosmeticStyles.BodyColors[styleId]
		if style then
			local button = Instance.new("TextButton")
			button.Name = styleId .. "Color"
			button.Size = UDim2.fromOffset(cardWidth, 82)
			button.Position = UDim2.fromOffset(startX + (index - 1) * (cardWidth + gap), 268)
			button.BackgroundColor3 = DEFAULT_CARD
			button.BackgroundTransparency = 0.02
			button.Text = ""
			button.AutoButtonColor = false
			button.Parent = panel

			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(91, 99, 93)
			stroke.Thickness = 1
			stroke.Parent = button

			local swatch = Instance.new("Frame")
			swatch.Size = UDim2.fromOffset(44, 28)
			swatch.Position = UDim2.new(0.5, -22, 0, 10)
			swatch.BackgroundColor3 = style.previewColor
			swatch.BorderSizePixel = 0
			swatch.Parent = button

			local label = makeText(button, "Label", style.displayName, UDim2.fromOffset(5, 42), UDim2.new(1, -10, 0, 34), 12, true)
			label.TextXAlignment = Enum.TextXAlignment.Center

			button.MouseButton1Click:Connect(function()
				if inRound then
					return
				end
				selectedBodyColor = styleId
				refreshColorCards()
				remotes.SetCosmetic:FireServer("BodyColor", styleId)
			end)

			colorCards[styleId] = {
				button = button,
				stroke = stroke,
				label = label,
				displayName = style.displayName,
			}
		end
	end

	makeText(panel, "FutureSlots", "Next slots: eyes, patterns, shell or wing details, and trails.", UDim2.fromOffset(22, 362), UDim2.new(1, -44, 0, 38), 12, false)

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
