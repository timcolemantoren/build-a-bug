--!nonstrict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local AudioController = {}
local player = Players.LocalPlayer
local currentHumanoid = nil
local healthConnection = nil
local lastHealth = nil
local inRound = false

-- Prototype audio uses Roblox-bundled sounds so timing/feedback can be tested
-- before custom music and SFX assets are authored. All playback is centralized
-- here so replacing these later does not touch gameplay services.
local SOUND = {
	Ping = "rbxasset://sounds/electronicpingshort.wav",
	Bass = "rbxasset://sounds/bass.wav",
	Water = "rbxasset://sounds/impact_water.mp3",
	Squish = "rbxasset://sounds/uuhhh.mp3",
}

local function playOneShot(soundId: string, volume: number?, playbackSpeed: number?, lifetime: number?)
	local sound = Instance.new("Sound")
	sound.Name = "BuildABugSFX"
	sound.SoundId = soundId
	sound.Volume = volume or 0.65
	sound.PlaybackSpeed = playbackSpeed or 1
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, lifetime or 5)
	return sound
end

local function playPingSequence(speeds, spacing: number, volume: number?)
	for index, speed in ipairs(speeds) do
		task.delay((index - 1) * spacing, function()
			playOneShot(SOUND.Ping, volume or 0.6, speed, 2)
		end)
	end
end

local function playDamageCue(damageAmount: number)
	if damageAmount <= 0 then
		return
	end

	local strength = math.clamp(damageAmount / 45, 0, 1)
	local volume = 0.38 + (0.26 * strength)
	local playbackSpeed = 1.72 - (0.42 * strength)
	playOneShot(SOUND.Bass, volume, playbackSpeed, 2)

	if damageAmount >= 30 then
		task.delay(0.035, function()
			playOneShot(SOUND.Squish, 0.28, 1.35, 2)
		end)
	end
end

local function playPillbugRollCue()
	if not inRound or player:GetAttribute("SelectedBug") ~= "Pillbug" then
		return
	end
	playOneShot(SOUND.Bass, 0.52, 1.58, 2)
	playPingSequence({ 0.76, 0.82, 0.88, 0.95, 1.02 }, 0.13, 0.28)
end

local function disconnectHealth()
	if healthConnection then
		healthConnection:Disconnect()
		healthConnection = nil
	end
	currentHumanoid = nil
	lastHealth = nil
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
		lastHealth = health
	end)
end

local function playPhaseCue(state: string, payload)
	payload = payload or {}
	if state == "Started" then
		inRound = true
		if currentHumanoid then
			lastHealth = currentHumanoid.Health
		end
		playPingSequence({ 0.95, 1.18 }, 0.12, 0.55)
	elseif state == "PhaseChanged" then
		local phaseId = payload.phaseId
		if phaseId == "Scavenge" then
			playPingSequence({ 1.0, 1.22 }, 0.12, 0.55)
		elseif phaseId == "Trouble" then
			playOneShot(SOUND.Bass, 0.62, 1.05, 3)
			playPingSequence({ 0.88, 1.05, 1.24 }, 0.10, 0.62)
		elseif phaseId == "Chaos" then
			playOneShot(SOUND.Bass, 0.88, 0.72, 3)
			playPingSequence({ 0.78, 1.02, 1.36 }, 0.09, 0.7)
		end
	elseif state == "FinalScramble" then
		playOneShot(SOUND.Bass, 0.9, 0.62, 3)
		playPingSequence({ 1.08, 1.28, 1.52, 1.78 }, 0.09, 0.72)
	elseif state == "RoundEvent" then
		local eventId = payload.eventId or payload.id
		if eventId == "DoubleTrouble" then
			playPingSequence({ 0.76, 0.76, 1.12, 1.12 }, 0.08, 0.65)
		elseif eventId == "DnaBurst" or eventId == "DNABurst" then
			playPingSequence({ 1.2, 1.48, 1.8 }, 0.08, 0.58)
		elseif eventId == "CrumbShower" then
			playPingSequence({ 0.95, 1.06, 1.17 }, 0.10, 0.5)
		end
	elseif state == "AchievementUnlocked" then
		playOneShot(SOUND.Bass, 0.48, 1.32, 2)
		playPingSequence({ 1.05, 1.28, 1.56, 1.92 }, 0.10, 0.72)
	elseif state == "Eliminated" then
		inRound = false
		playOneShot(SOUND.Bass, 0.95, 0.48, 3)
		task.delay(0.06, function()
			playOneShot(SOUND.Squish, 1.0, 0.82, 4)
		end)
	elseif state == "Ended" or state == "ExitedRound" or state == "Waiting" or state == "Results" or state == "MatchInProgress" then
		inRound = false
	end
end

local function playHazardCue(payload)
	payload = payload or {}
	local hazardId = payload.id
	local stage = payload.stage or "Warning"

	if stage == "Warning" then
		if hazardId == "ShoeStomp" then
			playOneShot(SOUND.Bass, 0.78, 0.72, 3)
			task.delay(0.18, function()
				playOneShot(SOUND.Bass, 0.58, 0.88, 3)
			end)
		elseif hazardId == "SprinklerBurst" then
			playPingSequence({ 1.55, 1.82 }, 0.12, 0.62)
		elseif hazardId == "BirdShadow" then
			playPingSequence({ 0.70, 0.62 }, 0.16, 0.68)
		elseif hazardId == "RollingBall" then
			playOneShot(SOUND.Bass, 0.60, 1.38, 2)
			playPingSequence({ 0.92, 1.02, 1.12 }, 0.15, 0.50)
		elseif hazardId == "Raindrop" then
			playPingSequence({ 1.62, 1.44, 1.26 }, 0.16, 0.50)
		elseif hazardId == "WindGust" then
			playPingSequence({ 0.92, 1.04, 1.18, 1.34 }, 0.10, 0.42)
		elseif hazardId == "RakeSweep" then
			playOneShot(SOUND.Bass, 0.44, 1.48, 2)
			playPingSequence({ 0.84, 0.94, 1.04 }, 0.13, 0.46)
		end
	elseif stage == "Impact" then
		if hazardId == "ShoeStomp" then
			playOneShot(SOUND.Bass, 1.0, 0.42, 3)
		elseif hazardId == "SprinklerBurst" then
			playOneShot(SOUND.Water, 0.95, 0.95, 4)
		elseif hazardId == "BirdShadow" then
			playOneShot(SOUND.Bass, 0.72, 1.22, 3)
		elseif hazardId == "RollingBall" then
			playOneShot(SOUND.Bass, 0.72, 1.60, 2)
			playPingSequence({ 0.78, 0.88, 0.98, 1.08 }, 0.11, 0.38)
		elseif hazardId == "Raindrop" then
			playOneShot(SOUND.Water, 0.82, 1.28, 3)
		elseif hazardId == "WindGust" then
			playOneShot(SOUND.Bass, 0.34, 1.72, 2)
			playPingSequence({ 1.35, 1.18, 1.02, 0.90 }, 0.08, 0.38)
		elseif hazardId == "RakeSweep" then
			playOneShot(SOUND.Bass, 0.62, 0.96, 2)
			playPingSequence({ 1.20, 1.06, 0.92, 0.80 }, 0.07, 0.34)
		end
	end
end

function AudioController.Init(remotes)
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
end

return AudioController
