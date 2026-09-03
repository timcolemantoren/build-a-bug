--!nonstrict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PersistenceHardeningService = {}

local AUTOSAVE_INTERVAL_SECONDS = 60
local SHUTDOWN_SAVE_TIMEOUT_SECONDS = 8
local shuttingDown = false

local function safeSave(PlayerDataService, player: Player)
	if not player then
		return
	end

	local ok, err = pcall(function()
		PlayerDataService.SavePlayer(player)
	end)
	if not ok then
		warn("[Build a Bug] Persistence hardening save failed for", player.Name, err)
	end
end

function PersistenceHardeningService.Init(PlayerDataService)
	-- Studio uses a deliberately inflated test wallet. PlayerDataService already
	-- refuses to persist Studio data, and this early return avoids unnecessary
	-- DataStore calls/noise while testing locally.
	if RunService:IsStudio() then
		print("[Build a Bug] Persistence hardening active in live servers; Studio autosave disabled")
		return
	end

	shuttingDown = false

	-- PlayerDataService already saves on PlayerRemoving. This periodic autosave is
	-- the second safety net so a crash or abrupt disconnect can lose at most a short
	-- slice of progress rather than an entire play session.
	task.spawn(function()
		while not shuttingDown do
			task.wait(AUTOSAVE_INTERVAL_SECONDS)
			if shuttingDown then
				break
			end

			for _, player in ipairs(Players:GetPlayers()) do
				task.spawn(safeSave, PlayerDataService, player)
			end
		end
	end)

	-- Roblox gives servers a brief shutdown window. Save every player in parallel
	-- and wait a bounded amount of time so the server has a chance to flush current
	-- progression even when PlayerRemoving is not the only path out.
	game:BindToClose(function()
		shuttingDown = true

		local remaining = 0
		for _, player in ipairs(Players:GetPlayers()) do
			remaining += 1
			task.spawn(function()
				safeSave(PlayerDataService, player)
				remaining -= 1
			end)
		end

		local deadline = os.clock() + SHUTDOWN_SAVE_TIMEOUT_SECONDS
		while remaining > 0 and os.clock() < deadline do
			task.wait(0.1)
		end

		if remaining > 0 then
			warn(string.format("[Build a Bug] Server closed with %d player save(s) still pending", remaining))
		end
	end)
end

return PersistenceHardeningService
