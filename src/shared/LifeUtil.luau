-- Helpers for a player's save, shared by the server and the UI.
--
-- data.parts = { [uid] = { id = itemId, mutations? } }: every item the player owns (pets,
-- yard items, plants; see Items.luau). Items are "out" in one place each:
--   data.pen    = { [uid] = true }       pets roaming the yard
--   data.yard   = { ["1".."6"] = uid }   yard items on the yard spots
--   data.garden = { ["1".."6"] = uid }   plants in the garden beds
-- Everything else is in the backpack. How many pets, yard spots and beds there are comes
-- from data.plotLevel (Config.plotSpaces). The house itself comes from data.houseLevel: its
-- style (Config.houseStyle), which pieces it has (Config.houseSlotOpen) and the bonus it
-- gives everything at home (Config.houseBonus).
-- data.nests = { ["1".."5"] = { zone, rarity, endsAt, mutations? } }: eggs growing at home.

local Config = require(script.Parent.Config)
local Format = require(script.Parent.Format)
local Items = require(script.Parent.Items)
local Mutations = require(script.Parent.Mutations)
local Parts = require(script.Parent.Parts)

local LifeUtil = {}

-- How many pets, yard spots and garden beds this player has (their plot level).
function LifeUtil.spaces(data): { yard: number, garden: number, pets: number }
	return Config.plotSpaces(data.plotLevel or 1)
end

-- Whether a house slot is open at this player's house level.
function LifeUtil.slotOpen(data, slotId: string): boolean
	return Config.houseSlotOpen(data.houseLevel or 1, slotId)
end

-- { [slotId] = partId } for the house: every open slot in the house level's style.
function LifeUtil.layout(data): { [string]: string }
	local style = Config.houseStyle(data.houseLevel or 1)
	local layout = {}
	for _, slot in Parts.SLOTS do
		if LifeUtil.slotOpen(data, slot.id) then
			layout[slot.id] = style .. "_" .. slot.id
		end
	end
	return layout
end

-- What one item earns a second (before game passes).
function LifeUtil.itemIncome(record): number
	local item = record and Items.byId[record.id]
	if not item then
		return 0
	end
	return item.income * Mutations.mult(record.mutations) * Items.weightFactor(record)
end
LifeUtil.partIncome = LifeUtil.itemIncome

-- uid -> where it is ("pen", "yard:3", "garden:2") for everything that's out.
function LifeUtil.placed(data): { [string]: string }
	local where = {}
	for uid in data.pen or {} do
		where[uid] = "pen"
	end
	for spot, uid in data.yard or {} do
		where[uid] = "yard:" .. spot
	end
	for bed, uid in data.garden or {} do
		where[uid] = "garden:" .. bed
	end
	return where
end

-- Everything out earning, with the house's bonus (passes are added by the server).
function LifeUtil.totalIncome(data): number
	local total = 0
	for uid in LifeUtil.placed(data) do
		total += LifeUtil.itemIncome(data.parts[uid])
	end
	return total * Config.houseBonus(data.houseLevel or 1)
end
LifeUtil.houseIncome = LifeUtil.totalIncome

-- The uids in the backpack (owned, not out), best first.
function LifeUtil.backpack(data): { string }
	local placed = LifeUtil.placed(data)
	local list = {}
	for uid in data.parts do
		if not placed[uid] then
			table.insert(list, uid)
		end
	end
	table.sort(list, function(a, b)
		local ia, ib = LifeUtil.itemIncome(data.parts[a]), LifeUtil.itemIncome(data.parts[b])
		if ia ~= ib then
			return ia > ib
		end
		return a < b
	end)
	return list
end

function LifeUtil.backpackCount(data): number
	return #LifeUtil.backpack(data)
end

function LifeUtil.sellPrice(record): number
	return math.floor(LifeUtil.itemIncome(record) * Config.SELL_MULTIPLIER)
end

