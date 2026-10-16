-- Runs the Freek cannons (see shared/Drops.luau): builds the glass bubble over the map,
-- the eight cannons hanging on it and the Freek House, fires a random Freek from each
-- cannon in turn, and lets players grab them (first come, first served) while they wander
-- around the town square.
--
-- Every species from Common to Ultra can come out (fusing never raises rarity, so cannons
-- are how players move up). Secrets never do. Limited Freeks only during their event.
--
-- Clients fly and walk the Freeks themselves (smooth, no network traffic); the server works
-- out where each one is from its seed and launch time when checking a grab.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Drops = require(ReplicatedStorage.Shared.Drops)
local Events = require(ReplicatedStorage.Shared.Events)
local Format = require(ReplicatedStorage.Shared.Format)
local FreekModel = require(ReplicatedStorage.Shared.FreekModel)
local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local Freeks = require(ReplicatedStorage.Shared.Freeks)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Seasons = require(ReplicatedStorage.Shared.Seasons)

local ActionService = require(script.Parent.ActionService)
local Decor = require(script.Parent.Decor)
local FreekTag = require(script.Parent.FreekTag)
local PlotService = require(script.Parent.PlotService)
local StealService = require(script.Parent.StealService)

local CannonService = {}

local notifyRemote = Remotes.get("Notify")
local rng = Random.new()
local folder: Folder
local cannons = {} -- [index] = cannon Model
local items = {} -- [id] = { species, mutations, price, path, model }
local nextId = 0

local function notify(player: Player, message: string, kind: string?)
	notifyRemote:FireClient(player, message, kind)
end

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

