-- Helpers for a player's save, shared by the server and the UI.
--
-- data.parts = { [uid] = { id = itemId, mutations? } }: every item the player owns (house
-- parts, pets, yard items, plants; see Items.luau). Items are "out" in one place each:
--   data.house  = { [slotId] = uid }     house parts on the house (a slot with none shows Basic)
--   data.pen    = { [uid] = true }       pets roaming the yard (up to Items.PET_SLOTS)
--   data.yard   = { ["1".."6"] = uid }   yard items on the yard spots
--   data.garden = { ["1".."6"] = uid }   plants in the garden beds
-- Everything else is in the backpack.
-- data.nests = { ["1".."5"] = { zone, rarity, endsAt, mutations? } }: eggs growing at home.

local Config = require(script.Parent.Config)
local Format = require(script.Parent.Format)
local Items = require(script.Parent.Items)
local Mutations = require(script.Parent.Mutations)
local Parts = require(script.Parent.Parts)

local LifeUtil = {}

-- The part id on a house slot (Basic if nothing is).
function LifeUtil.installed(data, slotId: string): string
	local uid = data.house and data.house[slotId]
	local owned = uid and data.parts[uid]
	return if owned then owned.id else Parts.basic(slotId)
end

-- The part on a house slot (nil for Basic) and its uid.
function LifeUtil.installedRecord(data, slotId: string)
	local uid = data.house and data.house[slotId]
	local owned = uid and data.parts[uid]
	return owned, if owned then uid else nil
end

-- { [slotId] = partId } for HouseModel.house.
function LifeUtil.layout(data): { [string]: string }
	local layout = {}
	for _, slot in Parts.SLOTS do
		layout[slot.id] = LifeUtil.installed(data, slot.id)
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

-- uid -> where it is ("house:Roof", "pen", "yard:3", "garden:2") for everything that's out.
function LifeUtil.placed(data): { [string]: string }
	local where = {}
	for slotId, uid in data.house or {} do
		where[uid] = "house:" .. slotId
	end
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

-- Everything out earning (passes are added by the server).
function LifeUtil.totalIncome(data): number
	local total = 0
	for _, slot in Parts.SLOTS do
		local record = LifeUtil.installedRecord(data, slot.id)
		total += LifeUtil.itemIncome(record or { id = Parts.basic(slot.id) })
	end
	for uid, where in LifeUtil.placed(data) do
		if string.sub(where, 1, 6) ~= "house:" then
			total += LifeUtil.itemIncome(data.parts[uid])
		end
	end
	return total
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

-- "Golden Candy Roof" (weights are shown separately: LifeUtil.weightText)
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

-- Puts an item the player owns (uid) out where it fits if it's an upgrade: onto its house
-- slot, into the yard as a pet, onto a yard spot or into a garden bed. Whatever it replaces
-- goes back to the backpack. Returns where it went ("house", "pen", "yard", "garden") or
-- "backpack" if it wasn't better than anything out.
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
	if item.kind == "House" then
		local current = LifeUtil.installedRecord(data, item.slot)
		if income > LifeUtil.itemIncome(current or { id = Parts.basic(item.slot) }) then
			data.house[item.slot] = uid
			return "house"
		end
	elseif item.kind == "Pet" then
		local pets = LifeUtil.pets(data)
		if #pets < Items.PET_SLOTS then
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
		local count = if item.kind == "Yard" then Items.YARD_SPOTS else Items.GARDEN_BEDS
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
		house = table.clone(data.house or {}),
		pen = table.clone(data.pen or {}),
		yard = table.clone(data.yard or {}),
		garden = table.clone(data.garden or {}),
	}
	return LifeUtil.placeIfBetter(copy, uid) ~= "backpack"
end

-- Takes an item off wherever it's out (it goes to the backpack).
function LifeUtil.takeOff(data, uid: string)
	for slotId, other in data.house or {} do
		if other == uid then
			data.house[slotId] = nil
		end
	end
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
