-- The zones: nests of eggs to steal, each guarded by a giant Freek.
--
-- Every zone has a ring of pedestals at its far end. Each pedestal grows one of the zone's
-- eggs (Items.ZONES: what kind of thing hatches from it, and the odds of each rarity). The
-- rarity is rolled when the egg appears and shown above it, sometimes with a mutation the
-- hatched item keeps. Hold Grab on one and run! The zone's guardian chases anyone carrying
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

local function buildPedestal(parent: Instance, index: number, n: number)
	local spot = CFrame.new(ZoneLayout.pedestal(index, n))
	local theme = ZoneDecor.theme(index)
	local base = part({
		Name = "Pedestal",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, 6, 6),
		CFrame = spot * CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = theme.cliff:Lerp(Color3.new(1, 1, 1), 0.3),
		Material = Enum.Material.Marble,
		Parent = parent,
	})
	local ring = part({
		Name = "PedestalRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 6.4, 6.4),
		CFrame = spot * CFrame.new(0, 2.05, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(200, 200, 200),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = parent,
	})
	-- Floating text: rarity, egg name, what hatches and how long it takes.
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(9, 3.6)
	gui.StudsOffset = Vector3.new(0, 8, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Parent = base
	local rarity = textLine(gui, Enum.Font.LuckiestGuy, 0, 0.32)
	local name = textLine(gui, Enum.Font.FredokaOne, 0.32, 0.36)
	local income = textLine(gui, Enum.Font.FredokaOne, 0.68, 0.32)
	income.TextColor3 = Color3.fromRGB(255, 215, 60)
	return {
		spot = spot * CFrame.new(0, 2.1, 0),
		base = base,
		ring = ring,
		labels = { rarity = rarity, name = name, income = income, gui = gui },
		record = nil,
		model = nil,
		respawnAt = 0,
		taken = false,
	}
end

-- Picks the egg that grows next on a pedestal in this zone:
-- { egg = zone, rarity, mutations, size } (size: Items.SIZES, nil = Normal).
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
		mutations = Mutations.pack(mutations),
		size = Items.rollSize(rng, Events.boost("rareBoost")),
	}
end

-- "Massive Golden Garden Egg"
function ZoneService.eggName(record): string
	local top = Mutations.top(record.mutations)
	local name = Items.eggName(record.egg)
	name = if top then top .. " " .. name else name
	return if record.size then record.size .. " " .. name else name
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
	local model, height = EggModel.build(index)
	local size = Items.size(record.size)
	Items.scaleModel(model, size.scale)
	model:PivotTo(pedestal.spot * CFrame.Angles(0, math.rad(180 + (rng:NextNumber() - 0.5) * 40), 0))
	-- The floating text clears the top of the egg, however big it is.
	pedestal.labels.gui.StudsOffset = Vector3.new(0, 3.5 + height * size.scale, 0)
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
	pedestal.labels.name.Text = ZoneService.eggName(record)
	pedestal.labels.name.TextColor3 = size.color
	pedestal.labels.income.Text = kind.icon
		.. " "
		.. kind.name
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

	if
		Rarities.rank[record.rarity] >= Rarities.rank.Ultra
		or top == "Rainbow"
		or size.rank >= Items.sizeById.Giant.rank
	then
		for _, player in Players:GetPlayers() do
			notifyRemote:FireClient(
				player,
				"🥚 A "
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
	pedestal.ring.Color = Color3.fromRGB(120, 120, 130)
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
	-- Fling them toward town.
	local away = flatten(root.Position - guardian.position)
	local direction = (Vector3.new(1, 0, 0) + (if away.Magnitude > 0.1 then away.Unit else Vector3.zero)).Unit
	knockbackRemote:FireClient(player, direction + Vector3.new(0, 0.9, 0), 95, 0.35)
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
		-- Wander round the pile.
		if now >= guardian.wanderAt then
			guardian.wanderAt = now + rng:NextNumber(2.5, 5)
			local a = rng:NextNumber() * math.pi * 2
			guardian.wanderTo = guardian.home + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(0, 9)
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
		pile.Name = "Pile"
		pile.Parent = folder
		local zone = { pedestals = {}, guardian = newGuardian(index) }
		zones[index] = zone
		for n = 1, ZoneLayout.PEDESTALS do
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
