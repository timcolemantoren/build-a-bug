--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local BugArchetypes = require(BuildABugShared.Config.BugArchetypes)

local EnvironmentHazardService = {}
local PlayerDataService = nil

local TICK_SECONDS = 0.35

local function getZonesFolder(): Folder?
	local arena = Workspace:FindFirstChild("BuildABugArena")
	return arena and arena:FindFirstChild("EnvironmentZones")
end

local function pointInsideZone(position: Vector3, zone: BasePart): boolean
	local relative = zone.CFrame:PointToObjectSpace(position)
	local half = zone.Size / 2
	return math.abs(relative.X) <= half.X and math.abs(relative.Y) <= half.Y + 6 and math.abs(relative.Z) <= half.Z
end

local function getBaseSpeed(player: Player): number
	if not PlayerDataService then
		return 16
	end

	local data = PlayerDataService.GetData(player)
	local bug = data and BugArchetypes[data.selectedBug]
	return bug and bug.movementSpeed or 16
end

local function applyEnvironmentToPlayer(player: Player)
	local zonesFolder = getZonesFolder()
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not zonesFolder or not rootPart or not humanoid or humanoid.Health <= 0 then
		return
	end

	local slowMultiplier = 1
	local damagePerSecond = 0
	local zoneName = nil

	for _, zone in ipairs(zonesFolder:GetChildren()) do
		if zone:IsA("BasePart") and zone:GetAttribute("IsEnvironmentZone") and pointInsideZone(rootPart.Position, zone) then
			slowMultiplier = math.min(slowMultiplier, zone:GetAttribute("SlowMultiplier") or 1)
			damagePerSecond += zone:GetAttribute("DamagePerSecond") or 0
			zoneName = zone.Name
		end
	end

	humanoid.WalkSpeed = math.max(6, getBaseSpeed(player) * slowMultiplier)
	player:SetAttribute("EnvironmentZone", zoneName or "")

	if damagePerSecond > 0 then
		humanoid:TakeDamage(damagePerSecond * TICK_SECONDS)
	end
end

function EnvironmentHazardService.Init(playerDataService)
	PlayerDataService = playerDataService

	task.spawn(function()
		while true do
			for _, player in ipairs(Players:GetPlayers()) do
				applyEnvironmentToPlayer(player)
			end
			task.wait(TICK_SECONDS)
		end
	end)
end

return EnvironmentHazardService