-- The bubble: a giant soap bubble over the town. Thin glass panels shimmer through soft
-- rainbow colours (with two bright glare streaks, like light on a real bubble), held by a
-- chunky white frame of rings and ribs. A lit rim runs round its foot and a glowing crown
-- sits on top.
local function buildDome(model: Model)
	local radius = Drops.DOME_RADIUS
	local rings, around = 12, 48
	local step = (math.pi / 2) / rings
	local slice = math.pi * 2 / around
	local frame = Color3.fromRGB(250, 250, 255)
	local gold = Color3.fromRGB(255, 200, 60)
	local function glass(props)
		props.CastShadow = false
		props.CanCollide = false
		props.CanQuery = false
		props.CanTouch = false
		props.Parent = model
		return part(props)
	end
	-- Two glare streaks: bands of panels on the sunny side, brighter and whiter.
	local function glare(angle: number, ring: number): number
		local best = 0
		for _, streak in { { 2.3, 6, 0.10 }, { 2.75, 8, 0.05 } } do
			local d = math.abs((angle - streak[1] + math.pi) % (math.pi * 2) - math.pi)
			local along = math.abs(ring - streak[2]) / 3
			if d < streak[3] * 2 and along < 1 then
				best = math.max(best, (1 - d / (streak[3] * 2)) * (1 - along))
			end
		end
		return best
	end
	for ring = 0, rings - 1 do
		local low, high = ring * step, (ring + 1) * step
		local middle = (low + high) / 2
		for i = 0, around - 1 do
			-- Each panel is a flat quad between four points on the bubble.
			local a0, a1 = i * slice, (i + 1) * slice
			local angle = (i + 0.5) * slice
			local bottom = (Drops.domePoint(a0, low) + Drops.domePoint(a1, low)) / 2
			local topEdge = (Drops.domePoint(a0, high) + Drops.domePoint(a1, high)) / 2
			local width = (Drops.domePoint(a1, middle) - Drops.domePoint(a0, middle)).Magnitude
			local center = (bottom + topEdge) / 2
			local up = (topEdge - bottom).Unit
			local right = Vector3.new(-math.sin(angle), 0, math.cos(angle))
			-- Soap-bubble colours swirl round and up: cyan, violet, pink, gold, mint.
			local hue = (0.5 + 0.18 * math.sin(angle * 2 + ring * 0.45) + ring * 0.025) % 1
			local tint = Color3.fromHSV(hue, 0.32, 1)
			local shine = glare(angle, ring)
			glass({
				Name = "Bubble",
				Size = Vector3.new(width, (topEdge - bottom).Magnitude, 0.4),
				CFrame = CFrame.fromMatrix(center, right, up),
				Color = tint:Lerp(Color3.new(1, 1, 1), shine),
				Material = Enum.Material.Glass,
				Transparency = 0.88 - shine * 0.3,
			})
		end
		-- A frame ring along the bottom edge of each band.
		local thick = if ring == 0 then 1.4 else 0.6
		for i = 0, around - 1 do
			local p0 = Drops.domePoint(i * slice, low)
			local p1 = Drops.domePoint((i + 1) * slice, low)
			glass({
				Name = "BubbleFrame",
				Size = Vector3.new(thick, thick, (p1 - p0).Magnitude + thick),
				CFrame = CFrame.lookAt((p0 + p1) / 2, p1),
				Color = frame,
				Material = Enum.Material.SmoothPlastic,
				Transparency = 0.15,
			})
		end
		-- Ribs up the bubble every few panels, with gold rivets where they cross the rings.
		for i = 0, around - 1, 4 do
			local a = i * slice
			local p0 = Drops.domePoint(a, low)
			local p1 = Drops.domePoint(a, high)
			glass({
				Name = "BubbleFrame",
				Size = Vector3.new(0.9, 0.9, (p1 - p0).Magnitude + 0.9),
				CFrame = CFrame.lookAt((p0 + p1) / 2, p1),
				Color = frame,
				Material = Enum.Material.SmoothPlastic,
				Transparency = 0.15,
			})
			if ring > 0 then
				glass({
					Name = "BubbleRivet",
					Shape = Enum.PartType.Ball,
					Size = Vector3.one * 2,
					CFrame = CFrame.new(p0),
					Color = gold,
					Material = Enum.Material.Foil,
				})
			end
		end
	end

	-- The rim round the foot: a chunky white-and-gold ring with coloured bulbs.
	local bulbColors = {
		Color3.fromRGB(255, 120, 200),
		Color3.fromRGB(120, 220, 255),
		Color3.fromRGB(255, 220, 90),
		Color3.fromRGB(150, 255, 150),
	}
	local rimSegments = 64
	for i = 0, rimSegments - 1 do
		local a0, a1 = i / rimSegments * math.pi * 2, (i + 1) / rimSegments * math.pi * 2
		local p0 = Vector3.new(math.cos(a0) * radius, 1.6, math.sin(a0) * radius)
		local p1 = Vector3.new(math.cos(a1) * radius, 1.6, math.sin(a1) * radius)
		local length = (p1 - p0).Magnitude
		glass({
			Name = "BubbleRim",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(length + 1, 3.6, 3.6),
			CFrame = CFrame.lookAt((p0 + p1) / 2, p1) * CFrame.Angles(0, math.pi / 2, 0),
			Color = if i % 2 == 0 then frame else gold,
			Material = if i % 2 == 0 then Enum.Material.SmoothPlastic else Enum.Material.Foil,
			Transparency = 0,
		})
		local bulb = glass({
			Name = "RimBulb",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 1.6,
			CFrame = CFrame.new(Vector3.new(math.cos(a0) * (radius - 1.6), 3.2, math.sin(a0) * (radius - 1.6))),
			Color = bulbColors[i % #bulbColors + 1],
			Material = Enum.Material.Neon,
			Transparency = 0,
		})
		bulb:SetAttribute("BulbIndex", i)
	end

	-- The crown on top: a gold ring holding a big glowing star-orb.
	local apex = Vector3.new(0, radius * Drops.DOME_HEIGHT, 0)
	local capWidth = 2 * radius * math.cos(math.pi / 2 - step) + 0.5
	glass({
		Name = "Bubble",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, capWidth, capWidth),
		CFrame = CFrame.new(apex) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(240, 200, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.88,
	})
	glass({
		Name = "Crown",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(3, 22, 22),
		CFrame = CFrame.new(apex + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = gold,
		Material = Enum.Material.Foil,
		Transparency = 0,
	})
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		glass({
			Name = "Crown",
			Size = Vector3.new(2.4, 7, 2.4),
			CFrame = CFrame.new(apex + Vector3.new(math.cos(a) * 9.5, 5.5, math.sin(a) * 9.5))
				* CFrame.Angles(0, -a, 0)
				* CFrame.Angles(0, math.pi / 4, 0),
			Color = gold,
			Material = Enum.Material.Foil,
			Transparency = 0,
		})
		glass({
			Name = "CrownGem",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 2.2,
			CFrame = CFrame.new(apex + Vector3.new(math.cos(a) * 9.5, 9.5, math.sin(a) * 9.5)),
			Color = bulbColors[k % #bulbColors + 1],
			Material = Enum.Material.Neon,
			Transparency = 0,
		})
	end
	local orb = glass({
		Name = "CrownOrb",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 10,
		CFrame = CFrame.new(apex + Vector3.new(0, 8, 0)),
		Color = Color3.fromRGB(255, 240, 160),
		Material = Enum.Material.Neon,
		Transparency = 0,
	})
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = Color3.fromRGB(255, 240, 180)
	sparkles.Parent = orb
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 230, 160)
	glow.Range = 60
	glow.Brightness = 2
	glow.Parent = orb
end

-- Each cannon has its own bright colour (and a number on a badge).
local CANNON_COLORS = {
	Color3.fromRGB(235, 60, 70),
	Color3.fromRGB(255, 140, 40),
	Color3.fromRGB(250, 205, 50),
	Color3.fromRGB(70, 200, 90),
	Color3.fromRGB(40, 190, 230),
	Color3.fromRGB(60, 110, 240),
	Color3.fromRGB(150, 80, 230),
	Color3.fromRGB(240, 90, 180),
}

-- A big chunky cartoon cannon: a bright barrel with gold bands and rivets, a flared muzzle
-- with a glowing rim, a round breech with a lit fuse, held in a gold yoke on a round mount
-- bolted to the bubble, and a number badge on top.
local function buildCannon(parent: Instance, index: number): Model
	local model = Instance.new("Model")
	model.Name = "Cannon" .. index
	local aim = Drops.cannonCFrame(index)
	local S = Drops.CANNON_SCALE
	-- The cannon hangs just inside the bubble; at() places a point in its own studs.
	local base = Drops.cannonBase(index)
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x * S, y * S, z * S)
	end
	local color = CANNON_COLORS[(index - 1) % #CANNON_COLORS + 1]
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.35)
	local gold = Color3.fromRGB(255, 200, 55)
	local outline = Color3.fromRGB(20, 22, 48)
	-- Cylinders run along their X axis; turn them to point down the barrel (-Z).
	local along = CFrame.Angles(0, math.pi / 2, 0)
	local function add(props)
		props.Material = props.Material or Enum.Material.SmoothPlastic
		props.Parent = model
		return part(props)
	end
	local function ring(z: number, diameter: number, length: number, ringColor: Color3, material)
		return add({
			Name = "Band",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(length, diameter, diameter) * S,
			CFrame = at(0, 0, z) * along,
			Color = ringColor,
			Material = material or Enum.Material.SmoothPlastic,
		})
	end
	-- The barrel tapers a little toward the muzzle: two lengths, the back one fatter.
	local barrel = add({
		Name = "Barrel",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(11, 7.4, 7.4) * S,
		CFrame = at(0, 0, 1.5) * along,
		Color = color,
	})
	model.PrimaryPart = barrel
	add({
		Name = "BarrelFront",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(11, 6.6, 6.6) * S,
		CFrame = at(0, 0, -8.5) * along,
		Color = color,
	})
	-- A white stripe for a toy-like look.
	ring(-5.5, 6.75, 1.2, Color3.fromRGB(255, 255, 255))
	-- Gold bands with rivets.
	for _, band in { { 6.5, 7.9 }, { -3, 7.9 }, { -13, 7.1 } } do
		ring(band[1], band[2], 1.4, gold, Enum.Material.Foil)
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			add({
				Name = "Rivet",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * 0.6 * S,
				CFrame = at(math.cos(a) * band[2] / 2, math.sin(a) * band[2] / 2, band[1]),
				Color = gold:Lerp(Color3.new(1, 1, 1), 0.3),
				Material = Enum.Material.Foil,
			})
		end
	end
	-- Flared muzzle: three rings, a dark bore and a glowing rim.
	ring(-14.6, 8.2, 1.4, dark)
	ring(-15.6, 9.4, 1, gold, Enum.Material.Foil)
	add({
		Name = "Muzzle",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 5.2, 5.2) * S,
		CFrame = at(0, 0, -16.15) * along,
		Color = Color3.fromRGB(10, 10, 16),
	})
	add({
		Name = "MuzzleGlow",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.25, 7.2, 7.2) * S,
		CFrame = at(0, 0, -16.1) * along,
		Color = color:Lerp(Color3.new(1, 1, 1), 0.45),
		Material = Enum.Material.Neon,
	})
	-- Round breech with a knob, and a fuse with a spark.
	add({
		Name = "Breech",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 8 * S,
		CFrame = at(0, 0, 7),
		Color = dark,
	})
	add({
		Name = "Knob",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 2.6 * S,
		CFrame = at(0, 0, 11.2),
		Color = gold,
		Material = Enum.Material.Foil,
	})
	add({
		Name = "Fuse",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.2, 0.45, 0.45) * S,
		CFrame = at(0, 4.6, 5.5) * CFrame.Angles(0, 0, math.pi / 2) * CFrame.Angles(0, 0, 0.3),
		Color = Color3.fromRGB(90, 70, 50),
	})
	local spark = add({
		Name = "FuseSpark",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 0.8 * S,
		CFrame = at(0, 5.7, 5.2),
		Color = Color3.fromRGB(255, 200, 80),
		Material = Enum.Material.Neon,
	})
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = Color3.fromRGB(255, 190, 80)
	sparkles.Parent = spark
	-- The number badge underneath (where players below can see it): a gold disc with a
	-- white face and the number.
	add({
		Name = "Badge",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 5.2, 5.2) * S,
		CFrame = at(0, -3.9, 1.5) * CFrame.Angles(0, 0, math.pi / 2),
		Color = gold,
		Material = Enum.Material.Foil,
	})
	local face = add({
		Name = "BadgeFace",
		Size = Vector3.new(4, 0.2, 4) * S,
		CFrame = at(0, -4.25, 1.5),
		Color = Color3.fromRGB(255, 255, 255),
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Bottom
	gui.CanvasSize = Vector2.new(100, 100)
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = tostring(index)
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.TextColor3 = color
	label.Rotation = 180
	local stroke = Instance.new("UIStroke")
	stroke.Color = outline
	stroke.Thickness = 4
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = face

	-- The gold yoke: two arms from the breech back to the bubble, holding pins on the
	-- barrel's sides; and a big round mount plate on the bubble with a coloured middle.
	local wall = aim.Position
	for _, side in { -1, 1 } do
		local pin = at(side * 4.4, 0, 3).Position
		local foot = wall + aim.RightVector * side * 4.4 * S
		local length = (pin - foot).Magnitude
		add({
			Name = "Yoke",
			Size = Vector3.new(1.6 * S, 2.6 * S, length),
			CFrame = CFrame.lookAt(foot, pin) * CFrame.new(0, 0, -length / 2),
			Color = gold,
			Material = Enum.Material.Foil,
		})
		add({
			Name = "Pin",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.6, 3, 3) * S,
			CFrame = CFrame.new(pin) * base.Rotation,
			Color = dark,
		})
	end
	local back = at(0, 0, 11).Position
	local length = (wall - back).Magnitude
	add({
		Name = "Bracket",
		Size = Vector3.new(3 * S, 3 * S, length + 1),
		CFrame = CFrame.lookAt(back, wall) * CFrame.new(0, 0, -length / 2),
		Color = gold,
		Material = Enum.Material.Foil,
	})
	add({
		Name = "Plate",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.4, 14 * S, 14 * S),
		CFrame = CFrame.lookAt(wall, wall + Drops.domeNormal(wall)) * along,
		Color = gold,
		Material = Enum.Material.Foil,
	})
	add({
		Name = "PlateMiddle",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.6, 10 * S, 10 * S),
		CFrame = CFrame.lookAt(wall, wall + Drops.domeNormal(wall)) * along,
		Color = color,
	})
	model.Parent = parent
	return model
