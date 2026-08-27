--!nonstrict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local InteractiveFoliageService = {}

local connectedParts = {}

local function getArena(): Folder?
	return Workspace:FindFirstChild("BuildABugArena")
end

local function isPlayerPart(hit: BasePart): boolean
	local character = hit.Parent
	return character and Players:GetPlayerFromCharacter(character) ~= nil
end

local function fallBlade(blade: BasePart, hit: BasePart)
	if blade:GetAttribute("Fallen") then
		return
	end

	blade:SetAttribute("Fallen", true)
	blade.CanCollide = false

	local originalCFrame = blade.CFrame
	local height = blade.Size.Y
	local direction = (blade.Position - hit.Position)
	if direction.Magnitude < 0.1 then
		direction = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
	end
	direction = Vector3.new(direction.X, 0, direction.Z).Unit

	local yaw = math.atan2(direction.X, direction.Z)
	local fallenCFrame = CFrame.new(blade.Position - Vector3.new(0, height * 0.42, 0))
		* CFrame.Angles(0, yaw, 0)
		* CFrame.Angles(math.rad(82), 0, 0)

	local fallTween = TweenService:Create(
		blade,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = fallenCFrame }
	)
	fallTween:Play()

	local recoverSeconds = blade:GetAttribute("FallRecoverSeconds") or 10
	task.delay(recoverSeconds, function()
		if blade and blade.Parent then
			local recoverTween = TweenService:Create(
				blade,
				TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = originalCFrame }
			)
			recoverTween:Play()
			task.delay(0.8, function()
				if blade and blade.Parent then
					blade.CanCollide = true
					blade:SetAttribute("Fallen", false)
				end
			end)
		end
	end)
end

local function connectBlade(blade: Instance)
	if not blade:IsA("BasePart") then
		return
	end

	if connectedParts[blade] then
		return
	end

	if not blade:GetAttribute("FallsWhenTouched") then
		return
	end

	connectedParts[blade] = true
	blade.Touched:Connect(function(hit)
		if hit and hit:IsA("BasePart") and isPlayerPart(hit) then
			fallBlade(blade, hit)
		end
	end)
end

local function connectArenaGrass()
	local arena = getArena()
	local grassFolder = arena and arena:FindFirstChild("GrassClumps")
	if not grassFolder then
		return
	end

	for _, child in ipairs(grassFolder:GetChildren()) do
		connectBlade(child)
	end

	grassFolder.ChildAdded:Connect(connectBlade)
end

function InteractiveFoliageService.Init()
	connectArenaGrass()

	Workspace.ChildAdded:Connect(function(child)
		if child.Name == "BuildABugArena" then
			task.wait(0.25)
			connectArenaGrass()
		end
	end)
end

return InteractiveFoliageService
