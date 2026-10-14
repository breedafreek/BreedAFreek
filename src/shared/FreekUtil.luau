-- Helpers shared by server and client for reading a saved Freek record:
--   { species = "Blobby", mutation = "Golden"?, slot = 3?, breeding = true? }

local Config = require(script.Parent.Config)
local Freeks = require(script.Parent.Freeks)
local Mutations = require(script.Parent.Mutations)
local Rarities = require(script.Parent.Rarities)
local Seasons = require(script.Parent.Seasons)

local FreekUtil = {}

function FreekUtil.species(freek)
	return Freeks.byId[freek.species]
end

function FreekUtil.income(freek): number
	local species = Freeks.byId[freek.species]
	if not species then
		return 0
	end
	return species.income * Mutations.mult(freek.mutation)
end

function FreekUtil.sellValue(freek): number
	return math.floor(FreekUtil.income(freek) * Config.SELL_MULTIPLIER)
end

function FreekUtil.displayName(freek): string
	local species = Freeks.byId[freek.species]
	local name = if species then species.name else "???"
	return if freek.mutation then freek.mutation .. " " .. name else name
end

-- "Rare" or, for Seasonal Freeks, "Rare · Halloween".
function FreekUtil.rarityText(speciesId: string): string
	local species = Freeks.byId[speciesId]
	local season = species.season and Seasons.list[species.season]
	return if season then species.rarity .. " · " .. season.name else species.rarity
end

function FreekUtil.yardIncome(data): number
	local total = 0
	for _, freek in data.freeks do
		if freek.slot then
			total += FreekUtil.income(freek)
		end
	end
	return total
end

-- First empty yard slot, or nil if the yard is full.
function FreekUtil.freeSlot(data): number?
	local used = {}
	for _, freek in data.freeks do
		if freek.slot then
			used[freek.slot] = true
		end
	end
	for i = 1, data.slots do
		if not used[i] then
			return i
		end
	end
	return nil
end

function FreekUtil.count(data): number
	local n = 0
	for _ in data.freeks do
		n += 1
	end
	return n
end

function FreekUtil.breedTime(a, b): number
	local rankA = Rarities.rank[Freeks.byId[a.species].rarity]
	local rankB = Rarities.rank[Freeks.byId[b.species].rarity]
	local rarity = Rarities.order[math.max(rankA, rankB)]
	return Rarities.info[rarity].breedTime
end

return FreekUtil
