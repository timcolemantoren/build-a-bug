--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local BugOrder = require(BuildABugShared.Config.BugOrder)
local CosmeticCatalog = require(BuildABugShared.Config.CosmeticCatalog)
local AchievementConfig = require(BuildABugShared.Config.AchievementConfig)

local CollectionController = {}

local player = Players.LocalPlayer
local gui = nil
local openButton = nil
local panel = nil
local currentData = nil
local inRound = false
local summaryLabel = nil
local overallFill = nil
local overallText = nil
local categoryLabels = {}
local bugLabels = {}

local function makeText(parent: Instance, text: string, size: UDim2, position: UDim2, textSize: number, bold: boolean?): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(242, 245, 242)
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.TextSize = textSize
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function countUnlockedBugs(data): number
	local count = 0
	for _, bugId in ipairs(BugOrder) do
		if data.unlockedBugs and data.unlockedBugs[bugId] == true then
			count += 1
		end
	end
	return count
end

local function cosmeticOwned(data, slot: string, styleId: string): boolean
	local item = CosmeticCatalog.GetItem(slot, styleId)
	if not item then
		return false
	end
	local unlocked = data.unlockedCosmetics or {}
	local key = CosmeticCatalog.GetUnlockKey(slot, styleId)
	if item.unlockType == "achievement" then
		return unlocked[key] == true
	end
	if item.availability == "always" and (item.dnaCost or 0) <= 0 then
		return true
	end
	return unlocked[key] == true
end

local function countCosmetics(data, slot: string)
	local config = CosmeticCatalog.GetSlot(slot)
	local order = config and config.order or {}
	local owned = 0
	for _, styleId in ipairs(order) do
		if cosmeticOwned(data, slot, styleId) then
			owned += 1
		end
	end
	return owned, #order
end

local function countAwards(data): number
	local count = 0
	for _, achievementId in ipairs(AchievementConfig.Order) do
		if data.achievements and data.achievements[achievementId] == true then
			count += 1
		end
	end
	return count
end

local function setCategory(name: string, owned: number, total: number)
	local label = categoryLabels[name]
	if label then
		label.Text = string.format("%s    %s / %s", name, tostring(owned), tostring(total))
	end
end

