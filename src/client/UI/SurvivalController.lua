--!nonstrict

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local SurvivalController = {}

local player = Players.LocalPlayer
local gui = nil
local healthPanel = nil
local healthFill = nil
local healthLabel = nil
local exitButton = nil
local forfeitLabel = nil
local toastLabel = nil
local damageFlash = nil
local damageFlashTween = nil
local inRound = false
local currentHumanoid = nil
local healthConnection = nil
local maxHealthConnection = nil
local toastToken = 0
local damageFlashToken = 0
local lastHealth = nil

local CREAM = Color3.fromRGB(250, 246, 232)
local PANEL_COLOR = Color3.fromRGB(25, 43, 48)
local BAR_BACK = Color3.fromRGB(52, 68, 66)
local EXIT_COLOR = Color3.fromRGB(76, 84, 90)

local function disconnectHealth()
	if healthConnection then
		healthConnection:Disconnect()
		healthConnection = nil
	end
	if maxHealthConnection then
		maxHealthConnection:Disconnect()
		maxHealthConnection = nil
	end
	currentHumanoid = nil
	lastHealth = nil
end

local function flashDamage(damageAmount: number)
	if not damageFlash or not inRound or damageAmount <= 0 then
		return
	end

	if damageFlashTween then
		damageFlashTween:Cancel()
		damageFlashTween = nil
	end

	damageFlashToken += 1
	local token = damageFlashToken
	local strength = math.clamp(damageAmount / 45, 0.18, 1)
	local visibleTransparency = 0.83 - (0.24 * strength)

	damageFlash.Visible = true
	damageFlash.BackgroundTransparency = visibleTransparency

	damageFlashTween = TweenService:Create(
		damageFlash,
		TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	damageFlashTween:Play()
	damageFlashTween.Completed:Connect(function()
		if token == damageFlashToken and damageFlash then
			damageFlash.Visible = false
			damageFlashTween = nil
		end
	end)
end

local function updateHealth(newHealth: number?)
	if not healthFill or not healthLabel then
		return
	end

	local humanoid = currentHumanoid
	if not humanoid then
		healthFill.Size = UDim2.fromScale(0, 1)
		healthLabel.Text = "Health"
		lastHealth = nil
		return
	end

	local observedHealth = newHealth or humanoid.Health
	if lastHealth ~= nil and observedHealth < lastHealth then
		flashDamage(lastHealth - observedHealth)
	end
	lastHealth = observedHealth

	local maxHealth = math.max(1, humanoid.MaxHealth)
	local health = math.clamp(observedHealth, 0, maxHealth)
	local ratio = health / maxHealth
	healthFill.Size = UDim2.fromScale(ratio, 1)
	healthLabel.Text = string.format("Health  %d / %d", math.ceil(health), math.ceil(maxHealth))

	if ratio > 0.55 then
		healthFill.BackgroundColor3 = Color3.fromRGB(80, 215, 105)
	elseif ratio > 0.25 then
		healthFill.BackgroundColor3 = Color3.fromRGB(240, 185, 65)
	else
		healthFill.BackgroundColor3 = Color3.fromRGB(235, 75, 70)
	end
end

local function bindCharacter(character: Model?)
	disconnectHealth()
	if not character then
		updateHealth()
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 3)
	if not humanoid then
		updateHealth()
		return
	end

	currentHumanoid = humanoid
	lastHealth = humanoid.Health
	healthConnection = humanoid.HealthChanged:Connect(function(health)
		updateHealth(health)
	end)
	maxHealthConnection = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		updateHealth(humanoid.Health)
	end)
	updateHealth(humanoid.Health)
end

local function updateVisibility()
	if healthPanel then
		healthPanel.Visible = inRound
	end
	if exitButton then
		exitButton.Visible = inRound
		exitButton.Active = inRound
		if inRound then
			exitButton.Text = "Exit Round"
		end
	end
	if forfeitLabel then
		forfeitLabel.Visible = inRound
	end
	if not inRound and damageFlash then
		damageFlashToken += 1
		if damageFlashTween then
			damageFlashTween:Cancel()
			damageFlashTween = nil
		end
		damageFlash.Visible = false
		damageFlash.BackgroundTransparency = 1
	end
end

local function showToast(text: string)
	if not toastLabel then
		return
	end

	toastToken += 1
	local token = toastToken
	toastLabel.Text = text
	toastLabel.Visible = true

	task.delay(2.4, function()
		if token == toastToken and toastLabel then
			toastLabel.Visible = false
		end
	end)
end

