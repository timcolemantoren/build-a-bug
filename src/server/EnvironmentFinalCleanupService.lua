--!nonstrict

local Workspace = game:GetService("Workspace")

local EnvironmentFinalCleanupService = {}

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

local function findExistingMushroomPosition(clutter: Instance, index: number): Vector3?
	local model = clutter:FindFirstChild("Mushroom" .. index)
	if model and model:IsA("Model") then
		return model:GetPivot().Position
	end

	local stem = clutter:FindFirstChild("MushroomStem" .. index)
	if stem and stem:IsA("BasePart") then
		return Vector3.new(stem.Position.X, 0.55, stem.Position.Z)
	end
	return nil
end

local function removeExistingMushroom(clutter: Instance, index: number)
	local model = clutter:FindFirstChild("Mushroom" .. index)
	if model then
		model:Destroy()
	end
	local stem = clutter:FindFirstChild("MushroomStem" .. index)
	if stem then
		stem:Destroy()
	end
	local cap = clutter:FindFirstChild("MushroomCap" .. index)
	if cap then
		cap:Destroy()
	end
end

local MUSHROOM_COLORS = {
	Color3.fromRGB(137, 97, 65),
	Color3.fromRGB(158, 112, 76),
	Color3.fromRGB(116, 83, 59),
	Color3.fromRGB(149, 91, 70),
	Color3.fromRGB(174, 132, 91),
}

