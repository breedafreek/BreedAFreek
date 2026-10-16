-- Server entry point. Order matters: remotes and the map exist before players load.
-- Each service starts on its own, so if one breaks the rest of the game still loads and
-- the Output window says exactly which one failed and why.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = script.Parent

-- Shown on players' screens if the game doesn't finish loading (see client Main), so
-- problems are visible without digging through Output.
local problems = {}
local function setStatus(text: string)
	local lines = table.clone(problems)
	table.insert(lines, text)
	ReplicatedStorage:SetAttribute("ServerStartup", table.concat(lines, "\n"))
end

local SERVICES = {
	"Environment",
	"PlotService",
	"DiscoveryService",
	"EconomyService",
	"ActionService",
	"TradeService",
	"StealService",
	"WeaponService",
	"RebirthService",
	"PassService",
	"CannonService",
	"LuckService",
	"EventService",
	"AdminService",
	"SeasonalService", -- after the map and yards exist
	"DataService",
}

for _, name in SERVICES do
	-- Startup shouldn't wait on anything; if a service hangs, say which one.
	local done = false
	setStatus("Starting " .. name .. "...")
	task.delay(5, function()
		if not done then
			warn("[Fuse a Freek] " .. name .. " is stuck starting up (still waiting after 5 seconds)")
		end
	end)
	local ok, err = xpcall(function()
		require(Server[name]).init()
	end, debug.traceback)
	done = true
	if not ok then
		warn("[Fuse a Freek] " .. name .. " failed to start:\n" .. tostring(err))
		table.insert(problems, name .. " failed: " .. tostring(err))
	end
end
setStatus("Server started")
print("[Fuse a Freek] Server started")
