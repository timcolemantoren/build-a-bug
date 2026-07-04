--!nonstrict

local Workspace = game:GetService("Workspace")

local ArenaService = {}

-- Current prototype yard is much larger than the first graybox.
-- Side length is 420 studs, about 9x the original 140x140 area.
local ARENA_HALF_SIZE = 210
local ARENA_SIDE_LENGTH = ARENA_HALF_SIZE * 2

local arenaFolder = nil
local spawnPosition = Vector3.new(0, 6, 145)

local function createFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function createPart(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function createMarker(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3): Part
	local marker = createPart(parent, name, size, position, color, Enum.Material.SmoothPlastic)
	marker.Transparency = 0.18
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	return marker
end

local function createZone(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, slowMultiplier: number?, damagePerSecond: number?): Part
	local zone = createMarker(parent, name, size, position, color)
	zone.Transparency = 0.35
	zone:SetAttribute("IsEnvironmentZone", true)
	zone:SetAttribute("SlowMultiplier", slowMultiplier or 1)
	zone:SetAttribute("DamagePerSecond", damagePerSecond or 0)
	return zone
end

local function removeDefaultBaseplate()
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate:Destroy()
	end
end

local function randomHorizontalPosition(margin: number): Vector3
	local min = -ARENA_HALF_SIZE + margin
	local max = ARENA_HALF_SIZE - margin
	return Vector3.new(math.random(min, max), 0, math.random(min, max))
end

local function scatterGrassClumps(parent: Instance)
	for i = 1, 130 do
		local pos = randomHorizontalPosition(22)
		local height = math.random(10, 36)
		local blade = createPart(parent, "GrassBlade" .. i, Vector3.new(2, height, 2), Vector3.new(pos.X, height / 2, pos.Z), Color3.fromRGB(45 + math.random(0, 20), 125 + math.random(0, 35), 45), Enum.Material.SmoothPlastic)
		blade.Orientation = Vector3.new(math.random(-10, 10), math.random(0, 180), math.random(-10, 10))
	end
end

local function scatterPebbles(parent: Instance)
	for i = 1, 65 do
		local pos = randomHorizontalPosition(18)
		local size = Vector3.new(math.random(3, 10), math.random(2, 6), math.random(3, 9))
		local rock = createPart(parent, "Pebble" .. i, size, Vector3.new(pos.X, size.Y / 2 + 0.6, pos.Z), Color3.fromRGB(95 + math.random(0, 35), 90 + math.random(0, 35), 82 + math.random(0, 35)), Enum.Material.SmoothPlastic)
		rock.Orientation = Vector3.new(math.random(0, 25), math.random(0, 180), math.random(0, 25))
	end
end

local function scatterLeaves(parent: Instance)
	for i = 1, 45 do
		local pos = randomHorizontalPosition(18)
		local leaf = createPart(parent, "FallenLeaf" .. i, Vector3.new(math.random(9, 18), 0.35, math.random(4, 9)), Vector3.new(pos.X, 0.85, pos.Z), Color3.fromRGB(95 + math.random(0, 50), 120 + math.random(0, 45), 45), Enum.Material.SmoothPlastic)
		leaf.CanCollide = false
		leaf.Orientation = Vector3.new(0, math.random(0, 180), 0)
	end
end

local function scatterTwigs(parent: Instance)
	for i = 1, 38 do
		local pos = randomHorizontalPosition(20)
		local twig = createPart(parent, "Twig" .. i, Vector3.new(math.random(12, 28), 1.2, 1.2), Vector3.new(pos.X, 1.2, pos.Z), Color3.fromRGB(95, 60, 35), Enum.Material.SmoothPlastic)
		twig.Orientation = Vector3.new(math.random(-8, 8), math.random(0, 180), math.random(-8, 8))
	end
end

local function createGardenHose(parent: Instance, zonesFolder: Folder)
	local hoseFolder = createFolder(parent, "GardenHose")
	local points = {
		Vector3.new(-180, 1.2, -150),
		Vector3.new(-135, 1.2, -130),
		Vector3.new(-95, 1.2, -145),
		Vector3.new(-55, 1.2, -120),
		Vector3.new(-25, 1.2, -92),
	}

	for i = 1, #points - 1 do
		local a = points[i]
		local b = points[i + 1]
		local mid = (a + b) / 2
		local length = (b - a).Magnitude
		local hose = createPart(hoseFolder, "HoseSegment" .. i, Vector3.new(length, 2.5, 2.5), mid, Color3.fromRGB(35, 135, 70), Enum.Material.SmoothPlastic)
		hose.CFrame = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.rad(90), 0)
	end

	createPart(hoseFolder, "HoseNozzle", Vector3.new(10, 5, 5), Vector3.new(-20, 2.5, -86), Color3.fromRGB(80, 90, 95), Enum.Material.SmoothPlastic)
	createZone(zonesFolder, "HoseDripSlowZone", Vector3.new(44, 0.12, 36), Vector3.new(-18, 0.72, -68), Color3.fromRGB(70, 170, 255), 0.45, 0)
