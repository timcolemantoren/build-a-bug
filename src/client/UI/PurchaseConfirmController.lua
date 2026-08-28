--!nonstrict

local Players = game:GetService("Players")

local PurchaseConfirmController = {}

local player = Players.LocalPlayer
local gui = nil
local overlay = nil
local titleLabel = nil
local detailLabel = nil
local confirmButton = nil
local cancelButton = nil
local pendingAction = nil

local function clearPending()
	pendingAction = nil
	if overlay then
		overlay.Visible = false
	end
end

local function ensureGui()
	if gui then
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "BuildABugPurchaseConfirm"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 30
	gui.Parent = player:WaitForChild("PlayerGui")

	overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(10, 12, 11)
	overlay.BackgroundTransparency = 0.32
	overlay.BorderSizePixel = 0
	overlay.Active = true
	overlay.Visible = false
	overlay.Parent = gui

	local card = Instance.new("Frame")
	card.Name = "ConfirmationCard"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.new(0.84, 0, 0, 238)
	card.BackgroundColor3 = Color3.fromRGB(34, 40, 36)
	card.BackgroundTransparency = 0.02
	card.BorderSizePixel = 0
	card.Parent = overlay

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(300, 220)
	sizeConstraint.MaxSize = Vector2.new(430, 238)
	sizeConstraint.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(137, 174, 132)
	stroke.Thickness = 2
	stroke.Transparency = 0.12
	stroke.Parent = card

	titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Position = UDim2.fromOffset(18, 14)
	titleLabel.Size = UDim2.new(1, -36, 0, 36)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Confirm Purchase"
	titleLabel.TextColor3 = Color3.fromRGB(250, 252, 248)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 20
	titleLabel.TextWrapped = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.Parent = card

	detailLabel = Instance.new("TextLabel")
	detailLabel.Name = "Details"
	detailLabel.Position = UDim2.fromOffset(18, 54)
	detailLabel.Size = UDim2.new(1, -36, 0, 104)
	detailLabel.BackgroundTransparency = 1
	detailLabel.Text = ""
	detailLabel.TextColor3 = Color3.fromRGB(220, 228, 220)
	detailLabel.Font = Enum.Font.Gotham
	detailLabel.TextSize = 14
	detailLabel.TextWrapped = true
	detailLabel.TextXAlignment = Enum.TextXAlignment.Center
	detailLabel.TextYAlignment = Enum.TextYAlignment.Center
	detailLabel.Parent = card

	cancelButton = Instance.new("TextButton")
	cancelButton.Name = "Cancel"
	cancelButton.Size = UDim2.new(0.42, 0, 0, 42)
	cancelButton.Position = UDim2.new(0.05, 0, 1, -58)
	cancelButton.BackgroundColor3 = Color3.fromRGB(72, 78, 74)
	cancelButton.BackgroundTransparency = 0.04
	cancelButton.Text = "Cancel"
	cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelButton.Font = Enum.Font.GothamBold
	cancelButton.TextSize = 15
	cancelButton.Parent = card
	cancelButton.MouseButton1Click:Connect(clearPending)

	confirmButton = Instance.new("TextButton")
	confirmButton.Name = "Confirm"
	confirmButton.Size = UDim2.new(0.42, 0, 0, 42)
	confirmButton.Position = UDim2.new(0.53, 0, 1, -58)
	confirmButton.BackgroundColor3 = Color3.fromRGB(74, 116, 77)
	confirmButton.BackgroundTransparency = 0.02
	confirmButton.Text = "Buy"
	confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmButton.Font = Enum.Font.GothamBold
	confirmButton.TextSize = 15
	confirmButton.Parent = card
	confirmButton.MouseButton1Click:Connect(function()
		local action = pendingAction
		clearPending()
		if action then
			action()
		end
	end)
end

function PurchaseConfirmController.Request(options, onConfirm)
	ensureGui()
	options = options or {}

	local itemName = tostring(options.itemName or "this cosmetic")
	local cost = math.max(0, tonumber(options.cost) or 0)
	local balance = math.max(0, tonumber(options.balance) or 0)
	local remaining = math.max(0, balance - cost)

	titleLabel.Text = "Unlock " .. itemName .. "?"
	detailLabel.Text = string.format(
		"Cost: %s DNA\nCurrent balance: %s DNA\nBalance after purchase: %s DNA\n\nThis unlock is permanent.",
		tostring(cost),
		tostring(balance),
		tostring(remaining)
	)
	confirmButton.Text = "Buy for " .. tostring(cost) .. " DNA"
	pendingAction = onConfirm
	overlay.Visible = true
end

function PurchaseConfirmController.Cancel()
	clearPending()
end

return PurchaseConfirmController
