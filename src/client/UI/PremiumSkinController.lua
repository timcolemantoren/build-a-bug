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
local selectedSkin = player:GetAttribute("SkinStyle") or "None"
local cards = {}
local inRound = false

local DEFAULT_CARD = Color3.fromRGB(52, 57, 61)
local SELECTED_CARD = Color3.fromRGB(73, 92, 82)
local PREMIUM_CARD = Color3.fromRGB(63, 52, 76)
local SELECTED_STROKE = Color3.fromRGB(147, 205, 159)
local PREMIUM_STROKE = Color3.fromRGB(196, 147, 237)

local function setStatus(text: string, warning: boolean?)
	if statusLabel then
		statusLabel.Text = text
		statusLabel.TextColor3 = warning and Color3.fromRGB(255, 203, 150) or Color3.fromRGB(205, 224, 211)
	end
end

local function refreshCards()
	selectedSkin = player:GetAttribute("SkinStyle") or selectedSkin
	for styleId, card in pairs(cards) do
		local item = CosmeticCatalog.GetItem("Skin", styleId)
		local selected = styleId == selectedSkin
		card.frame.BackgroundColor3 = selected and SELECTED_CARD or (styleId == "None" and DEFAULT_CARD or PREMIUM_CARD)
		card.stroke.Color = selected and SELECTED_STROKE or (styleId == "None" and Color3.fromRGB(92, 98, 94) or PREMIUM_STROKE)
		card.stroke.Thickness = selected and 2 or 1
		if selected then
			card.action.Text = "SELECTED"
		elseif styleId == "None" then
			card.action.Text = "EQUIP"
		elseif RunService:IsStudio() then
			card.action.Text = "PREVIEW"
		elseif item and (item.robuxPassId or 0) > 0 then
			card.action.Text = "BUY WITH ROBUX"
		else
			card.action.Text = "ROBUX ONLY"
		end
	end
end

local function close()
	if panel then
		panel.Visible = false
	end
	if openButton then
		openButton.Visible = not inRound
	end
end

local function ensureGui(remotes)
	if gui then
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "BuildABugPremiumSkins"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	openButton = Instance.new("TextButton")
	openButton.Name = "SkinsButton"
	openButton.Size = UDim2.fromOffset(92, 38)
	openButton.Position = UDim2.new(1, -110, 0, 62)
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
	panel.Size = UDim2.new(0.88, 0, 0.78, 0)
	panel.SizeConstraint = Enum.SizeConstraint.RelativeYY
	panel.BackgroundColor3 = Color3.fromRGB(31, 33, 38)
	panel.BackgroundTransparency = 0.05
	panel.Visible = false
	panel.Parent = gui

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(620, 520)
	sizeConstraint.MinSize = Vector2.new(320, 390)
	sizeConstraint.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -110, 0, 46)
	title.Position = UDim2.fromOffset(20, 12)
	title.BackgroundTransparency = 1
	title.Text = "Premium Skins"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -40, 0, 40)
	subtitle.Position = UDim2.fromOffset(20, 54)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Full-look cosmetics only. Premium skins never change bug stats or powers."
	subtitle.TextColor3 = Color3.fromRGB(210, 211, 218)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 13
	subtitle.TextWrapped = true
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = panel

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.fromOffset(74, 34)
	closeButton.Position = UDim2.new(1, -90, 0, 16)
	closeButton.BackgroundColor3 = Color3.fromRGB(64, 65, 71)
	closeButton.Text = "Close"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 13
	closeButton.Parent = panel
	closeButton.MouseButton1Click:Connect(close)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "SkinCards"
	scroll.Position = UDim2.fromOffset(20, 104)
	scroll.Size = UDim2.new(1, -40, 1, -166)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5
	scroll.CanvasSize = UDim2.fromOffset(0, 4 * 116)
	scroll.Parent = panel

	local y = 0
	for _, styleId in ipairs(CosmeticCatalog.Slots.Skin.order) do
		local item = CosmeticCatalog.GetItem("Skin", styleId)
		local style = CosmeticStyles.GetStyle("Skin", styleId)
		if item and style then
			local currentStyleId = styleId
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, -8, 0, 106)
			frame.Position = UDim2.fromOffset(0, y)
			frame.BackgroundColor3 = DEFAULT_CARD
			frame.Parent = scroll

			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 1
			stroke.Color = PREMIUM_STROKE
			stroke.Transparency = 0.08
			stroke.Parent = frame

			local swatch = Instance.new("Frame")
			swatch.Size = UDim2.fromOffset(66, 66)
			swatch.Position = UDim2.fromOffset(12, 12)
			swatch.BackgroundColor3 = style.previewColor or Color3.fromRGB(100, 100, 100)
			swatch.Parent = frame

			local name = Instance.new("TextLabel")
			name.Size = UDim2.new(1, -230, 0, 30)
			name.Position = UDim2.fromOffset(92, 10)
			name.BackgroundTransparency = 1
			name.Text = item.displayName
			name.TextColor3 = Color3.new(1, 1, 1)
			name.Font = Enum.Font.GothamBold
			name.TextSize = 17
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.Parent = frame

			local detail = Instance.new("TextLabel")
			detail.Size = UDim2.new(1, -230, 0, 44)
			detail.Position = UDim2.fromOffset(92, 39)
			detail.BackgroundTransparency = 1
			detail.Text = currentStyleId == "None" and "Use your normal mix-and-match cosmetics." or "Premium • Robux only • visual effect"
			detail.TextColor3 = Color3.fromRGB(211, 205, 220)
			detail.Font = Enum.Font.Gotham
			detail.TextSize = 12
			detail.TextWrapped = true
			detail.TextXAlignment = Enum.TextXAlignment.Left
			detail.Parent = frame

			local action = Instance.new("TextButton")
			action.Size = UDim2.fromOffset(118, 42)
			action.Position = UDim2.new(1, -132, 0.5, -21)
			action.BackgroundColor3 = currentStyleId == "None" and Color3.fromRGB(69, 82, 73) or Color3.fromRGB(99, 69, 119)
			action.TextColor3 = Color3.new(1, 1, 1)
			action.Font = Enum.Font.GothamBold
			action.TextSize = 11
			action.Parent = frame

			action.MouseButton1Click:Connect(function()
				if inRound or currentStyleId == selectedSkin then
					return
				end
				if currentStyleId == "None" or RunService:IsStudio() then
					remotes.SetPremiumSkin:FireServer(currentStyleId)
					setStatus(RunService:IsStudio() and currentStyleId ~= "None" and ("Studio preview: " .. item.displayName) or ("Equipped " .. item.displayName), false)
					return
				end

				local passId = tonumber(item.robuxPassId) or 0
				if passId <= 0 then
					setStatus(item.displayName .. " is Robux-only and not on sale yet.", true)
					return
				end
				MarketplaceService:PromptGamePassPurchase(player, passId)
			end)

			cards[currentStyleId] = { frame = frame, stroke = stroke, action = action }
			y += 116
		end
	end

	statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -40, 0, 42)
	statusLabel.Position = UDim2.new(0, 20, 1, -52)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = RunService:IsStudio() and "Studio: premium skins are preview-unlocked for testing." or "Premium skins require Robux and never improve gameplay."
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
			task.delay(0.4, function()
				remotes.SetPremiumSkin:FireServer(styleId)
			end)
		end
	end)

	player:GetAttributeChangedSignal("SkinStyle"):Connect(refreshCards)
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
