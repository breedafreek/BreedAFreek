-- The breeding rules. Shared so the Breed window can show what a pair will make.
--
--   * Any two Freeks can breed.
--   * The baby's rarity is the rarer parent's rarity; breeding never raises it.
--     The one exception: two Ultras make a Secret (the only way to get one).
--   * Which species of that rarity you get is fixed per pair (see server/Recipes), so
--     every combination has its own result to discover.
--   * Mutations are only inherited: if both parents share one the baby always gets it; if
--     only one parent has one it's a 50% chance; if they have different ones the baby gets
--     one of the two at random.

local Freeks = require(script.Parent.Freeks)
local Rarities = require(script.Parent.Rarities)

local Breeding = {}

-- Chance that two Ultras make a Secret (otherwise the baby is an Ultra).
Breeding.SECRET_CHANCE = 1

-- Chance of passing on a mutation when only one parent has it.
Breeding.SINGLE_PARENT_MUTATION_CHANCE = 0.5

-- The rarity the baby will be, plus whether it could be a Secret instead.
function Breeding.babyRarity(parentA, parentB): (string, boolean)
	local rankA = Rarities.rank[Freeks.byId[parentA.species].rarity]
	local rankB = Rarities.rank[Freeks.byId[parentB.species].rarity]
	local rarity = Rarities.order[math.max(rankA, rankB)]
	local bothUltra = rankA == Rarities.rank.Ultra and rankB == Rarities.rank.Ultra
	return rarity, bothUltra
end

-- Possible mutations for the baby as { { id, chance } }, chances adding up to <= 1.
function Breeding.mutationOdds(parentA, parentB)
	local a, b = parentA.mutation, parentB.mutation
	if a and b and a == b then
		return { { id = a, chance = 1 } }
	elseif a and b then
		return { { id = a, chance = 0.5 }, { id = b, chance = 0.5 } }
	elseif a or b then
		return { { id = a or b, chance = Breeding.SINGLE_PARENT_MUTATION_CHANCE } }
	end
	return {}
end

function Breeding.rollMutation(parentA, parentB, rng: Random): string?
	local roll = rng:NextNumber()
	for _, option in Breeding.mutationOdds(parentA, parentB) do
		if roll < option.chance then
			return option.id
		end
		roll -= option.chance
	end
	return nil
end

return Breeding
