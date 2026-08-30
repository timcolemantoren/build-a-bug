--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local CosmeticCatalog = require(BuildABugShared.Config.CosmeticCatalog)
local CosmeticStyles = require(BuildABugShared.Config.CosmeticStyles)

local PremiumSkinController = {}

local player = Players.LocalPlayer
local gui = nil
local openButton = nil
local panel = nil
local statusLabel = nil
local cancelPreviewButton = nil
local selectedSkin = player:GetAttribute("SkinStyle") or "None"
local previewSkin = player:GetAttribute("PreviewSkinStyle")
local cards = {}
local ownedCache = { None = true }
local inRound = false
local activeRemotes = nil

local DEFAULT_CARD = Color3.fromRGB(52, 57, 61)
local SELECTED_CARD = Color3.fromRGB(73, 92, 82)
local PREVIEW_CARD = Color3.fromRGB(70, 69, 96)
local PREMIUM_CARD = Color3.fromRGB(63, 52, 76)
local SELECTED_STROKE = Color3.fromRGB(147, 205, 159)
local PREVIEW_STROKE = Color3.fromRGB(117, 201, 229)
local PREMIUM_STROKE = Color3.fromRGB(196, 147, 237)

local function setStatus(text: string, warning: boolean?)
	if statusLabel then
		statusLabel.Text = text
		statusLabel.TextColor3 = warning and Color3.fromRGB(255, 203, 150) or Color3.fromRGB(205, 224, 211)
	end
end

local function ownsSkin(styleId: string): boolean
	if styleId == "None" or RunService:IsStudio() then
		return true
	end
	if styleId == selectedSkin then
		return true
	end
	return ownedCache[styleId] == true
end

local function clearPreview()
	previewSkin = nil
	if activeRemotes then
		activeRemotes.PreviewPremiumSkin:FireServer(nil)
	end
end

local function refreshCards()
	selectedSkin = player:GetAttribute("SkinStyle") or selectedSkin
	previewSkin = player:GetAttribute("PreviewSkinStyle") or previewSkin

	for styleId, card in pairs(cards) do
		local item = CosmeticCatalog.GetItem("Skin", styleId)
		local selected = styleId == selectedSkin and previewSkin == nil
		local previewing = styleId == previewSkin
		local owned = ownsSkin(styleId)
		local passId = item and tonumber(item.robuxPassId) or 0

		card.frame.BackgroundColor3 = selected and SELECTED_CARD or (previewing and PREVIEW_CARD or (styleId == "None" and DEFAULT_CARD or PREMIUM_CARD))
		card.stroke.Color = selected and SELECTED_STROKE or (previewing and PREVIEW_STROKE or (styleId == "None" and Color3.fromRGB(92, 98, 94) or PREMIUM_STROKE))
		card.stroke.Thickness = (selected or previewing) and 2 or 1

		if styleId == "None" then
			card.preview.Text = previewSkin and "RESET PREVIEW" or "PREVIEW"
		elseif previewing then
			card.preview.Text = "PREVIEWING"
		else
			card.preview.Text = "PREVIEW"
		end

		if selected then
			card.action.Text = "SELECTED"
		elseif owned then
			card.action.Text = RunService:IsStudio() and "EQUIP TEST" or "EQUIP"
		elseif passId > 0 then
			card.action.Text = "BUY"
		else
			card.action.Text = "COMING SOON"
		end
	end

	if cancelPreviewButton then
		cancelPreviewButton.Visible = previewSkin ~= nil
	end
end

local function close()
	clearPreview()
	if panel then
		panel.Visible = false
	end
	if openButton then
		openButton.Visible = not inRound
	end
	refreshCards()
end

local function previewStyle(remotes, styleId: string, item)
	if inRound then
		return
	end
	if styleId == "None" then
		clearPreview()
		setStatus("Preview cleared. Your equipped look is showing again.", false)
		refreshCards()
		return
	end
	previewSkin = styleId
	remotes.PreviewPremiumSkin:FireServer(styleId)
	setStatus("Previewing " .. item.displayName .. " on your current bug. Nothing has been purchased or equipped.", false)
	refreshCards()
end

local function useOrBuy(remotes, styleId: string, item)
	if inRound or styleId == selectedSkin and previewSkin == nil then
		return
	end

	if ownsSkin(styleId) then
		clearPreview()
		remotes.SetPremiumSkin:FireServer(styleId)
		setStatus(styleId == "None" and "Returned to your normal mix-and-match look." or ("Equipped " .. item.displayName .. "."), false)
		refreshCards()
		return
	end

	local passId = tonumber(item.robuxPassId) or 0
	if passId <= 0 then
		setStatus(item.displayName .. " is in the launch lineup but is not on sale yet. You can still preview it.", true)
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, passId)
end

