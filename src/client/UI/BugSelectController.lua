--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local BugArchetypes = require(BuildABugShared.Config.BugArchetypes)
local BugOrder = require(BuildABugShared.Config.BugOrder)

local BugSelectController = {}

local player = Players.LocalPlayer
local gui = nil
local panel = nil
local expanded = false
local details = {}
local toggleButton = nil

local function makeButton(parent: Instance, text: string, position: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(180, 40)
	button.Position = position
	button.BackgroundTransparency = 0.1
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.Parent = parent
	return button
end

local function applyLayout()
	if not panel then
		return
	end

	if expanded then
		panel.Size = UDim2.fromOffset(220, 252)
		panel.Position = UDim2.new(1, -236, 0, 14)
		toggleButton.Text = "Close"
	else
		panel.Size = UDim2.fromOffset(96, 44)
		panel.Position = UDim2.new(1, -110, 0, 14)
		toggleButton.Text = "Bugs"
	end

	for _, item in ipairs(details) do
		item.Visible = expanded
	end
end

local function ensureGui(remotes)
	if gui then
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "BuildABugBugSelect"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundTransparency = 0.2
	panel.Parent = gui

	toggleButton = makeButton(panel, "Bugs", UDim2.fromOffset(8, 4))
	toggleButton.Size = UDim2.fromOffset(80, 34)
	toggleButton.MouseButton1Click:Connect(function()
		expanded = not expanded
		applyLayout()
	end)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromOffset(200, 32)
	title.Position = UDim2.fromOffset(10, 44)
	title.BackgroundTransparency = 1
	title.Text = "Choose Your Bug"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.Parent = panel
	table.insert(details, title)

	local y = 82
	for _, bugId in ipairs(BugOrder) do
		local bug = BugArchetypes[bugId]
		if bug then
			local button = makeButton(panel, bug.displayName, UDim2.fromOffset(20, y))
			button.MouseButton1Click:Connect(function()
				remotes.SelectBug:FireServer(bugId)
				expanded = false
				applyLayout()
			end)
			table.insert(details, button)
			y += 46
		end
	end

	local startButton = makeButton(panel, "Start Round", UDim2.fromOffset(20, 220))
	startButton.MouseButton1Click:Connect(function()
		remotes.StartRoundRequest:FireServer()
		expanded = false
		applyLayout()
	end)
	table.insert(details, startButton)

	applyLayout()
end

function BugSelectController.Init(remotes)
	ensureGui(remotes)
end

return BugSelectController
