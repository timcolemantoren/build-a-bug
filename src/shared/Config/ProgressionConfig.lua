--!strict

local ProgressionConfig = {}

-- Early prototype levels arrived too quickly in one or two rounds. Keep the first
-- ten levels readable for younger players, then widen the late-game gaps so
-- long-term titles remain meaningful after the initial collection is underway.
ProgressionConfig.Levels = {
	{ level = 1, dnaRequired = 0, title = "Fresh Hatchling" },
	{ level = 2, dnaRequired = 150, title = "Tiny Forager" },
	{ level = 3, dnaRequired = 400, title = "Backyard Explorer" },
	{ level = 4, dnaRequired = 800, title = "Scrappy Survivor" },
	{ level = 5, dnaRequired = 1500, title = "Garden Veteran" },
	{ level = 6, dnaRequired = 2500, title = "Tough Critter" },
	{ level = 7, dnaRequired = 4000, title = "Micro Monster" },
	{ level = 8, dnaRequired = 6000, title = "Yard Champion" },
	{ level = 9, dnaRequired = 8000, title = "Backyard Beast" },
	{ level = 10, dnaRequired = 10000, title = "Legendary Bug" },
	{ level = 11, dnaRequired = 15000, title = "Garden Guardian" },
	{ level = 12, dnaRequired = 22000, title = "Tiny Titan" },
	{ level = 13, dnaRequired = 32000, title = "Yard Myth" },
	{ level = 14, dnaRequired = 45000, title = "Insect Icon" },
	{ level = 15, dnaRequired = 60000, title = "Backyard Legend" },
}

function ProgressionConfig.GetLevelForDna(dna: number)
	local current = ProgressionConfig.Levels[1]

	for _, levelInfo in ipairs(ProgressionConfig.Levels) do
		if dna >= levelInfo.dnaRequired then
			current = levelInfo
		else
			break
		end
	end

	return current
end

function ProgressionConfig.GetNextLevelForDna(dna: number)
	for _, levelInfo in ipairs(ProgressionConfig.Levels) do
		if dna < levelInfo.dnaRequired then
			return levelInfo
		end
	end

	return nil
end

return ProgressionConfig
