-- Everything you can own in Steal a Life, in four kinds:
--
--   House  house parts (Parts.luau): snap onto your house's slots
--   Pet    Freeks that roam your yard
--   Yard   yard items (pool, trampoline, hot tub...) on the spots in your yard
--   Plant  plants in your garden beds
--
-- Every item comes out of an egg stolen from a zone (see EGGS / ZONES): each zone grows
-- eggs of one kind, and deeper zones have better odds. An egg's rarity is rolled when it
-- goes into a nest at home, it grows for a while (rarer = longer) and hatches into a random
-- item of its kind and rarity.
--
-- Item ids: house parts "<Style>_<Slot>" ("Candy_Roof"), others "<Kind>_<Name>"
-- ("Pet_Oinkle", "Yard_HotTub", "Plant_Sunflower"). Never rename an id once players own it.

local Parts = require(script.Parent.Parts)
local Rarities = require(script.Parent.Rarities)

local Items = {}

Items.KINDS = {
	House = { name = "House", icon = "🏠", color = Color3.fromRGB(70, 140, 255), egg = "Hardware" },
	Pet = { name = "Pets", icon = "🐾", color = Color3.fromRGB(255, 120, 180), egg = "Wilds" },
	Yard = { name = "Yard", icon = "🛝", color = Color3.fromRGB(255, 160, 50), egg = "Yard Sale" },
	Plant = { name = "Garden", icon = "🌷", color = Color3.fromRGB(80, 200, 90), egg = "Garden" },
}
Items.KIND_ORDER = { "House", "Pet", "Yard", "Plant" }

-- What an item of each rarity earns a second (pets, yard items and plants; house parts use
-- their style's income times the slot's weight). Kept in line with house parts.
Items.INCOME = {
	Common = 4,
	Uncommon = 30,
	Rare = 180,
	Legendary = 1000,
	Mystic = 5000,
	Ultra = 13000,
	Secret = 45000,
}

-- Pets: Freeks (species in Freeks.luau). Their rarity here is what decides how often they
-- hatch and what they earn.
Items.PETS = {
	{ species = "Oinkle", rarity = "Common" },
	{ species = "Woofles", rarity = "Common" },
	{ species = "Chuckles", rarity = "Common" },
	{ species = "Whiskerz", rarity = "Uncommon" },
	{ species = "Lizzle", rarity = "Uncommon" },
	{ species = "Nerdle", rarity = "Uncommon" },
	{ species = "BooBoo", rarity = "Rare" },
	{ species = "Zomboy", rarity = "Rare" },
	{ species = "Hootsworth", rarity = "Rare" },
	{ species = "Flexo", rarity = "Legendary" },
	{ species = "Mumbles", rarity = "Legendary" },
	{ species = "Glamora", rarity = "Legendary" },
	{ species = "Chompers", rarity = "Mystic" },
	{ species = "CountFangula", rarity = "Mystic" },
	{ species = "Stompy", rarity = "Ultra" },
	{ species = "Howlz", rarity = "Ultra" },
	{ species = "Blinky", rarity = "Secret" },
	{ species = "Stormy", rarity = "Secret" },
}

-- Yard items (models in YardModel.luau).
Items.YARD = {
	{ id = "Gnome", name = "Garden Gnome", rarity = "Common" },
	{ id = "Lemonade", name = "Lemonade Stand", rarity = "Common" },
	{ id = "Grill", name = "BBQ Grill", rarity = "Uncommon" },
	{ id = "Swing", name = "Swing Set", rarity = "Uncommon" },
	{ id = "Trampoline", name = "Trampoline", rarity = "Rare" },
	{ id = "KiddiePool", name = "Kiddie Pool", rarity = "Rare" },
	{ id = "HotTub", name = "Hot Tub", rarity = "Legendary" },
	{ id = "Fountain", name = "Fountain", rarity = "Legendary" },
	{ id = "Treehouse", name = "Treehouse", rarity = "Mystic" },
	{ id = "SportsCar", name = "Sports Car", rarity = "Mystic" },
	{ id = "Pool", name = "Swimming Pool", rarity = "Ultra" },
	{ id = "Rocket", name = "Rocket Ship", rarity = "Secret" },
}

-- Plants (models in PlantModel.luau).
Items.PLANTS = {
	{ id = "Daisy", name = "Daisy", rarity = "Common" },
	{ id = "Tulip", name = "Tulip", rarity = "Common" },
	{ id = "Sunflower", name = "Sunflower", rarity = "Uncommon" },
	{ id = "RoseBush", name = "Rose Bush", rarity = "Uncommon" },
	{ id = "Cactus", name = "Cactus", rarity = "Rare" },
	{ id = "AppleTree", name = "Apple Tree", rarity = "Rare" },
	{ id = "Pumpkin", name = "Giant Pumpkin", rarity = "Legendary" },
	{ id = "Blossom", name = "Cherry Blossom", rarity = "Legendary" },
	{ id = "CrystalFlower", name = "Crystal Flower", rarity = "Mystic" },
	{ id = "GlowShroom", name = "Glow Mushroom", rarity = "Mystic" },
	{ id = "MoneyTree", name = "Money Tree", rarity = "Ultra" },
	{ id = "RainbowTree", name = "Rainbow Tree", rarity = "Secret" },
}

