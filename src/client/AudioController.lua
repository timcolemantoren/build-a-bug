--!nonstrict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local AudioController = {}
local player = Players.LocalPlayer
local currentHumanoid = nil
local healthConnection = nil
local lastHealth = nil
local inRound = false
local criticalHealthLatched = false
local openingPlayed = false
local sfxGroup = nil
local signatureGroup = nil
local musicGroup = nil
local musicSound = nil

-- Keep launch audio independent from any third-party license. If we later upload
-- a cleared/original opening sting, drop its rbxassetid here and the fallback
-- Build a Bug motif will automatically step aside.
local OPENING_AUDIO_ID = ""
local OPENING_AUDIO_VOLUME = 0.42

-- Temporary beta background track from Roblox Creator Store. Keep this isolated
-- so the final original Build a Bug theme can replace it without touching logic.
-- The music intentionally sits well below gameplay SFX and should feel more like
-- backyard atmosphere than the main thing the player is listening to.
local BACKGROUND_MUSIC_ID = "rbxassetid://1837383248"
local BACKGROUND_MUSIC_VOLUME = 0.055

-- Roblox-bundled assets keep the beta SFX path safe and deterministic. The
-- pitch/rhythm language below is the game's temporary sonic identity, and all
-- cues remain centralized here so custom authored assets can replace them later.
local SOUND = {
	Ping = "rbxasset://sounds/electronicpingshort.wav",
	Bass = "rbxasset://sounds/bass.wav",
	Water = "rbxasset://sounds/impact_water.mp3",
	Squish = "rbxasset://sounds/uuhhh.mp3",
}

local GRASS_REACTIONS = { "WHEE!", "WOOHOO!", "WHOAA!" }

local function getOrCreateSoundGroup(name: string, volume: number)
	local existing = SoundService:FindFirstChild(name)
	if existing and existing:IsA("SoundGroup") then
		existing.Volume = volume
		return existing
	end
	local group = Instance.new("SoundGroup")
	group.Name = name
	group.Volume = volume
	group.Parent = SoundService
	return group
end

local function ensureGroups()
	if not sfxGroup then
		sfxGroup = getOrCreateSoundGroup("BuildABugSFXGroup", 0.92)
	end
	if not signatureGroup then
		signatureGroup = getOrCreateSoundGroup("BuildABugSignatureGroup", 0.82)
	end
	if not musicGroup then
		musicGroup = getOrCreateSoundGroup("BuildABugMusicGroup", 0)
	end
end

local function playOneShot(soundId: string, volume: number?, playbackSpeed: number?, lifetime: number?, group)
	ensureGroups()
	local sound = Instance.new("Sound")
	sound.Name = "BuildABugSFX"
	sound.SoundId = soundId
	sound.Volume = volume or 0.65
	sound.PlaybackSpeed = playbackSpeed or 1
	sound.SoundGroup = group or sfxGroup
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, lifetime or 5)
	return sound
end

local function playPingSequence(speeds, spacing: number, volume: number?, delaySeconds: number?)
	local startDelay = delaySeconds or 0
	for index, speed in ipairs(speeds) do
		task.delay(startDelay + (index - 1) * spacing, function()
			playOneShot(SOUND.Ping, volume or 0.6, speed, 2)
		end)
	end
end

local function playBassSequence(speeds, spacing: number, volume: number?, delaySeconds: number?)
	local startDelay = delaySeconds or 0
	for index, speed in ipairs(speeds) do
		task.delay(startDelay + (index - 1) * spacing, function()
			playOneShot(SOUND.Bass, volume or 0.45, speed, 2)
		end)
	end
end

local function playPingCluster(speeds, volume: number?, delaySeconds: number?)
	local delay = delaySeconds or 0
	for _, speed in ipairs(speeds) do
		task.delay(delay, function()
			playOneShot(SOUND.Ping, volume or 0.22, speed, 2, signatureGroup)
		end)
	end
end

local function playFallbackOpeningSignature()
	playOneShot(SOUND.Bass, 0.20, 1.36, 2, signatureGroup)
	playPingSequence({ 0.92, 1.14, 1.42 }, 0.17, 0.24, 0.05)
	playPingSequence({ 1.05, 1.30, 1.62 }, 0.14, 0.28, 0.78)
	playPingCluster({ 1.22, 1.53, 1.84 }, 0.18, 1.28)
	playOneShot(SOUND.Bass, 0.16, 1.72, 2, signatureGroup)
