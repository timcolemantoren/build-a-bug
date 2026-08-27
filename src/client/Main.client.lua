--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local RemoteNames = require(BuildABugShared.Remotes.RemoteNames)

local remotesFolder = ReplicatedStorage:WaitForChild(RemoteNames.FolderName)

local remotes = {
	SelectBug = remotesFolder:WaitForChild(RemoteNames.SelectBug),
	SetCosmetic = remotesFolder:WaitForChild(RemoteNames.SetCosmetic),
	PurchaseCosmetic = remotesFolder:WaitForChild(RemoteNames.PurchaseCosmetic),
	StartRoundRequest = remotesFolder:WaitForChild(RemoteNames.StartRoundRequest),
	ExitRoundRequest = remotesFolder:WaitForChild(RemoteNames.ExitRoundRequest),
	RoundStateChanged = remotesFolder:WaitForChild(RemoteNames.RoundStateChanged),
	PlayerDataChanged = remotesFolder:WaitForChild(RemoteNames.PlayerDataChanged),
	HazardWarning = remotesFolder:WaitForChild(RemoteNames.HazardWarning),
	UseAbility = remotesFolder:WaitForChild(RemoteNames.UseAbility),
}

local clientRoot = script.Parent
local HUDController = require(clientRoot.UI.HUDController)
local BugSelectController = require(clientRoot.UI.BugSelectController)
local ProfileController = require(clientRoot.UI.ProfileController)
local RoundEndController = require(clientRoot.UI.RoundEndController)
local AbilityController = require(clientRoot.UI.AbilityController)
local RoundEventController = require(clientRoot.UI.RoundEventController)
local SurvivalController = require(clientRoot.UI.SurvivalController)
local CameraController = require(clientRoot.Camera.CameraController)
local BugMotionController = require(clientRoot.BugMotionController)
local EnvironmentMotionController = require(clientRoot.EnvironmentMotionController)

HUDController.Init(remotes)
BugSelectController.Init(remotes)
ProfileController.Init(remotes)
RoundEndController.Init(remotes)
AbilityController.Init(remotes)
RoundEventController.Init(remotes)
SurvivalController.Init(remotes)
CameraController.Init()
BugMotionController.Init()
EnvironmentMotionController.Init()

print("[Build a Bug] Client initialized")
