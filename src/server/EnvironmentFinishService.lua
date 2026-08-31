--!nonstrict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local EnvironmentFinishService = {}

local rescueCooldown = {}
local RESCUE_Y = -10

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

local function rebuildMushroom(model: Model, index: number)
	local oldStem = model:FindFirstChild("MushroomStem" .. index)
	local oldCap = model:FindFirstChild("MushroomCap" .. index)
	if not oldStem or not oldStem:IsA("BasePart") or not oldCap or not oldCap:IsA("BasePart") then
		return
	end

	local x = oldStem.Position.X
	local z = oldStem.Position.Z
	local capColor = oldCap.Color
	model:ClearAllChildren()

	-- Build a simple, recognizable backyard mushroom silhouette. A single flattened
	-- ellipsoid reads more naturally than the previous pancake + dome construction.
	local sizeStep = (index - 1) % 5
	local stemHeight = 3.0 + sizeStep * 0.31
	local stemDiameter = 1.85 + ((index * 3) % 4) * 0.16
	local capWidth = 7.3 + sizeStep * 0.55
	local capDepth = capWidth * (0.88 + ((index + 1) % 3) * 0.035)
	local capHeight = 2.05 + (index % 3) * 0.18
	local baseY = 0.55

	local leanDegrees = ((index % 5) - 2) * 1.3
	local stem = makePart(
		model,
		"MushroomStem" .. index,
		Vector3.new(stemHeight, stemDiameter, stemDiameter),
		CFrame.new(x, baseY + stemHeight / 2, z) * CFrame.Angles(0, 0, math.rad(90 + leanDegrees)),
		Color3.fromRGB(196 + (index % 3) * 5, 184 + (index % 2) * 4, 154),
		Enum.Material.Sand
	)
	stem.Shape = Enum.PartType.Cylinder

	local capOffsetX = (((index * 13) % 5) - 2) * 0.10
	local capOffsetZ = (((index * 17) % 5) - 2) * 0.09
	local capX = x + capOffsetX
	local capZ = z + capOffsetZ
	local capY = baseY + stemHeight + capHeight * 0.16
	local tiltX = math.rad((((index * 3) % 5) - 2) * 1.6)
	local tiltZ = math.rad((((index * 5) % 5) - 2) * 1.4)
	local capYaw = math.rad((index * 29) % 180)
	local capCFrame = CFrame.new(capX, capY, capZ) * CFrame.Angles(tiltX, capYaw, tiltZ)

	local cap = makePart(
		model,
		"MushroomCap" .. index,
		Vector3.new(capWidth, capHeight, capDepth),
		capCFrame,
		capColor,
		Enum.Material.Fabric
	)
	cap.Shape = Enum.PartType.Ball
	cap.Reflectance = 0

	-- A small pale underside gives the cap depth from bug height without creating a
	-- hard saucer edge. It is visual-only so the main cap remains the jump surface.
	local underside = makePart(
		model,
		"MushroomUnderside" .. index,
		Vector3.new(capWidth * 0.67, 0.42, capDepth * 0.67),
		CFrame.new(capX, capY - capHeight * 0.34, capZ) * CFrame.Angles(tiltX, capYaw, tiltZ),
		Color3.fromRGB(211, 196, 164),
		Enum.Material.Sand
	)
	underside.Shape = Enum.PartType.Ball
	underside.CanCollide = false
	underside.CanTouch = false
	underside.CanQuery = false
end

local function rebuildMushrooms(arena: Instance)
	local clutter = arena:FindFirstChild("Clutter")
	if not clutter then
		return
	end

	for index = 1, 24 do
		local model = clutter:FindFirstChild("Mushroom" .. index)
		if model and model:IsA("Model") then
			rebuildMushroom(model, index)
		end
	end
end

local function isMushroomBlockingPart(part: BasePart, model: Model, arena: Instance): boolean
	if part:IsDescendantOf(model) then
		return false
	end
	if part.Name == "DirtFloor" or part.Name == "OutOfBoundsRescue" then
		return false
	end
	if part:GetAttribute("IsEnvironmentZone") then
		return false
	end

	local name = part.Name
	if string.find(name, "Grass")
		or string.find(name, "FallenLeaf")
		or string.find(name, "Twig")
		or string.find(name, "Clover")
		or string.find(name, "DirtPatch")
		or string.find(name, "DirtClod") then
		return false
	end

	if string.find(name, "Mushroom") then
		return true
	end
	if string.find(name, "Pebble") or string.find(name, "RockPile") or string.find(name, "GardenRock") then
		return true
	end

	local cover = arena:FindFirstChild("Cover")
	if cover and part:IsDescendantOf(cover) then
		return true
	end

	return false
end

local function mushroomIsBlocked(model: Model, arena: Instance): boolean
	local boxCFrame, boxSize = model:GetBoundingBox()
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model }

	for _, hit in ipairs(Workspace:GetPartBoundsInBox(boxCFrame, boxSize * 0.88, params)) do
		if hit:IsA("BasePart") and isMushroomBlockingPart(hit, model, arena) then
			return true
		end
	end
	return false
