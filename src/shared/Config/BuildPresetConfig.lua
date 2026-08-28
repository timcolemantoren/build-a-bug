--!strict

local BuildPresetConfig = {}

BuildPresetConfig.Count = 6
BuildPresetConfig.Order = {}
BuildPresetConfig.Valid = {}

for index = 1, BuildPresetConfig.Count do
	local id = "Build" .. tostring(index)
	local entry = {
		id = id,
		name = "Build " .. tostring(index),
	}
	table.insert(BuildPresetConfig.Order, entry)
	BuildPresetConfig.Valid[id] = true
end

function BuildPresetConfig.IsValid(presetId: string): boolean
	return BuildPresetConfig.Valid[presetId] == true
end

return BuildPresetConfig
