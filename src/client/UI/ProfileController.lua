--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local CosmeticStyles = require(BuildABugShared.Config.CosmeticStyles)
local CosmeticCatalog = require(BuildABugShared.Config.CosmeticCatalog)
local AchievementConfig = require(BuildABugShared.Config.AchievementConfig)
local PurchaseConfirmController = require(script.Parent.PurchaseConfirmController)

local ProfileController = {}

local player = Players.LocalPlayer
local gui = nil
local openButton = nil
local panel = nil
local inRound = false
local expanded = false
local currentData = nil
local activeTab = "Stats"

local selectedBodyColor = player:GetAttribute("BodyColor") or "Natural"
local selectedEyes = player:GetAttribute("EyeStyle") or "Default"
local selectedPattern = player:GetAttribute("PatternStyle") or "None"

local cosmeticCards = {}
local achievementCards = {}
local buildCards = {}
local tabButtons = {}
local tabPages = {}

local headerSummary = nil
local nameLabel = nil
local progressLabel = nil
local currencyLabel = nil
local statsLabel = nil
local bugLabel = nil
local shopStatusLabel = nil
local buildsIntroLabel = nil

local DEFAULT_CARD = Color3.fromRGB(55, 62, 58)
local SELECTED_CARD = Color3.fromRGB(74, 103, 76)
local LOCKED_CARD = Color3.fromRGB(48, 49, 48)
local ACHIEVED_CARD = Color3.fromRGB(78, 92, 61)
local OWNED_STROKE = Color3.fromRGB(91, 99, 93)
local SELECTED_STROKE = Color3.fromRGB(143, 181, 137)
local LOCKED_STROKE = Color3.fromRGB(72, 72, 72)
local ACHIEVED_STROKE = Color3.fromRGB(218, 190, 87)
local TAB_IDLE = Color3.fromRGB(58, 65, 61)
local TAB_ACTIVE = Color3.fromRGB(82, 109, 83)
local BUILD_FILLED = Color3.fromRGB(61, 73, 65)
local BUILD_EMPTY = Color3.fromRGB(46, 51, 48)

local BUILD_PRESETS = {
	{ id = "Build1", name = "Build 1" },
	{ id = "Build2", name = "Build 2" },
	{ id = "Build3", name = "Build 3" },
}

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

local function getCurrentBugId(): string
	local data = currentData or {}
	return data.selectedBug or player:GetAttribute("SelectedBug") or "Ant"
end

local function isOwned(slot: string, styleId: string): boolean
	local item = CosmeticCatalog.GetItem(slot, styleId)
	if not item then
		return false
	end

	local data = currentData or {}
	local unlocked = data.unlockedCosmetics or {}
	if item.unlockType == "achievement" then
		return unlocked[CosmeticCatalog.GetUnlockKey(slot, styleId)] == true
	end
	if (item.dnaCost or 0) <= 0 then
		return true
	end
	return unlocked[CosmeticCatalog.GetUnlockKey(slot, styleId)] == true
end

local function isSelected(slot: string, styleId: string): boolean
	if slot == "BodyColor" then
		return styleId == selectedBodyColor
	elseif slot == "Eyes" then
		return styleId == selectedEyes
	elseif slot == "Pattern" then
		return styleId == selectedPattern
	end
	return false
end

local function setShopStatus(text: string, isWarning: boolean?)
	if not shopStatusLabel then
		return
	end
	shopStatusLabel.Text = text
	shopStatusLabel.TextColor3 = isWarning and Color3.fromRGB(255, 205, 145) or Color3.fromRGB(195, 225, 190)
end

local function styleDisplayName(slot: string, styleId: string?): string
	if not styleId then
		return "None"
	end
	local style = CosmeticStyles.GetStyle(slot, styleId)
	return style and style.displayName or tostring(styleId)
end

local function getPreset(presetId: string)
	local data = currentData or {}
	local savedBuilds = data.savedBuilds or {}
	local presetsByBug = savedBuilds.BugPresets or {}
	local bugPresets = presetsByBug[getCurrentBugId()] or {}
	return bugPresets[presetId]
end

