--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local RemoteNames = require(BuildABugShared.Remotes.RemoteNames)

local remotesFolder = ReplicatedStorage:WaitForChild(RemoteNames.FolderName)

local remotes = {
	SelectBug = remotesFolder:WaitForChild(RemoteNames.SelectBug),
	StartRoundRequest = remotesFolder:WaitForChild(RemoteNames.StartRoundRequest),
	RoundStateChanged = remotesFolder:WaitForChild(RemoteNames.RoundStateChanged),
	PlayerDataChanged = remotesFolder:WaitForChild(RemoteNames.PlayerDataChanged),
	HazardWarning = remotesFolder:WaitForChild(RemoteNames.HazardWarning),
	UseAbility = remotesFolder:WaitForChild(RemoteNames.UseAbility),
}

local clientRoot = script.Parent
local HUDController = require(clientRoot.UI.HUDController)
local BugSelectController = require(clientRoot.UI.BugSelectController)

HUDController.Init(remotes)
BugSelectController.Init(remotes)

print("[Build a Bug] Client initialized")
