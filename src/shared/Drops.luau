-- Freeks arrive by cannon. Eight cannons hang on the glass bubble over the map, and each
-- fires a Freek every FIRE_INTERVAL seconds (they take turns, so one lands every few
-- seconds). A Freek flies down, lands somewhere in the town square, wanders around for
-- WANDER_TIME, then walks into the Freek House and is gone. Hold Grab on it (and pay) to
-- carry it home.
--
-- Where a Freek is at any moment depends only on its seed, cannon and launch time, so the
-- server (which checks grabs) and every client (which draws it) agree without sending
-- positions around.

local Rarities = require(script.Parent.Rarities)

local Drops = {}

-- The bubble and its cannons.
Drops.DOME_RADIUS = 285
Drops.CANNON_COUNT = 8
Drops.CANNON_ELEVATION = math.rad(30) -- how high up the bubble the cannons hang
Drops.FIRE_INTERVAL = 30 -- seconds between shots from each cannon

-- Flight, wandering and leaving.
Drops.FLIGHT_TIME = 3.2
Drops.FLIGHT_ARC = 30 -- extra height in the middle of the flight
Drops.WANDER_TIME = 60
Drops.WANDER_SPEED = 5
Drops.EXIT_SPEED = 9
-- The town square between the two rows of barns, where Freeks land and wander.
Drops.AREA = { minX = -125, maxX = 125, minZ = -23, maxZ = 23 }
-- Height of the town square's floor, which Freeks walk on.
Drops.GROUND_Y = 0.2
-- The Freek House at the west end; Freeks nobody grabbed walk in through this door.
Drops.HOUSE_POSITION = Vector3.new(-152, 0, 0)
Drops.HOUSE_DOOR = Vector3.new(-143.5, 0, 0)

Drops.GRAB_DISTANCE = 12 -- how close a player must be to grab

-- Chance of each rarity per shot. Secrets never come out of a cannon.
Drops.ODDS = {
	{ rarity = "Common", weight = 70 },
	{ rarity = "Uncommon", weight = 22 },
	{ rarity = "Rare", weight = 6.5 },
	{ rarity = "Legendary", weight = 1.3 },
	{ rarity = "Mystic", weight = 0.2 },
	{ rarity = "Ultra", weight = 0.04 },
}

-- Scales each mutation's chance for cannon Freeks (the only place mutations come from).
Drops.MUTATION_FACTOR = 0.5

-- Price of a Freek that has no fixed shop price: this many seconds of its income.
Drops.PRICE_SECONDS = 50

-- Rarities at or above this get announced to the whole server when they're fired.
Drops.ANNOUNCE_RANK = Rarities.rank.Legendary

-- Where cannon `index` hangs on the bubble, pointing at the middle of the town square.
function Drops.cannonCFrame(index: number): CFrame
	local angle = (index - 0.5) / Drops.CANNON_COUNT * math.pi * 2
	local flat = Drops.DOME_RADIUS * math.cos(Drops.CANNON_ELEVATION)
	local position = Vector3.new(
		math.cos(angle) * flat,
		Drops.DOME_RADIUS * math.sin(Drops.CANNON_ELEVATION),
		math.sin(angle) * flat
	)
	return CFrame.lookAt(position, Vector3.new(0, 10, 0))
end

-- Where a fired Freek leaves the barrel.
function Drops.muzzle(index: number): Vector3
	return (Drops.cannonCFrame(index) * CFrame.new(0, 0, -12)).Position
end

local function clampToArea(position: Vector3): Vector3
	local area = Drops.AREA
	return Vector3.new(
		math.clamp(position.X, area.minX, area.maxX),
		Drops.GROUND_Y,
		math.clamp(position.Z, area.minZ, area.maxZ)
	)
end

-- The whole trip of one Freek: { launch, land, muzzle, legs, wanderEnd, finish }.
-- legs = { { start, finish, from, to, facing } } covering wandering and the walk home.
function Drops.plan(seed: number, cannon: number, launch: number)
	local rng = Random.new(seed)
	local area = Drops.AREA
	local landAt =
		Vector3.new(rng:NextNumber(area.minX, area.maxX), Drops.GROUND_Y, rng:NextNumber(area.minZ, area.maxZ))
	local legs = {}
	local t = launch + Drops.FLIGHT_TIME
	local wanderEnd = t + Drops.WANDER_TIME
	local position = landAt
	local facing = (Vector3.new(0, 0, 0) - Drops.muzzle(cannon)) * Vector3.new(1, 0, 1)
	facing = if facing.Magnitude > 0.01 then facing.Unit else Vector3.new(0, 0, -1)

	while t < wanderEnd do
		-- Stop and look around, then toddle somewhere nearby.
		local pause = rng:NextNumber(0.4, 2)
		table.insert(legs, { start = t, finish = t + pause, from = position, to = position, facing = facing })
		t += pause
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(6, 22)
		local target = clampToArea(position + Vector3.new(math.cos(angle), 0, math.sin(angle)) * distance)
		local length = (target - position).Magnitude
		if length > 0.5 then
			facing = (target - position).Unit
			local duration = length / Drops.WANDER_SPEED
			table.insert(legs, { start = t, finish = t + duration, from = position, to = target, facing = facing })
			t += duration
			position = target
		end
	end

	-- Time's up: head into the Freek House.
	local home = Drops.HOUSE_DOOR + Vector3.new(0, Drops.GROUND_Y, 0)
	local length = (home - position).Magnitude
	if length > 0.5 then
		facing = (home - position).Unit
	end
	local duration = length / Drops.EXIT_SPEED
	table.insert(
		legs,
		{ start = t, finish = t + duration, from = position, to = home, facing = facing, leaving = true }
	)

	return {
		launch = launch,
		land = launch + Drops.FLIGHT_TIME,
		landAt = landAt,
		muzzle = Drops.muzzle(cannon),
		legs = legs,
		finish = t + duration,
	}
end

-- Where a Freek on `path` is at time `now`, as a ground CFrame for FreekModel:PivotTo,
-- plus what it's doing: "waiting", "flying", "wandering", "leaving" or "gone".
function Drops.cframeAt(path, now: number): (CFrame, string, boolean)
	if now < path.launch then
		return CFrame.new(path.muzzle), "waiting", false
	end
	if now < path.land then
		local a = (now - path.launch) / Drops.FLIGHT_TIME
		local position = path.muzzle:Lerp(path.landAt, a) + Vector3.new(0, Drops.FLIGHT_ARC * 4 * a * (1 - a), 0)
		return CFrame.new(position) * CFrame.Angles(a * math.pi * 4, a * math.pi * 3, 0), "flying", false
	end
	if now >= path.finish then
		return CFrame.new(Drops.HOUSE_DOOR), "gone", false
	end
	for _, leg in path.legs do
		if now < leg.finish then
			local a = math.clamp((now - leg.start) / math.max(leg.finish - leg.start, 0.001), 0, 1)
			local position = leg.from:Lerp(leg.to, a)
			local moving = leg.from ~= leg.to
			return CFrame.lookAt(position, position + leg.facing),
				if leg.leaving then "leaving" else "wandering",
				moving
		end
	end
	return CFrame.new(Drops.HOUSE_DOOR), "gone", false
end

return Drops
