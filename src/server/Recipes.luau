-- Decides which species a pair of parents makes. Server-only so players can't read the
-- results out of the game and have to discover them.
--
-- Every pair has a result: a species of the baby's rarity (see shared/Breeding) picked by
-- the pair itself, so the same two species always make the same baby. Limited Freeks are
-- only picked while their event is running.
--
-- SECRETS lists the Ultra pairs that make a Secret, the only way to get one. Any other two
-- Ultras just make an Ultra.
--
-- OVERRIDES pins a specific result for any other pair if you want a hand-made recipe; it
-- must be the same rarity as the rarer parent.

local Shared = game:GetService("ReplicatedStorage").Shared
local Breeding = require(Shared.Breeding)
local Freeks = require(Shared.Freeks)
local Seasons = require(Shared.Seasons)

-- ["UltraA|UltraB"] = "SecretFreek" (names in either order).
local SECRETS = {}

local OVERRIDES = {
	-- ["Blobby|Snorp"] = "Oinkle",
}

local Recipes = {}

local function pairKey(a: string, b: string): string
	return if a < b then a .. "|" .. b else b .. "|" .. a
end
Recipes.pairKey = pairKey

-- Accept keys written in either order.
local function sortKeys(map)
	local sorted = {}
	for key, value in map do
		local a, b = string.match(key, "^(.-)|(.*)$")
		sorted[pairKey(a, b)] = value
	end
	return sorted
end
SECRETS = sortKeys(SECRETS)
OVERRIDES = sortKeys(OVERRIDES)

-- A stable number for a pair (same pair, same number, every server).
local function pairHash(key: string): number
	local hash = 5381
	for i = 1, #key do
		hash = (hash * 33 + string.byte(key, i)) % 2147483647
	end
	return hash
end

local function speciesOfRarity(rarity: string)
	local list = {}
	for _, species in Freeks.list do
		if species.rarity == rarity and Seasons.available(species) then
			table.insert(list, species.id)
		end
	end
	return list
end

-- Returns the baby's species and mutations (a list, or nil) for two parent records.
function Recipes.roll(parentA, parentB, rng: Random): (string, { string }?)
	local key = pairKey(parentA.species, parentB.species)
	local rarity, bothUltra = Breeding.babyRarity(parentA, parentB)
	local mutations = Breeding.rollMutations(parentA, parentB, rng)

	local secret = bothUltra and SECRETS[key]
	if secret and Freeks.byId[secret] and Seasons.available(Freeks.byId[secret]) then
		return secret, mutations
	end

	local species = OVERRIDES[key]
	if not species or not Freeks.byId[species] or not Seasons.available(Freeks.byId[species]) then
		local options = speciesOfRarity(rarity)
		if #options == 0 then
			-- No species of that rarity exists yet: copy the rarer parent.
			local rarer = if Freeks.byId[parentA.species].rarity == rarity then parentA else parentB
			species = rarer.species
		else
			table.sort(options)
			species = options[pairHash(key) % #options + 1]
		end
	end

	return species, mutations
end

return Recipes
