-- Everything you can own in Steal a Life: 80 items in ten zones (the owner's reference
-- sheet), each of one of three kinds that decides where it goes at home:
--
--   Pet    creatures (Freeks.luau) that roam your yard
--   Yard   things that stand on the spots in your yard (furniture, vehicles, props...)
--   Plant  plants and trees in your garden beds
--
-- Every item comes out of an egg stolen from a zone (see ZONES): each zone's eggs hatch
-- one of that zone's eight items, and deeper zones have better odds. An egg's rarity and
-- what's inside are rolled when it appears; it grows in a nest at home (rarer = longer)
-- and hatches into that item.
--
-- Item ids: "<Kind>_<Id>" ("Pet_GoldenRetriever", "Yard_RedMailbox", "Plant_AppleTree").
-- Never rename an id once players own it.

local Parts = require(script.Parent.Parts)
local Rarities = require(script.Parent.Rarities)

local Items = {}

Items.KINDS = {
	Pet = { name = "Pets", icon = "🐾", color = Color3.fromRGB(255, 120, 180) },
	Yard = { name = "Yard", icon = "🛝", color = Color3.fromRGB(255, 160, 50) },
	Plant = { name = "Garden", icon = "🌷", color = Color3.fromRGB(80, 200, 90) },
}
Items.KIND_ORDER = { "Pet", "Yard", "Plant" }

-- What an item of each rarity earns a second (a little more in deeper zones).
Items.INCOME = {
	Common = 4,
	Uncommon = 30,
	Rare = 180,
	Legendary = 1000,
	Mystic = 5000,
	Ultra = 13000,
	Secret = 45000,
}

