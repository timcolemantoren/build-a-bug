--!nonstrict

local Players = game:GetService("Players")

-- First-pass bug avatar system.
-- We intentionally keep Roblox's Humanoid/R15 controller underneath for movement,
-- networking, health, jumping, hazards, and abilities. The normal avatar is hidden
-- and a lightweight stylized bug body is welded to HumanoidRootPart.
--
-- This is a gameplay/proportion proxy, not the final animated insect rig.

local BugAvatarService = {}
local PlayerDataService = nil

local VISUAL_MODEL_NAME = "BuildABugVisual"
local BODY_OFFSET_Y = -2.15

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
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if not descendant:IsDescendantOf(character:FindFirstChild(VISUAL_MODEL_NAME)) then
				descendant.Transparency = 1
			end
		elseif descendant:IsA("Decal") then
			descendant.Transparency = 1
		elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
			-- Accessories occasionally carry effects that would reveal the hidden avatar.
			descendant.Enabled = false
		end
	end
end

local function weldToRoot(root: BasePart, part: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "BugVisualWeld"
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
end

local function makePart(model: Model, root: BasePart, name: string, shape, size: Vector3, localCFrame: CFrame, color: Color3, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape or Enum.PartType.Block
	part.Size = size
	part.CFrame = root.CFrame * CFrame.new(0, BODY_OFFSET_Y, 0) * localCFrame
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Parent = model
	weldToRoot(root, part)
	return part
end

local function makeEye(model: Model, root: BasePart, localPosition: Vector3, size: number)
	return makePart(
		model,
		root,
		"Eye",
		Enum.PartType.Ball,
		Vector3.new(size, size, size),
		CFrame.new(localPosition),
		Color3.fromRGB(16, 16, 18),
		Enum.Material.SmoothPlastic
	)
end

local function makeSegment(model: Model, root: BasePart, name: string, localA: Vector3, localB: Vector3, thickness: number, color: Color3)
	local bodyCFrame = root.CFrame * CFrame.new(0, BODY_OFFSET_Y, 0)
	local worldA = bodyCFrame:PointToWorldSpace(localA)
	local worldB = bodyCFrame:PointToWorldSpace(localB)
	local direction = worldB - worldA
	local length = direction.Magnitude
	if length <= 0.01 then
		return nil
	end

	local right = direction.Unit
	local referenceUp = Vector3.yAxis
	if math.abs(right:Dot(referenceUp)) > 0.94 then
		referenceUp = Vector3.zAxis
	end
	local back = right:Cross(referenceUp).Unit
	local up = back:Cross(right).Unit
	local midpoint = (worldA + worldB) / 2

	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(length, thickness, thickness)
	part.CFrame = CFrame.fromMatrix(midpoint, right, up, back)
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = true
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = model
	weldToRoot(root, part)
	return part
end

local function makeLeg(model: Model, root: BasePart, side: number, z: number, reach: number, color: Color3, rear: boolean?)
	local hip = Vector3.new(side * 0.7, -0.05, z)
	local knee = Vector3.new(side * reach * 0.62, -0.45, z + (rear and 0.45 or 0))
	local foot = Vector3.new(side * reach, -0.82, z + (rear and 0.9 or -0.15))
	makeSegment(model, root, "LegUpper", hip, knee, 0.16, color)
	makeSegment(model, root, "LegLower", knee, foot, 0.13, color)
end

local function makeAntenna(model: Model, root: BasePart, side: number, startZ: number, reachZ: number, color: Color3)
	local base = Vector3.new(side * 0.38, 0.16, startZ)
	local bend = Vector3.new(side * 0.58, 0.40, startZ - 0.55)
	local tip = Vector3.new(side * 0.82, 0.55, reachZ)
	makeSegment(model, root, "Antenna", base, bend, 0.09, color)
	makeSegment(model, root, "AntennaTip", bend, tip, 0.075, color)
end

local function buildAnt(model: Model, root: BasePart)
	local c = COLORS.Ant
	makePart(model, root, "Head", Enum.PartType.Ball, Vector3.new(1.35, 1.05, 1.25), CFrame.new(0, 0, -1.65), c.body)
	makePart(model, root, "Thorax", Enum.PartType.Ball, Vector3.new(1.35, 1.05, 1.45), CFrame.new(0, 0, -0.35), c.accent)
	makePart(model, root, "Abdomen", Enum.PartType.Ball, Vector3.new(1.75, 1.35, 2.25), CFrame.new(0, 0.02, 1.25), c.body)
	makeEye(model, root, Vector3.new(-0.48, 0.14, -2.12), 0.24)
	makeEye(model, root, Vector3.new(0.48, 0.14, -2.12), 0.24)

	for _, z in ipairs({ -0.85, 0.0, 0.85 }) do
		makeLeg(model, root, -1, z, 1.8, c.dark, z > 0.5)
		makeLeg(model, root, 1, z, 1.8, c.dark, z > 0.5)
	end
	makeAntenna(model, root, -1, -2.05, -3.0, c.dark)
	makeAntenna(model, root, 1, -2.05, -3.0, c.dark)
end

local function buildBeetle(model: Model, root: BasePart)
	local c = COLORS.Beetle
	makePart(model, root, "Head", Enum.PartType.Ball, Vector3.new(1.45, 1.05, 1.25), CFrame.new(0, -0.02, -1.75), c.dark)
	makePart(model, root, "Pronotum", Enum.PartType.Ball, Vector3.new(2.05, 1.20, 1.55), CFrame.new(0, 0.05, -0.65), c.accent)
	makePart(model, root, "Shell", Enum.PartType.Ball, Vector3.new(2.65, 1.55, 3.15), CFrame.new(0, 0.12, 1.05), c.body, Enum.Material.SmoothPlastic)
	makePart(model, root, "ShellSeam", Enum.PartType.Block, Vector3.new(0.08, 0.08, 2.65), CFrame.new(0, 0.93, 1.02), c.dark)
	makeEye(model, root, Vector3.new(-0.48, 0.10, -2.17), 0.22)
	makeEye(model, root, Vector3.new(0.48, 0.10, -2.17), 0.22)

	for _, z in ipairs({ -0.75, 0.15, 1.0 }) do
		makeLeg(model, root, -1, z, 1.85, c.dark, z > 0.6)
		makeLeg(model, root, 1, z, 1.85, c.dark, z > 0.6)
	end
	makeAntenna(model, root, -1, -2.10, -2.85, c.dark)
	makeAntenna(model, root, 1, -2.10, -2.85, c.dark)
end

local function buildGrasshopper(model: Model, root: BasePart)
	local c = COLORS.Grasshopper
	makePart(model, root, "Head", Enum.PartType.Ball, Vector3.new(1.35, 1.15, 1.25), CFrame.new(0, 0.05, -1.75), c.accent)
	makePart(model, root, "Thorax", Enum.PartType.Ball, Vector3.new(1.55, 1.15, 1.65), CFrame.new(0, 0.05, -0.55), c.body)
	makePart(model, root, "Abdomen", Enum.PartType.Ball, Vector3.new(1.45, 1.05, 2.85), CFrame.new(0, 0.05, 1.25), c.body)
	makePart(model, root, "WingLeft", Enum.PartType.Block, Vector3.new(0.18, 0.08, 2.45), CFrame.new(-0.45, 0.66, 0.8) * CFrame.Angles(0, math.rad(-8), math.rad(-8)), c.accent)
	makePart(model, root, "WingRight", Enum.PartType.Block, Vector3.new(0.18, 0.08, 2.45), CFrame.new(0.45, 0.66, 0.8) * CFrame.Angles(0, math.rad(8), math.rad(8)), c.accent)
	makeEye(model, root, Vector3.new(-0.50, 0.17, -2.18), 0.27)
	makeEye(model, root, Vector3.new(0.50, 0.17, -2.18), 0.27)

	-- Four smaller walking legs.
	for _, z in ipairs({ -0.75, 0.15 }) do
		makeLeg(model, root, -1, z, 1.75, c.dark, false)
		makeLeg(model, root, 1, z, 1.75, c.dark, false)
	end

	-- Signature oversized rear jumping legs.
	for _, side in ipairs({ -1, 1 }) do
		local hip = Vector3.new(side * 0.62, -0.02, 0.95)
		local knee = Vector3.new(side * 1.75, 0.15, 1.95)
		local foot = Vector3.new(side * 2.55, -0.82, 2.75)
		makeSegment(model, root, "HindLegThigh", hip, knee, 0.28, c.accent)
		makeSegment(model, root, "HindLegShin", knee, foot, 0.18, c.dark)
	end

	makeAntenna(model, root, -1, -2.05, -3.35, c.dark)
	makeAntenna(model, root, 1, -2.05, -3.35, c.dark)
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
	model.Parent = character

	if selectedBug == "Beetle" then
		buildBeetle(model, root)
	elseif selectedBug == "Grasshopper" then
		buildGrasshopper(model, root)
	else
		buildAnt(model, root)
	end

	hideRobloxAvatar(character)

	-- Keep the camera/body closer to the ground while retaining Humanoid movement.
	humanoid.CameraOffset = Vector3.new(0, -1.35, 0)
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
