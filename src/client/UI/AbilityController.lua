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
local feedbackLabel = nil
local selectedBug = "Ant"
local readyAt = 0
local feedbackToken = 0
local inRound = false

local CREAM = Color3.fromRGB(250, 246, 232)
local ABILITY_COLOR = Color3.fromRGB(57, 91, 86)

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

local function getFeedbackText(): string
	if selectedBug == "Ant" then
		return "+2 bonus food"
	elseif selectedBug == "Beetle" then
		return "Shell Block active"
	elseif selectedBug == "Grasshopper" then
		return "Leap!"
	elseif selectedBug == "Ladybug" then
		return "Wing Burst!"
	elseif selectedBug == "Mantis" then
		return "Pounce!"
	elseif selectedBug == "Dragonfly" then
		return "Air Dash!"
	elseif selectedBug == "Pillbug" then
		return "Roll Away!"
	end

	return "Ability used"
end

local function updateVisibility()
	if button then
		button.Visible = inRound
	end
	if cooldownLabel then
		cooldownLabel.Visible = inRound
	end
	if feedbackLabel and not inRound then
		feedbackLabel.Visible = false
	end
end

local function showFeedback(text: string)
	if not feedbackLabel or not inRound then
		return
	end

	feedbackToken += 1
	local token = feedbackToken
	feedbackLabel.Text = text
	feedbackLabel.Visible = true

	task.delay(1.4, function()
		if token == feedbackToken and feedbackLabel then
			feedbackLabel.Visible = false
		end
	end)
end

local function refreshButton()
	if not button then
		return
	end

	local remaining = math.ceil(readyAt - os.clock())
	button.Text = getAbilityName()
	if remaining > 0 then
		cooldownLabel.Text = tostring(remaining) .. "s"
		cooldownLabel.TextColor3 = Color3.fromRGB(229, 212, 157)
	else
		cooldownLabel.Text = "Ready"
		cooldownLabel.TextColor3 = CREAM
	end
end

local function useAbility(remotes)
	if not inRound or os.clock() < readyAt then
		return
	end

	readyAt = os.clock() + getCooldown()
	refreshButton()
	showFeedback(getFeedbackText())
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
	button.BackgroundColor3 = ABILITY_COLOR
	button.BackgroundTransparency = 0.04
	button.BorderSizePixel = 0
	button.TextColor3 = CREAM
	button.Font = Enum.Font.FredokaOne
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
	cooldownLabel.TextColor3 = CREAM
	cooldownLabel.TextStrokeColor3 = Color3.fromRGB(12, 20, 22)
	cooldownLabel.TextStrokeTransparency = 0.82
	cooldownLabel.Font = Enum.Font.GothamMedium
	cooldownLabel.TextSize = 13
	cooldownLabel.Parent = gui

	feedbackLabel = Instance.new("TextLabel")
	feedbackLabel.Name = "Feedback"
	feedbackLabel.Size = UDim2.fromOffset(190, 26)
	feedbackLabel.Position = UDim2.new(1, -190, 1, -132)
	feedbackLabel.BackgroundTransparency = 1
	feedbackLabel.TextColor3 = CREAM
	feedbackLabel.TextStrokeColor3 = Color3.fromRGB(12, 20, 22)
	feedbackLabel.TextStrokeTransparency = 0.76
	feedbackLabel.Font = Enum.Font.FredokaOne
	feedbackLabel.TextSize = 15
	feedbackLabel.Visible = false
	feedbackLabel.Parent = gui

	refreshButton()
	updateVisibility()
end

function AbilityController.Init(remotes)
	ensureGui(remotes)

	remotes.PlayerDataChanged.OnClientEvent:Connect(function(data)
		selectedBug = data.selectedBug or "Ant"
		readyAt = 0
		refreshButton()
	end)

	remotes.RoundStateChanged.OnClientEvent:Connect(function(state, _payload)
		if state == "Started" then
			inRound = true
			readyAt = 0
		elseif state == "Ended" or state == "Eliminated" or state == "ExitedRound" or state == "Waiting" or state == "Results" or state == "MatchInProgress" then
			inRound = false
		end
		refreshButton()
		updateVisibility()
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
