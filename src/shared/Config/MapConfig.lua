--!nonstrict

-- Central map registry. Mechanics should refer to map IDs instead of hard-coding
-- "the backyard" so seasonal and future maps can plug into the same match loop.
local MapConfig = {
	DefaultMapId = "Backyard",
	Order = {
		"Backyard",
		"FallBackyard",
	},
	Maps = {
		Backyard = {
			id = "Backyard",
			displayName = "Backyard",
			theme = "Summer",
			available = true,
			seasonal = false,
		},
		FallBackyard = {
			id = "FallBackyard",
			displayName = "Fall Backyard",
			theme = "Fall",
			available = false,
			seasonal = true,
			status = "Planned",
		},
	},
}

function MapConfig.GetMap(mapId: string)
	return MapConfig.Maps[mapId]
end

function MapConfig.GetAvailableMapIds()
	local result = {}
	for _, mapId in ipairs(MapConfig.Order) do
		local map = MapConfig.Maps[mapId]
		if map and map.available then
			table.insert(result, mapId)
		end
	end
	return result
end

return MapConfig
