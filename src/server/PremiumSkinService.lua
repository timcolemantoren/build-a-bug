--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local CosmeticCatalog = require(BuildABugShared.Config.CosmeticCatalog)
local CosmeticStyles = require(BuildABugShared.Config.CosmeticStyles)

local PremiumSkinService = {}
local PlayerDataService = nil

local function getBugSkinMap(data)
	data.savedBuilds = data.savedBuilds or {}
	data.savedBuilds.BugSkins = data.savedBuilds.BugSkins or {}
	return data.savedBuilds.BugSkins
end

local function clearPreview(player: Player)
	player:SetAttribute("PreviewSkinStyle", nil)
end

local function ownsLiveSkin(player: Player, styleId: string): boolean
	if styleId == "None" then
		return true
	end
	local item = CosmeticCatalog.GetItem("Skin", styleId)
	if not item or item.robuxOnly ~= true then
		return false
	end
	local passId = tonumber(item.robuxPassId) or 0
	if passId <= 0 then
		return false
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	return ok and owns == true
end

local function canUseSkin(player: Player, styleId: string): boolean
	if not CosmeticStyles.IsValidSkinStyle(styleId) then
		return false
	end
	if styleId == "None" then
		return true
	end
	if RunService:IsStudio() then
		return true
	end
	return ownsLiveSkin(player, styleId)
end

local function canPreviewSkin(player: Player, styleId: string?): boolean
	if player:GetAttribute("InRound") == true then
		return false
	end
	if styleId == nil or styleId == "None" then
		return true
	end
	return CosmeticStyles.IsValidSkinStyle(styleId)
end

local function applyForCurrentBug(player: Player)
	if not PlayerDataService then
		return
	end
	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end
	local bugId = data.selectedBug or "Ant"
	local bugSkins = getBugSkinMap(data)
	local styleId = bugSkins[bugId] or "None"
	if not canUseSkin(player, styleId) then
		styleId = "None"
		bugSkins[bugId] = styleId
	end
	data.cosmetics = data.cosmetics or {}
	data.cosmetics.skin = styleId
	player:SetAttribute("SkinStyle", styleId)
end

local function equip(player: Player, styleId: string): boolean
	if not PlayerDataService or player:GetAttribute("InRound") == true then
		return false
	end
	if not canUseSkin(player, styleId) then
		return false
	end

	local data = PlayerDataService.GetData(player)
	if not data then
		return false
	end
	local bugId = data.selectedBug or "Ant"
	local bugSkins = getBugSkinMap(data)
	bugSkins[bugId] = styleId
	data.cosmetics = data.cosmetics or {}
	data.cosmetics.skin = styleId
	clearPreview(player)
	player:SetAttribute("SkinStyle", styleId)
	return true
end

local function preview(player: Player, styleId: string?)
	if not canPreviewSkin(player, styleId) then
		clearPreview(player)
		return
	end
	if styleId == nil or styleId == "None" then
		clearPreview(player)
		return
	end
	player:SetAttribute("PreviewSkinStyle", styleId)
end

local function setupPlayer(player: Player)
	clearPreview(player)
	task.delay(0.45, function()
		if player.Parent == Players then
			applyForCurrentBug(player)
		end
	end)
	player:GetAttributeChangedSignal("SelectedBug"):Connect(function()
		task.defer(applyForCurrentBug, player)
	end)
	player:GetAttributeChangedSignal("InRound"):Connect(function()
		if player:GetAttribute("InRound") == true then
			clearPreview(player)
		end
	end)
end

function PremiumSkinService.Init(playerDataService, remotes)
	PlayerDataService = playerDataService

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)

	remotes.SetPremiumSkin.OnServerEvent:Connect(function(player: Player, styleId: string)
		equip(player, styleId)
	end)
	remotes.PreviewPremiumSkin.OnServerEvent:Connect(function(player: Player, styleId)
		if styleId ~= nil and type(styleId) ~= "string" then
			return
		end
		preview(player, styleId)
	end)
end

return PremiumSkinService
