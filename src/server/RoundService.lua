--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local RoundConfig = require(BuildABugShared.Config.RoundConfig)
local MapConfig = require(BuildABugShared.Config.MapConfig)

local RoundService = {}
local remotes = nil
local PlayerDataService = nil
local RewardService = nil
local HazardService = nil
local ArenaService = nil
local LobbyService = nil

local matchState = "Waiting"
local roundStartedAt = 0
local currentMapId = MapConfig.DefaultMapId
local participants = {}
local deathConnections = {}
local countdownToken = 0
local roundToken = 0
local lockedRoster = nil

local function getMap()
	return MapConfig.GetMap(currentMapId) or MapConfig.GetMap(MapConfig.DefaultMapId)
end

local function getMapPayload()
	local map = getMap()
	return {
		mapId = map and map.id or currentMapId,
		mapName = map and map.displayName or "Backyard",
	}
end

local function fireClient(player: Player, state: string, payload)
	if remotes and remotes.RoundStateChanged and player.Parent == Players then
		remotes.RoundStateChanged:FireClient(player, state, payload or {})
	end
end

local function broadcast(state: string, payload)
	if remotes and remotes.RoundStateChanged then
		remotes.RoundStateChanged:FireAllClients(state, payload or {})
	end
end

local function clearPickups()
	local pickupsFolder = ArenaService.GetPickupsFolder()
	pickupsFolder:ClearAllChildren()
end

local function clearTemporaryHazards()
	local arena = Workspace:FindFirstChild("BuildABugArena")
	local hazards = arena and arena:FindFirstChild("Hazards")
	if hazards then
		hazards:ClearAllChildren()
	end
end

local function collectPickup(pickup: BasePart, player: Player)
	if matchState ~= "Active" or player:GetAttribute("InRound") ~= true then
		return
	end

	local pickupType = pickup:GetAttribute("PickupType")
	if pickupType == "DNA" then
		RewardService.AwardDnaPickup(player, RoundConfig.dnaPickupReward)
	else
		RewardService.AwardCrumb(player, 1)
	end
end

local function wirePickupHitbox(hitbox: BasePart, destroyTarget: Instance)
	hitbox.Touched:Connect(function(hit)
		if hitbox:GetAttribute("Collected") then
			return
		end

		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or player:GetAttribute("InRound") ~= true then
			return
		end

		hitbox:SetAttribute("Collected", true)
		collectPickup(hitbox, player)
		destroyTarget:Destroy()
	end)
end

local function createCrumbPickup(position: Vector3)
	local pickupsFolder = ArenaService.GetPickupsFolder()
	local crumb = Instance.new("Part")
	crumb.Name = "Crumb"
	crumb.Size = Vector3.new(math.random(9, 16) / 10, math.random(5, 10) / 10, math.random(8, 14) / 10)
	crumb.Position = position
	crumb.Orientation = Vector3.new(math.random(0, 35), math.random(0, 180), math.random(0, 35))
	crumb.Anchored = true
	crumb.CanCollide = false
	crumb.Color = Color3.fromRGB(210 + math.random(0, 35), 165 + math.random(0, 35), 95 + math.random(0, 25))
	crumb.Material = Enum.Material.SmoothPlastic
	crumb:SetAttribute("Collected", false)
	crumb:SetAttribute("PickupType", "Crumb")
	crumb.Parent = pickupsFolder

	local crust = Instance.new("Part")
	crust.Name = "CrustEdge"
	crust.Size = Vector3.new(crumb.Size.X * 0.7, 0.18, crumb.Size.Z * 0.5)
	crust.CFrame = crumb.CFrame * CFrame.new(0, crumb.Size.Y / 2 + 0.05, 0)
	crust.Anchored = true
	crust.CanCollide = false
	crust.Color = Color3.fromRGB(145, 90, 42)
	crust.Material = Enum.Material.SmoothPlastic
	crust.Parent = crumb

	wirePickupHitbox(crumb, crumb)
end

