-- Decides which species a pair of parents makes. Server-only so players can't read the
-- results out of the game and have to discover them.
--
-- Every pair has a result: a species of the baby's rarity (see shared/Breeding) picked by
-- the pair itself, so the same two species always make the same baby. Two Ultras make a
-- Secret. Limited Freeks are only picked while their event is running.
--
-- OVERRIDES pins a specific result for a pair if you want a hand-made recipe; it must
-- follow the rarity rule (same rarity as the rarer parent, or Secret for two Ultras).

local Shared = game:GetService("ReplicatedStorage").Shared
local Breeding = require(Shared.Breeding)
local Freeks = require(Shared.Freeks)
local Seasons = require(Shared.Seasons)

local OVERRIDES = {
	-- ["Blobby|Snorp"] = "Oinkle",
}

local Recipes = {}

local function pairKey(a: string, b: string): string
	return if a < b then a .. "|" .. b else b .. "|" .. a
end
Recipes.pairKey = pairKey

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

-- Returns the baby's species and mutation (or nil) for two parent records.
function Recipes.roll(parentA, parentB, rng: Random): (string, string?)
	local key = pairKey(parentA.species, parentB.species)
	local rarity, bothUltra = Breeding.babyRarity(parentA, parentB)
	if bothUltra and rng:NextNumber() < Breeding.SECRET_CHANCE then
		rarity = "Secret"
	end

	local species = OVERRIDES[key]
	if not species or not Seasons.available(Freeks.byId[species]) then
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

	return species, Breeding.rollMutation(parentA, parentB, rng)
end

return Recipes
