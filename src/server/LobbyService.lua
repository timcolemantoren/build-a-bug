--!nonstrict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LobbyService = {}

local QUEUE_CENTER = Vector3.new(0, 1.05, 178)
local QUEUE_RADIUS = 18
local LOBBY_SPAWN = Vector3.new(0, 6, 145)

local ROUND_SPAWNS = {
	Vector3.new(0, 10, 55),
	Vector3.new(28, 10, 48),
	Vector3.new(-28, 10, 48),
	Vector3.new(48, 10, 15),
	Vector3.new(-48, 10, 15),
	Vector3.new(30, 10, -25),
	Vector3.new(-30, 10, -25),
	Vector3.new(0, 10, -48),
}

local lobbyFolder = nil
local queueCircle = nil
local boardLabel = nil

local function getArena()
	return Workspace:FindFirstChild("BuildABugArena") or Workspace:WaitForChild("BuildABugArena", 10)
end

local function horizontalDistance(a: Vector3, b: Vector3): number
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

local function clearLobbyArea(arena: Instance)
	for _, folderName in ipairs({ "GrassClumps", "Clutter", "StyleDetails" }) do
		local folder = arena:FindFirstChild(folderName)
		if folder then
			for _, item in ipairs(folder:GetDescendants()) do
				if item:IsA("BasePart") and horizontalDistance(item.Position, QUEUE_CENTER) < 29 then
					item:Destroy()
				end
			end
		end
	end
end

local function makeQueueCircle(parent: Instance)
	local circle = Instance.new("Part")
	circle.Name = "MatchQueueCircle"
	circle.Shape = Enum.PartType.Cylinder
	circle.Size = Vector3.new(0.18, QUEUE_RADIUS * 2, QUEUE_RADIUS * 2)
	circle.CFrame = CFrame.new(QUEUE_CENTER) * CFrame.Angles(0, 0, math.rad(90))
	circle.Anchored = true
	circle.CanCollide = false
	circle.CanTouch = false
	circle.CanQuery = false
	circle.Material = Enum.Material.Neon
	circle.Color = Color3.fromRGB(70, 220, 110)
	circle.Transparency = 0.5
	circle.Parent = parent
	return circle
end

local function makeNestPad(parent: Instance)
	local pad = Instance.new("Part")
	pad.Name = "NestLobbyPad"
	pad.Size = Vector3.new(72, 0.28, 66)
	pad.Position = Vector3.new(0, 0.7, 160)
	pad.Anchored = true
	pad.CanCollide = false
	pad.CanTouch = false
	pad.CanQuery = false
	pad.Material = Enum.Material.Ground
	pad.Color = Color3.fromRGB(90, 62, 38)
	pad.Transparency = 0.12
	pad.Parent = parent
end

local function makeBoard(parent: Instance)
	local anchor = Instance.new("Part")
	anchor.Name = "QueueBoardAnchor"
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = QUEUE_CENTER + Vector3.new(0, 14, 0)
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Parent = parent

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "QueueBoard"
	billboard.Size = UDim2.fromOffset(430, 150)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 115
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Name = "Status"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.18
	label.BackgroundColor3 = Color3.fromRGB(35, 42, 35)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.35
	label.Font = Enum.Font.GothamBold
	label.TextSize = 24
	label.TextWrapped = true
	label.Text = "NEXT MATCH\nStep inside the circle to join"
	label.Parent = billboard
	return label
end

function LobbyService.Build()
	local arena = getArena()
	if not arena then
		warn("[Build a Bug] LobbyService could not find arena")
		return
	end

	local old = arena:FindFirstChild("Lobby")
	if old then
		old:Destroy()
	end

	clearLobbyArea(arena)

	lobbyFolder = Instance.new("Folder")
	lobbyFolder.Name = "Lobby"
	lobbyFolder.Parent = arena

	makeNestPad(lobbyFolder)
	queueCircle = makeQueueCircle(lobbyFolder)
	boardLabel = makeBoard(lobbyFolder)
end

function LobbyService.IsPlayerInsideQueue(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end

	return horizontalDistance(root.Position, QUEUE_CENTER) <= QUEUE_RADIUS
end

function LobbyService.GetPlayersInsideQueue()
	local result = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("InRound") ~= true and LobbyService.IsPlayerInsideQueue(player) then
			table.insert(result, player)
		end
	end
	return result
end

function LobbyService.TeleportToLobby(player: Player, index: number?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local slot = index or 1
	local angle = ((slot - 1) % 8) * (math.pi / 4)
	local offset = Vector3.new(math.cos(angle) * 8, 0, math.sin(angle) * 8)
	root.CFrame = CFrame.new(LOBBY_SPAWN + offset)
end

function LobbyService.MoveIntoQueue(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local offset = Vector3.new(math.random(-5, 5), 5, math.random(-5, 5))
	root.CFrame = CFrame.new(QUEUE_CENTER + offset)
end

function LobbyService.TeleportToRound(player: Player, index: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local base = ROUND_SPAWNS[((index - 1) % #ROUND_SPAWNS) + 1]
	local cycle = math.floor((index - 1) / #ROUND_SPAWNS)
	local extra = Vector3.new((cycle % 3) * 5, 0, math.floor(cycle / 3) * 5)
	root.CFrame = CFrame.new(base + extra)
end

function LobbyService.SetBoard(state: string, seconds: number?, queuedCount: number?, mapName: string?)
	if not boardLabel then
		return
	end

	local count = queuedCount or 0
	local mapText = mapName or "Backyard"

	if state == "Countdown" then
		boardLabel.Text = string.format("%s\nMATCH STARTS IN %ss\n%s queued", mapText, tostring(seconds or 0), tostring(count))
		if queueCircle then
			queueCircle.Color = Color3.fromRGB(255, 205, 70)
		end
	elseif state == "Active" then
		boardLabel.Text = string.format("%s\nMATCH IN PROGRESS\nStand in the circle for the next match", mapText)
		if queueCircle then
			queueCircle.Color = Color3.fromRGB(85, 165, 255)
		end
	elseif state == "Results" then
		boardLabel.Text = string.format("%s\nROUND COMPLETE\nNext match forming...", mapText)
		if queueCircle then
			queueCircle.Color = Color3.fromRGB(180, 135, 255)
		end
	else
		boardLabel.Text = string.format("%s\nSTEP INSIDE TO JOIN\n%s queued", mapText, tostring(count))
		if queueCircle then
			queueCircle.Color = Color3.fromRGB(70, 220, 110)
		end
	end
end

function LobbyService.GetQueueCenter(): Vector3
	return QUEUE_CENTER
end

return LobbyService