end

local function playOpeningSignature()
	if openingPlayed then
		return
	end
	openingPlayed = true
	ensureGroups()

	if type(OPENING_AUDIO_ID) == "string" and OPENING_AUDIO_ID ~= "" then
		local sound = Instance.new("Sound")
		sound.Name = "BuildABugOpening"
		sound.SoundId = OPENING_AUDIO_ID
		sound.Volume = OPENING_AUDIO_VOLUME
		sound.SoundGroup = signatureGroup
		sound.Parent = SoundService
		sound:Play()
		Debris:AddItem(sound, 20)
	else
		playFallbackOpeningSignature()
	end
end

local function ensureMusic()
	ensureGroups()
	if musicSound and musicSound.Parent then
		return musicSound
	end

	musicSound = Instance.new("Sound")
	musicSound.Name = "BuildABugBackgroundMusic"
	musicSound.SoundId = BACKGROUND_MUSIC_ID
	musicSound.Volume = 1
	musicSound.Looped = true
	musicSound.SoundGroup = musicGroup
	musicSound.Parent = SoundService
	return musicSound
end

local function musicEnabled(): boolean
	return player:GetAttribute("MusicEnabled") ~= false
end

local function applyMusicPreference(instant: boolean?)
	local sound = ensureMusic()
	local enabled = musicEnabled()
	if enabled and not sound.IsPlaying then
		sound:Play()
	end

	local targetVolume = enabled and BACKGROUND_MUSIC_VOLUME or 0
	if instant then
		musicGroup.Volume = targetVolume
	else
		TweenService:Create(
			musicGroup,
			TweenInfo.new(enabled and 0.8 or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Volume = targetVolume }
		):Play()
	end
end

local function startBackgroundMusic()
	ensureMusic()
	applyMusicPreference(false)
end

local function playDamageCue(damageAmount: number)
	if damageAmount <= 0 then
		return
	end

	local strength = math.clamp(damageAmount / 45, 0, 1)
	local volume = 0.30 + (0.22 * strength)
	local playbackSpeed = 1.74 - (0.44 * strength)
	playOneShot(SOUND.Bass, volume, playbackSpeed, 2)

	if damageAmount >= 30 then
		task.delay(0.035, function()
			playOneShot(SOUND.Squish, 0.22, 1.38, 2)
		end)
	end
end

local function playCriticalHealthCue()
	playBassSequence({ 0.78, 0.72 }, 0.18, 0.34)
	playPingSequence({ 0.72, 0.64 }, 0.18, 0.26, 0.05)
end

local function playPillbugRollCue()
	if not inRound or player:GetAttribute("SelectedBug") ~= "Pillbug" then
		return
	end
	playOneShot(SOUND.Bass, 0.44, 1.60, 2)
	playPingSequence({ 0.78, 0.85, 0.93, 1.02 }, 0.12, 0.22)
end

