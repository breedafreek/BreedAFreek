-- House parts: one of the four kinds of item (see Items.luau), hatched from Hardware Eggs
-- and snapped onto the house.
--
-- A house has a fixed set of SLOTS (door, windows, roof...). Every part is one slot built in
-- one STYLE (Scrap, Log Cabin, Stone...). A style has a rarity, and the part's income is the
-- style's base income times the slot's weight. Part ids are "<Style>_<Slot>", e.g.
-- "Candy_Roof" (saves store them, so never rename a style or slot).
--
-- Everyone starts with the "Basic" style in every slot. Basic parts never hatch and can't be
-- sold; an empty slot shows Basic.

local Rarities = require(script.Parent.Rarities)

local Parts = {}

-- The snap slots on every house, in the order the UI lists them. weight scales income
-- (big pieces earn more).
Parts.SLOTS = {
	{ id = "Walls", name = "Walls", icon = "🧱", weight = 1.6 },
	{ id = "Roof", name = "Roof", icon = "🏠", weight = 1.4 },
	{ id = "Door", name = "Door", icon = "🚪", weight = 1 },
	{ id = "Windows", name = "Windows", icon = "🪟", weight = 1 },
	{ id = "Tower", name = "Tower", icon = "🏰", weight = 1.5 },
	{ id = "Chimney", name = "Chimney", icon = "🔥", weight = 0.7 },
	{ id = "Porch", name = "Porch", icon = "🪜", weight = 0.9 },
	{ id = "Fence", name = "Fence", icon = "🚧", weight = 0.8 },
	{ id = "Garden", name = "Garden", icon = "🌷", weight = 0.8 },
	{ id = "Mailbox", name = "Mailbox", icon = "📫", weight = 0.6 },
}
Parts.slotById = {}
for index, slot in Parts.SLOTS do
	slot.order = index
	Parts.slotById[slot.id] = slot
end

-- Styles, worst to best (Basic is given to everyone). income is per second for a weight-1
-- slot.
Parts.STYLES = {
	{ id = "Basic", name = "Basic", rarity = "Common", income = 1 },
	{ id = "Scrap", name = "Scrap", rarity = "Common", income = 3, zone = 1 },
	{ id = "Log", name = "Log Cabin", rarity = "Common", income = 8, zone = 2 },
	{ id = "Stone", name = "Stone", rarity = "Uncommon", income = 20, zone = 3 },
	{ id = "Sand", name = "Sandstone", rarity = "Uncommon", income = 50, zone = 4 },
	{ id = "Ice", name = "Ice", rarity = "Rare", income = 125, zone = 5 },
	{ id = "Candy", name = "Candy", rarity = "Rare", income = 300, zone = 6 },
	{ id = "Lava", name = "Lava", rarity = "Legendary", income = 750, zone = 7 },
	{ id = "Royal", name = "Royal", rarity = "Legendary", income = 1900, zone = 8 },
	{ id = "Crystal", name = "Crystal", rarity = "Mystic", income = 4800, zone = 9 },
	{ id = "Cloud", name = "Cloud", rarity = "Ultra", income = 12000, zone = 10 },
	{ id = "Rainbow", name = "Rainbow", rarity = "Secret", income = 40000, zone = 10, secret = true },
}
Parts.styleById = {}
for index, style in Parts.STYLES do
	style.tier = index
	Parts.styleById[style.id] = style
end

-- Every part, by id.
Parts.byId = {}
Parts.list = {}
for _, style in Parts.STYLES do
	for _, slot in Parts.SLOTS do
		local part = {
			id = style.id .. "_" .. slot.id,
			style = style.id,
			slot = slot.id,
			name = style.name .. " " .. slot.name,
			rarity = style.rarity,
			income = math.max(1, math.floor(style.income * slot.weight + 0.5)),
			tier = style.tier,
		}
		Parts.byId[part.id] = part
		table.insert(Parts.list, part)
	end
end

function Parts.basic(slotId: string): string
	return "Basic_" .. slotId
end

function Parts.isBasic(partId: string): boolean
	local part = Parts.byId[partId]
	return part ~= nil and part.style == "Basic"
end

function Parts.color(partId: string): Color3
	local part = Parts.byId[partId]
	return Rarities.info[part and part.rarity or "Common"].color
end

-- Speed -> walking speed. Grows quickly at first and slowly later, so every zone feels faster
-- but nobody becomes uncontrollable: 0 speed walks at 16, 50M speed at about 53.
function Parts.walkSpeed(speed: number): number
	return 16 + 6 * math.log10(1 + math.max(speed, 0) / 30)
end

return Parts
