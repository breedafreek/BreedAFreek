-- Runs the day and night cycle (DayNight.luau) on the server. At nightfall every zone's
-- eggs are swapped for new random ones and everyone is told; while it's night, the eggs in
-- every nest grow NIGHT_SPEED times as fast (each second of night counts as NIGHT_SPEED).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DayNight = require(ReplicatedStorage.Shared.DayNight)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local ZoneService = require(script.Parent.ZoneService)

local DayNightService = {}

-- Moves every growing egg `seconds` closer to hatching. The whole growing window shifts
-- back, so its weight curve (startAt..endsAt) moves along with it.
local function speedUpNests(seconds: number)
	local now = os.time()
	for player, data in DataService.all() do
		local changed = false
		for _, egg in data.nests or {} do
			if egg.endsAt and egg.endsAt > now then
				local shift = math.min(seconds, egg.endsAt - now)
				egg.endsAt -= shift
				if egg.startAt then
					egg.startAt -= shift
				end
				changed = true
			end
		end
		if changed then
			DataService.changed(player)
		end
	end
end

function DayNightService.init()
	local notify = Remotes.get("Notify")
	local wasNight = DayNight.isNight()
	task.spawn(function()
		while true do
			task.wait(1)
			local night = DayNight.isNight()
			if night and not wasNight then
				local ok, err = pcall(ZoneService.restock)
				if not ok then
					warn("[DayNightService] " .. tostring(err))
				end
				for _, player in Players:GetPlayers() do
					notify:FireClient(
						player,
						"🌙 Night! New eggs in every zone, and your eggs hatch x"
							.. DayNight.NIGHT_SPEED
							.. " faster!",
						"discovery"
					)
				end
			elseif wasNight and not night then
				for _, player in Players:GetPlayers() do
					notify:FireClient(player, "☀️ Good morning!", "success")
				end
			end
			wasNight = night
			if night then
				-- This second counts as NIGHT_SPEED seconds: NIGHT_SPEED - 1 extra.
				local ok, err = pcall(speedUpNests, DayNight.NIGHT_SPEED - 1)
				if not ok then
					warn("[DayNightService] " .. tostring(err))
				end
			end
		end
	end)
end

return DayNightService
