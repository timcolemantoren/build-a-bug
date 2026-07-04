--!nonstrict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local BugArchetypes = require(BuildABugShared.Config.BugArchetypes)

local AbilityController = {}

local player = Players.LocalPlayer
local gui = nil
local button = nil
local cooldownLabel = nil
local selectedBug = "Ant"
local readyAt = 0

local function getAbilityName(): string
	local bug = BugArchetypes[selectedBug]
	if bug and bug.ability then
		return bug.ability.displayName
	end
	return "Ability"
end

local function getCooldown(): number
	local bug = BugArchetypes[selectedBug]
	if bug and bug.ability then
		return bug.ability.cooldownSeconds or 8
	end
	return 8
end

local function refreshButton()
	if not button then
		return
	end

	local remaining = math.ceil(readyAt - os.clock())
	if remaining > 0 then
		button.Text = getAbilityName()
		cooldownLabel.Text = tostring(remaining) .. "s"
	else
		button.Text = getAbilityName()
		cooldownLabel.Text = "Ready"
	end
end

local function useAbility(remotes)
	if os.clock() < readyAt then
		return
	end

	readyAt = os.clock() + getCooldown()
	refreshButton()
	remotes.UseAbility:FireServer()
end

local function ensureGui(remotes)
	if gui then
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "BuildABugAbility"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	button = Instance.new("TextButton")
	button.Name = "AbilityButton"
	button.Size = UDim2.fromOffset(150, 54)
	button.Position = UDim2.new(1, -170, 1, -78)
	button.BackgroundTransparency = 0.08
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 17
	button.Parent = gui
	button.MouseButton1Click:Connect(function()
		useAbility(remotes)
	end)

	cooldownLabel = Instance.new("TextLabel")
	cooldownLabel.Name = "Cooldown"
	cooldownLabel.Size = UDim2.fromOffset(150, 22)
	cooldownLabel.Position = UDim2.new(1, -170, 1, -100)
	cooldownLabel.BackgroundTransparency = 1
	cooldownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	cooldownLabel.TextStrokeTransparency = 0.45
	cooldownLabel.Font = Enum.Font.GothamBold
	cooldownLabel.TextSize = 14
	cooldownLabel.Parent = gui

	refreshButton()
end

function AbilityController.Init(remotes)
	ensureGui(remotes)

	remotes.PlayerDataChanged.OnClientEvent:Connect(function(data)
		selectedBug = data.selectedBug or "Ant"
		readyAt = 0
		refreshButton()
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.E then
			useAbility(remotes)
		end
	end)

	task.spawn(function()
		while true do
			refreshButton()
			task.wait(0.25)
		end
	end)
end

return AbilityController
