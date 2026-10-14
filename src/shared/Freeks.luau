-- Every Freek species in the game. These are PLACEHOLDERS until the real list arrives.
--
-- id       unique key saved in player data; never rename one after release
-- income   money per second while in the yard
-- price    set only for Freeks sold in the shop (starter Freeks)
-- season   optional Seasonal tag (a key in Seasons.luau): only obtainable during that season
-- look     how the placeholder model is built: shape "Ball" or "Block", size in studs,
--          eyes 1-3, antennae 0-3
--
-- How new species are bred lives in ServerScriptService (Recipes) so players can't read it.

local Freeks = {}

Freeks.list = {
	-- Starter Freeks (shop)
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

Freeks.byId = {}
for i, species in Freeks.list do
	species.order = i
	Freeks.byId[species.id] = species
end

return Freeks
