--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local CosmeticStyles = require(BuildABugShared.Config.CosmeticStyles)

-- Roblox's hidden Humanoid/R15 character still owns movement, collision, health,
-- networking, and abilities. The visible insect is a lightweight articulated rig.

local BugAvatarService = {}
local PlayerDataService = nil

local VISUAL_MODEL_NAME = "BuildABugVisual"
local BODY_OFFSET_Y = -1.95
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

local function getPalette(player: Player, bugId: string)
	local styleId = player:GetAttribute("BodyColor") or "Natural"
	local style = CosmeticStyles.BodyColors[styleId]
	if style and not style.useBugPalette then
		return {
			body = style.body,
			dark = style.dark,
			accent = style.accent,
		}
	end
	return COLORS[bugId] or COLORS.Ant
end

local function getEyeStyle(player: Player)
	local styleId = player:GetAttribute("EyeStyle") or "Default"
	return CosmeticStyles.EyeStyles[styleId] or CosmeticStyles.EyeStyles.Default
end

local function getPatternStyle(player: Player)
	local styleId = player:GetAttribute("PatternStyle") or "None"
	return CosmeticStyles.PatternStyles[styleId] or CosmeticStyles.PatternStyles.None
end

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

local function createEye(model: Model, root: BasePart, head: BasePart, localPosition: Vector3, size: number, style)
	style = style or CosmeticStyles.EyeStyles.Default
	local actualSize = size * (style.sizeMultiplier or 1)
	local eye = createPart(
		model,
		"Eye",
		Enum.PartType.Ball,
		Vector3.new(actualSize, actualSize, actualSize),
		bodyFrame(root) * CFrame.new(localPosition),
		style.color or Color3.fromRGB(16, 16, 18),
		style.material or Enum.Material.SmoothPlastic
	)
	createStaticWeld(head, eye)

	if style.kind == "googly" then
		local pupilSize = actualSize * 0.48
		local pupilPosition = localPosition + Vector3.new(0, 0, -actualSize * 0.40)
		local pupil = createPart(
			model,
			"EyePupil",
			Enum.PartType.Ball,
			Vector3.new(pupilSize, pupilSize, pupilSize),
			bodyFrame(root) * CFrame.new(pupilPosition),
			style.pupilColor or Color3.fromRGB(18, 18, 20),
			Enum.Material.SmoothPlastic
		)
		createStaticWeld(eye, pupil)
	elseif style.kind == "glow" then
		local light = Instance.new("PointLight")
		light.Name = "EyeGlow"
		light.Color = style.color or Color3.fromRGB(73, 205, 255)
		light.Brightness = 0.7
		light.Range = 4
		light.Parent = eye
	end

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
	local basePoint = Vector3.new(side * 0.24, 0.46, startZ + 0.08)
	local bend = Vector3.new(side * 0.56, 0.78, startZ - 0.48)
	local tip = Vector3.new(side * 0.90, 0.76, reachZ)
	local phase = side < 0 and 0 or math.pi * 0.65
	local first = createSegment(model, root, head, "Antenna", basePoint, bend, 0.085, color, "Antenna", side, phase)
	createSegment(model, root, first, "AntennaTip", bend, tip, 0.07, color, "AntennaTip", side, phase)
end

local function buildAnt(model: Model, root: BasePart, c, eyeStyle)
	local thorax = createBodyPart(model, root, nil, "Thorax", Enum.PartType.Ball, Vector3.new(1.30, 1.00, 1.40), CFrame.new(0, 0, -0.30), c.accent, nil, "BodyRoot")
	local head = createBodyPart(model, root, thorax, "Head", Enum.PartType.Ball, Vector3.new(1.32, 1.02, 1.22), CFrame.new(0, 0.02, -1.62), c.body, nil, "Head")
	createBodyPart(model, root, thorax, "Abdomen", Enum.PartType.Ball, Vector3.new(1.72, 1.30, 2.20), CFrame.new(0, 0.02, 1.20), c.body, nil, "Abdomen")
	createEye(model, root, head, Vector3.new(-0.47, 0.14, -2.08), 0.24, eyeStyle)
	createEye(model, root, head, Vector3.new(0.47, 0.14, -2.08), 0.24, eyeStyle)

	for row, z in ipairs({ -0.82, 0.0, 0.82 }) do
		for _, side in ipairs({ -1, 1 }) do
			createLeg(model, root, thorax, side, row, z, 1.85, c.dark, row == 3 and 1 or 0)
		end
	end
	createAntenna(model, root, head, -1, -2.02, -3.05, c.dark)
	createAntenna(model, root, head, 1, -2.02, -3.05, c.dark)
