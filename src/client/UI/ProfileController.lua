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
local selectedEyes = player:GetAttribute("EyeStyle") or "Default"
local cosmeticCards = {}

local nameLabel = nil
local progressLabel = nil
local currencyLabel = nil
local statsLabel = nil
local bugLabel = nil
local shopStatusLabel = nil

local DEFAULT_CARD = Color3.fromRGB(55, 62, 58)
local SELECTED_CARD = Color3.fromRGB(74, 103, 76)
local LOCKED_CARD = Color3.fromRGB(48, 49, 48)
local OWNED_STROKE = Color3.fromRGB(91, 99, 93)
local SELECTED_STROKE = Color3.fromRGB(143, 181, 137)
local LOCKED_STROKE = Color3.fromRGB(72, 72, 72)

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

local function getAvailableDna(): number
	local data = currentData or {}
	local currency = data.currency or {}
	return currency.dna or player:GetAttribute("TotalDna") or 0
end

local function isOwned(slot: string, styleId: string): boolean
	local item = CosmeticStyles.GetItem(slot, styleId)
	if not item then
		return false
	end
	if (item.cost or 0) <= 0 then
		return true
	end

	local data = currentData or {}
	local unlocked = data.unlockedCosmetics or {}
	return unlocked[CosmeticStyles.GetUnlockKey(slot, styleId)] == true
end

local function isSelected(slot: string, styleId: string): boolean
	if slot == "BodyColor" then
		return styleId == selectedBodyColor
	elseif slot == "Eyes" then
		return styleId == selectedEyes
	end
	return false
end

local function refreshCosmeticCards()
	for _, card in pairs(cosmeticCards) do
		local owned = isOwned(card.slot, card.styleId)
		local selected = isSelected(card.slot, card.styleId)
		local cost = card.item.cost or 0

		if selected then
			card.button.BackgroundColor3 = SELECTED_CARD
			card.stroke.Color = SELECTED_STROKE
			card.stroke.Thickness = 2
			card.label.Text = "SELECTED\n" .. card.item.displayName
		elseif owned then
			card.button.BackgroundColor3 = DEFAULT_CARD
			card.stroke.Color = OWNED_STROKE
			card.stroke.Thickness = 1
			card.label.Text = "OWNED\n" .. card.item.displayName
		else
			card.button.BackgroundColor3 = LOCKED_CARD
			card.stroke.Color = LOCKED_STROKE
			card.stroke.Thickness = 1
			card.label.Text = string.format("%s\n%s DNA", card.item.displayName, tostring(cost))
		end
	end
end

local function setShopStatus(text: string, isWarning: boolean?)
	if not shopStatusLabel then
		return
	end
	shopStatusLabel.Text = text
	shopStatusLabel.TextColor3 = isWarning and Color3.fromRGB(255, 205, 145) or Color3.fromRGB(195, 225, 190)
end

local function useCosmetic(remotes, slot: string, styleId: string)
	if inRound then
		return
	end

	local item = CosmeticStyles.GetItem(slot, styleId)
	if not item then
		return
	end

	if isOwned(slot, styleId) then
		remotes.SetCosmetic:FireServer(slot, styleId)
		setShopStatus("Equipping " .. item.displayName .. "...", false)
		return
	end

	local cost = item.cost or 0
	local dna = getAvailableDna()
	if dna < cost then
		setShopStatus(string.format("Need %s more DNA to unlock %s.", tostring(cost - dna), item.displayName), true)
		return
	end

	remotes.PurchaseCosmetic:FireServer(slot, styleId)
	setShopStatus(string.format("Unlocking %s for %s DNA...", item.displayName, tostring(cost)), false)
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
	local lifetimeDna = progression.lifetimeDna or stats.lifetimeDna or player:GetAttribute("LifetimeDna") or dna
	local crumbs = currency.crumbs or player:GetAttribute("TotalCrumbs") or 0
	local rounds = stats.roundsPlayed or player:GetAttribute("RoundsPlayed") or 0
	local best = stats.longestSurvival or player:GetAttribute("BestSurvival") or 0
	local food = stats.foodCollected or player:GetAttribute("FoodCollected") or 0
	local bugId = data.selectedBug or player:GetAttribute("SelectedBug") or "Ant"
	local cosmetics = data.cosmetics or {}
	selectedBodyColor = cosmetics.bodyColor or player:GetAttribute("BodyColor") or selectedBodyColor
	selectedEyes = cosmetics.eyes or player:GetAttribute("EyeStyle") or selectedEyes

	if nameLabel then
		nameLabel.Text = player.DisplayName
	end
	if progressLabel then
		progressLabel.Text = string.format("Level %s • %s", tostring(level), tostring(title))
	end
	if currencyLabel then
		currencyLabel.Text = string.format("DNA: %s available • %s lifetime    Crumbs: %s", tostring(dna), tostring(lifetimeDna), tostring(crumbs))
	end
	if statsLabel then
		statsLabel.Text = string.format("Rounds: %s    Best: %s    Food: %s", tostring(rounds), formatTime(best), tostring(food))
	end
	if bugLabel then
		bugLabel.Text = "Current bug: " .. tostring(bugId)
	end

	refreshCosmeticCards()
