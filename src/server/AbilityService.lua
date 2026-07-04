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
	cooldownsByUserId[player.UserId] = {
		readyAt = os.clock() + seconds,
	}
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
	-- Simple active for the prototype: a tiny snack boost.
	-- Ant already has the stronger passive crumb pickup bonus.
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

function AbilityService.Init(remoteEvents, playerDataService)
	PlayerDataService = playerDataService

	Players.PlayerRemoving:Connect(function(player)
		cooldownsByUserId[player.UserId] = nil
	end)

	remoteEvents.UseAbility.OnServerEvent:Connect(function(player: Player)
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
		end
	end)
end

return AbilityService
