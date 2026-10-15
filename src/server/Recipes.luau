-- Decides what two Freeks fuse into. Server-only so players can't read the Secret recipes
-- out of the game.
--
-- Normally the result is the hybrid of the two (shared/Hybrids, via Breeding.babySpecies),
-- so every pair already has its own result. The only hand-made results are the Ultra
-- pairs in SECRETS: those make a Secret instead, the only way to get one.

local Shared = game:GetService("ReplicatedStorage").Shared
local Breeding = require(Shared.Breeding)
local Freeks = require(Shared.Freeks)
local Seasons = require(Shared.Seasons)

-- ["UltraA|UltraB"] = "SecretFreek" (names in either order).
local SECRETS = {}

local Recipes = {}

local function pairKey(a: string, b: string): string
	return if a < b then a .. "|" .. b else b .. "|" .. a
end

-- Accept keys written in either order.
local sorted = {}
for key, value in SECRETS do
	local a, b = string.match(key, "^(.-)|(.*)$")
	sorted[pairKey(a, b)] = value
end
SECRETS = sorted

-- Returns the fused Freek's species, mutations (a list, or nil) and income (before
-- mutations) for two parent records.
function Recipes.roll(parentA, parentB, rng: Random): (string, { string }?, number)
	local mutations = Breeding.rollMutations(parentA, parentB, rng)
	local income = Breeding.babyIncome(parentA, parentB)

	local _, bothUltra = Breeding.babyRarity(parentA, parentB)
	local secret = bothUltra and SECRETS[pairKey(parentA.species, parentB.species)]
	if secret and Freeks.byId[secret] and Seasons.available(Freeks.byId[secret]) then
		return secret, mutations, math.max(income, Freeks.byId[secret].income)
	end

	return Breeding.babySpecies(parentA, parentB), mutations, income
end

return Recipes
