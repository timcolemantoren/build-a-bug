--!nonstrict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Lightweight procedural animation for the proxy bug bodies.
-- Every client animates the visible Motor6Ds locally, including other players.
-- No gameplay position, collision, Humanoid state, or server authority is changed.

local BugMotionController = {}

local VISUAL_MODEL_NAME = "BuildABugVisual"
local MOTOR_NAME = "BugMotionMotor"
local UPDATE_INTERVAL = 1 / 30

local tracked = setmetatable({}, { __mode = "k" })
local accumulator = 0

local function addMotor(record, instance: Instance)
	if instance:IsA("Motor6D") and instance.Name == MOTOR_NAME then
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

local function getBaseMotion(record, now: number, moving: boolean, grounded: boolean, cycle: number, bugId: string)
	local bobAmplitude = 0.018
	if moving and grounded then
		if bugId == "Beetle" then
			bobAmplitude = 0.028
		elseif bugId == "Grasshopper" then
			bobAmplitude = 0.052
		else
			bobAmplitude = 0.042
		end
	end

	local bob
	if moving and grounded then
		bob = math.sin(cycle * 2) * bobAmplitude
	else
		bob = math.sin(now * 2.2) * bobAmplitude
	end

	return CFrame.new(0, bob, 0)
end

local function getMotorMotion(record, motor: Motor6D, now: number, moving: boolean, grounded: boolean, cycle: number, baseMotion: CFrame, bugId: string)
	local role = motor:GetAttribute("MotionRole") or ""
	local side = motor:GetAttribute("MotionSide") or 0
	local phase = motor:GetAttribute("MotionPhase") or 0
	local motion = baseMotion

	if role == "LegUpper" then
		local swing = moving and grounded and math.sin(cycle + phase) or math.sin(now * 1.5 + phase) * 0.10
		motion *= CFrame.Angles(0, math.rad(swing * 13), math.rad(side * -2))
	elseif role == "LegLower" then
		local swing = moving and grounded and math.sin(cycle + phase) or math.sin(now * 1.5 + phase) * 0.10
		motion *= CFrame.Angles(0, math.rad(swing * -10), math.rad(side * 2))
	elseif role == "HindLegThigh" then
		if bugId == "Grasshopper" and not grounded then
			motion *= CFrame.Angles(math.rad(-18), math.rad(side * 7), math.rad(side * -5))
		else
			local swing = moving and math.sin(cycle + phase) or math.sin(now * 1.2 + phase) * 0.08
			motion *= CFrame.Angles(math.rad(swing * 5), math.rad(swing * 8), 0)
		end
	elseif role == "HindLegShin" then
		if bugId == "Grasshopper" and not grounded then
			motion *= CFrame.Angles(math.rad(14), math.rad(side * -5), 0)
		else
			local swing = moving and math.sin(cycle + phase) or math.sin(now * 1.2 + phase) * 0.08
			motion *= CFrame.Angles(math.rad(swing * -4), math.rad(swing * -7), 0)
		end
	elseif role == "Antenna" or role == "AntennaTip" then
		local antennaSpeed = moving and 4.6 or 2.2
		local sway = math.sin(now * antennaSpeed + phase)
		local amount = role == "AntennaTip" and 8 or 5
		motion *= CFrame.Angles(math.rad(sway * 2), math.rad(sway * amount), math.rad(side * sway * 2))
	elseif role == "WingLeft" or role == "WingRight" then
		if bugId == "Grasshopper" and not grounded then
			local flutter = math.sin(now * 24)
			motion *= CFrame.Angles(0, math.rad(flutter * 4), math.rad(side * flutter * 7))
		elseif moving then
			motion *= CFrame.Angles(0, 0, math.rad(side * math.sin(cycle) * 1.5))
		end
	elseif role == "Head" then
		local nod = moving and math.sin(cycle) * 1.8 or math.sin(now * 1.8) * 0.8
		if bugId == "Grasshopper" and not grounded then
			nod -= 5
		end
		motion *= CFrame.Angles(math.rad(nod), 0, 0)
	elseif role == "Thorax" or role == "Pronotum" or role == "Abdomen" or role == "Shell" or role == "ShellSeam" or role == "Eye" then
		if bugId == "Grasshopper" and not grounded then
			motion *= CFrame.Angles(math.rad(-3), 0, 0)
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
	local cadence = math.clamp(5.5 + horizontalSpeed * 0.22, 5.5, 10.5)
	local cycle = now * cadence
	local bugId = model:GetAttribute("BugId") or "Ant"
	local baseMotion = getBaseMotion(record, now, moving, grounded, cycle, bugId)

	for i = #record.motors, 1, -1 do
		local motor = record.motors[i]
		if not motor.Parent or not motor.Part1 then
			table.remove(record.motors, i)
		else
			motor.Transform = getMotorMotion(record, motor, now, moving, grounded, cycle, baseMotion, bugId)
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
