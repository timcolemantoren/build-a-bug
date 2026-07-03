--!nonstrict

local Workspace = game:GetService("Workspace")

local ArenaService = {}

local arenaFolder = nil
local crumbZones = {}

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

local function addCrumbZone(name: string, center: Vector3, radius: number)
	table.insert(crumbZones, {
		name = name,
		center = center,
		radius = radius,
	})
end

function ArenaService.BuildArena()
	local existing = Workspace:FindFirstChild("BuildABugArena")
	if existing then
		existing:Destroy()
	end

	arenaFolder = createFolder(Workspace, "BuildABugArena")
	crumbZones = {}

	local ground = createPart(arenaFolder, "DirtFloor", Vector3.new(140, 1, 140), Vector3.new(0, -0.5, 0), Color3.fromRGB(116, 83, 55), Enum.Material.Ground)
	ground:SetAttribute("Purpose", "Main arena floor")

	createPart(arenaFolder, "PatioCrumbZone", Vector3.new(38, 1.1, 30), Vector3.new(-36, 0.05, -28), Color3.fromRGB(150, 150, 145), Enum.Material.Concrete)
	createPart(arenaFolder, "BugNestSpawn", Vector3.new(24, 1.2, 20), Vector3.new(0, 0.1, 42), Color3.fromRGB(92, 58, 34), Enum.Material.Mud)
	createPart(arenaFolder, "FlowerBed", Vector3.new(42, 1.1, 24), Vector3.new(36, 0.05, -30), Color3.fromRGB(70, 115, 55), Enum.Material.Grass)
	createPart(arenaFolder, "MulchMaze", Vector3.new(38, 1.1, 24), Vector3.new(36, 0.05, 24), Color3.fromRGB(90, 48, 30), Enum.Material.WoodPlanks)

	local coverFolder = createFolder(arenaFolder, "Cover")
	createPart(coverFolder, "LeafCoverA", Vector3.new(18, 2, 10), Vector3.new(-20, 2, 10), Color3.fromRGB(55, 125, 50), Enum.Material.Grass)
	createPart(coverFolder, "LeafCoverB", Vector3.new(16, 2, 9), Vector3.new(18, 2, 4), Color3.fromRGB(65, 145, 55), Enum.Material.Grass)
	createPart(coverFolder, "GardenGlove", Vector3.new(16, 4, 10), Vector3.new(-44, 2.5, 22), Color3.fromRGB(45, 95, 150), Enum.Material.Fabric)
	createPart(coverFolder, "ToyBlock", Vector3.new(10, 10, 10), Vector3.new(0, 5, -36), Color3.fromRGB(200, 70, 60), Enum.Material.Plastic)

	local grassFolder = createFolder(arenaFolder, "GrassBorder")
	for i = 1, 18 do
		local x = -68 + (i * 8)
		createPart(grassFolder, "GrassBladeNorth" .. i, Vector3.new(2, 18 + math.random(0, 10), 2), Vector3.new(x, 9, -70), Color3.fromRGB(45, 140, 50), Enum.Material.Grass)
		createPart(grassFolder, "GrassBladeSouth" .. i, Vector3.new(2, 18 + math.random(0, 10), 2), Vector3.new(x, 9, 70), Color3.fromRGB(45, 140, 50), Enum.Material.Grass)
	end

	local crumbsFolder = createFolder(arenaFolder, "Crumbs")
	crumbsFolder:ClearAllChildren()

	addCrumbZone("Patio", Vector3.new(-36, 4, -28), 16)
	addCrumbZone("FlowerBed", Vector3.new(36, 4, -30), 14)
	addCrumbZone("NestEdge", Vector3.new(0, 4, 22), 18)
end

function ArenaService.GetCrumbsFolder(): Folder
	if not arenaFolder then
		ArenaService.BuildArena()
	end

	return createFolder(arenaFolder, "Crumbs")
end

function ArenaService.GetRandomCrumbPosition(): Vector3
	if #crumbZones == 0 then
		ArenaService.BuildArena()
	end

	local zone = crumbZones[math.random(1, #crumbZones)]
	local angle = math.random() * math.pi * 2
	local distance = math.random() * zone.radius
	return zone.center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
end

return ArenaService