end

local function buildBeetle(model: Model, root: BasePart, c, eyeStyle)
	local pronotum = createBodyPart(model, root, nil, "Pronotum", Enum.PartType.Ball, Vector3.new(2.00, 1.16, 1.52), CFrame.new(0, 0.03, -0.58), c.accent, nil, "BodyRoot")
	local head = createBodyPart(model, root, pronotum, "Head", Enum.PartType.Ball, Vector3.new(1.42, 1.03, 1.23), CFrame.new(0, -0.02, -1.72), c.dark, nil, "Head")
	local shell = createBodyPart(model, root, pronotum, "Shell", Enum.PartType.Ball, Vector3.new(2.62, 1.52, 3.12), CFrame.new(0, 0.12, 1.02), c.body, nil, "Shell")
	local seam = createPart(model, "ShellSeam", Enum.PartType.Block, Vector3.new(0.07, 0.07, 2.58), bodyFrame(root) * CFrame.new(0, 0.91, 1.00), c.dark, Enum.Material.SmoothPlastic)
	createStaticWeld(shell, seam)
	createEye(model, root, head, Vector3.new(-0.47, 0.10, -2.13), 0.22, eyeStyle)
	createEye(model, root, head, Vector3.new(0.47, 0.10, -2.13), 0.22, eyeStyle)

	for row, z in ipairs({ -0.72, 0.14, 0.96 }) do
		for _, side in ipairs({ -1, 1 }) do
			createLeg(model, root, pronotum, side, row, z, 1.88, c.dark, row == 3 and 1 or 0)
		end
	end
	createAntenna(model, root, head, -1, -2.06, -2.88, c.dark)
	createAntenna(model, root, head, 1, -2.06, -2.88, c.dark)
end

local function buildGrasshopper(model: Model, root: BasePart, c, eyeStyle)
	local thorax = createBodyPart(model, root, nil, "Thorax", Enum.PartType.Ball, Vector3.new(1.50, 1.12, 1.62), CFrame.new(0, 0.04, -0.50), c.body, nil, "BodyRoot")
	local head = createBodyPart(model, root, thorax, "Head", Enum.PartType.Ball, Vector3.new(1.34, 1.12, 1.22), CFrame.new(0, 0.08, -1.72), c.accent, nil, "Head")
	local abdomen = createBodyPart(model, root, thorax, "Abdomen", Enum.PartType.Ball, Vector3.new(1.42, 1.02, 2.80), CFrame.new(0, 0.04, 1.18), c.body, nil, "Abdomen")
	createEye(model, root, head, Vector3.new(-0.49, 0.18, -2.14), 0.27, eyeStyle)
	createEye(model, root, head, Vector3.new(0.49, 0.18, -2.14), 0.27, eyeStyle)

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

-- Pattern marks are flattened ellipsoids that conform to the curved surface of
-- the target body part. Keeping most of each mark just under the surface makes
-- the result read like pigmentation rather than beads or stickers resting on top.
local function getEllipsoidSurface(target: BasePart, xScale: number, zScale: number)
	local radiusX = math.max(0.01, target.Size.X * 0.5)
	local radiusY = math.max(0.01, target.Size.Y * 0.5)
	local radiusZ = math.max(0.01, target.Size.Z * 0.5)

	xScale = math.clamp(xScale, -0.82, 0.82)
	zScale = math.clamp(zScale, -0.82, 0.82)
	local x = radiusX * xScale
	local z = radiusZ * zScale
	local inside = 1 - (x * x) / (radiusX * radiusX) - (z * z) / (radiusZ * radiusZ)
	local y = radiusY * math.sqrt(math.max(0.025, inside))
	local normal = Vector3.new(
		x / (radiusX * radiusX),
		y / (radiusY * radiusY),
		z / (radiusZ * radiusZ)
	).Unit

	return Vector3.new(x, y, z), normal
