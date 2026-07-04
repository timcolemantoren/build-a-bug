--!nonstrict

local Workspace = game:GetService("Workspace")

local ArenaService = {}

local ARENA_HALF_SIZE = 62

local arenaFolder = nil
local spawnPosition = Vector3.new(0, 6, 42)

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

function ArenaService.BuildArena()
	removeDefaultBaseplate()

	local existing = Workspace:FindFirstChild("BuildABugArena")
	if existing then
		existing:Destroy()
	end

	arenaFolder = createFolder(Workspace, "BuildABugArena")
	spawnPosition = Vector3.new(0, 6, 42)

	local ground = createPart(arenaFolder, "DirtFloor", Vector3.new(140, 1, 140), Vector3.new(0, 0, 0), Color3.fromRGB(116, 83, 55), Enum.Material.SmoothPlastic)
	ground:SetAttribute("Purpose", "Main arena floor")

	local zoneFolder = createFolder(arenaFolder, "ZoneMarkers")
	createMarker(zoneFolder, "PatioCrumbZone", Vector3.new(38, 0.08, 30), Vector3.new(-36, 0.56, -28), Color3.fromRGB(150, 150, 145))
	createMarker(zoneFolder, "BugNestSpawn", Vector3.new(24, 0.08, 20), Vector3.new(0, 0.57, 42), Color3.fromRGB(92, 58, 34))
	createMarker(zoneFolder, "FlowerBed", Vector3.new(42, 0.08, 24), Vector3.new(36, 0.58, -30), Color3.fromRGB(70, 115, 55))
	createMarker(zoneFolder, "MulchMaze", Vector3.new(38, 0.08, 24), Vector3.new(36, 0.59, 24), Color3.fromRGB(90, 48, 30))

	local coverFolder = createFolder(arenaFolder, "Cover")
	createPart(coverFolder, "LeafCoverA", Vector3.new(18, 2, 10), Vector3.new(-20, 2, 10), Color3.fromRGB(55, 125, 50), Enum.Material.SmoothPlastic)
	createPart(coverFolder, "LeafCoverB", Vector3.new(16, 2, 9), Vector3.new(18, 2, 4), Color3.fromRGB(65, 145, 55), Enum.Material.SmoothPlastic)
	createPart(coverFolder, "GardenGlove", Vector3.new(16, 4, 10), Vector3.new(-44, 2.5, 22), Color3.fromRGB(45, 95, 150), Enum.Material.SmoothPlastic)
	createPart(coverFolder, "ToyBlock", Vector3.new(10, 10, 10), Vector3.new(0, 5, -36), Color3.fromRGB(200, 70, 60), Enum.Material.SmoothPlastic)

	local wallsFolder = createFolder(arenaFolder, "Boundary")
	createPart(wallsFolder, "NorthFence", Vector3.new(150, 18, 2), Vector3.new(0, 9, -74), Color3.fromRGB(130, 90, 55), Enum.Material.SmoothPlastic)
	createPart(wallsFolder, "SouthFence", Vector3.new(150, 18, 2), Vector3.new(0, 9, 74), Color3.fromRGB(130, 90, 55), Enum.Material.SmoothPlastic)
	createPart(wallsFolder, "WestFence", Vector3.new(2, 18, 150), Vector3.new(-74, 9, 0), Color3.fromRGB(130, 90, 55), Enum.Material.SmoothPlastic)
	createPart(wallsFolder, "EastFence", Vector3.new(2, 18, 150), Vector3.new(74, 9, 0), Color3.fromRGB(130, 90, 55), Enum.Material.SmoothPlastic)

	local grassFolder = createFolder(arenaFolder, "GrassBorder")
	for i = 1, 18 do
		local x = -68 + (i * 8)
		createPart(grassFolder, "GrassBladeNorth" .. i, Vector3.new(2, 18 + math.random(0, 10), 2), Vector3.new(x, 9, -66), Color3.fromRGB(45, 140, 50), Enum.Material.SmoothPlastic)
		createPart(grassFolder, "GrassBladeSouth" .. i, Vector3.new(2, 18 + math.random(0, 10), 2), Vector3.new(x, 9, 66), Color3.fromRGB(45, 140, 50), Enum.Material.SmoothPlastic)
	end

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

	local horizontal = randomHorizontalPosition(6)
	return Vector3.new(horizontal.X, 2.2, horizontal.Z)
end

function ArenaService.GetRandomAirPickupPosition(): Vector3
	if not arenaFolder then
		ArenaService.BuildArena()
	end

	local horizontal = randomHorizontalPosition(10)
	local height = math.random(8, 24)
	return Vector3.new(horizontal.X, height, horizontal.Z)
end

function ArenaService.GetRandomCrumbPosition(): Vector3
	return ArenaService.GetRandomGroundPickupPosition()
end

return ArenaService
