-- Where the zones are. They run in a line west from the end of the town street: zone 1
-- starts at START_X and is LENGTH studs long; each zone after it is GROWTH studs longer
-- than the last, so the deeper zones are longer runs. All are WIDTH wide (centred on z = 0).
-- Each zone has a pile of egg pedestals in a ring near its far end, round the guardian's
-- home. Shared so the server builds them and the client knows which zone you're in.

local Items = require(script.Parent.Items)

local ZoneLayout = {}

ZoneLayout.START_X = -230 -- the east edge of zone 1 (the town street ends just before it)
ZoneLayout.LENGTH = 130 -- zone 1's length
ZoneLayout.GROWTH = 25 -- how much longer each zone is than the one before
ZoneLayout.WIDTH = 140
ZoneLayout.RING = 20 -- how far round the guardian's home its patrol keeps closest
ZoneLayout.HOME_BACK = 32 -- how far before a zone's back wall the guardian's home is

-- How long zone `index` is.
function ZoneLayout.length(index: number): number
	return ZoneLayout.LENGTH + (index - 1) * ZoneLayout.GROWTH
end

-- How far into zone `index` (from its entrance) the guardian's home and the pile are.
function ZoneLayout.homeU(index: number): number
	return ZoneLayout.length(index) - ZoneLayout.HOME_BACK
end

-- A zone's east (entrance) and west (back) x.
function ZoneLayout.edges(index: number): (number, number)
	local east = ZoneLayout.START_X
	for i = 1, index - 1 do
		east -= ZoneLayout.length(i)
	end
	return east, east - ZoneLayout.length(index)
end

-- The west end of the last zone (the end of the map).
function ZoneLayout.westEnd(): number
	local _, west = ZoneLayout.edges(#Items.ZONES)
	return west
end

-- A point in a zone from (u = studs in from the entrance, v = z).
function ZoneLayout.point(index: number, u: number, v: number): Vector3
	local east = ZoneLayout.edges(index)
	return Vector3.new(east - u, 0, v)
end

function ZoneLayout.center(index: number): Vector3
	return ZoneLayout.point(index, ZoneLayout.length(index) / 2, 0)
end

function ZoneLayout.guardianHome(index: number): Vector3
	return ZoneLayout.point(index, ZoneLayout.homeU(index), 0)
end

-- How many eggs lie about zone `index` at once (more in the bigger zones).
function ZoneLayout.eggCount(index: number): number
	return 8 + index
end

-- Which zone a position is in (nil in town).
function ZoneLayout.zoneAt(position: Vector3): number?
	if math.abs(position.Z) > ZoneLayout.WIDTH / 2 + 2 then
		return nil
	end
	for index = 1, #Items.ZONES do
		local east, west = ZoneLayout.edges(index)
		if position.X <= east and position.X > west then
			return index
		end
	end
	return nil
end

-- True if a position is inside zone `index` (plus `margin` studs all round).
function ZoneLayout.inside(index: number, position: Vector3, margin: number?): boolean
	local east, west = ZoneLayout.edges(index)
	local m = margin or 0
	return position.X <= east + m and position.X >= west - m and math.abs(position.Z) <= ZoneLayout.WIDTH / 2 + m
end

return ZoneLayout
