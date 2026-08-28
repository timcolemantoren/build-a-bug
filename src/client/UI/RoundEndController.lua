--!nonstrict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local RoundEndController = {}

local player = Players.LocalPlayer
local gui = nil
local panel = nil
local titleLabel = nil
local summaryLabel = nil
local playAgainButton = nil
local roamButton = nil
local splatFlash = nil
local splatLabel = nil
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
	gui.DisplayOrder = 20
	gui.Parent = player:WaitForChild("PlayerGui")

	splatFlash = Instance.new("Frame")
	splatFlash.Name = "SplatFlash"
	splatFlash.Size = UDim2.fromScale(1, 1)
	splatFlash.BackgroundColor3 = Color3.fromRGB(180, 42, 34)
	splatFlash.BackgroundTransparency = 1
	splatFlash.BorderSizePixel = 0
	splatFlash.Visible = false
	splatFlash.ZIndex = 40
	splatFlash.Parent = gui

	splatLabel = Instance.new("TextLabel")
	splatLabel.Name = "Splat"
	splatLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	splatLabel.Size = UDim2.fromOffset(260, 90)
	splatLabel.Position = UDim2.fromScale(0.5, 0.47)
	splatLabel.BackgroundTransparency = 1
	splatLabel.Text = "SPLAT!"
	splatLabel.TextColor3 = Color3.fromRGB(255, 232, 102)
	splatLabel.TextStrokeColor3 = Color3.fromRGB(78, 23, 18)
	splatLabel.TextStrokeTransparency = 0
	splatLabel.Font = Enum.Font.GothamBlack
	splatLabel.TextSize = 38
	splatLabel.Rotation = -14
	splatLabel.Visible = false
	splatLabel.ZIndex = 41
	splatLabel.Parent = gui

	panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromOffset(390, 320)
	panel.Position = UDim2.new(0.5, -195, 0.5, -160)
	panel.BackgroundColor3 = Color3.fromRGB(40, 42, 40)
	panel.BackgroundTransparency = 0.15
	panel.Visible = false
	panel.ZIndex = 10
	panel.Parent = gui

	titleLabel = makeLabel(panel, "Title", 18, 42, 24)
	titleLabel.Size = UDim2.fromOffset(350, 42)
	titleLabel.Text = "Round Complete!"
	titleLabel.ZIndex = 11

	summaryLabel = makeLabel(panel, "Summary", 66, 132, 17)
	summaryLabel.Size = UDim2.fromOffset(350, 132)
	summaryLabel.Text = ""
	summaryLabel.ZIndex = 11

	playAgainButton = Instance.new("TextButton")
	playAgainButton.Name = "PlayAgain"
	playAgainButton.Size = UDim2.fromOffset(230, 44)
	playAgainButton.Position = UDim2.fromOffset(80, 208)
	playAgainButton.BackgroundTransparency = 0.05
	playAgainButton.Text = "Join Next Match"
	playAgainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	playAgainButton.Font = Enum.Font.GothamBold
	playAgainButton.TextSize = 18
	playAgainButton.ZIndex = 11
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
	roamButton.ZIndex = 11
	roamButton.Parent = panel
	roamButton.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)
end

local function playSplatVisual()
	if not splatFlash or not splatLabel then
		return
	end

	splatFlash.Visible = true
	splatFlash.BackgroundTransparency = 0.56
	splatLabel.Visible = true
	splatLabel.TextTransparency = 0
	splatLabel.TextStrokeTransparency = 0
	splatLabel.Size = UDim2.fromOffset(210, 72)
	splatLabel.TextSize = 32
	splatLabel.Rotation = -18

	TweenService:Create(splatLabel, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(520, 155),
		TextSize = 78,
		Rotation = 7,
	}):Play()
	TweenService:Create(splatFlash, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()

	task.delay(0.72, function()
		if not splatLabel then
			return
		end
		TweenService:Create(splatLabel, TweenInfo.new(0.28), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()
		task.delay(0.30, function()
			if splatFlash then
				splatFlash.Visible = false
			end
			if splatLabel then
				splatLabel.Visible = false
			end
		end)
	end)
end

local function showEliminated(payload)
	if not panel then
		return
	end

	noticeToken += 1
	local token = noticeToken
	playSplatVisual()

	panel.BackgroundColor3 = Color3.fromRGB(73, 38, 34)
	titleLabel.Text = "SQUISHED!"
	summaryLabel.Text = string.format(
		"The backyard got you!\n\nYou survived %s seconds.\n%s bug%s still in the match.\nRewards total when the round ends.",
		tostring(payload and payload.survivedSeconds or 0),
		tostring(payload and payload.playersRemaining or 0),
		(payload and payload.playersRemaining == 1) and " is" or "s are"
	)
	setResultButtonsVisible(false)

	-- Let SPLAT own the screen for a beat, then show the useful information.
	panel.Visible = false
	task.delay(0.62, function()
		if token == noticeToken and panel then
			panel.Visible = true
		end
	end)

	task.delay(3.6, function()
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

	panel.BackgroundColor3 = Color3.fromRGB(40, 42, 40)
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
