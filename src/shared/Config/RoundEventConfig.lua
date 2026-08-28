--!nonstrict

-- A round should have an arc rather than feeling like one flat timer.
-- The yard gets busier by phase, but survival should remain achievable for kids.
-- Phase times are elapsed seconds from round start.
local RoundEventConfig = {
	Phases = {
		{
			id = "Scavenge",
			displayName = "SCAVENGE!",
			startsAt = 0,
			hazardMinSeconds = 14,
			hazardMaxSeconds = 18,
			eventMinSeconds = 24,
			eventMaxSeconds = 30,
		},
		{
			id = "Trouble",
			displayName = "TROUBLE'S COMING!",
			startsAt = 30,
			hazardMinSeconds = 10,
			hazardMaxSeconds = 14,
			eventMinSeconds = 18,
			eventMaxSeconds = 24,
		},
		{
			id = "Chaos",
			displayName = "BACKYARD CHAOS!",
			startsAt = 75,
			hazardMinSeconds = 7,
			hazardMaxSeconds = 11,
			eventMinSeconds = 13,
			eventMaxSeconds = 18,
		},
	},

	Events = {
		{
			id = "CrumbShower",
			displayName = "CRUMB SHOWER!",
			description = "Food is falling everywhere!",
			weight = 5,
		},
		{
			id = "DnaBurst",
			displayName = "DNA BURST!",
			description = "Glowing DNA has appeared!",
			weight = 4,
		},
		{
			id = "DoubleTrouble",
			displayName = "DOUBLE TROUBLE!",
			description = "Two hazards are coming!",
			weight = 2,
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
