--!nonstrict

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local AudioController = {}

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

local function playPhaseCue(state: string, payload)
	payload = payload or {}
	if state == "Started" then
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
	elseif state == "Eliminated" then
		playOneShot(SOUND.Bass, 0.95, 0.48, 3)
		task.delay(0.06, function()
			playOneShot(SOUND.Squish, 1.0, 0.82, 4)
		end)
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
		end
	elseif stage == "Impact" then
		if hazardId == "ShoeStomp" then
			playOneShot(SOUND.Bass, 1.0, 0.42, 3)
		elseif hazardId == "SprinklerBurst" then
			playOneShot(SOUND.Water, 0.95, 0.95, 4)
		elseif hazardId == "BirdShadow" then
			playOneShot(SOUND.Bass, 0.72, 1.22, 3)
		end
	end
end

function AudioController.Init(remotes)
	remotes.RoundStateChanged.OnClientEvent:Connect(playPhaseCue)
	remotes.HazardWarning.OnClientEvent:Connect(playHazardCue)
end

return AudioController
