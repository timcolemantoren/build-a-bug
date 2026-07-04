--!nonstrict

local Players = game:GetService("Players")

local HUDController = {}

local player = Players.LocalPlayer
local gui = nil
local statusLabel = nil
local dataLabel = nil
local progressLabel = nil
local hazardLabel = nil

local function makeLabel(parent: Instance, name: string, yOffset: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.fromOffset(460, 34)
	label.Position = UDim2.fromOffset(20, yOffset)
	label.BackgroundTransparency = 0.25
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function ensureGui()
	if gui then
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "BuildABugHUD"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	statusLabel = makeLabel(gui, "RoundStatus", 20)
	statusLabel.Text = "Build a Bug: getting ready..."

	dataLabel = makeLabel(gui, "PlayerData", 60)
	dataLabel.Text = "DNA: 0 | Crumbs: 0 | Bug: Ant"

	progressLabel = makeLabel(gui, "Progress", 100)
	progressLabel.Text = "Fresh Hatchling | Next: 25 DNA"

	hazardLabel = makeLabel(gui, "HazardWarning", 140)
	hazardLabel.Text = ""
end

function HUDController.Init(remotes)
	ensureGui()

	remotes.PlayerDataChanged.OnClientEvent:Connect(function(data)
		ensureGui()
		local dna = data.currency and data.currency.dna or 0
		local crumbs = data.currency and data.currency.crumbs or 0
		local selectedBug = data.selectedBug or "Ant"
		dataLabel.Text = string.format("DNA: %s | Crumbs: %s | Bug: %s", dna, crumbs, selectedBug)

		local current = data.progression and data.progression.current
		local nextLevel = data.progression and data.progression.next
		if current and nextLevel then
			progressLabel.Text = string.format("%s | Level %s | Next: %s DNA", current.title, current.level, nextLevel.dnaRequired)
		elseif current then
			progressLabel.Text = string.format("%s | Level %s | Max Level", current.title, current.level)
		end
	end)

	remotes.RoundStateChanged.OnClientEvent:Connect(function(state, payload)
		ensureGui()
		if state == "Started" then
			statusLabel.Text = string.format("Round started! Survive for %s seconds.", payload.durationSeconds or "?")
		elseif state == "Ended" then
			statusLabel.Text = string.format("Round ended. Survived: %s seconds.", payload.survivedSeconds or "?")
		else
			statusLabel.Text = "Round state: " .. tostring(state)
		end
	end)

	remotes.HazardWarning.OnClientEvent:Connect(function(hazard)
		ensureGui()
		hazardLabel.Text = "Hazard: " .. tostring(hazard.displayName) .. "!"

		task.delay(hazard.warningSeconds or 3, function()
			if hazardLabel then
				hazardLabel.Text = ""
			end
		end)
	end)
end

return HUDController
