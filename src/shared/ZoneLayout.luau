-- Where the zones are. They run in a line west from the end of the town street: zone 1
-- starts at START_X and each one is LENGTH studs long and WIDTH wide (centred on z = 0).
-- Each zone has a pile of part pedestals in a ring at its far end, round the guardian's
-- home. Shared so the server builds them and the client knows which zone you're in.

local Parts = require(script.Parent.Parts)

local ZoneLayout = {}

ZoneLayout.START_X = -200 -- the east edge of zone 1 (the town street ends just before it)
ZoneLayout.LENGTH = 130
ZoneLayout.WIDTH = 110
ZoneLayout.PEDESTALS = 6
ZoneLayout.RING = 20 -- pedestal ring radius round the guardian's home
ZoneLayout.HOME_U = 98 -- how far into the zone the guardian's home is

-- A zone's east (entrance) and west (back) x.
function ZoneLayout.edges(index: number): (number, number)
	local east = ZoneLayout.START_X - (index - 1) * ZoneLayout.LENGTH
	return east, east - ZoneLayout.LENGTH
end

-- A point in a zone from (u = studs in from the entrance, v = z).
function ZoneLayout.point(index: number, u: number, v: number): Vector3
	local east = ZoneLayout.edges(index)
	return Vector3.new(east - u, 0, v)
end

function ZoneLayout.center(index: number): Vector3
	return ZoneLayout.point(index, ZoneLayout.LENGTH / 2, 0)
end

function ZoneLayout.guardianHome(index: number): Vector3
	return ZoneLayout.point(index, ZoneLayout.HOME_U, 0)
end

-- The pedestals sit on the back half of a ring round the guardian's home, so you have to
-- get past it to reach them.
function ZoneLayout.pedestal(index: number, n: number): Vector3
	local a = math.rad(-90 + (n - 1) * 180 / (ZoneLayout.PEDESTALS - 1))
	return ZoneLayout.point(
		index,
		ZoneLayout.HOME_U + math.cos(a) * ZoneLayout.RING,
		math.sin(a) * ZoneLayout.RING * 1.2
	)
end

-- Which zone a position is in (nil in town).
function ZoneLayout.zoneAt(position: Vector3): number?
	if math.abs(position.Z) > ZoneLayout.WIDTH / 2 + 2 then
		return nil
	end
	local u = ZoneLayout.START_X - position.X
	if u < 0 then
		return nil
	end
	local index = math.floor(u / ZoneLayout.LENGTH) + 1
	return if index <= #Parts.ZONES then index else nil
end

-- True if a position is inside zone `index` (plus `margin` studs all round).
function ZoneLayout.inside(index: number, position: Vector3, margin: number?): boolean
	local east, west = ZoneLayout.edges(index)
	local m = margin or 0
	return position.X <= east + m and position.X >= west - m and math.abs(position.Z) <= ZoneLayout.WIDTH / 2 + m
end

return ZoneLayout
