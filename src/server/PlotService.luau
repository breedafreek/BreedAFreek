-- Builds the town and gives every player a home: a big fenced yard with their house (see
-- shared/HouseModel, made of the house parts in their save), a treadmill, a row of nests
-- for the eggs they bring home, garden beds for their plants, spots for their yard items
-- and a lawn their pets roam round.
--
-- Homes sit in two rows facing the street, four a side. Everything shown comes from the
-- save (LifeUtil): render() rebuilds whatever changed. Pets are drawn by each client (PetFX)
-- from the plot's "Pets" attribute, so they can wander smoothly.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local EggModel = require(ReplicatedStorage.Shared.EggModel)
local HouseModel = require(ReplicatedStorage.Shared.HouseModel)
local ItemModel = require(ReplicatedStorage.Shared.ItemModel)
local Items = require(ReplicatedStorage.Shared.Items)
local LifeUtil = require(ReplicatedStorage.Shared.LifeUtil)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Parts = require(ReplicatedStorage.Shared.Parts)
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)
local Decor = require(script.Parent.Decor)

local PLOT_SIZE = 96
local ROW_SPACING = 104 -- between home centres along the street
local ROW_DISTANCE = 80 -- from the middle of the street to each home's centre
local GATE_HALF = HouseModel.GATE_HALF
local FENCE_Z = HouseModel.FENCE_Z
-- In plot space (origin at the yard's centre, the gate at -Z).
local TREADMILL_SPOT = CFrame.new(22, 0, -16)
local NEST_MAX = Items.NESTS + 2 -- with the Extra Nests pass
local NEST_SPOTS = {} -- a row along the front fence, right of the gate
for n = 1, NEST_MAX do
	NEST_SPOTS[n] = Vector3.new(14 + (n - 1) * 6.5, 0, FENCE_Z + 8.5)
end
local BED_SPOTS = {} -- two rows of three, left of the gate
for n = 1, Items.GARDEN_BEDS do
	BED_SPOTS[n] = Vector3.new(-21 - ((n - 1) % 3) * 10, 0, FENCE_Z + 8.5 + ((n - 1) // 3) * 10)
end
local YARD_SPOTS = {
	Vector3.new(38, 0, -16),
	Vector3.new(-37, 0, 14),
	Vector3.new(37, 0, 14),
	Vector3.new(-30, 0, 36),
	Vector3.new(0, 0, 37),
	Vector3.new(30, 0, 36),
}
-- Where pets wander: the front lawn.
local PET_AREA = { min = Vector3.new(-14, 0, FENCE_Z + 12), max = Vector3.new(14, 0, -3) }

local PlotService = {}
PlotService.PLOT_SIZE = PLOT_SIZE
PlotService.ROW_DISTANCE = ROW_DISTANCE
PlotService.NEST_MAX = NEST_MAX
PlotService.PET_AREA = PET_AREA

local plots = {}
local plotOf = {} -- [Player] = plot

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

local function billboard(parent: Instance, size: UDim2, offset: Vector3, maxDistance: number): (BillboardGui, TextLabel)
	local gui = Instance.new("BillboardGui")
	gui.Size = size
	gui.StudsOffset = offset
	gui.MaxDistance = maxDistance
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE
	stroke.Thickness = 3
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	gui.Parent = parent
	return gui, label
end

-- Each home gets its own accent colour for its gate and sign.
local ACCENTS = {
	Color3.fromRGB(255, 110, 170),
	Color3.fromRGB(90, 200, 255),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(150, 110, 255),
	Color3.fromRGB(90, 220, 130),
	Color3.fromRGB(255, 140, 70),
	Color3.fromRGB(80, 230, 220),
	Color3.fromRGB(255, 90, 90),
}

--------------------------------------------------------------------------------
-- Building a home
--------------------------------------------------------------------------------

-- The gate: two chunky posts with a beam and the owner's sign.
local function buildGate(plot, folder: Instance)
	local origin = plot.origin
	local accent = plot.accent
	local postHeight = 12
	for _, side in { -1, 1 } do
		local spot = origin * CFrame.new(side * (GATE_HALF + 1), 0, FENCE_Z)
		part({
			Name = "GatePost",
			Size = Vector3.new(2.4, postHeight, 2.4),
			CFrame = spot * CFrame.new(0, postHeight / 2, 0),
			Color = Color3.fromRGB(250, 248, 240),
			Material = Enum.Material.SmoothPlastic,
			Parent = folder,
		})
		part({
			Name = "GatePostCap",
			Size = Vector3.new(3, 1, 3),
			CFrame = spot * CFrame.new(0, postHeight + 0.5, 0),
			Color = accent,
			Parent = folder,
		})
		local ball = part({
			Name = "GatePostBall",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 2,
			CFrame = spot * CFrame.new(0, postHeight + 2, 0),
			Color = accent,
			Material = Enum.Material.Neon,
			Parent = folder,
		})
		ball.CanCollide = false
	end
	-- The beam with the name board.
	part({
		Name = "GateBeam",
		Size = Vector3.new(GATE_HALF * 2 + 4.8, 1.6, 1.6),
		CFrame = origin * CFrame.new(0, postHeight - 1, FENCE_Z),
		Color = accent,
		Parent = folder,
	})
	local board = part({
		Name = "NameBoard",
		Size = Vector3.new(GATE_HALF * 2 - 1, 3.6, 0.6),
		CFrame = origin * CFrame.new(0, postHeight + 1.6, FENCE_Z),
		Color = Color3.fromRGB(255, 250, 235),
		Parent = folder,
	})
	-- A dark frame round the board (four bars, so nothing overlaps the board's faces).
	local boardW, boardH = GATE_HALF * 2 - 1, 3.6
	for _, bar in
		{
			{ Vector3.new(boardW + 0.8, 0.4, 0.8), Vector3.new(0, boardH / 2 + 0.2, 0) },
			{ Vector3.new(boardW + 0.8, 0.4, 0.8), Vector3.new(0, -boardH / 2 - 0.2, 0) },
			{ Vector3.new(0.4, boardH, 0.8), Vector3.new(boardW / 2 + 0.2, 0, 0) },
			{ Vector3.new(0.4, boardH, 0.8), Vector3.new(-boardW / 2 - 0.2, 0, 0) },
		}
	do
		part({
			Name = "SignFrame",
			Size = bar[1],
			CFrame = origin * CFrame.new(0, postHeight + 1.6, FENCE_Z) * CFrame.new(bar[2]),
			Color = OUTLINE,
			Parent = folder,
		})
	end
	-- The owner's name on both sides: the street side and the yard side.
	plot.signLabels = {}
	for _, faceId in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local sign = Instance.new("SurfaceGui")
		sign.Face = faceId
		sign.CanvasSize = Vector2.new(600, 140)
		sign.LightInfluence = 0
		sign.Parent = board
		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Size = UDim2.fromScale(0.94, 0.9)
		name.Position = UDim2.fromScale(0.03, 0.05)
		name.TextScaled = true
		name.Font = Enum.Font.LuckiestGuy
		name.TextColor3 = accent
		name.Text = "EMPTY HOME"
		name.Parent = sign
		local stroke = Instance.new("UIStroke")
		stroke.Color = OUTLINE
		stroke.Thickness = 5
		stroke.Parent = name
		table.insert(plot.signLabels, name)
	end

	-- Floating text over the gate: what the home earns.
	local gateGui = part({
		Name = "GateText",
		Size = Vector3.one,
		CFrame = origin * CFrame.new(0, postHeight + 7, FENCE_Z),
		Transparency = 1,
		CanCollide = false,
		Parent = folder,
	})
	local _, income = billboard(gateGui, UDim2.fromScale(14, 2.4), Vector3.new(0, 1, 0), 160)
	income.TextColor3 = Color3.fromRGB(110, 235, 140)
	income.Font = Enum.Font.LuckiestGuy
	plot.incomeLabel = income
end

-- The treadmill: run on the belt to train Speed (SpeedService). The belt pushes you back so
-- you stay on it while you run.
local function buildTreadmill(plot, folder: Instance)
	local spot = plot.origin * TREADMILL_SPOT
	local model = Instance.new("Model")
	model.Name = "Treadmill"
	model.Parent = folder
	local frameColor = Color3.fromRGB(60, 62, 75)
	part({
		Name = "Frame",
		Size = Vector3.new(7, 1, 14),
		CFrame = spot * CFrame.new(0, 0.5, 0),
		Color = frameColor,
		Material = Enum.Material.Metal,
		Parent = model,
	})
	local belt = part({
		Name = "Belt",
		Size = Vector3.new(5.6, 0.3, 12),
		CFrame = spot * CFrame.new(0, 1.12, 0.6),
		Color = Color3.fromRGB(30, 30, 36),
		Material = Enum.Material.Rubber,
		Parent = model,
	})
	-- Pushes anyone standing on it back toward the house (they run toward the street).
	belt.AssemblyLinearVelocity = spot:VectorToWorldSpace(Vector3.new(0, 0, 9))
	for _, x in { -3.2, 3.2 } do
		part({
			Name = "Rail",
			Size = Vector3.new(0.6, 0.6, 13),
			CFrame = spot * CFrame.new(x, 1.3, 0.3),
			Color = plot.accent,
			Parent = model,
		})
		-- Handle posts at the front.
		part({
			Name = "HandlePost",
			Size = Vector3.new(0.5, 4.6, 0.5),
			CFrame = spot * CFrame.new(x, 3.3, -5.6),
			Color = frameColor,
			Material = Enum.Material.Metal,
			Parent = model,
		})
	end
	part({
		Name = "Handlebar",
		Size = Vector3.new(6.9, 0.5, 0.5),
		CFrame = spot * CFrame.new(0, 4.6, -5.6),
		Color = plot.accent,
		Parent = model,
	})
	-- The console with a screen showing what you're earning.
	local console = part({
		Name = "Console",
		Size = Vector3.new(5, 2.4, 0.8),
		CFrame = spot * CFrame.new(0, 6.2, -6) * CFrame.Angles(math.rad(20), 0, 0),
		Color = frameColor,
		Material = Enum.Material.Metal,
		Parent = model,
	})
	local screen = part({
		Name = "Screen",
		Size = Vector3.new(4.4, 1.9, 0.2),
		CFrame = console.CFrame * CFrame.new(0, 0, 0.42),
		Color = Color3.fromRGB(20, 30, 50),
		Material = Enum.Material.Neon,
		Parent = model,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(300, 130)
	gui.LightInfluence = 0
	gui.Parent = screen
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.LuckiestGuy
	label.TextColor3 = Color3.fromRGB(110, 235, 255)
	label.Text = "TREADMILL"
	label.Parent = gui
	plot.treadmillLabel = label
	-- A sign over it so new players know what it's for.
	local signPart = part({
		Name = "TreadmillSign",
		Size = Vector3.one,
		CFrame = spot * CFrame.new(0, 9, -2),
		Transparency = 1,
		CanCollide = false,
		Parent = model,
	})
	local _, sign = billboard(signPart, UDim2.fromScale(6.5, 1.4), Vector3.zero, 60)
	sign.Font = Enum.Font.LuckiestGuy
	sign.Text = "⚡ TRAIN SPEED"
	sign.TextColor3 = Color3.fromRGB(255, 225, 80)
	plot.treadmill = { belt = belt, spot = spot }
end

-- The yard: lawn, a stone path from the gate to the porch.
local function buildYard(plot, folder: Instance)
	local origin = plot.origin
	-- A lighter green checkerboard lawn, a little raised off the town baseplate.
	Decor.checkerFloor(
		folder,
		origin * CFrame.new(0, 0.4, 0),
		PLOT_SIZE,
		PLOT_SIZE,
		12,
		Color3.fromRGB(125, 222, 95),
		Color3.fromRGB(105, 205, 82),
		"Lawn"
	)
	local from, to = FENCE_Z + 1, HouseModel.HOUSE_Z - 6
	local count = math.floor((to - from) / 3)
	for i = 0, count do
		part({
			Name = "PathStone",
			Size = Vector3.new(5 + (i % 2) * 0.8, 0.3, 2.4),
			CFrame = origin
				* CFrame.new((i % 2 - 0.5) * 0.6, 0.45, from + i * 3)
				* CFrame.Angles(0, math.rad((i % 3 - 1) * 4), 0),
			Color = Color3.fromRGB(215, 210, 200),
			Material = Enum.Material.Slate,
			CanCollide = false,
			Parent = folder,
		})
	end
end

-- The nests: a straw nest on a little stand for each egg, with floating text showing what's
-- in it and how long it has left, and a Hatch prompt once it's ready (NestService).
local function buildNests(plot, folder: Instance)
	local model = Instance.new("Model")
	model.Name = "Nests"
	model.Parent = folder
	plot.nests = {}
	for n, spot in NEST_SPOTS do
		local cf = plot.origin * CFrame.new(spot)
		local base = part({
			Name = "NestStand",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.4, 5, 5),
			CFrame = cf * CFrame.new(0, 1.1, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Color = plot.accent:Lerp(Color3.new(1, 1, 1), 0.35),
			Parent = model,
		})
		-- A ring of straw bricks.
		for k = 0, 9 do
			local a = k / 10 * math.pi * 2
			part({
				Name = "Straw",
				Size = Vector3.new(1.5, 0.8, 0.9),
				CFrame = cf
					* CFrame.new(math.cos(a) * 1.9, 2.1 + (k % 2) * 0.15, math.sin(a) * 1.9)
					* CFrame.Angles(0, -a + math.pi / 2, math.rad((k % 3 - 1) * 8)),
				Color = if k % 2 == 0 then Color3.fromRGB(230, 185, 90) else Color3.fromRGB(205, 155, 70),
				CanCollide = false,
				Parent = model,
			})
		end
		part({
			Name = "Straw",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4, 3.6, 3.6),
			CFrame = cf * CFrame.new(0, 1.9, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Color = Color3.fromRGB(190, 140, 65),
			CanCollide = false,
			Parent = model,
		})
		-- Narrower than the gap between nests, so neighbouring labels never overlap.
		local gui, title = billboard(base, UDim2.fromScale(5, 2), Vector3.new(0, 5.8, 0), 55)
		title.Size = UDim2.fromScale(1, 0.5)
		title.Font = Enum.Font.LuckiestGuy
		local timer = title:Clone()
		timer.Position = UDim2.fromScale(0, 0.5)
		timer.Font = Enum.Font.FredokaOne
		timer.Parent = gui
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "HatchPrompt"
		prompt.ActionText = "Hatch"
		prompt.ObjectText = "Egg"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Enabled = false
		prompt:SetAttribute("PlotIndex", plot.index)
		prompt:SetAttribute("Nest", n)
		prompt.Parent = base
		plot.nests[n] = {
			spot = cf * CFrame.new(0, 2.05, 0),
			title = title,
			timer = timer,
			prompt = prompt,
			egg = nil,
			key = nil,
		}
	end
end

-- Garden beds (soil in a plank rim) and yard spots (paving squares) where plants and yard
-- items go.
local function buildBeds(plot, folder: Instance)
	local model = Instance.new("Model")
	model.Name = "Garden"
	model.Parent = folder
	plot.beds = {}
	for n, spot in BED_SPOTS do
		local cf = plot.origin * CFrame.new(spot)
		part({
			Name = "Soil",
			Size = Vector3.new(7, 0.8, 7),
			CFrame = cf * CFrame.new(0, 0.6, 0),
			Color = Color3.fromRGB(120, 80, 50),
			Parent = model,
		})
		for k = 0, 3 do
			part({
				Name = "BedRim",
				Size = Vector3.new(8.2, 1.2, 0.6),
				CFrame = cf * CFrame.Angles(0, k * math.pi / 2, 0) * CFrame.new(0, 0.8, 3.8),
				Color = Color3.fromRGB(200, 140, 80),
				Parent = model,
			})
		end
		plot.beds[n] = { spot = cf * CFrame.new(0, 1, 0), model = nil, key = nil }
	end
	plot.spots = {}
	for n, spot in YARD_SPOTS do
		local cf = plot.origin * CFrame.new(spot)
		part({
			Name = "Pad",
			Size = Vector3.new(12, 0.3, 12),
			CFrame = cf * CFrame.new(0, 0.55, 0),
			Color = Color3.fromRGB(235, 230, 220),
			Parent = model,
		})
		for k = 0, 3 do
			part({
				Name = "PadRim",
				Size = Vector3.new(12.6, 0.5, 0.6),
				CFrame = cf * CFrame.Angles(0, k * math.pi / 2, 0) * CFrame.new(0, 0.6, 6),
				Color = plot.accent,
				Parent = model,
			})
		end
		-- Items at the back face the house; the rest face the street.
		local facing = if spot.Z > 30 then CFrame.Angles(0, math.pi, 0) else CFrame.identity
		plot.spots[n] = { spot = cf * CFrame.new(0, 0.7, 0) * facing, model = nil, key = nil }
	end
end

local function buildPlot(index: number)
	-- Homes 1-4 sit north of the street, 5-8 south, in rows along it.
	local perSide = Config.PLOT_COUNT // 2
	local rowSide = if index <= perSide then -1 else 1
	local rowX = ((index - 1) % perSide - (perSide - 1) / 2) * ROW_SPACING
	local center = Vector3.new(rowX, 0, rowSide * ROW_DISTANCE)
	-- Local -Z (the plot's front, with the gate) faces the street.
	local origin = CFrame.lookAt(center, Vector3.new(rowX, 0, 0))

	local folder = Instance.new("Model")
	folder.Name = "Plot" .. index
	folder:SetAttribute("Origin", origin)
	folder:SetAttribute("Size", PLOT_SIZE)
	folder:SetAttribute("PetMin", PET_AREA.min)
	folder:SetAttribute("PetMax", PET_AREA.max)
	folder.Parent = Workspace:WaitForChild("Plots")

	local plot = {
		index = index,
		origin = origin,
		accent = ACCENTS[(index - 1) % #ACCENTS + 1],
		spawn = origin * CFrame.new(0, 3, FENCE_Z + 7) * CFrame.Angles(0, math.pi, 0),
		folder = folder,
		owner = nil,
	}
	buildYard(plot, folder)
	buildGate(plot, folder)
	buildTreadmill(plot, folder)
	buildNests(plot, folder)
	buildBeds(plot, folder)

	local house = Instance.new("Model")
	house.Name = "House"
	house.Parent = folder
	plot.house = house
	local items = Instance.new("Model")
	items.Name = "Items"
	items.Parent = folder
	plot.items = items

	plots[index] = plot
	return plot
end

-- Rebuilds any house slot whose part changed.
local function updateHouse(plot, layout)
	for _, slot in Parts.SLOTS do
		local partId = layout[slot.id] or Parts.basic(slot.id)
		local current = plot.house:FindFirstChild(slot.id)
		if not current or current:GetAttribute("Part") ~= partId then
			if current then
				current:Destroy()
			end
			local model = HouseModel.slot(slot.id, partId)
			model:PivotTo(plot.origin * model:GetPivot())
			model.Parent = plot.house
		end
	end
end

-- Puts the right item model on a bed or yard spot (record = nil for none).
local function updateSpot(plot, spot, record)
	local key = record
		and (
			record.id
			.. ":"
			.. table.concat(Mutations.normalize(record.mutations), ",")
			.. ":"
			.. tostring(record.weight)
		)
	if spot.key == key then
		return
	end
	spot.key = key
	if spot.model then
		spot.model:Destroy()
		spot.model = nil
	end
	if record then
		local model = ItemModel.build(record)
		model:PivotTo(spot.spot)
		model.Parent = plot.items
		spot.model = model
	end
end

-- What a nest shows: "locked", "empty" or its egg.
local function nestState(data, player: Player, n: number)
	if n > LifeUtil.nestCount(GamePasses.extraNests(player)) then
		return "locked", nil
	end
	local egg = data.nests and data.nests[tostring(n)]
	if not egg then
		return "empty", nil
	end
	return "egg", egg
end

-- The floating text over each nest (counts down every half second).
local function updateNestLabels(plot)
	local player = plot.owner
	local data = player and DataService.get(player)
	local now = os.time()
	for n, nest in plot.nests do
		local state, egg = "unowned", nil
		if data then
			state, egg = nestState(data, player, n)
		end
		nest.prompt.Enabled = false
		if state == "unowned" then
			nest.title.Text = ""
			nest.timer.Text = ""
		elseif state == "locked" then
			nest.title.Text = "🔒 LOCKED"
			nest.title.TextColor3 = Color3.fromRGB(190, 190, 205)
			nest.timer.Text = "Extra Nests"
			nest.timer.TextColor3 = Color3.fromRGB(190, 190, 205)
		elseif state == "empty" then
			nest.title.Text = "EMPTY"
			nest.title.TextColor3 = Color3.new(1, 1, 1)
			nest.timer.Text = "Steal an egg!"
			nest.timer.TextColor3 = Color3.fromRGB(255, 215, 60)
		else
			nest.title.Text = string.upper(egg.rarity)
			nest.title.TextColor3 = Rarities.info[egg.rarity].color
			-- The egg grows while it waits: the weight climbs and the egg gets bigger.
			local weight = Items.eggWeightAt(egg, now)
			local scale = Items.weightScale(weight / (egg.baseWeight or weight))
			if nest.egg and nest.eggScale and math.abs(scale / nest.eggScale - 1) > 0.01 then
				Items.scaleModel(nest.egg, scale / nest.eggScale)
				nest.egg:PivotTo(nest.spot)
				nest.eggScale = scale
			end
			local left = egg.endsAt - now
			if left > 0 then
				nest.timer.Text = "⚖ " .. Format.weight(weight) .. " · " .. Format.time(left)
				nest.timer.TextColor3 = Color3.new(1, 1, 1)
			else
				nest.timer.Text = "🐣 " .. Format.weight(weight) .. " READY!"
				nest.timer.TextColor3 = Color3.fromRGB(110, 235, 140)
				nest.prompt.ObjectText = Items.itemEggName(egg.zone, egg.item)
				nest.prompt.Enabled = true
			end
		end
	end
end

local function updateNests(plot, data, player: Player?)
	for n, nest in plot.nests do
		local state, egg = "unowned", nil
		if data and player then
			state, egg = nestState(data, player, n)
		end
		local key = if egg then egg.zone .. ":" .. egg.rarity .. ":" .. egg.endsAt else state
		if nest.key ~= key then
			nest.key = key
			if nest.egg then
				nest.egg:Destroy()
				nest.egg = nil
			end
			if egg then
				local model = EggModel.build(egg.zone, egg.item)
				local weight = Items.eggWeightAt(egg, os.time())
				local scale = Items.weightScale(weight / (egg.baseWeight or weight))
				Items.scaleModel(model, scale)
				ItemModel.addMutationEffect(model, egg.mutations)
				model:PivotTo(nest.spot)
				model.Parent = plot.items
				nest.egg = model
				nest.eggScale = scale
			end
		end
	end
	updateNestLabels(plot)
end

-- The pets out in the yard, for the clients to draw, with their mutation, weight (kg) and
-- how big to draw them: "Pet_Oinkle:Golden:4.21:1.62,Pet_Woofles::0.88:0.93".
local function petList(data): string
	local list = {}
	for _, uid in LifeUtil.pets(data) do
		local record = data.parts[uid]
		table.insert(
			list,
			string.format(
				"%s:%s:%s:%.3f",
				record.id,
				Mutations.top(record.mutations) or "",
				if record.weight then string.format("%.2f", record.weight) else "",
				Items.weightScale(Items.weightFactor(record))
			)
		)
	end
	return table.concat(list, ",")
end

function PlotService.render(player: Player)
	local plot = plotOf[player]
	local data = DataService.get(player)
	if not plot or not data then
		return
	end
	updateHouse(plot, LifeUtil.layout(data))
	for n, bed in plot.beds do
		local uid = data.garden and data.garden[tostring(n)]
		updateSpot(plot, bed, uid and data.parts[uid])
	end
	for n, spot in plot.spots do
		local uid = data.yard and data.yard[tostring(n)]
		updateSpot(plot, spot, uid and data.parts[uid])
	end
	updateNests(plot, data, player)
	plot.folder:SetAttribute("Pets", petList(data))
	for _, label in plot.signLabels do
		label.Text = string.upper(player.DisplayName) .. "'S LIFE"
	end
	local income = LifeUtil.totalIncome(data) * GamePasses.coinMultiplier(player)
	plot.incomeLabel.Text = Format.money(income) .. "/s"
	local gain = Config.treadmillGain(data.treadmill) * GamePasses.speedMultiplier(player)
	plot.treadmillLabel.Text = "LV " .. data.treadmill .. "  +" .. Format.number(gain) .. " ⚡/s"
end

local function clearPlot(plot)
	plot.owner = nil
	updateHouse(plot, {})
	for _, spot in plot.beds do
		updateSpot(plot, spot, nil)
	end
	for _, spot in plot.spots do
		updateSpot(plot, spot, nil)
	end
	updateNests(plot, nil, nil)
	plot.folder:SetAttribute("Pets", "")
	for _, label in plot.signLabels do
		label.Text = "EMPTY HOME"
	end
	plot.incomeLabel.Text = ""
	plot.treadmillLabel.Text = "TREADMILL"
end

function PlotService.sendHome(player: Player)
	local plot = plotOf[player]
	local character = player.Character
	if plot and character then
		character:PivotTo(plot.spawn)
	end
end

local function onPlayerAdded(player: Player)
	for _, plot in plots do
		if not plot.owner then
			plot.owner = player
			plotOf[player] = plot
			player:SetAttribute("Plot", plot.index)
			player.CharacterAdded:Connect(function()
				task.wait(0.1)
				PlotService.sendHome(player)
			end)
			PlotService.sendHome(player)
			PlotService.render(player)
			return
		end
	end
	Remotes.get("Notify"):FireClient(player, "This server is full! Try another server.", "error")
end

-- Every home's origin (gate faces -Z), for scenery that decorates all homes.
function PlotService.origins(): { CFrame }
	local list = {}
	for _, plot in plots do
		table.insert(list, plot.origin)
	end
	return list
end

function PlotService.getPlot(player: Player)
	return plotOf[player]
end

function PlotService.plotByIndex(index: number)
	return plots[index]
end

-- The home whose yard this position is in (nil if none).
function PlotService.plotAt(position: Vector3)
	for _, plot in plots do
		if PlotService.isInside(plot, position) then
			return plot
		end
	end
	return nil
end

-- True if a world position is inside a home's yard.
function PlotService.isInside(plot, position: Vector3): boolean
	local localPos = plot.origin:PointToObjectSpace(position)
	local limit = PLOT_SIZE / 2 - 0.5
	return math.abs(localPos.X) < limit and math.abs(localPos.Z) < limit
end

-- True if a position is standing on the home's treadmill belt.
function PlotService.onTreadmill(plot, position: Vector3): boolean
	local localPos = plot.treadmill.belt.CFrame:PointToObjectSpace(position)
	return math.abs(localPos.X) < 3 and math.abs(localPos.Z) < 6.2 and localPos.Y > -1 and localPos.Y < 6
end

-- Where a slot's part is on the home (for effects).
function PlotService.slotPosition(plot, slotId: string): Vector3
	return (plot.origin * CFrame.new(HouseModel.ANCHORS[slotId])).Position
end

-- Where nest n is (world space, for effects).
function PlotService.nestPosition(plot, n: number): Vector3
	return plot.nests[n].spot.Position
end

-- Looks straight down at a few spots in every yard for anything covering the lawn (a
-- place's own terrain or parts). Terrain is cleared; anything else is reported in Output
-- and on the ReplicatedStorage attribute GroundProblems, so it can be tracked down.
local GROUND_SPOTS = {
	Vector3.new(22, 0, -16),
	Vector3.new(0, 0, -30),
	Vector3.new(-30, 0, -30),
	Vector3.new(30, 0, -38),
	Vector3.new(38, 0, -16),
}
local function checkGround()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = {}
	for _, plot in plots do
		table.insert(exclude, plot.folder)
	end
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(exclude, player.Character)
		end
	end
	params.FilterDescendantsInstances = exclude
	local problems = {}
	for _, plot in plots do
		for _, spot in GROUND_SPOTS do
			local from = plot.origin:PointToWorldSpace(spot + Vector3.new(0, 80, 0))
			local hit = Workspace:Raycast(from, Vector3.new(0, -100, 0), params)
			if hit and hit.Position.Y > 0.5 then
				if hit.Instance:IsA("Terrain") then
					pcall(function()
						Workspace.Terrain:FillBlock(
							plot.origin * CFrame.new(0, 30, 0),
							Vector3.new(PLOT_SIZE + 8, 84, PLOT_SIZE + 8),
							Enum.Material.Air
						)
					end)
					table.insert(problems, "terrain over yard " .. plot.index .. " (cleared)")
				else
					table.insert(
						problems,
						string.format(
							"%s over yard %d at y=%.1f",
							hit.Instance:GetFullName(),
							plot.index,
							hit.Position.Y
						)
					)
				end
				break
			end
		end
	end
	if #problems > 0 then
		warn("[PlotService] Something covers the yards: " .. table.concat(problems, "; "))
	end
	ReplicatedStorage:SetAttribute("GroundProblems", if #problems > 0 then table.concat(problems, "; ") else nil)
end

function PlotService.init()
	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = Workspace
	for i = 1, Config.PLOT_COUNT do
		clearPlot(buildPlot(i))
	end
	-- Once the rest of the map is built.
	for _, delay in { 5, 20 } do
		task.delay(delay, function()
			local ok, err = pcall(checkGround)
			if not ok then
				warn("[PlotService] ground check failed: " .. tostring(err))
			end
		end)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local plot = plotOf[player]
		if plot then
			clearPlot(plot)
		end
		plotOf[player] = nil
	end)

	DataService.onChanged(function(player)
		PlotService.render(player)
	end)

	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, plot in plots do
				if plot.owner then
					local ok, err = pcall(updateNestLabels, plot)
					if not ok then
						warn("[PlotService] " .. tostring(err))
					end
				end
			end
		end
	end)
end

return PlotService