-- "Golden Unicorn" (weights are shown separately: LifeUtil.weightText)
function LifeUtil.displayName(record): string
	local item = Items.byId[record.id]
	local name = if item then item.name else record.id
	local top = Mutations.top(record.mutations)
	return if top then top .. " " .. name else name
end

-- "⚖ 4.21 kg" (or "" for something with no weight).
function LifeUtil.weightText(record): string
	if not record or type(record.weight) ~= "number" then
		return ""
	end
	return "⚖ " .. Format.weight(record.weight)
end

-- The pets out in the yard, as a list of uids.
function LifeUtil.pets(data): { string }
	local list = {}
	for uid in data.pen or {} do
		if data.parts[uid] then
			table.insert(list, uid)
		end
	end
	table.sort(list)
	return list
end

-- For yard spots and garden beds: the first free spot, or the spot with the worst item
-- (and that item's income).
local function bestSpot(data, where, count: number)
	local worstSpot, worstIncome = nil, math.huge
	for n = 1, count do
		local key = tostring(n)
		local uid = where[key]
		if not uid or not data.parts[uid] then
			return key, -1
		end
		local income = LifeUtil.itemIncome(data.parts[uid])
		if income < worstIncome then
			worstSpot, worstIncome = key, income
		end
	end
	return worstSpot, worstIncome
end

-- Puts an item the player owns (uid) out where it fits if it's an upgrade: into the yard as
-- a pet, onto a yard spot or into a garden bed. Whatever it replaces goes back to the
-- backpack. Returns where it went ("pen", "yard", "garden") or "backpack" if it wasn't
-- better than anything out.
function LifeUtil.placeIfBetter(data, uid: string): string
	local record = data.parts[uid]
	local item = record and Items.byId[record.id]
	if not item then
		return "backpack"
	end
	local income = LifeUtil.itemIncome(record)
	data.pen = data.pen or {}
	data.yard = data.yard or {}
	data.garden = data.garden or {}
	local spaces = LifeUtil.spaces(data)
	if item.kind == "Pet" then
		local pets = LifeUtil.pets(data)
		if #pets < spaces.pets then
			data.pen[uid] = true
			return "pen"
		end
		local worst, worstIncome = nil, math.huge
		for _, other in pets do
			local otherIncome = LifeUtil.itemIncome(data.parts[other])
			if otherIncome < worstIncome then
				worst, worstIncome = other, otherIncome
			end
		end
		if worst and income > worstIncome then
			data.pen[worst] = nil
			data.pen[uid] = true
			return "pen"
		end
	elseif item.kind == "Yard" or item.kind == "Plant" then
		local where = if item.kind == "Yard" then data.yard else data.garden
		local count = if item.kind == "Yard" then spaces.yard else spaces.garden
		local spot, worstIncome = bestSpot(data, where, count)
		if spot and income > worstIncome then
			where[spot] = uid
			return if item.kind == "Yard" then "yard" else "garden"
		end
	end
	return "backpack"
end

-- Whether putting this backpack item out would earn more (without changing the save).
function LifeUtil.isUpgrade(data, uid: string): boolean
	local copy = {
		parts = data.parts,
		pen = table.clone(data.pen or {}),
		yard = table.clone(data.yard or {}),
		garden = table.clone(data.garden or {}),
		plotLevel = data.plotLevel,
		houseLevel = data.houseLevel,
	}
	return LifeUtil.placeIfBetter(copy, uid) ~= "backpack"
end

-- Takes an item off wherever it's out (it goes to the backpack).
function LifeUtil.takeOff(data, uid: string)
	if data.pen then
		data.pen[uid] = nil
	end
	for _, where in { data.yard or {}, data.garden or {} } do
		for spot, other in where do
			if other == uid then
				where[spot] = nil
			end
		end
	end
end

-- The nest numbers the player can use (Extra Nests adds two).
function LifeUtil.nestCount(extraNests: boolean): number
	return Items.NESTS + (if extraNests then 2 else 0)
end

return LifeUtil
