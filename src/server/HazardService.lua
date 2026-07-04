--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local HazardConfig = require(BuildABugShared.Config.HazardConfig)

local HazardService = {}
local remotes = nil

local hazardIds = {}
for hazardId, _ in pairs(HazardConfig) do
	table.insert(hazardIds, hazardId)
end

local function getHazardsFolder(): Folder
	local arena = Workspace:FindFirstChild("BuildABugArena")
	if not arena then
		arena = Instance.new("Folder")
		arena.Name = "BuildABugArena"
		arena.Parent = Workspace
	end

	local hazards = arena:FindFirstChild("Hazards")
	if hazards and hazards:IsA("Folder") then
		return hazards
	end

	local folder = Instance.new("Folder")
	folder.Name = "Hazards"
	folder.Parent = arena
	return folder
end

local function makeZone(hazardId: string)
	if hazardId == "SprinklerBurst" then
		return {
			center = Vector3.new(math.random(-35, 35), 0.35, math.random(-25, 25)),
			size = Vector3.new(18, 0.5, 70),
		}
	elseif hazardId == "ShoeStomp" then
		return {
			center = Vector3.new(math.random(-45, 45), 0.35, math.random(-45, 45)),
			size = Vector3.new(24, 0.5, 24),
		}
	else
		return {
			center = Vector3.new(math.random(-45, 45), 0.35, math.random(-45, 45)),
			size = Vector3.new(34, 0.5, 26),
		}
	end
end

local function createWarningPart(hazard, zone)
	local part = Instance.new("Part")
	part.Name = hazard.id .. "Warning"
	part.Anchored = true
	part.CanCollide = false
	part.Size = zone.size
	part.Position = zone.center
	part.Transparency = 0.45
	part.Color = Color3.fromRGB(255, 80, 55)
	part.Material = Enum.Material.Neon
	part.Parent = getHazardsFolder()
	return part
end

local function isInsideZone(rootPart: BasePart, zone): boolean
	local relative = rootPart.Position - zone.center
	local half = zone.size / 2
	return math.abs(relative.X) <= half.X and math.abs(relative.Z) <= half.Z
end

local function damagePlayersInZone(zone, damage: number)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if rootPart and humanoid and humanoid.Health > 0 and isInsideZone(rootPart, zone) then
			humanoid:TakeDamage(damage)
		end
	end
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

	local zone = makeZone(hazardId)
	local warningPart = createWarningPart(hazard, zone)

	if remotes and remotes.HazardWarning then
		remotes.HazardWarning:FireAllClients({
			id = hazard.id,
			displayName = hazard.displayName,
			warningSeconds = hazard.warningSeconds,
			damage = hazard.damage,
			description = hazard.description,
		})
	end

	task.delay(hazard.warningSeconds or 3, function()
		if warningPart and warningPart.Parent then
			warningPart.Transparency = 0.15
			warningPart.Color = Color3.fromRGB(255, 0, 0)
		end

		damagePlayersInZone(zone, hazard.damage or 25)

		task.delay(0.6, function()
			if warningPart and warningPart.Parent then
				warningPart:Destroy()
			end
		end)
	end)
end

return HazardService