end

local function getSurfaceFrame(target: BasePart, xScale: number, zScale: number, sinkAmount: number, rotationDegrees: number?)
	local position, normal = getEllipsoidSurface(target, xScale, zScale)
	local reference = Vector3.zAxis
	if math.abs(normal:Dot(reference)) > 0.92 then
		reference = Vector3.xAxis
	end

	local right = normal:Cross(reference).Unit
	local back = right:Cross(normal).Unit
	local localFrame = CFrame.fromMatrix(position - normal * sinkAmount, right, normal, back)
	if rotationDegrees then
		localFrame *= CFrame.Angles(0, math.rad(rotationDegrees), 0)
	end
	return target.CFrame * localFrame
end

local function createSurfaceMark(
	model: Model,
	target: BasePart,
	name: string,
	xScale: number,
	zScale: number,
	width: number,
	depth: number,
	color: Color3,
	material,
	rotationDegrees: number?
)
	local thickness = 0.045
	local piece = createPart(
		model,
		name,
		Enum.PartType.Ball,
		Vector3.new(width, thickness, depth),
		getSurfaceFrame(target, xScale, zScale, thickness * 0.30, rotationDegrees),
		color,
		material or Enum.Material.SmoothPlastic
	)
	piece.CastShadow = false
	createStaticWeld(target, piece)
	return piece
end

local function applyPattern(model: Model, patternStyle)
	if not patternStyle or patternStyle.kind == "none" then
		return
	end

	local target = model:FindFirstChild("Shell") or model:FindFirstChild("Abdomen") or model:FindFirstChild("Thorax") or model:FindFirstChild("Pronotum")
	if not target or not target:IsA("BasePart") then
		return
	end

	local color = patternStyle.color or Color3.fromRGB(230, 220, 170)
	local material = patternStyle.material or Enum.Material.SmoothPlastic

	if patternStyle.kind == "stripe" then
		-- Build each band from several flush marks so it follows the shell curve.
		for _, zScale in ipairs({ -0.19, 0.19 }) do
			for _, xScale in ipairs({ -0.54, -0.27, 0, 0.27, 0.54 }) do
				createSurfaceMark(
					model,
					target,
					"PatternStripe",
					xScale,
					zScale,
					target.Size.X * 0.20,
					math.max(0.16, target.Size.Z * 0.11),
					color,
					material,
					0
				)
			end
		end
	elseif patternStyle.kind == "speckles" then
		local offsets = {
			Vector2.new(-0.44, -0.24),
			Vector2.new(-0.10, -0.31),
			Vector2.new(0.34, -0.20),
			Vector2.new(-0.28, 0.02),
			Vector2.new(0.18, 0.08),
			Vector2.new(-0.06, 0.31),
			Vector2.new(0.42, 0.27),
		}
		local baseDiameter = math.max(0.15, math.min(target.Size.X, target.Size.Z) * 0.14)
		for index, offset in ipairs(offsets) do
			local scale = (index % 3 == 0) and 0.78 or ((index % 2 == 0) and 0.90 or 1)
			createSurfaceMark(
				model,
				target,
				"PatternSpeckle",
				offset.X,
				offset.Y,
				baseDiameter * scale,
				baseDiameter * scale,
				color,
				material,
				(index * 23) % 90
			)
		end
	elseif patternStyle.kind == "sunmark" then
		local mark = createSurfaceMark(
			model,
			target,
			"PatternSunmark",
			0,
			0,
			target.Size.X * 0.38,
			target.Size.Z * 0.25,
			color,
			material,
			45
		)

		for _, ray in ipairs({
			{ -0.34, 0, 90 },
			{ 0.34, 0, 90 },
			{ 0, -0.28, 0 },
			{ 0, 0.28, 0 },
			{ -0.25, -0.20, 45 },
			{ 0.25, -0.20, -45 },
			{ -0.25, 0.20, -45 },
			{ 0.25, 0.20, 45 },
		}) do
			createSurfaceMark(
				model,
				target,
				"PatternSunRay",
				ray[1],
				ray[2],
				target.Size.X * 0.12,
				target.Size.Z * 0.08,
				color,
				material,
				ray[3]
			)
		end

		local light = Instance.new("PointLight")
		light.Name = "PatternGlow"
		light.Color = color
		light.Brightness = 0.16
		light.Range = 2.2
		light.Parent = mark
	end
