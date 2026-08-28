--!strict

-- Centralized RemoteEvent/RemoteFunction names.
-- Server creates these under ReplicatedStorage/BuildABugRemotes.

local RemoteNames = {
	FolderName = "BuildABugRemotes",
	SelectBug = "SelectBug",
	SelectBugLoadout = "SelectBugLoadout",
	PurchaseBug = "PurchaseBug",
	BuildPreset = "BuildPreset",
	SetCosmetic = "SetCosmetic",
	PurchaseCosmetic = "PurchaseCosmetic",
	SetPremiumSkin = "SetPremiumSkin",
	StartRoundRequest = "StartRoundRequest",
	ExitRoundRequest = "ExitRoundRequest",
	RoundStateChanged = "RoundStateChanged",
	PlayerDataChanged = "PlayerDataChanged",
	HazardWarning = "HazardWarning",
	UseAbility = "UseAbility",
}

return RemoteNames
