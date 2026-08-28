--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local CosmeticStyles = require(BuildABugShared.Config.CosmeticStyles)

local AdditionalBugAvatarService = {}

local VISUAL_MODEL_NAME = "BuildABugVisual"
local BODY_OFFSET_Y = -1.95

local NATURAL = {
	Dragonfly = {
		body = Color3.fromRGB(54, 139, 159),
		dark = Color3.fromRGB(28, 72, 83),
		accent = Color3.fromRGB(92, 204, 214),
	},
	Pillbug = {
		body = Color3.fromRGB(104, 112, 122),
		dark = Color3.fromRGB(48, 54, 62),
		accent = Color3.fromRGB(143, 150, 158),
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
	return NATURAL[bugId]
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

local function leg(model: Model, root: BasePart, thorax: BasePart, side: number, row: number, z: number, reach: number, color: Color3)
	local hip = Vector3.new(side * 0.52, -0.03, z)
	local knee = Vector3.new(side * reach * 0.62, -0.39, z + (row == 3 and 0.30 or 0))
	local foot = Vector3.new(side * reach, -0.80, z + (row == 3 and 0.62 or -0.05))
	local phase = gaitPhase(row, side)
	local upper = segment(model, root, thorax, "LegUpper", hip, knee, 0.14, color, "LegUpper", side, phase)
	segment(model, root, upper, "LegLower", knee, foot, 0.11, color, "LegLower", side, phase)
end

local function antenna(model: Model, root: BasePart, head: BasePart, side: number, z: number, reach: number, color: Color3)
	local a = Vector3.new(side * 0.20, 0.43, z)
	local b = Vector3.new(side * 0.43, 0.69, z - 0.48)
	local c = Vector3.new(side * 0.70, 0.72, reach)
	local phase = side < 0 and 0 or math.pi * 0.65
	local first = segment(model, root, head, "Antenna", a, b, 0.065, color, "Antenna", side, phase)
	segment(model, root, first, "AntennaTip", b, c, 0.05, color, "AntennaTip", side, phase)
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

local function wing(model: Model, root: BasePart, thorax: BasePart, side: number, x: number, z: number, length: number, color: Color3)
	local world = bodyFrame(root) * CFrame.new(side * x, 0.48, z) * CFrame.Angles(0, math.rad(side * 10), math.rad(side * -12))
	local part = createPart(model, side < 0 and "WingLeft" or "WingRight", Enum.PartType.Block, Vector3.new(0.08, 0.05, length), world, color, Enum.Material.Glass)
	part.Transparency = 0.35
	createMotor(thorax, part, part.Name .. "Joint", world, "Wing", side, side < 0 and 0 or math.pi)
end

local function buildDragonfly(player: Player, model: Model, root: BasePart)
	local c = paletteFor(player, "Dragonfly")
	local eyes = eyeStyleFor(player)
	local thorax = bodyPart(model, root, nil, "Thorax", Vector3.new(1.10, 0.90, 1.55), CFrame.new(0, 0.04, -0.45), c.accent, "BodyRoot")
	local head = bodyPart(model, root, thorax, "Head", Vector3.new(1.34, 1.02, 1.05), CFrame.new(0, 0.10, -1.58), c.body, "Head")
	local abdomen = bodyPart(model, root, thorax, "Abdomen", Vector3.new(0.78, 0.72, 3.55), CFrame.new(0, 0.06, 1.55), c.body, "Abdomen")
	bodyPart(model, root, abdomen, "TailTip", Vector3.new(0.62, 0.58, 1.18), CFrame.new(0, 0.05, 3.58), c.dark, "Abdomen")

	eye(model, root, head, Vector3.new(-0.48, 0.22, -1.94), 0.34, eyes)
	eye(model, root, head, Vector3.new(0.48, 0.22, -1.94), 0.34, eyes)
	antenna(model, root, head, -1, -1.86, -2.55, c.dark)
	antenna(model, root, head, 1, -1.86, -2.55, c.dark)

	wing(model, root, thorax, -1, 0.82, -0.10, 3.45, Color3.fromRGB(173, 232, 238))
	wing(model, root, thorax, 1, 0.82, -0.10, 3.45, Color3.fromRGB(173, 232, 238))
	wing(model, root, thorax, -1, 0.72, 0.62, 2.95, Color3.fromRGB(143, 213, 224))
	wing(model, root, thorax, 1, 0.72, 0.62, 2.95, Color3.fromRGB(143, 213, 224))

	for row, z in ipairs({ -0.68, 0.02, 0.72 }) do
		for _, side in ipairs({ -1, 1 }) do
			leg(model, root, thorax, side, row, z, 1.55, c.dark)
		end
	end
end

local function buildPillbug(player: Player, model: Model, root: BasePart)
	local c = paletteFor(player, "Pillbug")
	local eyes = eyeStyleFor(player)
	local thorax = bodyPart(model, root, nil, "Thorax", Vector3.new(1.92, 1.20, 1.40), CFrame.new(0, 0.02, -0.88), c.dark, "BodyRoot")
	local head = bodyPart(model, root, thorax, "Head", Vector3.new(1.48, 1.02, 1.10), CFrame.new(0, -0.02, -1.86), c.dark, "Head")

	local parent = thorax
	for i = 1, 6 do
		local z = -0.18 + ((i - 1) * 0.58)
		local width = 2.18 - math.abs(i - 3.5) * 0.13
		local plate = bodyPart(model, root, parent, "ShellPlate", Vector3.new(width, 1.28, 0.82), CFrame.new(0, 0.10, z), (i % 2 == 0) and c.body or c.accent, "PillbugPlate")
		local joint = plate:FindFirstChild("ShellPlateJoint")
		if joint and joint:IsA("Motor6D") then
			joint:SetAttribute("RollIndex", i)
			joint:SetAttribute("MotionPhase", i * 0.38)
		end
		parent = plate
	end

	eye(model, root, head, Vector3.new(-0.46, 0.12, -2.22), 0.23, eyes)
	eye(model, root, head, Vector3.new(0.46, 0.12, -2.22), 0.23, eyes)
	antenna(model, root, head, -1, -2.12, -2.86, c.dark)
	antenna(model, root, head, 1, -2.12, -2.86, c.dark)

	for row, z in ipairs({ -0.86, -0.16, 0.54 }) do
		for _, side in ipairs({ -1, 1 }) do
			leg(model, root, thorax, side, row, z, 1.62, c.dark)
		end
	end
end

local function replaceVisual(player: Player, model: Model)
	local bugId = model:GetAttribute("BugId")
	if bugId ~= "Dragonfly" and bugId ~= "Pillbug" then
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
	model:SetAttribute("RigVersion", 7)
	if bugId == "Dragonfly" then
		buildDragonfly(player, model, root)
	else
		buildPillbug(player, model, root)
	end
end

local function watchCharacter(player: Player, character: Model)
	local function consider(child)
		if child:IsA("Model") and child.Name == VISUAL_MODEL_NAME then
			task.delay(0.10, function()
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

function AdditionalBugAvatarService.Init()
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)
end

return AdditionalBugAvatarService
