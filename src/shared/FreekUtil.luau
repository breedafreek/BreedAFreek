-- Helpers shared by server and client for reading a saved Freek record:
--   { species = "Nerdle", mutations = { "Golden" }?, income = 2.2?, slot = 3?, breeding = true? }
-- species can be a hybrid id ("Nerdle+Oinkle"). income is set on fused Freeks; others earn
-- their species' income.

local Config = require(script.Parent.Config)
local Freeks = require(script.Parent.Freeks)
local Mutations = require(script.Parent.Mutations)
local Rarities = require(script.Parent.Rarities)
local Seasons = require(script.Parent.Seasons)

local FreekUtil = {}

function FreekUtil.species(freek)
	return Freeks.byId[freek.species]
end

-- Money per second before mutations.
function FreekUtil.baseIncome(freek): number
	if freek.income then
		return freek.income
	end
	local species = Freeks.byId[freek.species]
	return if species then species.income else 0
end

function FreekUtil.income(freek): number
	return FreekUtil.baseIncome(freek) * Mutations.mult(freek.mutations)
end

function FreekUtil.sellValue(freek): number
	return math.floor(FreekUtil.income(freek) * Config.SELL_MULTIPLIER)
end

function FreekUtil.displayName(freek): string
	local species = Freeks.byId[freek.species]
	local name = if species then species.name else "???"
	local mutations = Mutations.normalize(freek.mutations)
	return if #mutations > 0 then table.concat(mutations, " ") .. " " .. name else name
end

-- "Rare" or, for Seasonal Freeks, "Rare · Halloween".
function FreekUtil.rarityText(speciesId: string): string
	local species = Freeks.byId[speciesId]
	local season = species.season and Seasons.list[species.season]
	return if season then species.rarity .. " · " .. season.name else species.rarity
end

-- Money per second from the yard, including the rebirth bonus.
function FreekUtil.yardIncome(data): number
	local total = 0
	for _, freek in data.freeks do
		if freek.slot then
			total += FreekUtil.income(freek)
		end
	end
	return total * Config.incomeMultiplier(data.rebirths)
end

-- Yard slots a player can use: bought with coins plus any from Extra Yard Slot passes.
function FreekUtil.totalSlots(data): number
	return data.slots + (data.passSlots or 0)
end

-- First empty yard slot, or nil if the yard is full.
function FreekUtil.freeSlot(data): number?
	local used = {}
	for _, freek in data.freeks do
		if freek.slot then
			used[freek.slot] = true
		end
	end
	for i = 1, FreekUtil.totalSlots(data) do
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

-- Breeding pens live in the save as data.breeding (pen 1) and data.breeding2 (pen 2, from
-- the Extra Breeding Pen pass). Each is nil or { a = uid, b = uid, endsAt = unix seconds }.
FreekUtil.PEN_KEYS = { "breeding", "breeding2" }

function FreekUtil.pen(data, index: number)
	local key = FreekUtil.PEN_KEYS[index]
	return key and data[key]
end

function FreekUtil.breedTime(a, b): number
	local rankA = Rarities.rank[Freeks.byId[a.species].rarity]
	local rankB = Rarities.rank[Freeks.byId[b.species].rarity]
	local rarity = Rarities.order[math.max(rankA, rankB)]
	return Rarities.info[rarity].breedTime
end

return FreekUtil
