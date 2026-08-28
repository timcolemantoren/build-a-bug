--!nonstrict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local RakeSweepHazard = {}

local function weldToHead(head: BasePart, part: BasePart)
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Parent = head

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = part
	weld.Parent = part
end

local function makeRake(zone, folder: Instance)
	local alongX = zone.alongX == true
	local direction = zone.sweepDirection or 1
	local halfTravel = ((alongX and zone.size.X or zone.size.Z) / 2) + 14
	local startOffset = -direction * halfTravel
	local endOffset = direction * halfTravel

	local startPosition
	local endPosition
	if alongX then
		startPosition = zone.center + Vector3.new(startOffset, 4.0, 0)
		endPosition = zone.center + Vector3.new(endOffset, 4.0, 0)
	else
		startPosition = zone.center + Vector3.new(0, 4.0, startOffset)
		endPosition = zone.center + Vector3.new(0, 4.0, endOffset)
	end

	local head = Instance.new("Part")
	head.Name = "SweepingRakeHead"
	head.Size = alongX and Vector3.new(5.5, 3.0, 36) or Vector3.new(36, 3.0, 5.5)
	head.Position = startPosition
	head.Anchored = true
	head.CanCollide = false
	head.CanTouch = false
	head.CanQuery = false
	head.Color = Color3.fromRGB(92, 102, 105)
	head.Material = Enum.Material.Metal
	head.Parent = folder

	local handle = Instance.new("Part")
	handle.Name = "RakeHandle"
	handle.Size = Vector3.new(2.8, 32, 2.8)
	handle.Color = Color3.fromRGB(147, 93, 49)
	handle.Material = Enum.Material.Wood
	handle.CFrame = CFrame.new(startPosition + Vector3.new(0, 16.5, 0))
	weldToHead(head, handle)

	for index = -4, 4 do
		local tine = Instance.new("Part")
		tine.Name = "RakeTine"
		tine.Color = Color3.fromRGB(67, 75, 78)
		tine.Material = Enum.Material.Metal
		if alongX then
			tine.Size = Vector3.new(10, 1.15, 1.35)
			tine.Position = startPosition + Vector3.new(direction * 5.5, -1.45, index * 3.7)
		else
			tine.Size = Vector3.new(1.35, 1.15, 10)
			tine.Position = startPosition + Vector3.new(index * 3.7, -1.45, direction * 5.5)
		end
		weldToHead(head, tine)
	end

	return head, endPosition
end

function RakeSweepHazard.Run(zone, damage: number, travelTime: number, folder: Instance, generationAlive, onHit)
	local head, endPosition = makeRake(zone, folder)
	local alongX = zone.alongX == true
	local direction = zone.sweepDirection or 1
	local sweepVector = alongX and Vector3.new(direction, 0, 0) or Vector3.new(0, 0, direction)
	local hitPlayers = {}

	TweenService:Create(head, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
		Position = endPosition,
	}):Play()

	task.spawn(function()
		local startedAt = os.clock()
		while head.Parent and generationAlive() and os.clock() - startedAt <= travelTime + 0.08 do
			for _, player in ipairs(Players:GetPlayers()) do
				if player:GetAttribute("InRound") == true and not hitPlayers[player.UserId] then
					local character = player.Character
					local rootPart = character and character:FindFirstChild("HumanoidRootPart")
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					if rootPart and humanoid and humanoid.Health > 0 then
						local delta = rootPart.Position - head.Position
						local touched = if alongX
							then math.abs(delta.X) <= 7.5 and math.abs(delta.Z) <= 20
							else math.abs(delta.Z) <= 7.5 and math.abs(delta.X) <= 20
						if touched then
							hitPlayers[player.UserId] = true
							onHit(player, humanoid, damage, sweepVector)
						end
					end
				end
			end
			task.wait(0.04)
		end
	end)

	Debris:AddItem(head, travelTime + 0.18)
end

return RakeSweepHazard
