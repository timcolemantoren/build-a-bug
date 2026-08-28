--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local RemoteNames = require(BuildABugShared.Remotes.RemoteNames)

local PlayerDataService = require(script.Parent.PlayerDataService)
local BugLoadoutService = require(script.Parent.BugLoadoutService)
local BugUnlockService = require(script.Parent.BugUnlockService)
local PremiumSkinService = require(script.Parent.PremiumSkinService)
local StudioTestBoostService = require(script.Parent.StudioTestBoostService)
local AchievementService = require(script.Parent.AchievementService)
local RewardService = require(script.Parent.RewardService)
local HazardService = require(script.Parent.HazardService)
local ArenaService = require(script.Parent.ArenaService)
local LobbyService = require(script.Parent.LobbyService)
local RoundService = require(script.Parent.RoundService)
local AbilityService = require(script.Parent.AbilityService)
local EnvironmentHazardService = require(script.Parent.EnvironmentHazardService)
local InteractiveFoliageService = require(script.Parent.InteractiveFoliageService)
local EnvironmentStyleService = require(script.Parent.EnvironmentStyleService)
local BugAvatarService = require(script.Parent.BugAvatarService)
local ExtendedBugAvatarService = require(script.Parent.ExtendedBugAvatarService)
local AdditionalBugAvatarService = require(script.Parent.AdditionalBugAvatarService)
local SkinVisualService = require(script.Parent.SkinVisualService)

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
	SelectBugLoadout = getOrCreateRemoteEvent(remotesFolder, RemoteNames.SelectBugLoadout),
	PurchaseBug = getOrCreateRemoteEvent(remotesFolder, RemoteNames.PurchaseBug),
	BugUnlockResult = getOrCreateRemoteEvent(remotesFolder, RemoteNames.BugUnlockResult),
	BuildPreset = getOrCreateRemoteEvent(remotesFolder, RemoteNames.BuildPreset),
	SetCosmetic = getOrCreateRemoteEvent(remotesFolder, RemoteNames.SetCosmetic),
	PurchaseCosmetic = getOrCreateRemoteEvent(remotesFolder, RemoteNames.PurchaseCosmetic),
	SetPremiumSkin = getOrCreateRemoteEvent(remotesFolder, RemoteNames.SetPremiumSkin),
	StartRoundRequest = getOrCreateRemoteEvent(remotesFolder, RemoteNames.StartRoundRequest),
	ExitRoundRequest = getOrCreateRemoteEvent(remotesFolder, RemoteNames.ExitRoundRequest),
	RoundStateChanged = getOrCreateRemoteEvent(remotesFolder, RemoteNames.RoundStateChanged),
	PlayerDataChanged = getOrCreateRemoteEvent(remotesFolder, RemoteNames.PlayerDataChanged),
	HazardWarning = getOrCreateRemoteEvent(remotesFolder, RemoteNames.HazardWarning),
	UseAbility = getOrCreateRemoteEvent(remotesFolder, RemoteNames.UseAbility),
}

ArenaService.BuildArena()
EnvironmentStyleService.Init()
LobbyService.Build()
PlayerDataService.Init(remotes)
StudioTestBoostService.Init(PlayerDataService)
BugLoadoutService.Init(PlayerDataService, remotes)
BugUnlockService.Init(PlayerDataService, remotes)
PremiumSkinService.Init(PlayerDataService, remotes)
AchievementService.Init(PlayerDataService, remotes)
BugAvatarService.Init(PlayerDataService)
ExtendedBugAvatarService.Init()
AdditionalBugAvatarService.Init()
SkinVisualService.Init()
RewardService.Init(PlayerDataService, AchievementService)
HazardService.Init(remotes, PlayerDataService)
RoundService.Init(remotes, PlayerDataService, RewardService, HazardService, ArenaService, LobbyService)
AbilityService.Init(remotes, PlayerDataService)
EnvironmentHazardService.Init(PlayerDataService)
InteractiveFoliageService.Init(remotes)

print("[Build a Bug] Server initialized")