end

local function separateMushrooms(arena: Instance)
	local clutter = arena:FindFirstChild("Clutter")
	if not clutter then
		return
	end

	local offsets = {
		Vector3.new(7, 0, 0), Vector3.new(-7, 0, 0), Vector3.new(0, 0, 7), Vector3.new(0, 0, -7),
		Vector3.new(7, 0, 7), Vector3.new(-7, 0, 7), Vector3.new(7, 0, -7), Vector3.new(-7, 0, -7),
		Vector3.new(12, 0, 0), Vector3.new(-12, 0, 0), Vector3.new(0, 0, 12), Vector3.new(0, 0, -12),
		Vector3.new(12, 0, 8), Vector3.new(-12, 0, 8), Vector3.new(12, 0, -8), Vector3.new(-12, 0, -8),
	}

	for index = 1, 24 do
		local model = clutter:FindFirstChild("Mushroom" .. index)
		if model and model:IsA("Model") and mushroomIsBlocked(model, arena) then
			local originalPivot = model:GetPivot()
			local originalPosition = originalPivot.Position
			local rotation = originalPivot.Rotation
			local foundClear = false

			for _, offset in ipairs(offsets) do
				local candidate = originalPosition + offset
				if math.abs(candidate.X) < 194 and math.abs(candidate.Z) < 194 then
					model:PivotTo(CFrame.new(candidate) * rotation)
					if not mushroomIsBlocked(model, arena) then
						foundClear = true
						break
					end
				end
			end

			if not foundClear then
				model:PivotTo(originalPivot)
			end
		end
	end
end

