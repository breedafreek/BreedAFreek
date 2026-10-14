-- Rarity tiers, lowest to highest. breedTime is in seconds. carrySpeed is how fast a thief
-- walks while carrying a Freek of this rarity (normal walking speed is 16).
-- "Seasonal" isn't a tier: it's a tag a Freek of any rarity can have (see Seasons).

local Rarities = {}

Rarities.order = { "Common", "Uncommon", "Rare", "Legendary", "Mystic", "Ultra", "Secret" }

Rarities.info = {
	Common = { color = Color3.fromRGB(200, 200, 200), breedTime = 30, carrySpeed = 15 },
	Uncommon = { color = Color3.fromRGB(90, 220, 90), breedTime = 60, carrySpeed = 14 },
	Rare = { color = Color3.fromRGB(70, 150, 255), breedTime = 120, carrySpeed = 12.5 },
	Legendary = { color = Color3.fromRGB(255, 180, 40), breedTime = 300, carrySpeed = 11 },
	Mystic = { color = Color3.fromRGB(190, 90, 255), breedTime = 600, carrySpeed = 9.5 },
	Ultra = { color = Color3.fromRGB(255, 60, 100), breedTime = 1200, carrySpeed = 8 },
	Secret = { color = Color3.fromRGB(255, 255, 255), breedTime = 2400, carrySpeed = 6.5 },
}

Rarities.rank = {}
for i, name in Rarities.order do
	Rarities.rank[name] = i
end

return Rarities
