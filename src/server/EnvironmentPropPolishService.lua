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

local MUSHROOM_CAP_COLORS = {
	Color3.fromRGB(132, 93, 62),
	Color3.fromRGB(157, 116, 76),
	Color3.fromRGB(116, 82, 56),
	Color3.fromRGB(151, 86, 67),
	Color3.fromRGB(173, 133, 91),
}

local function makeMushroom(parent: Instance, index: number, basePosition: Vector3, originalStemHeight: number, originalCapSize: Vector3)
	local existing = parent:FindFirstChild("Mushroom" .. index)
	if existing then
		existing:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "Mushroom" .. index
	model.Parent = parent

	-- Keep these recognizably backyard-sized. The first polish pass made them tall,
	-- glossy and almost alien. These are shorter, flatter and much more matte.
	local stemHeight = math.clamp(originalStemHeight * 0.58, 2.2, 4.0)
	local capWidth = math.clamp(originalCapSize.X * 0.74, 4.6, 7.2)
	local capDepth = math.clamp(originalCapSize.Z * 0.74, 4.6, 7.2)
	local capHeight = 1.15 + (index % 3) * 0.16
	local stemDiameter = math.clamp(math.min(capWidth, capDepth) * 0.19, 1.05, 1.65)
	local capColor = MUSHROOM_CAP_COLORS[((index - 1) % #MUSHROOM_CAP_COLORS) + 1]
	local stemColor = Color3.fromRGB(196 + (index % 3) * 5, 182 + (index % 2) * 5, 151)

	local leanDegrees = ((index % 5) - 2) * 1.8
	local stem = makePart(
		model,
		"MushroomStem" .. index,
		Vector3.new(stemHeight, stemDiameter, stemDiameter),
		CFrame.new(basePosition.X, 0.55 + stemHeight / 2, basePosition.Z)
			* CFrame.Angles(0, 0, math.rad(90 + leanDegrees)),
		stemColor,
		Enum.Material.Sand
	)
	stem.Shape = Enum.PartType.Cylinder

	local capY = 0.55 + stemHeight + capHeight * 0.18
	local capTiltX = math.rad(((index * 3) % 7) - 3)
	local capTiltZ = math.rad(((index * 5) % 7) - 3)
	local cap = makePart(
		model,
		"MushroomCap" .. index,
		Vector3.new(capWidth, capHeight, capDepth),
		CFrame.new(basePosition.X, capY, basePosition.Z) * CFrame.Angles(capTiltX, math.rad((index * 31) % 180), capTiltZ),
		capColor,
		Enum.Material.Fabric
	)
	cap.Shape = Enum.PartType.Ball
	cap.Reflectance = 0

	-- A shallow underside keeps the cap dimensional from bug height without adding
	-- the bright UFO-like ring the previous version had.
	local underside = makePart(
		model,
		"MushroomUnderside" .. index,
		Vector3.new(capWidth * 0.72, 0.34, capDepth * 0.72),
		CFrame.new(basePosition.X, capY - capHeight * 0.33, basePosition.Z),
		Color3.fromRGB(211, 195, 160),
		Enum.Material.Sand
	)
	underside.Shape = Enum.PartType.Ball
	underside.CanCollide = false
	underside.CanTouch = false
	underside.CanQuery = false

	-- A small darker center mark on some caps adds natural variation without the
	-- bright cream polka dots that made them read as fantasy mushrooms.
	if index % 4 == 0 then
		local centerMark = makePart(
			model,
			"MushroomCapMark" .. index,
			Vector3.new(capWidth * 0.24, 0.18, capDepth * 0.24),
			CFrame.new(basePosition.X + capWidth * 0.08, capY + capHeight * 0.43, basePosition.Z - capDepth * 0.06),
			capColor:Lerp(Color3.fromRGB(70, 52, 40), 0.25),
			Enum.Material.Fabric
		)
		centerMark.Shape = Enum.PartType.Ball
		centerMark.CanCollide = false
		centerMark.CanTouch = false
		centerMark.CanQuery = false
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
			oldStem:Destroy()
			oldCap:Destroy()
			makeMushroom(clutter, index, basePosition, stemHeight, capSize)
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

local function configureHiddenBarrier(part: BasePart, size: Vector3, position: Vector3)
	part.Size = size
	part.Position = position
	part.Transparency = 1
	part.CanCollide = true
	part.CanTouch = true
	part.CanQuery = true
	part.CastShadow = false
end

local function makeFenceBoard(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, yawDegrees: number)
	local board = makePart(
		parent,
		name,
		size,
		CFrame.new(position) * CFrame.Angles(0, math.rad(yawDegrees), 0),
		color,
		Enum.Material.WoodPlanks
	)
	board.CanCollide = false
	board.CanTouch = false
	board.CanQuery = false
	return board
end

local function buildFenceSide(parent: Instance, side: string)
	local span = 420
	local boardCount = 28
	local step = span / boardCount
	local baseColor = Color3.fromRGB(118, 82, 51)

	for index = 1, boardCount do
		local along = -span / 2 + step * (index - 0.5)
		local height = 18.5 + ((index * 7) % 6) * 0.75
		local width = step - 0.55
		local shade = ((index * 11) % 17) - 8
		local color = Color3.fromRGB(
			math.clamp(math.floor(baseColor.R * 255) + shade, 80, 150),
			math.clamp(math.floor(baseColor.G * 255) + math.floor(shade * 0.7), 55, 115),
			math.clamp(math.floor(baseColor.B * 255) + math.floor(shade * 0.5), 35, 85)
		)
		local yawJitter = ((index % 5) - 2) * 0.7

		if side == "North" then
			makeFenceBoard(parent, side .. "Board" .. index, Vector3.new(width, height, 2.2), Vector3.new(along, height / 2, -209.1), color, yawJitter)
		elseif side == "South" then
			makeFenceBoard(parent, side .. "Board" .. index, Vector3.new(width, height, 2.2), Vector3.new(along, height / 2, 209.1), color, -yawJitter)
		elseif side == "West" then
			makeFenceBoard(parent, side .. "Board" .. index, Vector3.new(2.2, height, width), Vector3.new(-209.1, height / 2, along), color, yawJitter)
		elseif side == "East" then
			makeFenceBoard(parent, side .. "Board" .. index, Vector3.new(2.2, height, width), Vector3.new(209.1, height / 2, along), color, -yawJitter)
		end
	end
end

local function polishBoundary(arena: Instance)
	local boundary = arena:FindFirstChild("Boundary")
	if not boundary then
		return
	end

	-- The original visible walls were centered several studs outside the dirt edge,
	-- leaving a narrow seam that tiny bugs could fall through. Reuse those parts as
	-- invisible blockers, move them inward and overlap them below the floor.
	local north = boundary:FindFirstChild("NorthFence")
	local south = boundary:FindFirstChild("SouthFence")
	local west = boundary:FindFirstChild("WestFence")
	local east = boundary:FindFirstChild("EastFence")

	if north and north:IsA("BasePart") then
		configureHiddenBarrier(north, Vector3.new(426, 28, 5), Vector3.new(0, 12, -210.5))
	end
	if south and south:IsA("BasePart") then
		configureHiddenBarrier(south, Vector3.new(426, 28, 5), Vector3.new(0, 12, 210.5))
	end
	if west and west:IsA("BasePart") then
		configureHiddenBarrier(west, Vector3.new(5, 28, 426), Vector3.new(-210.5, 12, 0))
	end
	if east and east:IsA("BasePart") then
		configureHiddenBarrier(east, Vector3.new(5, 28, 426), Vector3.new(210.5, 12, 0))
	end

	local oldVisuals = boundary:FindFirstChild("FenceVisuals")
	if oldVisuals then
		oldVisuals:Destroy()
	end

	local visuals = Instance.new("Folder")
	visuals.Name = "FenceVisuals"
	visuals.Parent = boundary

	-- Individual boards break up the old giant brown slab while the invisible shell
	-- behind them keeps collision simple and fully sealed.
	buildFenceSide(visuals, "North")
	buildFenceSide(visuals, "South")
	buildFenceSide(visuals, "West")
	buildFenceSide(visuals, "East")
end

function EnvironmentPropPolishService.Init()
	local arena = Workspace:FindFirstChild("BuildABugArena") or Workspace:WaitForChild("BuildABugArena", 10)
	if not arena then
		warn("[Build a Bug] EnvironmentPropPolishService could not find arena")
		return
	end

	polishMushrooms(arena)
	makeBarkTunnel(arena)
	polishBoundary(arena)
end

return EnvironmentPropPolishService
