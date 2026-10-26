-- Helpers for a player's house data, shared by the server and the UI.
--
-- data.parts = { [uid] = { id = partId, mutations? } }: every part the player owns.
-- data.house = { [slotId] = uid }: which owned part is installed in each slot (a slot with
-- no entry shows the free Basic part). Parts that aren't installed are in the backpack.

local Config = require(script.Parent.Config)
local Mutations = require(script.Parent.Mutations)
local Parts = require(script.Parent.Parts)

local HouseUtil = {}

-- The part id installed in a slot (Basic if nothing is).
function HouseUtil.installed(data, slotId: string): string
	local uid = data.house and data.house[slotId]
	local owned = uid and data.parts[uid]
	return if owned then owned.id else Parts.basic(slotId)
end

-- The installed part's record (nil for Basic) and its uid.
function HouseUtil.installedRecord(data, slotId: string)
	local uid = data.house and data.house[slotId]
	local owned = uid and data.parts[uid]
	return owned, if owned then uid else nil
end

-- { [slotId] = partId } for HouseModel.house.
function HouseUtil.layout(data): { [string]: string }
	local layout = {}
	for _, slot in Parts.SLOTS do
		layout[slot.id] = HouseUtil.installed(data, slot.id)
	end
	return layout
end

-- What one part earns a second (before rebirths and passes).
function HouseUtil.partIncome(record): number
	local part = Parts.byId[record.id]
	if not part then
		return 0
	end
	return part.income * Mutations.mult(record.mutations)
end

-- The whole house's income a second, including rebirths (passes are added by the server).
function HouseUtil.houseIncome(data): number
	local total = 0
	for _, slot in Parts.SLOTS do
		local record = HouseUtil.installedRecord(data, slot.id)
		total += HouseUtil.partIncome(record or { id = Parts.basic(slot.id) })
	end
	return total * Config.incomeMultiplier(data.rebirths)
end

-- uid -> slot for every installed part.
function HouseUtil.installedSlots(data): { [string]: string }
	local slots = {}
	for slotId, uid in data.house or {} do
		slots[uid] = slotId
	end
	return slots
end

-- The uids in the backpack (owned, not installed), best first.
function HouseUtil.backpack(data): { string }
	local installed = HouseUtil.installedSlots(data)
	local list = {}
	for uid in data.parts do
		if not installed[uid] then
			table.insert(list, uid)
		end
	end
	table.sort(list, function(a, b)
		local ia, ib = HouseUtil.partIncome(data.parts[a]), HouseUtil.partIncome(data.parts[b])
		if ia ~= ib then
			return ia > ib
		end
		return a < b
	end)
	return list
end

function HouseUtil.backpackCount(data): number
	return #HouseUtil.backpack(data)
end

-- What a part sells for.
function HouseUtil.sellPrice(record): number
	return math.floor(HouseUtil.partIncome(record) * Config.SELL_MULTIPLIER)
end

-- "Golden Candy Roof"
function HouseUtil.displayName(record): string
	local part = Parts.byId[record.id]
	local name = if part then part.name else record.id
	local top = Mutations.top(record.mutations)
	return if top then top .. " " .. name else name
end

return HouseUtil