-- The zones, in order out from town. speed = the Speed you need to outrun its guardian (a
-- giant version of one of its creatures, a species in Freeks.luau). odds = chance of each
-- rarity for its eggs (weights). items = its eight items, { kind, id, name, rarity },
-- from the most common up.
Items.ZONES = {
	{
		name = "The Neighborhood",
		tagline = "Everyday Life",
		icon = "🏡",
		speed = 0,
		guardian = "GoldenRetriever",
		title = "Big Buddy",
		eggColor = Color3.fromRGB(110, 200, 90),
		spotColor = Color3.fromRGB(255, 255, 255),
		odds = { Common = 70, Uncommon = 25, Rare = 5 },
		items = {
			{ "Plant", "FlowerPot", "Flower Pot", "Common" },
			{ "Yard", "RedMailbox", "Red Mailbox", "Common" },
			{ "Yard", "GardenBench", "Garden Bench", "Common" },
			{ "Yard", "Doghouse", "Doghouse", "Uncommon" },
			{ "Pet", "PetBunny", "Pet Bunny", "Uncommon" },
			{ "Plant", "AppleTree", "Apple Tree", "Uncommon" },
			{ "Pet", "TabbyCat", "Orange Tabby Cat", "Rare" },
			{ "Pet", "GoldenRetriever", "Golden Retriever", "Rare" },
		},
	},
	{
		name = "The Garden",
		tagline = "Plants & Gardening",
		icon = "🌻",
		speed = 300,
		guardian = "Gnome",
		title = "Giant Gnome",
		eggColor = Color3.fromRGB(80, 190, 70),
		spotColor = Color3.fromRGB(255, 210, 60),
		odds = { Common = 60, Uncommon = 30, Rare = 9, Legendary = 1 },
		items = {
			{ "Plant", "Cactus", "Cactus", "Common" },
			{ "Plant", "RoseBush", "Rose Bush", "Common" },
			{ "Plant", "StrawberryBush", "Strawberry Bush", "Uncommon" },
			{ "Yard", "GardenGnome", "Garden Gnome", "Uncommon" },
			{ "Plant", "GiantSunflower", "Giant Sunflower", "Rare" },
			{ "Plant", "GiantMushroom", "Giant Mushroom", "Rare" },
			{ "Plant", "GiantPumpkin", "Giant Pumpkin", "Legendary" },
			{ "Yard", "GardenFountain", "Garden Fountain", "Legendary" },
		},
	},
	{
		name = "The Beach",
		tagline = "Summer & Outdoor Fun",
		icon = "🏖️",
		speed = 2_000,
		guardian = "BeachCrab",
		title = "King Crab",
		eggColor = Color3.fromRGB(250, 215, 140),
		spotColor = Color3.fromRGB(60, 200, 230),
		odds = { Common = 50, Uncommon = 35, Rare = 13, Legendary = 2 },
		items = {
			{ "Yard", "Lifebuoy", "Lifebuoy", "Common" },
			{ "Yard", "Surfboard", "Surfboard", "Common" },
			{ "Yard", "BeachUmbrella", "Beach Umbrella", "Uncommon" },
			{ "Yard", "Sandcastle", "Sandcastle", "Uncommon" },
			{ "Yard", "FlamingoFloat", "Flamingo Float", "Rare" },
			{ "Pet", "BeachCrab", "Beach Crab", "Rare" },
			{ "Plant", "PalmTree", "Coconut Palm Tree", "Legendary" },
			{ "Yard", "DolphinSprinkler", "Dolphin Sprinkler", "Legendary" },
		},
	},
	{
		name = "The Wilderness",
		tagline = "Forest & Camping",
		icon = "🏕️",
		speed = 10_000,
		guardian = "BrownBear",
		title = "Grizzly Boss",
		eggColor = Color3.fromRGB(70, 140, 70),
		spotColor = Color3.fromRGB(160, 105, 60),
		odds = { Common = 40, Uncommon = 38, Rare = 18, Legendary = 4 },
		items = {
			{ "Plant", "PineTree", "Pine Tree", "Common" },
			{ "Yard", "Campfire", "Campfire", "Common" },
			{ "Yard", "CampingTent", "Camping Tent", "Uncommon" },
			{ "Yard", "Canoe", "Canoe", "Uncommon" },
			{ "Pet", "RedFox", "Red Fox", "Rare" },
			{ "Pet", "BabyDeer", "Baby Deer", "Rare" },
			{ "Yard", "LogCabin", "Log Cabin", "Legendary" },
			{ "Pet", "BrownBear", "Brown Bear", "Legendary" },
		},
	},
	{
		name = "The Dream Home",
		tagline = "Furniture & Home Upgrades",
		icon = "🛋️",
		speed = 40_000,
		guardian = "TabbyCat",
		title = "Queen of the House",
		eggColor = Color3.fromRGB(190, 150, 240),
		spotColor = Color3.fromRGB(255, 255, 255),
		odds = { Uncommon = 40, Rare = 35, Legendary = 20, Mystic = 5 },
		items = {
			{ "Yard", "SmartFridge", "Smart Fridge", "Uncommon" },
			{ "Yard", "LuxurySofa", "Luxury Sofa", "Uncommon" },
			{ "Yard", "GiantTV", "Giant TV", "Rare" },
			{ "Yard", "KingBed", "King Bed", "Rare" },
			{ "Yard", "VanityMirror", "Golden Vanity Mirror", "Legendary" },
			{ "Yard", "GamingSetup", "RGB Gaming Setup", "Legendary" },
			{ "Yard", "HotTub", "Hot Tub", "Mystic" },
			{ "Yard", "GrandPiano", "Grand Piano", "Mystic" },
		},
	},
	{
		name = "The City",
		tagline = "Urban Life & Vehicles",
		icon = "🏙️",
		speed = 150_000,
		guardian = "RobotButler",
		title = "Mega Butler",
		eggColor = Color3.fromRGB(80, 110, 230),
		spotColor = Color3.fromRGB(255, 220, 40),
		odds = { Uncommon = 30, Rare = 38, Legendary = 25, Mystic = 7 },
		items = {
			{ "Yard", "ElectricScooter", "Electric Scooter", "Uncommon" },
			{ "Yard", "VendingMachine", "Vending Machine", "Uncommon" },
			{ "Yard", "ATM", "ATM", "Rare" },
			{ "Yard", "YellowTaxi", "Yellow Taxi", "Rare" },
			{ "Pet", "RobotButler", "Robot Butler", "Legendary" },
			{ "Yard", "RedSupercar", "Red Supercar", "Legendary" },
			{ "Yard", "Helicopter", "Helicopter", "Mystic" },
			{ "Yard", "Skyscraper", "Skyscraper", "Mystic" },
		},
	},
	{
		name = "The Millionaire",
		tagline = "Wealth & Luxury",
		icon = "💰",
		speed = 600_000,
		guardian = "WhiteTiger",
		title = "Golden Tiger",
		eggColor = Color3.fromRGB(240, 200, 80),
		spotColor = Color3.fromRGB(255, 255, 255),
		odds = { Rare = 40, Legendary = 38, Mystic = 18, Ultra = 4 },
		items = {
			{ "Yard", "DiamondWatch", "Diamond Watch", "Rare" },
			{ "Yard", "Diamond", "Diamond", "Rare" },
			{ "Yard", "GoldenThrone", "Golden Throne", "Legendary" },
			{ "Yard", "GoldSupercar", "Gold Supercar", "Legendary" },
			{ "Yard", "MansionModel", "Mansion Model", "Mystic" },
			{ "Yard", "LuxuryYacht", "Luxury Yacht", "Mystic" },
			{ "Yard", "GoldHelicopter", "Gold Helicopter", "Ultra" },
			{ "Pet", "WhiteTiger", "White Tiger", "Ultra" },
		},
	},
	{
		name = "The Enchanted Life",
		tagline = "Magic & Fantasy",
		icon = "🔮",
		speed = 2_500_000,
		guardian = "BabyDragon",
		title = "Elder Dragon",
		eggColor = Color3.fromRGB(200, 110, 230),
		spotColor = Color3.fromRGB(120, 240, 255),
		odds = { Rare = 30, Legendary = 40, Mystic = 23, Ultra = 7 },
		items = {
			{ "Yard", "MagicWand", "Magic Wand", "Rare" },
			{ "Yard", "PotionCauldron", "Potion Cauldron", "Rare" },
			{ "Yard", "CrystalCluster", "Crystal Cluster", "Legendary" },
			{ "Yard", "MushroomHouse", "Mushroom House", "Legendary" },
			{ "Plant", "CrystalTree", "Crystal Tree", "Mystic" },
			{ "Pet", "Unicorn", "Unicorn", "Mystic" },
			{ "Yard", "DragonFountain", "Dragon Fountain", "Ultra" },
			{ "Pet", "BabyDragon", "Baby Dragon", "Ultra" },
		},
	},
	{
		name = "The Alien Life",
		tagline = "Extraterrestrial & Sci-Fi",
		icon = "👽",
		speed = 10_000_000,
		guardian = "Alien",
		title = "Alien Overlord",
		eggColor = Color3.fromRGB(90, 70, 170),
		spotColor = Color3.fromRGB(120, 255, 120),
		odds = { Legendary = 40, Mystic = 38, Ultra = 20, Secret = 2 },
		items = {
			{ "Plant", "AlienPlant", "Alien Plant", "Legendary" },
			{ "Yard", "Saturn", "Saturn", "Legendary" },
			{ "Yard", "CrystalReactor", "Crystal Reactor", "Mystic" },
			{ "Pet", "Alien", "Alien", "Mystic" },
			{ "Pet", "AlienRobot", "Alien Robot", "Ultra" },
			{ "Yard", "UFO", "UFO", "Ultra" },
			{ "Yard", "TeleportPortal", "Teleport Portal", "Secret" },
			{ "Yard", "RocketShip", "Rocket Ship", "Secret" },
		},
	},
	{
		name = "The Ultimate Life",
		tagline = "Cosmic & Impossible",
		icon = "🌌",
		speed = 50_000_000,
		guardian = "RainbowPhoenix",
		title = "Cosmic Phoenix",
		eggColor = Color3.fromRGB(240, 245, 255),
		spotColor = Color3.fromRGB(255, 200, 80),
		odds = { Legendary = 30, Mystic = 40, Ultra = 26, Secret = 4 },
		items = {
			{ "Yard", "CelestialCrown", "Celestial Crown", "Legendary" },
			{ "Plant", "CosmicTree", "Cosmic Tree", "Legendary" },
			{ "Yard", "GoldenPalace", "Golden Palace", "Mystic" },
			{ "Yard", "RainbowWaterfall", "Rainbow Waterfall", "Mystic" },
			{ "Yard", "LivingPlanet", "Living Planet", "Ultra" },
			{ "Yard", "MiniGalaxy", "Miniature Galaxy", "Ultra" },
			{ "Pet", "RainbowPhoenix", "Rainbow Phoenix", "Secret" },
			{ "Yard", "PocketUniverse", "Pocket Universe", "Secret" },
		},
	},
}

