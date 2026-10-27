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

local STARTUP_WAIT = 10 -- seconds to wait for each service before moving on

local SERVICES = {
	"Environment",
	"PlotService",
	"DiscoveryService",
	"EconomyService",
	"ActionService",
	"ZoneService",
	"StealService",
	"SpeedService",
	"NestService",
	"PassService",
	"LuckService",
	"EventService",
	"AdminService",
	"SeasonalService", -- after the map and homes exist
	"DataService",
}

for _, name in SERVICES do
	-- Startup shouldn't wait on anything. Each service starts in its own thread; if one is
	-- still starting after STARTUP_WAIT seconds, say which and carry on, so a stuck service
	-- can never stop players' data loading.
	local done = false
	setStatus("Starting " .. name .. "...")
	task.spawn(function()
		local ok, err = xpcall(function()
			require(Server[name]).init()
		end, debug.traceback)
		done = true
		if not ok then
			warn("[Steal a Life] " .. name .. " failed to start:\n" .. tostring(err))
			table.insert(problems, name .. " failed: " .. tostring(err))
		end
	end)
	local started = os.clock()
	while not done and os.clock() - started < STARTUP_WAIT do
		task.wait()
	end
	if not done then
		warn("[Steal a Life] " .. name .. " is slow to start (still going after " .. STARTUP_WAIT .. "s); carrying on")
	end
end
setStatus("Server started")
print("[Steal a Life] Server started, build " .. require(ReplicatedStorage.Shared.Config).BUILD)
