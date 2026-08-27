--!nonstrict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Lightweight procedural animation for the proxy bug bodies.
-- Every client animates visible Motor6Ds locally, including other players.
-- Gameplay position, collision, Humanoid state, and server authority are untouched.

local BugMotionController = {}

local VISUAL_MODEL_NAME = "BuildABugVisual"
local MOTOR_NAME = "BugMotionMotor"
local UPDATE_INTERVAL = 1 / 30

local tracked = setmetatable({}, { __mode = "k" })
local accumulator = 0

local function addMotor(record, instance: Instance)
	if instance:IsA("Motor6D") and instance.Name == MOTOR_NAME then
		for _, existing in ipairs(record.motors) do
			if existing == instance then
				return
			end
		end
		table.insert(record.motors, instance)
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
		character = character,
		humanoid = humanoid,
		root = root,
		motors = {},
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
				print(string.format("[Build a Bug] Motion tracking %s with %d joints", tostring(model:GetAttribute("BugId")), #record.motors))
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

local function getBaseMotion(now: number, moving: boolean, grounded: boolean, cycle: number, bugId: string, verticalVelocity: number)
	local bobAmplitude = 0.025
	if moving and grounded then
		if bugId == "Beetle" then
			bobAmplitude = 0.045
		elseif bugId == "Grasshopper" then
			bobAmplitude = 0.075
		else
			bobAmplitude = 0.065
		end
	end

	local bob
	if moving and grounded then
		bob = math.sin(cycle * 2) * bobAmplitude
	else
		bob = math.sin(now * 2.2) * bobAmplitude
	end

	local pitch = 0
	if not grounded then
		if verticalVelocity > 2 then
			pitch = -6
		elseif verticalVelocity < -2 then
			pitch = 7
		end
	end

	return CFrame.new(0, bob, 0) * CFrame.Angles(math.rad(pitch), 0, 0)
end

local function getMotorMotion(motor: Motor6D, now: number, moving: boolean, grounded: boolean, cycle: number, baseMotion: CFrame, bugId: string, verticalVelocity: number)
	local role = motor:GetAttribute("MotionRole") or ""
	local side = motor:GetAttribute("MotionSide") or 0
	local phase = motor:GetAttribute("MotionPhase") or 0
	local motion = baseMotion

	if role == "LegUpper" then
		if moving and grounded then
			local swing = math.sin(cycle + phase)
			local lift = math.max(0, math.sin(cycle + phase + 0.55))
			motion *= CFrame.Angles(0, math.rad(swing * 24), math.rad(side * -lift * 10))
		else
			local idle = math.sin(now * 1.4 + phase)
			motion *= CFrame.Angles(0, math.rad(idle * 2.5), math.rad(side * idle * 1.5))
		end
	elseif role == "LegLower" then
		if moving and grounded then
			local swing = math.sin(cycle + phase)
			local lift = math.max(0, math.sin(cycle + phase + 0.55))
			motion *= CFrame.Angles(0, math.rad(swing * -18), math.rad(side * lift * 15))
		else
			local idle = math.sin(now * 1.4 + phase)
			motion *= CFrame.Angles(0, math.rad(idle * -2), 0)
		end
	elseif role == "HindLegThigh" then
		if bugId == "Grasshopper" and not grounded then
			-- Tuck the huge rear legs visibly during a jump.
			local tuck = verticalVelocity > 0 and 1 or 0.75
			motion *= CFrame.Angles(math.rad(-32 * tuck), math.rad(side * 15), math.rad(side * -12))
		elseif moving then
			local swing = math.sin(cycle + phase)
			motion *= CFrame.Angles(math.rad(swing * 8), math.rad(swing * 16), math.rad(side * -4))
		else
			local idle = math.sin(now * 1.1 + phase)
			motion *= CFrame.Angles(0, math.rad(idle * 2), 0)
		end
	elseif role == "HindLegShin" then
		if bugId == "Grasshopper" and not grounded then
			local tuck = verticalVelocity > 0 and 1 or 0.75
			motion *= CFrame.Angles(math.rad(28 * tuck), math.rad(side * -12), math.rad(side * 8))
		elseif moving then
			local swing = math.sin(cycle + phase)
			motion *= CFrame.Angles(math.rad(swing * -7), math.rad(swing * -14), 0)
		else
			local idle = math.sin(now * 1.1 + phase)
			motion *= CFrame.Angles(0, math.rad(idle * -2), 0)
		end
	elseif role == "Antenna" then
		local speed = moving and 6.2 or 2.4
		local sway = math.sin(now * speed + phase)
		local forwardFlick = math.sin(now * (speed * 0.72) + phase * 0.5)
		motion *= CFrame.Angles(math.rad(forwardFlick * 6), math.rad(sway * 12), math.rad(side * sway * 5))
	elseif role == "AntennaTip" then
		local speed = moving and 7.4 or 2.8
		local sway = math.sin(now * speed + phase + 0.45)
		motion *= CFrame.Angles(math.rad(sway * 8), math.rad(sway * 18), math.rad(side * sway * 7))
	elseif role == "WingLeft" or role == "WingRight" then
		if bugId == "Grasshopper" and not grounded then
			local flutter = math.sin(now * 28)
			motion *= CFrame.Angles(math.rad(-5), math.rad(flutter * 6), math.rad(side * (10 + flutter * 12)))
		elseif moving then
			motion *= CFrame.Angles(0, 0, math.rad(side * math.sin(cycle) * 3))
		end
	elseif role == "Head" then
		local nod = moving and math.sin(cycle) * 3.5 or math.sin(now * 1.8) * 1.4
		if bugId == "Grasshopper" and not grounded then
			nod -= 8
		end
		motion *= CFrame.Angles(math.rad(nod), 0, 0)
	elseif role == "Abdomen" then
		if moving and grounded then
			motion *= CFrame.Angles(math.rad(math.sin(cycle + math.pi) * 2.5), 0, 0)
		end
	elseif role == "Shell" or role == "Pronotum" then
		if bugId == "Beetle" and moving and grounded then
			motion *= CFrame.Angles(0, 0, math.rad(math.sin(cycle * 2) * 1.6))
		end
	end

	return motion
end

local function animateRecord(record, now: number)
	local model = record.model
	local humanoid = record.humanoid
	local root = record.root
	if not model.Parent or not humanoid.Parent or not root.Parent then
		tracked[model] = nil
		return
	end

	local velocity = root.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	local moving = horizontalSpeed > 1.1
	local cadence = math.clamp(6.4 + horizontalSpeed * 0.28, 6.4, 12.5)
	local cycle = now * cadence
	local bugId = model:GetAttribute("BugId") or "Ant"
	local baseMotion = getBaseMotion(now, moving, grounded, cycle, bugId, velocity.Y)

	for i = #record.motors, 1, -1 do
		local motor = record.motors[i]
		if not motor.Parent or not motor.Part1 then
			table.remove(record.motors, i)
		else
			motor.Transform = getMotorMotion(motor, now, moving, grounded, cycle, baseMotion, bugId, velocity.Y)
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
