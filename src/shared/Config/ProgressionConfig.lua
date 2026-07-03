--!strict

local ProgressionConfig = {}

ProgressionConfig.Levels = {
	{ level = 1, dnaRequired = 0, sizeScale = 1.00, title = "Level 1" },
	{ level = 2, dnaRequired = 25, sizeScale = 1.04, title = "Level 2" },
	{ level = 3, dnaRequired = 75, sizeScale = 1.08, title = "Level 3" },
	{ level = 4, dnaRequired = 175, sizeScale = 1.12, title = "Level 4" },
	{ level = 5, dnaRequired = 400, sizeScale = 1.16, title = "Level 5" },
	{ level = 6, dnaRequired = 900, sizeScale = 1.20, title = "Level 6" },
	{ level = 7, dnaRequired = 1800, sizeScale = 1.24, title = "Level 7" },
	{ level = 8, dnaRequired = 3500, sizeScale = 1.28, title = "Level 8" },
	{ level = 9, dnaRequired = 6500, sizeScale = 1.32, title = "Level 9" },
	{ level = 10, dnaRequired = 10000, sizeScale = 1.36, title = "Level 10" },
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
