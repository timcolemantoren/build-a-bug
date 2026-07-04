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
	for i = 1, 72 do
		local pos = randomHorizontalPosition(22)
		local height = math.random(12, 34)
		createPart(parent, "GrassBlade" .. i, Vector3.new(2, height, 2), Vector3.new(pos.X, height / 2, pos.Z), Color3.fromRGB(45, 140, 50), Enum.Material.SmoothPlastic)
	end
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

	local wallsFolder = createFolder(arenaFolder, "Boundary")
	createPart(wallsFolder, "NorthFence", Vector3.new(ARENA_SIDE_LENGTH + 12, 22, 2), Vector3.new(0, 11, -ARENA_HALF_SIZE - 4), Color3.fromRGB(130, 90, 55), Enum.Material.SmoothPlastic)
	createPart(wallsFolder, "SouthFence", Vector3.new(ARENA_SIDE_LENGTH + 12, 22, 2), Vector3.new(0, 11, ARENA_HALF_SIZE + 4), Color3.fromRGB(130, 90, 55), Enum.Material.SmoothPlastic)
	createPart(wallsFolder, "WestFence", Vector3.new(2, 22, ARENA_SIDE_LENGTH + 12), Vector3.new(-ARENA_HALF_SIZE - 4, 11, 0), Color3.fromRGB(130, 90, 55), Enum.Material.SmoothPlastic)
	createPart(wallsFolder, "EastFence", Vector3.new(2, 22, ARENA_SIDE_LENGTH + 12), Vector3.new(ARENA_HALF_SIZE + 4, 11, 0), Color3.fromRGB(130, 90, 55), Enum.Material.SmoothPlastic)

	local grassFolder = createFolder(arenaFolder, "GrassClumps")
	scatterGrassClumps(grassFolder)

	local pickupsFolder = createFolder(arenaFolder, "Pickups")
	pickupsFolder:ClearAllChildren()
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
