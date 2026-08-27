--!strict

-- Centralized RemoteEvent/RemoteFunction names.
-- Server creates these under ReplicatedStorage/BuildABugRemotes.

local RemoteNames = {
	FolderName = "BuildABugRemotes",
	SelectBug = "SelectBug",
	SetCosmetic = "SetCosmetic",
	StartRoundRequest = "StartRoundRequest",
	ExitRoundRequest = "ExitRoundRequest",
	RoundStateChanged = "RoundStateChanged",
	PlayerDataChanged = "PlayerDataChanged",
	HazardWarning = "HazardWarning",
	UseAbility = "UseAbility",
}

return RemoteNames
