--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local BugArchetypes = require(BuildABugShared.Config.BugArchetypes)
local BugOrder = require(BuildABugShared.Config.BugOrder)
local PurchaseConfirmController = require(script.Parent.PurchaseConfirmController)

local BugSelectController = {}

local player = Players.LocalPlayer
local gui = nil
local panel = nil
local expanded = false
local details = {}
local toggleButton = nil
local statusLabel = nil
local inRound = false
local selectedBug = player:GetAttribute("SelectedBug") or "Ant"
local currentData = nil
local bugCards = {}

local DEFAULT_CARD = Color3.fromRGB(55, 65, 58)
local SELECTED_CARD = Color3.fromRGB(74, 103, 76)
local LOCKED_CARD = Color3.fromRGB(46, 49, 47)
local DEFAULT_STROKE = Color3.fromRGB(85, 96, 88)
local SELECTED_STROKE = Color3.fromRGB(137, 174, 132)
local LOCKED_STROKE = Color3.fromRGB(92, 82, 70)

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

local function getUnlockedBugs()
	local data = currentData or {}
	return data.unlockedBugs or { Ant = true, Beetle = true, Grasshopper = true }
end

local function getAvailableDna(): number
	local data = currentData or {}
	local currency = data.currency or {}
	return currency.dna or player:GetAttribute("TotalDna") or 0
end

local function isUnlocked(bugId: string): boolean
	return getUnlockedBugs()[bugId] == true
end

local function getRoleLine(bugId: string): string
	if bugId == "Beetle" then
		return "Slower • 25% less hazard damage"
	elseif bugId == "Grasshopper" then
		return "Fastest starter • Highest jump"
	elseif bugId == "Ladybug" then
		return "Quick • 10% less hazard damage"
	elseif bugId == "Mantis" then
		return "Precise • Strong jump • Mid-speed"
	elseif bugId == "Dragonfly" then
		return "Very fast • Strong jump • Risky escape specialist"
	elseif bugId == "Pillbug" then
		return "Slow • Armored • 18% less hazard damage"
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
	elseif bugId == "Ladybug" then
		return "POWER: Wing Burst | short ground-speed boost"
	elseif bugId == "Mantis" then
		return "POWER: Pounce | fast low forward dash"
	elseif bugId == "Dragonfly" then
		return "POWER: Air Dash | fast forward and upward escape"
	elseif bugId == "Pillbug" then
		return "POWER: Roll Away | protected forward burst"
	end

	local ability = bug and bug.ability
	return ability and ("POWER: " .. tostring(ability.displayName)) or ""
end

local function setStatus(text: string, warning: boolean?)
	if statusLabel then
		statusLabel.Text = text
		statusLabel.TextColor3 = warning and Color3.fromRGB(255, 204, 145) or Color3.fromRGB(195, 225, 190)
	end
end

