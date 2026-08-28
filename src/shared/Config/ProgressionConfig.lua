--!strict

local ProgressionConfig = {}

-- Early prototype levels arrived too quickly in one or two rounds. Keep level 10
-- at the original 10k long-term target, but widen the steps substantially so
-- titles feel earned and later levels become real multi-session goals.
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
