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

	-- Rebuild from a stable backyard-mushroom recipe rather than repeatedly scaling
	-- the previous version. The broad brim + low dome is what makes the silhouette
	-- read as mushroom instead of matchstick or sci-fi orb at bug height.
	local sizeStep = (index - 1) % 5
	local stemHeight = 3.35 + sizeStep * 0.34
	local stemDiameter = 1.85 + ((index * 3) % 4) * 0.18
	local capWidth = 8.1 + sizeStep * 0.62
	local capDepth = capWidth * (0.84 + ((index + 1) % 3) * 0.045)
	local brimThickness = 0.72 + (index % 2) * 0.10
	local domeHeight = 1.45 + (index % 3) * 0.16
	local baseY = 0.55

	local leanX = (((index * 7) % 5) - 2) * 0.10
	local leanZ = (((index * 11) % 5) - 2) * 0.08
	local stemCFrame = CFrame.new(x, baseY + stemHeight / 2, z)
		* CFrame.Angles(math.rad(leanX), 0, math.rad(90 + leanZ))

	local stem = makePart(
		model,
		"MushroomStem" .. index,
		Vector3.new(stemHeight, stemDiameter, stemDiameter),
		stemCFrame,
		Color3.fromRGB(196 + (index % 3) * 5, 184 + (index % 2) * 4, 154),
		Enum.Material.Sand
	)
	stem.Shape = Enum.PartType.Cylinder

	local capOffsetX = (((index * 13) % 5) - 2) * 0.12
	local capOffsetZ = (((index * 17) % 5) - 2) * 0.10
	local capX = x + capOffsetX
	local capZ = z + capOffsetZ
	local brimY = baseY + stemHeight + 0.10
	local capYaw = math.rad((index * 29) % 180)

	-- Cylinders use their X axis, so a 90-degree Z rotation makes this a horizontal
	-- pancake. It is collidable and gives players a predictable surface to jump on.
	local brim = makePart(
		model,
		"MushroomCap" .. index,
		Vector3.new(brimThickness, capWidth, capDepth),
		CFrame.new(capX, brimY, capZ) * CFrame.Angles(0, capYaw, math.rad(90)),
		capColor,
		Enum.Material.Fabric
	)
	brim.Shape = Enum.PartType.Cylinder
	brim.Reflectance = 0

	local dome = makePart(
		model,
		"MushroomDome" .. index,
		Vector3.new(capWidth * 0.76, domeHeight, capDepth * 0.76),
		CFrame.new(capX, brimY + brimThickness * 0.42 + domeHeight * 0.30, capZ) * CFrame.Angles(0, capYaw, 0),
		capColor:Lerp(Color3.fromRGB(105, 75, 55), 0.07),
		Enum.Material.Fabric
	)
	dome.Shape = Enum.PartType.Ball
	dome.CanCollide = false
	dome.CanTouch = false
	dome.CanQuery = false

	local underside = makePart(
		model,
		"MushroomUnderside" .. index,
		Vector3.new(0.20, capWidth * 0.78, capDepth * 0.78),
		CFrame.new(capX, brimY - brimThickness * 0.44, capZ) * CFrame.Angles(0, capYaw, math.rad(90)),
		Color3.fromRGB(211, 196, 164),
		Enum.Material.Sand
	)
	underside.Shape = Enum.PartType.Cylinder
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

	-- Three rounded logs form a clear arch. There are no broad rectangular wall or
	-- roof pieces, so this landmark cannot turn back into a solid brown slab from a
	-- different camera angle.
	makeLog("BarkSideLeft", Vector3.new(center.X, groundY + sideDiameter / 2, center.Z - zSpread), sideDiameter, barkA, 1.0, -1.2)
	makeLog("BarkSideRight", Vector3.new(center.X + 0.7, groundY + sideDiameter / 2 + 0.25, center.Z + zSpread), sideDiameter * 0.96, barkB, -1.1, 1.4)
	makeLog("BarkTop", Vector3.new(center.X - 0.4, groundY + sideDiameter + topDiameter / 2 + 1.1, center.Z), topDiameter, barkA, 0.7, -0.8)

	local leftX = center.X - length / 2
	local rightX = center.X + length / 2
	addLogEnd(model, "LeftLogEndA", Vector3.new(leftX, groundY + sideDiameter / 2, center.Z - zSpread), sideDiameter, endColor)
	addLogEnd(model, "RightLogEndA", Vector3.new(rightX, groundY + sideDiameter / 2, center.Z - zSpread), sideDiameter, endColor)
	addLogEnd(model, "LeftLogEndTop", Vector3.new(leftX - 0.4, groundY + sideDiameter + topDiameter / 2 + 1.1, center.Z), topDiameter, endColor)
	addLogEnd(model, "RightLogEndTop", Vector3.new(rightX - 0.4, groundY + sideDiameter + topDiameter / 2 + 1.1, center.Z), topDiameter, endColor)

	-- Small dark knots break up the long cylinders without affecting collision.
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
	rebuildBarkTunnel(arena)
	createRescuePlane(arena)

	Players.PlayerRemoving:Connect(function(player)
		rescueCooldown[player.UserId] = nil
	end)
end

return EnvironmentFinishService
