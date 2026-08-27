--!nonstrict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local RoundEventController = {}

local player = Players.LocalPlayer
local gui = nil
local frame = nil
local titleLabel = nil
local subtitleLabel = nil
local bannerToken = 0

local phaseDescriptions = {
	Scavenge = "Grab food and DNA while the yard is calm.",
	Trouble = "Hazards are getting faster!",
	Chaos = "Stay moving. Anything can happen now!",
}

local function ensureGui()
	if gui then
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "BuildABugRoundEvents"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Parent = player:WaitForChild("PlayerGui")

	frame = Instance.new("Frame")
	frame.Name = "Banner"
	frame.Size = UDim2.fromOffset(470, 92)
	frame.Position = UDim2.new(0.5, -235, 0, 70)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = gui

	titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 52)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextStrokeTransparency = 0.25
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 34
	titleLabel.TextTransparency = 1
	titleLabel.Parent = frame

	subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.Size = UDim2.new(1, 0, 0, 34)
	subtitleLabel.Position = UDim2.fromOffset(0, 50)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	subtitleLabel.TextStrokeTransparency = 0.4
	subtitleLabel.Font = Enum.Font.GothamBold
	subtitleLabel.TextSize = 17
	subtitleLabel.TextWrapped = true
	subtitleLabel.TextTransparency = 1
	subtitleLabel.Parent = frame
end

local function showBanner(title: string, subtitle: string, duration: number?)
	ensureGui()
	bannerToken += 1
	local token = bannerToken

	titleLabel.Text = title
	subtitleLabel.Text = subtitle or ""
	titleLabel.TextTransparency = 1
	subtitleLabel.TextTransparency = 1
	frame.Position = UDim2.new(0.5, -235, 0, 82)
	frame.Visible = true

	TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -235, 0, 70),
	}):Play()
	TweenService:Create(titleLabel, TweenInfo.new(0.16), { TextTransparency = 0 }):Play()
	TweenService:Create(subtitleLabel, TweenInfo.new(0.22), { TextTransparency = 0 }):Play()

	task.delay(duration or 2.4, function()
		if token ~= bannerToken or not frame then
			return
		end

		local titleTween = TweenService:Create(titleLabel, TweenInfo.new(0.28), { TextTransparency = 1 })
		local subtitleTween = TweenService:Create(subtitleLabel, TweenInfo.new(0.28), { TextTransparency = 1 })
		titleTween:Play()
		subtitleTween:Play()
		task.delay(0.3, function()
			if token == bannerToken and frame then
				frame.Visible = false
			end
		end)
	end)
end

function RoundEventController.Init(remotes)
	ensureGui()

	remotes.RoundStateChanged.OnClientEvent:Connect(function(state, payload)
		if state == "PhaseChanged" then
			local phaseId = payload.phaseId or "Scavenge"
			showBanner(
				payload.displayName or "NEW PHASE!",
				phaseDescriptions[phaseId] or "The backyard is changing.",
				2.5
			)
		elseif state == "RoundEvent" then
			showBanner(payload.displayName or "SURPRISE!", payload.description or "Something is happening!", 2.6)
		elseif state == "FinalScramble" then
			showBanner(payload.displayName or "FINAL SCRAMBLE!", payload.description or "10 seconds!", 3)
		elseif state == "Ended" or state == "Eliminated" then
			bannerToken += 1
			if frame then
				frame.Visible = false
			end
		end
	end)
end

return RoundEventController
