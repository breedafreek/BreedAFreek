-- The fusing rules (the code calls it breeding). Shared so the Fuse window can show what a
-- pair will make.
--
--   * Any two Freeks can fuse. Both are used up and become one new Freek.
--   * Two different species make a hybrid of the two (see Hybrids.luau), so every
--     combination has its own result to discover. Mutations are what make two fused
--     Freeks of the same kind different.
--   * The result's rarity is the rarer parent's rarity; fusing never raises it.
--   * It earns both parents' income added together, times HYBRID_BONUS.
--   * The one way to get a Secret: certain pairs of Ultras (listed in server/Recipes).
--   * Mutations are only inherited, each one rolled on its own: if both parents have it the
--     baby always gets it, if only one parent has it it's a 50% chance. A baby can end up
--     with several.

local FreekUtil = require(script.Parent.FreekUtil)
local Freeks = require(script.Parent.Freeks)
local Hybrids = require(script.Parent.Hybrids)
local Mutations = require(script.Parent.Mutations)
local Rarities = require(script.Parent.Rarities)

local Breeding = {}

-- A fused Freek earns both parents' income (before mutations) times this.
Breeding.HYBRID_BONUS = 1.1

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

-- What the pair fuses into, unless it's an Ultra pair with a Secret recipe (server only).
function Breeding.babySpecies(parentA, parentB): string
	return Hybrids.combine(parentA.species, parentB.species)
end

-- The fused Freek's income before mutations, rounded to a tenth.
function Breeding.babyIncome(parentA, parentB): number
	local total = (FreekUtil.baseIncome(parentA) + FreekUtil.baseIncome(parentB)) * Breeding.HYBRID_BONUS
	return math.round(total * 10) / 10
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