end

local function createPuddles(parent: Instance, zonesFolder: Folder)
	createMarker(parent, "LittlePuddleA", Vector3.new(46, 0.12, 34), Vector3.new(130, 0.7, 130), Color3.fromRGB(70, 145, 210)).Transparency = 0.28
	createZone(zonesFolder, "PuddleSlowZoneA", Vector3.new(50, 0.12, 38), Vector3.new(130, 0.75, 130), Color3.fromRGB(70, 145, 210), 0.6, 0)

	createMarker(parent, "LittlePuddleB", Vector3.new(34, 0.12, 24), Vector3.new(-138, 0.71, 24), Color3.fromRGB(75, 155, 220)).Transparency = 0.3
	createZone(zonesFolder, "PuddleSlowZoneB", Vector3.new(38, 0.12, 28), Vector3.new(-138, 0.76, 24), Color3.fromRGB(75, 155, 220), 0.65, 0)
end

local function createDamageZones(parent: Instance, zonesFolder: Folder)
	createMarker(parent, "SplinterPatch", Vector3.new(48, 0.12, 30), Vector3.new(30, 0.74, -165), Color3.fromRGB(150, 85, 45)).Transparency = 0.25
	for i = 1, 11 do
		local spike = createPart(parent, "Splinter" .. i, Vector3.new(2, math.random(5, 12), 2), Vector3.new(10 + math.random(0, 42), 3.2, -180 + math.random(0, 28)), Color3.fromRGB(115, 70, 38), Enum.Material.SmoothPlastic)
		spike.Orientation = Vector3.new(math.random(0, 35), math.random(0, 180), math.random(0, 35))
	end
	createZone(zonesFolder, "SplinterDamageZone", Vector3.new(52, 0.12, 34), Vector3.new(30, 0.78, -165), Color3.fromRGB(255, 110, 80), 0.85, 4)
end