local function createDnaPickup(position: Vector3)
	local pickupsFolder = ArenaService.GetPickupsFolder()
	local model = Instance.new("Model")
	model.Name = "DnaPickup"
	model.Parent = pickupsFolder

	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Shape = Enum.PartType.Ball
	hitbox.Size = Vector3.new(5, 5, 5)
	hitbox.Position = position
	hitbox.Transparency = 1
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox:SetAttribute("Collected", false)
	hitbox:SetAttribute("PickupType", "DNA")
	hitbox.Parent = model
	model.PrimaryPart = hitbox

	local strands = 7
	for i = 1, strands do
		local t = (i - 1) / (strands - 1)
		local y = -2.4 + (t * 4.8)
		local angle = t * math.pi * 2
		local offsetA = Vector3.new(math.cos(angle) * 1.1, y, math.sin(angle) * 1.1)

		local orbA = Instance.new("Part")
		orbA.Name = "HelixNodeA"
		orbA.Shape = Enum.PartType.Ball
		orbA.Size = Vector3.new(0.6, 0.6, 0.6)
		orbA.Position = position + offsetA
		orbA.Anchored = true
		orbA.CanCollide = false
		orbA.Color = Color3.fromRGB(60, 220, 255)
		orbA.Material = Enum.Material.Neon
		orbA.Parent = model

		local orbB = Instance.new("Part")
		orbB.Name = "HelixNodeB"
		orbB.Shape = Enum.PartType.Ball
		orbB.Size = Vector3.new(0.6, 0.6, 0.6)
		orbB.Position = position + Vector3.new(-offsetA.X, y, -offsetA.Z)
		orbB.Anchored = true
		orbB.CanCollide = false
		orbB.Color = Color3.fromRGB(120, 150, 255)
		orbB.Material = Enum.Material.Neon
		orbB.Parent = model

		local rung = Instance.new("Part")
		rung.Name = "HelixRung"
		rung.Size = Vector3.new(2.2, 0.12, 0.12)
		rung.Position = position + Vector3.new(0, y, 0)
		rung.CFrame = CFrame.new(rung.Position) * CFrame.Angles(0, -angle, 0)
		rung.Anchored = true
		rung.CanCollide = false
		rung.Color = Color3.fromRGB(165, 235, 255)
		rung.Material = Enum.Material.Neon
		rung.Parent = model
	end

	wirePickupHitbox(hitbox, model)
end

local function spawnPickupWave()
	for _ = 1, RoundConfig.crumbsPerSpawn do
		createCrumbPickup(ArenaService.GetRandomGroundPickupPosition())
	end

	for _ = 1, RoundConfig.dnaPickupsPerSpawn do
		local useAir = math.random() < 0.6
		local position = useAir and ArenaService.GetRandomAirPickupPosition() or ArenaService.GetRandomGroundPickupPosition()
		createDnaPickup(position)
	end
end

local function runHazardLoop(myRoundToken: number)
	while matchState == "Active" and myRoundToken == roundToken do
		task.wait(18)
		if matchState ~= "Active" or myRoundToken ~= roundToken then
			break
		end

		local hazardId = HazardService.GetRandomHazardId()
		if hazardId then
			HazardService.WarnHazard(hazardId)
		end
	end
end

local function runPickupLoop(myRoundToken: number)
	while matchState == "Active" and myRoundToken == roundToken do
		spawnPickupWave()
		task.wait(RoundConfig.pickupSpawnIntervalSeconds or RoundConfig.crumbSpawnIntervalSeconds)
	end
end

local function countAliveParticipants(): number
	local count = 0
	for _, entry in pairs(participants) do
		if not entry.eliminated and entry.player and entry.player.Parent == Players then
			count += 1
		end
	end
	return count
end

local function countParticipants(): number
	local count = 0
	for _, entry in pairs(participants) do
		if entry.player and entry.player.Parent == Players then
			count += 1
		end
	end
	return count
end

local function broadcastRosterUpdate()
	local mapPayload = getMapPayload()
	broadcast("RosterUpdate", {
		playersRemaining = countAliveParticipants(),
		playerCount = countParticipants(),
		mapId = mapPayload.mapId,
		mapName = mapPayload.mapName,
	})
end

local function disconnectDeath(player: Player)
	local connection = deathConnections[player.UserId]
	if connection then
		connection:Disconnect()
		deathConnections[player.UserId] = nil
	end
end

local function eliminatePlayer(player: Player)
	if matchState ~= "Active" then
		return
	end

	local entry = participants[player.UserId]
	if not entry or entry.eliminated then
		return
	end

	entry.eliminated = true
	entry.survivedSeconds = math.max(0, math.floor(os.clock() - roundStartedAt))
	player:SetAttribute("InRound", false)
	player:SetAttribute("QueuedForMatch", false)

	local remaining = countAliveParticipants()
	local mapPayload = getMapPayload()
	fireClient(player, "Eliminated", {
		survivedSeconds = entry.survivedSeconds,
		playersRemaining = remaining,
		playerCount = countParticipants(),
		mapId = mapPayload.mapId,
		mapName = mapPayload.mapName,
	})
	broadcastRosterUpdate()

	if remaining == 0 then
		task.defer(function()
			RoundService.EndRound()
		end)
	end
end

local function prepareParticipant(player: Player, index: number)
	player:SetAttribute("InRound", true)
	player:SetAttribute("QueuedForMatch", false)
	player:SetAttribute("EnvironmentZone", "")

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
		disconnectDeath(player)
		deathConnections[player.UserId] = humanoid.Died:Connect(function()
			eliminatePlayer(player)
		end)
	end

	LobbyService.TeleportToRound(player, index)
end

