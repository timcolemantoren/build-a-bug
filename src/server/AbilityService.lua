--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local BugArchetypes = require(BuildABugShared.Config.BugArchetypes)

local AbilityService = {}

local PlayerDataService = nil
local cooldownsByUserId = {}

local DEFAULT_COOLDOWN = 8

local function getBugForPlayer(player: Player)
	if not PlayerDataService then
		return nil, nil
	end

	local data = PlayerDataService.GetData(player)
	local bugId = data and data.selectedBug or "Ant"
	return bugId, BugArchetypes[bugId]
end

local function getCooldown(player: Player): number
	local userCooldowns = cooldownsByUserId[player.UserId]
	if not userCooldowns then
		return 0
	end

	return userCooldowns.readyAt or 0
end

local function setCooldown(player: Player, seconds: number)
	cooldownsByUserId[player.UserId] = { readyAt = os.clock() + seconds }
end

local function isReady(player: Player): boolean
	return os.clock() >= getCooldown(player)
end

local function getRootPart(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function glowCharacter(player: Player, color: Color3, duration: number, name: string)
	local character = player.Character
	if not character then
		return
	end

	local old = character:FindFirstChild(name)
	if old then
		old:Destroy()
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = name
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = 0.45
	highlight.OutlineTransparency = 0
	highlight.Parent = character

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local light = nil
	if rootPart then
		light = Instance.new("PointLight")
		light.Name = name .. "Light"
		light.Color = color
		light.Brightness = 2.5
		light.Range = 16
		light.Parent = rootPart
	end

	task.delay(duration, function()
		if highlight and highlight.Parent then
			highlight:Destroy()
		end
		if light and light.Parent then
			light:Destroy()
		end
	end)
end

local function burstAtRoot(player: Player, color: Color3)
	local rootPart = getRootPart(player)
	if not rootPart then
		return
	end

	local ring = Instance.new("Part")
	ring.Name = "AbilityBurst"
	ring.Shape = Enum.PartType.Ball
	ring.Size = Vector3.new(5, 0.35, 5)
	ring.Position = rootPart.Position - Vector3.new(0, 2.2, 0)
	ring.Anchored = true
	ring.CanCollide = false
	ring.Color = color
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.45
	ring.Parent = workspace

	task.delay(0.45, function()
		if ring and ring.Parent then
			ring:Destroy()
		end
	end)
end

local function useAntForage(player: Player)
	PlayerDataService.AddCrumbs(player, 2)
	PlayerDataService.AddDna(player, 2)
	glowCharacter(player, Color3.fromRGB(255, 185, 70), 1.5, "AntForageGlow")
	burstAtRoot(player, Color3.fromRGB(255, 190, 75))
end

local function useBeetleShellBlock(player: Player, bug)
	local duration = bug.ability and bug.ability.durationSeconds or 4
	player:SetAttribute("ShellBlockUntil", os.clock() + duration)
	glowCharacter(player, Color3.fromRGB(50, 210, 255), duration, "BeetleShellGlow")
	burstAtRoot(player, Color3.fromRGB(55, 210, 255))
end

local function useGrasshopperLeap(player: Player)
	local rootPart = getRootPart(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not rootPart then
		return
	end

	local forward = rootPart.CFrame.LookVector
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end

	rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 2, 0)
	rootPart.AssemblyLinearVelocity = Vector3.new(forward.X * 115, 88, forward.Z * 115)
	glowCharacter(player, Color3.fromRGB(90, 255, 95), 0.75, "GrasshopperLeapGlow")
	burstAtRoot(player, Color3.fromRGB(90, 255, 95))
end

local function useLadybugWingBurst(player: Player, bug)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local duration = bug.ability and bug.ability.durationSeconds or 3.5
	local boostSpeed = bug.ability and bug.ability.boostSpeed or 25
	humanoid.WalkSpeed = boostSpeed
	glowCharacter(player, Color3.fromRGB(255, 92, 88), duration, "LadybugWingBurstGlow")
	burstAtRoot(player, Color3.fromRGB(255, 92, 88))

	task.delay(duration, function()
		if player.Parent ~= Players or player:GetAttribute("InRound") ~= true then
			return
		end
		local currentId, currentBug = getBugForPlayer(player)
		local currentCharacter = player.Character
		local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
		if currentId == "Ladybug" and currentBug and currentHumanoid then
			currentHumanoid.WalkSpeed = currentBug.movementSpeed or 17
		end
	end)
end

local function useMantisPounce(player: Player)
	local rootPart = getRootPart(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not rootPart then
		return
	end

	local forward = rootPart.CFrame.LookVector
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
	rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 0.8, 0)
	rootPart.AssemblyLinearVelocity = Vector3.new(forward.X * 94, 42, forward.Z * 94)
	glowCharacter(player, Color3.fromRGB(185, 255, 90), 0.7, "MantisPounceGlow")
	burstAtRoot(player, Color3.fromRGB(185, 255, 90))
end

local function useDragonflyAirDash(player: Player)
	local rootPart = getRootPart(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not rootPart then
		return
	end

	local forward = rootPart.CFrame.LookVector
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 1.4, 0)
	rootPart.AssemblyLinearVelocity = Vector3.new(forward.X * 128, 58, forward.Z * 128)
	glowCharacter(player, Color3.fromRGB(88, 225, 255), 0.85, "DragonflyDashGlow")
	burstAtRoot(player, Color3.fromRGB(88, 225, 255))
end

local function usePillbugRollAway(player: Player, bug)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = getRootPart(player)
	if not humanoid or not rootPart then
		return
	end

	local duration = bug.ability and bug.ability.durationSeconds or 1.55
	local rollSpeed = bug.ability and bug.ability.rollSpeed or 72
	local forward = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z)
	if forward.Magnitude < 0.01 then
		forward = Vector3.new(0, 0, -1)
	else
		forward = forward.Unit
	end

	-- HazardService already understands ShellBlockUntil, so the curled shell gets
	-- the same strong protected window as Beetle without creating a parallel rule.
	player:SetAttribute("ShellBlockUntil", os.clock() + duration)

	-- Replicated roll metadata lets every client animate the shell while the owning
	-- client sustains the actual physics. GetServerTimeNow is synchronized enough
	-- for a short visual ability and avoids comparing unrelated os.clock values.
	local now = workspace:GetServerTimeNow()
	player:SetAttribute("PillbugRollStartedAt", now)
	player:SetAttribute("PillbugRollUntil", now + duration)
	player:SetAttribute("PillbugRollDirX", forward.X)
	player:SetAttribute("PillbugRollDirZ", forward.Z)
	player:SetAttribute("PillbugRollSpeed", rollSpeed)
	player:SetAttribute("PillbugRollNonce", (player:GetAttribute("PillbugRollNonce") or 0) + 1)

	-- The server gives the first shove immediately. The local motion controller then
	-- keeps the client-owned character moving at roll speed for the whole burst.
	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = false
	rootPart.AssemblyLinearVelocity = Vector3.new(forward.X * rollSpeed, math.max(rootPart.AssemblyLinearVelocity.Y, 6), forward.Z * rollSpeed)
	glowCharacter(player, Color3.fromRGB(188, 164, 128), duration, "PillbugRollGlow")
	burstAtRoot(player, Color3.fromRGB(188, 164, 128))

	task.delay(duration, function()
		if player.Parent ~= Players then
			return
		end
		local currentId, currentBug = getBugForPlayer(player)
		local currentCharacter = player.Character
		local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
		if currentId == "Pillbug" and currentBug and currentHumanoid then
			currentHumanoid.WalkSpeed = currentBug.movementSpeed or 13
			currentHumanoid.AutoRotate = true
		end
		player:SetAttribute("PillbugRollUntil", 0)
	end)
end

function AbilityService.Init(remoteEvents, playerDataService)
	PlayerDataService = playerDataService

	Players.PlayerRemoving:Connect(function(player)
		cooldownsByUserId[player.UserId] = nil
	end)

	remoteEvents.UseAbility.OnServerEvent:Connect(function(player: Player)
		if player:GetAttribute("InRound") ~= true then
			return
		end

		local bugId, bug = getBugForPlayer(player)
		if not bug or not isReady(player) then
			return
		end

		local cooldown = bug.ability and bug.ability.cooldownSeconds or DEFAULT_COOLDOWN
		setCooldown(player, cooldown)

		if bugId == "Ant" then
			useAntForage(player)
		elseif bugId == "Beetle" then
			useBeetleShellBlock(player, bug)
		elseif bugId == "Grasshopper" then
			useGrasshopperLeap(player)
		elseif bugId == "Ladybug" then
			useLadybugWingBurst(player, bug)
		elseif bugId == "Mantis" then
			useMantisPounce(player)
		elseif bugId == "Dragonfly" then
			useDragonflyAirDash(player)
		elseif bugId == "Pillbug" then
			usePillbugRollAway(player, bug)
		end
	end)
end

return AbilityService
