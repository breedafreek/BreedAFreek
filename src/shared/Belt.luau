-- The conveyor belt in the middle of the map. Shared so the server (which decides what's
-- on it and checks purchases) and clients (which animate it smoothly) agree on where every
-- Freek is: an item's position depends only on when it spawned.

local Rarities = require(script.Parent.Rarities)

local Belt = {}

-- Two lanes side by side down the middle of the map, one nearer each row of yards. Each
-- comes out of its own Freek House at the west end and runs east to a drop-off chute.
Belt.START_X = -118 -- where Freeks appear
Belt.Y = 1 -- top of the belt surface
Belt.LANES = { -6, 6 } -- Z position of each lane's centre line
Belt.LENGTH = 236 -- studs travelled before falling off the far end
Belt.SPEED = 6 -- studs per second (so each Freek rides for about 40 seconds)
Belt.SPAWN_INTERVAL = 4 -- seconds between new Freeks on each lane
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

-- Where an item on `lane` is at time `now`, as a ground CFrame for FreekModel:PivotTo.
function Belt.cframeAt(lane: number, spawnTime: number, now: number): CFrame
	local travelled = math.clamp((now - spawnTime) * Belt.SPEED, 0, Belt.LENGTH)
	return CFrame.new(Belt.START_X + travelled, Belt.Y, Belt.LANES[lane] or 0) * FACING
end

function Belt.isGone(spawnTime: number, now: number): boolean
	return (now - spawnTime) * Belt.SPEED >= Belt.LENGTH
end

return Belt
