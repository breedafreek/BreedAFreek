-- Luck: Lucky Crates, the daily Lucky Wheel and Lucky Hour events. Shared so the client
-- can show every chance on screen (players always see the odds), while the server does
-- all the rolling (server/LuckService).
--
-- Everything here is bought with coins or free; nothing is sold for Robux, and every
-- crate always gives a Freek.

local Rarities = require(script.Parent.Rarities)

local Luck = {}

-- Crates crack open into a random Freek. odds are weights per rarity (shown as %).
-- mutation multiplies each mutation's normal chance (see Mutations.luau).
Luck.CRATES = {
	{
		id = "Bronze",
		name = "Bronze Crate",
		price = 400,
		color = Color3.fromRGB(205, 130, 70),
		odds = { Common = 75, Uncommon = 22, Rare = 3 },
		mutation = 0.5,
	},
	{
		id = "Silver",
		name = "Silver Crate",
		price = 1500,
		color = Color3.fromRGB(200, 210, 225),
		odds = { Common = 35, Uncommon = 45, Rare = 17, Legendary = 3 },
		mutation = 1,
	},
	{
		id = "Gold",
		name = "Gold Crate",
		price = 9000,
		color = Color3.fromRGB(255, 200, 60),
		odds = { Uncommon = 25, Rare = 45, Legendary = 25, Mystic = 5 },
		mutation = 1.5,
	},
	{
		id = "Diamond",
		name = "Diamond Crate",
		price = 25000,
		color = Color3.fromRGB(110, 220, 255),
		odds = { Rare = 40, Legendary = 40, Mystic = 18, Ultra = 2 },
		mutation = 2.5,
	},
}
Luck.crateById = {}
for _, crate in Luck.CRATES do
	Luck.crateById[crate.id] = crate
end

-- The crate's odds as a list, rarest last, with percentages: { { rarity, percent } }.
function Luck.oddsList(crate)
	local total = 0
	for _, weight in crate.odds do
		total += weight
	end
	local list = {}
	for _, rarity in Rarities.order do
		local weight = crate.odds[rarity]
		if weight then
			table.insert(list, { rarity = rarity, percent = weight / total * 100 })
		end
	end
	return list
end

-- The Lucky Wheel: one free spin a day (twice a day with VIP). Coin prizes are minutes of
-- the player's own income, so they stay worth it as the player grows.
Luck.SPIN_COOLDOWN = 24 * 60 * 60
Luck.VIP_SPIN_COOLDOWN = 12 * 60 * 60
Luck.WHEEL = {
	{ label = "Coins", minutes = 3, weight = 30, color = Color3.fromRGB(110, 235, 140) },
	{ label = "Bronze Crate", crate = "Bronze", weight = 25, color = Color3.fromRGB(205, 130, 70) },
	{ label = "Big Coins", minutes = 10, weight = 15, color = Color3.fromRGB(60, 200, 110) },
	{ label = "Silver Crate", crate = "Silver", weight = 12, color = Color3.fromRGB(200, 210, 225) },
	{ label = "Golden Freek", golden = true, weight = 6, color = Color3.fromRGB(255, 220, 90) },
	{ label = "Gold Crate", crate = "Gold", weight = 6, color = Color3.fromRGB(255, 200, 60) },
	{ label = "Huge Coins", minutes = 30, weight = 5, color = Color3.fromRGB(40, 160, 90) },
	{ label = "JACKPOT", crate = "Diamond", weight = 1, color = Color3.fromRGB(110, 220, 255) },
}
Luck.MIN_COIN_PRIZE = 200 -- coin prizes are never less than this

function Luck.wheelPercent(index: number): number
	local total = 0
	for _, slice in Luck.WHEEL do
		total += slice.weight
	end
	return Luck.WHEEL[index].weight / total * 100
end

-- Lucky Hour events: every so often a random one runs server-wide for DURATION seconds.
-- The current one is published as ReplicatedStorage attributes (see Luck.current).
Luck.EVENT_DURATION = 10 * 60
Luck.EVENT_GAP = { 20 * 60, 35 * 60 } -- seconds between events (random in this range)
Luck.FIRST_EVENT_AFTER = 3 * 60 -- the first one comes soon after a server starts
Luck.EVENTS = {
	Rainbow = {
		name = "Rainbow Hour",
		icon = "🌈",
		description = "Cannon Freeks are 5x as likely to be mutated!",
		color = Color3.fromRGB(255, 120, 255),
		mutationBoost = 5,
	},
	LuckySkies = {
		name = "Lucky Skies",
		icon = "🍀",
		description = "Rare and better Freeks come out of the cannons 3x as often!",
		color = Color3.fromRGB(90, 230, 120),
		rareBoost = 3,
	},
	RapidFire = {
		name = "Rapid Fire",
		icon = "💥",
		description = "The cannons fire twice as fast!",
		color = Color3.fromRGB(255, 140, 50),
		fireRate = 2,
	},
	CrateFrenzy = {
		name = "Crate Frenzy",
		icon = "📦",
		description = "Lucky Crates are 30% off!",
		color = Color3.fromRGB(110, 200, 255),
		crateDiscount = 0.3,
	},
}

-- The Lucky Hour event running right now (or nil), from the attributes the server sets.
function Luck.current()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local id = ReplicatedStorage:GetAttribute("LuckyEvent")
	local ends = ReplicatedStorage:GetAttribute("LuckyEventEnds") or 0
	if id and Luck.EVENTS[id] and game:GetService("Workspace"):GetServerTimeNow() < ends then
		return Luck.EVENTS[id], ends
	end
	return nil, 0
end

-- A crate's price right now (Crate Frenzy makes it cheaper).
function Luck.cratePrice(crate): number
	local event = Luck.current()
	local discount = event and event.crateDiscount or 0
	return math.floor(crate.price * (1 - discount))
end

return Luck
