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

GamePasses.order = {
	"DoubleCoins",
	"FastBreeding",
	"LongerLock",
	"VIP",
	"ExtraPen",
	"ExtraSlot1",
	"ExtraSlot2",
	"ExtraSlot3",
}

-- The keys are the original names the passes were created under (their ids are live on
-- Roblox); name/description say what each one does now. Rename them on the dashboard to
-- match.
GamePasses.list = {
	DoubleCoins = {
		id = 2037836799,
		name = "2x Coins",
		icon = "💰",
		price = 499,
		description = "Double coins from your house, forever.",
		color = Color3.fromRGB(255, 200, 60),
	},
	FastBreeding = {
		id = 2037644787,
		name = "2x Speed",
		icon = "⚡",
		price = 999,
		description = "Your treadmill trains twice as much Speed.",
		color = Color3.fromRGB(90, 200, 255),
	},
	LongerLock = {
		id = 2039660564,
		name = "Longer Gate Lock",
		icon = "🔒",
		price = 499,
		description = "Your gate stays locked for 5 minutes instead of 3.",
		color = Color3.fromRGB(235, 90, 90),
	},
	ExtraSlot1 = {
		id = 2036624799,
		name = "Bigger Backpack 1",
		icon = "🎒",
		price = 199,
		description = "+20 backpack space for house parts.",
		color = Color3.fromRGB(230, 150, 90),
		backpack = true,
	},
	ExtraSlot2 = {
		id = 2040200325,
		name = "Bigger Backpack 2",
		icon = "🎒",
		price = 299,
		description = "+20 more backpack space for house parts.",
		color = Color3.fromRGB(230, 150, 90),
		backpack = true,
	},
	ExtraSlot3 = {
		id = 2037518787,
		name = "Bigger Backpack 3",
		icon = "🎒",
		price = 349,
		description = "+20 more backpack space for house parts.",
		color = Color3.fromRGB(230, 150, 90),
		backpack = true,
	},
	ExtraPen = {
		id = 2037308784,
		name = "Strong Arms",
		icon = "💪",
		price = 399,
		description = "Carrying a part never slows you down.",
		color = Color3.fromRGB(255, 130, 190),
	},
	VIP = {
		id = 2040272321,
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

function GamePasses.speedMultiplier(player: Player): number
	return if GamePasses.has(player, "FastBreeding") then 2 else 1
end

function GamePasses.gateLockSeconds(player: Player): number
	return if GamePasses.has(player, "LongerLock") then 300 else Config.GATE_LOCK_SECONDS
end

-- How many parts the player's backpack holds.
function GamePasses.backpackSize(player: Player): number
	local size = Config.MAX_PARTS
	for _, key in GamePasses.order do
		if GamePasses.list[key].backpack and GamePasses.has(player, key) then
			size += 20
		end
	end
	return size
end

-- How much carrying a part slows the player (1 = not at all).
function GamePasses.carrySlowdown(player: Player): number
	return if GamePasses.has(player, "ExtraPen") then 1 else 0.9
end

return GamePasses
