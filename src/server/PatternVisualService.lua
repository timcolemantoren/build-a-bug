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

local function findPart(model: Model, name: string): BasePart?
	local part = model:FindFirstChild(name, true)
	return part and part:IsA("BasePart") and part or nil
end

local function getRollIndex(part: BasePart): number
	local joint = part:FindFirstChild("ShellPlateJoint")
	if joint and joint:IsA("Motor6D") then
		return tonumber(joint:GetAttribute("RollIndex")) or 0
	end
	return 0
end

local function findTargets(model: Model)
	local bugId = model:GetAttribute("BugId") or ""
	local targets = {}

	local function add(part: BasePart?)
		if part then
			table.insert(targets, part)
		end
	end

	if bugId == "Pillbug" then
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant.Name == "ShellPlate" then
				table.insert(targets, descendant)
			end
		end
		table.sort(targets, function(a, b)
			return getRollIndex(a) < getRollIndex(b)
		end)
		return targets
	elseif bugId == "Dragonfly" then
		add(findPart(model, "Abdomen"))
		add(findPart(model, "TailTip"))
		add(findPart(model, "Thorax"))
		return targets
	elseif bugId == "Mantis" then
		add(findPart(model, "Abdomen"))
		add(findPart(model, "Thorax"))
		return targets
	end

	for _, name in ipairs({ "Shell", "Abdomen", "Thorax", "Pronotum", "ShellPlate" }) do
		local part = findPart(model, name)
		if part then
			return { part }
		end
	end
	return targets
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
	local normal = Vector3.new(x / (radiusX * radiusX), y / (radiusY * radiusY), z / (radiusZ * radiusZ)).Unit
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

local function applyStripe(model: Model, target: BasePart, color: Color3, material, compact: boolean, variant: number)
	local zScales = compact and { (variant % 2 == 0) and 0.12 or -0.12 } or { -0.19, 0.19 }
	for _, zScale in ipairs(zScales) do
		for _, xScale in ipairs({ -0.54, -0.27, 0, 0.27, 0.54 }) do
			mark(model, target, "PatternStripe", xScale, zScale, target.Size.X * 0.20, math.max(0.12, target.Size.Z * 0.11), color, material, 0)
		end
	end
end

local function applySpeckles(model: Model, target: BasePart, color: Color3, material, compact: boolean, variant: number)
	local offsets
	if compact then
		offsets = variant % 2 == 0
			and { Vector2.new(-0.42, -0.18), Vector2.new(0.18, -0.24), Vector2.new(-0.08, 0.22), Vector2.new(0.43, 0.18) }
			or { Vector2.new(-0.20, -0.28), Vector2.new(0.42, -0.14), Vector2.new(-0.43, 0.18), Vector2.new(0.14, 0.27) }
	else
		offsets = {
			Vector2.new(-0.44, -0.24), Vector2.new(-0.10, -0.31), Vector2.new(0.34, -0.20),
			Vector2.new(-0.28, 0.02), Vector2.new(0.18, 0.08), Vector2.new(-0.06, 0.31), Vector2.new(0.42, 0.27),
		}
	end
	local base = math.max(0.14, math.min(target.Size.X, target.Size.Z) * (compact and 0.18 or 0.14))
	for index, offset in ipairs(offsets) do
		local scale = (index % 3 == 0) and 0.78 or ((index % 2 == 0) and 0.90 or 1)
		mark(model, target, "PatternSpeckle", offset.X, offset.Y, base * scale, base * scale, color, material, (index * 23 + variant * 11) % 90)
	end
end

local function applyTiger(model: Model, target: BasePart, color: Color3, material, compact: boolean, variant: number)
	-- Tiger Stripe should read as a body treatment from normal play distance, not
	-- as a collection of tiny scratches. Multi-part bodies receive one broad,
	-- alternating band per segment so the pattern continues down the whole bug.
	if compact then
		local flip = variant % 2 == 0 and 1 or -1
		local zScale = ((variant - 1) % 3 - 1) * 0.10
		mark(
			model,
			target,
			"PatternTiger",
			0.02 * flip,
			zScale,
			target.Size.X * 0.68,
			math.max(0.14, target.Size.Z * 0.18),
			color,
			material,
			22 * flip
		)
		return
	end

	local stripes = {
		{ -0.12, -0.43, 24 },
		{ 0.15, -0.20, -24 },
		{ -0.14, 0.04, 23 },
		{ 0.16, 0.27, -23 },
		{ -0.10, 0.47, 21 },
	}
	for _, stripe in ipairs(stripes) do
		mark(
			model,
			target,
			"PatternTiger",
			stripe[1],
			stripe[2],
			target.Size.X * 0.64,
			math.max(0.15, target.Size.Z * 0.13),
			color,
			material,
			stripe[3]
		)
	end
end

