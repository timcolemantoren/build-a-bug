--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local RemoteNames = require(BuildABugShared.Remotes.RemoteNames)

local PlayerDataService = require(script.Parent.PlayerDataService)
local RewardService = require(script.Parent.RewardService)
local HazardService = require(script.Parent.HazardService)
local ArenaService = require(script.Parent.ArenaService)
local RoundService = require(script.Parent.RoundService)
local AbilityService = require(script.Parent.AbilityService)
local EnvironmentHazardService = require(script.Parent.EnvironmentHazardService)

local function getOrCreateFolder(parent: Instance, name: string): Folder
	local folder = parent:FindFirstChild(name)
	if folder and folder:IsA("Folder") then
		return folder
	end

	local newFolder = Instance.new("Folder")
	newFolder.Name = name
	newFolder.Parent = parent
	return newFolder
end

local function getOrCreateRemoteEvent(parent: Instance, name: string): RemoteEvent
	local remote = parent:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end

	local newRemote = Instance.new("RemoteEvent")
	newRemote.Name = name
	newRemote.Parent = parent
	return newRemote
end

local remotesFolder = getOrCreateFolder(ReplicatedStorage, RemoteNames.FolderName)

local remotes = {
	SelectBug = getOrCreateRemoteEvent(remotesFolder, RemoteNames.SelectBug),
	StartRoundRequest = getOrCreateRemoteEvent(remotesFolder, RemoteNames.StartRoundRequest),
	RoundStateChanged = getOrCreateRemoteEvent(remotesFolder, RemoteNames.RoundStateChanged),
	PlayerDataChanged = getOrCreateRemoteEvent(remotesFolder, RemoteNames.PlayerDataChanged),
	HazardWarning = getOrCreateRemoteEvent(remotesFolder, RemoteNames.HazardWarning),
	UseAbility = getOrCreateRemoteEvent(remotesFolder, RemoteNames.UseAbility),
}

ArenaService.BuildArena()
PlayerDataService.Init(remotes)
RewardService.Init(PlayerDataService)
HazardService.Init(remotes, PlayerDataService)
RoundService.Init(remotes, PlayerDataService, RewardService, HazardService, ArenaService)
AbilityService.Init(remotes, PlayerDataService)
EnvironmentHazardService.Init(PlayerDataService)

print("[Build a Bug] Server initialized")
