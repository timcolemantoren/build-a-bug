--!strict

-- Lightweight type reference for future cleanup.
-- Luau type exports can help us keep DataStore shape consistent as the project grows.

export type Currency = {
	dna: number,
	crumbs: number,
}

export type SavedBuild = {
	base: string,
	color: string,
	pattern: string,
	eyes: string,
	shell: string,
}

export type PlayerStats = {
	roundsPlayed: number,
	longestSurvival: number,
	foodCollected: number,
}

export type PlayerData = {
	version: number,
	selectedBug: string,
	currency: Currency,
	unlockedBugs: { [string]: boolean },
	unlockedCosmetics: { [string]: boolean },
	savedBuilds: { [string]: SavedBuild },
	stats: PlayerStats,
}

return {}