local function updateQueueAttributes()
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("InRound") == true then
			player:SetAttribute("QueuedForMatch", false)
		else
			local locked = false
			if matchState == "Countdown" and lockedRoster then
				for _, lockedPlayer in ipairs(lockedRoster) do
					if lockedPlayer == player then
						locked = true
						break
					end
				end
			end
			player:SetAttribute("QueuedForMatch", locked or LobbyService.IsPlayerInsideQueue(player))
		end
	end
end

local function getQueuedPlayers()
	updateQueueAttributes()
	return LobbyService.GetPlayersInsideQueue()
end

local function setWaitingState()
	matchState = "Waiting"
	lockedRoster = nil
	local queued = getQueuedPlayers()
	local mapPayload = getMapPayload()
	LobbyService.SetBoard("Waiting", nil, #queued, mapPayload.mapName)
	broadcast("Waiting", {
		queuedPlayers = #queued,
		mapId = mapPayload.mapId,
		mapName = mapPayload.mapName,
	})
end

local function beginCountdown()
	if matchState ~= "Waiting" then
		return
	end

	matchState = "Countdown"
	lockedRoster = nil
	countdownToken += 1
	local myToken = countdownToken
	local mapPayload = getMapPayload()
	local lockAt = RoundConfig.countdownLockSeconds or 3

	task.spawn(function()
		for remaining = RoundConfig.lobbyCountdownSeconds, 0, -1 do
			if matchState ~= "Countdown" or myToken ~= countdownToken then
				return
			end

			local roster = lockedRoster or getQueuedPlayers()
			if #roster < RoundConfig.minimumPlayers then
				setWaitingState()
				return
			end

			if remaining == lockAt and not lockedRoster then
				lockedRoster = roster
				for _, player in ipairs(lockedRoster) do
					if player.Parent == Players then
						player:SetAttribute("QueuedForMatch", true)
					end
				end
				LobbyService.SetBoard("Locked", remaining, #lockedRoster, mapPayload.mapName)
				broadcast("RosterLocked", {
					seconds = remaining,
					queuedPlayers = #lockedRoster,
					mapId = mapPayload.mapId,
					mapName = mapPayload.mapName,
				})
			else
				local state = lockedRoster and "Locked" or "Countdown"
				LobbyService.SetBoard(state, remaining, #roster, mapPayload.mapName)
				broadcast("Countdown", {
					seconds = remaining,
					queuedPlayers = #roster,
					locked = lockedRoster ~= nil,
					mapId = mapPayload.mapId,
					mapName = mapPayload.mapName,
				})
			end

			if remaining > 0 then
				task.wait(1)
			end
		end

		if matchState ~= "Countdown" or myToken ~= countdownToken then
			return
		end

		local roster = lockedRoster or getQueuedPlayers()
		lockedRoster = nil
		if #roster < RoundConfig.minimumPlayers then
			setWaitingState()
			return
		end

		RoundService.StartRound(roster)
	end)
end

function RoundService.StartRound(roster)
	if matchState == "Active" then
		return
	end

	local playersToStart = roster or getQueuedPlayers()
	if #playersToStart < RoundConfig.minimumPlayers then
		setWaitingState()
		return
	end

	countdownToken += 1
	roundToken += 1
	local myRoundToken = roundToken
	matchState = "Active"
	lockedRoster = nil
	roundStartedAt = os.clock()
	participants = {}
	clearPickups()
	clearTemporaryHazards()

	local mapPayload = getMapPayload()
	local arena = Workspace:FindFirstChild("BuildABugArena")
	if arena then
		arena:SetAttribute("CurrentMapId", mapPayload.mapId)
	end

	for index, player in ipairs(playersToStart) do
		if player.Parent == Players then
			local data = PlayerDataService.GetData(player)
			local currency = data and data.currency or {}
			participants[player.UserId] = {
				player = player,
				eliminated = false,
				survivedSeconds = nil,
				startDna = currency.dna or 0,
				startCrumbs = currency.crumbs or 0,
			}
			prepareParticipant(player, index)
		end
	end

	local actualCount = countParticipants()
	for _, entry in pairs(participants) do
		local player = entry.player
		fireClient(player, "Started", {
			durationSeconds = RoundConfig.roundDurationSeconds,
			startedAt = roundStartedAt,
			playerCount = actualCount,
			playersRemaining = actualCount,
			mapId = mapPayload.mapId,
			mapName = mapPayload.mapName,
		})
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if not participants[player.UserId] then
			fireClient(player, "MatchInProgress", {
				durationSeconds = RoundConfig.roundDurationSeconds,
				playerCount = actualCount,
				playersRemaining = actualCount,
				mapId = mapPayload.mapId,
				mapName = mapPayload.mapName,
			})
		end
	end

	LobbyService.SetBoard("Active", nil, #getQueuedPlayers(), mapPayload.mapName)
	broadcastRosterUpdate()

	task.spawn(runPickupLoop, myRoundToken)
	task.spawn(runHazardLoop, myRoundToken)

	task.delay(RoundConfig.roundDurationSeconds, function()
		if matchState == "Active" and myRoundToken == roundToken then
			RoundService.EndRound()
		end
	end)
end

function RoundService.EndRound()
	if matchState ~= "Active" then
		return
	end

	matchState = "Results"
	roundToken += 1
	local survivedToEnd = math.max(0, math.floor(os.clock() - roundStartedAt))
	local mapPayload = getMapPayload()
	clearPickups()
	clearTemporaryHazards()

	for _, entry in pairs(participants) do
		local player = entry.player
		if player and player.Parent == Players then
			local survivedSeconds = entry.survivedSeconds or survivedToEnd
			local reward = RewardService.AwardRoundComplete(player, survivedSeconds)
			local data = PlayerDataService.GetData(player)
			local currency = data and data.currency or {}
			local progression = data and data.progression or {}
			local currentProgress = progression.current
			local nextProgress = progression.next

			local roundCrumbs = math.max(0, (currency.crumbs or 0) - (entry.startCrumbs or 0))
			local roundDna = math.max(0, (currency.dna or 0) - (entry.startDna or 0))

			player:SetAttribute("InRound", false)
			player:SetAttribute("QueuedForMatch", false)
			disconnectDeath(player)
			LobbyService.TeleportToLobby(player, 1)

			fireClient(player, "Ended", {
				survivedSeconds = survivedSeconds,
				eliminated = entry.eliminated == true,
				crumbsCollected = roundCrumbs,
				dnaEarned = roundDna,
				completionDna = reward and reward.completionDna or 0,
				totalCrumbs = currency.crumbs or 0,
				totalDna = currency.dna or 0,
				title = currentProgress and currentProgress.title or nil,
				nextTitleDna = nextProgress and nextProgress.dnaRequired or nil,
				mapId = mapPayload.mapId,
				mapName = mapPayload.mapName,
			})
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if not participants[player.UserId] then
			fireClient(player, "Results", {
				mapId = mapPayload.mapId,
				mapName = mapPayload.mapName,
			})
		end
	end

	participants = {}
	LobbyService.SetBoard("Results", nil, #getQueuedPlayers(), mapPayload.mapName)

	task.delay(RoundConfig.resultsSeconds or 8, function()
		if matchState == "Results" then
			setWaitingState()
		end
	end)
end

local function setupPlayer(player: Player)
	player:SetAttribute("InRound", false)
	player:SetAttribute("QueuedForMatch", false)
	player:SetAttribute("EnvironmentZone", "")

	player.CharacterAdded:Connect(function()
		task.wait(0.35)
		if player.Parent == Players and player:GetAttribute("InRound") ~= true then
			LobbyService.TeleportToLobby(player, 1)
		end
	end)

	if player.Character then
		task.delay(0.35, function()
			if player.Parent == Players and player:GetAttribute("InRound") ~= true then
				LobbyService.TeleportToLobby(player, 1)
			end
		end)
	end
end

function RoundService.Init(remoteEvents, playerDataService, rewardService, hazardService, arenaService, lobbyService)
	remotes = remoteEvents
	PlayerDataService = playerDataService
	RewardService = rewardService
	HazardService = hazardService
	ArenaService = arenaService
	LobbyService = lobbyService

	clearPickups()
	clearTemporaryHazards()

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(function(player)
		local entry = participants[player.UserId]
		if entry and not entry.eliminated then
			entry.eliminated = true
			entry.survivedSeconds = math.max(0, math.floor(os.clock() - roundStartedAt))
		end
		disconnectDeath(player)
		if matchState == "Active" then
			broadcastRosterUpdate()
			if countAliveParticipants() == 0 then
				task.defer(function()
					RoundService.EndRound()
				end)
			end
		end
	end)

	remotes.StartRoundRequest.OnServerEvent:Connect(function(player: Player)
		if player:GetAttribute("InRound") == true then
			return
		end
		if matchState == "Countdown" and lockedRoster then
			return
		end
		LobbyService.MoveIntoQueue(player)
		player:SetAttribute("QueuedForMatch", true)
	end)

	setWaitingState()

	task.spawn(function()
		while true do
			updateQueueAttributes()
			local queued = getQueuedPlayers()
			local mapPayload = getMapPayload()

			if matchState == "Waiting" then
				LobbyService.SetBoard("Waiting", nil, #queued, mapPayload.mapName)
				if #queued >= RoundConfig.minimumPlayers then
					beginCountdown()
				end
			elseif matchState == "Active" then
				LobbyService.SetBoard("Active", nil, #queued, mapPayload.mapName)
			end

			task.wait(0.3)
		end
	end)
end

return RoundService
