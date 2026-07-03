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

local HUDController = require(script.UI.HUDController)
local BugSelectController = require(script.UI.BugSelectController)

HUDController.Init(remotes)
BugSelectController.Init(remotes)

print("[Build a Bug] Client initialized")