local function applySunmark(model: Model, target: BasePart, color: Color3, material, compact: boolean)
	mark(model, target, "PatternSunmark", 0, 0, target.Size.X * (compact and 0.32 or 0.38), target.Size.Z * (compact and 0.22 or 0.25), color, material, 45)
	local rays = compact and {
		{ -0.34, 0, 90 }, { 0.34, 0, 90 }, { 0, -0.27, 0 }, { 0, 0.27, 0 },
	} or {
		{ -0.34, 0, 90 }, { 0.34, 0, 90 }, { 0, -0.28, 0 }, { 0, 0.28, 0 },
		{ -0.25, -0.20, 45 }, { 0.25, -0.20, -45 }, { -0.25, 0.20, -45 }, { 0.25, 0.20, 45 },
	}
	for _, ray in ipairs(rays) do
		mark(model, target, "PatternSunRay", ray[1], ray[2], target.Size.X * 0.16, math.max(0.07, target.Size.Z * 0.075), color, material, ray[3])
	end
end

local function applyChecker(model: Model, target: BasePart, color: Color3, material, compact: boolean, variant: number)
	local cells = {}
	if compact then
		cells = variant % 2 == 0
			and { { -0.42, -0.18 }, { 0.10, -0.18 }, { 0.38, 0.20 } }
			or { { 0.42, -0.18 }, { -0.10, -0.18 }, { -0.38, 0.20 } }
	else
		for row, z in ipairs({ -0.34, 0, 0.34 }) do
			for col, x in ipairs({ -0.48, -0.16, 0.16, 0.48 }) do
				if (row + col) % 2 == 0 then
					table.insert(cells, { x, z })
				end
			end
	end
	for _, cell in ipairs(cells) do
		mark(model, target, "PatternChecker", cell[1], cell[2], target.Size.X * (compact and 0.20 or 0.18), math.max(0.11, target.Size.Z * (compact and 0.18 or 0.14)), color, material, 45)
	end
end

local function applyBands(model: Model, target: BasePart, color: Color3, material, compact: boolean, variant: number)
	local zScales = compact and { ((variant - 1) % 3 - 1) * 0.18 } or { -0.42, 0, 0.42 }
	for _, zScale in ipairs(zScales) do
		for _, xScale in ipairs({ -0.50, -0.25, 0, 0.25, 0.50 }) do
			mark(model, target, "PatternBand", xScale, zScale, target.Size.X * 0.19, math.max(0.10, target.Size.Z * 0.075), color, material, 0)
		end
	end
end

local function applyDots(model: Model, target: BasePart, color: Color3, material, compact: boolean, variant: number)
	local offsets
	if compact then
		offsets = variant % 2 == 0
			and { Vector2.new(-0.42, -0.20), Vector2.new(0.32, -0.02), Vector2.new(-0.08, 0.27) }
			or { Vector2.new(0.42, -0.20), Vector2.new(-0.32, -0.02), Vector2.new(0.08, 0.27) }
	else
		offsets = {
			Vector2.new(-0.48, -0.32), Vector2.new(0, -0.35), Vector2.new(0.48, -0.32),
			Vector2.new(-0.30, 0), Vector2.new(0.30, 0),
			Vector2.new(-0.48, 0.32), Vector2.new(0, 0.35), Vector2.new(0.48, 0.32),
		}
	end
	local diameter = math.max(0.17, math.min(target.Size.X, target.Size.Z) * (compact and 0.24 or 0.18))
	for _, offset in ipairs(offsets) do
		mark(model, target, "PatternDot", offset.X, offset.Y, diameter, diameter, color, material, 0)
	end
end

local function applyChevron(model: Model, target: BasePart, color: Color3, material, compact: boolean, variant: number)
	local rows = compact and { ((variant - 1) % 3 - 1) * 0.18 } or { -0.34, 0, 0.34 }
	for _, z in ipairs(rows) do
		mark(model, target, "PatternChevron", -0.20, z, target.Size.X * 0.32, math.max(0.08, target.Size.Z * 0.06), color, material, -34)
		mark(model, target, "PatternChevron", 0.20, z, target.Size.X * 0.32, math.max(0.08, target.Size.Z * 0.06), color, material, 34)
	end
end

local function applyWeb(model: Model, target: BasePart, color: Color3, material, compact: boolean, variant: number)
	local rotations = compact and { (variant % 2 == 0) and 25 or -25, (variant % 2 == 0) and 115 or 65 } or { 0, 45, 90, 135 }
	for _, rotation in ipairs(rotations) do
		mark(model, target, "PatternWebSpoke", 0, 0, target.Size.X * (compact and 0.48 or 0.58), math.max(0.07, target.Size.Z * 0.045), color, material, rotation)
	end
	local offsets = compact and { Vector2.new(-0.34, -0.16), Vector2.new(0.34, 0.16) } or {
		Vector2.new(-0.36, -0.25), Vector2.new(0.36, -0.25), Vector2.new(-0.36, 0.25), Vector2.new(0.36, 0.25),
	}
	for _, offset in ipairs(offsets) do
		mark(model, target, "PatternWebNode", offset.X, offset.Y, target.Size.X * 0.12, math.max(0.08, target.Size.Z * 0.10), color, material, 45)
	end