local function buildMushroom(clutter: Instance, index: number, groundPosition: Vector3)
	local model = Instance.new("Model")
	model.Name = "Mushroom" .. index
	model.Parent = clutter

	local sizeStep = (index - 1) % 5
	local stemHeight = 3.0 + sizeStep * 0.28
	local stemDiameter = 1.65 + ((index * 3) % 4) * 0.16
	local capWidth = 6.4 + sizeStep * 0.48
	local capDepth = capWidth * (0.88 + (index % 3) * 0.025)
	local capHeight = 1.75 + (index % 3) * 0.16
	local stemColor = Color3.fromRGB(201, 190, 165)
	local capColor = MUSHROOM_COLORS[((index - 1) % #MUSHROOM_COLORS) + 1]
	local x = groundPosition.X
	local z = groundPosition.Z
	local baseY = 0.55

	local lean = ((index % 5) - 2) * 1.5
	local stem = makePart(
		model,
		"MushroomStem" .. index,
		Vector3.new(stemHeight, stemDiameter, stemDiameter),
		CFrame.new(x, baseY + stemHeight / 2, z) * CFrame.Angles(0, 0, math.rad(90 + lean)),
		stemColor,
		Enum.Material.Sand
	)
	stem.Shape = Enum.PartType.Cylinder

	local capX = x + (((index * 13) % 5) - 2) * 0.08
	local capZ = z + (((index * 17) % 5) - 2) * 0.07
	local capY = baseY + stemHeight + capHeight * 0.28
	local tiltX = math.rad((((index * 3) % 5) - 2) * 1.3)
	local tiltZ = math.rad((((index * 5) % 5) - 2) * 1.1)
	local capYaw = math.rad((index * 29) % 180)
	local capFrame = CFrame.new(capX, capY, capZ) * CFrame.Angles(tiltX, capYaw, tiltZ)

	makeEllipsoid(
		model,
		"MushroomCapVisual" .. index,
		Vector3.new(capWidth, capHeight, capDepth),
		capFrame,
		capColor,
		Enum.Material.Fabric
	)

	makeEllipsoid(
		model,
		"MushroomUnderside" .. index,
		Vector3.new(capWidth * 0.72, 0.36, capDepth * 0.72),
		CFrame.new(capX, capY - capHeight * 0.35, capZ) * CFrame.Angles(tiltX, capYaw, tiltZ),
		Color3.fromRGB(214, 201, 174),
		Enum.Material.Sand
	)

	-- Simple invisible cap collision keeps the mushroom fun to jump on while the
	-- SpecialMesh handles the organic visual silhouette.
	local collision = makePart(
		model,
		"MushroomCap" .. index,
		Vector3.new(0.52, capWidth * 0.82, capDepth * 0.82),
		CFrame.new(capX, capY - 0.08, capZ) * CFrame.Angles(0, capYaw, math.rad(90)),
		capColor,
		Enum.Material.SmoothPlastic
	)
	collision.Shape = Enum.PartType.Cylinder
	collision.Transparency = 1
	collision.CastShadow = false
end

local function rebuildMushrooms(arena: Instance)
	local clutter = arena:FindFirstChild("Clutter")
	if not clutter then
		return
	end

	for index = 1, 24 do
		local position = findExistingMushroomPosition(clutter, index)
		if position then
			removeExistingMushroom(clutter, index)
			buildMushroom(clutter, index, Vector3.new(position.X, 0.55, position.Z))
		end
	end
end

local function getPropCenter(instance: Instance): Vector3?
	if instance:IsA("BasePart") then
		return instance.Position
	elseif instance:IsA("Model") then
		return instance:GetPivot().Position
	end
	return nil
end

local function buildAcorn(cover: Instance, name: string, index: number, center: Vector3)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = cover

	local bodyLength = index == 1 and 7.0 or 6.3
	local bodyHeight = index == 1 and 4.7 or 4.3
	local bodyDepth = index == 1 and 4.8 or 4.4
	local yaw = math.rad(index == 1 and -28 or 22)
	local roll = math.rad(index == 1 and 12 or -10)
	local frame = CFrame.new(center.X, 0.55 + bodyHeight / 2, center.Z) * CFrame.Angles(roll, yaw, math.rad(7))
	local nutColor = index == 1 and Color3.fromRGB(135, 79, 42) or Color3.fromRGB(116, 69, 38)

	makeEllipsoid(model, "AcornBodyVisual", Vector3.new(bodyLength, bodyHeight, bodyDepth), frame, nutColor, Enum.Material.SmoothPlastic)
	makeEllipsoid(
		model,
		"AcornCapVisual",
		Vector3.new(bodyLength * 0.58, bodyHeight * 0.36, bodyDepth * 0.91),
		frame * CFrame.new(bodyLength * 0.23, bodyHeight * 0.20, 0),
		Color3.fromRGB(76, 50, 32),
		Enum.Material.Fabric
	)

	local collision = makePart(model, "AcornCollision", Vector3.new(bodyLength * 0.78, bodyHeight * 0.78, bodyDepth * 0.78), frame, nutColor, Enum.Material.SmoothPlastic)
	collision.Transparency = 1
	collision.CastShadow = false

	local stem = makePart(
		model,
		"AcornStem",
		Vector3.new(1.8, 0.55, 0.55),
		frame * CFrame.new(bodyLength * 0.49, bodyHeight * 0.14, 0) * CFrame.Angles(0, 0, math.rad(20)),
		Color3.fromRGB(70, 46, 29),
		Enum.Material.Wood
	)
	stem.Shape = Enum.PartType.Cylinder
	stem.CanCollide = false
	stem.CanTouch = false
	stem.CanQuery = false
end

local function rebuildAcorns(arena: Instance)
	local cover = arena:FindFirstChild("Cover")
	if not cover then
		return
	end

	for index, name in ipairs({ "AcornCapA", "AcornCapB" }) do
		local old = cover:FindFirstChild(name)
		local center = old and getPropCenter(old)
		if old and center then
			old:Destroy()
			buildAcorn(cover, name, index, center)
		end
	end
end

local function buildGardenGlove(cover: Instance, center: Vector3)
	local model = Instance.new("Model")
	model.Name = "GardenGlove"
	model.Parent = cover

	local gloveColor = Color3.fromRGB(54, 111, 170)
	local cuffColor = Color3.fromRGB(42, 86, 132)
	local yaw = math.rad(-18)
	local palmCenter = Vector3.new(center.X, 1.75, center.Z)
	local palmFrame = CFrame.new(palmCenter) * CFrame.Angles(0, yaw, math.rad(-4))

	makeEllipsoid(model, "GlovePalmVisual", Vector3.new(11.5, 3.0, 8.6), palmFrame, gloveColor, Enum.Material.Fabric)

	local collision = makePart(model, "GlovePalmCollision", Vector3.new(10.5, 2.0, 7.7), palmFrame, gloveColor, Enum.Material.SmoothPlastic)
	collision.Transparency = 1
	collision.CastShadow = false

	local fingerOffsets = { -2.9, -1.0, 1.0, 2.9 }
	local fingerLengths = { 5.8, 7.0, 6.7, 5.4 }
	for fingerIndex, zOffset in ipairs(fingerOffsets) do
		local length = fingerLengths[fingerIndex]
		local localFrame = palmFrame * CFrame.new(5.1 + length / 2, 0.10, zOffset)
		local finger = makePart(
			model,
			"GloveFinger" .. fingerIndex,
			Vector3.new(length, 1.65, 1.65),
			localFrame,
			gloveColor,
			Enum.Material.Fabric
		)
		finger.Shape = Enum.PartType.Cylinder
	end

	local thumbFrame = palmFrame * CFrame.new(1.8, -0.05, -5.3) * CFrame.Angles(0, math.rad(-35), 0)
	local thumb = makePart(model, "GloveThumb", Vector3.new(5.2, 1.8, 1.8), thumbFrame, gloveColor, Enum.Material.Fabric)
	thumb.Shape = Enum.PartType.Cylinder

	local cuff = makePart(
		model,
		"GloveCuff",
		Vector3.new(5.0, 2.4, 8.8),
		palmFrame * CFrame.new(-7.4, -0.15, 0),
		cuffColor,
		Enum.Material.Fabric
	)
	cuff.CanCollide = true
end

local function rebuildGardenGlove(arena: Instance)
	local cover = arena:FindFirstChild("Cover")
	if not cover then
		return
	end
	local old = cover:FindFirstChild("GardenGlove")
	local center = old and getPropCenter(old)
	if old and center then
		old:Destroy()
		buildGardenGlove(cover, center)
	end
end

function EnvironmentFinalCleanupService.Init()
	local arena = Workspace:FindFirstChild("BuildABugArena") or Workspace:WaitForChild("BuildABugArena", 10)
	if not arena then
		warn("[Build a Bug] EnvironmentFinalCleanupService could not find arena")
		return
	end

	rebuildMushrooms(arena)
	rebuildAcorns(arena)
	rebuildGardenGlove(arena)
end

return EnvironmentFinalCleanupService
