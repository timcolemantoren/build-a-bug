--!nonstrict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CameraController = {}
local player = Players.LocalPlayer

local function applyCharacterCamera(character: Model?)
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 3)
	if humanoid then
		-- Lower the subject toward the welded bug visual while retaining Roblox's
		-- reliable third-person camera/controller behavior.
		humanoid.CameraOffset = Vector3.new(0, -1.35, 0)
	end
end

local function applyCameraStyle()
	player.CameraMinZoomDistance = 6
	player.CameraMaxZoomDistance = 18

	local camera = Workspace.CurrentCamera
	if camera then
		camera.FieldOfView = 74
	end
end

function CameraController.Init()
	applyCameraStyle()
	applyCharacterCamera(player.Character)

	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		applyCharacterCamera(character)
		applyCameraStyle()
	end)

	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		task.defer(applyCameraStyle)
	end)
end

return CameraController
