--!strict

local ProgressionConfig = {}

ProgressionConfig.Levels = {
	{ level = 1, dnaRequired = 0, title = "Fresh Hatchling" },
	{ level = 2, dnaRequired = 25, title = "Tiny Forager" },
	{ level = 3, dnaRequired = 75, title = "Backyard Explorer" },
	{ level = 4, dnaRequired = 175, title = "Scrappy Survivor" },
	{ level = 5, dnaRequired = 400, title = "Garden Veteran" },
	{ level = 6, dnaRequired = 900, title = "Tough Critter" },
	{ level = 7, dnaRequired = 1800, title = "Micro Monster" },
	{ level = 8, dnaRequired = 3500, title = "Yard Champion" },
	{ level = 9, dnaRequired = 6500, title = "Backyard Beast" },
	{ level = 10, dnaRequired = 10000, title = "Legendary Bug" },
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
