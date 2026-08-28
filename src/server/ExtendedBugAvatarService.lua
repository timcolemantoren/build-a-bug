--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local CosmeticStyles = require(BuildABugShared.Config.CosmeticStyles)

local ExtendedBugAvatarService = {}

local VISUAL_MODEL_NAME = "BuildABugVisual"
local BODY_OFFSET_Y = -1.95

local NATURAL = {
	Ladybug = {
		body = Color3.fromRGB(205, 54, 48),
		dark = Color3.fromRGB(35, 29, 28),
		accent = Color3.fromRGB(239, 76, 60),
	},
	Mantis = {
		body = Color3.fromRGB(121, 169, 72),
		dark = Color3.fromRGB(54, 93, 43),
		accent = Color3.fromRGB(174, 204, 91),
	},
}

local function bodyFrame(root: BasePart): CFrame
	return root.CFrame * CFrame.new(0, BODY_OFFSET_Y, 0)
end

local function paletteFor(player: Player, bugId: string)
	local style = CosmeticStyles.BodyColors[player:GetAttribute("BodyColor") or "Natural"]
	if style and not style.useBugPalette then
		return { body = style.body, dark = style.dark, accent = style.accent }
	end
	return NATURAL[bugId] or NATURAL.Ladybug
end

local function eyeStyleFor(player: Player)
	return CosmeticStyles.EyeStyles[player:GetAttribute("EyeStyle") or "Default"] or CosmeticStyles.EyeStyles.Default
end

