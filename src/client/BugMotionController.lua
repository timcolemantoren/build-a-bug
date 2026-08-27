--!nonstrict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Lightweight procedural animation for articulated proxy bugs.
-- Every client animates visible Motor6Ds locally, including other players.
-- Gameplay position, collision, Humanoid state, and server authority are untouched.

local BugMotionController = {}

local VISUAL_MODEL_NAME = "BuildABugVisual"
local UPDATE_INTERVAL = 1 / 30

local tracked = setmetatable({}, { __mode = "k" })
local accumulator = 0

local function addMotor(record, instance: Instance)
	if instance:IsA("Motor6D") and instance:GetAttribute("MotionRole") then
		for _, existing in ipairs(record.motors) do
			if existing == instance then
				return
			end
		end
		table.insert(record.motors, instance)
		record.baseC0[instance] = instance.C0
	end
end

local function trackVisual(model: Model)
	if tracked[model] then
		return
	end

	local character = model.Parent
	if not character or not character:IsA("Model") then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		return
	end

	local record = {
		model = model,
		humanoid = humanoid,
		root = root,
		motors = {},
		baseC0 = {},
		airBlend = 0,
		gaitCycle = 0,
		lastUpdate = os.clock(),
	}
	tracked[model] = record

	for _, descendant in ipairs(model:GetDescendants()) do
		addMotor(record, descendant)
	end
	model.DescendantAdded:Connect(function(descendant)
		addMotor(record, descendant)
	end)

	if RunService:IsStudio() then
		task.delay(0.25, function()
			if model.Parent then
				print(string.format("[Build a Bug] Articulated %s rig: %d animated joints", tostring(model:GetAttribute("BugId")), #record.motors))
			end
		end)
	end
end

local function trackCharacter(character: Model)
	local existing = character:FindFirstChild(VISUAL_MODEL_NAME)
	if existing and existing:IsA("Model") then
		trackVisual(existing)
	end

	character.ChildAdded:Connect(function(child)
		if child:IsA("Model") and child.Name == VISUAL_MODEL_NAME then
			task.defer(trackVisual, child)
		end
	end)
end

local function trackPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		task.defer(trackCharacter, character)
	end)
	if player.Character then
		trackCharacter(player.Character)
	end
end

local function bodyRootMotion(now: number, moving: boolean, grounded: boolean, cycle: number, bugId: string, verticalVelocity: number, airBlend: number): CFrame
	local bobAmplitude = 0.018
	if moving and grounded then
		if bugId == "Beetle" then
			bobAmplitude = 0.035
		elseif bugId == "Grasshopper" then
			bobAmplitude = 0.060
		else
			bobAmplitude = 0.052
		end
	end

	local bob = moving and grounded and math.sin(cycle * 2) * bobAmplitude or math.sin(now * 2.2) * 0.014
	local pitch = 0
	if airBlend > 0.01 then
		local normalizedVertical = math.clamp(verticalVelocity / 55, -1, 1)
		if bugId == "Grasshopper" then
			pitch = -normalizedVertical * 6.5 * airBlend
		else
			pitch = -normalizedVertical * 3.5 * airBlend
		end
	end
	return CFrame.new(0, bob, 0) * CFrame.Angles(math.rad(pitch), 0, 0)
end

local function jointMotion(motor: Motor6D, now: number, moving: boolean, grounded: boolean, cycle: number, bugId: string, verticalVelocity: number, airBlend: number): CFrame
	local role = motor:GetAttribute("MotionRole") or ""
	local side = motor:GetAttribute("MotionSide") or 0
	local phase = motor:GetAttribute("MotionPhase") or 0

	if role == "BodyRoot" then
		return bodyRootMotion(now, moving, grounded, cycle, bugId, verticalVelocity, airBlend)
	elseif role == "LegUpper" then
		if moving and grounded then
			local stride = math.sin(cycle + phase)
			local lift = math.max(0, math.sin(cycle + phase + 0.45))
			return CFrame.Angles(math.rad(lift * -7), math.rad(stride * 27), math.rad(side * -lift * 12))
		end
		local idle = math.sin(now * 1.3 + phase)
		return CFrame.Angles(0, math.rad(idle * 2.5), math.rad(side * idle * 1.5))
	elseif role == "LegLower" then
		if moving and grounded then
			local stride = math.sin(cycle + phase)
			local lift = math.max(0, math.sin(cycle + phase + 0.45))
			return CFrame.Angles(math.rad(lift * 15), math.rad(stride * -17), math.rad(side * lift * 16))
		end
		return CFrame.new()
	elseif role == "HindLegThigh" then
		if bugId == "Grasshopper" and airBlend > 0.01 then
			local rise = math.clamp(verticalVelocity / 55, 0, 1)
			local tuck = 14 + (rise * 10)
			return CFrame.Angles(
				math.rad(-tuck * airBlend),
				math.rad(side * 10 * airBlend),
				math.rad(side * -8 * airBlend)
			)
		elseif moving then
			local stride = math.sin(cycle + phase)
			return CFrame.Angles(math.rad(stride * 8), math.rad(stride * 20), math.rad(side * -5))
		end
		return CFrame.new()
	elseif role == "HindLegShin" then
		if bugId == "Grasshopper" and airBlend > 0.01 then
			local rise = math.clamp(verticalVelocity / 55, 0, 1)
			local tuck = 15 + (rise * 8)
			return CFrame.Angles(
				math.rad(tuck * airBlend),
				math.rad(side * -9 * airBlend),
				math.rad(side * 6 * airBlend)
			)
		elseif moving then
			local stride = math.sin(cycle + phase)
			return CFrame.Angles(math.rad(stride * -7), math.rad(stride * -16), 0)
		end
		return CFrame.new()
	elseif role == "Antenna" then
		local speed = moving and 6.5 or 2.5
		local sway = math.sin(now * speed + phase)
		local nod = math.sin(now * speed * 0.72 + phase * 0.4)
		return CFrame.Angles(math.rad(nod * 8), math.rad(sway * 15), math.rad(side * sway * 6))
	elseif role == "AntennaTip" then
		local speed = moving and 7.7 or 3.0
		local sway = math.sin(now * speed + phase + 0.5)
		return CFrame.Angles(math.rad(sway * 10), math.rad(sway * 22), math.rad(side * sway * 8))
	elseif role == "WingLeft" or role == "WingRight" then
		if bugId == "Grasshopper" and airBlend > 0.01 then
			local flutter = math.sin(now * 27)
			return CFrame.Angles(
				math.rad(-4 * airBlend),
				math.rad(flutter * 4 * airBlend),
				math.rad(side * (6 + flutter * 8) * airBlend)
			)
		elseif moving then
			return CFrame.Angles(0, 0, math.rad(side * math.sin(cycle) * 3))
		end
		return CFrame.new()
	elseif role == "Head" then
		local nod = moving and math.sin(cycle) * 3 or math.sin(now * 1.8) * 1.5
		if bugId == "Grasshopper" then
			nod -= 4 * airBlend
		end
		return CFrame.Angles(math.rad(nod), 0, 0)
	elseif role == "Abdomen" then
		if moving and grounded then
			return CFrame.Angles(math.rad(math.sin(cycle + math.pi) * 3.0), 0, math.rad(math.sin(cycle * 0.5) * 1.3))
		end
		return CFrame.Angles(math.rad(math.sin(now * 1.5) * 0.8), 0, 0)
	elseif role == "Shell" then
		if bugId == "Beetle" and moving and grounded then
			return CFrame.Angles(0, 0, math.rad(math.sin(cycle * 2) * 1.8))
		end
		return CFrame.new()
	end

	return CFrame.new()
end

local function animateRecord(record, now: number)
	local model = record.model
	local humanoid = record.humanoid
	local root = record.root
	if not model.Parent or not humanoid.Parent or not root.Parent then
		tracked[model] = nil
		return
	end

	local dt = math.clamp(now - (record.lastUpdate or now), 0, 0.1)
	record.lastUpdate = now

	local velocity = root.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	local moving = horizontalSpeed > 1.1

	-- Tie leg cadence directly to actual ground speed. The previous fixed-ish
	-- cadence made the bugs slide faster than their feet appeared to move.
	local cadence = moving and math.clamp(horizontalSpeed * 1.45, 10.5, 28) or 0
	record.gaitCycle = (record.gaitCycle or 0) + cadence * dt
	local cycle = record.gaitCycle

	-- Blend into and out of airborne posture rather than snapping between a rigid
	-- ground pose and a rigid jump pose.
	local airTarget = grounded and 0 or 1
	local airAlpha = 1 - math.exp(-dt * (airTarget > record.airBlend and 8 or 6))
	record.airBlend = record.airBlend + (airTarget - record.airBlend) * airAlpha

	local bugId = model:GetAttribute("BugId") or "Ant"
	for i = #record.motors, 1, -1 do
		local motor = record.motors[i]
		local base = record.baseC0[motor]
		if not motor.Parent or not motor.Part1 or not base then
			record.baseC0[motor] = nil
			table.remove(record.motors, i)
		else
			motor.Transform = CFrame.new()
			motor.C0 = base * jointMotion(motor, now, moving, grounded, cycle, bugId, velocity.Y, record.airBlend)
		end
	end
end

function BugMotionController.Init()
	for _, player in ipairs(Players:GetPlayers()) do
		trackPlayer(player)
	end
	Players.PlayerAdded:Connect(trackPlayer)

	RunService.RenderStepped:Connect(function(dt)
		accumulator += dt
		if accumulator < UPDATE_INTERVAL then
			return
		end
		accumulator = 0

		local now = os.clock()
		for _, record in pairs(tracked) do
			animateRecord(record, now)
		end
	end)
end

return BugMotionController
