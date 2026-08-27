--!nonstrict

local Players = game:GetService("Players")

-- Articulated bug avatar system.
-- Roblox's hidden Humanoid/R15 character still owns all movement, collision,
-- health, networking, and abilities. The visible insect is a lightweight Motor6D
-- hierarchy attached to HumanoidRootPart so motion can propagate through real
-- body/hip/knee/antenna chains.

local BugAvatarService = {}
local PlayerDataService = nil

local VISUAL_MODEL_NAME = "BuildABugVisual"
local BODY_OFFSET_Y = -2.15
local CAMERA_OFFSET_Y = -0.75

local COLORS = {
	Ant = {
		body = Color3.fromRGB(92, 43, 30),
		dark = Color3.fromRGB(54, 27, 22),
		accent = Color3.fromRGB(135, 66, 40),
	},
	Beetle = {
		body = Color3.fromRGB(38, 69, 92),
		dark = Color3.fromRGB(20, 31, 43),
		accent = Color3.fromRGB(72, 124, 148),
	},
	Grasshopper = {
		body = Color3.fromRGB(89, 139, 55),
		dark = Color3.fromRGB(45, 82, 35),
		accent = Color3.fromRGB(145, 178, 76),
	},
}

local function hideRobloxAvatar(character: Model)
	local visual = character:FindFirstChild(VISUAL_MODEL_NAME)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if not visual or not descendant:IsDescendantOf(visual) then
				descendant.Transparency = 1
			end
		elseif descendant:IsA("Decal") then
			descendant.Transparency = 1
		elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
			descendant.Enabled = false
		end
	end
end

local function bodyFrame(root: BasePart): CFrame
	return root.CFrame * CFrame.new(0, BODY_OFFSET_Y, 0)
end