local function showBugReaction(text: string)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	local old = root:FindFirstChild("BuildABugReaction")
	if old then
		old:Destroy()
	end

	local bubble = Instance.new("BillboardGui")
	bubble.Name = "BuildABugReaction"
	bubble.Size = UDim2.fromOffset(150, 52)
	bubble.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)
	bubble.AlwaysOnTop = true
	bubble.LightInfluence = 0
	bubble.Adornee = root
	bubble.Parent = root

	local label = Instance.new("TextLabel")
	label.Name = "ReactionText"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(250, 246, 232)
	label.BackgroundTransparency = 0.08
	label.TextColor3 = Color3.fromRGB(30, 48, 51)
	label.TextStrokeTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 23
	label.Text = text
	label.Parent = bubble

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = label

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(117, 188, 151)
	stroke.Thickness = 2
	stroke.Transparency = 0.18
	stroke.Parent = label

	local scale = Instance.new("UIScale")
	scale.Scale = 0.72
	scale.Parent = label
	TweenService:Create(scale, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	task.delay(0.58, function()
		if label.Parent then
			TweenService:Create(label, TweenInfo.new(0.22), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
			TweenService:Create(stroke, TweenInfo.new(0.22), { Transparency = 1 }):Play()
		end
	end)
	Debris:AddItem(bubble, 0.9)
end

local function playGrassFlickReaction()
	local reaction = GRASS_REACTIONS[math.random(1, #GRASS_REACTIONS)]
	showBugReaction(reaction)
	playOneShot(SOUND.Squish, 0.18, 1.78, 2)
	playPingSequence({ 1.60, 1.92 }, 0.09, 0.20, 0.02)
end

local function disconnectHealth()
	if healthConnection then
		healthConnection:Disconnect()
		healthConnection = nil
	end
	currentHumanoid = nil
	lastHealth = nil
	criticalHealthLatched = false
end

local function bindCharacter(character: Model?)
	disconnectHealth()
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 3)
	if not humanoid then
		return
	end

	currentHumanoid = humanoid
	lastHealth = humanoid.Health
	healthConnection = humanoid.HealthChanged:Connect(function(health)
		if lastHealth ~= nil and health < lastHealth and inRound then
			playDamageCue(lastHealth - health)
		end

		local ratio = health / math.max(1, humanoid.MaxHealth)
		if inRound and ratio <= 0.25 and not criticalHealthLatched then
			criticalHealthLatched = true
			playCriticalHealthCue()
		elseif ratio >= 0.40 then
			criticalHealthLatched = false
		end
		lastHealth = health
	end)
end

local function playStartCue()
	playOneShot(SOUND.Bass, 0.22, 1.48, 2)
	playPingSequence({ 1.02, 1.28, 1.58 }, 0.11, 0.38, 0.04)
end

local function playResultsCue()
	playOneShot(SOUND.Bass, 0.18, 1.56, 2)
	playPingSequence({ 1.10, 1.34, 1.62, 1.92 }, 0.10, 0.38, 0.03)
	playPingCluster({ 1.30, 1.62 }, 0.13, 0.43)
end

local function playPhaseCue(state: string, payload)
	payload = payload or {}
	if state == "GrassFlick" then
		playGrassFlickReaction()
	elseif state == "Started" then
		inRound = true
		criticalHealthLatched = false
		if currentHumanoid then
			lastHealth = currentHumanoid.Health
		end
		playStartCue()
	elseif state == "PhaseChanged" then
		local phaseId = payload.phaseId
		if phaseId == "Scavenge" then
			playPingSequence({ 1.02, 1.28 }, 0.12, 0.34)
		elseif phaseId == "Trouble" then
			playOneShot(SOUND.Bass, 0.42, 1.02, 3)
			playPingSequence({ 0.90, 1.08, 1.30 }, 0.11, 0.38, 0.05)
		elseif phaseId == "Chaos" then
			playBassSequence({ 0.78, 0.68 }, 0.14, 0.50)
			playPingSequence({ 0.82, 1.05, 1.40 }, 0.10, 0.42, 0.04)
		end
	elseif state == "FinalScramble" then
		playBassSequence({ 0.66, 0.58 }, 0.14, 0.58)
		playPingSequence({ 1.08, 1.30, 1.56, 1.86 }, 0.085, 0.46, 0.04)
	elseif state == "RoundEvent" then
		local eventId = payload.eventId or payload.id
		if eventId == "DoubleTrouble" then
			playBassSequence({ 1.18, 1.18 }, 0.16, 0.30)
			playPingSequence({ 0.80, 1.18, 0.80, 1.18 }, 0.075, 0.36, 0.03)
		elseif eventId == "DnaBurst" or eventId == "DNABurst" then
			playPingSequence({ 1.22, 1.50, 1.82 }, 0.085, 0.38)
			playPingCluster({ 1.42, 1.78 }, 0.12, 0.29)
		elseif eventId == "CrumbShower" then
			playPingSequence({ 0.96, 1.08, 1.20 }, 0.105, 0.30)
		end
	elseif state == "AchievementUnlocked" then
		playOneShot(SOUND.Bass, 0.30, 1.38, 2)
		playPingSequence({ 1.08, 1.34, 1.64, 1.98 }, 0.095, 0.46, 0.03)
		playPingCluster({ 1.30, 1.62, 1.94 }, 0.12, 0.42)
	elseif state == "Eliminated" then
		inRound = false
		criticalHealthLatched = false
		playOneShot(SOUND.Bass, 0.72, 0.50, 3)
		task.delay(0.06, function()
			playOneShot(SOUND.Squish, 0.78, 0.84, 4)
		end)
	elseif state == "Results" then
		inRound = false
		criticalHealthLatched = false
		playResultsCue()
	elseif state == "ExitedRound" then
		inRound = false
		criticalHealthLatched = false
		playPingSequence({ 0.98, 0.82 }, 0.12, 0.22)
	elseif state == "Ended" or state == "Waiting" or state == "MatchInProgress" then
		inRound = false
		criticalHealthLatched = false
	end
end

local function playHazardCue(payload)
	payload = payload or {}
	local hazardId = payload.id
	local stage = payload.stage or "Warning"

	if stage == "Warning" then
		if hazardId == "ShoeStomp" then
			playBassSequence({ 0.72, 0.86 }, 0.20, 0.52)
		elseif hazardId == "SprinklerBurst" then
			playPingSequence({ 1.58, 1.84 }, 0.13, 0.40)
		elseif hazardId == "BirdShadow" then
			playPingSequence({ 0.72, 0.62 }, 0.17, 0.42)
		elseif hazardId == "RollingBall" then
			playOneShot(SOUND.Bass, 0.38, 1.42, 2)
			playPingSequence({ 0.94, 1.08 }, 0.16, 0.28, 0.04)
		elseif hazardId == "Raindrop" then
			playPingSequence({ 1.64, 1.42, 1.22 }, 0.16, 0.32)
		elseif hazardId == "WindGust" then
			playPingSequence({ 0.94, 1.10, 1.30 }, 0.11, 0.24)
		elseif hazardId == "RakeSweep" then
			playOneShot(SOUND.Bass, 0.30, 1.46, 2)
			playPingSequence({ 0.86, 0.98 }, 0.14, 0.28, 0.05)
		end
	elseif stage == "Impact" then
		if hazardId == "ShoeStomp" then
			playOneShot(SOUND.Bass, 0.82, 0.44, 3)
		elseif hazardId == "SprinklerBurst" then
			playOneShot(SOUND.Water, 0.72, 0.96, 4)
		elseif hazardId == "BirdShadow" then
			playOneShot(SOUND.Bass, 0.50, 1.24, 3)
		elseif hazardId == "RollingBall" then
			playOneShot(SOUND.Bass, 0.50, 1.58, 2)
			playPingSequence({ 0.82, 0.96, 1.10 }, 0.10, 0.22, 0.03)
		elseif hazardId == "Raindrop" then
			playOneShot(SOUND.Water, 0.62, 1.28, 3)
		elseif hazardId == "WindGust" then
			playOneShot(SOUND.Bass, 0.24, 1.72, 2)
			playPingSequence({ 1.30, 1.12, 0.96 }, 0.08, 0.22, 0.02)
		elseif hazardId == "RakeSweep" then
			playOneShot(SOUND.Bass, 0.44, 0.96, 2)
			playPingSequence({ 1.16, 1.00, 0.84 }, 0.07, 0.20, 0.03)
		end
	end
end

function AudioController.Init(remotes)
	ensureGroups()
	if player:GetAttribute("MusicEnabled") == nil then
		player:SetAttribute("MusicEnabled", true)
	end
	player:GetAttributeChangedSignal("MusicEnabled"):Connect(function()
		applyMusicPreference(false)
	end)

	player.CharacterAdded:Connect(function(character)
		task.wait(0.15)
		bindCharacter(character)
	end)
	if player.Character then
		bindCharacter(player.Character)
	end

	player:GetAttributeChangedSignal("PillbugRollNonce"):Connect(playPillbugRollCue)
	remotes.RoundStateChanged.OnClientEvent:Connect(playPhaseCue)
	remotes.HazardWarning.OnClientEvent:Connect(playHazardCue)

	task.delay(0.65, function()
		if not inRound then
			playOpeningSignature()
		end
	end)
	task.delay(2.35, startBackgroundMusic)
end

return AudioController