local function refreshBugCards()
	for bugId, card in pairs(bugCards) do
		local bug = BugArchetypes[bugId]
		if bug and card then
			local unlocked = isUnlocked(bugId)
			local isSelected = unlocked and bugId == selectedBug
			card.button.BackgroundColor3 = isSelected and SELECTED_CARD or (unlocked and DEFAULT_CARD or LOCKED_CARD)
			card.stroke.Color = isSelected and SELECTED_STROKE or (unlocked and DEFAULT_STROKE or LOCKED_STROKE)
			card.stroke.Thickness = isSelected and 2 or 1

			local heading
			if isSelected then
				heading = "SELECTED • " .. bug.displayName
			elseif unlocked then
				heading = "UNLOCKED • " .. bug.displayName
			else
				heading = string.format("LOCKED • %s DNA • %s", tostring(bug.unlockCost or 0), bug.displayName)
			end

			card.label.Text = string.format("%s\n%s\n%s", heading, getRoleLine(bugId), getPowerLine(bugId, bug))
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
		panel.Size = UDim2.fromOffset(356, 510)
		panel.Position = UDim2.new(1, -370, 0, 14)
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
	title.Size = UDim2.fromOffset(328, 30)
	title.Position = UDim2.fromOffset(14, 44)
	title.BackgroundTransparency = 1
	title.Text = "Choose Your Play Style"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel
	table.insert(details, title)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "BugCards"
	scroll.Position = UDim2.fromOffset(12, 78)
	scroll.Size = UDim2.new(1, -24, 0, 330)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.fromOffset(0, (#BugOrder * 92) + 4)
	scroll.Parent = panel
	table.insert(details, scroll)

	local y = 0
	for _, bugId in ipairs(BugOrder) do
		local currentBugId = bugId
		local bug = BugArchetypes[currentBugId]
		if bug then
			local button = Instance.new("TextButton")
			button.Name = currentBugId .. "Card"
			button.Size = UDim2.new(1, -8, 0, 86)
			button.Position = UDim2.fromOffset(0, y)
			button.BackgroundTransparency = 0.04
			button.BackgroundColor3 = DEFAULT_CARD
			button.Text = ""
			button.AutoButtonColor = false
			button.Parent = scroll

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
			label.TextSize = 13
			label.TextWrapped = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextYAlignment = Enum.TextYAlignment.Center
			label.Parent = button

			button.MouseButton1Click:Connect(function()
				if inRound then
					return
				end

				if isUnlocked(currentBugId) then
					selectedBug = currentBugId
					refreshBugCards()
					remotes.SelectBugLoadout:FireServer(currentBugId)
					setStatus("Selected " .. bug.displayName .. ".", false)
					return
				end

				local cost = math.max(0, bug.unlockCost or 0)
				local dna = getAvailableDna()
				if dna < cost then
					setStatus(string.format("Need %s more DNA to unlock %s.", tostring(cost - dna), bug.displayName), true)
					return
				end

				PurchaseConfirmController.Request({ itemName = bug.displayName, cost = cost, balance = dna }, function()
					if inRound or isUnlocked(currentBugId) then
						return
					end
					if getAvailableDna() < cost then
						setStatus("Your DNA balance changed. Unlock cancelled.", true)
						return
					end
					remotes.PurchaseBug:FireServer(currentBugId)
					setStatus("Unlocking " .. bug.displayName .. "...", false)
				end)
				setStatus("Review the bug unlock and choose Buy or Cancel.", false)
			end)

			bugCards[currentBugId] = { button = button, label = label, stroke = stroke }
			y += 92
		end
	end

	statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.Size = UDim2.new(1, -28, 0, 36)
	statusLabel.Position = UDim2.fromOffset(14, 414)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Starter bugs are free. Unlock new sidegrades with DNA."
	statusLabel.TextColor3 = Color3.fromRGB(195, 225, 190)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 11
	statusLabel.TextWrapped = true
	statusLabel.Parent = panel
	table.insert(details, statusLabel)

	local startButton = makeButton(panel, "Join Next Match", UDim2.fromOffset(83, 458))
	startButton.Size = UDim2.fromOffset(190, 40)
	startButton.MouseButton1Click:Connect(function()
		if inRound then
			return
		end
		PurchaseConfirmController.Cancel()
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
		currentData = data
		selectedBug = data.selectedBug or selectedBug
		refreshBugCards()
	end)

	remotes.BugUnlockResult.OnClientEvent:Connect(function(result)
		if type(result) ~= "table" then
			return
		end
		local bugId = result.bugId
		if result.success == true and type(bugId) == "string" then
			currentData = currentData or {}
			currentData.unlockedBugs = currentData.unlockedBugs or { Ant = true, Beetle = true, Grasshopper = true }
			currentData.unlockedBugs[bugId] = true
			currentData.currency = currentData.currency or {}
			if type(result.balance) == "number" then
				currentData.currency.dna = result.balance
			end
			if result.selected == true then
				selectedBug = bugId
				currentData.selectedBug = bugId
			end
			refreshBugCards()
			local displayName = result.displayName or bugId
			if result.alreadyOwned then
				setStatus("Selected " .. displayName .. ".", false)
			elseif result.selected == true then
				setStatus("Unlocked " .. displayName .. "! Selected and ready.", false)
			else
				setStatus("Unlocked " .. displayName .. "! Tap it to select.", false)
			end
		else
			setStatus(result.message or "Bug unlock failed. Your DNA was not spent.", true)
		end
	end)

	remotes.RoundStateChanged.OnClientEvent:Connect(function(state, _payload)
		if state == "Started" then
			PurchaseConfirmController.Cancel()
			inRound = true
			expanded = false
		elseif state == "Ended" or state == "Eliminated" or state == "ExitedRound" or state == "Waiting" or state == "Results" or state == "MatchInProgress" then
			inRound = false
		end
		applyLayout()
	end)
end

return BugSelectController
