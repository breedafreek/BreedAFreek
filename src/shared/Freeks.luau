-- Every Freek species in the game.
--
-- id       unique key saved in player data; never rename one after release
-- income   money per second while in the yard
-- price    set only for starter Freeks: always allowed on the conveyor belt, at this price.
--          Other species appear on the belt once discovered, priced from their income.
-- season   optional Seasonal tag (a key in Seasons.luau): only obtainable during that season
-- walk     how it moves around the town square: waddle, trot, prowl, slither, flap, stomp,
--          bounce, strut, catwalk, shamble or float (see the client)
-- exclusive only from Monster Crates (never from cannons, the wheel or anywhere else)
-- event       only from the cannons while that event runs (see Events.luau)
-- look     how the model is built: a part list (see FreekModel), in the crafted look from
--          CraftedFreeks.luau
--
-- Fusing two different Freeks makes a hybrid (see Hybrids.luau); the only hand-made results
-- are the Ultra pairs that make Secrets, in ServerScriptService (Recipes).

local CraftedFreeks = require(script.Parent.CraftedFreeks)

local Freeks = {}

Freeks.list = {
	-- Starter Freeks (shop)
	{
		id = "Oinkle",
		signature = "bow",
		walk = "waddle",
		name = "Oinkle",
		rarity = "Common",
		income = 1,
		price = 50,
		look = CraftedFreeks.Oinkle(),
	},

	-- The Animal line (Oinkle is the pig)
	{
		id = "Woofles",
		signature = "collar",
		walk = "trot",
		name = "Woofles",
		rarity = "Common",
		income = 3,
		look = CraftedFreeks.Woofles(),
	},
	{
		id = "Whiskerz",
		signature = "bell",
		walk = "prowl",
		name = "Whiskerz",
		rarity = "Uncommon",
		income = 14,
		look = CraftedFreeks.Whiskerz(),
	},
	{
		id = "Lizzle",
		signature = "flower",
		walk = "slither",
		name = "Lizzle",
		rarity = "Uncommon",
		income = 18,
		look = CraftedFreeks.Lizzle(),
	},
	{
		id = "Hootsworth",
		signature = "tophat",
		walk = "flap",
		name = "Hootsworth",
		rarity = "Rare",
		income = 70,
		look = CraftedFreeks.Hootsworth(),
	},
	{
		id = "Chompers",
		signature = "shades",
		walk = "slither",
		name = "Chompers",
		rarity = "Legendary",
		income = 260,
		look = CraftedFreeks.Chompers(),
	},
	{
		id = "Stompy",
		signature = "horn",
		walk = "stomp",
		name = "Stompy",
		rarity = "Mystic",
		income = 1000,
		look = CraftedFreeks.Stompy(),
	},

	-- The Human line
	{
		id = "Chuckles",
		signature = "clownnose",
		walk = "bounce",
		name = "Chuckles",
		rarity = "Common",
		income = 4,
		look = CraftedFreeks.Chuckles(),
	},
	{
		id = "Nerdle",
		signature = "glasses",
		walk = "strut",
		name = "Nerdle",
		rarity = "Uncommon",
		income = 20,
		look = CraftedFreeks.Nerdle(),
	},
	{
		id = "Flexo",
		signature = "sweatband",
		walk = "stomp",
		name = "Flexo",
		rarity = "Rare",
		income = 80,
		look = CraftedFreeks.Flexo(),
	},
	{
		id = "Glamora",
		signature = "tiara",
		walk = "catwalk",
		name = "Glamora",
		rarity = "Legendary",
		income = 300,
		look = CraftedFreeks.Glamora(),
	},

	-- The Monster line: only from Monster Crates (exclusive = true keeps them out of the
	-- cannons and everywhere else).
	{
		id = "BooBoo",
		signature = "witchhat",
		name = "Boo-Boo",
		rarity = "Uncommon",
		exclusive = true,
		walk = "float",
		income = 25,
		look = CraftedFreeks.BooBoo(),
	},
	{
		id = "Zomboy",
		signature = "bolts",
		name = "Zomboy",
		rarity = "Uncommon",
		exclusive = true,
		walk = "shamble",
		income = 30,
		look = CraftedFreeks.Zomboy(),
	},
	{
		id = "Mumbles",
		signature = "bandage",
		name = "Mumbles",
		rarity = "Rare",
		exclusive = true,
		walk = "shamble",
		income = 100,
		look = CraftedFreeks.Mumbles(),
	},
	{
		id = "CountFangula",
		signature = "capecollar",
		name = "Count Fangula",
		rarity = "Legendary",
		exclusive = true,
		walk = "strut",
		income = 400,
		look = CraftedFreeks.CountFangula(),
	},
	{
		id = "Howlz",
		signature = "spikedcollar",
		name = "Howlz",
		rarity = "Mystic",
		exclusive = true,
		walk = "prowl",
		income = 1500,
		look = CraftedFreeks.Howlz(),
	},
	{
		id = "Blinky",
		signature = "horns",
		name = "Blinky",
		rarity = "Ultra",
		exclusive = true,
		walk = "bounce",
		income = 6000,
		look = CraftedFreeks.Blinky(),
	},
	-- Event Freeks: only from the cannons during their event (see Events.luau).
	{
		id = "Stormy",
		signature = "lightning",
		name = "Stormy",
		rarity = "Mystic",
		event = "MonsterStorm",
		walk = "float",
		income = 2000,
		look = CraftedFreeks.Stormy(),
	},
}

-- Every Freek belongs to a series (shown first when a Monster Egg hatches).
Freeks.SERIES = {
	Animal = { name = "Animal Series", icon = "🐾", color = Color3.fromRGB(90, 220, 110) },
	Human = { name = "Human Series", icon = "🧑", color = Color3.fromRGB(80, 170, 255) },
	Monster = { name = "Monster Series", icon = "🎃", color = Color3.fromRGB(255, 130, 40) },
	Hybrid = { name = "Hybrid", icon = "🧪", color = Color3.fromRGB(255, 95, 200) },
}
local HUMAN_LINE = { Chuckles = true, Nerdle = true, Flexo = true, Glamora = true }

local base = {}
for i, species in Freeks.list do
	species.order = i
	species.series = if species.exclusive or species.event
		then "Monster"
		elseif HUMAN_LINE[species.id] then "Human"
		else "Animal"
	base[species.id] = species
end

-- Freeks.byId[id] also answers for hybrid ids ("Nerdle+Oinkle"), built on first use.
local Hybrids = require(script.Parent.Hybrids)
local hybridCache = {}
Freeks.byId = setmetatable(table.clone(base), {
	__index = function(_, id)
		if type(id) ~= "string" or not Hybrids.isHybrid(id) then
			return nil
		end
		if hybridCache[id] == nil then
			hybridCache[id] = Hybrids.info(id, function(baseId)
				return base[baseId]
			end) or false
		end
		return hybridCache[id] or nil
	end,
})

return Freeks