end

-- The Freek House at the west end, with a glowing doorway Freeks walk into.
local function buildHouse(model: Model)
	local base = CFrame.new(Drops.HOUSE_POSITION) * CFrame.Angles(0, -math.pi / 2, 0) -- front faces +X
	local wall = Color3.fromRGB(150, 80, 220)
	local roofColor = Color3.fromRGB(90, 40, 150)
	part({
		Name = "FreekHouse",
		Size = Vector3.new(20, 16, 16),
		CFrame = base * CFrame.new(0, 8, 0),
		Color = wall,
		Material = Enum.Material.SmoothPlastic,
		Parent = model,
	})
	for _, side in { -1, 1 } do
		local roof = Instance.new("WedgePart")
		roof.Anchored = true
		roof.Name = "Roof"
		roof.Size = Vector3.new(18, 6, 10.5)
		roof.CFrame = base
			* CFrame.new(side * 5.25, 19, 0)
			* CFrame.Angles(0, if side > 0 then -math.pi / 2 else math.pi / 2, 0)
		roof.Color = roofColor
		roof.Material = Enum.Material.SmoothPlastic
		roof.Parent = model
	end
	part({
		Name = "Doorway",
		Size = Vector3.new(9, 9, 0.4),
		CFrame = base * CFrame.new(0, 4.5, -8.05),
		Color = Color3.fromRGB(255, 220, 120),
		Material = Enum.Material.Neon,
		Parent = model,
	})
	for _, x in { -4.9, 4.9 } do
		part({
			Name = "DoorFrame",
			Size = Vector3.new(0.9, 10, 0.9),
			CFrame = base * CFrame.new(x, 5, -8.2),
			Color = Color3.new(1, 1, 1),
			Parent = model,
		})
	end
	part({
		Name = "DoorFrame",
		Size = Vector3.new(10.7, 0.9, 0.9),
		CFrame = base * CFrame.new(0, 9.6, -8.2),
		Color = Color3.new(1, 1, 1),
		Parent = model,
	})
	for _, x in { -7, 7 } do
		part({
			Name = "Window",
			Size = Vector3.new(3, 3, 0.3),
			CFrame = base * CFrame.new(x, 10, -8.1),
			Color = Color3.fromRGB(255, 225, 140),
			Material = Enum.Material.Neon,
			Parent = model,
		})
	end
	part({
		Name = "Chimney",
		Size = Vector3.new(2.5, 6, 2.5),
		CFrame = base * CFrame.new(5, 22, 3),
		Color = Color3.fromRGB(140, 70, 60),
		Material = Enum.Material.Brick,
		Parent = model,
	})
	Decor.signboard(model, base * CFrame.new(0, 13.4, -8.4), Vector2.new(13, 2.4), "FREEK HOUSE", roofColor)
