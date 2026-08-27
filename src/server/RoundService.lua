--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local RoundConfig = require(BuildABugShared.Config.RoundConfig)
local MapConfig = require(BuildABugShared.Config.MapConfig)
local RoundEventConfig = require(BuildABugShared.Config.RoundEventConfig)

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

local function sendToActiveParticipants(state: string, payload)
	for _, entry in pairs(participants) do
		local player = entry.player
		if player and player.Parent == Players and not entry.eliminated then
			fireClient(player, state, payload)
		end
	end
end

local function clearPickups()
	local pickupsFolder = ArenaService.GetPickupsFolder()
	pickupsFolder:ClearAllChildren()
end

local function clearTemporaryHazards()
	if HazardService and HazardService.ClearHazards then
		HazardService.ClearHazards()
		return
	end

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

local function clampPickupPosition(position: Vector3, y: number?): Vector3
	return Vector3.new(
		math.clamp(position.X, -190, 190),
		y or position.Y,
		math.clamp(position.Z, -178, 158)
	)
end

local function getAlivePlayers()
	local result = {}
	for _, entry in pairs(participants) do
		local player = entry.player
		if player and player.Parent == Players and not entry.eliminated then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 then
				table.insert(result, player)
			end
		end
	end
	return result
end

local function getRandomAlivePlayer(): Player?
	local alive = getAlivePlayers()
	if #alive == 0 then
		return nil
	end
	return alive[math.random(1, #alive)]
end

local function getPositionNearPlayer(player: Player, radius: number, y: number): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	local angle = math.random() * math.pi * 2
	local distance = math.sqrt(math.random()) * radius
	local position = root.Position + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
	return clampPickupPosition(position, y)
end

local function getPositionNearAnyAlivePlayer(radius: number, y: number): Vector3
	local target = getRandomAlivePlayer()
	if target then
		local position = getPositionNearPlayer(target, radius, y)
		if position then
			return position
		end
	end
	return clampPickupPosition(ArenaService.GetRandomGroundPickupPosition(), y)
end

local function createCrumbPickup(position: Vector3, fallHeight: number?)
	local pickupsFolder = ArenaService.GetPickupsFolder()
	local finalPosition = clampPickupPosition(position, 2.0)
	local crumb = Instance.new("Part")
	crumb.Name = "Crumb"
	crumb.Size = Vector3.new(math.random(9, 16) / 10, math.random(5, 10) / 10, math.random(8, 14) / 10)
	crumb.Position = finalPosition
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
	crust.Anchored = false
	crust.Massless = true
	crust.CanCollide = false
	crust.CanTouch = false
	crust.Color = Color3.fromRGB(145, 90, 42)
	crust.Material = Enum.Material.SmoothPlastic
	crust.Parent = crumb

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = crumb
	weld.Part1 = crust
	weld.Parent = crumb

	wirePickupHitbox(crumb, crumb)

	if fallHeight and fallHeight > 0 then
		local landingCFrame = crumb.CFrame
		crumb.CFrame = landingCFrame + Vector3.new(0, fallHeight, 0)
		local fallTime = math.random(75, 125) / 100
		local tween = TweenService:Create(
			crumb,
			TweenInfo.new(fallTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ CFrame = landingCFrame }
		)
		tween:Play()
	end

	return crumb
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
	hitbox.Position = clampPickupPosition(position, position.Y)
	hitbox.Transparency = 1
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox:SetAttribute("Collected", false)
	hitbox:SetAttribute("PickupType", "DNA")
	hitbox.Parent = model
	model.PrimaryPart = hitbox

	local origin = hitbox.Position
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
		orbA.Position = origin + offsetA
		orbA.Anchored = true
		orbA.CanCollide = false
		orbA.CanTouch = false
		orbA.Color = Color3.fromRGB(60, 220, 255)
		orbA.Material = Enum.Material.Neon
		orbA.Parent = model

		local orbB = Instance.new("Part")
		orbB.Name = "HelixNodeB"
		orbB.Shape = Enum.PartType.Ball
		orbB.Size = Vector3.new(0.6, 0.6, 0.6)
		orbB.Position = origin + Vector3.new(-offsetA.X, y, -offsetA.Z)
		orbB.Anchored = true
		orbB.CanCollide = false
		orbB.CanTouch = false
		orbB.Color = Color3.fromRGB(120, 150, 255)
		orbB.Material = Enum.Material.Neon
		orbB.Parent = model

		local rung = Instance.new("Part")
		rung.Name = "HelixRung"
		rung.Size = Vector3.new(2.2, 0.12, 0.12)
		rung.Position = origin + Vector3.new(0, y, 0)
		rung.CFrame = CFrame.new(rung.Position) * CFrame.Angles(0, -angle, 0)
		rung.Anchored = true
		rung.CanCollide = false
		rung.CanTouch = false
		rung.Color = Color3.fromRGB(165, 235, 255)
		rung.Material = Enum.Material.Neon
		rung.Parent = model
	end

	wirePickupHitbox(hitbox, model)
end

local function spawnPickupWave()
	for _ = 1, RoundConfig.crumbsPerSpawn do
		local position
		if math.random() < 0.55 then
			position = getPositionNearAnyAlivePlayer(65, 2.0)
		else
			position = ArenaService.GetRandomGroundPickupPosition()
		end
		createCrumbPickup(position)
	end

	for _ = 1, RoundConfig.dnaPickupsPerSpawn do
		local position
		if math.random() < 0.65 then
			local height = math.random(3, 20)
			position = getPositionNearAnyAlivePlayer(55, height)
		else
			local useAir = math.random() < 0.6
			position = useAir and ArenaService.GetRandomAirPickupPosition() or ArenaService.GetRandomGroundPickupPosition()
		end
		createDnaPickup(position)
	end
end

local function getElapsedSeconds(): number
	return math.max(0, os.clock() - roundStartedAt)
end

local function triggerHazardForPhase(phase, forceTargeted: boolean?)
	local targetedChance = 0.6
	local radius = 14
	local warningScale = 1
	local extraChance = 0

	if phase.id == "Trouble" then
		targetedChance = 0.85
		radius = 10
		warningScale = 0.95
		extraChance = 0.18
	elseif phase.id == "Chaos" then
		targetedChance = 1
		radius = 7
		warningScale = 0.85
		extraChance = 0.38
	end

	if forceTargeted or math.random() < targetedChance then
		HazardService.WarnRandomHazardNearActivePlayer(radius, {
			warningScale = warningScale,
		})
	else
		local hazardId = HazardService.GetRandomHazardId()
		if hazardId then
			HazardService.WarnHazard(hazardId)
		end
	end

	if extraChance > 0 and math.random() < extraChance then
		task.delay(math.random(7, 14) / 10, function()
			if matchState == "Active" then
				HazardService.WarnRandomHazardNearActivePlayer(radius, {
					warningScale = warningScale,
				})
			end
		end)
	end
end

local function announceRoundEvent(event)
	local mapPayload = getMapPayload()
	sendToActiveParticipants("RoundEvent", {
		id = event.id,
		displayName = event.displayName,
		description = event.description,
		mapId = mapPayload.mapId,
		mapName = mapPayload.mapName,
	})
end

local function runCrumbShower(myRoundToken: number)
	for wave = 1, 4 do
		if matchState ~= "Active" or myRoundToken ~= roundToken then
			return
		end

		for _ = 1, 5 do
			local target = getRandomAlivePlayer()
			if target then
				local position = getPositionNearPlayer(target, 22, 2.0)
				if position then
					createCrumbPickup(position, math.random(22, 38))
				end
			end
		end

		if wave < 4 then
			task.wait(0.42)
		end
	end
end

local function runDnaBurst()
	for _ = 1, 14 do
		local target = getRandomAlivePlayer()
		if target then
			local height = math.random(3, 16)
			local position = getPositionNearPlayer(target, 24, height)
			if position then
				createDnaPickup(position)
			end
		end
	end
end

local function runDoubleTrouble(myRoundToken: number)
	HazardService.WarnRandomHazardNearActivePlayer(6, {
		warningScale = 0.9,
		damageScale = 1.05,
	})

	task.delay(0.8, function()
		if matchState == "Active" and myRoundToken == roundToken then
			HazardService.WarnRandomHazardNearActivePlayer(6, {
				warningScale = 0.85,
				damageScale = 1.05,
			})
		end
	end)
end

local function executeRoundEvent(event, myRoundToken: number)
	if matchState ~= "Active" or myRoundToken ~= roundToken then
		return
	end

	announceRoundEvent(event)

	if event.id == "CrumbShower" then
		task.spawn(runCrumbShower, myRoundToken)
	elseif event.id == "DnaBurst" then
		runDnaBurst()
	elseif event.id == "DoubleTrouble" then
		runDoubleTrouble(myRoundToken)
	end
end

local function runHazardLoop(myRoundToken: number)
	while matchState == "Active" and myRoundToken == roundToken do
		local phase = RoundEventConfig.GetPhase(getElapsedSeconds())
		local waitSeconds = math.random(phase.hazardMinSeconds, phase.hazardMaxSeconds)
		task.wait(waitSeconds)

		if matchState ~= "Active" or myRoundToken ~= roundToken then
			break
		end

		phase = RoundEventConfig.GetPhase(getElapsedSeconds())
		triggerHazardForPhase(phase, false)
	end
end

local function runPickupLoop(myRoundToken: number)
	while matchState == "Active" and myRoundToken == roundToken do
		spawnPickupWave()
		task.wait(RoundConfig.pickupSpawnIntervalSeconds or RoundConfig.crumbSpawnIntervalSeconds)
	end
end

local function runRoundEventLoop(myRoundToken: number)
	local lastEventId = nil

	while matchState == "Active" and myRoundToken == roundToken do
		local phase = RoundEventConfig.GetPhase(getElapsedSeconds())
		local waitSeconds = math.random(phase.eventMinSeconds, phase.eventMaxSeconds)
		task.wait(waitSeconds)

		if matchState ~= "Active" or myRoundToken ~= roundToken then
			break
		end

		local event = RoundEventConfig.GetRandomEvent()
		for _ = 1, 3 do
			if event.id ~= lastEventId then
				break
			end
			event = RoundEventConfig.GetRandomEvent()
		end

		lastEventId = event.id
		executeRoundEvent(event, myRoundToken)
	end
end

local function runFinalScramble(myRoundToken: number)
	local mapPayload = getMapPayload()
	sendToActiveParticipants("FinalScramble", {
		displayName = "FINAL SCRAMBLE!",
		description = "Everything at once! Grab DNA and keep moving!",
		mapId = mapPayload.mapId,
		mapName = mapPayload.mapName,
	})

	for _ = 1, 10 do
		local target = getRandomAlivePlayer()
		if target then
			local position = getPositionNearPlayer(target, 18, math.random(3, 12))
			if position then
				createDnaPickup(position)
			end
		end
	end

	task.spawn(runCrumbShower, myRoundToken)

	for barrage = 1, 5 do
		task.delay((barrage - 1) * 1.55, function()
			if matchState == "Active" and myRoundToken == roundToken then
				HazardService.WarnRandomHazardNearActivePlayer(5, {
					warningScale = 0.78,
					damageScale = 1.1,
				})
			end
		end)
	end
end

local function runPhaseLoop(myRoundToken: number)
	local currentPhaseId = nil
	local finalScrambleTriggered = false

	while matchState == "Active" and myRoundToken == roundToken do
		local elapsed = getElapsedSeconds()
		local phase = RoundEventConfig.GetPhase(elapsed)

		if phase.id ~= currentPhaseId then
			currentPhaseId = phase.id
			local mapPayload = getMapPayload()
			sendToActiveParticipants("PhaseChanged", {
				phaseId = phase.id,
				displayName = phase.displayName,
				elapsedSeconds = math.floor(elapsed),
				mapId = mapPayload.mapId,
				mapName = mapPayload.mapName,
			})

			if phase.id == "Trouble" then
				task.delay(1.0, function()
					if matchState == "Active" and myRoundToken == roundToken then
						triggerHazardForPhase(phase, true)
					end
				end)
			elseif phase.id == "Chaos" then
				task.delay(0.75, function()
					if matchState == "Active" and myRoundToken == roundToken then
						runDoubleTrouble(myRoundToken)
					end
				end)
			end
		end

		local remaining = RoundConfig.roundDurationSeconds - elapsed
		if not finalScrambleTriggered and remaining <= 10 then
			finalScrambleTriggered = true
			runFinalScramble(myRoundToken)
		end

		task.wait(0.35)
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

local function exitPlayer(player: Player)
	if matchState ~= "Active" then
		return
	end

	local entry = participants[player.UserId]
	if not entry or entry.eliminated then
		return
	end

	entry.eliminated = true
	entry.forfeited = true
	entry.survivedSeconds = math.max(0, math.floor(os.clock() - roundStartedAt))

	PlayerDataService.RestoreRoundSnapshot(player, {
		dna = entry.startDna,
		crumbs = entry.startCrumbs,
		foodCollected = entry.startFoodCollected,
	})

	player:SetAttribute("InRound", false)
	player:SetAttribute("QueuedForMatch", false)
	disconnectDeath(player)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
	end
	LobbyService.TeleportToLobby(player, 1)

	local remaining = countAliveParticipants()
	local mapPayload = getMapPayload()
	fireClient(player, "ExitedRound", {
		survivedSeconds = entry.survivedSeconds,
		playersRemaining = remaining,
		playerCount = countParticipants(),
		mapId = mapPayload.mapId,
		mapName = mapPayload.mapName,
		forfeitedRewards = true,
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
			local stats = data and data.stats or {}
			participants[player.UserId] = {
				player = player,
				eliminated = false,
				forfeited = false,
				survivedSeconds = nil,
				startDna = currency.dna or 0,
				startCrumbs = currency.crumbs or 0,
				startFoodCollected = stats.foodCollected or 0,
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
	task.spawn(runRoundEventLoop, myRoundToken)
	task.spawn(runPhaseLoop, myRoundToken)

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
		if player and player.Parent == Players and not entry.forfeited then
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

	remotes.ExitRoundRequest.OnServerEvent:Connect(function(player: Player)
		exitPlayer(player)
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
