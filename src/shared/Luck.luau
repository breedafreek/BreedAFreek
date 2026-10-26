-- Luck: Mystery Boxes, the daily Lucky Wheel and Lucky Hour events. Shared so the client
-- can show every chance on screen (players always see the odds before buying), while the
-- server does all the rolling (server/LuckService).
--
-- Mystery Boxes are Developer Products bought with Robux: each one opens into a random house
-- part (a random slot, in a style rolled from the box's odds). Roblox's rules for paid
-- random items: the odds are shown before buying, and players in countries where paid
-- random items aren't allowed can't buy them (LuckService checks PolicyService).

local Parts = require(script.Parent.Parts)
local Rarities = require(script.Parent.Rarities)

local Luck = {}

-- Mystery Boxes. In the code they're still called crates (and the product ids are the ones
-- first made for the old Monster Eggs: rename those products on the dashboard).
-- productId: the Developer Product's ID. odds are weights per part style; mutation
-- multiplies each mutation's normal chance.
Luck.CRATES = {
	{
		id = "Monster",
		name = "Mystery Box",
		robux = 49,
		productId = 3718866310,
		color = Color3.fromRGB(255, 140, 30),
		odds = { Stone = 45, Sand = 35, Ice = 15, Candy = 4.5, Lava = 0.5 },
		mutation = 1,
	},
	{
		id = "MegaMonster",
		name = "Mega Mystery Box",
		robux = 149,
		productId = 3718866430,
		color = Color3.fromRGB(160, 110, 240),
		odds = { Sand = 20, Ice = 25, Candy = 35, Lava = 15, Royal = 4.5, Crystal = 0.5 },
		mutation = 2,
	},
	{
		id = "LegendaryMonster",
		name = "Legendary Mystery Box",
		robux = 399,
		productId = 3718866530,
		color = Color3.fromRGB(255, 200, 60),
		odds = { Candy = 30, Lava = 45, Royal = 20, Crystal = 5 },
		mutation = 3,
	},
}
-- Opens boxes for free in Studio when they have no product ID yet (for testing).
Luck.STUDIO_FREE_CRATES = true

-- The Starter Pack: a one-time offer for a player's first STARTER.hours after they first
-- join. It's a game pass (passId); its contents are given once, the first time the server
-- sees the player owns it. The boxes are saved to open from the Luck tab.
Luck.STARTER = {
	name = "Starter Pack",
	robux = 499,
	passId = 2040722277,
	hours = 12,
	coins = 50000,
	crates = { LegendaryMonster = 3 },
}

-- Box bundles (Developer Products): several boxes at once, cheaper than one by one.
Luck.BUNDLES = {
	{
		id = "LegendaryTen",
		name = "10x Legendary Mystery Boxes",
		robux = 2800,
		productId = 3718869744,
		crate = "LegendaryMonster",
		count = 10,
	},
}

Luck.crateById = {}
Luck.crateByProduct = {}
for _, crate in Luck.CRATES do
	Luck.crateById[crate.id] = crate
	if crate.productId ~= 0 then
		Luck.crateByProduct[crate.productId] = crate
	end
end
Luck.bundleById = {}
Luck.bundleByProduct = {}
for _, bundle in Luck.BUNDLES do
	Luck.bundleById[bundle.id] = bundle
	if bundle.productId ~= 0 then
		Luck.bundleByProduct[bundle.productId] = bundle
	end
end

-- How much cheaper a bundle is than buying its boxes one by one (percent).
function Luck.bundleSaving(bundle): number
	local single = Luck.crateById[bundle.crate].robux * bundle.count
	return math.floor((1 - bundle.robux / single) * 100 + 0.5)
end

-- The crate's odds right now (Crate Luck makes the rarest ones likelier), as weights.
function Luck.crateOdds(crate): { [string]: number }
	local event = Luck.current()
	local boost = event and event.crateLuck or 1
	local odds = {}
	for styleId, weight in crate.odds do
		local style = Parts.styleById[styleId]
		local rare = style and Rarities.rank[style.rarity] >= Rarities.rank.Legendary
		odds[styleId] = if rare then weight * boost else weight
	end
	return odds
end

-- The crate's odds as a list, most likely first: { { style, percent } }.
function Luck.oddsList(crate)
	local odds = Luck.crateOdds(crate)
	local total = 0
	for _, weight in odds do
		total += weight
	end
	local list = {}
	for styleId, weight in odds do
		table.insert(list, { style = styleId, percent = weight / total * 100 })
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
	{ label = "Golden Part", golden = true, weight = 14, color = Color3.fromRGB(255, 220, 90) },
	{ label = "Mystery Box", crate = "Monster", weight = 12, color = Color3.fromRGB(255, 140, 30) },
	{ label = "Huge Coins", minutes = 30, weight = 10, color = Color3.fromRGB(40, 160, 90) },
	{ label = "Rainbow Part", rainbow = true, weight = 4, color = Color3.fromRGB(255, 120, 255) },
	{ label = "Mega Box", crate = "MegaMonster", weight = 3, color = Color3.fromRGB(160, 110, 240) },
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
		description = "Parts in the zones are 5x as likely to be mutated!",
		color = Color3.fromRGB(255, 120, 255),
		mutationBoost = 5,
	},
	LuckySkies = {
		name = "Lucky Zones",
		icon = "🍀",
		description = "Rarer parts turn up in the zones 3x as often!",
		color = Color3.fromRGB(90, 230, 120),
		rareBoost = 3,
	},
	RapidFire = {
		name = "Fast Regrow",
		icon = "💥",
		description = "Parts regrow in the zones twice as fast!",
		color = Color3.fromRGB(255, 140, 50),
		respawnBoost = 2,
	},
	CrateLuck = {
		name = "Box Luck",
		icon = "📦",
		description = "Legendary and better parts are 2x as likely from Mystery Boxes!",
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