end

local function priceOf(species, mutations: { string }?): number
	local base = species.price or math.floor(species.income * Drops.PRICE_SECONDS)
	return math.floor(base * Mutations.mult(mutations))
end

-- Species that can come out of a cannon right now, grouped by rarity.
local function eligibleByRarity()
	local groups = {}
	for _, species in Freeks.list do
		if
			Seasons.available(species)
			and species.rarity ~= "Secret"
			and not species.exclusive
			and not species.event
		then
			groups[species.rarity] = groups[species.rarity] or {}
			table.insert(groups[species.rarity], species)
		end
	end
	return groups
end

-- Lucky Skies (see Luck.luau) and big events (Events.luau) make Rare and better more likely.
local function rollRarity(): string
	local boost = Events.boost("rareBoost")
	local function weightOf(entry)
		return if Rarities.rank[entry.rarity] >= Rarities.rank.Rare then entry.weight * boost else entry.weight
	end
	local total = 0
	for _, entry in Drops.ODDS do
		total += weightOf(entry)
	end
	local roll = rng:NextNumber() * total
	for _, entry in Drops.ODDS do
		roll -= weightOf(entry)
		if roll <= 0 then
			return entry.rarity
		end
	end
	return Drops.ODDS[1].rarity
end

-- Cannon Freeks get at most one mutation; stacking them is done by fusing.
local function rollMutations(): { string }?
	local boost = Events.boost("mutationBoost") -- Rainbow Hour, Monster Storm
	for _, mutation in Mutations.list do
		if rng:NextNumber() < mutation.chance * Drops.MUTATION_FACTOR * boost then
			return { mutation.id }
		end
	end
	return nil