-- How many of each kind can be out at once (more items wait in the backpack).
Items.PET_SLOTS = 8
Items.YARD_SPOTS = 6
Items.GARDEN_BEDS = 6

-- Every item, by id.
Items.byId = {}
Items.list = {}
local function add(item)
	item.order = #Items.list + 1
	Items.byId[item.id] = item
	table.insert(Items.list, item)
end
for _, part in Parts.list do
	add({
		id = part.id,
		kind = "House",
		name = part.name,
		rarity = part.rarity,
		income = part.income,
		slot = part.slot,
		style = part.style,
		basic = part.style == "Basic",
	})
end
for i, pet in Items.PETS do
	-- A little more for each species further down its rarity, so they're not all equal.
	add({
		id = "Pet_" .. pet.species,
		kind = "Pet",
		name = pet.species,
		species = pet.species,
		rarity = pet.rarity,
		income = math.floor(Items.INCOME[pet.rarity] * (1 + (i % 3) * 0.1)),
	})
end
for i, yard in Items.YARD do
	add({
		id = "Yard_" .. yard.id,
		kind = "Yard",
		name = yard.name,
		model = yard.id,
		rarity = yard.rarity,
		income = math.floor(Items.INCOME[yard.rarity] * (1 + (i % 2) * 0.15)),
	})
end
for i, plant in Items.PLANTS do
	add({
		id = "Plant_" .. plant.id,
		kind = "Plant",
		name = plant.name,
		model = plant.id,
		rarity = plant.rarity,
		income = math.floor(Items.INCOME[plant.rarity] * (1 + (i % 2) * 0.12)),
	})
end
-- Pets now have names as their display name: use the species' friendly name.
do
	local ok, Freeks = pcall(require, script.Parent.Freeks)
	if ok then
		for _, pet in Items.PETS do
			local species = Freeks.byId[pet.species]
			if species then
				Items.byId["Pet_" .. pet.species].name = species.name
			end
		end
	end
end

function Items.color(id: string): Color3
	local item = Items.byId[id]
	return Rarities.info[item and item.rarity or "Common"].color
end

-- Every item of a kind and rarity that can hatch (Basic house parts never do).
function Items.pool(kind: string, rarity: string): { string }
	local list = {}
	for _, item in Items.list do
		if item.kind == kind and item.rarity == rarity and not item.basic then
			table.insert(list, item.id)
		end
	end
	return list
end

--------------------------------------------------------------------------------
-- Zones and their eggs
--------------------------------------------------------------------------------

