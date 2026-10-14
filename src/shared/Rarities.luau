-- Rarity tiers, lowest to highest. breedTime is in seconds.
-- "Seasonal" isn't a tier: it's a tag a Freek of any rarity can have (see Seasons).

local Rarities = {}

Rarities.order = { "Common", "Uncommon", "Rare", "Legendary", "Mystic", "Ultra", "Secret" }

Rarities.info = {
	Common = { color = Color3.fromRGB(200, 200, 200), breedTime = 30 },
	Uncommon = { color = Color3.fromRGB(90, 220, 90), breedTime = 60 },
	Rare = { color = Color3.fromRGB(70, 150, 255), breedTime = 120 },
	Legendary = { color = Color3.fromRGB(255, 180, 40), breedTime = 300 },
	Mystic = { color = Color3.fromRGB(190, 90, 255), breedTime = 600 },
	Ultra = { color = Color3.fromRGB(255, 60, 100), breedTime = 1200 },
	Secret = { color = Color3.fromRGB(255, 255, 255), breedTime = 2400 },
}

Rarities.rank = {}
for i, name in Rarities.order do
	Rarities.rank[name] = i
end

return Rarities
