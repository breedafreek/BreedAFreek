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

GamePasses.list = {
	DoubleCoins = {
		id = 2037836799,
		name = "2x Coins",
		icon = "💰",
		price = 499,
		description = "Double coins from your Freeks, forever.",
		color = Color3.fromRGB(255, 200, 60),
	},
	FastBreeding = {
		id = 0,
		name = "Fast Fusing",
		icon = "⚡",
		price = 999,
		description = "Fusing takes half the time.",
		color = Color3.fromRGB(90, 200, 255),
	},
	LongerLock = {
		id = 0,
		name = "Longer Gate Lock",
		icon = "🔒",
		price = 499,
		description = "Your gate stays locked for 5 minutes instead of 3.",
		color = Color3.fromRGB(235, 90, 90),
	},
	ExtraSlot1 = {
		id = 0,
		name = "Extra Barn Slot 1",
		icon = "🧱",
		price = 299,
		description = "+1 barn slot on top of the 12 you can buy with coins.",
		color = Color3.fromRGB(230, 150, 90),
		slot = true,
	},
	ExtraSlot2 = {
		id = 0,
		name = "Extra Barn Slot 2",
		icon = "🧱",
		price = 299,
		description = "+1 barn slot on top of the 12 you can buy with coins.",
		color = Color3.fromRGB(230, 150, 90),
		slot = true,
	},
	ExtraSlot3 = {
		id = 0,
		name = "Extra Barn Slot 3",
		icon = "🧱",
		price = 299,
		description = "+1 barn slot on top of the 12 you can buy with coins.",
		color = Color3.fromRGB(230, 150, 90),
		slot = true,
	},
	ExtraPen = {
		id = 0,
		name = "Extra Fusion Den",
		icon = "🐣",
		price = 399,
		description = "A second Fusion Den, so you can fuse two pairs at once.",
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

function GamePasses.breedTimeMultiplier(player: Player): number
	return if GamePasses.has(player, "FastBreeding") then 0.5 else 1
end

function GamePasses.gateLockSeconds(player: Player): number
	return if GamePasses.has(player, "LongerLock") then 300 else Config.GATE_LOCK_SECONDS
end

-- How many breeding pens the player can use.
function GamePasses.penCount(player: Player): number
	return if GamePasses.has(player, "ExtraPen") then 2 else 1
end

-- How many Extra Yard Slot passes the player owns.
function GamePasses.passSlots(player: Player): number
	local count = 0
	for _, key in GamePasses.order do
		if GamePasses.list[key].slot and GamePasses.has(player, key) then
			count += 1
		end
	end
	return count
end

-- Kept as a hook so a future pass can raise the limit.
function GamePasses.maxFreeks(_player: Player): number
	return Config.MAX_FREEKS
end

return GamePasses