end

local function applyVisibility()
	if openButton then
		openButton.Visible = not inRound and not expanded
	end
	if panel then
		panel.Visible = not inRound and expanded
	end
end

local function createCosmeticGrid(parent: Instance, remotes, slot: string, order, styles, y: number)
	local frame = Instance.new("Frame")
	frame.Name = slot .. "Grid"
	frame.Position = UDim2.fromOffset(18, y)
	frame.Size = UDim2.new(1, -36, 0, 140)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.5, -4, 0, 64)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.FillDirectionMaxCells = 2
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = frame

	for index, styleId in ipairs(order) do
		local currentStyleId = styleId
		local item = styles[currentStyleId]
		if item then
			local button = Instance.new("TextButton")
			button.Name = currentStyleId .. slot
			button.LayoutOrder = index
			button.BackgroundColor3 = DEFAULT_CARD
			button.BackgroundTransparency = 0.02
			button.Text = ""
			button.AutoButtonColor = false
			button.Parent = frame

			local stroke = Instance.new("UIStroke")
			stroke.Color = OWNED_STROKE
			stroke.Thickness = 1
			stroke.Parent = button

			local swatch = Instance.new("Frame")
			swatch.Size = UDim2.fromOffset(38, 32)
			swatch.Position = UDim2.fromOffset(10, 16)
			swatch.BackgroundColor3 = item.previewColor
			swatch.BorderSizePixel = 0
			swatch.Parent = button

			if slot == "Eyes" and item.kind == "googly" then
				local pupil = Instance.new("Frame")
				pupil.Size = UDim2.fromOffset(12, 12)
				pupil.Position = UDim2.new(0.5, -2, 0.5, -2)
				pupil.BackgroundColor3 = item.pupilColor or Color3.fromRGB(18, 18, 20)
				pupil.BorderSizePixel = 0
				pupil.Parent = swatch
			end

			local label = makeText(button, "Label", item.displayName, UDim2.fromOffset(56, 4), UDim2.new(1, -64, 1, -8), 12, true)

			button.MouseButton1Click:Connect(function()
				useCosmetic(remotes, slot, currentStyleId)
			end)

			cosmeticCards[slot .. ":" .. currentStyleId] = {
				button = button,
				stroke = stroke,
				label = label,
				item = item,
				slot = slot,
				styleId = currentStyleId,
			}
		end
	end

	return frame
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
		setShopStatus("Spend DNA on cosmetics without losing level progress.", false)
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
	sizeConstraint.MaxSize = Vector2.new(500, 500)
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
	scroll.CanvasSize = UDim2.fromOffset(0, 650)
	scroll.ScrollBarThickness = 4
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = panel

	nameLabel = makeText(scroll, "PlayerName", player.DisplayName, UDim2.fromOffset(18, 0), UDim2.new(1, -36, 0, 30), 18, true)
	progressLabel = makeText(scroll, "Progress", "Level 1 • Fresh Hatchling", UDim2.fromOffset(18, 28), UDim2.new(1, -36, 0, 26), 14, true)
	currencyLabel = makeText(scroll, "Currency", "DNA: 0 available • 0 lifetime    Crumbs: 0", UDim2.fromOffset(18, 56), UDim2.new(1, -36, 0, 30), 12, false)
	statsLabel = makeText(scroll, "Stats", "Rounds: 0    Best: --    Food: 0", UDim2.fromOffset(18, 86), UDim2.new(1, -36, 0, 28), 13, false)
	bugLabel = makeText(scroll, "Bug", "Current bug: Ant", UDim2.fromOffset(18, 116), UDim2.new(1, -36, 0, 28), 14, true)

	shopStatusLabel = makeText(scroll, "ShopStatus", "Spend DNA on cosmetics without losing level progress.", UDim2.fromOffset(18, 146), UDim2.new(1, -36, 0, 36), 12, true)
	shopStatusLabel.TextColor3 = Color3.fromRGB(195, 225, 190)

	makeText(scroll, "BodyColorTitle", "Body Color", UDim2.fromOffset(18, 190), UDim2.fromOffset(240, 28), 17, true)
	createCosmeticGrid(scroll, remotes, "BodyColor", CosmeticStyles.BodyColorOrder, CosmeticStyles.BodyColors, 222)

	makeText(scroll, "EyeTitle", "Eyes", UDim2.fromOffset(18, 372), UDim2.fromOffset(240, 28), 17, true)
	createCosmeticGrid(scroll, remotes, "Eyes", CosmeticStyles.EyeStyleOrder, CosmeticStyles.EyeStyles, 404)

	makeText(scroll, "FutureSlots", "Next slots: patterns, shell or wing details, antenna accents, and trails.", UDim2.fromOffset(18, 570), UDim2.new(1, -36, 0, 44), 12, false)

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

	for _, attributeName in ipairs({ "BodyColor", "EyeStyle", "BugLevel", "BugTitle", "RoundsPlayed", "BestSurvival", "FoodCollected", "LifetimeDna", "TotalDna", "TotalCrumbs", "SelectedBug" }) do
		player:GetAttributeChangedSignal(attributeName):Connect(refreshProfile)
	end
end

return ProfileController
