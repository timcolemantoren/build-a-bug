--!nonstrict

local Workspace = game:GetService("Workspace")

local EnvironmentPropPolishService = {}

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

local function makeMushroom(parent: Instance, index: number, basePosition: Vector3, stemHeight: number, capSize: Vector3, capColor: Color3)
	local model = Instance.new("Model")
	model.Name = "Mushroom" .. index
	model.Parent = parent

	local stemDiameter = math.clamp(math.min(capSize.X, capSize.Z) * 0.22, 1.6, 2.8)
	local stem = makePart(
		model,
		"MushroomStem" .. index,
		Vector3.new(stemHeight, stemDiameter, stemDiameter),
		CFrame.new(basePosition.X, 0.55 + stemHeight / 2, basePosition.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(221, 206, 170),
		Enum.Material.Sand
	)
	stem.Shape = Enum.PartType.Cylinder

	local capWidth = math.max(6, capSize.X)
	local capDepth = math.max(6, capSize.Z)
	local capHeight = math.clamp(math.max(2.6, capSize.Y * 1.45), 2.6, 4.2)
	local capY = 0.55 + stemHeight + capHeight * 0.28
	local cap = makePart(
		model,
		"MushroomCap" .. index,
		Vector3.new(capWidth, capHeight, capDepth),
		CFrame.new(basePosition.X, capY, basePosition.Z),
		capColor,
		Enum.Material.SmoothPlastic
	)
	cap.Shape = Enum.PartType.Ball

	-- A pale underside gives the cap depth from bug-eye level instead of reading
	-- as a single floating red/orange blob.
	local underside = makePart(
		model,
		"MushroomGills" .. index,
		Vector3.new(capWidth * 0.74, 0.42, capDepth * 0.74),
		CFrame.new(basePosition.X, capY - capHeight * 0.31, basePosition.Z),
		Color3.fromRGB(235, 220, 187),
		Enum.Material.Sand
	)
	underside.Shape = Enum.PartType.Ball
	underside.CanCollide = false
	underside.CanTouch = false
	underside.CanQuery = false

	-- Small cream cap spots make the mushrooms read as intentional backyard props
	-- without turning them into noisy decoration. They are visual-only.
	local spotLayouts = {
		{ -0.22, -0.14, 0.86 },
		{ 0.24, -0.05, 0.72 },
		{ -0.02, 0.22, 0.62 },
		{ 0.31, 0.24, 0.48 },
	}
	local spotCount = 2 + (index % 3)
	for spotIndex = 1, spotCount do
		local layout = spotLayouts[spotIndex]
		local spotDiameter = math.max(0.75, math.min(capWidth, capDepth) * 0.13 * layout[3])
		local spot = makePart(
			model,
			"MushroomSpot" .. index .. "_" .. spotIndex,
			Vector3.new(spotDiameter, 0.30, spotDiameter),
			CFrame.new(
				basePosition.X + capWidth * layout[1],
				capY + capHeight * 0.45,
				basePosition.Z + capDepth * layout[2]
			),
			Color3.fromRGB(246, 232, 196),
			Enum.Material.SmoothPlastic
		)
		spot.Shape = Enum.PartType.Ball
		spot.CanCollide = false
		spot.CanTouch = false
		spot.CanQuery = false
	end
end

local function polishMushrooms(arena: Instance)
	local clutter = arena:FindFirstChild("Clutter")
	if not clutter then
		return
	end

	for index = 1, 24 do
		local oldStem = clutter:FindFirstChild("MushroomStem" .. index)
		local oldCap = clutter:FindFirstChild("MushroomCap" .. index)
		if oldStem and oldStem:IsA("BasePart") and oldCap and oldCap:IsA("BasePart") then
			local basePosition = Vector3.new(oldStem.Position.X, 0, oldStem.Position.Z)
			local stemHeight = math.max(3.5, oldStem.Size.Y)
			local capSize = oldCap.Size
			local capColor = oldCap.Color
			oldStem:Destroy()
			oldCap:Destroy()
			makeMushroom(clutter, index, basePosition, stemHeight, capSize, capColor)
		end
	end
end

local function makeBarkTunnel(arena: Instance)
	local cover = arena:FindFirstChild("Cover")
	local oldTunnel = cover and cover:FindFirstChild("BarkTunnel")
	if not cover or not oldTunnel or not oldTunnel:IsA("BasePart") then
		return
	end

	local center = oldTunnel.Position
	local length = oldTunnel.Size.X
	local oldColor = oldTunnel.Color
	oldTunnel:Destroy()

	local model = Instance.new("Model")
	model.Name = "BarkTunnel"
	model.Parent = cover

	local bark = oldColor:Lerp(Color3.fromRGB(82, 47, 28), 0.30)
	local darkBark = bark:Lerp(Color3.fromRGB(47, 29, 20), 0.42)
	local lightBark = bark:Lerp(Color3.fromRGB(139, 92, 55), 0.30)

	-- Two chunky sides plus a three-piece arch create a real opening while keeping
	-- the whole landmark sturdy enough to climb over and run through.
	local leftWall = makePart(
		model,
		"BarkTunnelLeftWall",
		Vector3.new(length, 9.5, 4.2),
		CFrame.new(center + Vector3.new(0, -5.0, -7.1)),
		bark,
		Enum.Material.Wood
	)
	leftWall.Orientation = Vector3.new(0, 0, -3)

	local rightWall = makePart(
		model,
		"BarkTunnelRightWall",
		Vector3.new(length, 10.5, 4.4),
		CFrame.new(center + Vector3.new(0, -4.5, 7.0)),
		lightBark,
		Enum.Material.Wood
	)
	rightWall.Orientation = Vector3.new(0, 0, 4)

	local leftRoof = makePart(
		model,
		"BarkTunnelLeftRoof",
		Vector3.new(length, 4.0, 8.4),
		CFrame.new(center + Vector3.new(0, 2.0, -4.5)),
		bark,
		Enum.Material.Wood
	)
	leftRoof.Orientation = Vector3.new(-27, 0, 0)

	local rightRoof = makePart(
		model,
		"BarkTunnelRightRoof",
		Vector3.new(length, 4.0, 8.4),
		CFrame.new(center + Vector3.new(0, 2.2, 4.5)),
		lightBark,
		Enum.Material.Wood
	)
	rightRoof.Orientation = Vector3.new(27, 0, 0)

	makePart(
		model,
		"BarkTunnelCrown",
		Vector3.new(length, 3.2, 6.8),
		CFrame.new(center + Vector3.new(0, 5.2, 0)),
		bark,
		Enum.Material.Wood
	)

	-- Long raised bark ridges break up the old giant-box silhouette and give the
	-- tunnel visible grain at bug scale.
	for ridgeIndex, zOffset in ipairs({ -5.1, -2.5, 0, 2.6, 5.0 }) do
		local yOffset = 6.8 - math.abs(zOffset) * 0.28
		local ridge = makePart(
			model,
			"BarkTunnelRidge" .. ridgeIndex,
			Vector3.new(length * (0.88 + (ridgeIndex % 2) * 0.06), 0.72, 0.9),
			CFrame.new(center + Vector3.new((ridgeIndex % 2 == 0) and 1.2 or -1.1, yOffset, zOffset)),
			darkBark,
			Enum.Material.WoodPlanks
		)
		ridge.CanCollide = false
		ridge.CanTouch = false
		ridge.CanQuery = false
	end

	-- A couple of knots add asymmetry so the landmark does not read as five clean
	-- construction blocks from a distance.
	for knotIndex, data in ipairs({
		{ -14, -8.6, -5.0, 3.2 },
		{ 12, 8.3, -4.2, 2.5 },
	}) do
		local knot = makePart(
			model,
			"BarkTunnelKnot" .. knotIndex,
			Vector3.new(data[4], data[4] * 0.62, data[4]),
			CFrame.new(center + Vector3.new(data[1], data[3], data[2])),
			darkBark,
			Enum.Material.Wood
		)
		knot.Shape = Enum.PartType.Ball
		knot.CanCollide = false
		knot.CanTouch = false
		knot.CanQuery = false
	end
end

function EnvironmentPropPolishService.Init()
	local arena = Workspace:FindFirstChild("BuildABugArena") or Workspace:WaitForChild("BuildABugArena", 10)
	if not arena then
		warn("[Build a Bug] EnvironmentPropPolishService could not find arena")
		return
	end

	polishMushrooms(arena)
	makeBarkTunnel(arena)
end

return EnvironmentPropPolishService
