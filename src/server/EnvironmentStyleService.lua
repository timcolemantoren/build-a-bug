--!nonstrict

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local EnvironmentStyleService = {}

local function getOrCreateEffect(className: string, name: string)
	local existing = Lighting:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end

	if existing then
		existing:Destroy()
	end

	local effect = Instance.new(className)
	effect.Name = name
	effect.Parent = Lighting
	return effect
end

local function configureLighting()
	Lighting.ClockTime = 14.35
	Lighting.Brightness = 2.1
	Lighting.Ambient = Color3.fromRGB(112, 105, 94)
	Lighting.OutdoorAmbient = Color3.fromRGB(138, 139, 132)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 244, 220)
	Lighting.ColorShift_Bottom = Color3.fromRGB(220, 225, 235)
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.32
	Lighting.ShadowSoftness = 0.42
	Lighting.GlobalShadows = true

	local atmosphere = getOrCreateEffect("Atmosphere", "BuildABugAtmosphere")
	atmosphere.Density = 0.2
	atmosphere.Offset = 0.08
	atmosphere.Color = Color3.fromRGB(214, 225, 235)
	atmosphere.Decay = Color3.fromRGB(175, 155, 128)
	atmosphere.Glare = 0.08
	atmosphere.Haze = 1.15

	local color = getOrCreateEffect("ColorCorrectionEffect", "BuildABugColor")
	color.Brightness = 0.015
	color.Contrast = 0.07
	color.Saturation = 0.04
	color.TintColor = Color3.fromRGB(255, 249, 238)

	local bloom = getOrCreateEffect("BloomEffect", "BuildABugBloom")
	bloom.Intensity = 0.16
	bloom.Size = 18
	bloom.Threshold = 1.45

	local rays = getOrCreateEffect("SunRaysEffect", "BuildABugSunRays")
	rays.Intensity = 0.035
	rays.Spread = 0.72
end

local function makeDirtPatch(parent: Instance, index: number)
	local patch = Instance.new("Part")
	patch.Name = "DirtPatch" .. index
	patch.Shape = Enum.PartType.Cylinder
	local diameter = math.random(14, 48)
	patch.Size = Vector3.new(0.08, diameter, math.random(10, diameter))
	patch.CFrame = CFrame.new(math.random(-198, 198), 0.54, math.random(-198, 198)) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(math.random(-2, 2)), math.rad(math.random(0, 180)), 0)
	patch.Anchored = true
	patch.CanCollide = false
	patch.CanTouch = false
	patch.CanQuery = false
	patch.Material = Enum.Material.Ground
	local shade = math.random(-16, 18)
	patch.Color = Color3.fromRGB(116 + shade, 82 + math.floor(shade * 0.7), 53 + math.floor(shade * 0.45))
	patch.Transparency = math.random(18, 48) / 100
	patch.Parent = parent
end

local function makeDirtClod(parent: Instance, index: number)
	local clod = Instance.new("Part")
	clod.Name = "DirtClod" .. index
	clod.Shape = Enum.PartType.Ball
	clod.Size = Vector3.new(math.random(8, 30) / 10, math.random(5, 18) / 10, math.random(8, 30) / 10)
	clod.Position = Vector3.new(math.random(-198, 198), 0.55 + clod.Size.Y / 3, math.random(-198, 198))
	clod.Orientation = Vector3.new(math.random(0, 25), math.random(0, 180), math.random(0, 25))
	clod.Anchored = true
	clod.CanCollide = false
	clod.CanTouch = false
	clod.Material = math.random() < 0.35 and Enum.Material.Mud or Enum.Material.Ground
	clod.Color = Color3.fromRGB(98 + math.random(0, 30), 65 + math.random(0, 24), 39 + math.random(0, 20))
	clod.Parent = parent
end

local function addGroundVariation(arena: Instance)
	local old = arena:FindFirstChild("StyleDetails")
	if old then
		old:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "StyleDetails"
	folder.Parent = arena

	for i = 1, 72 do
		makeDirtPatch(folder, i)
	end

	for i = 1, 110 do
		makeDirtClod(folder, i)
	end
end

local function styleArena(arena: Instance)
	local dirtFloor = arena:FindFirstChild("DirtFloor")
	if dirtFloor and dirtFloor:IsA("BasePart") then
		dirtFloor.Material = Enum.Material.Ground
		dirtFloor.Color = Color3.fromRGB(112, 79, 50)
	end

	for _, item in ipairs(arena:GetDescendants()) do
		if not item:IsA("BasePart") then
			continue
		end

		local name = item.Name

		if string.find(name, "Pebble") or string.find(name, "Rock") then
			item.Material = Enum.Material.Rock
			item.Reflectance = 0
		elseif string.find(name, "Twig") or name == "BarkTunnel" then
			item.Material = Enum.Material.Wood
		elseif string.find(name, "Grass") then
			item.Material = Enum.Material.Grass
		elseif string.find(name, "HoseSegment") then
			item.Material = Enum.Material.Rubber
		elseif name == "HoseNozzle" then
			item.Material = Enum.Material.Metal
			item.Reflectance = 0.08
		elseif string.find(name, "LittlePuddle") then
			item.Material = Enum.Material.Glass
			item.Transparency = 0.24
			item.Reflectance = 0.08
		elseif name == "BrokenPot" then
			item.Material = Enum.Material.Brick
		end

		-- Trigger planes are gameplay helpers, not scenery. Keep them nearly invisible.
		if item:GetAttribute("IsEnvironmentZone") then
			item.Transparency = 0.94
		end
	end

	addGroundVariation(arena)
end

function EnvironmentStyleService.Init()
	configureLighting()

	local arena = Workspace:FindFirstChild("BuildABugArena") or Workspace:WaitForChild("BuildABugArena", 10)
	if arena then
		styleArena(arena)
	end
end

return EnvironmentStyleService
