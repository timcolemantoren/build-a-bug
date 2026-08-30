--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local CosmeticStyles = require(BuildABugShared.Config.CosmeticStyles)

local TigerPatternPolishService = {}
local VISUAL_MODEL_NAME = "BuildABugVisual"

local function clearTigerParts(model: Model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "PatternTiger" then
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

local function surfaceFrame(target: BasePart, xScale: number, zScale: number, rotation: number?)
	local position, normal = ellipsoidSurface(target, xScale, zScale)
	local reference = Vector3.zAxis
	if math.abs(normal:Dot(reference)) > 0.92 then
		reference = Vector3.xAxis
	end
	local right = normal:Cross(reference).Unit
	local back = right:Cross(normal).Unit

	-- Sink almost half the very thin mark into the shell so it reads as pigment,
	-- not a decal hovering above the bug.
	local frame = CFrame.fromMatrix(position - normal * 0.016, right, normal, back)
	if rotation then
		frame *= CFrame.Angles(0, math.rad(rotation), 0)
	end
	return target.CFrame * frame
end

local function mark(model: Model, target: BasePart, xScale: number, zScale: number, width: number, depth: number, color: Color3, rotation: number)
	local piece = Instance.new("Part")
	piece.Name = "PatternTiger"
	piece.Shape = Enum.PartType.Ball
	piece.Size = Vector3.new(width, 0.035, depth)
	piece.CFrame = surfaceFrame(target, xScale, zScale, rotation)
	piece.Color = color
	piece.Material = Enum.Material.SmoothPlastic
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
end

local function makeTigerBand(model: Model, target: BasePart, zScale: number, flip: number, color: Color3)
	local depth = math.max(0.065, target.Size.Z * 0.052)
	local leftWidth = target.Size.X * (flip > 0 and 0.27 or 0.22)
	local rightWidth = target.Size.X * (flip > 0 and 0.22 or 0.27)

	-- Three slightly angled pieces form one tapered cross-body stripe. From normal
	-- play distance the pieces visually merge into a wrapped band instead of a blob.
	mark(model, target, 0, zScale, target.Size.X * 0.34, depth, color, flip * 3)
	mark(model, target, -0.36, zScale + (0.018 * flip), leftWidth, depth * 0.86, color, flip * -12)
	mark(model, target, 0.36, zScale - (0.018 * flip), rightWidth, depth * 0.86, color, flip * 12)
end

local function stripePositions(model: Model, target: BasePart, targetCount: number, variant: number)
	local bugId = model:GetAttribute("BugId") or ""
	if bugId == "Pillbug" then
		-- One narrow band per shell plate creates the classic repeated striped back.
		return { variant % 2 == 0 and 0.03 or -0.03 }
	end

	if targetCount > 1 then
		-- Long, multipart insects need several narrow stripes on each major body
		-- section. This avoids the old Mantis/Dragonfly "two giant lines" problem.
		if target.Size.Z >= 1.6 then
			return { -0.48, 0, 0.48 }
		end
		return { -0.30, 0.30 }
	end

	-- Single-shell bugs can carry a fuller tiger rhythm without visual clutter.
	return { -0.54, -0.18, 0.18, 0.54 }
end

local function applyTiger(player: Player, model: Model)
	clearTigerParts(model)
	if (player:GetAttribute("PatternStyle") or "None") ~= "TigerStripe" then
		return
	end

	local style = CosmeticStyles.PatternStyles.TigerStripe
	local color = style and style.color or Color3.fromRGB(38, 31, 28)
	local targets = findTargets(model)
	local targetCount = #targets

	for variant, target in ipairs(targets) do
		local positions = stripePositions(model, target, targetCount, variant)
		for stripeIndex, zScale in ipairs(positions) do
			local flip = ((variant + stripeIndex) % 2 == 0) and 1 or -1
			makeTigerBand(model, target, zScale, flip, color)
		end
	end
end

local function refresh(player: Player)
	local character = player.Character
	local model = character and character:FindFirstChild(VISUAL_MODEL_NAME)
	if model and model:IsA("Model") then
		applyTiger(player, model)
	end
end

local function scheduleRefresh(player: Player, delaySeconds: number?)
	task.delay(delaySeconds or 0.42, function()
		refresh(player)
	end)
end

local function watchCharacter(player: Player, character: Model)
	local function consider(child)
		if child:IsA("Model") and child.Name == VISUAL_MODEL_NAME then
			scheduleRefresh(player, 0.42)
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
		scheduleRefresh(player, 0.42)
	end)
	player:GetAttributeChangedSignal("SelectedBug"):Connect(function()
		scheduleRefresh(player, 0.44)
	end)
	player.CharacterAdded:Connect(function(character)
		watchCharacter(player, character)
	end)
	if player.Character then
		watchCharacter(player, player.Character)
	end
end

function TigerPatternPolishService.Init()
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)
end

return TigerPatternPolishService
