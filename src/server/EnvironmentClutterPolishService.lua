--!nonstrict

local Workspace = game:GetService("Workspace")

local EnvironmentClutterPolishService = {}

local LEAF_COLORS = {
	Color3.fromRGB(91, 126, 52),
	Color3.fromRGB(112, 142, 55),
	Color3.fromRGB(132, 118, 47),
	Color3.fromRGB(147, 101, 43),
	Color3.fromRGB(122, 78, 39),
	Color3.fromRGB(81, 111, 49),
}

local COVER_LEAF_COLORS = {
	Color3.fromRGB(66, 126, 55),
	Color3.fromRGB(78, 143, 60),
	Color3.fromRGB(89, 132, 53),
}

local function makePart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = true
	part.CanQuery = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function makeEllipsoid(parent: Instance, name: string, dimensions: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local holder = makePart(parent, name, Vector3.new(1, 1, 1), cframe, color, material)
	holder.CanCollide = false
	holder.CanTouch = false
	holder.CanQuery = false

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = dimensions
	mesh.Parent = holder
	return holder
end

local function clearDebugOverlay()
	local debugFolder = Workspace:FindFirstChild("BuildABug_Debug")
	if debugFolder then
		debugFolder:Destroy()
	end
end

local function polishLeaves(arena: Instance)
	local clutter = arena:FindFirstChild("Clutter")
	if not clutter then
		return
	end

	for _, item in ipairs(clutter:GetChildren()) do
		if item:IsA("BasePart") and string.find(item.Name, "FallenLeaf") == 1 then
			local seed = tonumber(string.match(item.Name, "%d+")) or 1
			local length = math.clamp(item.Size.X * 0.72, 6.5, 14)
			local width = math.clamp(item.Size.Z * 0.82, 3.4, 7.2)
			local thickness = 0.24 + (seed % 3) * 0.04
			local yaw = math.rad((seed * 37) % 180)
			local tiltX = math.rad(((seed * 7) % 5) - 2)
			local tiltZ = math.rad(((seed * 11) % 5) - 2)

			-- The arena generator uses simple rectangles for leaf litter. Flattened
			-- ellipsoids keep the same low-cost one-Part footprint but read much more
			-- like organic leaves from bug height.
			item.Shape = Enum.PartType.Ball
			item.Size = Vector3.new(length, thickness, width)
			item.CFrame = CFrame.new(item.Position.X, 0.72 + thickness / 2, item.Position.Z)
				* CFrame.Angles(tiltX, yaw, tiltZ)
			item.Color = LEAF_COLORS[((seed - 1) % #LEAF_COLORS) + 1]
			item.Material = Enum.Material.Fabric
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = false
			item.Reflectance = 0
		end
	end
end

local function rebuildLeafCover(cover: Instance, name: string, index: number)
	local old = cover:FindFirstChild(name)
	if not old or not old:IsA("BasePart") then
		return
	end

	local center = old.Position
	local oldSize = old.Size
	old:Destroy()

	local model = Instance.new("Model")
	model.Name = name
	model.Parent = cover

	local length = oldSize.X * 0.96
	local width = oldSize.Z * 0.92
	local thickness = 1.25 + index * 0.12
	local yaw = math.rad(({ -14, 19, -27 })[index] or 0)
	local roll = math.rad(({ 8, -6, 10 })[index] or 0)
	local lift = 1.7 + index * 0.22
	local frame = CFrame.new(center.X, lift, center.Z) * CFrame.Angles(roll, yaw, math.rad((index - 2) * 3))
	local color = COVER_LEAF_COLORS[index] or COVER_LEAF_COLORS[1]

	-- Main leaf visual. Slightly domed and tilted so it reads as a fallen leaf
	-- shelter rather than a flat green platform.
	makeEllipsoid(
		model,
		"LeafBladeVisual",
		Vector3.new(length, thickness, width),
		frame,
		color,
		Enum.Material.Fabric
	)

	-- A smaller overlapping tip breaks the perfect oval silhouette.
	makeEllipsoid(
		model,
		"LeafTipVisual",
		Vector3.new(length * 0.34, thickness * 0.72, width * 0.60),
		frame * CFrame.new(length * 0.42, 0.05, 0) * CFrame.Angles(0, 0, math.rad(index % 2 == 0 and -5 or 5)),
		color:Lerp(Color3.fromRGB(53, 104, 46), 0.10),
		Enum.Material.Fabric
	)

	local collision = makePart(
		model,
		"LeafCoverCollision",
		Vector3.new(length * 0.82, 1.15, width * 0.74),
		frame,
		color,
		Enum.Material.SmoothPlastic
	)
	collision.Transparency = 1
	collision.CastShadow = false

	local vein = makePart(
		model,
		"LeafVein",
		Vector3.new(length * 0.78, 0.20, 0.38),
		frame * CFrame.new(0, thickness * 0.48, 0),
		color:Lerp(Color3.fromRGB(42, 82, 36), 0.40),
		Enum.Material.Fabric
	)
	vein.CanCollide = false
	vein.CanTouch = false
	vein.CanQuery = false
end

local function rebuildLeafCovers(arena: Instance)
	local cover = arena:FindFirstChild("Cover")
	if not cover then
		return
	end

	for index, name in ipairs({ "LeafCoverA", "LeafCoverB", "LeafCoverC" }) do
		rebuildLeafCover(cover, name, index)
	end
end

local function rebuildToyBlock(arena: Instance)
	local cover = arena:FindFirstChild("Cover")
	if not cover then
		return
	end

	local old = cover:FindFirstChild("ToyBlock")
	if not old or not old:IsA("BasePart") then
		return
	end

	local center = old.Position
	old:Destroy()

	local model = Instance.new("Model")
	model.Name = "ToyBlock"
	model.Parent = cover

	local bodyColor = Color3.fromRGB(205, 68, 55)
	local bodySize = Vector3.new(18, 8.5, 14)
	local bodyFrame = CFrame.new(center.X, 0.55 + bodySize.Y / 2, center.Z) * CFrame.Angles(0, math.rad(-7), 0)
	local body = makePart(model, "ToyBrickBody", bodySize, bodyFrame, bodyColor, Enum.Material.SmoothPlastic)
	body.Reflectance = 0.02

	-- Six chunky studs make the old red cube read as an intentional toy brick.
	local studXs = { -5.3, 0, 5.3 }
	local studZs = { -3.6, 3.6 }
	local studIndex = 0
	for _, xOffset in ipairs(studXs) do
		for _, zOffset in ipairs(studZs) do
			studIndex += 1
			local stud = makePart(
				model,
				"ToyBrickStud" .. studIndex,
				Vector3.new(1.25, 3.2, 3.2),
				bodyFrame * CFrame.new(xOffset, bodySize.Y / 2 + 0.62, zOffset) * CFrame.Angles(0, 0, math.rad(90)),
				bodyColor:Lerp(Color3.fromRGB(245, 95, 74), 0.12),
				Enum.Material.SmoothPlastic
			)
			stud.Shape = Enum.PartType.Cylinder
			stud.CanCollide = false
			stud.CanTouch = false
			stud.CanQuery = false
		end
	end
end

function EnvironmentClutterPolishService.Init()
	clearDebugOverlay()

	local arena = Workspace:FindFirstChild("BuildABugArena") or Workspace:WaitForChild("BuildABugArena", 10)
	if not arena then
		warn("[Build a Bug] EnvironmentClutterPolishService could not find arena")
		return
	end

	polishLeaves(arena)
	rebuildLeafCovers(arena)
	rebuildToyBlock(arena)
end

return EnvironmentClutterPolishService