-- How many of each kind can be out at once (more items wait in the backpack).
Items.PET_SLOTS = 8
Items.YARD_SPOTS = 6
Items.GARDEN_BEDS = 6

-- Every item, by id (and in zone order in Items.list).
Items.byId = {}
Items.list = {}
for zoneIndex, zone in Items.ZONES do
	for i, entry in zone.items do
		local kind, id, name, rarity = entry[1], entry[2], entry[3], entry[4]
		local item = {
			id = kind .. "_" .. id,
			kind = kind,
			model = id,
			species = if kind == "Pet" then id else nil,
			name = name,
			rarity = rarity,
			zone = zoneIndex,
			-- A little more for deeper zones and for the second of each pair.
			income = math.floor(Items.INCOME[rarity] * (1 + (zoneIndex - 1) * 0.04 + (i % 2) * 0.1)),
			order = #Items.list + 1,
		}
		Items.byId[item.id] = item
		table.insert(Items.list, item)
		zone.items[i] = item.id
	end
end

function Items.color(id: string): Color3
	local item = Items.byId[id]
	return Rarities.info[item and item.rarity or "Common"].color
end

-- Every item of a rarity (in one zone, or in any zone).
function Items.pool(rarity: string, zoneIndex: number?): { string }
	local list = {}
	for _, item in Items.list do
		if item.rarity == rarity and (not zoneIndex or item.zone == zoneIndex) then
			table.insert(list, item.id)
		end
	end
	return list
