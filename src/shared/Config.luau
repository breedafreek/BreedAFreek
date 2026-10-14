-- Tuning knobs for the whole game. Change numbers here, not in the services.

local Config = {
	START_MONEY = 100,
	START_SLOTS = 4, -- yard slots a new player gets
	MAX_SLOTS = 12, -- most yard slots anyone can own
	MAX_FREEKS = 50, -- yard + backpack combined

	SLOT_BASE_PRICE = 250,
	SLOT_PRICE_GROWTH = 2.2, -- each extra slot costs this much more than the last

	SELL_MULTIPLIER = 20, -- a Freek sells for (money per second * this)

	OFFLINE_RATE = 0.5, -- earn 50% of normal income while offline
	OFFLINE_MAX_SECONDS = 8 * 60 * 60, -- capped at 8 hours

	AUTOSAVE_INTERVAL = 60,
	SESSION_LOCK_TIMEOUT = 150, -- seconds before another server may take over a player's save

	PLOT_COUNT = 6, -- set the place's Max Players to this in Game Settings
}

function Config.slotPrice(currentSlots: number): number
	return math.floor(Config.SLOT_BASE_PRICE * Config.SLOT_PRICE_GROWTH ^ (currentSlots - Config.START_SLOTS))
end

return Config