local function ensureGui(remotes)
	if gui then
		return
	end

	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	end)

	gui = Instance.new("ScreenGui")
	gui.Name = "BuildABugSurvival"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 7
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	damageFlash = Instance.new("Frame")
	damageFlash.Name = "DamageFlash"
	damageFlash.Size = UDim2.fromScale(1, 1)
	damageFlash.Position = UDim2.fromScale(0, 0)
	damageFlash.BackgroundColor3 = Color3.fromRGB(220, 32, 32)
	damageFlash.BackgroundTransparency = 1
	damageFlash.BorderSizePixel = 0
	damageFlash.ZIndex = 50
	damageFlash.Visible = false
	damageFlash.Parent = gui

	healthPanel = Instance.new("Frame")
	healthPanel.Name = "HealthPanel"
	healthPanel.Size = UDim2.fromOffset(300, 34)
	healthPanel.Position = UDim2.new(0.5, -150, 1, -52)
	healthPanel.BackgroundColor3 = PANEL_COLOR
	healthPanel.BackgroundTransparency = 0.08
	healthPanel.BorderSizePixel = 0
	healthPanel.Parent = gui

	local barBackground = Instance.new("Frame")
	barBackground.Name = "BarBackground"
	barBackground.Size = UDim2.new(1, -8, 1, -8)
	barBackground.Position = UDim2.fromOffset(4, 4)
	barBackground.BackgroundColor3 = BAR_BACK
	barBackground.BorderSizePixel = 0
	barBackground.Parent = healthPanel

	healthFill = Instance.new("Frame")
	healthFill.Name = "HealthFill"
	healthFill.Size = UDim2.fromScale(1, 1)
	healthFill.BackgroundColor3 = Color3.fromRGB(80, 215, 105)
	healthFill.BorderSizePixel = 0
	healthFill.Parent = barBackground

	healthLabel = Instance.new("TextLabel")
	healthLabel.Name = "HealthText"
	healthLabel.Size = UDim2.fromScale(1, 1)
	healthLabel.BackgroundTransparency = 1
	healthLabel.Text = "Health  100 / 100"
	healthLabel.TextColor3 = CREAM
	healthLabel.TextStrokeColor3 = Color3.fromRGB(12, 20, 22)
	healthLabel.TextStrokeTransparency = 0.80
	healthLabel.Font = Enum.Font.FredokaOne
	healthLabel.TextSize = 15
	healthLabel.ZIndex = 3
	healthLabel.Parent = healthPanel

	exitButton = Instance.new("TextButton")
	exitButton.Name = "ExitRound"
	exitButton.Size = UDim2.fromOffset(112, 36)
	exitButton.Position = UDim2.new(1, -126, 0, 62)
	exitButton.BackgroundColor3 = EXIT_COLOR
	exitButton.BackgroundTransparency = 0.06
	exitButton.BorderSizePixel = 0
	exitButton.Text = "Exit Round"
	exitButton.TextColor3 = CREAM
	exitButton.Font = Enum.Font.FredokaOne
	exitButton.TextSize = 14
	exitButton.Parent = gui
	exitButton.MouseButton1Click:Connect(function()
		if not inRound then
			return
		end
		exitButton.Active = false
		exitButton.Text = "Exiting..."
		remotes.ExitRoundRequest:FireServer()
	end)

	forfeitLabel = Instance.new("TextLabel")
	forfeitLabel.Name = "ForfeitNote"
	forfeitLabel.Size = UDim2.fromOffset(138, 22)
	forfeitLabel.Position = UDim2.new(1, -141, 0, 98)
	forfeitLabel.BackgroundTransparency = 1
	forfeitLabel.Text = "forfeits round pickups"
	forfeitLabel.TextColor3 = Color3.fromRGB(232, 220, 211)
	forfeitLabel.TextStrokeColor3 = Color3.fromRGB(12, 20, 22)
	forfeitLabel.TextStrokeTransparency = 0.82
	forfeitLabel.Font = Enum.Font.GothamMedium
	forfeitLabel.TextSize = 10
	forfeitLabel.Parent = gui

	toastLabel = Instance.new("TextLabel")
	toastLabel.Name = "ExitToast"
	toastLabel.Size = UDim2.fromOffset(360, 76)
	toastLabel.Position = UDim2.new(0.5, -180, 0.5, -38)
	toastLabel.BackgroundTransparency = 0.10
	toastLabel.BackgroundColor3 = Color3.fromRGB(31, 48, 51)
	toastLabel.BorderSizePixel = 0
	toastLabel.TextColor3 = CREAM
	toastLabel.TextStrokeColor3 = Color3.fromRGB(12, 20, 22)
	toastLabel.TextStrokeTransparency = 0.82
	toastLabel.Font = Enum.Font.FredokaOne
	toastLabel.TextSize = 18
	toastLabel.TextWrapped = true
	toastLabel.Visible = false
	toastLabel.Parent = gui

	updateVisibility()
end

function SurvivalController.Init(remotes)
	ensureGui(remotes)

	player.CharacterAdded:Connect(function(character)
		task.wait(0.15)
		bindCharacter(character)
	end)
	if player.Character then
		bindCharacter(player.Character)
	end

	remotes.RoundStateChanged.OnClientEvent:Connect(function(state, _payload)
		if state == "Started" then
			inRound = true
			bindCharacter(player.Character)
		elseif state == "ExitedRound" then
			inRound = false
			showToast("Round exited\nRound DNA and crumbs forfeited")
		elseif state == "Ended" or state == "Eliminated" or state == "Waiting" or state == "Results" or state == "MatchInProgress" then
			inRound = false
		end
		updateVisibility()
	end)
end

return SurvivalController
