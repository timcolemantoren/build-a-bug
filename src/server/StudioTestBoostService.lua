--!nonstrict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local StudioTestBoostService = {}

-- Studio-only test wallet. This is intentionally large enough to unlock the
-- current bug roster and premium-priced DNA cosmetics in a single session.
-- It does not increase Lifetime DNA and is never a live economy grant.
local STUDIO_AVAILABLE_DNA = 30000

function StudioTestBoostService.Init(PlayerDataService)
	if not RunService:IsStudio() then
		return
	end

	local function boost(player: Player)
		task.delay(0.35, function()
			local data = PlayerDataService.GetData(player)
			if not data then
				return
			end
			data.currency = data.currency or {}
			data.currency.dna = math.max(data.currency.dna or 0, STUDIO_AVAILABLE_DNA)
			PlayerDataService.SelectBug(player, data.selectedBug or "Ant")
			print(string.format("[Build a Bug] Studio progression test wallet: %s available DNA", tostring(STUDIO_AVAILABLE_DNA)))
		end)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		boost(player)
	end
	Players.PlayerAdded:Connect(boost)
end

return StudioTestBoostService
