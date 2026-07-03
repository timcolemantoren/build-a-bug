--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local BugArchetypes = require(BuildABugShared.Config.BugArchetypes)

local BugSelectController = {}

local player = Players.LocalPlayer
local gui = nil

local function makeButton(parent: Instance, text: string, position: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(180, 44)
	button.Position = position
	button.BackgroundTransparency = 0.1
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 18
	button.Parent = parent
	return button
end

local function ensureGui(remotes)
	if gui then
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "BuildABugBugSelect"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromOffset(220, 260)
	panel.Position = UDim2.new(1, -240, 0, 20)
	panel.BackgroundTransparency = 0.2
	panel.Parent = gui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromOffset(200, 36)
	title.Position = UDim2.fromOffset(10, 10)
	title.BackgroundTransparency = 1
	title.Text = "Choose Your Bug"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.Parent = panel

	local y = 56
	for bugId, bug in pairs(BugArchetypes) do
		local button = makeButton(panel, bug.displayName, UDim2.fromOffset(20, y))
		button.MouseButton1Click:Connect(function()
			remotes.SelectBug:FireServer(bugId)
		end)
		y += 52
	end

	local startButton = makeButton(panel, "Start Round", UDim2.fromOffset(20, 210))
	startButton.MouseButton1Click:Connect(function()
		remotes.StartRoundRequest:FireServer()
	end)
end

function BugSelectController.Init(remotes)
	ensureGui(remotes)
end

return BugSelectController