end

-- Fires a random Freek (or the given one, from the admin panel) from cannon `cannon`.
local function fire(cannon: number, forcedSpecies: string?, forcedMutations: { string }?)
	local species
	local big = Events.current()
	if forcedSpecies then
		species = Freeks.byId[forcedSpecies]
	elseif big and big.eventFreek and Freeks.byId[big.eventFreek] and rng:NextNumber() < big.eventChance then
		species = Freeks.byId[big.eventFreek] -- the event-only Freek!
	else
		local groups = eligibleByRarity()
		local rarity = rollRarity()
		-- Nothing of that rarity exists yet: fall back down the tiers.
		while not groups[rarity] and Rarities.rank[rarity] > 1 do
			rarity = Rarities.order[Rarities.rank[rarity] - 1]
		end
		local pool = groups[rarity]
		if not pool then
			return
		end
		species = pool[rng:NextInteger(1, #pool)]
	end
	if not species then
		return
	end
	local mutations = if forcedSpecies then forcedMutations else rollMutations()
	local price = priceOf(species, mutations)
	-- A moment of warning so every client has the Freek before it leaves the barrel.
	local launch = Workspace:GetServerTimeNow() + 0.5
	local seed = rng:NextInteger(1, 2 ^ 30)
	local path = Drops.plan(seed, cannon, launch)

	nextId += 1
	local id = tostring(nextId)
	local model, height = FreekModel.build(species.id, mutations)
	model.Name = id
	model:SetAttribute("Seed", seed)
	model:SetAttribute("Cannon", cannon)
	model:SetAttribute("Launch", launch)
	model:PivotTo(CFrame.new(path.muzzle))

	local anchor = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	local freek = { species = species.id, mutations = mutations }
	FreekTag.add(anchor, freek, height - (anchor.Position.Y - path.muzzle.Y) + 1.6, 90, price)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GrabPrompt"
	prompt.ActionText = "Grab " .. Format.money(price)
	prompt.ObjectText = FreekUtil.displayName(freek)
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = Drops.GRAB_DISTANCE - 2
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false -- clients switch it on once it has landed
	prompt:SetAttribute("ItemId", id)
	prompt.Parent = anchor

	model.Parent = folder
	items[id] = { species = species, mutations = mutations, price = price, path = path, model = model }
	-- Clients play the boom and smoke when this changes.
	cannons[cannon]:SetAttribute("FiredAt", launch)

	if Rarities.rank[species.rarity] >= Drops.ANNOUNCE_RANK then
		for _, player in Players:GetPlayers() do
			notify(
				player,
				"A " .. species.rarity .. " " .. FreekUtil.displayName(freek) .. " just got fired!",
				"discovery"
			)
		end
	end
end

local function grab(player: Player, data, id: any)
	local item = typeof(id) == "string" and items[id]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not item or not root then
		return
	end
	-- Checked against where the Freek is by the server's own maths (clients move the
	-- models). A little extra range covers lag.
	local where, doing = Drops.cframeAt(item.path, Workspace:GetServerTimeNow())
	if doing ~= "wandering" and doing ~= "leaving" then
		return
	end
	local flat = (root.Position - where.Position) * Vector3.new(1, 0, 1)
	if flat.Magnitude > Drops.GRAB_DISTANCE + 4 then
		return
	end
	if not PlotService.getPlot(player) then
		return
	end
	if StealService.isCarrying(player) then
		return notify(player, "Your hands are full! Take that Freek home first.", "error")
	end
	if FreekUtil.count(data) >= GamePasses.maxFreeks(player) or not FreekUtil.freeSlot(data) then
		return notify(player, "Your barn is full! Buy more slots or sell a Freek.", "error")
	end
	if data.money < item.price then
		return notify(player, "Not enough money! It costs " .. Format.money(item.price) .. ".", "error")
	end

	items[id] = nil
	item.model:Destroy()
	data.money -= item.price
	local uid = ActionService.giveFreek(player, data, item.species.id, item.mutations)
	local freek = data.freeks[uid]
	local name = FreekUtil.displayName(freek)
	-- It goes in the player's arms; walking into their barn puts it on a pad.
	local slot = freek.slot
	freek.slot = nil
	if StealService.carryHome(player, uid, freek) then
		notify(player, "You grabbed " .. name .. "! Carry it back to your barn.", "success")
	else
		freek.slot = slot
		notify(player, "You got " .. name .. "! It's in your barn.", "success")
	end
end

-- Fires a chosen Freek from a random cannon right away (the admin panel's "admin abuse").
function CannonService.fireNow(speciesId: string, mutations: { string }?)
	fire(rng:NextInteger(1, Drops.CANNON_COUNT), speciesId, mutations)
end

function CannonService.init()
	local world = Instance.new("Model")
	world.Name = "Cannons"
	world.Parent = Workspace
	buildDome(world)
	for index = 1, Drops.CANNON_COUNT do
		cannons[index] = buildCannon(world, index)
	end
	buildHouse(world)

	folder = Instance.new("Folder")
	folder.Name = "DropFreeks"
	folder.Parent = Workspace

	-- Grab prompts are handled on the client (the server never moves these models, so
	-- Roblox's own prompt range check would reject them); the client sends GrabDrop instead.
	ActionService.register("GrabDrop", grab)

	-- The cannons take turns, so one fires every FIRE_INTERVAL / CANNON_COUNT seconds and
	-- each cannon fires every FIRE_INTERVAL.
	task.spawn(function()
		local cannon = 0
		while true do
			cannon = cannon % Drops.CANNON_COUNT + 1
			fire(cannon)
			-- Rapid Fire and big events speed the cannons up.
			task.wait(Drops.FIRE_INTERVAL / Drops.CANNON_COUNT / Events.boost("fireRate"))
		end
	end)

	-- Freeks nobody grabbed go into the Freek House.
	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = Workspace:GetServerTimeNow()
			for id, item in items do
				if now >= item.path.finish then
					item.model:Destroy()
					items[id] = nil
				end
			end
		end
	end)
end

return CannonService
