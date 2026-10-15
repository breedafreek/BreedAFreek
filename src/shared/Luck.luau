-- Luck: Monster Eggs, the daily Lucky Wheel and Lucky Hour events. Shared so the client
-- can show every chance on screen (players always see the odds before buying), while the
-- server does all the rolling (server/LuckService).
--
-- Monster Eggs are Developer Products bought with Robux. They're the only way to get
-- the Monster line (Freeks with exclusive = true). Roblox's rules for paid random items:
-- the odds are shown before buying, and players in countries where paid random items
-- aren't allowed can't buy them (LuckService checks PolicyService).

local Freeks = require(script.Parent.Freeks)
local Rarities = require(script.Parent.Rarities)

local Luck = {}

-- Monster Eggs (Halloween style; models in EggModel.luau). In the code they're still
-- called crates. productId: create a Developer Product for each on the Creator Dashboard
-- (Monetization -> Developer Products) at this price and paste its ID here. Until then
-- the egg shows "Coming soon", except in Studio where it hatches free for testing.
-- odds are weights per Monster; mutation multiplies each mutation's normal chance.
Luck.CRATES = {
	{
		id = "Monster",
		name = "Monster Egg",
		robux = 49,
		productId = 0,
		color = Color3.fromRGB(255, 140, 30),
		odds = { BooBoo = 45, Zomboy = 35, Mumbles = 15, CountFangula = 4.5, Howlz = 0.5 },
		mutation = 1,
	},
	{
		id = "MegaMonster",
		name = "Mega Monster Egg",
		robux = 149,
		productId = 0,
		color = Color3.fromRGB(160, 110, 240),
		odds = { BooBoo = 20, Zomboy = 25, Mumbles = 35, CountFangula = 15, Howlz = 4.5, Blinky = 0.5 },
		mutation = 2,
	},
	{
		id = "LegendaryMonster",
		name = "Legendary Monster Egg",
		robux = 399,
		productId = 0,
		color = Color3.fromRGB(255, 200, 60),
		odds = { Mumbles = 30, CountFangula = 45, Howlz = 20, Blinky = 5 },
		mutation = 3,
	},
}
-- Opens crates for free in Studio when they have no product ID yet (for testing).
Luck.STUDIO_FREE_CRATES = true

Luck.crateById = {}
Luck.crateByProduct = {}
for _, crate in Luck.CRATES do
	Luck.crateById[crate.id] = crate
	if crate.productId ~= 0 then
		Luck.crateByProduct[crate.productId] = crate
	end
end

-- The crate's odds right now (Crate Luck makes the rarest ones likelier), as weights.
function Luck.crateOdds(crate): { [string]: number }
	local event = Luck.current()
	local boost = event and event.crateLuck or 1
	local odds = {}
	for speciesId, weight in crate.odds do
		local species = Freeks.byId[speciesId]
		local rare = species and Rarities.rank[species.rarity] >= Rarities.rank.Legendary
		odds[speciesId] = if rare then weight * boost else weight
	end
	return odds
end

-- The crate's odds as a list, most likely first: { { species, percent } }.
function Luck.oddsList(crate)
	local odds = Luck.crateOdds(crate)
	local total = 0
	for _, weight in odds do
		total += weight
	end
	local list = {}
	for speciesId, weight in odds do
		table.insert(list, { species = speciesId, percent = weight / total * 100 })
	end
	table.sort(list, function(a, b)
		return a.percent > b.percent
	end)
	return list
end

-- The Lucky Wheel: one free spin a day (twice a day with VIP). Coin prizes are minutes of
-- the player's own income, so they stay worth it as the player grows.
Luck.SPIN_COOLDOWN = 24 * 60 * 60
Luck.VIP_SPIN_COOLDOWN = 12 * 60 * 60
Luck.WHEEL = {
	{ label = "Coins", minutes = 3, weight = 34, color = Color3.fromRGB(110, 235, 140) },
	{ label = "Big Coins", minutes = 10, weight = 22, color = Color3.fromRGB(60, 200, 110) },
	{ label = "Golden Freek", golden = true, weight = 14, color = Color3.fromRGB(255, 220, 90) },
	{ label = "Monster Egg", crate = "Monster", weight = 12, color = Color3.fromRGB(255, 140, 30) },
	{ label = "Huge Coins", minutes = 30, weight = 10, color = Color3.fromRGB(40, 160, 90) },
	{ label = "Rainbow Freek", rainbow = true, weight = 4, color = Color3.fromRGB(255, 120, 255) },
	{ label = "Mega Egg", crate = "MegaMonster", weight = 3, color = Color3.fromRGB(160, 110, 240) },
	{ label = "JACKPOT", crate = "LegendaryMonster", weight = 1, color = Color3.fromRGB(255, 200, 60) },
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
	CrateLuck = {
		name = "Egg Luck",
		icon = "📦",
		description = "Legendary and better Monsters are 2x as likely from Monster Eggs!",
		color = Color3.fromRGB(110, 200, 255),
		crateLuck = 2,
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

return Luck
