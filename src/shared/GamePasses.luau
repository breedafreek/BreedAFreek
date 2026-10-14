-- Game passes: one-time Robux purchases with permanent perks.
--
-- To make a pass live:
--   1. Publish the game, then go to create.roblox.com → your game → Monetization → Passes.
--   2. Create the pass (name, icon, price) and copy its ID number.
--   3. Paste the ID into `id` below. Passes with id = 0 show as "Coming soon".
-- `price` here is only what the Store shows; the real price is set on the dashboard.
--
-- The server marks owners with a player attribute "Pass_<key>", so any script (server or
-- client) can check a perk with GamePasses.has(player, key).

local Config = require(script.Parent.Config)

local GamePasses = {}

-- Set true to pretend every player owns every pass while testing in Studio.
GamePasses.STUDIO_GRANT_ALL = false

GamePasses.order = { "DoubleCoins", "FastBreeding", "LuckyBreeder", "LongerLock", "BigBackpack", "VIP" }

GamePasses.list = {
	DoubleCoins = {
		id = 0,
		name = "2x Coins",
		icon = "💰",
		price = 199,
		description = "Double coins from your Freeks, forever.",
		color = Color3.fromRGB(255, 200, 60),
	},
	FastBreeding = {
		id = 0,
		name = "Fast Breeding",
		icon = "⚡",
		price = 149,
		description = "Breeding takes half the time.",
		color = Color3.fromRGB(90, 200, 255),
	},
	LuckyBreeder = {
		id = 0,
		name = "Lucky Breeder",
		icon = "🍀",
		price = 249,
		description = "1.5x chance of new species and 2x mutation chance when breeding.",
		color = Color3.fromRGB(90, 220, 110),
	},
	LongerLock = {
		id = 0,
		name = "Longer Lock",
		icon = "🔒",
		price = 99,
		description = "Your gate stays locked for 5 minutes instead of 3.",
		color = Color3.fromRGB(235, 90, 90),
	},
	BigBackpack = {
		id = 0,
		name = "Big Backpack",
		icon = "🎒",
		price = 99,
		description = "Hold 100 Freeks instead of 50.",
		color = Color3.fromRGB(170, 120, 240),
	},
	VIP = {
		id = 0,
		name = "VIP",
		icon = "👑",
		price = 299,
		description = "Gold VIP badge on the leaderboard and in chat, plus +10% coins.",
		color = Color3.fromRGB(255, 180, 40),
	},
}

function GamePasses.has(player: Player, key: string): boolean
	return player:GetAttribute("Pass_" .. key) == true
end

-- Perks --------------------------------------------------------------------------

function GamePasses.coinMultiplier(player: Player): number
	local multiplier = 1
	if GamePasses.has(player, "DoubleCoins") then
		multiplier *= 2
	end
	if GamePasses.has(player, "VIP") then
		multiplier *= 1.1
	end
	return multiplier
end

function GamePasses.breedTimeMultiplier(player: Player): number
	return if GamePasses.has(player, "FastBreeding") then 0.5 else 1
end

-- Returns (recipe chance multiplier, mutation chance multiplier).
function GamePasses.breedingLuck(player: Player): (number, number)
	if GamePasses.has(player, "LuckyBreeder") then
		return 1.5, 2
	end
	return 1, 1
end

function GamePasses.gateLockSeconds(player: Player): number
	return if GamePasses.has(player, "LongerLock") then 300 else Config.GATE_LOCK_SECONDS
end

function GamePasses.maxFreeks(player: Player): number
	return if GamePasses.has(player, "BigBackpack") then 100 else Config.MAX_FREEKS
end

return GamePasses
