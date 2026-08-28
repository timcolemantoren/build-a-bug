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
local inRound = false
local selectedBug = player:GetAttribute("SelectedBug") or "Ant"
local bugCards = {}

local DEFAULT_CARD = Color3.fromRGB(55, 65, 58)
local SELECTED_CARD = Color3.fromRGB(74, 103, 76)
local DEFAULT_STROKE = Color3.fromRGB(85, 96, 88)
local SELECTED_STROKE = Color3.fromRGB(137, 174, 132)

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

local function getRoleLine(bugId: string): string
	if bugId == "Beetle" then
		return "Slower • 25% less hazard damage"
	elseif bugId == "Grasshopper" then
		return "Fastest • Highest jump"
	end
	return "Balanced speed • Reliable all-rounder"
end

local function getPowerLine(bugId: string, bug): string
	if bugId == "Ant" then
		return "POWER: Carry More | extra food from crumbs"
	elseif bugId == "Beetle" then
		return "POWER: Shell Block | briefly shrugs off most damage"
	elseif bugId == "Grasshopper" then
		return "POWER: Leap | launch forward out of danger"
	end

	local ability = bug and bug.ability
	return ability and ("POWER: " .. tostring(ability.displayName)) or ""
end

local function refreshBugCards()
	for bugId, card in pairs(bugCards) do
		local bug = BugArchetypes[bugId]
		if bug and card then
			local isSelected = bugId == selectedBug
			card.button.BackgroundColor3 = isSelected and SELECTED_CARD or DEFAULT_CARD
			card.stroke.Color = isSelected and SELECTED_STROKE or DEFAULT_STROKE
			card.stroke.Thickness = isSelected and 2 or 1
			local prefix = isSelected and "SELECTED • " or ""
			card.label.Text = string.format(
				"%s%s\n%s\n%s",
				prefix,
				bug.displayName,
				getRoleLine(bugId),
				getPowerLine(bugId, bug)
			)
		end
	end
end

local function applyVisibility()
	if panel then
		panel.Visible = not inRound
	end
end

local function applyLayout()
	if not panel then
		return
	end

	if expanded then
		panel.Size = UDim2.fromOffset(344, 418)
		panel.Position = UDim2.new(1, -356, 0, 14)
		toggleButton.Text = "Close"
	else
		panel.Size = UDim2.fromOffset(96, 44)
		panel.Position = UDim2.new(1, -110, 0, 14)
		toggleButton.Text = "Bugs"
	end

	for _, item in ipairs(details) do
		item.Visible = expanded
	end

	applyVisibility()
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
	panel.BackgroundTransparency = 0.16
	panel.BackgroundColor3 = Color3.fromRGB(32, 38, 34)
	panel.Parent = gui

	toggleButton = makeButton(panel, "Bugs", UDim2.fromOffset(8, 4))
	toggleButton.Size = UDim2.fromOffset(80, 34)
	toggleButton.MouseButton1Click:Connect(function()
		if inRound then
			return
		end
		expanded = not expanded
		applyLayout()
	end)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromOffset(316, 30)
	title.Position = UDim2.fromOffset(14, 44)
	title.BackgroundTransparency = 1
	title.Text = "Choose Your Play Style"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel
	table.insert(details, title)

	local y = 78
	for _, bugId in ipairs(BugOrder) do
		local currentBugId = bugId
		local bug = BugArchetypes[currentBugId]
		if bug then
			local button = Instance.new("TextButton")
			button.Name = currentBugId .. "Card"
			button.Size = UDim2.fromOffset(316, 86)
			button.Position = UDim2.fromOffset(14, y)
			button.BackgroundTransparency = 0.04
			button.BackgroundColor3 = DEFAULT_CARD
			button.Text = ""
			button.AutoButtonColor = false
			button.Parent = panel

			local stroke = Instance.new("UIStroke")
			stroke.Color = DEFAULT_STROKE
			stroke.Thickness = 1
			stroke.Transparency = 0.15
			stroke.Parent = button

			local label = Instance.new("TextLabel")
			label.Name = "CardText"
			label.Size = UDim2.new(1, -24, 1, -14)
			label.Position = UDim2.fromOffset(12, 7)
			label.BackgroundTransparency = 1
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.Font = Enum.Font.GothamBold
			label.TextSize = 14
			label.TextWrapped = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextYAlignment = Enum.TextYAlignment.Center
			label.Parent = button

			button.MouseButton1Click:Connect(function()
				if inRound then
					return
				end
				selectedBug = currentBugId
				refreshBugCards()
				remotes.SelectBugLoadout:FireServer(currentBugId)
			end)

			bugCards[currentBugId] = {
				button = button,
				label = label,
				stroke = stroke,
			}
			table.insert(details, button)
			y += 92
		end
	end

	local startButton = makeButton(panel, "Join Next Match", UDim2.fromOffset(77, 360))
	startButton.Size = UDim2.fromOffset(190, 42)
	startButton.MouseButton1Click:Connect(function()
		if inRound then
			return
		end
		remotes.StartRoundRequest:FireServer()
		expanded = false
		applyLayout()
	end)
	table.insert(details, startButton)

	refreshBugCards()
	applyLayout()
end

function BugSelectController.Init(remotes)
	ensureGui(remotes)

	player:GetAttributeChangedSignal("SelectedBug"):Connect(function()
		selectedBug = player:GetAttribute("SelectedBug") or selectedBug
		refreshBugCards()
	end)

	remotes.PlayerDataChanged.OnClientEvent:Connect(function(data)
		selectedBug = data.selectedBug or selectedBug
		refreshBugCards()
	end)

	remotes.RoundStateChanged.OnClientEvent:Connect(function(state, _payload)
		if state == "Started" then
			inRound = true
			expanded = false
		elseif state == "Ended" or state == "Eliminated" or state == "ExitedRound" or state == "Waiting" or state == "Results" or state == "MatchInProgress" then
			inRound = false
		end
		applyLayout()
	end)
end

return BugSelectController