-- The zones, in order out from town, each growing eggs of one kind. speed = the Speed you
-- need to outrun its guardian (a giant Freek). odds = chance of each rarity when one of its
-- eggs goes in a nest (weights).
Items.ZONES = {
	{
		name = "Backyard Garden",
		kind = "Plant",
		speed = 0,
		guardian = "Oinkle",
		title = "Gardener Oinkle",
		eggColor = Color3.fromRGB(120, 210, 90),
		spotColor = Color3.fromRGB(255, 220, 90),
		odds = { Common = 70, Uncommon = 25, Rare = 5 },
	},
	{
		name = "Junkyard",
		kind = "House",
		speed = 300,
		guardian = "Woofles",
		title = "Junk Dog",
		eggColor = Color3.fromRGB(190, 140, 90),
		spotColor = Color3.fromRGB(120, 125, 135),
		odds = { Common = 60, Uncommon = 30, Rare = 9, Legendary = 1 },
	},
	{
		name = "Pine Woods",
		kind = "Pet",
		speed = 2_000,
		guardian = "Hootsworth",
		title = "Old Owl Hootsworth",
		eggColor = Color3.fromRGB(90, 170, 110),
		spotColor = Color3.fromRGB(150, 100, 60),
		odds = { Common = 50, Uncommon = 35, Rare = 13, Legendary = 2 },
	},
	{
		name = "Toy Town",
		kind = "Yard",
		speed = 10_000,
		guardian = "Chuckles",
		title = "Toy Clown Chuckles",
		eggColor = Color3.fromRGB(255, 200, 60),
		spotColor = Color3.fromRGB(80, 150, 255),
		odds = { Common = 40, Uncommon = 38, Rare = 18, Legendary = 4 },
	},
	{
		name = "Sunny Desert",
		kind = "Plant",
		speed = 40_000,
		guardian = "Mumbles",
		title = "Mummy Mumbles",
		eggColor = Color3.fromRGB(240, 200, 120),
		spotColor = Color3.fromRGB(60, 190, 200),
		odds = { Uncommon = 40, Rare = 35, Legendary = 20, Mystic = 5 },
	},
	{
		name = "Candy Land",
		kind = "House",
		speed = 150_000,
		guardian = "Glamora",
		title = "Candy Queen Glamora",
		eggColor = Color3.fromRGB(255, 150, 200),
		spotColor = Color3.fromRGB(255, 255, 255),
		odds = { Uncommon = 30, Rare = 38, Legendary = 25, Mystic = 7 },
	},
	{
		name = "Frosty Peaks",
		kind = "Pet",
		speed = 600_000,
		guardian = "BooBoo",
		title = "Frosty BooBoo",
		eggColor = Color3.fromRGB(170, 220, 255),
		spotColor = Color3.fromRGB(255, 255, 255),
		odds = { Rare = 40, Legendary = 38, Mystic = 18, Ultra = 4 },
	},
	{
		name = "Royal Kingdom",
		kind = "Yard",
		speed = 2_500_000,
		guardian = "CountFangula",
		title = "Count Fangula",
		eggColor = Color3.fromRGB(150, 60, 220),
		spotColor = Color3.fromRGB(255, 200, 60),
		odds = { Rare = 30, Legendary = 40, Mystic = 23, Ultra = 7 },
	},
	{
		name = "Crystal Caves",
		kind = "House",
		speed = 10_000_000,
		guardian = "Blinky",
		title = "Crystal Blinky",
		eggColor = Color3.fromRGB(170, 120, 255),
		spotColor = Color3.fromRGB(120, 250, 240),
		odds = { Legendary = 40, Mystic = 38, Ultra = 20, Secret = 2 },
	},
	{
		name = "Sky Islands",
		kind = "Pet",
		speed = 50_000_000,
		guardian = "Stormy",
		title = "Storm Lord Stormy",
		eggColor = Color3.fromRGB(240, 248, 255),
		spotColor = Color3.fromRGB(255, 210, 80),
		odds = { Legendary = 30, Mystic = 40, Ultra = 26, Secret = 4 },
	},
}

-- How long an egg of each rarity grows in a nest (seconds).
Items.HATCH_SECONDS = {
	Common = 20,
	Uncommon = 45,
	Rare = 90,
	Legendary = 180,
	Mystic = 360,
	Ultra = 600,
	Secret = 900,
}
Items.NESTS = 3 -- nests every yard has (the Extra Nests pass adds 2)

-- The odds of a zone's eggs as a list, most likely first: { { rarity, percent } }.
function Items.oddsList(zoneIndex: number)
	local odds = Items.ZONES[zoneIndex].odds
	local total = 0
	for _, weight in odds do
		total += weight
	end
	local list = {}
	for rarity, weight in odds do
		table.insert(list, { rarity = rarity, percent = weight / total * 100 })
	end
	table.sort(list, function(a, b)
		return Rarities.rank[a.rarity] < Rarities.rank[b.rarity]
	end)
	return list
end

-- Rolls an egg's rarity from a zone's odds. `boost` (>= 1) makes everything above Common
-- that many times likelier.
function Items.rollRarity(zoneIndex: number, rng: Random, boost: number?): string
	local odds = Items.ZONES[zoneIndex].odds
	local weights, total = {}, 0
	for _, rarity in Rarities.order do
		local weight = odds[rarity]
		if weight then
			weight *= if rarity == "Common" then 1 else (boost or 1)
			table.insert(weights, { rarity, weight })
			total += weight
		end
	end
	local roll = rng:NextNumber() * total
	for _, entry in weights do
		roll -= entry[2]
		if roll <= 0 then
			return entry[1]
		end
	end
	return weights[#weights][1]
end

-- An egg's display name, e.g. "Garden Egg".
function Items.eggName(zoneIndex: number): string
	local zone = Items.ZONES[zoneIndex]
	return Items.KINDS[zone.kind].egg .. " Egg"
end

-- The time eggs count in (os.time() on the server), on the server or a client: clients
-- add the offset the server publishes to their synced clock.
function Items.now(): number
	local RunService = game:GetService("RunService")
	if RunService:IsServer() then
		return os.time()
	end
	local offset = game:GetService("ReplicatedStorage"):GetAttribute("OsTimeOffset") or 0
	return game:GetService("Workspace"):GetServerTimeNow() + offset
end

-- Speed -> walking speed, and guardian speeds (the Speed rules live in Parts).
Items.walkSpeed = Parts.walkSpeed
function Items.guardianSpeed(zoneIndex: number): number
	return Parts.walkSpeed(Items.ZONES[zoneIndex].speed) * 0.85
end

-- The highest zone a Speed is enough for.
function Items.zoneFor(speed: number): number
	local best = 1
	for index, zone in Items.ZONES do
		if speed >= zone.speed then
			best = index
		end
	end
	return best
end

return Items