local function createPart(model: Model, name: string, shape, size: Vector3, worldCFrame: CFrame, color: Color3, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape or Enum.PartType.Block
	part.Size = size
	part.CFrame = worldCFrame
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Parent = model
	return part
end

local function createMotor(parentPart: BasePart, childPart: BasePart, name: string, pivotWorld: CFrame, role: string?, side: number?, phase: number?)
	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Part0 = parentPart
	motor.Part1 = childPart
	motor.C0 = parentPart.CFrame:ToObjectSpace(pivotWorld)
	motor.C1 = childPart.CFrame:ToObjectSpace(pivotWorld)
	if role then
		motor:SetAttribute("MotionRole", role)
	end
	if side then
		motor:SetAttribute("MotionSide", side)
	end
	if phase then
		motor:SetAttribute("MotionPhase", phase)
	end
	motor.Parent = childPart
	return motor
end

local function createStaticWeld(parentPart: BasePart, childPart: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = parentPart
	weld.Part1 = childPart
	weld.Parent = childPart
end

local function createBodyPart(model: Model, root: BasePart, parentPart: BasePart?, name: string, shape, size: Vector3, localCFrame: CFrame, color: Color3, material, role: string?)
	local world = bodyFrame(root) * localCFrame
	local part = createPart(model, name, shape, size, world, color, material)
	if parentPart then
		createMotor(parentPart, part, name .. "Joint", world, role or name, 0, 0)
	else
		createMotor(root, part, "BodyRootJoint", world, role or "BodyRoot", 0, 0)
	end
	return part
end

local function segmentFrame(worldA: Vector3, worldB: Vector3): CFrame
	local direction = worldB - worldA
	local right = direction.Unit
	local referenceUp = Vector3.yAxis
	if math.abs(right:Dot(referenceUp)) > 0.94 then
		referenceUp = Vector3.zAxis
	end
	local back = right:Cross(referenceUp).Unit
	local up = back:Cross(right).Unit
	local midpoint = (worldA + worldB) / 2
	return CFrame.fromMatrix(midpoint, right, up, back)
end

local function createSegment(model: Model, root: BasePart, parentPart: BasePart, name: string, localA: Vector3, localB: Vector3, thickness: number, color: Color3, role: string, side: number, phase: number)
	local base = bodyFrame(root)
	local worldA = base:PointToWorldSpace(localA)
	local worldB = base:PointToWorldSpace(localB)
	local length = (worldB - worldA).Magnitude
	local part = createPart(
		model,
		name,
		Enum.PartType.Cylinder,
		Vector3.new(length, thickness, thickness),
		segmentFrame(worldA, worldB),
		color,
		Enum.Material.SmoothPlastic
	)
	local pivot = CFrame.fromMatrix(worldA, base.XVector, base.YVector, base.ZVector)
	createMotor(parentPart, part, name .. "Joint", pivot, role, side, phase)
	return part
end

local function createEye(model: Model, root: BasePart, head: BasePart, localPosition: Vector3, size: number)
	local eye = createPart(
		model,
		"Eye",
		Enum.PartType.Ball,
		Vector3.new(size, size, size),
		bodyFrame(root) * CFrame.new(localPosition),
		Color3.fromRGB(16, 16, 18),
		Enum.Material.SmoothPlastic
	)
	createStaticWeld(head, eye)
	return eye
end

local function gaitPhase(row: number, side: number): number
	local rightOffset = side > 0 and 1 or 0
	return ((row + rightOffset) % 2 == 0) and 0 or math.pi
end

local function createLeg(model: Model, root: BasePart, thorax: BasePart, side: number, row: number, z: number, reach: number, color: Color3, rearBias: number?)
	local rear = rearBias or 0
	local hip = Vector3.new(side * 0.62, -0.03, z)
	local knee = Vector3.new(side * reach * 0.63, -0.42, z + rear * 0.38)
	local foot = Vector3.new(side * reach, -0.82, z + rear * 0.78 - 0.10)
	local phase = gaitPhase(row, side)
	local upper = createSegment(model, root, thorax, "LegUpper", hip, knee, 0.16, color, "LegUpper", side, phase)
	createSegment(model, root, upper, "LegLower", knee, foot, 0.13, color, "LegLower", side, phase)
end

local function createAntenna(model: Model, root: BasePart, head: BasePart, side: number, startZ: number, reachZ: number, color: Color3)
	-- Antennae now emerge from the upper/inner surface of the head instead of
	-- visually sharing the eye sockets. This keeps the lively motion while making
	-- their anatomy read correctly from the normal third-person camera.
	local basePoint = Vector3.new(side * 0.24, 0.46, startZ + 0.08)
	local bend = Vector3.new(side * 0.56, 0.78, startZ - 0.48)
	local tip = Vector3.new(side * 0.90, 0.76, reachZ)
	local phase = side < 0 and 0 or math.pi * 0.65
	local first = createSegment(model, root, head, "Antenna", basePoint, bend, 0.085, color, "Antenna", side, phase)
	createSegment(model, root, first, "AntennaTip", bend, tip, 0.07, color, "AntennaTip", side, phase)
end

local function buildAnt(model: Model, root: BasePart)
	local c = COLORS.Ant
	local thorax = createBodyPart(model, root, nil, "Thorax", Enum.PartType.Ball, Vector3.new(1.30, 1.00, 1.40), CFrame.new(0, 0, -0.30), c.accent, nil, "BodyRoot")
	local head = createBodyPart(model, root, thorax, "Head", Enum.PartType.Ball, Vector3.new(1.32, 1.02, 1.22), CFrame.new(0, 0.02, -1.62), c.body, nil, "Head")
	createBodyPart(model, root, thorax, "Abdomen", Enum.PartType.Ball, Vector3.new(1.72, 1.30, 2.20), CFrame.new(0, 0.02, 1.20), c.body, nil, "Abdomen")
	createEye(model, root, head, Vector3.new(-0.47, 0.14, -2.08), 0.24)
	createEye(model, root, head, Vector3.new(0.47, 0.14, -2.08), 0.24)

	for row, z in ipairs({ -0.82, 0.0, 0.82 }) do
		for _, side in ipairs({ -1, 1 }) do
			createLeg(model, root, thorax, side, row, z, 1.85, c.dark, row == 3 and 1 or 0)
		end
	end
	createAntenna(model, root, head, -1, -2.02, -3.05, c.dark)
	createAntenna(model, root, head, 1, -2.02, -3.05, c.dark)
end

local function buildBeetle(model: Model, root: BasePart)
	local c = COLORS.Beetle
	local pronotum = createBodyPart(model, root, nil, "Pronotum", Enum.PartType.Ball, Vector3.new(2.00, 1.16, 1.52), CFrame.new(0, 0.03, -0.58), c.accent, nil, "BodyRoot")
	local head = createBodyPart(model, root, pronotum, "Head", Enum.PartType.Ball, Vector3.new(1.42, 1.03, 1.23), CFrame.new(0, -0.02, -1.72), c.dark, nil, "Head")
	local shell = createBodyPart(model, root, pronotum, "Shell", Enum.PartType.Ball, Vector3.new(2.62, 1.52, 3.12), CFrame.new(0, 0.12, 1.02), c.body, nil, "Shell")
	local seam = createPart(model, "ShellSeam", Enum.PartType.Block, Vector3.new(0.07, 0.07, 2.58), bodyFrame(root) * CFrame.new(0, 0.91, 1.00), c.dark, Enum.Material.SmoothPlastic)
	createStaticWeld(shell, seam)
	createEye(model, root, head, Vector3.new(-0.47, 0.10, -2.13), 0.22)
	createEye(model, root, head, Vector3.new(0.47, 0.10, -2.13), 0.22)

	for row, z in ipairs({ -0.72, 0.14, 0.96 }) do
		for _, side in ipairs({ -1, 1 }) do
			createLeg(model, root, pronotum, side, row, z, 1.88, c.dark, row == 3 and 1 or 0)
		end
	end
	createAntenna(model, root, head, -1, -2.06, -2.88, c.dark)
	createAntenna(model, root, head, 1, -2.06, -2.88, c.dark)
end

local function buildGrasshopper(model: Model, root: BasePart)
	local c = COLORS.Grasshopper
	local thorax = createBodyPart(model, root, nil, "Thorax", Enum.PartType.Ball, Vector3.new(1.50, 1.12, 1.62), CFrame.new(0, 0.04, -0.50), c.body, nil, "BodyRoot")
	local head = createBodyPart(model, root, thorax, "Head", Enum.PartType.Ball, Vector3.new(1.34, 1.12, 1.22), CFrame.new(0, 0.08, -1.72), c.accent, nil, "Head")
	local abdomen = createBodyPart(model, root, thorax, "Abdomen", Enum.PartType.Ball, Vector3.new(1.42, 1.02, 2.80), CFrame.new(0, 0.04, 1.18), c.body, nil, "Abdomen")
	createEye(model, root, head, Vector3.new(-0.49, 0.18, -2.14), 0.27)
	createEye(model, root, head, Vector3.new(0.49, 0.18, -2.14), 0.27)

	for _, side in ipairs({ -1, 1 }) do
		local wing = createPart(
			model,
			side < 0 and "WingLeft" or "WingRight",
			Enum.PartType.Block,
			Vector3.new(0.16, 0.07, 2.38),
			bodyFrame(root) * CFrame.new(side * 0.42, 0.64, 0.76) * CFrame.Angles(0, math.rad(side * 8), math.rad(side * 7)),
			c.accent,
			Enum.Material.SmoothPlastic
		)
		local pivotWorld = bodyFrame(root) * CFrame.new(side * 0.34, 0.58, -0.12)
		createMotor(abdomen, wing, "WingJoint", pivotWorld, side < 0 and "WingLeft" or "WingRight", side, 0)
	end

	for row, z in ipairs({ -0.72, 0.12 }) do
		for _, side in ipairs({ -1, 1 }) do
			createLeg(model, root, thorax, side, row, z, 1.78, c.dark, 0)
		end
	end

	for _, side in ipairs({ -1, 1 }) do
		local hip = Vector3.new(side * 0.62, -0.02, 0.90)
		local knee = Vector3.new(side * 1.78, 0.18, 1.92)
		local foot = Vector3.new(side * 2.62, -0.82, 2.72)
		local phase = gaitPhase(3, side)
		local thigh = createSegment(model, root, thorax, "HindLegThigh", hip, knee, 0.30, c.accent, "HindLegThigh", side, phase)
		createSegment(model, root, thigh, "HindLegShin", knee, foot, 0.18, c.dark, "HindLegShin", side, phase)
	end

	createAntenna(model, root, head, -1, -2.00, -3.40, c.dark)
	createAntenna(model, root, head, 1, -2.00, -3.40, c.dark)
end

local function buildVisual(player: Player)
	local character = player.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end

	local existing = character:FindFirstChild(VISUAL_MODEL_NAME)
	if existing then
		existing:Destroy()
	end

	local selectedBug = player:GetAttribute("SelectedBug")
	if not selectedBug and PlayerDataService then
		local data = PlayerDataService.GetData(player)
		selectedBug = data and data.selectedBug
	end
	selectedBug = selectedBug or "Ant"

	local model = Instance.new("Model")
	model.Name = VISUAL_MODEL_NAME
	model:SetAttribute("BugId", selectedBug)
	model:SetAttribute("RigVersion", 2)
	model.Parent = character

	if selectedBug == "Beetle" then
		buildBeetle(model, root)
	elseif selectedBug == "Grasshopper" then
		buildGrasshopper(model, root)
	else
		buildAnt(model, root)
	end

	hideRobloxAvatar(character)
	humanoid.CameraOffset = Vector3.new(0, CAMERA_OFFSET_Y, 0)
	pcall(function()
		humanoid.NameDisplayDistance = 0
	end)
end

local function setupPlayer(player: Player)
	player:GetAttributeChangedSignal("SelectedBug"):Connect(function()
		task.defer(buildVisual, player)
	end)

	player.CharacterAdded:Connect(function()
		task.wait(0.4)
		buildVisual(player)
	end)

	if player.Character then
		task.defer(function()
			task.wait(0.4)
			buildVisual(player)
		end)
	end
end

function BugAvatarService.Init(playerDataService)
	PlayerDataService = playerDataService
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)
end

return BugAvatarService
