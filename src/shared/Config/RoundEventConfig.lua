--!nonstrict

-- A round should have an arc rather than feeling like one flat timer.
-- Phase times are elapsed seconds from round start.
local RoundEventConfig = {
	Phases = {
		{
			id = "Scavenge",
			displayName = "SCAVENGE!",
			startsAt = 0,
			hazardMinSeconds = 12,
			hazardMaxSeconds = 17,
			eventMinSeconds = 20,
			eventMaxSeconds = 27,
		},
		{
			id = "Trouble",
			displayName = "TROUBLE'S COMING!",
			startsAt = 30,
			hazardMinSeconds = 8,
			hazardMaxSeconds = 12,
			eventMinSeconds = 15,
			eventMaxSeconds = 22,
		},
		{
			id = "Chaos",
			displayName = "BACKYARD CHAOS!",
			startsAt = 75,
			hazardMinSeconds = 5,
			hazardMaxSeconds = 9,
			eventMinSeconds = 10,
			eventMaxSeconds = 16,
		},
	},

	Events = {
		{
			id = "CrumbShower",
			displayName = "CRUMB SHOWER!",
			description = "Food is falling everywhere!",
			weight = 4,
		},
		{
			id = "DnaBurst",
			displayName = "DNA BURST!",
			description = "Glowing DNA has appeared!",
			weight = 3,
		},
		{
			id = "DoubleTrouble",
			displayName = "DOUBLE TROUBLE!",
			description = "Two hazards are coming!",
			weight = 3,
		},
	},
}

function RoundEventConfig.GetPhase(elapsedSeconds: number)
	local selected = RoundEventConfig.Phases[1]
	for _, phase in ipairs(RoundEventConfig.Phases) do
		if elapsedSeconds >= phase.startsAt then
			selected = phase
		end
	end
	return selected
end

function RoundEventConfig.GetRandomEvent()
	local totalWeight = 0
	for _, event in ipairs(RoundEventConfig.Events) do
		totalWeight += event.weight or 1
	end

	local roll = math.random() * totalWeight
	local running = 0
	for _, event in ipairs(RoundEventConfig.Events) do
		running += event.weight or 1
		if roll <= running then
			return event
		end
	end

	return RoundEventConfig.Events[1]
end

return RoundEventConfig
