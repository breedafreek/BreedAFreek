-- Builds the map and gives every player a fenced yard. Other players can walk in to look
-- (or steal, see StealService) only while the gate is open. The owner locks the gate for
-- GATE_LOCK_SECONDS at a time (longer with the Longer Lock pass) and can always walk through
-- their own gate.
-- The whole yard is rebuilt whenever its owner's data changes.

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local GateTiers = require(ReplicatedStorage.Shared.GateTiers)
local FreekModel = require(ReplicatedStorage.Shared.FreekModel)
local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)
local Decor = require(script.Parent.Decor)

local PLOT_SIZE = 64
local ROW_SPACING = 70 -- between yard centres along the conveyor
local ROW_DISTANCE = 64 -- from the conveyor's centre line to each yard's centre
local PAD_COLUMNS = 5
local FENCE_HEIGHT = 4 -- what you see
local WALL_HEIGHT = 16 -- invisible wall above the fence so nobody can jump it
local GATE_WIDTH = 14

local PlotService = {}

local plots = {}
local plotOf = {} -- [Player] = plot

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
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	gui.Parent = parent
	return gui, label
end

local function buildMap()
	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = Workspace

	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(140, 0.5, 0) -- past the east end of the conveyor
	spawn.Color = Color3.fromRGB(255, 220, 120)
	spawn.Material = Enum.Material.Marble
	spawn.TopSurface = Enum.SurfaceType.Smooth
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy() -- drop the default spawn logo
	end
	spawn.Parent = map

	local post = part({
		Name = "TitleSign",
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(0, 22, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = map,
	})
	local _, title = billboard(post, UDim2.fromScale(40, 8), Vector3.zero, 400)
	title.Text = "BREED A FREEK"
	title.TextColor3 = Color3.fromRGB(255, 230, 90)
end

-- Each yard gets its own accent colour for pedestal rims and its sign trim.
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

local function setSign(plot, text: string)
	plot.signText = text
	for _, label in plot.signLabels do
		label.Text = text
	end
end

-- Optional extra decoration for every gate arch (set by SeasonalService during events).
-- Called as decorator(archFolder, info) with info = { origin, half, innerX, beamBottom, front }.
local archDecorator = nil

-- (Re)builds a yard's gate arch for a tier from GateTiers: posts, beam, name sign, and for
-- higher tiers finials, a crest and glowing gems.
local function buildArch(plot, tierIndex: number)
	local tier = GateTiers.list[tierIndex]
	if plot.archFolder then
		plot.archFolder:Destroy()
	end
	local arch = Instance.new("Model")
	arch.Name = "GateArch"
	arch.Parent = plot.freeks.Parent
	plot.archFolder = arch
	plot.archTier = tierIndex

	local origin, half = plot.origin, plot.half
	local w = tier.postWidth
	local postX = GATE_WIDTH / 2 + w / 2
	local material = Enum.Material[tier.material]
	local top = 1 + tier.height -- top of the posts
	for _, side in { -1, 1 } do
		part({
			Name = "GatePost",
			Size = Vector3.new(w, tier.height, w),
			CFrame = origin * CFrame.new(side * postX, 1 + tier.height / 2, -half),
			Color = tier.color,
			Material = material,
			Parent = arch,
		})
		-- A wider base and cap on each post.
		part({
			Name = "PostBase",
			Size = Vector3.new(w + 0.8, 1, w + 0.8),
			CFrame = origin * CFrame.new(side * postX, 1.5, -half),
			Color = tier.color,
			Material = material,
			Parent = arch,
		})
		part({
			Name = "PostCap",
			Size = Vector3.new(w + 0.6, 0.6, w + 0.6),
			CFrame = origin * CFrame.new(side * postX, top + 0.3, -half),
			Color = plot.accent,
			Parent = arch,
		})
		if tier.finials then
			part({
				Name = "Finial",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * (w * 0.9),
				CFrame = origin * CFrame.new(side * postX, top + 0.6 + w * 0.4, -half),
				Color = tier.color,
				Material = material,
				Parent = arch,
			})
		end
		if tier.gems then
			local gem = part({
				Name = "Gem",
				Size = Vector3.new(1.1, 1.1, 0.4),
				CFrame = origin
					* CFrame.new(side * postX, 1 + tier.height * 0.6, -half - w / 2 - 0.1)
					* CFrame.Angles(0, 0, math.rad(45)),
				Color = plot.accent,
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = arch,
			})
			local sparkle = Instance.new("Sparkles")
			sparkle.SparkleColor = Color3.fromRGB(255, 235, 150)
			sparkle.Parent = gem
		end
	end
	local beamY = top - 0.6
	part({
		Name = "ArchBeam",
		Size = Vector3.new(postX * 2 + w, 1.2, w * 0.85),
		CFrame = origin * CFrame.new(0, beamY, -half),
		Color = tier.color,
		Material = material,
		Parent = arch,
	})
	local signY = beamY + 2.4
	local signWidth = 13 + tierIndex * 1.5
	plot.signLabels = Decor.signboard(
		arch,
		origin * CFrame.new(0, signY, -half),
		Vector2.new(signWidth, 3),
		plot.signText,
		plot.accent
	)
	if tier.crest then
		-- A half-ring of segments arching over the sign.
		local radius = signWidth / 2 + 1
		local segments = 9
		for i = 0, segments - 1 do
			local a0 = math.pi * i / segments
			local a1 = math.pi * (i + 1) / segments
			local p0 = origin * CFrame.new(math.cos(a0) * radius, signY - 1 + math.sin(a0) * radius * 0.45, -half)
			local p1 = origin * CFrame.new(math.cos(a1) * radius, signY - 1 + math.sin(a1) * radius * 0.45, -half)
			local length = (p1.Position - p0.Position).Magnitude
			part({
				Name = "Crest",
				Size = Vector3.new(0.6, 0.6, length + 0.3),
				CFrame = CFrame.lookAt(p0.Position, p1.Position) * CFrame.new(0, 0, -length / 2),
				Color = tier.color,
				Material = material,
				CanCollide = false,
				Parent = arch,
			})
		end
		local jewel = part({
			Name = "CrestJewel",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * (if tier.gems then 1.8 else 1.2),
			CFrame = origin * CFrame.new(0, signY - 1 + radius * 0.45, -half),
			Color = if tier.gems then plot.accent else tier.color,
			Material = if tier.gems then Enum.Material.Neon else material,
			CanCollide = false,
			Parent = arch,
		})
		if tier.gems then
			local sparkle = Instance.new("Sparkles")
			sparkle.SparkleColor = Color3.fromRGB(255, 235, 150)
			sparkle.Parent = jewel
		end
	end

	-- Keep the LOCKED/OPEN timer just above the arch.
	plot.gateGuiPart.CFrame = origin * CFrame.new(0, signY + (if tier.crest then 6 else 4), -half)

	if archDecorator then
		archDecorator(arch, {
			origin = origin,
			half = half,
			innerX = GATE_WIDTH / 2,
			beamBottom = beamY - 0.6,
			front = -half - w / 2 - 0.1,
		})
	end
end

-- Rebuilds every arch, e.g. when a seasonal theme starts or ends.
function PlotService.setArchDecorator(decorator)
	archDecorator = decorator
	for _, plot in plots do
		if plot.archTier > 0 then
			buildArch(plot, plot.archTier)
		end
	end
end

local function buildPlot(index: number)
	-- Yards 1-4 sit north of the conveyor, 5-8 south, in rows along it.
	local perSide = Config.PLOT_COUNT // 2
	local rowSide = if index <= perSide then -1 else 1
	local rowX = ((index - 1) % perSide - (perSide - 1) / 2) * ROW_SPACING
	local center = Vector3.new(rowX, 0, rowSide * ROW_DISTANCE)
	-- Local -Z (the plot's front, with the gate) faces the conveyor.
	local origin = CFrame.lookAt(center, Vector3.new(rowX, 0, 0))
	local accent = ACCENTS[(index - 1) % #ACCENTS + 1]
	local half = PLOT_SIZE / 2 - 0.5

	local folder = Instance.new("Model")
	folder.Name = "Plot" .. index
	folder.Parent = Workspace:WaitForChild("Plots")
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = folder

	-- Lawn, with a cobblestone path from the gate to the pens and across to the pedestals.
	Decor.tag(
		part({
			Name = "Base",
			Size = Vector3.new(PLOT_SIZE, 1, PLOT_SIZE),
			CFrame = origin * CFrame.new(0, 0.5, 0),
			Color = Color3.fromRGB(105, 185, 85),
			Material = Enum.Material.Grass,
			Parent = folder,
		}),
		Decor.TAGS.lawn
	)
	for _, path in
		{
			{ size = Vector3.new(7, 0.2, 12), pos = Vector3.new(0, 1.1, -26) },
			{ size = Vector3.new(58, 0.2, 3.5), pos = Vector3.new(0, 1.1, -6.2) },
			{ size = Vector3.new(4, 0.2, 13), pos = Vector3.new(0, 1.1, -13.5) },
		}
	do
		part({
			Name = "Path",
			Size = path.size,
			CFrame = origin * CFrame.new(path.pos),
			Color = Color3.fromRGB(175, 165, 150),
			Material = Enum.Material.Cobblestone,
			CanCollide = false,
			Parent = decor,
		})
	end

	-- Round stone pedestals with a glowing rim. Freeks stand on top (pad.ground).
	local pads = {}
	for i = 1, Config.MAX_SLOTS + Config.PASS_SLOTS do
		local column = (i - 1) % PAD_COLUMNS
		local row = (i - 1) // PAD_COLUMNS
		local spot = origin * CFrame.new((column - (PAD_COLUMNS - 1) / 2) * 12.2, 1, 4 + row * 10)
		local rim = part({
			Name = "PadRim" .. i,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, 9.4, 9.4),
			CFrame = spot * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Material = Enum.Material.Neon,
			Color = accent,
			Parent = folder,
		})
		local base = part({
			Name = "Pad" .. i,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, 8.6, 8.6),
			CFrame = spot * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Material = Enum.Material.Marble,
			Parent = folder,
		})
		local lockGui, lockLabel = billboard(base, UDim2.fromScale(4, 2), Vector3.new(0, 1.5, 0), 60)
		lockLabel.Text = "🔒"
		lockLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		pads[i] = { ground = spot * CFrame.new(0, 0.6, 0), base = base, rim = rim, lock = lockGui }
	end

	-- Two hay-floored breeding pens with low fences; the second needs the Extra Breeding Pen pass.
	local pens = {}
	for i, x in { -12, 12 } do
		local penSpot = origin * CFrame.new(x, 1, -14)
		local floor = part({
			Name = "BreedingPen" .. i,
			Size = Vector3.new(19, 0.4, 9.5),
			CFrame = penSpot * CFrame.new(0, 0.2, 0),
			Color = Color3.fromRGB(230, 200, 120),
			Material = Enum.Material.Sand,
			Parent = folder,
		})
		local corner = function(dx, dz)
			return (penSpot * CFrame.new(dx, 0, dz)).Position
		end
		Decor.picketFence(decor, corner(-9.7, 4.9), corner(9.7, 4.9), 2.2, Color3.fromRGB(150, 100, 65))
		Decor.picketFence(decor, corner(-9.7, -4.9), corner(-9.7, 4.9), 2.2, Color3.fromRGB(150, 100, 65))
		Decor.picketFence(decor, corner(9.7, -4.9), corner(9.7, 4.9), 2.2, Color3.fromRGB(150, 100, 65))
		local _, label = billboard(floor, UDim2.fromScale(13, 2.3), Vector3.new(0, 9, 0), 80)
		pens[i] = { part = floor, label = label }
	end

	-- White picket fence plus a tall invisible wall, with the gate at the front.
	local function edge(x: number, z: number): Vector3
		return (origin * CFrame.new(x, 1, z)).Position
	end
	local postX = GATE_WIDTH / 2 + 0.6
	Decor.picketFence(decor, edge(-half, half), edge(half, half), FENCE_HEIGHT)
	Decor.picketFence(decor, edge(-half, -half), edge(-half, half), FENCE_HEIGHT)
	Decor.picketFence(decor, edge(half, -half), edge(half, half), FENCE_HEIGHT)
	Decor.picketFence(decor, edge(-half, -half), edge(-postX, -half), FENCE_HEIGHT)
	Decor.picketFence(decor, edge(postX, -half), edge(half, -half), FENCE_HEIGHT)
	local frontSide = (PLOT_SIZE - GATE_WIDTH) / 2
	for _, wall in
		{
			{ size = Vector3.new(PLOT_SIZE, WALL_HEIGHT, 1), x = 0, z = half },
			{ size = Vector3.new(1, WALL_HEIGHT, PLOT_SIZE), x = -half, z = 0 },
			{ size = Vector3.new(1, WALL_HEIGHT, PLOT_SIZE), x = half, z = 0 },
			{ size = Vector3.new(frontSide, WALL_HEIGHT, 1), x = -(GATE_WIDTH / 2 + frontSide / 2), z = -half },
			{ size = Vector3.new(frontSide, WALL_HEIGHT, 1), x = GATE_WIDTH / 2 + frontSide / 2, z = -half },
		}
	do
		part({
			Name = "Wall",
			Size = wall.size,
			CFrame = origin * CFrame.new(wall.x, 1 + WALL_HEIGHT / 2, wall.z),
			Transparency = 1,
			Parent = folder,
		})
	end

	-- The visible force field fills the gate; an invisible part above stops jumping over.
	local gateHeight = 9.5
	local gate = part({
		Name = "Gate",
		Size = Vector3.new(GATE_WIDTH, gateHeight, 1),
		CFrame = origin * CFrame.new(0, 1 + gateHeight / 2, -half),
		Color = Color3.fromRGB(255, 60, 60),
		Material = Enum.Material.ForceField,
		CollisionGroup = "Gate" .. index,
		Parent = folder,
	})
	local gateTop = part({
		Name = "GateTop",
		Size = Vector3.new(GATE_WIDTH, WALL_HEIGHT - gateHeight, 1),
		CFrame = origin * CFrame.new(0, 1 + gateHeight + (WALL_HEIGHT - gateHeight) / 2, -half),
		Transparency = 1,
		CollisionGroup = "Gate" .. index,
		Parent = folder,
	})
	local gateGuiPart = part({
		Name = "GateSign",
		Size = Vector3.new(1, 1, 1),
		CFrame = origin * CFrame.new(0, 18, -half),
		Transparency = 1,
		CanCollide = false,
		Parent = folder,
	})
	local _, gateLabel = billboard(gateGuiPart, UDim2.fromScale(12, 2.5), Vector3.zero, 120)

	-- Scenery: trees and bushes in the front corners, flower beds along the front fence,
	-- lamps by the gate.
	for _, side in { -1, 1 } do
		Decor.tree(decor, origin * CFrame.new(side * 26.5, 1, -26.5), 0.85, index * 10 + side)
		Decor.bush(decor, origin * CFrame.new(side * 27, 1, -14), 1, index * 20 + side)
		Decor.flowerBed(decor, origin * CFrame.new(side * 15.5, 1, -29.3), 11, 2.2, index * 30 + side)
		Decor.lamp(decor, origin * CFrame.new(side * (postX + 2), 1, -27.5))
	end

	local freekFolder = Instance.new("Folder")
	freekFolder.Name = "Freeks"
	freekFolder.Parent = folder

	local plot = {
		index = index,
		origin = origin,
		accent = accent,
		spawn = origin * CFrame.new(0, 4, -(PLOT_SIZE / 2 - 5)) * CFrame.Angles(0, math.pi, 0),
		pads = pads,
		pens = pens,
		signLabels = {},
		signText = "Empty Yard",
		archTier = 0,
		archFolder = nil,
		gateGuiPart = gateGuiPart,
		half = half,
		freeks = freekFolder,
		gate = gate,
		gateTop = gateTop,
		gateLabel = gateLabel,
		lockedUntil = math.huge,
		owner = nil,
	}
	plots[index] = plot
	return plot
end

-- steal = { uid, ownerUserId } for Freeks on pads, so other players get a Steal prompt.
local function placeFreek(plot, freek, ground: CFrame, steal)
	local model, height = FreekModel.build(freek.species, freek.mutations)
	model:PivotTo(ground)
	model.Parent = plot.freeks

	local species = FreekUtil.species(freek)
	local anchor = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not anchor then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(170, 46)
	gui.MaxDistance = 70
	gui.LightInfluence = 0

	local name = Instance.new("TextLabel")
	name.Size = UDim2.fromScale(1, 0.6)
	name.BackgroundTransparency = 1
	name.TextScaled = true
	name.Font = Enum.Font.FredokaOne
	name.Text = FreekUtil.displayName(freek)
	local topMutation = Mutations.top(freek.mutations)
	name.TextColor3 = if topMutation then Mutations.byId[topMutation].color else Rarities.info[species.rarity].color
	name.TextStrokeTransparency = 0.2
	name.Parent = gui

	local income = name:Clone()
	income.Size = UDim2.fromScale(1, 0.4)
	income.Position = UDim2.fromScale(0, 0.6)
	income.Text = Format.money(FreekUtil.income(freek)) .. "/s"
	income.TextColor3 = Color3.fromRGB(140, 255, 140)
	income.Parent = gui

	-- The tag hangs off the body, so measure the offset from the body's center, not the feet.
	gui.StudsOffsetWorldSpace = Vector3.new(0, height - (anchor.Position.Y - ground.Position.Y) + 1, 0)
	gui.Parent = anchor

	if steal then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "StealPrompt"
		prompt.ActionText = "Steal"
		prompt.ObjectText = FreekUtil.displayName(freek)
		prompt.HoldDuration = Config.STEAL_HOLD_SECONDS
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Uid", steal.uid)
		prompt:SetAttribute("OwnerUserId", steal.ownerUserId)
		prompt.Parent = anchor
	end
end

-- Unlocked pedestals are white marble with a glowing rim in the yard's colour.
local function setPadLook(plot, pad, unlocked: boolean)
	pad.base.Color = if unlocked then Color3.fromRGB(235, 232, 225) else Color3.fromRGB(85, 85, 92)
	pad.base.Material = if unlocked then Enum.Material.Marble else Enum.Material.Slate
	pad.rim.Color = if unlocked then plot.accent else Color3.fromRGB(55, 55, 60)
	pad.rim.Material = if unlocked then Enum.Material.Neon else Enum.Material.SmoothPlastic
end

local function updatePenLabels(plot, data)
	local owner = plot.owner
	for i, pen in plot.pens do
		local breeding = data and FreekUtil.pen(data, i)
		local usable = owner ~= nil and i <= GamePasses.penCount(owner)
		pen.part.Color = if usable then Color3.fromRGB(230, 200, 120) else Color3.fromRGB(95, 95, 100)
		pen.part.Material = if usable then Enum.Material.Sand else Enum.Material.Concrete
		if not owner then
			pen.label.Text = ""
		elseif breeding then
			local left = breeding.endsAt - os.time()
			pen.label.Text = if left > 0 then "Breeding... " .. Format.time(left) else "Baby ready!"
		elseif usable then
			pen.label.Text = "Breeding Pen"
		else
			pen.label.Text = "Extra Pen · Store"
		end
	end
end

function PlotService.render(player: Player)
	local plot = plotOf[player]
	local data = DataService.get(player)
	if not plot or not data then
		return
	end

	plot.freeks:ClearAllChildren()
	local tier = GateTiers.forRebirths(data.rebirths)
	if plot.archTier ~= tier then
		buildArch(plot, tier)
	end
	setSign(plot, player.DisplayName .. "'s Yard")

	for i, pad in plot.pads do
		local unlocked = i <= FreekUtil.totalSlots(data)
		setPadLook(plot, pad, unlocked)
		pad.lock.Enabled = not unlocked
	end

	for uid, freek in data.freeks do
		local pad = freek.slot and plot.pads[freek.slot]
		if pad then
			placeFreek(plot, freek, pad.ground, {
				uid = uid,
				ownerUserId = player.UserId,
			})
		end
	end

	for i, pen in plot.pens do
		local breeding = FreekUtil.pen(data, i)
		if breeding then
			local penTop = pen.part.CFrame * CFrame.new(0, 0.2, 0)
			local a = data.freeks[breeding.a]
			local b = data.freeks[breeding.b]
			if a then
				placeFreek(plot, a, penTop * CFrame.new(-5, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0))
			end
			if b then
				placeFreek(plot, b, penTop * CFrame.new(5, 0, 0) * CFrame.Angles(0, math.pi / 2, 0))
			end
		end
	end
	updatePenLabels(plot, data)
end

local function setGateLock(plot, lockedUntil: number)
	plot.lockedUntil = lockedUntil
	if plot.owner then
		plot.owner:SetAttribute("GateLockedUntil", lockedUntil)
	end
end

local function updateGate(plot)
	local left = plot.lockedUntil - Workspace:GetServerTimeNow()
	local locked = left > 0
	plot.gate.CanCollide = locked
	plot.gateTop.CanCollide = locked
	plot.gate.Transparency = if locked then 0.4 else 1
	if not plot.owner then
		plot.gateLabel.Text = ""
	elseif locked then
		plot.gateLabel.Text = "LOCKED " .. Format.time(left)
		plot.gateLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
	else
		plot.gateLabel.Text = "GATE OPEN"
		plot.gateLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	end
end

-- Lets the owner's character pass through their own locked gate.
local function setCollisionGroup(character: Model, group: string)
	local function apply(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = group
		end
	end
	for _, descendant in character:GetDescendants() do
		apply(descendant)
	end
	character.DescendantAdded:Connect(apply)
end

local function clearPlot(plot)
	setGateLock(plot, math.huge) -- empty yards stay shut
	plot.owner = nil
	plot.freeks:ClearAllChildren()
	setSign(plot, "Empty Yard")
	if plot.archTier ~= 1 then
		buildArch(plot, 1)
	end
	updatePenLabels(plot, nil)
	for _, pad in plot.pads do
		setPadLook(plot, pad, false)
		pad.lock.Enabled = false
	end
	updateGate(plot)
end

local function sendHome(player: Player)
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
			-- New arrivals get one free lock so they aren't robbed while loading in.
			setGateLock(plot, Workspace:GetServerTimeNow() + GamePasses.gateLockSeconds(player))
			player.CharacterAdded:Connect(function(character)
				setCollisionGroup(character, "Owner" .. plot.index)
				task.wait(0.1)
				sendHome(player)
			end)
			if player.Character then
				setCollisionGroup(player.Character, "Owner" .. plot.index)
			end
			sendHome(player)
			PlotService.render(player)
			return
		end
	end
	Remotes.get("Notify"):FireClient(player, "This server is full of yards! Try another server.", "error")
end

-- Every yard's origin (gate faces -Z), for scenery that decorates all yards.
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

-- True if a world position is inside a plot's fence.
function PlotService.isInside(plot, position: Vector3): boolean
	local localPos = plot.origin:PointToObjectSpace(position)
	local limit = PLOT_SIZE / 2 - 1
	return math.abs(localPos.X) < limit and math.abs(localPos.Z) < limit
end

function PlotService.isGateLocked(plot): boolean
	return Workspace:GetServerTimeNow() < plot.lockedUntil
end

-- Returns an error message, or nil if the gate was locked.
function PlotService.lockGate(player: Player): string?
	local plot = plotOf[player]
	if not plot then
		return "You don't have a yard."
	end
	if PlotService.isGateLocked(plot) then
		return "Your gate is already locked."
	end
	setGateLock(plot, Workspace:GetServerTimeNow() + GamePasses.gateLockSeconds(player))
	updateGate(plot)
	return nil
end

function PlotService.init()
	for i = 1, Config.PLOT_COUNT do
		PhysicsService:RegisterCollisionGroup("Gate" .. i)
		PhysicsService:RegisterCollisionGroup("Owner" .. i)
		PhysicsService:CollisionGroupSetCollidable("Gate" .. i, "Owner" .. i, false)
	end
	buildMap()
	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = Workspace
	for i = 1, Config.PLOT_COUNT do
		clearPlot(buildPlot(i))
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
			task.wait(0.25)
			for _, plot in plots do
				updateGate(plot)
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			for player, plot in plotOf do
				local data = DataService.get(player)
				if data and (data.breeding or data.breeding2) then
					updatePenLabels(plot, data)
				end
			end
		end
	end)
end

return PlotService
