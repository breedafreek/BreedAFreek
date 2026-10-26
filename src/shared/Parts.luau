-- House parts: what players steal from the zones and snap onto their house.
--
-- A house has a fixed set of SLOTS (door, windows, roof...). Every part is one slot built in
-- one STYLE (Scrap, Log Cabin, Stone...). A style comes from one zone and has a rarity, and
-- the part's income is the style's base income times the slot's weight. Part ids are
-- "<Style>_<Slot>", e.g. "Candy_Roof".
--
-- Everyone starts with the "Basic" style in every slot. Basic parts can't be stolen or sold;
-- when a slot's part is stolen the slot goes back to Basic.

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

-- Styles, worst to best. zone = the zone that drops them (nil: Basic, given to everyone;
-- Rainbow is a super-rare drop in the last zone). income is per second for a weight-1 slot.
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

-- The zones, in order out from the town. speed = the Speed you need to outrun the guardian,
-- a giant Freek (guardian = its species in Freeks.luau) that chases thieves out of its zone.
Parts.ZONES = {
	{ name = "Junkyard", style = "Scrap", speed = 0, guardian = "Woofles", title = "Junk Dog" },
	{ name = "Pine Woods", style = "Log", speed = 300, guardian = "Howlz", title = "Big Bad Howlz" },
	{ name = "Rocky Quarry", style = "Stone", speed = 2_000, guardian = "Stompy", title = "Rock Stompy" },
	{ name = "Sunny Desert", style = "Sand", speed = 10_000, guardian = "Mumbles", title = "Mummy Mumbles" },
	{ name = "Frosty Peaks", style = "Ice", speed = 40_000, guardian = "BooBoo", title = "Frosty BooBoo" },
	{ name = "Candy Land", style = "Candy", speed = 150_000, guardian = "Chuckles", title = "Candy Chuckles" },
	{ name = "Lava Volcano", style = "Lava", speed = 600_000, guardian = "Chompers", title = "Lava Chompers" },
	{ name = "Royal Kingdom", style = "Royal", speed = 2_500_000, guardian = "CountFangula", title = "Count Fangula" },
	{ name = "Crystal Caves", style = "Crystal", speed = 10_000_000, guardian = "Blinky", title = "Crystal Blinky" },
	{ name = "Sky Islands", style = "Cloud", speed = 50_000_000, guardian = "Stormy", title = "Storm Lord Stormy" },
}
Parts.RAINBOW_CHANCE = 0.02 -- chance a part spawning in the last zone is Rainbow

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

-- How fast a zone's guardian runs: a bit slower than a player who has the zone's speed, so
-- meeting the requirement lets you escape even while carrying (carrying slows you by
-- CARRY_SLOWDOWN).
Parts.CARRY_SLOWDOWN = 0.9
function Parts.guardianSpeed(zoneIndex: number): number
	return Parts.walkSpeed(Parts.ZONES[zoneIndex].speed) * 0.85
end

-- The highest zone a Speed is enough for.
function Parts.zoneFor(speed: number): number
	local best = 1
	for index, zone in Parts.ZONES do
		if speed >= zone.speed then
			best = index
		end
	end
	return best
end

return Parts