end

-- Weights, like Steal an Egg: every egg has a random weight in kg, and grows a random amount
-- (in random spurts) while it sits in a nest. What hatches keeps the egg's final weight.
-- There's no top limit: weights come from a long-tailed roll, so each step heavier is
-- rarer than the last. Counting nest growth, a hatched item ranges from about a third of
-- normal up: 3x normal is about 1 in 14, 10x about 1 in 190, 30x about 1 in 2,000, 100x
-- about 1 in 35,000, and so on with no end.
--
-- On item records: weight (kg) and baseWeight (the normal weight of the egg it came from).
-- weight / baseWeight is the item's "factor": it multiplies income and sets how big it's
-- drawn (Items.weightScale). Records without a weight count as factor 1.
local WEIGHT_SCALE = 0.66 -- sets where the typical egg lands (about 1x normal)
local WEIGHT_TAIL = 2.2 -- how fast heavier eggs get rarer (bigger = rarer)
local GROWTH_MIN = 0.5 -- the growth roll's scale (half of eggs grow +13% or more, 1 in 10 +58%)
local GROWTH_TAIL = 3 -- how fast bigger growth gets rarer (1 in 100 nearly triples)

-- The normal weight of a zone's eggs (kg): deeper zones lay heavier eggs.
function Items.eggBaseWeight(zoneIndex: number): number
	return 1 + (zoneIndex - 1) * 0.75
end

-- A random weight factor (1 = normal). `boost` (>= 1, from lucky events) makes heavy ones
-- likelier.
function Items.rollWeightFactor(rng: Random, boost: number?): number
	local tail = WEIGHT_TAIL / (boost or 1) ^ 0.25
	-- A spread round normal (0.5x to 1.5x), times a long tail with no top.
	return WEIGHT_SCALE * (0.5 + rng:NextNumber()) * (1 - rng:NextNumber()) ^ (-1 / tail)
end

-- A random amount an egg grows by in its nest (1 = not at all, 2 = doubles).
function Items.rollGrowth(rng: Random): number
	return 1 + GROWTH_MIN * ((1 - rng:NextNumber()) ^ (-1 / GROWTH_TAIL) - 1)
end

-- How far through its growth an egg is (0 to 1) at fraction t of its hatch time: random
-- spurts and pauses, the same every time for the same seed (so the server and the clients
-- agree).
function Items.growthCurve(seed: number, t: number): number
	t = math.clamp(t, 0, 1)
	local rng = Random.new(seed)
	local steps, total = {}, 0
	for k = 1, 6 do
		steps[k] = rng:NextNumber() ^ 2 + 0.02
		total += steps[k]
	end
	local done = 0
	local position = t * 6
	for k = 1, 6 do
		local share = steps[k] / total
		if position >= k then
			done += share
		else
			local a = math.clamp(position - (k - 1), 0, 1)
			done += share * a * a * (3 - 2 * a) -- smoothstep: a spurt within the step
			break
		end
	end
	return math.min(done, 1)
