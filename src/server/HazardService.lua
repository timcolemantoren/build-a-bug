--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local HazardConfig = require(BuildABugShared.Config.HazardConfig)

local HazardService = {}
local remotes = nil

local hazardIds = {}
for hazardId, _ in pairs(HazardConfig) do
	table.insert(hazardIds, hazardId)
end

function HazardService.Init(remoteEvents)
	remotes = remoteEvents
end

function HazardService.GetRandomHazardId(): string?
	if #hazardIds == 0 then
		return nil
	end

	return hazardIds[math.random(1, #hazardIds)]
end

function HazardService.WarnHazard(hazardId: string)
	local hazard = HazardConfig[hazardId]
	if not hazard then
		warn("Unknown hazard:", hazardId)
		return
	end

	if remotes and remotes.HazardWarning then
		remotes.HazardWarning:FireAllClients({
			id = hazard.id,
			displayName = hazard.displayName,
			warningSeconds = hazard.warningSeconds,
			damage = hazard.damage,
			description = hazard.description,
		})
	end
end

return HazardService
