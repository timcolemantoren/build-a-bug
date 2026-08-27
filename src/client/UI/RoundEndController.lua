--!nonstrict

local Players = game:GetService("Players")

local RoundEndController = {}

local player = Players.LocalPlayer
local gui = nil
local panel = nil
local titleLabel = nil
local summaryLabel = nil
local playAgainButton = nil
local roamButton = nil
local latestData = nil
local noticeToken = 0

local function makeLabel(parent: Instance, name: string, y: number, height: number, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.fromOffset(320, height)
	label.Position = UDim2.fromOffset(20, y)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.45
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function setResultButtonsVisible(visible: boolean)
	if playAgainButton then
		playAgainButton.Visible = visible
	end
	if roamButton then
		roamButton.Visible = visible
	end
end

local function ensureGui(remotes)
	if gui then
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "BuildABugRoundEnd"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromOffset(390, 320)
	panel.Position = UDim2.new(0.5, -195, 0.5, -160)
	panel.BackgroundTransparency = 0.15
	panel.Visible = false
	panel.Parent = gui

	titleLabel = makeLabel(panel, "Title", 18, 42, 24)
	titleLabel.Size = UDim2.fromOffset(350, 42)
	titleLabel.Text = "Round Complete!"

	summaryLabel = makeLabel(panel, "Summary", 66, 132, 17)
	summaryLabel.Size = UDim2.fromOffset(350, 132)
	summaryLabel.Text = ""

	playAgainButton = Instance.new("TextButton")
	playAgainButton.Name = "PlayAgain"
	playAgainButton.Size = UDim2.fromOffset(230, 44)
	playAgainButton.Position = UDim2.fromOffset(80, 208)
	playAgainButton.BackgroundTransparency = 0.05
	playAgainButton.Text = "Join Next Match"
	playAgainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	playAgainButton.Font = Enum.Font.GothamBold
	playAgainButton.TextSize = 18
	playAgainButton.Parent = panel
	playAgainButton.MouseButton1Click:Connect(function()
		panel.Visible = false
		remotes.StartRoundRequest:FireServer()
	end)

	roamButton = Instance.new("TextButton")
	roamButton.Name = "RoamBackyard"
	roamButton.Size = UDim2.fromOffset(230, 40)
	roamButton.Position = UDim2.fromOffset(80, 262)
	roamButton.BackgroundTransparency = 0.18
	roamButton.Text = "Roam Backyard"
	roamButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	roamButton.Font = Enum.Font.GothamBold
	roamButton.TextSize = 17
	roamButton.Parent = panel
	roamButton.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)
end

local function showEliminated(payload)
	if not panel then
		return
	end

	noticeToken += 1
	local token = noticeToken
	titleLabel.Text = "SQUISHED!"
	summaryLabel.Text = string.format(
		"You survived %s seconds.\n%s bug%s still in the match.\nYour rewards will be totaled when the round ends.",
		tostring(payload and payload.survivedSeconds or 0),
		tostring(payload and payload.playersRemaining or 0),
		(payload and payload.playersRemaining == 1) and " is" or "s are"
	)
	setResultButtonsVisible(false)
	panel.Visible = true

	task.delay(3, function()
		if token == noticeToken and panel and playAgainButton and not playAgainButton.Visible then
			panel.Visible = false
		end
	end)
end

local function showRoundEnd(payload)
	if not panel then
		return
	end

	noticeToken += 1
	payload = payload or {}
	local survivedSeconds = payload.survivedSeconds or 0
	local mapName = payload.mapName or "Backyard"
	local roundCrumbs = payload.crumbsCollected or 0
	local roundDna = payload.dnaEarned or 0
	local availableDna = payload.totalDna or (latestData and latestData.currency and latestData.currency.dna) or 0
	local title = payload.title or (latestData and latestData.progression and latestData.progression.current and latestData.progression.current.title) or "Fresh Hatchling"
	local nextTitleDna = payload.nextTitleDna
	local resultText = payload.eliminated and "Squished" or "Survived"
	local nextText = nextTitleDna and ("Next title at " .. tostring(nextTitleDna) .. " lifetime DNA") or "Max title reached"

	titleLabel.Text = mapName .. " Complete!"
	summaryLabel.Text = string.format(
		"%s: %s seconds\nCrumbs this round: %s\nDNA earned this round: %s\nAvailable DNA: %s\n%s • %s",
		resultText,
		tostring(survivedSeconds),
		tostring(roundCrumbs),
		tostring(roundDna),
		tostring(availableDna),
		tostring(title),
		nextText
	)

	setResultButtonsVisible(true)
	panel.Visible = true
end

function RoundEndController.Init(remotes)
	ensureGui(remotes)

	remotes.PlayerDataChanged.OnClientEvent:Connect(function(data)
		latestData = data
	end)

	remotes.RoundStateChanged.OnClientEvent:Connect(function(state, payload)
		if state == "Started" then
			noticeToken += 1
			if panel then
				panel.Visible = false
			end
		elseif state == "Eliminated" then
			showEliminated(payload)
		elseif state == "Ended" then
			showRoundEnd(payload)
		end
	end)
end

return RoundEndController