local function rebuildAcorn(cover: Instance, partName: string, index: number)
	local old = cover:FindFirstChild(partName)
	if not old or not old:IsA("BasePart") then
		return
	end

	local center = old.Position
	local originalSize = old.Size
	old:Destroy()

	local model = Instance.new("Model")
	model.Name = partName
	model.Parent = cover

	local footprint = math.min(originalSize.X, originalSize.Z)
	local bodyWidth = footprint * 0.76
	local bodyDepth = footprint * 0.70
	local bodyHeight = math.max(5.2, originalSize.Y * 0.92)
	local yaw = math.rad(index == 1 and -24 or 19)
	local roll = math.rad(index == 1 and 13 or -11)
	local bodyY = 0.55 + bodyHeight / 2
	local nutColor = index == 1 and Color3.fromRGB(128, 76, 40) or Color3.fromRGB(113, 68, 37)

	local body = makePart(
		model,
		"AcornBody",
		Vector3.new(bodyWidth, bodyHeight, bodyDepth),
		CFrame.new(center.X, bodyY, center.Z) * CFrame.Angles(roll, yaw, math.rad(8)),
		nutColor,
		Enum.Material.SmoothPlastic
	)
	body.Shape = Enum.PartType.Ball

	local capHeight = math.max(1.8, bodyHeight * 0.30)
	local cap = makePart(
		model,
		"AcornCap",
		Vector3.new(bodyWidth * 0.93, capHeight, bodyDepth * 0.93),
		CFrame.new(center.X, bodyY + bodyHeight * 0.34, center.Z) * CFrame.Angles(roll, yaw, math.rad(8)),
		Color3.fromRGB(78, 52, 34),
		Enum.Material.Fabric
	)
	cap.Shape = Enum.PartType.Ball

	local stem = makePart(
		model,
		"AcornStem",
		Vector3.new(2.2, 0.8, 0.8),
		CFrame.new(center.X, bodyY + bodyHeight * 0.61, center.Z) * CFrame.Angles(0, yaw, math.rad(72)),
		Color3.fromRGB(71, 47, 30),
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
	rebuildAcorn(cover, "AcornCapA", 1)
	rebuildAcorn(cover, "AcornCapB", 2)
end

local function addLogEnd(parent: Instance, name: string, position: Vector3, diameter: number, color: Color3)
	local ring = makePart(
		parent,
		name,
		Vector3.new(0.34, diameter * 0.90, diameter * 0.90),
		CFrame.new(position),
		color,
		Enum.Material.Wood
	)
	ring.Shape = Enum.PartType.Cylinder
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
end

local function rebuildBarkTunnel(arena: Instance)
	local cover = arena:FindFirstChild("Cover")
	if not cover then
		return
	end

	local old = cover:FindFirstChild("BarkTunnel")
	if not old then
		return
	end

	local center
	local size
	if old:IsA("Model") then
		local boxCFrame, boxSize = old:GetBoundingBox()
		center = boxCFrame.Position
		size = boxSize
	elseif old:IsA("BasePart") then
		center = old.Position
		size = old.Size
	else
		return
	end
	old:Destroy()

	local model = Instance.new("Model")
	model.Name = "BarkTunnel"
	model.Parent = cover

	local length = math.clamp(size.X, 44, 52)
	local groundY = 0.55
	local sideDiameter = 5.4
	local topDiameter = 5.9
	local zSpread = 7.4
	local barkA = Color3.fromRGB(91, 57, 35)
	local barkB = Color3.fromRGB(111, 70, 41)
	local barkDark = Color3.fromRGB(64, 40, 28)
	local endColor = Color3.fromRGB(146, 104, 67)

	local function makeLog(name: string, position: Vector3, diameter: number, color: Color3, yawDegrees: number, rollDegrees: number)
		local log = makePart(
			model,
			name,
			Vector3.new(length, diameter, diameter),
			CFrame.new(position) * CFrame.Angles(math.rad(rollDegrees), math.rad(yawDegrees), 0),
			color,
			Enum.Material.Wood
		)
		log.Shape = Enum.PartType.Cylinder
		return log
	end

	makeLog("BarkSideLeft", Vector3.new(center.X, groundY + sideDiameter / 2, center.Z - zSpread), sideDiameter, barkA, 1.0, -1.2)
	makeLog("BarkSideRight", Vector3.new(center.X + 0.7, groundY + sideDiameter / 2 + 0.25, center.Z + zSpread), sideDiameter * 0.96, barkB, -1.1, 1.4)
	makeLog("BarkTop", Vector3.new(center.X - 0.4, groundY + sideDiameter + topDiameter / 2 + 1.1, center.Z), topDiameter, barkA, 0.7, -0.8)

	local leftX = center.X - length / 2
	local rightX = center.X + length / 2
	addLogEnd(model, "LeftLogEndA", Vector3.new(leftX, groundY + sideDiameter / 2, center.Z - zSpread), sideDiameter, endColor)
	addLogEnd(model, "RightLogEndA", Vector3.new(rightX, groundY + sideDiameter / 2, center.Z - zSpread), sideDiameter, endColor)
	addLogEnd(model, "LeftLogEndTop", Vector3.new(leftX - 0.4, groundY + sideDiameter + topDiameter / 2 + 1.1, center.Z), topDiameter, endColor)
	addLogEnd(model, "RightLogEndTop", Vector3.new(rightX - 0.4, groundY + sideDiameter + topDiameter / 2 + 1.1, center.Z), topDiameter, endColor)

	for knotIndex, data in ipairs({
		{ -12, groundY + sideDiameter + 4.0, -2.5, 2.1 },
		{ 10, groundY + sideDiameter + 3.5, 2.3, 1.7 },
		{ -4, groundY + 3.2, zSpread - 2.3, 1.5 },
	}) do
		local knot = makePart(
			model,
			"BarkKnot" .. knotIndex,
			Vector3.new(data[4], data[4] * 0.72, data[4]),
			CFrame.new(center.X + data[1], data[2], center.Z + data[3]),
			barkDark,
			Enum.Material.Wood
		)
		knot.Shape = Enum.PartType.Ball
		knot.CanCollide = false
		knot.CanTouch = false
		knot.CanQuery = false
	end
end

local function getPlayerFromHit(hit: Instance): Player?
	local current = hit
	while current and current ~= Workspace do
		if current:IsA("Model") then
			local player = Players:GetPlayerFromCharacter(current)
			if player then
				return player
			end
		end
		current = current.Parent
	end
	return nil
end

local function rescuePlayer(player: Player)
	local now = os.clock()
	if rescueCooldown[player.UserId] and now - rescueCooldown[player.UserId] < 1.5 then
		return
	end
	rescueCooldown[player.UserId] = now

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return
	end

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	local inRound = player:GetAttribute("InRound") == true
	local safeZ = inRound and 105 or 145
	local laneOffset = ((player.UserId % 7) - 3) * 2.2
	character:PivotTo(CFrame.new(laneOffset, 6, safeZ))
end

local function createRescuePlane(arena: Instance)
	local old = arena:FindFirstChild("OutOfBoundsRescue")
	if old then
		old:Destroy()
	end

	local plane = Instance.new("Part")
	plane.Name = "OutOfBoundsRescue"
	plane.Size = Vector3.new(470, 1, 470)
	plane.Position = Vector3.new(0, RESCUE_Y, 0)
	plane.Anchored = true
	plane.Transparency = 1
	plane.CanCollide = false
	plane.CanTouch = true
	plane.CanQuery = false
	plane.CastShadow = false
	plane.Parent = arena

	plane.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if player then
			rescuePlayer(player)
		end
	end)

	task.spawn(function()
		while arena.Parent do
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") and root.Position.Y < RESCUE_Y - 3 then
					rescuePlayer(player)
				end
			end
			task.wait(0.75)
		end
	end)
end

function EnvironmentFinishService.Init()
	local arena = Workspace:FindFirstChild("BuildABugArena") or Workspace:WaitForChild("BuildABugArena", 10)
	if not arena then
		warn("[Build a Bug] EnvironmentFinishService could not find arena")
		return
	end

	rebuildMushrooms(arena)
	rebuildAcorns(arena)
	rebuildBarkTunnel(arena)
	separateMushrooms(arena)
	createRescuePlane(arena)

	Players.PlayerRemoving:Connect(function(player)
		rescueCooldown[player.UserId] = nil
	end)
end

return EnvironmentFinishService
