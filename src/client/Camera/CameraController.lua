--!nonstrict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CameraController = {}
local player = Players.LocalPlayer

local CAMERA_OFFSET_Y = -0.75

local function applyCharacterCamera(character: Model?)
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 3)
	if humanoid then
		-- Keep the bug itself low to the ground, but raise the gameplay viewpoint
		-- enough that hazards, paths, and nearby obstacles remain readable.
		humanoid.CameraOffset = Vector3.new(0, CAMERA_OFFSET_Y, 0)
	end
end

local function applyCameraStyle()
	player.CameraMinZoomDistance = 7
	player.CameraMaxZoomDistance = 22

	local camera = Workspace.CurrentCamera
	if camera then
		camera.FieldOfView = 72
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
