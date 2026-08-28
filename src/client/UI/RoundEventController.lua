--!nonstrict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local RoundEventController = {}

local player = Players.LocalPlayer
local gui = nil
local frame = nil
local titleLabel = nil
local subtitleLabel = nil
local border = nil
local bannerToken = 0

local phaseDescriptions = {
	Scavenge = "Grab food and DNA while the yard is calm.",
	Trouble = "Hazards are faster now. Stay alert.",
	Chaos = "Danger targets bugs directly. Keep moving!",
}

local phaseColors = {
	Scavenge = Color3.fromRGB(70, 120, 76),
	Trouble = Color3.fromRGB(165, 105, 42),
	Chaos = Color3.fromRGB(160, 55, 48),
	Final = Color3.fromRGB(150, 55, 100),
	Event = Color3.fromRGB(72, 92, 130),
}

local hazardColors = {
	ShoeStomp = Color3.fromRGB(178, 53, 44),
	SprinklerBurst = Color3.fromRGB(45, 125, 174),
	BirdShadow = Color3.fromRGB(58, 58, 76),
}

local hazardFallback = {
	ShoeStomp = "MOVE OUT OF THE STOMP ZONE!",
	SprinklerBurst = "GET OUT OF THE WATER LANE!",
	BirdShadow = "RUN OUT OF THE SHADOW!",
}

local function ensureGui()
	if gui then
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "BuildABugRoundEvents"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 8
	gui.Parent = player:WaitForChild("PlayerGui")

	frame = Instance.new("Frame")
	frame.Name = "Banner"
	frame.Size = UDim2.fromOffset(470, 92)
	frame.Position = UDim2.new(0.5, -235, 0, 70)
	frame.BackgroundColor3 = phaseColors.Event
	frame.BackgroundTransparency = 0.20
	frame.Visible = false
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	border = Instance.new("UIStroke")
	border.Color = Color3.fromRGB(255, 255, 255)
	border.Transparency = 0.28
	border.Thickness = 2
	border.Parent = frame

	titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -20, 0, 52)
	titleLabel.Position = UDim2.fromOffset(10, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextStrokeTransparency = 0.18
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 34
	titleLabel.TextTransparency = 1
	titleLabel.Parent = frame

	subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.Size = UDim2.new(1, -24, 0, 34)
	subtitleLabel.Position = UDim2.fromOffset(12, 50)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.TextColor3 = Color3.fromRGB(255, 245, 210)
	subtitleLabel.TextStrokeTransparency = 0.3
	subtitleLabel.Font = Enum.Font.GothamBold
	subtitleLabel.TextSize = 17
	subtitleLabel.TextWrapped = true
	subtitleLabel.TextTransparency = 1
	subtitleLabel.Parent = frame
end

local function showBanner(title: string, subtitle: string, duration: number?, color: Color3?)
	ensureGui()
	bannerToken += 1
	local token = bannerToken

	frame.BackgroundColor3 = color or phaseColors.Event
	titleLabel.Text = title
	subtitleLabel.Text = subtitle or ""
	titleLabel.TextTransparency = 1
	subtitleLabel.TextTransparency = 1
	frame.Position = UDim2.new(0.5, -235, 0, 82)
	frame.Size = UDim2.fromOffset(420, 82)
	frame.Visible = true

	TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -235, 0, 70),
		Size = UDim2.fromOffset(470, 92),
	}):Play()
	TweenService:Create(titleLabel, TweenInfo.new(0.16), { TextTransparency = 0 }):Play()
	TweenService:Create(subtitleLabel, TweenInfo.new(0.22), { TextTransparency = 0 }):Play()

	task.delay(duration or 2.4, function()
		if token ~= bannerToken or not frame then
			return
		end

		TweenService:Create(titleLabel, TweenInfo.new(0.28), { TextTransparency = 1 }):Play()
		TweenService:Create(subtitleLabel, TweenInfo.new(0.28), { TextTransparency = 1 }):Play()
		TweenService:Create(frame, TweenInfo.new(0.28), { BackgroundTransparency = 1 }):Play()
		task.delay(0.3, function()
			if token == bannerToken and frame then
				frame.Visible = false
				frame.BackgroundTransparency = 0.20
			end
		end)
	end)
end

function RoundEventController.Init(remotes)
	ensureGui()

	remotes.RoundStateChanged.OnClientEvent:Connect(function(state, payload)
		payload = payload or {}
		if state == "PhaseChanged" then
			local phaseId = payload.phaseId or "Scavenge"
			showBanner(
				payload.displayName or "NEW PHASE!",
				phaseDescriptions[phaseId] or "The backyard is changing.",
				2.5,
				phaseColors[phaseId] or phaseColors.Event
			)
		elseif state == "RoundEvent" then
			showBanner(payload.displayName or "SURPRISE!", payload.description or "Something is happening!", 2.6, phaseColors.Event)
		elseif state == "FinalScramble" then
			showBanner(payload.displayName or "FINAL SCRAMBLE!", payload.description or "10 seconds!", 3, phaseColors.Final)
		elseif state == "Ended" or state == "Eliminated" then
			bannerToken += 1
			if frame then
				frame.Visible = false
			end
		end
	end)

	remotes.HazardWarning.OnClientEvent:Connect(function(payload)
		payload = payload or {}
		if player:GetAttribute("InRound") ~= true or (payload.stage or "Warning") ~= "Warning" then
			return
		end

		local hazardId = payload.id or ""
		local title = string.upper(payload.displayName or "HAZARD") .. "!"
		local instruction = payload.instruction or hazardFallback[hazardId] or "MOVE OUT OF THE DANGER ZONE!"
		local duration = math.min(2.2, math.max(1.0, payload.warningSeconds or 2))
		showBanner(title, instruction, duration, hazardColors[hazardId] or phaseColors.Chaos)
	end)
end

return RoundEventController