function ArenaService.BuildArena()
	removeDefaultBaseplate()

	local existing = Workspace:FindFirstChild("BuildABugArena")
	if existing then
		existing:Destroy()
	end

	arenaFolder = createFolder(Workspace, "BuildABugArena")
	spawnPosition = Vector3.new(0, 6, 145)

	local ground = createPart(arenaFolder, "DirtFloor", Vector3.new(ARENA_SIDE_LENGTH, 1, ARENA_SIDE_LENGTH), Vector3.new(0, 0, 0), Color3.fromRGB(116, 83, 55), Enum.Material.SmoothPlastic)
	ground:SetAttribute("Purpose", "Main arena floor")

	local zoneFolder = createFolder(arenaFolder, "ZoneMarkers")
	createMarker(zoneFolder, "PatioCrumbZone", Vector3.new(75, 0.08, 58), Vector3.new(-105, 0.56, -95), Color3.fromRGB(150, 150, 145))
	createMarker(zoneFolder, "BugNestSpawn", Vector3.new(46, 0.08, 38), Vector3.new(0, 0.57, 145), Color3.fromRGB(92, 58, 34))
	createMarker(zoneFolder, "FlowerBed", Vector3.new(80, 0.08, 46), Vector3.new(105, 0.58, -100), Color3.fromRGB(70, 115, 55))
	createMarker(zoneFolder, "MulchMaze", Vector3.new(84, 0.08, 50), Vector3.new(105, 0.59, 78), Color3.fromRGB(90, 48, 30))
	createMarker(zoneFolder, "OpenDirtRun", Vector3.new(88, 0.08, 54), Vector3.new(-90, 0.6, 72), Color3.fromRGB(125, 92, 60))

	local coverFolder = createFolder(arenaFolder, "Cover")
	createPart(coverFolder, "LeafCoverA", Vector3.new(34, 2, 20), Vector3.new(-55, 2, 40), Color3.fromRGB(55, 125, 50), Enum.Material.SmoothPlastic)
	createPart(coverFolder, "LeafCoverB", Vector3.new(32, 2, 18), Vector3.new(60, 2, 15), Color3.fromRGB(65, 145, 55), Enum.Material.SmoothPlastic)
	createPart(coverFolder, "LeafCoverC", Vector3.new(40, 2, 18), Vector3.new(-145, 2, -20), Color3.fromRGB(50, 132, 52), Enum.Material.SmoothPlastic)
	createPart(coverFolder, "GardenGlove", Vector3.new(28, 5, 18), Vector3.new(-150, 3, 96), Color3.fromRGB(45, 95, 150), Enum.Material.SmoothPlastic)
	createPart(coverFolder, "ToyBlock", Vector3.new(18, 18, 18), Vector3.new(0, 9, -135), Color3.fromRGB(200, 70, 60), Enum.Material.SmoothPlastic)
	createPart(coverFolder, "GardenRockA", Vector3.new(26, 9, 22), Vector3.new(145, 4.5, 25), Color3.fromRGB(110, 110, 105), Enum.Material.SmoothPlastic)
	createPart(coverFolder, "GardenRockB", Vector3.new(20, 7, 28), Vector3.new(-35, 3.5, -150), Color3.fromRGB(115, 115, 110), Enum.Material.SmoothPlastic)
	createPart(coverFolder, "BrokenPot", Vector3.new(30, 16, 22), Vector3.new(175, 8, -60), Color3.fromRGB(160, 78, 48), Enum.Material.SmoothPlastic)

	local clutterFolder = createFolder(arenaFolder, "Clutter")
	scatterPebbles(clutterFolder)
	scatterLeaves(clutterFolder)
	scatterTwigs(clutterFolder)

	local environmentZones = createFolder(arenaFolder, "EnvironmentZones")
	createPuddles(clutterFolder, environmentZones)
	createGardenHose(clutterFolder, environmentZones)
	createDamageZones(clutterFolder, environmentZones)

	local wallsFolder = createFolder(arenaFolder, "Boundary")
	createPart(wallsFolder, "NorthFence", Vector3.new(ARENA_SIDE_LENGTH + 12, 22, 2), Vector3.new(0, 11, -ARENA_HALF_SIZE - 4), Color3.fromRGB(130, 90, 55), Enum.Material.SmoothPlastic)
	createPart(wallsFolder, "SouthFence", Vector3.new(ARENA_SIDE_LENGTH + 12, 22, 2), Vector3.new(0, 11, ARENA_HALF_SIZE + 4), Color3.fromRGB(130, 90, 55), Enum.Material.SmoothPlastic)
	createPart(wallsFolder, "WestFence", Vector3.new(2, 22, ARENA_SIDE_LENGTH + 12), Vector3.new(-ARENA_HALF_SIZE - 4, 11, 0), Color3.fromRGB(130, 90, 55), Enum.Material.SmoothPlastic)
	createPart(wallsFolder, "EastFence", Vector3.new(2, 22, ARENA_SIDE_LENGTH + 12), Vector3.new(ARENA_HALF_SIZE + 4, 11, 0), Color3.fromRGB(130, 90, 55), Enum.Material.SmoothPlastic)

	local grassFolder = createFolder(arenaFolder, "GrassClumps")
	scatterGrassClumps(grassFolder)

	local pickupsFolder = createFolder(arenaFolder, "Pickups")	pickupsFolder:ClearAllChildren()
end

function ArenaService.GetSpawnPosition(): Vector3
	if not arenaFolder then
		ArenaService.BuildArena()
	end

	return spawnPosition
end

function ArenaService.GetPickupsFolder(): Folder
	if not arenaFolder then
		ArenaService.BuildArena()
	end

	return createFolder(arenaFolder, "Pickups")
end

function ArenaService.GetCrumbsFolder(): Folder
	return ArenaService.GetPickupsFolder()
end

function ArenaService.GetRandomGroundPickupPosition(): Vector3
	if not arenaFolder then
		ArenaService.BuildArena()
	end

	local horizontal = randomHorizontalPosition(14)
	return Vector3.new(horizontal.X, 2.2, horizontal.Z)
end

function ArenaService.GetRandomAirPickupPosition(): Vector3
	if not arenaFolder then
		ArenaService.BuildArena()
	end

	local horizontal = randomHorizontalPosition(18)
	local height = math.random(10, 36)
	return Vector3.new(horizontal.X, height, horizontal.Z)
end

function ArenaService.GetRandomCrumbPosition(): Vector3
	return ArenaService.GetRandomGroundPickupPosition()
end

return ArenaService