local function checkOwnedPasses()
	if RunService:IsStudio() then
		return
	end
	for _, styleId in ipairs(CosmeticCatalog.Slots.Skin.order) do
		local item = CosmeticCatalog.GetItem("Skin", styleId)
		local passId = item and tonumber(item.robuxPassId) or 0
		if styleId ~= "None" and passId > 0 then
			task.spawn(function()
				local ok, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
				end)
				if ok then
					ownedCache[styleId] = owns == true
					refreshCards()
				end
			end)
		end
	end
end

local function ensureGui(remotes)
	if gui then
		return
	end
	activeRemotes = remotes

	gui = Instance.new("ScreenGui")
	gui.Name = "BuildABugPremiumSkins"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 7
	gui.Parent = player:WaitForChild("PlayerGui")

	openButton = Instance.new("TextButton")
	openButton.Name = "SkinsButton"
	openButton.Size = UDim2.fromOffset(88, 36)
	openButton.Position = UDim2.new(1, -206, 0, 14)
	openButton.BackgroundColor3 = Color3.fromRGB(78, 53, 92)
	openButton.BackgroundTransparency = 0.06
	openButton.Text = "Skins"
	openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	openButton.Font = Enum.Font.GothamBold
	openButton.TextSize = 15
	openButton.Parent = gui

	panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0.90, 0, 0.84, 0)
	panel.BackgroundColor3 = Color3.fromRGB(31, 33, 38)
	panel.BackgroundTransparency = 0.04
	panel.Visible = false
	panel.Parent = gui

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(660, 560)
	sizeConstraint.MinSize = Vector2.new(330, 410)
	sizeConstraint.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -110, 0, 42)
	title.Position = UDim2.fromOffset(20, 10)
	title.BackgroundTransparency = 1
	title.Text = "Skin Shop"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -40, 0, 48)
	subtitle.Position = UDim2.fromOffset(20, 50)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Preview first. Buy only if you love it. Skins change your character look, never your powers."
	subtitle.TextColor3 = Color3.fromRGB(210, 211, 218)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 13
	subtitle.TextWrapped = true
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = panel

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseSkins"
	closeButton.Size = UDim2.fromOffset(74, 34)
	closeButton.Position = UDim2.new(1, -90, 0, 14)
	closeButton.BackgroundColor3 = Color3.fromRGB(64, 65, 71)
	closeButton.Text = "Close"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 13
	closeButton.Parent = panel
	closeButton.MouseButton1Click:Connect(close)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "SkinCards"
	scroll.Position = UDim2.fromOffset(18, 104)
	scroll.Size = UDim2.new(1, -36, 1, -190)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5
	scroll.CanvasSize = UDim2.fromOffset(0, #CosmeticCatalog.Slots.Skin.order * 150)
	scroll.Parent = panel

	local y = 0
	for _, styleId in ipairs(CosmeticCatalog.Slots.Skin.order) do
		local item = CosmeticCatalog.GetItem("Skin", styleId)
		local style = CosmeticStyles.GetStyle("Skin", styleId)
		if item and style then
			local currentStyleId = styleId
			local frame = Instance.new("Frame")
			frame.Name = currentStyleId .. "Card"
			frame.Size = UDim2.new(1, -8, 0, 142)
			frame.Position = UDim2.fromOffset(0, y)
			frame.BackgroundColor3 = DEFAULT_CARD
			frame.BackgroundTransparency = 0.02
			frame.Parent = scroll

			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 1
			stroke.Color = PREMIUM_STROKE
			stroke.Transparency = 0.08
			stroke.Parent = frame

			local swatch = Instance.new("Frame")
			swatch.Name = "Swatch"
			swatch.Size = UDim2.fromOffset(58, 58)
			swatch.Position = UDim2.fromOffset(12, 14)
			swatch.BackgroundColor3 = style.previewColor or Color3.fromRGB(100, 100, 100)
			swatch.BorderSizePixel = 0
			swatch.Parent = frame

			local name = Instance.new("TextLabel")
			name.Size = UDim2.new(1, -96, 0, 28)
			name.Position = UDim2.fromOffset(82, 10)
			name.BackgroundTransparency = 1
			name.Text = item.displayName
			name.TextColor3 = Color3.new(1, 1, 1)
			name.Font = Enum.Font.GothamBold
			name.TextSize = 17
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.Parent = frame

			local detail = Instance.new("TextLabel")
			detail.Size = UDim2.new(1, -96, 0, 56)
			detail.Position = UDim2.fromOffset(82, 37)
			detail.BackgroundTransparency = 1
			detail.Text = style.tagline or (currentStyleId == "None" and "Use your normal mix-and-match cosmetics." or "Premium character look with custom accessories.")
			detail.TextColor3 = Color3.fromRGB(211, 205, 220)
			detail.Font = Enum.Font.Gotham
			detail.TextSize = 12
			detail.TextWrapped = true
			detail.TextXAlignment = Enum.TextXAlignment.Left
			detail.TextYAlignment = Enum.TextYAlignment.Top
			detail.Parent = frame

			local previewButton = Instance.new("TextButton")
			previewButton.Name = "Preview"
			previewButton.Size = UDim2.fromOffset(100, 34)
			previewButton.Position = UDim2.new(0.5, -108, 1, -42)
			previewButton.BackgroundColor3 = Color3.fromRGB(66, 94, 106)
			previewButton.Text = "PREVIEW"
			previewButton.TextColor3 = Color3.new(1, 1, 1)
			previewButton.Font = Enum.Font.GothamBold
			previewButton.TextSize = 11
			previewButton.Parent = frame
			previewButton.MouseButton1Click:Connect(function()
				previewStyle(remotes, currentStyleId, item)
			end)

			local action = Instance.new("TextButton")
			action.Name = "Action"
			action.Size = UDim2.fromOffset(116, 34)
			action.Position = UDim2.new(0.5, 4, 1, -42)
			action.BackgroundColor3 = currentStyleId == "None" and Color3.fromRGB(69, 82, 73) or Color3.fromRGB(99, 69, 119)
			action.TextColor3 = Color3.new(1, 1, 1)
			action.Font = Enum.Font.GothamBold
			action.TextSize = 11
			action.Parent = frame
			action.MouseButton1Click:Connect(function()
				useOrBuy(remotes, currentStyleId, item)
			end)

			cards[currentStyleId] = { frame = frame, stroke = stroke, preview = previewButton, action = action }
			y += 150
		end
	end

	cancelPreviewButton = Instance.new("TextButton")
	cancelPreviewButton.Name = "CancelPreview"
	cancelPreviewButton.Size = UDim2.fromOffset(126, 34)
	cancelPreviewButton.Position = UDim2.new(1, -146, 1, -72)
	cancelPreviewButton.BackgroundColor3 = Color3.fromRGB(64, 72, 79)
	cancelPreviewButton.Text = "Cancel Preview"
	cancelPreviewButton.TextColor3 = Color3.new(1, 1, 1)
	cancelPreviewButton.Font = Enum.Font.GothamBold
	cancelPreviewButton.TextSize = 11
	cancelPreviewButton.Visible = false
	cancelPreviewButton.Parent = panel
	cancelPreviewButton.MouseButton1Click:Connect(function()
		clearPreview()
		setStatus("Preview cleared. Your equipped look is showing again.", false)
		refreshCards()
	end)

	statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -180, 0, 54)
	statusLabel.Position = UDim2.new(0, 20, 1, -78)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = RunService:IsStudio() and "Studio: all launch skins can be previewed and test-equipped." or "Preview is free. Buying a skin never improves gameplay."
	statusLabel.TextColor3 = Color3.fromRGB(205, 224, 211)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 12
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = panel

	openButton.MouseButton1Click:Connect(function()
		if inRound then
			return
		end
		panel.Visible = true
		openButton.Visible = false
		refreshCards()
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(finishedPlayer, passId, wasPurchased)
		if finishedPlayer ~= player or not wasPurchased then
			return
		end
		local slot, styleId = CosmeticCatalog.GetItemByRobuxPassId(passId)
		if slot == "Skin" and styleId then
			ownedCache[styleId] = true
			clearPreview()
			task.delay(0.4, function()
				remotes.SetPremiumSkin:FireServer(styleId)
			end)
		end
	end)

	player:GetAttributeChangedSignal("SkinStyle"):Connect(function()
		selectedSkin = player:GetAttribute("SkinStyle") or selectedSkin
		refreshCards()
	end)
	player:GetAttributeChangedSignal("PreviewSkinStyle"):Connect(function()
		previewSkin = player:GetAttribute("PreviewSkinStyle")
		refreshCards()
	end)

	checkOwnedPasses()
	refreshCards()
end

function PremiumSkinController.Init(remotes)
	ensureGui(remotes)
	remotes.RoundStateChanged.OnClientEvent:Connect(function(state)
		if state == "Started" then
			inRound = true
			close()
		elseif state == "Ended" or state == "Eliminated" or state == "ExitedRound" or state == "Waiting" or state == "Results" or state == "MatchInProgress" then
			inRound = false
			if panel and not panel.Visible and openButton then
				openButton.Visible = true
			end
		end
	end)
end

return PremiumSkinController
