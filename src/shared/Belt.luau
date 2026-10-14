-- The conveyor belt in the middle of the map. Shared so the server (which decides what's
-- on it and checks purchases) and clients (which animate it smoothly) agree on where every
-- Freek is: an item's position depends only on when it spawned.

local Rarities = require(script.Parent.Rarities)

local Belt = {}

Belt.START = Vector3.new(-52, 1, 0) -- where Freeks appear (top of the belt surface)
Belt.LENGTH = 104 -- studs travelled before falling off the far end
Belt.SPEED = 4 -- studs per second (so each Freek rides for 26 seconds)
Belt.SPAWN_INTERVAL = 3 -- seconds between new Freeks
Belt.BUY_DISTANCE = 14 -- how close a player must be to buy

-- Chance of each rarity per spawn. Ultra and Secret never appear: breeding only.
Belt.ODDS = {
	{ rarity = "Common", weight = 70 },
	{ rarity = "Uncommon", weight = 22 },
	{ rarity = "Rare", weight = 6.5 },
	{ rarity = "Legendary", weight = 1.3 },
	{ rarity = "Mystic", weight = 0.2 },
}

-- Belt Freeks are half as likely to be mutated as bred ones.
Belt.MUTATION_FACTOR = 0.5

-- Price of a Freek that has no fixed shop price: this many seconds of its income.
Belt.PRICE_SECONDS = 50

-- Rarities at or above this get announced to the whole server when they spawn.
Belt.ANNOUNCE_RANK = Rarities.rank.Legendary

-- Freeks face the way the belt moves (+X).
local FACING = CFrame.Angles(0, -math.pi / 2, 0)

-- Where an item is at time `now`, as a ground CFrame for FreekModel:PivotTo.
function Belt.cframeAt(spawnTime: number, now: number): CFrame
	local travelled = math.clamp((now - spawnTime) * Belt.SPEED, 0, Belt.LENGTH)
	return CFrame.new(Belt.START + Vector3.new(travelled, 0, 0)) * FACING
end

function Belt.isGone(spawnTime: number, now: number): boolean
	return (now - spawnTime) * Belt.SPEED >= Belt.LENGTH
end

return Belt