local function createPart(model: Model, name: string, shape, size: Vector3, cframe: CFrame, color: Color3, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape or Enum.PartType.Block
	part.Size = size
	part.CFrame = cframe
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Parent = model
	return part
end

local function createMotor(parentPart: BasePart, childPart: BasePart, name: string, pivot: CFrame, role: string, side: number?, phase: number?)
	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Part0 = parentPart
	motor.Part1 = childPart
	motor.C0 = parentPart.CFrame:ToObjectSpace(pivot)
	motor.C1 = childPart.CFrame:ToObjectSpace(pivot)
	motor:SetAttribute("MotionRole", role)
	motor:SetAttribute("MotionSide", side or 0)
	motor:SetAttribute("MotionPhase", phase or 0)
	motor.Parent = childPart
	return motor
end

local function weld(parent: BasePart, child: BasePart)
	local joint = Instance.new("WeldConstraint")
	joint.Part0 = parent
	joint.Part1 = child
	joint.Parent = child
end

local function bodyPart(model: Model, root: BasePart, parent: BasePart?, name: string, size: Vector3, localFrame: CFrame, color: Color3, role: string)
	local world = bodyFrame(root) * localFrame
	local part = createPart(model, name, Enum.PartType.Ball, size, world, color, Enum.Material.SmoothPlastic)
	if parent then
		createMotor(parent, part, name .. "Joint", world, role)
	else
		createMotor(root, part, "BodyRootJoint", world, "BodyRoot")
	end
	return part
end

local function segmentFrame(a: Vector3, b: Vector3): CFrame
	local direction = b - a
	local right = direction.Unit
	local reference = Vector3.yAxis
	if math.abs(right:Dot(reference)) > 0.94 then
		reference = Vector3.zAxis
	end
	local back = right:Cross(reference).Unit
	local up = back:Cross(right).Unit
	return CFrame.fromMatrix((a + b) / 2, right, up, back)
end

local function segment(model: Model, root: BasePart, parent: BasePart, name: string, a: Vector3, b: Vector3, thickness: number, color: Color3, role: string, side: number, phase: number)
	local base = bodyFrame(root)
	local worldA = base:PointToWorldSpace(a)
	local worldB = base:PointToWorldSpace(b)
	local part = createPart(model, name, Enum.PartType.Cylinder, Vector3.new((worldB - worldA).Magnitude, thickness, thickness), segmentFrame(worldA, worldB), color, Enum.Material.SmoothPlastic)
	local pivot = CFrame.fromMatrix(worldA, base.XVector, base.YVector, base.ZVector)
	createMotor(parent, part, name .. "Joint", pivot, role, side, phase)
	return part
end

local function gaitPhase(row: number, side: number): number
	return ((row + (side > 0 and 1 or 0)) % 2 == 0) and 0 or math.pi
end

local function standardLeg(model: Model, root: BasePart, thorax: BasePart, side: number, row: number, z: number, reach: number, color: Color3, rear: number?)
	local rearBias = rear or 0
	local hip = Vector3.new(side * 0.62, -0.02, z)
	local knee = Vector3.new(side * reach * 0.63, -0.42, z + rearBias * 0.34)
	local foot = Vector3.new(side * reach, -0.82, z + rearBias * 0.72 - 0.08)
	local phase = gaitPhase(row, side)
	local upper = segment(model, root, thorax, "LegUpper", hip, knee, 0.16, color, "LegUpper", side, phase)
	segment(model, root, upper, "LegLower", knee, foot, 0.13, color, "LegLower", side, phase)
end

local function antenna(model: Model, root: BasePart, head: BasePart, side: number, z: number, reach: number, color: Color3)
	local a = Vector3.new(side * 0.22, 0.44, z)
	local b = Vector3.new(side * 0.48, 0.71, z - 0.48)
	local c = Vector3.new(side * 0.78, 0.70, reach)
	local phase = side < 0 and 0 or math.pi * 0.65
	local first = segment(model, root, head, "Antenna", a, b, 0.075, color, "Antenna", side, phase)
	segment(model, root, first, "AntennaTip", b, c, 0.06, color, "AntennaTip", side, phase)
end

local function eye(model: Model, root: BasePart, head: BasePart, position: Vector3, size: number, style)
	local actual = size * (style.sizeMultiplier or 1)
	local part = createPart(model, "Eye", Enum.PartType.Ball, Vector3.new(actual, actual, actual), bodyFrame(root) * CFrame.new(position), style.color or Color3.fromRGB(16, 16, 18), style.material or Enum.Material.SmoothPlastic)
	weld(head, part)
	if style.kind == "googly" then
		local pupilSize = actual * 0.48
		local pupil = createPart(model, "EyePupil", Enum.PartType.Ball, Vector3.new(pupilSize, pupilSize, pupilSize), bodyFrame(root) * CFrame.new(position + Vector3.new(0, 0, -actual * 0.40)), style.pupilColor or Color3.fromRGB(18, 18, 20), Enum.Material.SmoothPlastic)
		weld(part, pupil)
	elseif style.kind == "glow" then
		local light = Instance.new("PointLight")
		light.Color = style.color or Color3.fromRGB(73, 205, 255)
		light.Brightness = 0.7
		light.Range = 4
		light.Parent = part
	end
end

local function shellSurfaceFrame(shell: BasePart, xScale: number, zScale: number, sink: number): CFrame
	local rx = math.max(0.01, shell.Size.X * 0.5)
	local ry = math.max(0.01, shell.Size.Y * 0.5)
	local rz = math.max(0.01, shell.Size.Z * 0.5)
	xScale = math.clamp(xScale, -0.78, 0.78)
	zScale = math.clamp(zScale, -0.78, 0.78)

	local x = rx * xScale
	local z = rz * zScale
	local inside = 1 - (x * x) / (rx * rx) - (z * z) / (rz * rz)
	local y = ry * math.sqrt(math.max(0.035, inside))
	local normal = Vector3.new(x / (rx * rx), y / (ry * ry), z / (rz * rz)).Unit
	local reference = Vector3.zAxis
	if math.abs(normal:Dot(reference)) > 0.92 then
		reference = Vector3.xAxis
	end
	local right = normal:Cross(reference).Unit
	local back = right:Cross(normal).Unit
	return shell.CFrame * CFrame.fromMatrix(Vector3.new(x, y, z) - normal * sink, right, normal, back)
end

local function ladybugSpot(model: Model, shell: BasePart, xScale: number, zScale: number, size: number)
	local thickness = 0.045
	local spot = createPart(
		model,
		"LadybugSpot",
		Enum.PartType.Ball,
		Vector3.new(size, thickness, size),
		shellSurfaceFrame(shell, xScale, zScale, thickness * 0.32),
		Color3.fromRGB(27, 24, 24),
		Enum.Material.SmoothPlastic
	)
	spot.CastShadow = false
	weld(shell, spot)
end

local function buildLadybug(player: Player, model: Model, root: BasePart)
	local c = paletteFor(player, "Ladybug")
	local eyes = eyeStyleFor(player)
	local thorax = bodyPart(model, root, nil, "Pronotum", Vector3.new(1.86, 1.08, 1.44), CFrame.new(0, 0.02, -0.60), c.dark, "BodyRoot")
	local head = bodyPart(model, root, thorax, "Head", Vector3.new(1.28, 0.98, 1.16), CFrame.new(0, -0.02, -1.66), c.dark, "Head")
	local shell = bodyPart(model, root, thorax, "Shell", Vector3.new(2.48, 1.48, 2.94), CFrame.new(0, 0.12, 0.96), c.body, "Shell")
	local seam = createPart(model, "ShellSeam", Enum.PartType.Block, Vector3.new(0.06, 0.06, 2.42), bodyFrame(root) * CFrame.new(0, 0.91, 0.95), c.dark, Enum.Material.SmoothPlastic)
	weld(shell, seam)

	-- Native Ladybug spots are true surface markings now, not flattened balls at a
	-- shared world height. This keeps every dot flush to the curved shell.
	for _, s in ipairs({
		{ -0.50, -0.53 }, { 0.50, -0.53 },
		{ -0.58, -0.04 }, { 0.58, -0.04 },
		{ -0.40, 0.41 }, { 0.40, 0.41 },
	}) do
		ladybugSpot(model, shell, s[1], s[2], 0.38)
	end

	eye(model, root, head, Vector3.new(-0.43, 0.10, -2.08), 0.22, eyes)
	eye(model, root, head, Vector3.new(0.43, 0.10, -2.08), 0.22, eyes)
	for row, z in ipairs({ -0.72, 0.12, 0.92 }) do
		for _, side in ipairs({ -1, 1 }) do
			standardLeg(model, root, thorax, side, row, z, 1.75, c.dark, row == 3 and 1 or 0)
		end
	end
	antenna(model, root, head, -1, -2.02, -2.82, c.dark)
	antenna(model, root, head, 1, -2.02, -2.82, c.dark)
end

local function buildMantis(player: Player, model: Model, root: BasePart)
	local c = paletteFor(player, "Mantis")
	local eyes = eyeStyleFor(player)
	local thorax = bodyPart(model, root, nil, "Thorax", Vector3.new(1.10, 1.00, 2.20), CFrame.new(0, 0.05, -0.30), c.accent, "BodyRoot")
	local head = bodyPart(model, root, thorax, "Head", Vector3.new(1.48, 1.12, 1.10), CFrame.new(0, 0.13, -1.78), c.body, "Head")
	bodyPart(model, root, thorax, "Abdomen", Vector3.new(1.18, 0.96, 3.10), CFrame.new(0, 0.03, 1.72), c.body, "Abdomen")
	eye(model, root, head, Vector3.new(-0.53, 0.23, -2.13), 0.30, eyes)
	eye(model, root, head, Vector3.new(0.53, 0.23, -2.13), 0.30, eyes)

	-- Two folding raptorial forelegs plus four walking legs = six insect legs total.
	for _, side in ipairs({ -1, 1 }) do
		local phase = gaitPhase(1, side)
		local shoulder = Vector3.new(side * 0.48, 0.10, -0.92)
		local elbow = Vector3.new(side * 1.38, 0.20, -1.55)
		local claw = Vector3.new(side * 1.10, -0.64, -2.32)
		local upper = segment(model, root, thorax, "LegUpper", shoulder, elbow, 0.22, c.accent, "LegUpper", side, phase)
		segment(model, root, upper, "LegLower", elbow, claw, 0.15, c.dark, "LegLower", side, phase)
	end
	for row, z in ipairs({ 0.35, 1.28 }) do
		for _, side in ipairs({ -1, 1 }) do
			standardLeg(model, root, thorax, side, row + 1, z, row == 1 and 1.95 or 2.18, c.dark, row == 2 and 1 or 0)
		end
	end
	antenna(model, root, head, -1, -2.02, -3.15, c.dark)
	antenna(model, root, head, 1, -2.02, -3.15, c.dark)
end

local function replaceVisual(player: Player, model: Model)
	local bugId = model:GetAttribute("BugId")
	if bugId ~= "Ladybug" and bugId ~= "Mantis" then
		return
	end
	local character = model.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	for _, child in ipairs(model:GetChildren()) do
		child:Destroy()
	end
	model:SetAttribute("RigVersion", 6)
	if bugId == "Ladybug" then
		buildLadybug(player, model, root)
	else
		buildMantis(player, model, root)
	end
end

local function watchCharacter(player: Player, character: Model)
	local function consider(child)
		if child:IsA("Model") and child.Name == VISUAL_MODEL_NAME then
			task.delay(0.08, function()
				if child.Parent then
					replaceVisual(player, child)
				end
			end)
		end
	end
	local current = character:FindFirstChild(VISUAL_MODEL_NAME)
	if current then
		consider(current)
	end
	character.ChildAdded:Connect(consider)
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		watchCharacter(player, character)
	end)
	if player.Character then
		watchCharacter(player, player.Character)
	end
end

function ExtendedBugAvatarService.Init()
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)
end

return ExtendedBugAvatarService