end

local function applyConfetti(model: Model, target: BasePart, style, material, compact: boolean, variant: number)
	local colors = {
		style.color or Color3.fromRGB(255, 112, 190),
		style.secondaryColor or Color3.fromRGB(80, 221, 235),
		style.tertiaryColor or Color3.fromRGB(255, 214, 73),
	}
	local pieces = compact and {
		{ -0.38, -0.20, -28 }, { 0.05, 0.02, 32 }, { 0.38, 0.22, -40 },
	} or {
		{ -0.50, -0.30, -24 }, { -0.14, -0.34, 35 }, { 0.28, -0.26, 65 }, { 0.51, -0.04, -35 },
		{ -0.38, 0.04, 52 }, { 0.04, 0.10, -54 }, { 0.40, 0.18, 28 }, { -0.20, 0.34, -18 }, { 0.22, 0.36, 70 },
	}
	for index, piece in ipairs(pieces) do
		local pieceColor = colors[((index + variant - 2) % #colors) + 1]
		mark(model, target, "PatternConfetti", piece[1], piece[2], target.Size.X * (compact and 0.18 or 0.16), math.max(0.08, target.Size.Z * 0.07), pieceColor, material, piece[3])
	end
end

local function applyCircuit(model: Model, target: BasePart, color: Color3, material, compact: boolean, variant: number)
	local lines
	local nodes
	if compact then
		local flip = variant % 2 == 0 and 1 or -1
		lines = { { -0.30 * flip, -0.22, 0 }, { 0.02, -0.02, 90 }, { 0.30 * flip, 0.20, 0 } }
		nodes = { Vector2.new(-0.45 * flip, -0.22), Vector2.new(0.42 * flip, 0.20) }
	else
		lines = {
			{ -0.34, -0.28, 0 }, { -0.12, -0.08, 90 }, { 0.18, -0.08, 0 },
			{ 0.34, 0.20, 90 }, { 0.05, 0.30, 0 }, { -0.30, 0.24, 90 },
		}
		nodes = { Vector2.new(-0.48, -0.28), Vector2.new(0.34, -0.08), Vector2.new(0.34, 0.38), Vector2.new(-0.30, 0.42) }
	end
	for _, line in ipairs(lines) do
		mark(model, target, "PatternCircuitLine", line[1], line[2], target.Size.X * (compact and 0.25 or 0.28), math.max(0.07, target.Size.Z * 0.055), color, material, line[3])
	end
	for _, node in ipairs(nodes) do
		mark(model, target, "PatternCircuitNode", node.X, node.Y, target.Size.X * 0.13, math.max(0.08, target.Size.Z * 0.10), color, material, 0)
	end
end

local function applyPatternToTarget(model: Model, target: BasePart, style, color: Color3, material, compact: boolean, variant: number)
	if style.kind == "stripe" then
		applyStripe(model, target, color, material, compact, variant)
	elseif style.kind == "speckles" then
		applySpeckles(model, target, color, material, compact, variant)
	elseif style.kind == "tiger" then
		applyTiger(model, target, color, material, compact, variant)
	elseif style.kind == "sunmark" then
		applySunmark(model, target, color, material, compact)
	elseif style.kind == "checker" then
		applyChecker(model, target, color, material, compact, variant)
	elseif style.kind == "bands" then
		applyBands(model, target, color, material, compact, variant)
	elseif style.kind == "dots" then
		applyDots(model, target, color, material, compact, variant)
	elseif style.kind == "chevron" then
		applyChevron(model, target, color, material, compact, variant)
	elseif style.kind == "web" then
		applyWeb(model, target, color, material, compact, variant)
	elseif style.kind == "confetti" then
		applyConfetti(model, target, style, material, compact, variant)
	elseif style.kind == "circuit" then
		applyCircuit(model, target, color, material, compact, variant)
	end
end

local function applyPattern(player: Player, model: Model)
	clearPatternParts(model)
	local styleId = player:GetAttribute("PatternStyle") or "None"
	local style = CosmeticStyles.PatternStyles[styleId] or CosmeticStyles.PatternStyles.None
	if style.kind == "none" then
		return
	end

	local targets = findTargets(model)
	if #targets == 0 then
		return
	end
	local color = style.color or Color3.fromRGB(230, 220, 170)
	local material = style.material or Enum.Material.SmoothPlastic
	local compact = #targets > 1

	for index, target in ipairs(targets) do
		applyPatternToTarget(model, target, style, color, material, compact, index)
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
