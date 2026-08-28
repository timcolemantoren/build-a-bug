--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local CosmeticStyles = require(BuildABugShared.Config.CosmeticStyles)

local PatternVisualService = {}
local VISUAL_MODEL_NAME = "BuildABugVisual"

local function clearPatternParts(model: Model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and string.sub(descendant.Name, 1, 7) == "Pattern" then
			descendant:Destroy()
		end
	end
end

local function findTarget(model: Model): BasePart?
	for _, name in ipairs({ "Shell", "Abdomen", "ShellPlate", "Thorax", "Pronotum" }) do
		local part = model:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

local function ellipsoidSurface(target: BasePart, xScale: number, zScale: number)
	local radiusX = math.max(0.01, target.Size.X * 0.5)
	local radiusY = math.max(0.01, target.Size.Y * 0.5)
	local radiusZ = math.max(0.01, target.Size.Z * 0.5)

	xScale = math.clamp(xScale, -0.80, 0.80)
	zScale = math.clamp(zScale, -0.80, 0.80)
	local x = radiusX * xScale
	local z = radiusZ * zScale
	local inside = 1 - (x * x) / (radiusX * radiusX) - (z * z) / (radiusZ * radiusZ)
	local y = radiusY * math.sqrt(math.max(0.03, inside))
	local normal = Vector3.new(
		x / (radiusX * radiusX),
		y / (radiusY * radiusY),
		z / (radiusZ * radiusZ)
	).Unit
	return Vector3.new(x, y, z), normal
end

local function surfaceFrame(target: BasePart, xScale: number, zScale: number, sink: number, rotation: number?)
	local position, normal = ellipsoidSurface(target, xScale, zScale)
	local reference = Vector3.zAxis
	if math.abs(normal:Dot(reference)) > 0.92 then
		reference = Vector3.xAxis
	end
	local right = normal:Cross(reference).Unit
	local back = right:Cross(normal).Unit
	local frame = CFrame.fromMatrix(position - normal * sink, right, normal, back)
	if rotation then
		frame *= CFrame.Angles(0, math.rad(rotation), 0)
	end
	return target.CFrame * frame
end

local function mark(model: Model, target: BasePart, name: string, xScale: number, zScale: number, width: number, depth: number, color: Color3, material, rotation: number?)
	local thickness = 0.045
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Shape = Enum.PartType.Ball
	piece.Size = Vector3.new(width, thickness, depth)
	piece.CFrame = surfaceFrame(target, xScale, zScale, thickness * 0.30, rotation)
	piece.Color = color
	piece.Material = material or Enum.Material.SmoothPlastic
	piece.Anchored = false
	piece.Massless = true
	piece.CanCollide = false
	piece.CanTouch = false
	piece.CanQuery = false
	piece.CastShadow = false
	piece.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = target
	weld.Part1 = piece
	weld.Parent = piece
	return piece
end

local function applyStripe(model: Model, target: BasePart, color: Color3, material)
	for _, zScale in ipairs({ -0.19, 0.19 }) do
		for _, xScale in ipairs({ -0.54, -0.27, 0, 0.27, 0.54 }) do
			mark(model, target, "PatternStripe", xScale, zScale, target.Size.X * 0.20, math.max(0.16, target.Size.Z * 0.11), color, material, 0)
		end
	end
end

local function applySpeckles(model: Model, target: BasePart, color: Color3, material)
	local offsets = {
		Vector2.new(-0.44, -0.24), Vector2.new(-0.10, -0.31), Vector2.new(0.34, -0.20),
		Vector2.new(-0.28, 0.02), Vector2.new(0.18, 0.08), Vector2.new(-0.06, 0.31), Vector2.new(0.42, 0.27),
	}
	local base = math.max(0.15, math.min(target.Size.X, target.Size.Z) * 0.14)
	for index, offset in ipairs(offsets) do
		local scale = (index % 3 == 0) and 0.78 or ((index % 2 == 0) and 0.90 or 1)
		mark(model, target, "PatternSpeckle", offset.X, offset.Y, base * scale, base * scale, color, material, (index * 23) % 90)
	end
end

local function applySunmark(model: Model, target: BasePart, color: Color3, material)
	mark(model, target, "PatternSunmark", 0, 0, target.Size.X * 0.38, target.Size.Z * 0.25, color, material, 45)
	for _, ray in ipairs({
		{ -0.34, 0, 90 }, { 0.34, 0, 90 }, { 0, -0.28, 0 }, { 0, 0.28, 0 },
		{ -0.25, -0.20, 45 }, { 0.25, -0.20, -45 }, { -0.25, 0.20, -45 }, { 0.25, 0.20, 45 },
	}) do
		mark(model, target, "PatternSunRay", ray[1], ray[2], target.Size.X * 0.16, target.Size.Z * 0.075, color, material, ray[3])
	end
end

local function applyBands(model: Model, target: BasePart, color: Color3, material)
	for _, zScale in ipairs({ -0.42, 0, 0.42 }) do
		for _, xScale in ipairs({ -0.50, -0.25, 0, 0.25, 0.50 }) do
			mark(model, target, "PatternBand", xScale, zScale, target.Size.X * 0.19, math.max(0.12, target.Size.Z * 0.075), color, material, 0)
		end
	end
end

local function applyDots(model: Model, target: BasePart, color: Color3, material)
	local offsets = {
		Vector2.new(-0.48, -0.32), Vector2.new(0, -0.35), Vector2.new(0.48, -0.32),
		Vector2.new(-0.30, 0), Vector2.new(0.30, 0),
		Vector2.new(-0.48, 0.32), Vector2.new(0, 0.35), Vector2.new(0.48, 0.32),
	}
	local diameter = math.max(0.18, math.min(target.Size.X, target.Size.Z) * 0.18)
	for _, offset in ipairs(offsets) do
		mark(model, target, "PatternDot", offset.X, offset.Y, diameter, diameter, color, material, 0)
	end
end

local function applyWeb(model: Model, target: BasePart, color: Color3, material)
	for _, rotation in ipairs({ 0, 45, 90, 135 }) do
		mark(model, target, "PatternWebSpoke", 0, 0, target.Size.X * 0.58, math.max(0.07, target.Size.Z * 0.045), color, material, rotation)
	end
	for _, offset in ipairs({
		Vector2.new(-0.36, -0.25), Vector2.new(0.36, -0.25), Vector2.new(-0.36, 0.25), Vector2.new(0.36, 0.25),
	}) do
		mark(model, target, "PatternWebNode", offset.X, offset.Y, target.Size.X * 0.12, target.Size.Z * 0.10, color, material, 45)
	end
end

local function applyCircuit(model: Model, target: BasePart, color: Color3, material)
	for _, line in ipairs({
		{ -0.34, -0.28, 0 }, { -0.12, -0.08, 90 }, { 0.18, -0.08, 0 },
		{ 0.34, 0.20, 90 }, { 0.05, 0.30, 0 }, { -0.30, 0.24, 90 },
	}) do
		mark(model, target, "PatternCircuitLine", line[1], line[2], target.Size.X * 0.28, math.max(0.07, target.Size.Z * 0.055), color, material, line[3])
	end
	for _, node in ipairs({ Vector2.new(-0.48, -0.28), Vector2.new(0.34, -0.08), Vector2.new(0.34, 0.38), Vector2.new(-0.30, 0.42) }) do
		mark(model, target, "PatternCircuitNode", node.X, node.Y, target.Size.X * 0.13, target.Size.Z * 0.10, color, material, 0)
	end
end

local function applyPattern(player: Player, model: Model)
	clearPatternParts(model)
	local styleId = player:GetAttribute("PatternStyle") or "None"
	local style = CosmeticStyles.PatternStyles[styleId] or CosmeticStyles.PatternStyles.None
	if style.kind == "none" then
		return
	end

	local target = findTarget(model)
	if not target then
		return
	end
	local color = style.color or Color3.fromRGB(230, 220, 170)
	local material = style.material or Enum.Material.SmoothPlastic

	if style.kind == "stripe" then
		applyStripe(model, target, color, material)
	elseif style.kind == "speckles" then
		applySpeckles(model, target, color, material)
	elseif style.kind == "sunmark" then
		applySunmark(model, target, color, material)
	elseif style.kind == "bands" then
		applyBands(model, target, color, material)
	elseif style.kind == "dots" then
		applyDots(model, target, color, material)
	elseif style.kind == "web" then
		applyWeb(model, target, color, material)
	elseif style.kind == "circuit" then
		applyCircuit(model, target, color, material)
	end
end

local function refresh(player: Player)
	local character = player.Character
	local model = character and character:FindFirstChild(VISUAL_MODEL_NAME)
	if model and model:IsA("Model") then
		applyPattern(player, model)
	end
end

local function watchCharacter(player: Player, character: Model)
	local function consider(child)
		if child:IsA("Model") and child.Name == VISUAL_MODEL_NAME then
			task.delay(0.30, function()
				if child.Parent then
					applyPattern(player, child)
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
	player:GetAttributeChangedSignal("PatternStyle"):Connect(function()
		task.delay(0.30, refresh, player)
	end)
	player:GetAttributeChangedSignal("SelectedBug"):Connect(function()
		task.delay(0.32, refresh, player)
	end)
	player.CharacterAdded:Connect(function(character)
		watchCharacter(player, character)
	end)
	if player.Character then
		watchCharacter(player, player.Character)
	end
end

function PatternVisualService.Init()
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)
end

return PatternVisualService
