--!nonstrict

local Workspace = game:GetService("Workspace")

local EnvironmentClutterPolishService = {}

local function makePart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local LEAF_COLORS = {
	Color3.fromRGB(91, 126, 52),
	Color3.fromRGB(112, 142, 55),
	Color3.fromRGB(132, 118, 47),
	Color3.fromRGB(147, 101, 43),
	Color3.fromRGB(122, 78, 39),
	Color3.fromRGB(81, 111, 49),
}

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

local function rebuildGardenGlove(arena: Instance)
	local cover = arena:FindFirstChild("Cover")
	if not cover then
		return
	end

	local old = cover:FindFirstChild("GardenGlove")
	if not old then
		return
	end

	local center
	local size
	if old:IsA("BasePart") then
		center = old.Position
		size = old.Size
	elseif old:IsA("Model") then
		local cf, bounds = old:GetBoundingBox()
		center = cf.Position
		size = bounds
	else
		return
	end
	old:Destroy()

	local model = Instance.new("Model")
	model.Name = "GardenGlove"
	model.Parent = cover

	local gloveBlue = Color3.fromRGB(51, 103, 153)
	local gloveDark = Color3.fromRGB(38, 76, 116)
	local cuffBlue = Color3.fromRGB(43, 87, 132)
	local rotation = CFrame.Angles(math.rad(-7), math.rad(-18), math.rad(4))

	-- One invisible collision volume keeps traversal predictable while the visible
	-- glove is built from rounded pieces instead of the old giant blue cuboid.
	local collision = makePart(
		model,
		"GlovePalmCollision",
		Vector3.new(math.max(16, size.X * 0.62), 5.2, math.max(12, size.Z * 0.72)),
		CFrame.new(center.X, 3.1, center.Z) * rotation,
		gloveBlue,
		Enum.Material.SmoothPlastic
	)
	collision.Transparency = 1
	collision.CanCollide = true
	collision.CanTouch = true
	collision.CanQuery = true

	local palm = makePart(
		model,
		"GlovePalm",
		Vector3.new(15.5, 4.7, 12.5),
		CFrame.new(center.X - 1.2, 3.35, center.Z) * rotation,
		gloveBlue,
		Enum.Material.Fabric
	)
	palm.Shape = Enum.PartType.Ball

	local cuff = makePart(
		model,
		"GloveCuff",
		Vector3.new(7.5, 3.8, 11.5),
		CFrame.new(center.X - 10.2, 2.75, center.Z + 0.4) * rotation,
		cuffBlue,
		Enum.Material.Fabric
	)
	cuff.Shape = Enum.PartType.Ball

	local fingerOffsets = {
		{ 6.4, -4.4, 6.8, 2.3, -10 },
		{ 8.0, -1.6, 7.9, 2.35, -4 },
		{ 8.5, 1.2, 8.3, 2.45, 2 },
		{ 7.7, 4.0, 7.2, 2.25, 9 },
	}
	for index, data in ipairs(fingerOffsets) do
		local finger = makePart(
			model,
			"GloveFinger" .. index,
			Vector3.new(data[3], data[4], data[4]),
			CFrame.new(center.X + data[1], 3.1, center.Z + data[2])
				* CFrame.Angles(0, math.rad(data[5] - 18), math.rad(90)),
			gloveBlue:Lerp(gloveDark, index * 0.035),
			Enum.Material.Fabric
		)
		finger.Shape = Enum.PartType.Cylinder
	end

	local thumb = makePart(
		model,
		"GloveThumb",
		Vector3.new(6.4, 2.8, 2.8),
		CFrame.new(center.X + 2.7, 2.6, center.Z - 7.2)
			* CFrame.Angles(math.rad(8), math.rad(-34), math.rad(68)),
		gloveDark,
		Enum.Material.Fabric
	)
	thumb.Shape = Enum.PartType.Cylinder

	-- A couple of dark seam strips make the glove read intentionally at bug height.
	for seamIndex, zOffset in ipairs({ -2.2, 2.1 }) do
		local seam = makePart(
			model,
			"GloveSeam" .. seamIndex,
			Vector3.new(10.5, 0.20, 0.42),
			CFrame.new(center.X - 0.2, 5.25, center.Z + zOffset) * rotation,
			gloveDark,
			Enum.Material.Fabric
		)
		seam.Transparency = 0.12
	end
end

function EnvironmentClutterPolishService.Init()
	local arena = Workspace:FindFirstChild("BuildABugArena") or Workspace:WaitForChild("BuildABugArena", 10)
	if not arena then
		warn("[Build a Bug] EnvironmentClutterPolishService could not find arena")
		return
	end

	polishLeaves(arena)
	rebuildGardenGlove(arena)
end

return EnvironmentClutterPolishService
