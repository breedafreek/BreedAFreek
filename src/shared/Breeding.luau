-- The breeding rules. Shared so the Breed window can show what a pair will make.
--
--   * Any two Freeks can breed.
--   * The baby's rarity is the rarer parent's rarity; breeding never raises it.
--   * Which species you get is fixed per pair (see server/Recipes), so every combination
--     has its own result to discover. Mutations are what make two babies different.
--   * The one way to get a Secret: certain pairs of Ultras (listed in server/Recipes).
--   * Mutations are only inherited, each one rolled on its own: if both parents have it the
--     baby always gets it, if only one parent has it it's a 50% chance. A baby can end up
--     with several.

local Freeks = require(script.Parent.Freeks)
local Mutations = require(script.Parent.Mutations)
local Rarities = require(script.Parent.Rarities)

local Breeding = {}

-- Chance of passing on a mutation that only one parent has.
Breeding.SINGLE_PARENT_MUTATION_CHANCE = 0.5

-- The rarity the baby will be, plus whether both parents are Ultras (some Ultra pairs make
-- a Secret instead; which ones is kept on the server).
function Breeding.babyRarity(parentA, parentB): (string, boolean)
	local rankA = Rarities.rank[Freeks.byId[parentA.species].rarity]
	local rankB = Rarities.rank[Freeks.byId[parentB.species].rarity]
	local rarity = Rarities.order[math.max(rankA, rankB)]
	local bothUltra = rankA == Rarities.rank.Ultra and rankB == Rarities.rank.Ultra
	return rarity, bothUltra
end

-- Every mutation the baby could get, rarest first: { { id, chance } }. Each is rolled
-- separately.
function Breeding.mutationOdds(parentA, parentB)
	local fromA = Mutations.normalize(parentA.mutations)
	local fromB = Mutations.normalize(parentB.mutations)
	local odds = {}
	for _, id in Mutations.normalize(table.move(fromB, 1, #fromB, #fromA + 1, table.clone(fromA))) do
		local both = table.find(fromA, id) and table.find(fromB, id)
		table.insert(odds, { id = id, chance = if both then 1 else Breeding.SINGLE_PARENT_MUTATION_CHANCE })
	end
	return odds
end

-- The baby's mutations (a list, or nil for none).
function Breeding.rollMutations(parentA, parentB, rng: Random): { string }?
	local list = {}
	for _, option in Breeding.mutationOdds(parentA, parentB) do
		if rng:NextNumber() < option.chance then
			table.insert(list, option.id)
		end
	end
	return Mutations.pack(list)
end

return Breeding
