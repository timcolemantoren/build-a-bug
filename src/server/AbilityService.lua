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

local function useAntForage(player: Player)
	-- Simple active for the prototype: a tiny snack boost.
	-- Ant already has the stronger passive crumb pickup bonus.
	PlayerDataService.AddCrumbs(player, 2)
	PlayerDataService.AddDna(player, 2)
end

local function useBeetleShellBlock(player: Player, bug)
	local duration = bug.ability and bug.ability.durationSeconds or 4
	player:SetAttribute("ShellBlockUntil", os.clock() + duration)
end

local function useGrasshopperLeap(player: Player)
	local rootPart = getRootPart(player)
	if not rootPart then
		return
	end

	local forward = rootPart.CFrame.LookVector
	rootPart.AssemblyLinearVelocity = Vector3.new(forward.X * 70, 58, forward.Z * 70)
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
