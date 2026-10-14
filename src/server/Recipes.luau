-- Secret breeding recipes. Server-only so players can't read them out of the game.
-- Order of a and b doesn't matter. chance is how often the pair produces the result;
-- otherwise the baby is a copy of one of the parents' species. A recipe for a Seasonal
-- Freek only works while its season is running.

local Shared = game:GetService("ReplicatedStorage").Shared
local Freeks = require(Shared.Freeks)
local Mutations = require(Shared.Mutations)
local Seasons = require(Shared.Seasons)

local RECIPES = {
	{ a = "Blobby", b = "Snorp", result = "Snoblob", chance = 0.5 },
	{ a = "Wigglet", b = "Grumbo", result = "Wigglump", chance = 0.5 },
	{ a = "Blobby", b = "Wigglet", result = "Blobwig", chance = 0.5 },
	{ a = "Grumbo", b = "Snorp", result = "Grumsnorp", chance = 0.5 },

	{ a = "Snoblob", b = "Wigglump", result = "Chonkler", chance = 0.35 },
	{ a = "Blobwig", b = "Grumsnorp", result = "Zorpdorp", chance = 0.35 },

	{ a = "Chonkler", b = "Zorpdorp", result = "EyeballEarl", chance = 0.25 },
	{ a = "EyeballEarl", b = "Chonkler", result = "KingGoob", chance = 0.15 },
	{ a = "KingGoob", b = "Zorpdorp", result = "CosmicSnorp", chance = 0.1 },
	{ a = "CosmicSnorp", b = "KingGoob", result = "TheFreek", chance = 0.05 },

	-- Seasonal
	{ a = "Blobby", b = "Grumbo", result = "PumpkinBlob", chance = 0.4 },
}

local function pairKey(a: string, b: string): string
	return if a < b then a .. "|" .. b else b .. "|" .. a
end

local byPair = {}
for _, recipe in RECIPES do
	byPair[pairKey(recipe.a, recipe.b)] = recipe
end

local Recipes = {}

-- Returns the baby's species and mutation (or nil) for two parent records.
function Recipes.roll(parentA, parentB, rng: Random): (string, string?)
	local species
	local recipe = byPair[pairKey(parentA.species, parentB.species)]
	if recipe and Seasons.available(Freeks.byId[recipe.result]) and rng:NextNumber() < recipe.chance then
		species = recipe.result
	else
		species = if rng:NextNumber() < 0.5 then parentA.species else parentB.species
	end

	local mutation = nil
	for _, m in Mutations.list do
		local chance = m.chance
		if parentA.mutation == m.id or parentB.mutation == m.id then
			chance *= Mutations.INHERIT_BOOST
		end
		if rng:NextNumber() < chance then
			mutation = m.id
			break
		end
	end

	return species, mutation
end

return Recipes