local function formatBuildSummary(loadout): string
	if type(loadout) ~= "table" then
		return "Empty slot"
	end
	return string.format(
		"%s  •  %s\n%s",
		styleDisplayName("BodyColor", loadout.bodyColor or "Natural"),
		styleDisplayName("Eyes", loadout.eyes or "Default"),
		styleDisplayName("Pattern", loadout.pattern or "None")
	)
end

local function refreshBuildCards()
	local bugId = getCurrentBugId()
	if buildsIntroLabel then
		buildsIntroLabel.Text = bugId .. " Saved Builds"
	end

	for presetId, card in pairs(buildCards) do
		local preset = getPreset(presetId)
		local filled = type(preset) == "table"
		card.frame.BackgroundColor3 = filled and BUILD_FILLED or BUILD_EMPTY
		card.summary.Text = formatBuildSummary(preset)
		card.saveButton.Text = filled and "Overwrite" or "Save"
		card.loadButton.TextTransparency = filled and 0 or 0.52
		card.loadButton.BackgroundTransparency = filled and 0.08 or 0.42
	end
end

local function refreshCosmeticCards()
	for _, card in pairs(cosmeticCards) do
		local owned = isOwned(card.slot, card.styleId)
		local selected = isSelected(card.slot, card.styleId)
		local cost = card.item.dnaCost or 0
		local rarity = card.item.rarity or "Common"

		if selected then
			card.button.BackgroundColor3 = SELECTED_CARD
			card.stroke.Color = SELECTED_STROKE
			card.stroke.Thickness = 2
			card.label.Text = string.format("SELECTED\n%s\n%s", card.item.displayName, rarity)
		elseif owned then
			card.button.BackgroundColor3 = DEFAULT_CARD
			card.stroke.Color = OWNED_STROKE
			card.stroke.Thickness = 1
			card.label.Text = string.format("OWNED\n%s\n%s", card.item.displayName, rarity)
		else
			card.button.BackgroundColor3 = LOCKED_CARD
			card.stroke.Color = LOCKED_STROKE
			card.stroke.Thickness = 1
			if card.item.unlockType == "achievement" then
				card.label.Text = string.format("%s\nEarn in Awards\n%s", card.item.displayName, rarity)
			elseif card.item.availability == "always" then
				card.label.Text = string.format("%s\n%s DNA\n%s", card.item.displayName, tostring(cost), rarity)
			else
				card.label.Text = string.format("%s\nNot in stock\n%s", card.item.displayName, rarity)
			end
		end
	end
end

local function refreshAchievementCards()
	local data = currentData or {}
	local achievements = data.achievements or {}

	for achievementId, card in pairs(achievementCards) do
		local achievement = AchievementConfig.Get(achievementId)
		if achievement then
			local complete = achievements[achievementId] == true
			local progress = math.min(achievement.target or 1, AchievementConfig.GetProgress(achievement, data))
			local target = achievement.target or 1
			if complete then
				card.frame.BackgroundColor3 = ACHIEVED_CARD
				card.stroke.Color = ACHIEVED_STROKE
				card.stroke.Thickness = 2
				card.progress.Text = "COMPLETE  •  " .. achievement.rewardName
				card.progress.TextColor3 = Color3.fromRGB(255, 224, 121)
			else
				card.frame.BackgroundColor3 = LOCKED_CARD
				card.stroke.Color = LOCKED_STROKE
				card.stroke.Thickness = 1
				card.progress.Text = string.format("%s / %s  •  Reward: %s", tostring(progress), tostring(target), achievement.rewardName)
				card.progress.TextColor3 = Color3.fromRGB(205, 215, 205)
			end
		end
	end
end

