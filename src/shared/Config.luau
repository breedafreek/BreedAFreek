-- Tuning knobs for the whole game. Change numbers here, not in the services.

local Config = {
	START_MONEY = 50,
	-- TESTING ONLY: every player is topped up to this many coins when they join (and after
	-- a rebirth). Set to nil before the game launches!
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
	REBIRTH_SPEED_BONUS = 0.5, -- each rebirth: +50% speed from the treadmill, forever

	OFFLINE_RATE = 0.5, -- earn 50% of normal income while offline
	OFFLINE_MAX_SECONDS = 8 * 60 * 60, -- capped at 8 hours

	AUTOSAVE_INTERVAL = 60,
	SESSION_LOCK_TIMEOUT = 150, -- seconds before another server may take over a player's save

	PLOT_COUNT = 8, -- 4 homes each side of the street; set the place's Max Players to this

	REBIRTH_BASE_COST = 100000, -- coins needed for the first rebirth
	REBIRTH_COST_GROWTH = 4, -- each rebirth costs this many times more than the last
	REBIRTH_INCOME_BONUS = 0.5, -- +50% income per rebirth, forever

	GRAB_HOLD_SECONDS = 0.5, -- how long to hold the prompt to grab an egg in a zone
}

-- Speed a second from a treadmill of this level (before rebirth and pass bonuses).
function Config.treadmillGain(level: number): number
	return Config.TREADMILL_BASE_GAIN * Config.TREADMILL_GAIN_GROWTH ^ (level - 1)
end

-- Coins to upgrade a treadmill from `level` to the next level.
function Config.treadmillCost(level: number): number
	return math.floor(Config.TREADMILL_BASE_COST * Config.TREADMILL_COST_GROWTH ^ (level - 1))
end

function Config.speedMultiplier(rebirths: number): number
	return 1 + (rebirths or 0) * Config.REBIRTH_SPEED_BONUS
end

function Config.rebirthCost(rebirths: number): number
	return math.floor(Config.REBIRTH_BASE_COST * Config.REBIRTH_COST_GROWTH ^ rebirths)
end

function Config.incomeMultiplier(rebirths: number): number
	return 1 + (rebirths or 0) * Config.REBIRTH_INCOME_BONUS
end

return Config
