-- The zones: eggs to steal, each zone guarded by a giant Freek.
--
-- Eggs lie scattered on the ground all over each zone (ZoneLayout.eggCount at a time; when
-- one is taken a new one turns up somewhere else a few seconds later). Each is one of the
-- zone's eggs (Items.ZONES: what kind of thing hatches from it and the odds of each rarity):
-- what's inside is decided when it appears, and the egg is designed around it (EggModel).
-- Rarer eggs lie deeper in, nearer the guardian. Each shows its rarity, what's inside, its
-- weight and hatch time, sometimes with a mutation the hatched item keeps. Hold Grab on one
-- and run! The zone's guardian chases anyone carrying
-- an egg inside its zone. It runs at Items.guardianSpeed: a bit slower than a player who has
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
local Items = require(ReplicatedStorage.Shared.Items)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ZoneLayout = require(ReplicatedStorage.Shared.ZoneLayout)

local ZoneDecor = require(script.Parent.ZoneDecor)

local ZoneService = {}

local RESPAWN_MIN, RESPAWN_MAX = 6, 12 -- seconds before an empty pedestal grows a new egg
local CATCH_RADIUS = 7
local LEASH = 14 -- how far past its zone's edge a guardian keeps chasing
local PUBLISH_INTERVAL = 0.1

local notifyRemote = Remotes.get("Notify")
local knockbackRemote = Remotes.get("Knockback")
local rng = Random.new()

local zones = {} -- [index] = { pedestals = { { spot, part, model, ring, label, respawnAt, taken } }, guardian }
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

local OUTLINE = Color3.fromRGB(20, 22, 48)

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

local function textLine(parent: Instance, font: Enum.Font, y: number, h: number)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0, y)
	label.Size = UDim2.fromScale(1, h)
	label.TextScaled = true
	label.Font = font
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE
	stroke.Thickness = 3
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	return label
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
	-- Floating text: rarity, what's inside, weight and hatch time.
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(8, 3.2)
	gui.StudsOffset = Vector3.new(0, 6, 0)
	gui.MaxDistance = 26 -- only up close: the eggs speak for themselves from afar
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Parent = base
	local rarity = textLine(gui, Enum.Font.LuckiestGuy, 0, 0.32)
	local name = textLine(gui, Enum.Font.FredokaOne, 0.32, 0.36)
	local income = textLine(gui, Enum.Font.FredokaOne, 0.68, 0.32)
	income.TextColor3 = Color3.fromRGB(255, 215, 60)
	return {
		spot = base.CFrame,
		base = base,
		ring = ring,
		labels = { rarity = rarity, name = name, income = income, gui = gui },
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

local function showEgg(index: number, pedestal, record)
	if pedestal.model then
		pedestal.model:Destroy()
	end
	pedestal.record = record
	pedestal.taken = false
	local zone = Items.ZONES[index]
	local kind = Items.KINDS[zone.kind]
	local color = Rarities.info[record.rarity].color
	-- A new place on the ground for it.
	pedestal.spot = pickSpot(index, record.rarity, zones[index].pedestals)
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
	pedestal.labels.gui.StudsOffset = Vector3.new(0, 2.5 + height * scale, 0)
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
	pedestal.labels.income.Text = "⚖ "
		.. Format.weight(record.weight)
		.. " · ⏱ "
		.. Format.time(Items.HATCH_SECONDS[record.rarity])
	pedestal.labels.gui.Enabled = true

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GrabPrompt"
	prompt.ActionText = "Grab"
	prompt.ObjectText = record.rarity .. " " .. ZoneService.eggName(record)
	prompt.HoldDuration = Config.GRAB_HOLD_SECONDS
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Zone", index)
	prompt:SetAttribute("Pedestal", table.find(zones[index].pedestals, pedestal))
	prompt.Parent = pedestal.base

	if Rarities.rank[record.rarity] >= Rarities.rank.Ultra or top == "Rainbow" or factor >= 10 then
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

-- Takes the egg off a pedestal for someone to carry. Returns its record, or nil if there's
-- nothing there.
function ZoneService.take(index: number, n: number)
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
	local data = Instance.new("Configuration")
	data.Name = "Guardian" .. index
	data:SetAttribute("Zone", index)
	data:SetAttribute("Species", zone.guardian)
	data:SetAttribute("Title", zone.title)
	data.Parent = guardianFolder
	return {
		index = index,
		position = home,
		home = home,
		yaw = -math.pi / 2, -- facing the entrance (+X)
		target = nil,
		cooldown = 0,
		wanderAt = 0,
		wanderTo = home,
		speed = Items.guardianSpeed(index),
		data = data,
		moving = false,
	}
end

-- Sends a guardian after a player right away (they just grabbed an egg).
function ZoneService.alert(index: number, player: Player)
	local zone = zones[index]
	if zone and zone.guardian.cooldown <= os.clock() then
		zone.guardian.target = player
	end
end

local function flatten(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function catch(guardian, player: Player, root: BasePart)
	local zone = Items.ZONES[guardian.index]
	guardian.target = nil
	guardian.cooldown = os.clock() + 2.5
	hooks.drop(player, zone.title .. " caught you! You dropped the egg.")
	-- Fling them back toward town, along the zone and a little toward its middle, in a low
	-- arc (well under the side walls, which also have invisible barriers above them).
	local toMiddle = math.clamp(-root.Position.Z / (ZoneLayout.WIDTH / 2), -1, 1) * 0.3
	local direction = Vector3.new(1, 0, toMiddle).Unit
	knockbackRemote:FireClient(player, direction + Vector3.new(0, 0.25, 0), 80, 0.35)
end

local function stepGuardian(guardian, dt: number)
	local now = os.clock()
	local target = guardian.target
	local targetRoot = target and rootPart(target)
	-- Give up on anyone who got away, isn't carrying anything, or left.
	if
		target
		and (
			not targetRoot
			or not hooks.carrying(target)
			or not ZoneLayout.inside(guardian.index, targetRoot.Position, LEASH)
			or not target.Parent
		)
	then
		guardian.target = nil
		target, targetRoot = nil, nil
	end
	-- Look for thieves in the zone.
	if not target and guardian.cooldown <= now then
		local best, bestDistance = nil, math.huge
		for _, player in Players:GetPlayers() do
			local root = rootPart(player)
			if root and hooks.carrying(player) and ZoneLayout.inside(guardian.index, root.Position) then
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
	else
		-- Patrol: mostly round its home at the back, now and then out across the zone.
		if now >= guardian.wanderAt then
			guardian.wanderAt = now + rng:NextNumber(3, 6)
			if rng:NextNumber() < 0.6 then
				local a = rng:NextNumber() * math.pi * 2
				guardian.wanderTo = guardian.home
					+ Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(0, ZoneLayout.RING)
			else
				guardian.wanderTo = ZoneLayout.point(
					guardian.index,
					rng:NextNumber(30, ZoneLayout.length(guardian.index) - 10),
					rng:NextNumber(-ZoneLayout.WIDTH / 2 + 12, ZoneLayout.WIDTH / 2 - 12)
				)
			end
		end
		goal = guardian.wanderTo
		speed = guardian.speed * 0.45
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
	end
end

local function publish(guardian)
	local data = guardian.data
	data:SetAttribute("X", math.floor(guardian.position.X * 10) / 10)
	data:SetAttribute("Z", math.floor(guardian.position.Z * 10) / 10)
	data:SetAttribute("Yaw", math.floor(guardian.yaw * 100) / 100)
	data:SetAttribute("Moving", guardian.moving)
	data:SetAttribute("Chasing", guardian.target ~= nil)
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
		end
	end)
end

return ZoneService
