--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildABugShared = ReplicatedStorage:WaitForChild("BuildABug")
local CosmeticStyles = require(BuildABugShared.Config.CosmeticStyles)

local EyeDetailService = {}
local VISUAL_MODEL_NAME = "BuildABugVisual"
local DETAIL_PREFIX = "EyeDetail"

local function clearDetails(model: Model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and string.sub(descendant.Name, 1, #DETAIL_PREFIX) == DETAIL_PREFIX then
			descendant:Destroy()
		end
	end
end

local function createDetailPart(model: Model, eye: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3)
	local part = Instance.new("Part")
	part.Name = DETAIL_PREFIX .. name
	part.Size = size
	part.CFrame = eye.CFrame * offset
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = eye
	weld.Part1 = part
	weld.Parent = part
	return part
end

local function applyCatEye(model: Model, style)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "Eye" then
			local eye = descendant
			local width = math.max(0.045, eye.Size.X * 0.16)
			local height = math.max(0.10, eye.Size.Y * 0.72)
			local depth = math.max(0.035, eye.Size.Z * 0.08)
			createDetailPart(
				model,
				eye,
				"CatSlit",
				Vector3.new(width, height, depth),
				CFrame.new(0, 0, -(eye.Size.Z * 0.49)),
				style.pupilColor or Color3.fromRGB(18, 20, 16)
			)
		end
	end
end

local function apply(player: Player, model: Model)
	clearDetails(model)
	local styleId = player:GetAttribute("EyeStyle") or "Default"
	local style = CosmeticStyles.EyeStyles[styleId] or CosmeticStyles.EyeStyles.Default
	if style.kind == "cat" then
		applyCatEye(model, style)
	end
end

local function refresh(player: Player)
	local character = player.Character
	local model = character and character:FindFirstChild(VISUAL_MODEL_NAME)
	if model and model:IsA("Model") then
		apply(player, model)
	end
end

local function watchCharacter(player: Player, character: Model)
	local function consider(child)
		if child:IsA("Model") and child.Name == VISUAL_MODEL_NAME then
			task.delay(0.34, function()
				if child.Parent then
					apply(player, child)
				end
			end)
		end
	end

	local current = character:FindFirstChild(VISUAL_MODEL_NAME)
	if current then
		consider(current)
	end
	character.ChildAdded:Connect(consider)
end

local function setupPlayer(player: Player)
	player:GetAttributeChangedSignal("EyeStyle"):Connect(function()
		task.delay(0.34, refresh, player)
	end)
	player:GetAttributeChangedSignal("SelectedBug"):Connect(function()
		task.delay(0.36, refresh, player)
	end)
	player.CharacterAdded:Connect(function(character)
		watchCharacter(player, character)
	end)
	if player.Character then
		watchCharacter(player, player.Character)
	end
end

function EyeDetailService.Init()
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)
end

return EyeDetailService
