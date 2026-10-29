-- The zones: eggs to steal, each zone guarded by a giant Freek.
--
-- Eggs lie scattered on the ground all over each zone (ZoneLayout.eggCount at a time; when
-- one is taken a new one turns up somewhere else a few seconds later). Each is one of the
-- zone's eggs (Items.ZONES: what kind of thing hatches from it and the odds of each rarity):
-- what's inside is decided when it appears, and the egg is designed around it (EggModel).
-- Rarer eggs lie deeper in, nearer the guardian. Each shows its rarity, what's inside, its
-- weight and hatch time, sometimes with a mutation the hatched item keeps. Hold Grab on one
-- and run! Each zone's guardian sleeps at the back of its zone until someone grabs one of
-- its eggs; then it wakes and chases whoever is carrying an egg from its zone (only its own
-- eggs: carrying another zone's egg past it is safe), and once nobody is, it walks home and
-- goes back to sleep. It runs at Items.guardianSpeed: a bit slower than a player who has
-- the zone's Speed, so if you trained enough you get away, and if you didn't it catches you,
-- flings you toward town and you drop the egg.
--
-- Guardians live on the server as plain data (position, heading, who they're chasing) and
-- are published as attributes on ReplicatedStorage.Guardians, so every client builds and
-- animates its own copy smoothly (client GuardianFX).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Events = require(ReplicatedStorage.Shared.Events)
local Format = require(ReplicatedStorage.Shared.Format)
local EggModel = require(ReplicatedStorage.Shared.EggModel)
local FloatText = require(ReplicatedStorage.Shared.FloatText)
local GuardianAttacks = require(ReplicatedStorage.Shared.GuardianAttacks)
local Items = require(ReplicatedStorage.Shared.Items)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ZoneLayout = require(ReplicatedStorage.Shared.ZoneLayout)

local ZoneDecor = require(script.Parent.ZoneDecor)

local ZoneService = {}

local RESPAWN_MIN, RESPAWN_MAX = 6, 12 -- seconds before an empty pedestal grows a new egg
local CATCH_RADIUS = 7
local LEASH = 14 -- how far past its zone's edges a guardian keeps chasing
local GIVE_UP_DISTANCE = 220 -- a thief this far ahead got away (reaching town always does)
local PUBLISH_INTERVAL = 0.1

local notifyRemote = Remotes.get("Notify")
local knockbackRemote = Remotes.get("Knockback")
local attackRemote = Remotes.get("GuardianAttack")
local rng = Random.new()

local zones = {}
local inReach, startAttack, stepAttacks -- guardian helpers, defined further down -- [index] = { pedestals = { { spot, part, model, ring, label, respawnAt, taken } }, guardian }
local hooks = {
	carrying = function(_player)
		return nil
	end,
	drop = function(_player, _message)
		return false
	end,
}
-- Mutations an egg can grow with (the item that hatches keeps them).
local MUTATION_FACTOR = 0.6

--------------------------------------------------------------------------------
-- Pedestals
--------------------------------------------------------------------------------

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		p[key] = value
	end
	return p
end

-- An egg spot: where one egg lies on the ground (it moves to a new random place each time a
-- new egg turns up), with a glowing ring round it in the egg's rarity colour and floating
-- text. `base` is an invisible part at the spot that holds the Grab prompt and the text.
local function buildPedestal(parent: Instance, index: number, n: number)
	local base = part({
		Name = "EggSpot" .. n,
		Size = Vector3.new(4, 1, 4),
		CFrame = CFrame.new(ZoneLayout.guardianHome(index)),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Parent = parent,
	})
	local ring = part({
		Name = "EggRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.12, 5, 5),
		CFrame = base.CFrame * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(200, 200, 200),
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		CanCollide = false,
		CanQuery = false,
		Parent = parent,
	})
	-- Floating text, only up close: its rarity and what's inside (the weight and hatch time
	-- are on the Grab prompt).
	local gui, lines = FloatText.new(base, { { size = 20, heavy = true }, { size = 16 } }, { maxDistance = 26 })
	return {
		spot = base.CFrame,
		base = base,
		ring = ring,
		labels = { rarity = lines[1], name = lines[2], gui = gui },
		record = nil,
		model = nil,
		respawnAt = 0,
		taken = false,
	}
end

-- A random place on the ground in zone `index` for a new egg: rarer eggs lie deeper in, near
-- the guardian; nowhere inside the scenery or right on top of another egg.
local function pickSpot(index: number, rarity: string, others): CFrame
	local length, width = ZoneLayout.length(index), ZoneLayout.WIDTH
	local homeU = ZoneLayout.homeU(index)
	local depth = ((Rarities.rank[rarity] or 1) - 1) / (#Rarities.order - 1) -- 0 common .. 1 secret
	local nearest = 22 + depth * (homeU - 40) -- how close to the entrance it may lie
	local props = ZoneDecor.propSpots[index] or {}
	local best, bestRoom = nil, -1
	for _ = 1, 30 do
		local u = rng:NextNumber(nearest, length - 8)
		local v = rng:NextNumber(-width / 2 + 8, width / 2 - 8)
		local point = ZoneLayout.point(index, u, v)
		local room = math.huge
		for _, prop in props do
			room = math.min(room, (prop - point).Magnitude - 6)
		end
		for _, other in others do
			if other.record and other.spot then
				room = math.min(room, (other.spot.Position - point).Magnitude - 7)
			end
		end
		if room > 0 then
			return CFrame.new(point)
		elseif room > bestRoom then
			best, bestRoom = point, room
		end
	end
	return CFrame.new(best or ZoneLayout.point(index, length - 12, 0))
end

-- Picks the egg that turns up next in this zone, and what's inside it:
-- { egg = zone, rarity, item, mutations, weight, baseWeight } (weights in kg, see Items).
local function rollEgg(index: number)
	local rarity = Items.rollRarity(index, rng, Events.boost("rareBoost"))
	local mutations = {}
	for _, mutation in Mutations.list do
		if rng:NextNumber() < mutation.chance * MUTATION_FACTOR * Events.boost("mutationBoost") then
			table.insert(mutations, mutation.id)
			break
		end
	end
	-- Weather events give every new egg a good chance of their mutation.
	local weather = Events.weather()
	if weather and rng:NextNumber() < 0.25 then
		mutations = { weather.mutation }
	end
	return {
		egg = index,
		rarity = rarity,
		item = Items.rollItem(Items.ZONES[index].kind, rarity, rng),
		mutations = Mutations.pack(mutations),
		weight = Items.eggBaseWeight(index) * Items.rollWeightFactor(rng, Events.boost("rareBoost")),
		baseWeight = Items.eggBaseWeight(index),
	}
end

-- "Golden Woofles Egg"
function ZoneService.eggName(record): string
	local top = Mutations.top(record.mutations)
	local name = Items.itemEggName(record.egg, record.item)
	return if top then top .. " " .. name else name
end

-- Shows an egg on a spot. keepSpot = true puts it back exactly where the spot was (an egg a
-- guardian took back); otherwise it turns up somewhere new. quiet = true never announces it.
local function showEgg(index: number, pedestal, record, keepSpot: boolean?, quiet: boolean?)
	if pedestal.model then
		pedestal.model:Destroy()
	end
	pedestal.record = record
	pedestal.taken = false
	local zone = Items.ZONES[index]
	local kind = Items.KINDS[zone.kind]
	local color = Rarities.info[record.rarity].color
	-- A new place on the ground for it (or the same place, for an egg put back).
	if not keepSpot then
		pedestal.spot = pickSpot(index, record.rarity, zones[index].pedestals)
	end
	pedestal.base.CFrame = pedestal.spot * CFrame.new(0, 0.5, 0)
	pedestal.ring.CFrame = pedestal.spot * CFrame.new(0, 0.07, 0) * CFrame.Angles(0, 0, math.pi / 2)
	pedestal.ring.Transparency = 0.35
	local model, height = EggModel.build(index, record.item)
	local factor = Items.weightFactor(record)
	local scale = Items.weightScale(factor)
	Items.scaleModel(model, scale)
	model:PivotTo(pedestal.spot * CFrame.Angles(0, math.rad(180 + (rng:NextNumber() - 0.5) * 40), 0))
	-- The ring fits round the egg and the floating text clears its top, however big it is.
	pedestal.ring.Size = Vector3.new(0.12, 4.4 * scale + 1.6, 4.4 * scale + 1.6)
	pedestal.labels.gui.StudsOffsetWorldSpace = Vector3.new(0, 1.5 + height * scale, 0)
	local top = Mutations.top(record.mutations)
	if top and model.PrimaryPart then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Mutations.byId[top].color
		sparkles.Parent = model.PrimaryPart
	end
	model.Parent = pedestal.base.Parent
	pedestal.model = model
	pedestal.ring.Color = color
	pedestal.labels.rarity.Text = string.upper(record.rarity)
	pedestal.labels.rarity.TextColor3 = color
	pedestal.labels.name.Text = kind.icon .. " " .. ZoneService.eggName(record)
	pedestal.labels.name.TextColor3 = Items.weightColor(factor)
	pedestal.labels.gui.Enabled = true

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GrabPrompt"
	prompt.ActionText = "Grab"
	prompt.ObjectText = "⚖ "
		.. Format.weight(record.weight)
		.. "  ·  ⏱ "
		.. Format.time(Items.HATCH_SECONDS[record.rarity])
	prompt.HoldDuration = Config.GRAB_HOLD_SECONDS
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Zone", index)
	prompt:SetAttribute("Pedestal", table.find(zones[index].pedestals, pedestal))
	prompt.Parent = pedestal.base

	if
		not keepSpot
		and not quiet
		and (Rarities.rank[record.rarity] >= Rarities.rank.Ultra or top == "Rainbow" or factor >= 10)
	then
		for _, player in Players:GetPlayers() do
			notifyRemote:FireClient(
				player,
				"🥚 A "
					.. Format.weight(record.weight)
					.. " "
					.. string.upper(record.rarity)
					.. " "
					.. ZoneService.eggName(record)
					.. " just appeared in "
					.. zone.name
					.. "!",
				"discovery"
			)
		end
	end
end

local function clearPedestal(pedestal)
	if pedestal.model then
		pedestal.model:Destroy()
		pedestal.model = nil
	end
	local prompt = pedestal.base:FindFirstChild("GrabPrompt")
	if prompt then
		-- Destroyed a moment later: other PromptTriggered handlers may still be looking at it.
		prompt.Enabled = false
		prompt.Name = "OldGrabPrompt"
		task.defer(prompt.Destroy, prompt)
	end
	pedestal.record = nil
	pedestal.ring.Transparency = 1
	pedestal.labels.gui.Enabled = false
end

--------------------------------------------------------------------------------
-- Dropped eggs: knocked out of a thief's arms outside the egg's own zone, an egg lies on
-- the ground where they were hit until someone grabs it (or LOOSE_SECONDS pass and it
-- vanishes, freeing its spot back home to grow a new one).
--------------------------------------------------------------------------------

local LOOSE_SECONDS = 60
local loose = {} -- [id] = { record, zone, pedestal, base, expiresAt }
local nextLoose = 0
local looseFolder

-- Drops an egg (from spot n of zone `index`) on the ground at `position`.
function ZoneService.dropLoose(record, position: Vector3, index: number, n: number)
	nextLoose += 1
	local id = nextLoose
	local ground = CFrame.new(position.X, 0, position.Z)
	local base = part({
		Name = "DroppedEgg",
		Size = Vector3.new(4, 1, 4),
		CFrame = ground * CFrame.new(0, 0.5, 0),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Parent = looseFolder,
	})
	local model, height = EggModel.build(record.egg, record.item)
	local scale = Items.weightScale(Items.weightFactor(record))
	Items.scaleModel(model, scale)
	model:PivotTo(ground * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0))
	model.Parent = base
	local _, lines = FloatText.new(base, { { size = 16 } }, {
		offset = Vector3.new(0, 1.5 + height * scale, 0),
		maxDistance = 26,
	})
	lines[1].Text = ZoneService.eggName(record)
	lines[1].TextColor3 = Rarities.info[record.rarity].color
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GrabPrompt"
	prompt.ActionText = "Grab"
	prompt.ObjectText = "⚖ " .. Format.weight(record.weight or 1) .. "  ·  dropped"
	prompt.HoldDuration = Config.GRAB_HOLD_SECONDS
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Zone", index)
	prompt:SetAttribute("Pedestal", n)
	prompt:SetAttribute("Loose", id)
	prompt.Parent = base
	loose[id] = { record = record, zone = index, pedestal = n, base = base, expiresAt = os.clock() + LOOSE_SECONDS }
end

local function removeLoose(id: number)
	local entry = loose[id]
	if not entry then
		return nil
	end
	loose[id] = nil
	-- Destroyed a moment later: other PromptTriggered handlers may still be looking at it.
	entry.base.Parent = nil
	task.defer(entry.base.Destroy, entry.base)
	return entry
end

-- A thief was caught in the egg's own zone: the egg goes back exactly where it was taken.
function ZoneService.restore(index: number?, n: number?, record)
	local zone = index and zones[index]
	local pedestal = zone and n and zone.pedestals[n]
	if pedestal and record then
		showEgg(index, pedestal, record, true)
	end
end

-- Takes the egg off a spot (or, with looseId, a dropped egg) for someone to carry. Returns
-- its record, or nil if there's nothing there. A dropped egg's spot back home stays taken.
function ZoneService.take(index: number, n: number, looseId: number?)
	if looseId then
		local entry = removeLoose(looseId)
		return entry and entry.record
	end
	local zone = zones[index]
	local pedestal = zone and zone.pedestals[n]
	if not pedestal or not pedestal.record or pedestal.taken then
		return nil
	end
	local record = pedestal.record
	clearPedestal(pedestal)
	pedestal.taken = true
	return record
end

-- The carried egg was delivered or dropped: the pedestal can grow a new one.
function ZoneService.release(index: number?, n: number?)
	local zone = index and zones[index]
	local pedestal = zone and n and zone.pedestals[n]
	if pedestal then
		pedestal.taken = false
		pedestal.respawnAt = os.clock() + rng:NextNumber(RESPAWN_MIN, RESPAWN_MAX) / Events.boost("respawnBoost")
	end
end

-- Fills every empty pedestal of zone `index` right away (admin). With a rarity, only one
-- egg of that rarity.
function ZoneService.spawnNow(index: number, rarity: string?, mutations: { string }?)
	local zone = zones[index]
	if not zone then
		return
	end
	for _, pedestal in zone.pedestals do
		if not pedestal.taken then
			local record = rollEgg(index)
			if rarity then
				record.rarity = rarity
				record.mutations = Mutations.pack(mutations)
			end
			showEgg(index, pedestal, record)
			if rarity then
				return
			end
		end
	end
end

-- Nightfall: every egg in every zone is swapped for a new random one (eggs being carried
-- are left alone). New Ultra-or-better eggs are announced once, all together.
function ZoneService.restock()
	local best = nil
	for index, zone in zones do
		for _, pedestal in zone.pedestals do
			if not pedestal.taken then
				local record = rollEgg(index)
				showEgg(index, pedestal, record, false, true)
				if not best or Rarities.rank[record.rarity] > Rarities.rank[best.record.rarity] then
					best = { record = record, index = index }
				end
			end
		end
	end
	if best and Rarities.rank[best.record.rarity] >= Rarities.rank.Ultra then
		for _, player in Players:GetPlayers() do
			notifyRemote:FireClient(
				player,
				"🥚 A "
					.. string.upper(best.record.rarity)
					.. " "
					.. ZoneService.eggName(best.record)
					.. " is in "
					.. Items.ZONES[best.index].name
					.. "!",
				"discovery"
			)
		end
	end
end

--------------------------------------------------------------------------------
-- Guardians
--------------------------------------------------------------------------------

local guardianFolder

local function rootPart(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function newGuardian(index: number)
	local home = ZoneLayout.guardianHome(index)
	local zone = Items.ZONES[index]
	local attackId, attack = GuardianAttacks.forSpecies(zone.guardian)
	local data = Instance.new("Configuration")
	data.Name = "Guardian" .. index
	data:SetAttribute("Zone", index)
	data:SetAttribute("Species", zone.guardian)
	data:SetAttribute("Title", zone.title)
	data:SetAttribute("Attack", attackId)
	data.Parent = guardianFolder
	return {
		index = index,
		position = home,
		home = home,
		yaw = -math.pi / 2, -- facing the entrance (+X)
		target = nil,
		cooldown = 0,
		speed = Items.guardianSpeed(index),
		data = data,
		moving = false,
		awake = false, -- guardians sleep at home until someone steals one of their eggs
		attackId = attackId,
		attack = attack,
		attackReadyAt = 0,
		dashUntil = 0,
		projectiles = {},
		pending = nil,
	}
end

-- Wakes a zone's guardian and sends it after a player right away (they just grabbed one of
-- its eggs).
function ZoneService.alert(index: number, player: Player)
	local zone = zones[index]
	if zone then
		zone.guardian.awake = true
		if zone.guardian.cooldown <= os.clock() then
			zone.guardian.target = player
		end
	end
end

-- True if a player is carrying an egg that came from this guardian's zone (guardians only
-- care about their own eggs: carrying another zone's egg through here is safe).
local function carryingOurs(guardian, player: Player): boolean
	local record = hooks.carrying(player)
	return record ~= nil and record.egg == guardian.index
end

local function flatten(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- The guardian got them (by running into them or with its attack). Caught in the egg's own
-- zone, the egg goes back where it was taken from; caught in a zone nearer town, it drops on
-- the ground right there. pull = yanked back toward the guardian instead of flung away.
local function catch(guardian, player: Player, root: BasePart, how: string?, pull: boolean?)
	local zone = Items.ZONES[guardian.index]
	guardian.target = nil
	guardian.cooldown = os.clock() + 2.5
	guardian.projectiles = {}
	guardian.pending = nil
	guardian.dashUntil = 0
	local home = ZoneLayout.inside(guardian.index, root.Position)
	hooks.drop(
		player,
		zone.title .. (if how then "'s " .. how else "") .. " got you! You dropped the egg.",
		if home then nil else root.Position
	)
	-- Fling them back toward town, along the zone and a little toward its middle, in a low
	-- arc (well under the side walls, which also have invisible barriers above them).
	local toMiddle = math.clamp(-root.Position.Z / (ZoneLayout.WIDTH / 2), -1, 1) * 0.3
	local direction = Vector3.new(1, 0, toMiddle).Unit
	if pull then
		local back = flatten(guardian.position - root.Position)
		direction = if back.Magnitude > 0.1 then back.Unit else direction
	end
	knockbackRemote:FireClient(player, direction + Vector3.new(0, 0.25, 0), if pull then 55 else 80, 0.35)
end

-- True if a position is somewhere a guardian keeps chasing: its own zone (plus LEASH) or
-- the zones between it and town.
function inReach(guardian, position: Vector3): boolean
	if ZoneLayout.inside(guardian.index, position, LEASH) then
		return true
	end
	local zone = ZoneLayout.zoneAt(position)
	return zone ~= nil and zone <= guardian.index
end

-- How a target is moving (flat), or standing still if that can't be read.
local function velocityOf(root: BasePart): Vector3
	local ok, velocity = pcall(function()
		return root.AssemblyLinearVelocity
	end)
	return if ok and typeof(velocity) == "Vector3" then flatten(velocity) else Vector3.zero
end

-- Where a target will be in `seconds` (flat, on the ground), from how it's moving now.
local function predict(root: BasePart, seconds: number): Vector3
	return flatten(root.Position) + velocityOf(root) * seconds
end

-- Keeps a point inside the zones a guardian can reach (for teleports).
local function clampToZones(guardian, point: Vector3): Vector3
	local _, west = ZoneLayout.edges(guardian.index)
	local half = ZoneLayout.WIDTH / 2 - 6
	return Vector3.new(math.clamp(point.X, west + 6, ZoneLayout.START_X - 6), 0, math.clamp(point.Z, -half, half))
end

-- Starts the guardian's signature attack on its target, if it's ready and in range.
function startAttack(guardian, target: Player, root: BasePart, now: number)
	local attack = guardian.attack
	if guardian.pending or now < guardian.attackReadyAt or now < guardian.dashUntil then
		return
	end
	local distance = (flatten(root.Position) - guardian.position).Magnitude
	if distance > attack.range or distance < CATCH_RADIUS + 2 then
		return
	end
	guardian.attackReadyAt = now + attack.cooldown
	local from = guardian.position + Vector3.new(0, 5, 0)
	if attack.kind == "dash" then
		guardian.dashUntil = now + attack.time
		guardian.dashStart = now
		attackRemote:FireAllClients(guardian.index, guardian.attackId, { time = attack.time })
	elseif attack.kind == "projectile" then
		local aim = predict(root, distance / attack.speed * attack.lead) + Vector3.new(0, 2.5, 0)
		local velocity = (aim - from).Unit * attack.speed
		local duration = attack.range / attack.speed * 1.5
		table.insert(
			guardian.projectiles,
			{ position = from, velocity = velocity, target = target, endsAt = now + duration }
		)
		attackRemote:FireAllClients(guardian.index, guardian.attackId, {
			from = from,
			velocity = velocity,
			target = target.UserId,
			duration = duration,
		})
	elseif attack.kind == "teleport" then
		local velocity = velocityOf(root)
		local ahead = if velocity.Magnitude > 1 then velocity.Unit else flatten(root.Position - guardian.position).Unit
		local to = clampToZones(guardian, flatten(root.Position) + ahead * attack.ahead)
		attackRemote:FireAllClients(guardian.index, guardian.attackId, { from = guardian.position, to = to })
		guardian.position = to
		guardian.snap = (guardian.snap or 0) + 1
	elseif attack.kind == "beam" then
		guardian.pending = { fireAt = now + attack.windup, target = target, slow = true }
		attackRemote:FireAllClients(guardian.index, guardian.attackId, {
			phase = "aim",
			target = target.UserId,
			windup = attack.windup,
		})
	elseif attack.kind == "strike" then
		local spot = predict(root, attack.windup * attack.lead)
		guardian.pending = { fireAt = now + attack.windup, spot = spot, target = target }
		attackRemote:FireAllClients(guardian.index, guardian.attackId, {
			phase = "mark",
			spot = spot,
			windup = attack.windup,
			radius = attack.radius,
		})
	end
end

-- Moves projectiles and fires aimed attacks whose time has come; anything that hits its
-- target catches them.
function stepAttacks(guardian, dt: number, now: number)
	local attack = guardian.attack
	for i = #guardian.projectiles, 1, -1 do
		local shot = guardian.projectiles[i]
		local root = rootPart(shot.target)
		if attack.homing and root then
			local want = (root.Position - shot.position).Unit * attack.speed
			shot.velocity = shot.velocity:Lerp(want, math.min(1, attack.homing * dt))
		end
		shot.position += shot.velocity * dt
		if
			root
			and carryingOurs(guardian, shot.target)
			and (root.Position - shot.position).Magnitude < attack.radius
		then
			catch(guardian, shot.target, root, attack.name, attack.pull)
			return
		end
		if now > shot.endsAt then
			table.remove(guardian.projectiles, i)
		end
	end
	local pending = guardian.pending
	if pending and now >= pending.fireAt then
		guardian.pending = nil
		local root = rootPart(pending.target)
		if attack.kind == "beam" then
			local from = guardian.position + Vector3.new(0, 5, 0)
			local aimAt = if root then root.Position else from + Vector3.new(attack.range, 0, 0)
			local direction = (aimAt - from).Unit
			attackRemote:FireAllClients(guardian.index, guardian.attackId, {
				phase = "fire",
				from = from,
				direction = direction,
				range = attack.range,
			})
			if root and carryingOurs(guardian, pending.target) then
				local rel = root.Position - from
				local along = rel:Dot(direction)
				local off = (rel - direction * along).Magnitude
				if along > 0 and along < attack.range and off < attack.width then
					catch(guardian, pending.target, root, attack.name)
				end
			end
		elseif attack.kind == "strike" then
			attackRemote:FireAllClients(guardian.index, guardian.attackId, {
				phase = "fire",
				spot = pending.spot,
				radius = attack.radius,
			})
			if root and carryingOurs(guardian, pending.target) then
				if (flatten(root.Position) - pending.spot).Magnitude < attack.radius then
					catch(guardian, pending.target, root, attack.name)
				end
			end
		end
	end
end

local function stepGuardian(guardian, dt: number)
	local now = os.clock()
	local target = guardian.target
	local targetRoot = target and rootPart(target)
	-- Give up on anyone who got away (made it back to town, or outran us by a long way),
	-- isn't carrying one of our eggs any more, or left. Guardians chase thieves out of their
	-- own zone into the zones nearer town.
	if
		target
		and (
			not targetRoot
			or not carryingOurs(guardian, target)
			or not inReach(guardian, targetRoot.Position)
			or (flatten(targetRoot.Position) - guardian.position).Magnitude > GIVE_UP_DISTANCE
			or not target.Parent
		)
	then
		guardian.target = nil
		target, targetRoot = nil, nil
	end
	-- While awake, look for anyone in the zone carrying one of our eggs.
	if not target and guardian.awake and guardian.cooldown <= now then
		local best, bestDistance = nil, math.huge
		for _, player in Players:GetPlayers() do
			local root = rootPart(player)
			if root and carryingOurs(guardian, player) and ZoneLayout.inside(guardian.index, root.Position) then
				local distance = (flatten(root.Position) - guardian.position).Magnitude
				if distance < bestDistance then
					best, bestDistance = player, distance
				end
			end
		end
		if best then
			guardian.target = best
			target, targetRoot = best, rootPart(best)
		end
	end

	local goal, speed
	if target and targetRoot then
		goal = flatten(targetRoot.Position)
		speed = guardian.speed * Events.boost("guardianSpeed")
		if now < (guardian.dashUntil or 0) then
			speed *= guardian.attack.mult
		elseif guardian.pending and guardian.pending.slow then
			speed *= 0.3 -- nearly standing still while it aims
		end
		startAttack(guardian, target, targetRoot, now)
	else
		-- Nobody to chase: walk back home and, once there, go back to sleep.
		goal = guardian.home
		speed = guardian.speed * 0.6
		if guardian.awake and (guardian.position - guardian.home).Magnitude < 1 and guardian.cooldown <= now then
			guardian.awake = false
			guardian.yaw = -math.pi / 2 -- curled up facing the entrance
		end
	end
	local offset = goal - guardian.position
	local distance = offset.Magnitude
	guardian.moving = distance > 0.5
	if guardian.moving then
		local step = math.min(distance, speed * dt)
		guardian.position += offset.Unit * step
		guardian.yaw = math.atan2(-offset.X, -offset.Z)
	end
	if target and targetRoot and (flatten(targetRoot.Position) - guardian.position).Magnitude < CATCH_RADIUS then
		catch(guardian, target, targetRoot)
		return
	end
	stepAttacks(guardian, dt, now)
end

local function publish(guardian)
	local data = guardian.data
	data:SetAttribute("X", math.floor(guardian.position.X * 10) / 10)
	data:SetAttribute("Z", math.floor(guardian.position.Z * 10) / 10)
	data:SetAttribute("Yaw", math.floor(guardian.yaw * 100) / 100)
	data:SetAttribute("Moving", guardian.moving)
	data:SetAttribute("Chasing", guardian.target ~= nil)
	data:SetAttribute("Sleeping", not guardian.awake)
	-- Off the ground during a leap or swoop; Snap changes when it teleports.
	local lift = 0
	local now = os.clock()
	if guardian.attack.lift and now < guardian.dashUntil then
		local t = (now - (guardian.dashStart or now)) / guardian.attack.time
		lift = guardian.attack.lift * math.sin(math.clamp(t, 0, 1) * math.pi)
	end
	data:SetAttribute("Lift", math.floor(lift * 10) / 10)
	data:SetAttribute("Snap", guardian.snap or 0)
	data:SetAttribute("Speed", guardian.speed)
end

-- StealService tells us how to check and end carries (it requires this module).
function ZoneService.setCarrierHooks(newHooks)
	hooks = newHooks
end

function ZoneService.init()
	local map = Instance.new("Folder")
	map.Name = "Zones"
	map.Parent = Workspace
	guardianFolder = Instance.new("Folder")
	guardianFolder.Name = "Guardians"
	guardianFolder.Parent = ReplicatedStorage
	looseFolder = Instance.new("Folder")
	looseFolder.Name = "DroppedEggs"
	looseFolder.Parent = map

	for index = 1, #Items.ZONES do
		local folder = ZoneDecor.build(map, index)
		local pile = Instance.new("Folder")
		pile.Name = "Eggs"
		pile.Parent = folder
		local zone = { pedestals = {}, guardian = newGuardian(index) }
		zones[index] = zone
		for n = 1, ZoneLayout.eggCount(index) do
			zone.pedestals[n] = buildPedestal(pile, index, n)
		end
		for _, pedestal in zone.pedestals do
			showEgg(index, pedestal, rollEgg(index))
		end
		publish(zone.guardian)
	end

	-- Every frame (task.wait() resumes on Heartbeat). Guarded so one bad step can't stop
	-- the guardians for the rest of the server.
	task.spawn(function()
		while true do
			local dt = task.wait()
			for _, zone in zones do
				local ok, err = pcall(stepGuardian, zone.guardian, math.min(dt, 0.1))
				if not ok then
					warn("[ZoneService] " .. tostring(err))
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(PUBLISH_INTERVAL)
			for _, zone in zones do
				publish(zone.guardian)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			for index, zone in zones do
				for _, pedestal in zone.pedestals do
					if not pedestal.record and not pedestal.taken and now >= pedestal.respawnAt then
						showEgg(index, pedestal, rollEgg(index))
					end
				end
			end
			-- Dropped eggs nobody picked up vanish, and their spot back home grows a new egg.
			for id, entry in loose do
				if now >= entry.expiresAt then
					removeLoose(id)
					ZoneService.release(entry.zone, entry.pedestal)
				end
			end
		end
	end)
end

return ZoneService