local function useCosmetic(remotes, slot: string, styleId: string)
	if inRound then
		return
	end

	local item = CosmeticCatalog.GetItem(slot, styleId)
	if not item then
		return
	end

	if isOwned(slot, styleId) then
		remotes.SetCosmetic:FireServer(slot, styleId)
		setShopStatus("Equipping " .. item.displayName .. "...", false)
		return
	end

	if item.unlockType == "achievement" then
		local achievement = item.achievementId and AchievementConfig.Get(item.achievementId) or nil
		setShopStatus(achievement and ("Earn " .. achievement.displayName .. " to unlock " .. item.displayName .. ".") or "This cosmetic is earned from an achievement.", true)
		return
	end

	if item.availability ~= "always" then
		setShopStatus(item.displayName .. " is not currently in stock.", true)
		return
	end

	local cost = item.dnaCost or 0
	local dna = getAvailableDna()
	if dna < cost then
		setShopStatus(string.format("Need %s more DNA to unlock %s.", tostring(cost - dna), item.displayName), true)
		return
	end

	PurchaseConfirmController.Request({
		itemName = item.displayName,
		cost = cost,
		balance = dna,
	}, function()
		if inRound then
			return
		end

		if isOwned(slot, styleId) then
			remotes.SetCosmetic:FireServer(slot, styleId)
			setShopStatus(item.displayName .. " is already owned and has been equipped.", false)
			return
		end

		local currentItem = CosmeticCatalog.GetItem(slot, styleId)
		if not currentItem or currentItem.unlockType == "achievement" or currentItem.availability ~= "always" then
			setShopStatus("That cosmetic is no longer available for purchase.", true)
			return
		end

		local currentCost = currentItem.dnaCost or 0
		if getAvailableDna() < currentCost then
			setShopStatus("Your DNA balance changed. Purchase cancelled.", true)
			return
		end

		remotes.PurchaseCosmetic:FireServer(slot, styleId)
		setShopStatus(string.format("Unlocking %s for %s DNA...", currentItem.displayName, tostring(currentCost)), false)
	end)
	setShopStatus("Review the purchase and choose Buy or Cancel.", false)
end

