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
local boardMapLabel = nil
local boardStateLabel = nil
local boardInstructionLabel = nil

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
	pad.Position = Vector3.new(0, 0.78, 160)
	pad.Anchored = true
	pad.CanCollide = false
	pad.CanTouch = false
	pad.CanQuery = false
	pad.Material = Enum.Material.Ground
	pad.Color = Color3.fromRGB(90, 62, 38)
	pad.Transparency = 0.12
	pad.Parent = parent
end

local function makeBoardLabel(parent: Instance, name: string, position: UDim2, size: UDim2, font, textSize: number, color: Color3)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextStrokeColor3 = Color3.fromRGB(12, 20, 22)
	label.TextStrokeTransparency = 0.82
	label.Font = font
	label.TextSize = textSize
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function setBoardText(mapText: string, stateText: string, instructionText: string)
	if boardMapLabel then
		boardMapLabel.Text = mapText
	end
	if boardStateLabel then
		boardStateLabel.Text = stateText
	end
	if boardInstructionLabel then
		boardInstructionLabel.Text = instructionText
	end
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
	billboard.Size = UDim2.fromOffset(430, 145)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 115
	billboard.LightInfluence = 0
	billboard.Parent = anchor

	local panel = Instance.new("Frame")
	panel.Name = "BoardPanel"
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundTransparency = 0.10
	panel.BackgroundColor3 = Color3.fromRGB(25, 43, 48)
	panel.BorderSizePixel = 0
	panel.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(117, 188, 151)
	stroke.Thickness = 2
	stroke.Transparency = 0.28
	stroke.Parent = panel

	boardMapLabel = makeBoardLabel(
		panel,
		"MapName",
		UDim2.fromOffset(18, 10),
		UDim2.new(1, -36, 0, 30),
		Enum.Font.FredokaOne,
		20,
		Color3.fromRGB(250, 246, 232)
	)
	boardStateLabel = makeBoardLabel(
		panel,
		"MatchState",
		UDim2.fromOffset(18, 37),
		UDim2.new(1, -36, 0, 40),
		Enum.Font.FredokaOne,
		27,
		Color3.fromRGB(250, 246, 232)
	)
	boardInstructionLabel = makeBoardLabel(
		panel,
		"Instruction",
		UDim2.fromOffset(22, 82),
		UDim2.new(1, -44, 0, 45),
		Enum.Font.GothamMedium,
		17,
		Color3.fromRGB(225, 235, 229)
	)

	setBoardText("Backyard", "NEXT MATCH", "Step inside the circle to join")
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
	makeBoard(lobbyFolder)
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
	if not boardStateLabel then
		return
	end

	local count = queuedCount or 0
	local mapText = mapName or "Backyard"

	if state == "Countdown" then
		setBoardText(mapText, string.format("MATCH STARTS IN %ss", tostring(seconds or 0)), string.format("%s queued", tostring(count)))
		if queueCircle then
			queueCircle.Color = Color3.fromRGB(255, 205, 70)
		end
	elseif state == "Locked" then
		setBoardText(mapText, string.format("ROSTER LOCKED  •  %ss", tostring(seconds or 0)), string.format("%s playing", tostring(count)))
		if queueCircle then
			queueCircle.Color = Color3.fromRGB(255, 125, 70)
		end
	elseif state == "Active" then
		setBoardText(mapText, "MATCH IN PROGRESS", "Stand in the circle for the next match")
		if queueCircle then
			queueCircle.Color = Color3.fromRGB(85, 165, 255)
		end
	elseif state == "Results" then
		setBoardText(mapText, "ROUND COMPLETE", "Next match forming...")
		if queueCircle then
			queueCircle.Color = Color3.fromRGB(180, 135, 255)
		end
	else
		setBoardText(mapText, "STEP INSIDE TO JOIN", string.format("%s queued", tostring(count)))
		if queueCircle then
			queueCircle.Color = Color3.fromRGB(70, 220, 110)
		end
	end
end

function LobbyService.GetQueueCenter(): Vector3
	return QUEUE_CENTER
end

return LobbyService
