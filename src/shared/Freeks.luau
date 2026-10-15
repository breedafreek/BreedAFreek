-- Every Freek species in the game. These are PLACEHOLDERS until the real list arrives.
--
-- id       unique key saved in player data; never rename one after release
-- income   money per second while in the yard
-- price    set only for starter Freeks: always allowed on the conveyor belt, at this price.
--          Other species appear on the belt once discovered, priced from their income.
-- season   optional Seasonal tag (a key in Seasons.luau): only obtainable during that season
-- look     how the placeholder model is built: shape "Ball" or "Block", size in studs,
--          eyes 1-3, antennae 0-3
--
-- Fusing two different Freeks makes a hybrid (see Hybrids.luau); the only hand-made results
-- are the Ultra pairs that make Secrets, in ServerScriptService (Recipes).

local Freeks = {}

Freeks.list = {
	-- Starter Freeks (shop)
	{
		id = "Oinkle",
		name = "Oinkle",
		rarity = "Common",
		income = 1,
		price = 50,
		look = {
			parts = {
				-- Body
				{ shape = "Ball", size = 3.4, pos = { 0, 2.1, 0 }, color = Color3.fromRGB(255, 170, 190) },
				-- Legs
				{
					shape = "Cylinder",
					size = { 1, 0.75, 0.75 },
					pos = { -0.8, 0.5, -0.75 },
					rot = { 0, 0, 90 },
					color = Color3.fromRGB(240, 145, 170),
				},
				{
					shape = "Cylinder",
					size = { 1, 0.75, 0.75 },
					pos = { 0.8, 0.5, -0.75 },
					rot = { 0, 0, 90 },
					color = Color3.fromRGB(240, 145, 170),
				},
				{
					shape = "Cylinder",
					size = { 1, 0.75, 0.75 },
					pos = { -0.8, 0.5, 0.75 },
					rot = { 0, 0, 90 },
					color = Color3.fromRGB(240, 145, 170),
				},
				{
					shape = "Cylinder",
					size = { 1, 0.75, 0.75 },
					pos = { 0.8, 0.5, 0.75 },
					rot = { 0, 0, 90 },
					color = Color3.fromRGB(240, 145, 170),
				},
				-- Snout and nostrils
				{
					shape = "Cylinder",
					size = { 0.55, 1.15, 1.15 },
					pos = { 0, 1.95, -1.72 },
					rot = { 0, 90, 0 },
					color = Color3.fromRGB(255, 135, 160),
				},
				{
					shape = "Ball",
					size = 0.24,
					pos = { -0.22, 1.95, -2.0 },
					color = Color3.fromRGB(110, 40, 60),
					detail = true,
				},
				{
					shape = "Ball",
					size = 0.24,
					pos = { 0.22, 1.95, -2.0 },
					color = Color3.fromRGB(110, 40, 60),
					detail = true,
				},
				-- Eyes
				{
					shape = "Ball",
					size = 0.62,
					pos = { -0.6, 2.75, -1.42 },
					color = Color3.new(1, 1, 1),
					detail = true,
				},
				{
					shape = "Ball",
					size = 0.32,
					pos = { -0.6, 2.75, -1.68 },
					color = Color3.new(0, 0, 0),
					detail = true,
				},
				{ shape = "Ball", size = 0.62, pos = { 0.6, 2.75, -1.42 }, color = Color3.new(1, 1, 1), detail = true },
				{ shape = "Ball", size = 0.32, pos = { 0.6, 2.75, -1.68 }, color = Color3.new(0, 0, 0), detail = true },
				-- Rosy cheeks
				{
					shape = "Ball",
					size = 0.5,
					pos = { -1.0, 2.0, -1.22 },
					color = Color3.fromRGB(255, 110, 140),
					detail = true,
				},
				{
					shape = "Ball",
					size = 0.5,
					pos = { 1.0, 2.0, -1.22 },
					color = Color3.fromRGB(255, 110, 140),
					detail = true,
				},
				-- Smile
				{
					shape = "Block",
					size = { 0.55, 0.1, 0.1 },
					pos = { 0, 1.18, -1.45 },
					color = Color3.fromRGB(110, 40, 60),
					detail = true,
				},
				-- Floppy ears
				{
					shape = "Wedge",
					size = { 0.2, 1.1, 1 },
					pos = { -0.85, 3.55, -0.4 },
					rot = { -15, 90, 20 },
					color = Color3.fromRGB(240, 140, 165),
				},
				{
					shape = "Wedge",
					size = { 0.2, 1.1, 1 },
					pos = { 0.85, 3.55, -0.4 },
					rot = { -15, -90, -20 },
					color = Color3.fromRGB(240, 140, 165),
				},
				-- Curly tail
				{ shape = "Ball", size = 0.3, pos = { 0, 2.25, 1.75 }, color = Color3.fromRGB(240, 145, 170) },
				{ shape = "Ball", size = 0.3, pos = { 0.18, 2.42, 1.88 }, color = Color3.fromRGB(240, 145, 170) },
				{ shape = "Ball", size = 0.3, pos = { 0.05, 2.62, 1.96 }, color = Color3.fromRGB(240, 145, 170) },
				{ shape = "Ball", size = 0.3, pos = { -0.14, 2.5, 2.02 }, color = Color3.fromRGB(240, 145, 170) },
			},
		},
	},
	{
		id = "Blobby",
		name = "Blobby",
		rarity = "Common",
		income = 1,
		price = 50,
		look = { color = Color3.fromRGB(120, 200, 255), shape = "Ball", size = 3, eyes = 2, antennae = 0 },
	},
	{
		id = "Snorp",
		name = "Snorp",
		rarity = "Common",
		income = 2,
		price = 120,
		look = { color = Color3.fromRGB(255, 140, 180), shape = "Ball", size = 3.2, eyes = 1, antennae = 1 },
	},
	{
		id = "Wigglet",
		name = "Wigglet",
		rarity = "Common",
		income = 3,
		price = 250,
		look = { color = Color3.fromRGB(140, 230, 110), shape = "Block", size = 2.8, eyes = 2, antennae = 2 },
	},
	{
		id = "Grumbo",
		name = "Grumbo",
		rarity = "Common",
		income = 5,
		price = 500,
		look = { color = Color3.fromRGB(170, 120, 80), shape = "Block", size = 3.4, eyes = 3, antennae = 0 },
	},

	-- Bred only
	{
		id = "Snoblob",
		name = "Snoblob",
		rarity = "Uncommon",
		income = 12,
		look = { color = Color3.fromRGB(190, 150, 255), shape = "Ball", size = 3.6, eyes = 2, antennae = 1 },
	},
	{
		id = "Wigglump",
		name = "Wigglump",
		rarity = "Uncommon",
		income = 18,
		look = { color = Color3.fromRGB(230, 220, 90), shape = "Block", size = 3.6, eyes = 3, antennae = 2 },
	},
	{
		id = "Blobwig",
		name = "Blobwig",
		rarity = "Uncommon",
		income = 15,
		look = { color = Color3.fromRGB(90, 220, 200), shape = "Ball", size = 3.4, eyes = 3, antennae = 2 },
	},
	{
		id = "Grumsnorp",
		name = "Grumsnorp",
		rarity = "Uncommon",
		income = 22,
		look = { color = Color3.fromRGB(255, 120, 70), shape = "Block", size = 3.8, eyes = 1, antennae = 1 },
	},

	{
		id = "Chonkler",
		name = "Chonkler",
		rarity = "Rare",
		income = 60,
		look = { color = Color3.fromRGB(255, 90, 90), shape = "Ball", size = 4.6, eyes = 2, antennae = 0 },
	},
	{
		id = "Zorpdorp",
		name = "Zorpdorp",
		rarity = "Rare",
		income = 75,
		look = { color = Color3.fromRGB(60, 120, 255), shape = "Block", size = 4.2, eyes = 3, antennae = 3 },
	},

	{
		id = "EyeballEarl",
		name = "Eyeball Earl",
		rarity = "Legendary",
		income = 250,
		look = { color = Color3.fromRGB(245, 245, 245), shape = "Ball", size = 5, eyes = 1, antennae = 2 },
	},

	{
		id = "KingGoob",
		name = "King Goob",
		rarity = "Mystic",
		income = 1000,
		look = { color = Color3.fromRGB(120, 255, 120), shape = "Ball", size = 6, eyes = 2, antennae = 3 },
	},

	{
		id = "CosmicSnorp",
		name = "Cosmic Snorp",
		rarity = "Ultra",
		income = 4000,
		look = { color = Color3.fromRGB(40, 20, 90), shape = "Ball", size = 6.5, eyes = 3, antennae = 1 },
	},

	-- Seasonal
	{
		id = "PumpkinBlob",
		name = "Pumpkin Blob",
		rarity = "Rare",
		season = "Halloween",
		income = 90,
		look = { color = Color3.fromRGB(255, 130, 20), shape = "Ball", size = 4.2, eyes = 2, antennae = 1 },
	},

	{
		id = "TheFreek",
		name = "The Freek",
		rarity = "Secret",
		income = 15000,
		look = { color = Color3.fromRGB(15, 15, 15), shape = "Block", size = 7, eyes = 3, antennae = 3 },
	},
}

local base = {}
for i, species in Freeks.list do
	species.order = i
	base[species.id] = species
end

-- Freeks.byId[id] also answers for hybrid ids ("Blobby+Oinkle"), built on first use.
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
