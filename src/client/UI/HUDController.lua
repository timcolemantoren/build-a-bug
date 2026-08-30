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
local statsLabel = nil
local hazardLabel = nil
local countdownToken = 0
local expanded = false
local activePlayersRemaining = nil
local activePlayerCount = nil
local activePhaseName = nil

local PANEL_COLOR = Color3.fromRGB(25, 43, 48)
local BUTTON_COLOR = Color3.fromRGB(71, 104, 95)
local CREAM = Color3.fromRGB(250, 246, 232)
local BODY_TEXT = Color3.fromRGB(225, 235, 229)

local lastStatusText = "Build a Bug"
local lastDataText = "DNA: 0 | Crumbs: 0 | Bug: Ant"
local lastProgressText = "Lv 1 Fresh Hatchling | Lifetime DNA: 0 / 25"
local lastStatsText = "Rounds: 0 | Best: -- | Food: 0"

local function makeLabel(parent: Instance, name: string, yOffset: number, height: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.fromOffset(280, height)
	label.Position = UDim2.fromOffset(12, yOffset)
	label.BackgroundTransparency = 1
	label.TextColor3 = BODY_TEXT
	label.TextStrokeColor3 = Color3.fromRGB(12, 20, 22)
	label.TextStrokeTransparency = 0.82
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds or 0))
	if seconds <= 0 then
		return "--"
	end
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function applyLayout()
	if not panel then
		return
	end

	if expanded then
		panel.Size = UDim2.fromOffset(320, 176)
		toggleButton.Text = "Hide"
		statusLabel.Text = lastStatusText
		dataLabel.Visible = true
		progressLabel.Visible = true
		statsLabel.Visible = true
		hazardLabel.Visible = true
	else
		panel.Size = UDim2.fromOffset(276, 46)
		toggleButton.Text = "Info"
		statusLabel.Text = lastStatusText
		dataLabel.Visible = false
		progressLabel.Visible = false
		statsLabel.Visible = false
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
	panel.BackgroundColor3 = PANEL_COLOR
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Parent = gui

	statusLabel = makeLabel(panel, "RoundStatus", 5, 36)
	statusLabel.Size = UDim2.fromOffset(208, 36)
	statusLabel.Text = lastStatusText
	statusLabel.TextColor3 = CREAM
	statusLabel.TextStrokeTransparency = 0.88
	statusLabel.Font = Enum.Font.FredokaOne
	statusLabel.TextSize = 14

	toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleDetails"
	toggleButton.Size = UDim2.fromOffset(58, 30)
	toggleButton.Position = UDim2.new(1, -66, 0, 8)
	toggleButton.BackgroundColor3 = BUTTON_COLOR
	toggleButton.BackgroundTransparency = 0.04
	toggleButton.BorderSizePixel = 0
	toggleButton.TextColor3 = CREAM
	toggleButton.Font = Enum.Font.FredokaOne
	toggleButton.TextSize = 13
	toggleButton.Parent = panel
	toggleButton.MouseButton1Click:Connect(function()
		expanded = not expanded
		applyLayout()
	end)

	dataLabel = makeLabel(panel, "PlayerData", 44, 28)
	dataLabel.Text = lastDataText

	progressLabel = makeLabel(panel, "Progress", 72, 28)
	progressLabel.Text = lastProgressText
	progressLabel.TextSize = 12

	statsLabel = makeLabel(panel, "Stats", 100, 28)
	statsLabel.Text = lastStatsText
	statsLabel.TextSize = 12

	hazardLabel = makeLabel(panel, "HazardWarning", 132, 32)
	hazardLabel.Text = ""
	hazardLabel.TextColor3 = Color3.fromRGB(255, 190, 174)
	hazardLabel.Font = Enum.Font.FredokaOne
	hazardLabel.TextSize = 13
	hazardLabel.TextStrokeTransparency = 0.84

	applyLayout()
end

local function setStatus(text: string)
	lastStatusText = text
	if statusLabel then
		statusLabel.Text = text
	end
end

local function formatRoundStatus(remaining: number): string
	local phase = activePhaseName or "Play"
	if activePlayersRemaining and activePlayerCount then
		return string.format("%ss | %s | %s/%s", remaining, phase, activePlayersRemaining, activePlayerCount)
	end
	return string.format("%ss | %s", remaining, phase)
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

		local progression = data.progression or {}
		local current = progression.current
		local nextLevel = progression.next
		local lifetimeDna = progression.lifetimeDna or (data.stats and data.stats.lifetimeDna) or dna
		if current and nextLevel then
			lastProgressText = string.format("Lv %s %s | Lifetime DNA: %s / %s", current.level or 1, current.title, lifetimeDna, nextLevel.dnaRequired)
		elseif current then
			lastProgressText = string.format("Lv %s %s | Lifetime DNA: %s | Max Level", current.level or 1, current.title, lifetimeDna)
		end
		progressLabel.Text = lastProgressText

		local stats = data.stats or {}
		lastStatsText = string.format(
			"Rounds: %s | Best: %s | Food: %s",
			stats.roundsPlayed or 0,
			formatTime(stats.longestSurvival or 0),
			stats.foodCollected or 0
		)
		statsLabel.Text = lastStatsText
	end)

	remotes.RoundStateChanged.OnClientEvent:Connect(function(state, payload)
		ensureGui()
		payload = payload or {}
		local mapName = payload.mapName or "Backyard"

		if state == "Started" then
			activePlayersRemaining = payload.playersRemaining or payload.playerCount
			activePlayerCount = payload.playerCount
			activePhaseName = payload.phaseId or "Scavenge"
			startRoundCountdown(payload.durationSeconds or 0)
		elseif state == "PhaseChanged" then
			activePhaseName = payload.phaseId or activePhaseName
		elseif state == "FinalScramble" then
			activePhaseName = "FINAL"
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
			activePhaseName = nil
			setStatus(string.format("%s | Join circle", mapName))
		elseif state == "MatchInProgress" then
			countdownToken += 1
			setStatus(string.format("%s | Match active", mapName))
		elseif state == "Eliminated" then
			countdownToken += 1
			activePlayersRemaining = payload.playersRemaining
			activePlayerCount = payload.playerCount
			setStatus(string.format("SQUISHED! %ss | %s left", payload.survivedSeconds or 0, payload.playersRemaining or 0))
		elseif state == "ExitedRound" then
			countdownToken += 1
			activePlayersRemaining = nil
			activePlayerCount = nil
			activePhaseName = nil
			setStatus(string.format("%s | Roaming", mapName))
		elseif state == "Results" then
			countdownToken += 1
			setStatus("Round complete | Next soon")
		elseif state == "Ended" then
			countdownToken += 1
			activePlayersRemaining = nil
			activePlayerCount = nil
			activePhaseName = nil
			setStatus("Round complete")
		end
	end)

	remotes.HazardWarning.OnClientEvent:Connect(function(hazard)
		ensureGui()
		if player:GetAttribute("InRound") ~= true or (hazard.stage or "Warning") ~= "Warning" then
			return
		end

		hazardLabel.Text = tostring(hazard.displayName) .. ": " .. tostring(hazard.instruction or "MOVE!")
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