local function refresh()
	local data = currentData or {}
	local bugsOwned = countUnlockedBugs(data)
	local colorsOwned, colorsTotal = countCosmetics(data, "BodyColor")
	local eyesOwned, eyesTotal = countCosmetics(data, "Eyes")
	local patternsOwned, patternsTotal = countCosmetics(data, "Pattern")
	local awardsOwned = countAwards(data)
	local awardsTotal = #AchievementConfig.Order

	local earnedOwned = bugsOwned + colorsOwned + eyesOwned + patternsOwned + awardsOwned
	local earnedTotal = #BugOrder + colorsTotal + eyesTotal + patternsTotal + awardsTotal
	local percent = earnedTotal > 0 and math.floor((earnedOwned / earnedTotal) * 100 + 0.5) or 0

	if summaryLabel then
		summaryLabel.Text = string.format("Earned Collection    %s%%", tostring(percent))
	end
	if overallText then
		overallText.Text = string.format("%s / %s earned items and milestones", tostring(earnedOwned), tostring(earnedTotal))
	end
	if overallFill then
		overallFill.Size = UDim2.new(earnedTotal > 0 and earnedOwned / earnedTotal or 0, 0, 1, 0)
	end

	setCategory("Bugs", bugsOwned, #BugOrder)
	setCategory("Colors", colorsOwned, colorsTotal)
	setCategory("Eyes", eyesOwned, eyesTotal)
	setCategory("Patterns", patternsOwned, patternsTotal)
	setCategory("Awards", awardsOwned, awardsTotal)

	for _, bugId in ipairs(BugOrder) do
		local label = bugLabels[bugId]
		if label then
			local owned = data.unlockedBugs and data.unlockedBugs[bugId] == true
			label.Text = (owned and "OWNED   " or "LOCKED   ") .. bugId
			label.TextColor3 = owned and Color3.fromRGB(195, 232, 190) or Color3.fromRGB(170, 174, 170)
		end
	end
end

local function applyVisibility()
	if openButton then
		openButton.Visible = not inRound and not (panel and panel.Visible)
	end
	if inRound and panel then
		panel.Visible = false
	end
end

local function ensureGui()
	if gui then
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "BuildABugCollection"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Parent = player:WaitForChild("PlayerGui")

	openButton = Instance.new("TextButton")
	openButton.Name = "OpenCollection"
	openButton.Size = UDim2.fromOffset(112, 36)
	openButton.Position = UDim2.fromOffset(14, 14)
	openButton.BackgroundColor3 = Color3.fromRGB(64, 73, 65)
	openButton.BackgroundTransparency = 0.06
	openButton.Text = "Collection"
	openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	openButton.Font = Enum.Font.GothamBold
	openButton.TextSize = 14
	openButton.Parent = gui

	panel = Instance.new("Frame")
	panel.Name = "CollectionPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0.90, 0, 0.84, 0)
	panel.BackgroundColor3 = Color3.fromRGB(30, 36, 32)
	panel.BackgroundTransparency = 0.03
	panel.Visible = false
	panel.Parent = gui

	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(520, 500)
	constraint.MinSize = Vector2.new(310, 360)
	constraint.Parent = panel

	makeText(panel, "Bug Collection", UDim2.new(1, -120, 0, 36), UDim2.fromOffset(18, 10), 22, true)
	local subtitle = makeText(panel, "Everything earned through play lives here. Premium skins are tracked separately.", UDim2.new(1, -36, 0, 38), UDim2.fromOffset(18, 44), 11, false)
	subtitle.TextColor3 = Color3.fromRGB(196, 207, 198)

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(76, 34)
	close.Position = UDim2.new(1, -92, 0, 12)
	close.BackgroundColor3 = Color3.fromRGB(74, 80, 76)
	close.Text = "Close"
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 13
	close.Parent = panel
	close.MouseButton1Click:Connect(function()
		panel.Visible = false
		applyVisibility()
	end)

	summaryLabel = makeText(panel, "Earned Collection    0%", UDim2.new(1, -36, 0, 28), UDim2.fromOffset(18, 86), 17, true)

	local progressBack = Instance.new("Frame")
	progressBack.Size = UDim2.new(1, -36, 0, 16)
	progressBack.Position = UDim2.fromOffset(18, 118)
	progressBack.BackgroundColor3 = Color3.fromRGB(50, 56, 51)
	progressBack.BorderSizePixel = 0
	progressBack.Parent = panel

	overallFill = Instance.new("Frame")
	overallFill.Size = UDim2.new(0, 0, 1, 0)
	overallFill.BackgroundColor3 = Color3.fromRGB(112, 157, 105)
	overallFill.BorderSizePixel = 0
	overallFill.Parent = progressBack

	overallText = makeText(panel, "0 / 0 earned items and milestones", UDim2.new(1, -36, 0, 22), UDim2.fromOffset(18, 138), 11, false)
	overallText.TextColor3 = Color3.fromRGB(202, 214, 203)

	local categories = Instance.new("Frame")
	categories.Position = UDim2.fromOffset(18, 166)
	categories.Size = UDim2.new(1, -36, 0, 110)
	categories.BackgroundColor3 = Color3.fromRGB(40, 47, 42)
	categories.BackgroundTransparency = 0.08
	categories.Parent = panel

	for index, name in ipairs({ "Bugs", "Colors", "Eyes", "Patterns", "Awards" }) do
		local column = (index - 1) % 2
		local row = math.floor((index - 1) / 2)
		local label = makeText(
			categories,
			name .. "    0 / 0",
			UDim2.new(0.5, -14, 0, 30),
			UDim2.new(column * 0.5, 10, 0, 6 + row * 33),
			12,
			true
		)
		categoryLabels[name] = label
	end

	makeText(panel, "Bug Box", UDim2.new(1, -36, 0, 26), UDim2.fromOffset(18, 288), 16, true)

	local bugBox = Instance.new("Frame")
	bugBox.Position = UDim2.fromOffset(18, 318)
	bugBox.Size = UDim2.new(1, -36, 0, 112)
	bugBox.BackgroundTransparency = 1
	bugBox.Parent = panel

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.5, -5, 0, 24)
	grid.CellPadding = UDim2.fromOffset(8, 5)
	grid.FillDirectionMaxCells = 2
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = bugBox

	for index, bugId in ipairs(BugOrder) do
		local label = makeText(bugBox, "LOCKED   " .. bugId, UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), 11, true)
		label.LayoutOrder = index
		label.BackgroundColor3 = Color3.fromRGB(43, 49, 45)
		label.BackgroundTransparency = 0.12
		label.TextXAlignment = Enum.TextXAlignment.Center
		bugLabels[bugId] = label
	end

	local premiumTotal = #(CosmeticCatalog.Slots.Skin and CosmeticCatalog.Slots.Skin.order or {}) - 1
	local premium = makeText(
		panel,
		string.format("Premium Skins: %s character looks currently in the catalog. Robux skins do not affect earned completion.", tostring(math.max(0, premiumTotal))),
		UDim2.new(1, -36, 0, 42),
		UDim2.new(0, 18, 1, -54),
		11,
		false
	)
	premium.TextColor3 = Color3.fromRGB(211, 186, 226)

	openButton.MouseButton1Click:Connect(function()
		if inRound then
			return
		end
		panel.Visible = true
		refresh()
		applyVisibility()
	end)

	refresh()
	applyVisibility()
end

function CollectionController.Init(remotes)
	ensureGui()

	remotes.PlayerDataChanged.OnClientEvent:Connect(function(data)
		currentData = data
		refresh()
	end)

	remotes.RoundStateChanged.OnClientEvent:Connect(function(state)
		if state == "Started" then
			inRound = true
			panel.Visible = false
		elseif state == "Ended" or state == "Eliminated" or state == "ExitedRound" or state == "Waiting" or state == "Results" or state == "MatchInProgress" then
			inRound = false
		end
		applyVisibility()
	end)
end

return CollectionController