end

-- An egg's weight (kg) at time `now` (os.time() on the server, Items.now() on clients). Eggs
-- on pedestals or carried don't grow; eggs in nests have startAt / endsAt / growth / seed.
function Items.eggWeightAt(egg, now: number?): number
	local weight = egg.weight or Items.eggBaseWeight(egg.egg or egg.zone or 1)
	if not egg.growth or not egg.startAt or not egg.endsAt or not now then
		return weight
	end
	local t = (now - egg.startAt) / math.max(egg.endsAt - egg.startAt, 1)
	return weight * egg.growth ^ Items.growthCurve(egg.seed or 1, t)
end

-- An item's (or egg's) weight factor: weight / normal weight (1 if it has none).
function Items.weightFactor(record): number
	local weight, base = record and record.weight, record and record.baseWeight
	if type(weight) ~= "number" or type(base) ~= "number" or base <= 0 then
		return 1
	end
	return weight / base
end

-- How fast you run carrying an egg (a multiplier on your walk speed): a normal or lighter
-- egg slows you a little, and every time an egg is twice as heavy you're about 12% slower,
-- down to half speed. So a monster egg is a real risk to run home with.
function Items.carrySpeed(record): number
	local factor = Items.weightFactor(record)
	return math.clamp(0.92 - 0.12 * math.log(math.max(factor, 1), 2), 0.5, 0.92)
end

-- The colour heavy things are named in: white, then blue, gold, and hot pink for monsters.
function Items.weightColor(factor: number): Color3
	if factor >= 10 then
		return Color3.fromRGB(255, 80, 170)
	elseif factor >= 3 then
		return Color3.fromRGB(255, 205, 60)
	elseif factor >= 1.5 then
		return Color3.fromRGB(130, 225, 255)
	end
	return Color3.new(1, 1, 1)
end

-- How big something of this weight factor is drawn (a heavy thing is bigger, but not as
-- many times bigger as it is heavier).
function Items.weightScale(factor: number): number
	return math.max(factor, 0.05) ^ 0.45
end

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

-- A random item of a rarity from zone `zoneIndex` (from any zone if nil), falling back to
-- the next rarity down if there are none of that rarity.
function Items.rollItem(zoneIndex: number?, rarity: string, rng: Random): string
	for rank = Rarities.rank[rarity] or 1, 1, -1 do
		local pool = Items.pool(Rarities.order[rank], zoneIndex)
		if #pool > 0 then
			return pool[rng:NextInteger(1, #pool)]
		end
	end
	-- Rarer than anything there (or nothing of it): the zone's best item.
	local zone = zoneIndex and Items.ZONES[zoneIndex]
	return if zone then zone.items[#zone.items] else Items.list[1].id
end

-- An egg's name from what's inside it: "Golden Retriever Egg" (or the zone's egg name,
-- "Neighborhood Egg", if it doesn't say).
function Items.itemEggName(zoneIndex: number, itemId: string?): string
	local item = itemId and Items.byId[itemId]
	return if item then item.name .. " Egg" else Items.eggName(zoneIndex)
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

-- Scales a model round its pivot, or round `around` if given (parts, their positions and
-- attachments).
function Items.scaleModel(model: Model, factor: number, around: CFrame?)
	if math.abs(factor - 1) < 0.001 then
		return
	end
	local pivot = around or model:GetPivot()
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			local rel = pivot:ToObjectSpace(p.CFrame)
			p.Size *= factor
			p.CFrame = pivot * (rel.Rotation + rel.Position * factor)
		elseif p:IsA("Attachment") then
			p.Position *= factor
		end
	end
	if model.PrimaryPart and not around then
		local offset = model.PrimaryPart.PivotOffset
		model.PrimaryPart.PivotOffset = offset.Rotation + offset.Position * factor
	end
end

-- An egg's display name, e.g. "Neighborhood Egg".
function Items.eggName(zoneIndex: number): string
	local zone = Items.ZONES[zoneIndex] or Items.ZONES[1]
	return (string.gsub(zone.name, "^The ", "")) .. " Egg"
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
