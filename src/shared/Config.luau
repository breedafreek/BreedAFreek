-- Tuning knobs for the whole game. Change numbers here, not in the services.

local Config = {
	START_MONEY = 50,
	START_SLOTS = 4, -- yard slots a new player gets
	MAX_SLOTS = 12, -- most yard slots you can buy with coins
	PASS_SLOTS = 3, -- extra slots from the three Extra Yard Slot game passes (15 pads per yard)
	MAX_FREEKS = 50, -- yard + backpack combined

	SLOT_BASE_PRICE = 250,
	SLOT_PRICE_GROWTH = 2.2, -- each extra slot costs this much more than the last

	SELL_MULTIPLIER = 20, -- a Freek sells for (money per second * this)

	OFFLINE_RATE = 0.5, -- earn 50% of normal income while offline
	OFFLINE_MAX_SECONDS = 8 * 60 * 60, -- capped at 8 hours

	AUTOSAVE_INTERVAL = 60,
	SESSION_LOCK_TIMEOUT = 150, -- seconds before another server may take over a player's save

	PLOT_COUNT = 6, -- set the place's Max Players to this in Game Settings

	REBIRTH_BASE_COST = 100000, -- coins needed for the first rebirth
	REBIRTH_COST_GROWTH = 4, -- each rebirth costs this many times more than the last
	REBIRTH_INCOME_BONUS = 0.5, -- +50% income per rebirth, forever

	GATE_LOCK_SECONDS = 180, -- how long the gate stays locked each time the owner locks it
	STEAL_HOLD_SECONDS = 1.5, -- how long a thief holds the prompt to pick up a Freek
	SNATCH_HOLD_SECONDS = 1, -- how long another player holds the prompt to snatch a carried Freek
}

function Config.slotPrice(currentSlots: number): number
	return math.floor(Config.SLOT_BASE_PRICE * Config.SLOT_PRICE_GROWTH ^ (currentSlots - Config.START_SLOTS))
end

function Config.rebirthCost(rebirths: number): number
	return math.floor(Config.REBIRTH_BASE_COST * Config.REBIRTH_COST_GROWTH ^ rebirths)
end

function Config.incomeMultiplier(rebirths: number): number
	return 1 + (rebirths or 0) * Config.REBIRTH_INCOME_BONUS
end

return Config
