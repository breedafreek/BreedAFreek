-- Server entry point. Order matters: remotes and the map exist before players load.
-- Each service starts on its own, so if one breaks the rest of the game still loads and
-- the Output window says exactly which one failed and why.

local Server = script.Parent

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
	"ConveyorService",
	"SeasonalService", -- after the map and yards exist
	"DataService",
}

for _, name in SERVICES do
	local ok, err = xpcall(function()
		require(Server[name]).init()
	end, debug.traceback)
	if not ok then
		warn("[Fuse a Freek] " .. name .. " failed to start:\n" .. tostring(err))
	end
end
print("[Fuse a Freek] Server started")
