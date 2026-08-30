--!nonstrict

local Players = game:GetService("Players")

local LobbyMenuCoordinator = {}
local player = Players.LocalPlayer

local function findButton(root: Instance?, name: string): TextButton?
	if not root then
		return nil
	end
	local button = root:FindFirstChild(name, true)
	return button and button:IsA("TextButton") and button or nil
end

local function findFrame(root: Instance?, name: string): Frame?
	if not root then
		return nil
	end
	local frame = root:FindFirstChild(name, true)
	return frame and frame:IsA("Frame") and frame or nil
end

local function findBugToggle(panel: Frame?): TextButton?
	if not panel then
		return nil
	end
	for _, child in ipairs(panel:GetChildren()) do
		if child:IsA("TextButton") and (child.Text == "Bugs" or child.Text == "Close") then
			return child
		end
	end
	return nil
end

function LobbyMenuCoordinator.Init()
	local playerGui = player:WaitForChild("PlayerGui")
	local bugGui = playerGui:WaitForChild("BuildABugBugSelect")
	local profileGui = playerGui:WaitForChild("BuildABugProfile")
	local collectionGui = playerGui:WaitForChild("BuildABugCollection")
	local skinGui = playerGui:WaitForChild("BuildABugPremiumSkins")

	local bugPanel = findFrame(bugGui, "Panel")
	local profilePanel = findFrame(profileGui, "ProfilePanel")
	local collectionPanel = findFrame(collectionGui, "CollectionPanel")
	local skinPanel = findFrame(skinGui, "Panel")

	local profileButton = findButton(profileGui, "OpenProfile")
	local collectionButton = findButton(collectionGui, "OpenCollection")
	local skinButton = findButton(skinGui, "SkinsButton")
	local bugButton = findBugToggle(bugPanel)

	-- A single, predictable launcher row. Bugs keeps the far-right slot because
	-- its compact panel already owns that position.
	if collectionButton then
		collectionButton.Position = UDim2.new(1, -446, 0, 14)
		collectionButton.Size = UDim2.fromOffset(112, 36)
	end
	if profileButton then
		profileButton.Position = UDim2.new(1, -326, 0, 14)
		profileButton.Size = UDim2.fromOffset(112, 36)
		profileButton.Text = "Customize"
	end
	if skinButton then
		skinButton.Position = UDim2.new(1, -206, 0, 14)
		skinButton.Size = UDim2.fromOffset(88, 36)
	end
	if bugButton then
		bugButton.TextSize = 15
	end

	local function isBugOpen(): boolean
		return bugPanel ~= nil and bugPanel.Visible and bugPanel.Size.X.Offset > 150
	end

	local function update()
		local inRound = player:GetAttribute("InRound") == true
		local profileOpen = profilePanel ~= nil and profilePanel.Visible
		local collectionOpen = collectionPanel ~= nil and collectionPanel.Visible
		local skinsOpen = skinPanel ~= nil and skinPanel.Visible
		local bugsOpen = isBugOpen()
		local anyOpen = profileOpen or collectionOpen or skinsOpen or bugsOpen

		if profileButton then
			profileButton.Visible = not inRound and (not anyOpen or profileOpen)
		end
		if collectionButton then
			collectionButton.Visible = not inRound and (not anyOpen or collectionOpen)
		end
		if skinButton then
			skinButton.Visible = not inRound and (not anyOpen or skinsOpen)
		end
		if bugPanel then
			bugPanel.Visible = not inRound and (not anyOpen or bugsOpen)
		end
	end

	if profilePanel then
		profilePanel:GetPropertyChangedSignal("Visible"):Connect(function()
			task.defer(update)
		end)
	end
	if collectionPanel then
		collectionPanel:GetPropertyChangedSignal("Visible"):Connect(function()
			task.defer(update)
		end)
	end
	if skinPanel then
		skinPanel:GetPropertyChangedSignal("Visible"):Connect(function()
			task.defer(update)
		end)
	end
	if bugPanel then
		bugPanel:GetPropertyChangedSignal("Size"):Connect(function()
			task.defer(update)
		end)
	end
	player:GetAttributeChangedSignal("InRound"):Connect(function()
		task.defer(update)
	end)

	task.defer(update)
end

return LobbyMenuCoordinator
