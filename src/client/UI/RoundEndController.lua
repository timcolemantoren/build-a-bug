--!nonstrict

local Players = game:GetService("Players")

local RoundEndController = {}

local player = Players.LocalPlayer
local gui = nil
local panel = nil
local titleLabel = nil
local summaryLabel = nil
local playAgainButton = nil
local latestData = nil

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
	panel.Size = UDim2.fromOffset(360, 250)
	panel.Position = UDim2.new(0.5, -180, 0.5, -125)
	panel.BackgroundTransparency = 0.15
	panel.Visible = false
	panel.Parent = gui

	titleLabel = makeLabel(panel, "Title", 18, 42, 24)
	titleLabel.Text = "Round Complete!"

	summaryLabel = makeLabel(panel, "Summary", 66, 104, 17)
	summaryLabel.Text = ""

	playAgainButton = Instance.new("TextButton")
	playAgainButton.Name = "PlayAgain"
	playAgainButton.Size = UDim2.fromOffset(180, 44)
	playAgainButton.Position = UDim2.fromOffset(90, 184)
	playAgainButton.BackgroundTransparency = 0.05
	playAgainButton.Text = "Play Again"
	playAgainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	playAgainButton.Font = Enum.Font.GothamBold
	playAgainButton.TextSize = 18
	playAgainButton.Parent = panel
	playAgainButton.MouseButton1Click:Connect(function()
		panel.Visible = false
		remotes.StartRoundRequest:FireServer()
	end)
end

local function showRoundEnd(payload)
	if not panel then
		return
	end

	local survivedSeconds = payload and payload.survivedSeconds or "?"
	local dna = latestData and latestData.currency and latestData.currency.dna or 0
	local crumbs = latestData and latestData.currency and latestData.currency.crumbs or 0
	local current = latestData and latestData.progression and latestData.progression.current
	local nextLevel = latestData and latestData.progression and latestData.progression.next
	local title = current and current.title or "Fresh Hatchling"
	local nextText = nextLevel and ("Next title at " .. tostring(nextLevel.dnaRequired) .. " DNA") or "Max title reached"

	summaryLabel.Text = string.format(
		"Survived: %s seconds\nTotal Crumbs: %s\nTotal DNA: %s\nTitle: %s\n%s",
		tostring(survivedSeconds),
		tostring(crumbs),
		tostring(dna),
		tostring(title),
		nextText
	)

	panel.Visible = true
end

function RoundEndController.Init(remotes)
	ensureGui(remotes)

	remotes.PlayerDataChanged.OnClientEvent:Connect(function(data)
		latestData = data
	end)

	remotes.RoundStateChanged.OnClientEvent:Connect(function(state, payload)
		if state == "Started" then
			if panel then
				panel.Visible = false
			end
		elseif state == "Ended" then
			showRoundEnd(payload)
		end
	end)
end

return RoundEndController