local function refreshProfile()
	local data = currentData or {}
	local currency = data.currency or {}
	local stats = data.stats or {}
	local progression = data.progression or {}
	local current = progression.current or {}
	local achievements = data.achievements or {}

	local level = current.level or player:GetAttribute("BugLevel") or 1
	local title = current.title or player:GetAttribute("BugTitle") or "Fresh Hatchling"
	local dna = currency.dna or player:GetAttribute("TotalDna") or 0
	local lifetimeDna = progression.lifetimeDna or stats.lifetimeDna or player:GetAttribute("LifetimeDna") or dna
	local crumbs = currency.crumbs or player:GetAttribute("TotalCrumbs") or 0
	local rounds = stats.roundsPlayed or player:GetAttribute("RoundsPlayed") or 0
	local fullSurvives = stats.fullRoundsSurvived or player:GetAttribute("FullRoundsSurvived") or 0
	local best = stats.longestSurvival or player:GetAttribute("BestSurvival") or 0
	local food = stats.foodCollected or player:GetAttribute("FoodCollected") or 0
	local bugId = getCurrentBugId()
	local completedCount = 0
	for _, value in pairs(achievements) do
		if value == true then
			completedCount += 1
		end
	end

	local cosmetics = data.cosmetics or {}
	selectedBodyColor = cosmetics.bodyColor or player:GetAttribute("BodyColor") or selectedBodyColor
	selectedEyes = cosmetics.eyes or player:GetAttribute("EyeStyle") or selectedEyes
	selectedPattern = cosmetics.pattern or player:GetAttribute("PatternStyle") or selectedPattern

	if headerSummary then
		headerSummary.Text = string.format("Lv %s • %s    DNA %s", tostring(level), tostring(title), tostring(dna))
	end
	if nameLabel then
		nameLabel.Text = player.DisplayName
	end
	if progressLabel then
		progressLabel.Text = string.format("Level %s • %s", tostring(level), tostring(title))
	end
	if currencyLabel then
		currencyLabel.Text = string.format("Available DNA: %s\nLifetime DNA: %s\nCrumbs: %s", tostring(dna), tostring(lifetimeDna), tostring(crumbs))
	end
	if statsLabel then
		statsLabel.Text = string.format("Rounds played: %s\nFull rounds survived: %s\nBest survival: %s\nFood collected: %s\nAwards: %s / %s", tostring(rounds), tostring(fullSurvives), formatTime(best), tostring(food), tostring(completedCount), tostring(#AchievementConfig.Order))
	end
	if bugLabel then
		bugLabel.Text = string.format("Current bug: %s\nColor: %s    Eyes: %s\nPattern: %s", tostring(bugId), tostring(selectedBodyColor), tostring(selectedEyes), tostring(selectedPattern))
	end

	refreshCosmeticCards()
	refreshAchievementCards()
	refreshBuildCards()
end

local function applyTab()
	for tabId, page in pairs(tabPages) do
		page.Visible = tabId == activeTab
	end
	for tabId, button in pairs(tabButtons) do
		local active = tabId == activeTab
		button.BackgroundColor3 = active and TAB_ACTIVE or TAB_IDLE
		button.TextTransparency = active and 0 or 0.08
	end
end

local function applyVisibility()
	if openButton then
		openButton.Visible = not inRound and not expanded
	end
	if panel then
		panel.Visible = not inRound and expanded
	end
	if inRound or not expanded then
		PurchaseConfirmController.Cancel()
	end
end

local function createTabButton(parent: Instance, tabId: string, text: string, order: number)
	local button = Instance.new("TextButton")
	button.Name = tabId .. "Tab"
	button.Size = UDim2.fromOffset(80, 36)
	button.LayoutOrder = order
	button.BackgroundColor3 = TAB_IDLE
	button.BackgroundTransparency = 0.02
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	button.AutoButtonColor = false
	button.Parent = parent
	button.MouseButton1Click:Connect(function()
		activeTab = tabId
		if tabId == "Awards" then
			setShopStatus("Complete Awards to unlock cosmetics that cannot be bought with DNA.", false)
		elseif tabId == "Builds" then
			setShopStatus("Save favorite looks for the current bug. Each species has its own three build slots.", false)
		elseif tabId ~= "Stats" then
			setShopStatus("Tap a locked cosmetic to review its DNA purchase. Award cosmetics must be earned.", false)
		end
		applyTab()
	end)
	tabButtons[tabId] = button
end

local function createPage(parent: Instance, tabId: string): Frame
	local page = Instance.new("Frame")
	page.Name = tabId .. "Page"
	page.Position = UDim2.fromOffset(0, 0)
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = parent
	tabPages[tabId] = page
	return page
end

local function createBuildsPage(parent: Instance, remotes)
	local page = createPage(parent, "Builds")
	buildsIntroLabel = makeText(page, "Intro", "Ant Saved Builds", UDim2.fromOffset(16, 4), UDim2.new(1, -32, 0, 28), 17, true)
	local note = makeText(page, "Note", "Your current look is remembered automatically. Save favorite snapshots here.", UDim2.fromOffset(16, 30), UDim2.new(1, -32, 0, 38), 11, false)
	note.TextColor3 = Color3.fromRGB(205, 215, 205)

	for index, presetInfo in ipairs(BUILD_PRESETS) do
		local presetId = presetInfo.id
		local card = Instance.new("Frame")
		card.Name = presetId
		card.Size = UDim2.new(1, -24, 0, 84)
		card.Position = UDim2.fromOffset(12, 72 + ((index - 1) * 92))
		card.BackgroundColor3 = BUILD_EMPTY
		card.BackgroundTransparency = 0.02
		card.Parent = page

		local stroke = Instance.new("UIStroke")
		stroke.Color = OWNED_STROKE
		stroke.Thickness = 1
		stroke.Parent = card

		local title = makeText(card, "Title", presetInfo.name, UDim2.fromOffset(12, 5), UDim2.new(1, -180, 0, 22), 14, true)
		title.TextColor3 = Color3.fromRGB(250, 250, 245)
		local summary = makeText(card, "Summary", "Empty slot", UDim2.fromOffset(12, 28), UDim2.new(1, -180, 0, 46), 11, false)
		summary.TextColor3 = Color3.fromRGB(210, 218, 210)

		local saveButton = Instance.new("TextButton")
		saveButton.Name = "Save"
		saveButton.Size = UDim2.fromOffset(78, 32)
		saveButton.Position = UDim2.new(1, -166, 0, 30)
		saveButton.BackgroundColor3 = Color3.fromRGB(78, 101, 79)
		saveButton.BackgroundTransparency = 0.08
		saveButton.Text = "Save"
		saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		saveButton.Font = Enum.Font.GothamBold
		saveButton.TextSize = 12
		saveButton.Parent = card
		saveButton.MouseButton1Click:Connect(function()
			if inRound then
				return
			end
			remotes.BuildPreset:FireServer("Save", presetId)
			setShopStatus("Saving " .. presetInfo.name .. " for " .. getCurrentBugId() .. "...", false)
		end)

		local loadButton = Instance.new("TextButton")
		loadButton.Name = "Load"
		loadButton.Size = UDim2.fromOffset(70, 32)
		loadButton.Position = UDim2.new(1, -80, 0, 30)
		loadButton.BackgroundColor3 = Color3.fromRGB(75, 82, 79)
		loadButton.BackgroundTransparency = 0.42
		loadButton.Text = "Load"
		loadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		loadButton.TextTransparency = 0.52
		loadButton.Font = Enum.Font.GothamBold
		loadButton.TextSize = 12
		loadButton.Parent = card
		loadButton.MouseButton1Click:Connect(function()
			if inRound then
				return
			end
			if type(getPreset(presetId)) ~= "table" then
				setShopStatus(presetInfo.name .. " is empty. Save your current look first.", true)
				return
			end
			remotes.BuildPreset:FireServer("Load", presetId)
			setShopStatus("Loading " .. presetInfo.name .. " for " .. getCurrentBugId() .. "...", false)
		end)

		buildCards[presetId] = {
			frame = card,
			summary = summary,
			saveButton = saveButton,
			loadButton = loadButton,
		}
	end
end

local function createCosmeticPage(parent: Instance, remotes, tabId: string, slot: string)
	local page = createPage(parent, tabId)
	local slotConfig = CosmeticCatalog.GetSlot(slot)
	local order = slotConfig and slotConfig.order or {}
	local slotItems = CosmeticCatalog.Items[slot] or {}

	local intro = makeText(page, "Intro", (slotConfig and slotConfig.displayName or slot) .. " Collection", UDim2.fromOffset(16, 8), UDim2.new(1, -32, 0, 28), 17, true)
	intro.TextColor3 = Color3.fromRGB(245, 247, 245)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = slot .. "Scroll"
	scroll.Position = UDim2.fromOffset(12, 42)
	scroll.Size = UDim2.new(1, -24, 1, -50)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.fromOffset(0, math.max(150, math.ceil(#order / 2) * 82 + 12))
	scroll.ScrollBarThickness = 4
	scroll.Parent = page

	local gridFrame = Instance.new("Frame")
	gridFrame.Name = "Grid"
	gridFrame.Size = UDim2.new(1, -8, 0, math.ceil(#order / 2) * 82)
	gridFrame.BackgroundTransparency = 1
	gridFrame.Parent = scroll

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.5, -5, 0, 74)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.FillDirectionMaxCells = 2
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = gridFrame

	for index, styleId in ipairs(order) do
		local currentStyleId = styleId
		local item = slotItems[currentStyleId]
		local style = CosmeticStyles.GetStyle(slot, currentStyleId)
		if item and style then
			local button = Instance.new("TextButton")
			button.Name = currentStyleId .. slot
			button.LayoutOrder = index
			button.BackgroundColor3 = DEFAULT_CARD
			button.BackgroundTransparency = 0.02
			button.Text = ""
			button.AutoButtonColor = false
			button.Parent = gridFrame

			local stroke = Instance.new("UIStroke")
			stroke.Color = OWNED_STROKE
			stroke.Thickness = 1
			stroke.Parent = button

			local swatch = Instance.new("Frame")
			swatch.Size = UDim2.fromOffset(38, 38)
			swatch.Position = UDim2.fromOffset(9, 18)
			swatch.BackgroundColor3 = style.previewColor or Color3.fromRGB(120, 120, 120)
			swatch.BorderSizePixel = 0
			swatch.Parent = button

			if slot == "Eyes" and style.kind == "googly" then
				local pupil = Instance.new("Frame")
				pupil.Size = UDim2.fromOffset(12, 12)
				pupil.Position = UDim2.new(0.5, -2, 0.5, -2)
				pupil.BackgroundColor3 = style.pupilColor or Color3.fromRGB(18, 18, 20)
				pupil.BorderSizePixel = 0
				pupil.Parent = swatch
			elseif slot == "Pattern" and style.kind == "stripe" then
				for _, y in ipairs({ 10, 24 }) do
					local stripe = Instance.new("Frame")
					stripe.Size = UDim2.new(1, 0, 0, 5)
					stripe.Position = UDim2.fromOffset(0, y)
					stripe.BackgroundColor3 = Color3.fromRGB(55, 55, 45)
					stripe.BorderSizePixel = 0
					stripe.Parent = swatch
				end
			elseif slot == "Pattern" and style.kind == "speckles" then
				for _, pos in ipairs({ Vector2.new(7, 8), Vector2.new(23, 7), Vector2.new(14, 23), Vector2.new(28, 27) }) do
					local dot = Instance.new("Frame")
					dot.Size = UDim2.fromOffset(6, 6)
					dot.Position = UDim2.fromOffset(pos.X, pos.Y)
					dot.BackgroundColor3 = Color3.fromRGB(70, 70, 65)
					dot.BorderSizePixel = 0
					dot.Parent = swatch
				end
			end

			local label = makeText(button, "Label", item.displayName, UDim2.fromOffset(54, 4), UDim2.new(1, -60, 1, -8), 11, true)
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
end

local function createAwardsPage(parent: Instance)
	local page = createPage(parent, "Awards")
	makeText(page, "Intro", "Awards", UDim2.fromOffset(16, 8), UDim2.new(1, -32, 0, 28), 17, true)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "AwardsScroll"
	scroll.Position = UDim2.fromOffset(12, 42)
	scroll.Size = UDim2.new(1, -24, 1, -50)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.fromOffset(0, #AchievementConfig.Order * 92 + 8)
	scroll.Parent = page

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	for index, achievementId in ipairs(AchievementConfig.Order) do
		local achievement = AchievementConfig.Get(achievementId)
		if achievement then
			local card = Instance.new("Frame")
			card.Name = achievementId
			card.Size = UDim2.new(1, -8, 0, 84)
			card.LayoutOrder = index
			card.BackgroundColor3 = LOCKED_CARD
			card.BackgroundTransparency = 0.02
			card.Parent = scroll

			local stroke = Instance.new("UIStroke")
			stroke.Color = LOCKED_STROKE
			stroke.Thickness = 1
			stroke.Parent = card

			local title = makeText(card, "Title", achievement.displayName, UDim2.fromOffset(12, 6), UDim2.new(1, -24, 0, 22), 14, true)
			title.TextColor3 = Color3.fromRGB(250, 250, 245)
			local desc = makeText(card, "Description", achievement.description, UDim2.fromOffset(12, 28), UDim2.new(1, -24, 0, 22), 12, false)
			desc.TextColor3 = Color3.fromRGB(218, 222, 216)
			local progress = makeText(card, "Progress", "0 / 1", UDim2.fromOffset(12, 52), UDim2.new(1, -24, 0, 25), 11, true)
			progress.TextColor3 = Color3.fromRGB(205, 215, 205)

			achievementCards[achievementId] = {
				frame = card,
				stroke = stroke,
				progress = progress,
			}
		end
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
	panel.Size = UDim2.new(0.92, 0, 0.88, 0)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(31, 37, 34)
	panel.BackgroundTransparency = 0.03
	panel.Parent = gui

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(560, 520)
	sizeConstraint.MinSize = Vector2.new(320, 320)
	sizeConstraint.Parent = panel

	makeText(panel, "Title", "Profile / Customize", UDim2.fromOffset(18, 8), UDim2.new(1, -118, 0, 32), 20, true)
	headerSummary = makeText(panel, "Summary", "Lv 1 • Fresh Hatchling    DNA 0", UDim2.fromOffset(18, 38), UDim2.new(1, -36, 0, 24), 12, false)
	headerSummary.TextColor3 = Color3.fromRGB(205, 225, 205)

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
		PurchaseConfirmController.Cancel()
		expanded = false
		applyVisibility()
	end)

	local tabs = Instance.new("ScrollingFrame")
	tabs.Name = "Tabs"
	tabs.Position = UDim2.fromOffset(14, 70)
	tabs.Size = UDim2.new(1, -28, 0, 38)
	tabs.BackgroundTransparency = 1
	tabs.BorderSizePixel = 0
	tabs.ScrollBarThickness = 0
	tabs.ScrollingDirection = Enum.ScrollingDirection.X
	tabs.CanvasSize = UDim2.fromOffset(510, 0)
	tabs.Parent = panel

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.Parent = tabs

	createTabButton(tabs, "Stats", "Stats", 1)
	createTabButton(tabs, "Builds", "Builds", 2)
	createTabButton(tabs, "Colors", "Colors", 3)
	createTabButton(tabs, "Eyes", "Eyes", 4)
	createTabButton(tabs, "Patterns", "Patterns", 5)
	createTabButton(tabs, "Awards", "Awards", 6)

	local content = Instance.new("Frame")
	content.Name = "TabContent"
	content.Position = UDim2.fromOffset(12, 116)
	content.Size = UDim2.new(1, -24, 1, -164)
	content.BackgroundTransparency = 1
	content.Parent = panel

	local statsPage = createPage(content, "Stats")
	nameLabel = makeText(statsPage, "PlayerName", player.DisplayName, UDim2.fromOffset(18, 8), UDim2.new(1, -36, 0, 34), 20, true)
	progressLabel = makeText(statsPage, "Progress", "Level 1 • Fresh Hatchling", UDim2.fromOffset(18, 46), UDim2.new(1, -36, 0, 30), 16, true)
	currencyLabel = makeText(statsPage, "Currency", "Available DNA: 0\nLifetime DNA: 0\nCrumbs: 0", UDim2.fromOffset(18, 86), UDim2.new(1, -36, 0, 70), 14, false)
	statsLabel = makeText(statsPage, "Stats", "Rounds played: 0\nFull rounds survived: 0\nBest survival: --\nFood collected: 0\nAwards: 0 / 4", UDim2.fromOffset(18, 158), UDim2.new(1, -36, 0, 108), 13, false)
	bugLabel = makeText(statsPage, "Bug", "Current bug: Ant\nColor: Natural    Eyes: Default\nPattern: None", UDim2.fromOffset(18, 270), UDim2.new(1, -36, 0, 72), 13, true)

	createBuildsPage(content, remotes)
	createCosmeticPage(content, remotes, "Colors", "BodyColor")
	createCosmeticPage(content, remotes, "Eyes", "Eyes")
	createCosmeticPage(content, remotes, "Patterns", "Pattern")
	createAwardsPage(content)

	shopStatusLabel = makeText(panel, "ShopStatus", "Cosmetics are visual only. Gameplay power comes from your bug choice.", UDim2.fromOffset(18, -42), UDim2.new(1, -36, 0, 30), 11, true)
	shopStatusLabel.AnchorPoint = Vector2.new(0, 1)
	shopStatusLabel.Position = UDim2.new(0, 18, 1, -8)
	shopStatusLabel.TextColor3 = Color3.fromRGB(195, 225, 190)

	refreshProfile()
	applyTab()
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
			PurchaseConfirmController.Cancel()
			inRound = true
			expanded = false
		elseif state == "Ended" or state == "Eliminated" or state == "ExitedRound" or state == "Waiting" or state == "Results" or state == "MatchInProgress" then
			inRound = false
		end
		applyVisibility()
	end)

	for _, attributeName in ipairs({
		"BodyColor",
		"EyeStyle",
		"PatternStyle",
		"BugLevel",
		"BugTitle",
		"RoundsPlayed",
		"FullRoundsSurvived",
		"BestSurvival",
		"FoodCollected",
		"LifetimeDna",
		"TotalDna",
		"TotalCrumbs",
		"AchievementsUnlocked",
		"SelectedBug",
	}) do
		player:GetAttributeChangedSignal(attributeName):Connect(refreshProfile)
	end
end

return ProfileController
