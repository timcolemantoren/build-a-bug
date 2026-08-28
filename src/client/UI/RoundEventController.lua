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
	Chaos = "The backyard is getting wild. Keep moving!",
}

local phaseColors = {
	Scavenge = Color3.fromRGB(70, 120, 76),
	Trouble = Color3.fromRGB(165, 105, 42),
	Chaos = Color3.fromRGB(160, 55, 48),
	Final = Color3.fromRGB(150, 55, 100),
	Event = Color3.fromRGB(72, 92, 130),
	Achievement = Color3.fromRGB(154, 119, 39),
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
	frame.BackgroundTransparency = 0.20
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

	task.delay(duration or 2.2, function()
		if token ~= bannerToken or not frame then
			return
		end

		TweenService:Create(titleLabel, TweenInfo.new(0.24), { TextTransparency = 1 }):Play()
		TweenService:Create(subtitleLabel, TweenInfo.new(0.24), { TextTransparency = 1 }):Play()
		TweenService:Create(frame, TweenInfo.new(0.24), { BackgroundTransparency = 1 }):Play()
		task.delay(0.26, function()
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
				2.0,
				phaseColors[phaseId] or phaseColors.Event
			)
		elseif state == "RoundEvent" then
			showBanner(payload.displayName or "SURPRISE!", payload.description or "Something is happening!", 2.1, phaseColors.Event)
		elseif state == "FinalScramble" then
			showBanner(payload.displayName or "FINAL SCRAMBLE!", payload.description or "10 seconds!", 2.4, phaseColors.Final)
		elseif state == "AchievementUnlocked" then
			showBanner(
				"AWARD UNLOCKED!",
				string.format("%s  •  %s", payload.displayName or "Achievement", payload.rewardName or "New cosmetic"),
				3.2,
				phaseColors.Achievement
			)
		elseif state == "Ended" or state == "Eliminated" then
			bannerToken += 1
			if frame then
				frame.Visible = false
			end
		end
	end)

	-- Hazard warnings intentionally do not take over the center of the screen.
	-- Their physical world cue, audio cue, and compact HUD label carry the message.
end

return RoundEventController
