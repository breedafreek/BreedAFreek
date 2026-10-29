-- Tuning knobs for the whole game. Change numbers here, not in the services.

local Config = {
	BUILD = "life-33", -- printed in Output: which build is running
	START_MONEY = 50,
	-- TESTING ONLY: every player is topped up to this many coins when they join. Set to nil
	-- before the game launches!
	TEST_MONEY = 1_000_000,
	-- Who can open the admin panel (events, part spawns, announcements). Usernames are
	-- checked as well as user ids; anyone can use it in Studio for testing.
	ADMIN_NAMES = { "FuseAFreek" }, -- the owner's Roblox username
	ADMIN_USER_IDS = { 11813437895 } :: { number }, -- the owner's account
	MAX_PARTS = 40, -- house parts you can keep in your backpack (not counting the house)
	SELL_MULTIPLIER = 30, -- a part sells for (its money per second * this)

	-- The treadmill in your yard trains Speed while you run on it. Level 1 gives
	-- TREADMILL_BASE_GAIN speed a second; each level multiplies that by TREADMILL_GAIN_GROWTH.
	TREADMILL_BASE_GAIN = 2,
	TREADMILL_GAIN_GROWTH = 1.9,
	TREADMILL_BASE_COST = 150, -- coins for level 2
	TREADMILL_COST_GROWTH = 2.8,
	TREADMILL_MAX = 20,

	OFFLINE_RATE = 0.5, -- earn 50% of normal income while offline
	OFFLINE_MAX_SECONDS = 8 * 60 * 60, -- capped at 8 hours

	AUTOSAVE_INTERVAL = 60,
	SESSION_LOCK_TIMEOUT = 150, -- seconds before another server may take over a player's save

	PLOT_COUNT = 8, -- 4 homes each side of the street; set the place's Max Players to this

	GRAB_HOLD_SECONDS = 0.5, -- how long to hold the prompt to grab an egg in a zone
}

-- Plot upgrades (coins): each level unlocks another yard spot, garden bed and pet place.
Config.PLOT_MAX = 5

-- What a plot level holds: yard spots, garden beds and pets.
function Config.plotSpaces(level: number): { yard: number, garden: number, pets: number }
	level = math.clamp(level or 1, 1, Config.PLOT_MAX)
	return { yard = level + 1, garden = level + 1, pets = level + 3 }
end

-- Coins to upgrade a plot from `level` to the next level.
function Config.plotCost(level: number): number
	return math.floor(2000 * 6 ^ (level - 1))
end

-- House upgrades (coins): the house grows bigger each level, and some slots only open up
-- at a higher level (the rest are there from level 1).
Config.HOUSE_MAX = 8
Config.HOUSE_SLOT_LEVEL = { Porch = 2, Chimney = 3, Garden = 4, Tower = 5 }

function Config.houseSlotOpen(level: number, slotId: string): boolean
	return (level or 1) >= (Config.HOUSE_SLOT_LEVEL[slotId] or 1)
end

-- How big the house is drawn at a level (1x at level 1, 1.25x at the top level).
function Config.houseScale(level: number): number
	return 1 + 0.25 * (math.clamp(level or 1, 1, Config.HOUSE_MAX) - 1) / (Config.HOUSE_MAX - 1)
end

-- Coins to upgrade a house from `level` to the next level.
function Config.houseCost(level: number): number
	return math.floor(1000 * 5 ^ (level - 1))
end

-- Speed a second from a treadmill of this level (before pass bonuses).
function Config.treadmillGain(level: number): number
	return Config.TREADMILL_BASE_GAIN * Config.TREADMILL_GAIN_GROWTH ^ (level - 1)
end

-- Coins to upgrade a treadmill from `level` to the next level.
function Config.treadmillCost(level: number): number
	return math.floor(Config.TREADMILL_BASE_COST * Config.TREADMILL_COST_GROWTH ^ (level - 1))
end

return Config
