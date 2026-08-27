--!nonstrict

local Players = game:GetService("Players")

local HUDController = {}

local player = Players.LocalPlayer
local gui = nil
local panel = nil
local toggleButton = nil
local statusLabel = nil
local dataLabel = nil
local progressLabel = nil
local hazardLabel = nil
local countdownToken = 0
local expanded = false
local activePlayersRemaining = nil
local activePlayerCount = nil

local lastStatusText = "Build a Bug"
local lastDataText = "DNA: 0 | Crumbs: 0 | Bug: Ant"
local lastProgressText = "Fresh Hatchling | Next: 25 DNA"

local function makeLabel(parent: Instance, name: string, yOffset: number, height: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.fromOffset(250, height)
	label.Position = UDim2.fromOffset(10, yOffset)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.45
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function applyLayout()
	if not panel then
		return
	end

	if expanded then
		panel.Size = UDim2.fromOffset(300, 148)
		toggleButton.Text = "Hide"
		statusLabel.Text = lastStatusText
		dataLabel.Visible = true
		progressLabel.Visible = true
		hazardLabel.Visible = true
	else
		panel.Size = UDim2.fromOffset(250, 44)
		toggleButton.Text = "Info"
		statusLabel.Text = lastStatusText
		dataLabel.Visible = false
		progressLabel.Visible = false
		hazardLabel.Visible = false
	end
end

local function ensureGui()
	if gui then
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "BuildABugHUD"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	panel = Instance.new("Frame")
	panel.Name = "CompactPanel"
	panel.Position = UDim2.fromOffset(14, 14)
	panel.BackgroundTransparency = 0.25
	panel.Parent = gui

	statusLabel = makeLabel(panel, "RoundStatus", 5, 34)
	statusLabel.Size = UDim2.fromOffset(190, 34)
	statusLabel.Text = lastStatusText

	toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleDetails"
	toggleButton.Size = UDim2.fromOffset(56, 28)
	toggleButton.Position = UDim2.new(1, -64, 0, 8)
	toggleButton.BackgroundTransparency = 0.1
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextSize = 14
	toggleButton.Parent = panel
	toggleButton.MouseButton1Click:Connect(function()
		expanded = not expanded
		applyLayout()
	end)

	dataLabel = makeLabel(panel, "PlayerData", 44, 28)
	dataLabel.Text = lastDataText

	progressLabel = makeLabel(panel, "Progress", 72, 28)
	progressLabel.Text = lastProgressText

	hazardLabel = makeLabel(panel, "HazardWarning", 104, 32)
	hazardLabel.Text = ""
	hazardLabel.TextColor3 = Color3.fromRGB(255, 205, 205)

	applyLayout()
end

local function setStatus(text: string)
	lastStatusText = text
	if statusLabel then
		statusLabel.Text = text
	end
end

local function formatRoundStatus(remaining: number): string
	if activePlayersRemaining and activePlayerCount then
		return string.format("%ss | Bugs: %s/%s", remaining, activePlayersRemaining, activePlayerCount)
	end
	return string.format("Time: %ss", remaining)
end

local function startRoundCountdown(durationSeconds: number)
	countdownToken += 1
	local token = countdownToken
	local remaining = math.floor(durationSeconds)

	task.spawn(function()
		while remaining >= 0 and token == countdownToken do
			setStatus(formatRoundStatus(remaining))
			task.wait(1)
			remaining -= 1
		end
	end)
end

function HUDController.Init(remotes)
	ensureGui()

	remotes.PlayerDataChanged.OnClientEvent:Connect(function(data)
		ensureGui()
		local dna = data.currency and data.currency.dna or 0
		local crumbs = data.currency and data.currency.crumbs or 0
		local selectedBug = data.selectedBug or "Ant"
		lastDataText = string.format("DNA: %s | Crumbs: %s | Bug: %s", dna, crumbs, selectedBug)
		dataLabel.Text = lastDataText

		local current = data.progression and data.progression.current
		local nextLevel = data.progression and data.progression.next
		if current and nextLevel then
			lastProgressText = string.format("%s | Next: %s DNA", current.title, nextLevel.dnaRequired)
		elseif current then
			lastProgressText = string.format("%s | Max Level", current.title)
		end
		progressLabel.Text = lastProgressText
	end)

	remotes.RoundStateChanged.OnClientEvent:Connect(function(state, payload)
		ensureGui()
		payload = payload or {}
		local mapName = payload.mapName or "Backyard"

		if state == "Started" then
			activePlayersRemaining = payload.playersRemaining or payload.playerCount
			activePlayerCount = payload.playerCount
			startRoundCountdown(payload.durationSeconds or 0)
		elseif state == "RosterUpdate" then
			activePlayersRemaining = payload.playersRemaining or activePlayersRemaining
			activePlayerCount = payload.playerCount or activePlayerCount
		elseif state == "Countdown" then
			countdownToken += 1
			local lockText = payload.locked and "LOCKED" or "Join circle"
			setStatus(string.format("%s | %ss | %s queued", lockText, payload.seconds or 0, payload.queuedPlayers or 0))
		elseif state == "RosterLocked" then
			countdownToken += 1
			setStatus(string.format("ROSTER LOCKED | %ss", payload.seconds or 0))
		elseif state == "Waiting" then
			countdownToken += 1
			activePlayersRemaining = nil
			activePlayerCount = nil
			setStatus(string.format("%s | Join circle", mapName))
		elseif state == "MatchInProgress" then
			countdownToken += 1
			setStatus(string.format("%s | Match active", mapName))
		elseif state == "Eliminated" then
			countdownToken += 1
			activePlayersRemaining = payload.playersRemaining
			activePlayerCount = payload.playerCount
			setStatus(string.format("SQUISHED! %ss | %s left", payload.survivedSeconds or 0, payload.playersRemaining or 0))
		elseif state == "Results" then
			countdownToken += 1
			setStatus("Round complete | Next soon")
		elseif state == "Ended" then
			countdownToken += 1
			activePlayersRemaining = nil
			activePlayerCount = nil
			setStatus("Round complete")
		else
			setStatus("State: " .. tostring(state))
		end
	end)

	remotes.HazardWarning.OnClientEvent:Connect(function(hazard)
		ensureGui()
		if player:GetAttribute("InRound") ~= true then
			return
		end

		hazardLabel.Text = "Hazard: " .. tostring(hazard.displayName) .. "!"
		if not expanded then
			setStatus("Hazard: " .. tostring(hazard.displayName))
		end

		task.delay(hazard.warningSeconds or 3, function()
			if hazardLabel then
				hazardLabel.Text = ""
			end
		end)
	end)
end

return HUDController