end

local function formatBestTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds or 0))
	if seconds <= 0 then
		return "--"
	end
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function makeTagLabel(parent: Instance, name: string, y: number, height: number, textSize: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, height)
	label.Position = UDim2.fromOffset(0, y)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
	label.TextStrokeTransparency = 0.25
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Parent = parent
	return label
end

local function createIdentityTag(player: Player, root: BasePart)
	local existing = root:FindFirstChild("PlayerIdentity")
	if existing then
		existing:Destroy()
	end

	local tag = Instance.new("BillboardGui")
	tag.Name = "PlayerIdentity"
	tag.Size = UDim2.fromOffset(280, 70)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 0.55, 0)
	tag.AlwaysOnTop = true
	tag.MaxDistance = 75
	tag.LightInfluence = 0
	tag.Adornee = root
	tag.Parent = root

	makeTagLabel(tag, "PlayerName", 0, 24, 16, Color3.fromRGB(255, 255, 255))
	makeTagLabel(tag, "Progress", 23, 22, 13, Color3.fromRGB(255, 225, 125))
	makeTagLabel(tag, "Stats", 44, 20, 11, Color3.fromRGB(220, 235, 245))
end

local function refreshIdentityTag(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	local tag = root:FindFirstChild("PlayerIdentity")
	if not tag or not tag:IsA("BillboardGui") then
		return
	end

	local nameLabel = tag:FindFirstChild("PlayerName")
	local progressLabel = tag:FindFirstChild("Progress")
	local statsLabel = tag:FindFirstChild("Stats")
	local level = player:GetAttribute("BugLevel") or 1
	local title = player:GetAttribute("BugTitle") or "Fresh Hatchling"
	local bugId = player:GetAttribute("SelectedBug") or "Ant"
	local rounds = player:GetAttribute("RoundsPlayed") or 0
	local best = player:GetAttribute("BestSurvival") or 0
	local roundWord = rounds == 1 and "round" or "rounds"

	if nameLabel and nameLabel:IsA("TextLabel") then
		nameLabel.Text = player.DisplayName
	end
	if progressLabel and progressLabel:IsA("TextLabel") then
		progressLabel.Text = string.format("Lv %s  •  %s", tostring(level), tostring(title))
	end
	if statsLabel and statsLabel:IsA("TextLabel") then
		statsLabel.Text = string.format("%s  •  %s %s  •  Best %s", tostring(bugId), tostring(rounds), roundWord, formatBestTime(best))
	end
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
	local palette = getPalette(player, selectedBug)
	local eyeStyle = getEyeStyle(player)
	local patternStyle = getPatternStyle(player)

	local model = Instance.new("Model")
	model.Name = VISUAL_MODEL_NAME
	model:SetAttribute("BugId", selectedBug)
	model:SetAttribute("RigVersion", 4)
	model.Parent = character

	if selectedBug == "Beetle" then
		buildBeetle(model, root, palette, eyeStyle)
	elseif selectedBug == "Grasshopper" then
		buildGrasshopper(model, root, palette, eyeStyle)
	else
		buildAnt(model, root, palette, eyeStyle)
	end

	applyPattern(model, patternStyle)
	createIdentityTag(player, root)
	refreshIdentityTag(player)
	hideRobloxAvatar(character)
	humanoid.CameraOffset = Vector3.new(0, CAMERA_OFFSET_Y, 0)
	pcall(function()
		humanoid.NameDisplayDistance = 0
	end)
end

local function setupPlayer(player: Player)
	for _, visualAttribute in ipairs({ "SelectedBug", "BodyColor", "EyeStyle", "PatternStyle" }) do
		player:GetAttributeChangedSignal(visualAttribute):Connect(function()
			task.defer(buildVisual, player)
		end)
	end

	for _, attributeName in ipairs({ "BugLevel", "BugTitle", "RoundsPlayed", "BestSurvival" }) do
		player:GetAttributeChangedSignal(attributeName):Connect(function()
			task.defer(refreshIdentityTag, player)
		end)
	end

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
