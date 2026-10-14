-- Which Freeks are being carried off by a thief right now. Kept in memory only: if the
-- server stops mid-steal, the owner simply keeps the Freek.

local Carried = {}

local byOwner = {} -- [owner Player] = { [uid] = thief Player }

function Carried.is(owner: Player, uid: string): boolean
	local list = byOwner[owner]
	return list ~= nil and list[uid] ~= nil
end

function Carried.set(owner: Player, uid: string, thief: Player?)
	local list = byOwner[owner]
	if thief then
		if not list then
			list = {}
			byOwner[owner] = list
		end
		list[uid] = thief
	elseif list then
		list[uid] = nil
		if next(list) == nil then
			byOwner[owner] = nil
		end
	end
end

-- True if any of this owner's Freeks are being carried off right now.
function Carried.any(owner: Player): boolean
	return byOwner[owner] ~= nil
end

return Carried
