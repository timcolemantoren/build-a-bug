--!nonstrict

local Workspace = game:GetService("Workspace")

local EnvironmentClutterPolishService = {}

local LEAF_COLORS = {
	Color3.fromRGB(91, 126, 52),
	Color3.fromRGB(112, 142, 55),
	Color3.fromRGB(132, 118, 47),
	Color3.fromRGB(147, 101, 43),
	Color3.fromRGB(122, 78, 39),
	Color3.fromRGB(81, 111, 49),
}

local function polishLeaves(arena: Instance)
	local clutter = arena:FindFirstChild("Clutter")
	if not clutter then
		return
	end

	for _, item in ipairs(clutter:GetChildren()) do
		if item:IsA("BasePart") and string.find(item.Name, "FallenLeaf") == 1 then
			local seed = tonumber(string.match(item.Name, "%d+")) or 1
			local length = math.clamp(item.Size.X * 0.72, 6.5, 14)
			local width = math.clamp(item.Size.Z * 0.82, 3.4, 7.2)
			local thickness = 0.24 + (seed % 3) * 0.04
			local yaw = math.rad((seed * 37) % 180)
			local tiltX = math.rad(((seed * 7) % 5) - 2)
			local tiltZ = math.rad(((seed * 11) % 5) - 2)

			-- The arena generator uses simple rectangles for leaf litter. Flattened
			-- ellipsoids keep the same low-cost one-Part footprint but read much more
			-- like organic leaves from bug height.
			item.Shape = Enum.PartType.Ball
			item.Size = Vector3.new(length, thickness, width)
			item.CFrame = CFrame.new(item.Position.X, 0.72 + thickness / 2, item.Position.Z)
				* CFrame.Angles(tiltX, yaw, tiltZ)
			item.Color = LEAF_COLORS[((seed - 1) % #LEAF_COLORS) + 1]
			item.Material = Enum.Material.Fabric
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = false
			item.Reflectance = 0
		end
	end
end

function EnvironmentClutterPolishService.Init()
	local arena = Workspace:FindFirstChild("BuildABugArena") or Workspace:WaitForChild("BuildABugArena", 10)
	if not arena then
		warn("[Build a Bug] EnvironmentClutterPolishService could not find arena")
		return
	end

	polishLeaves(arena)
end

return EnvironmentClutterPolishService
