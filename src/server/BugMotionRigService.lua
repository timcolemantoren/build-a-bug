--!nonstrict

local Players = game:GetService("Players")

-- Converts the proxy bug visual's rigid WeldConstraints into Motor6Ds.
-- The underlying Humanoid/R15 character still owns all real movement and collision;
-- these joints exist only so clients can add inexpensive visual motion.

local BugMotionRigService = {}

local VISUAL_MODEL_NAME = "BuildABugVisual"
local WELD_NAME = "BugVisualWeld"
local MOTOR_NAME = "BugMotionMotor"

local function getSide(localPosition: Vector3): number
	if localPosition.X < -0.08 then
		return -1
	elseif localPosition.X > 0.08 then
		return 1
	end
	return 0
end

local function getLegPhase(localPosition: Vector3, side: number): number
	local row
	if localPosition.Z < -0.4 then
		row = 1
	elseif localPosition.Z < 0.65 then
		row = 2
	else
		row = 3
	end

	-- Alternating tripod gait: left-front/right-middle/left-rear oppose the others.
	local rightOffset = side > 0 and 1 or 0
	return ((row + rightOffset) % 2 == 0) and 0 or math.pi
end

local function classifyPart(part: BasePart, root: BasePart)
	local localPosition = root.CFrame:PointToObjectSpace(part.Position)
	local side = getSide(localPosition)
	local role = part.Name
	local phase = 0

	if string.find(role, "Leg") then
		phase = getLegPhase(localPosition, side)
	elseif string.find(role, "Antenna") then
		phase = side < 0 and 0 or math.pi * 0.65
	end

	return role, side, phase
end

local function convertPart(part: BasePart, root: BasePart)
	if part:FindFirstChild(MOTOR_NAME) then
		return
	end

	local weld = part:FindFirstChild(WELD_NAME)
	if not weld or not weld:IsA("WeldConstraint") then
		return
	end

	local relative = root.CFrame:ToObjectSpace(part.CFrame)
	local rotationOnly = relative - relative.Position
	local role, side, phase = classifyPart(part, root)

	local motor = Instance.new("Motor6D")
	motor.Name = MOTOR_NAME
	motor.Part0 = root
	motor.Part1 = part

	-- Put the animation frame at the part center but keep its axes aligned to the
	-- character root. This lets every client use the same X/Y/Z motion language
	-- regardless of whether the visual piece is a ball, block, or rotated cylinder.
	motor.C0 = CFrame.new(relative.Position)
	motor.C1 = rotationOnly:Inverse()
	motor:SetAttribute("MotionRole", role)
	motor:SetAttribute("MotionSide", side)
	motor:SetAttribute("MotionPhase", phase)
	motor.Parent = part

	weld:Destroy()
end

local function prepareVisual(model: Model)
	local character = model.Parent
	if not character or not character:IsA("Model") then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			convertPart(descendant, root)
		end
	end

	model.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("WeldConstraint") and descendant.Name == WELD_NAME then
			local part = descendant.Parent
			if part and part:IsA("BasePart") then
				task.defer(convertPart, part, root)
			end
		elseif descendant:IsA("BasePart") then
			-- BugAvatarService parents the part immediately before adding its weld.
			-- A tiny defer catches either construction order safely.
			task.delay(0.02, convertPart, descendant, root)
		end
	end)
end

local function setupCharacter(character: Model)
	local existing = character:FindFirstChild(VISUAL_MODEL_NAME)
	if existing and existing:IsA("Model") then
		prepareVisual(existing)
	end

	character.ChildAdded:Connect(function(child)
		if child:IsA("Model") and child.Name == VISUAL_MODEL_NAME then
			prepareVisual(child)
		end
	end)
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then
		setupCharacter(player.Character)
	end
end

function BugMotionRigService.Init()
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)
end

return BugMotionRigService
