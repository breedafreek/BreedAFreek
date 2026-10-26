-- Builds the town and gives every player a home: a yard with a fence, a gate, a treadmill
-- and a house (see shared/HouseModel) made of the parts in their save.
--
-- Homes sit in two rows facing the street, four a side. The only way in is the gate (an
-- invisible wall runs round the rest of the yard). The owner locks the gate from the
-- padlock post for GATE_LOCK_SECONDS at a time (longer with the Longer Lock pass) and can
-- always walk through their own gate and walls. While it's open, other players can walk in
-- and pry parts off the house (StealService).

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local HouseModel = require(ReplicatedStorage.Shared.HouseModel)
local HouseUtil = require(ReplicatedStorage.Shared.HouseUtil)
local Parts = require(ReplicatedStorage.Shared.Parts)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Carried = require(script.Parent.Carried)
local DataService = require(script.Parent.DataService)

local PLOT_SIZE = 64
local ROW_SPACING = 70 -- between home centres along the street
local ROW_DISTANCE = 64 -- from the middle of the street to each home's centre
local GATE_HALF = HouseModel.GATE_HALF
local FENCE_Z = HouseModel.FENCE_Z
local TREADMILL_SPOT = CFrame.new(18, 0, -14) -- in plot space

local PlotService = {}
PlotService.PLOT_SIZE = PLOT_SIZE
PlotService.ROW_DISTANCE = ROW_DISTANCE
PlotService.STREET_EAST = 2 * ROW_SPACING + 40 -- where the street ends past the last homes
PlotService.STREET_WEST = -(2 * ROW_SPACING + 40)

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

-- The gate: two chunky posts with a beam and the owner's sign, and a glowing barrier that
-- blocks the gap while the gate is locked.
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
			CFrame = spot * CFrame.new(0, postHeight + 1.8, 0),
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
	part({
		Name = "NameBoardRim",
		Size = Vector3.new(GATE_HALF * 2 - 0.4, 4.2, 0.4),
		CFrame = origin * CFrame.new(0, postHeight + 1.6, FENCE_Z + 0.1),
		Color = OUTLINE,
		Parent = folder,
	})
	local sign = Instance.new("SurfaceGui")
	sign.Face = Enum.NormalId.Front
	sign.CanvasSize = Vector2.new(600, 140)
	sign.LightInfluence = 0
	sign.Parent = board
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(1, 1)
	name.TextScaled = true
	name.Font = Enum.Font.LuckiestGuy
	name.TextColor3 = accent
	name.Text = "EMPTY HOME"
	name.Parent = sign
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE
	stroke.Thickness = 5
	stroke.Parent = name
	plot.signLabel = name

	-- Floating text over the gate: owner, income, lock state.
	local gateGui = part({
		Name = "GateText",
		Size = Vector3.one,
		CFrame = origin * CFrame.new(0, postHeight + 7, FENCE_Z),
		Transparency = 1,
		CanCollide = false,
		Parent = folder,
	})
	local _, income = billboard(gateGui, UDim2.fromScale(14, 2.4), Vector3.new(0, 1.6, 0), 140)
	income.TextColor3 = Color3.fromRGB(110, 235, 140)
	income.Font = Enum.Font.LuckiestGuy
	plot.incomeLabel = income
	local _, gate = billboard(gateGui, UDim2.fromScale(12, 2), Vector3.new(0, -1, 0), 140)
	plot.gateLabel = gate

	-- The barrier across the gap (and the invisible walls round the rest of the yard), in the
	-- home's Gate collision group so the owner walks straight through.
	local barrier = part({
		Name = "GateBarrier",
		Size = Vector3.new(GATE_HALF * 2, postHeight - 1.8, 0.6),
		CFrame = origin * CFrame.new(0, (postHeight - 1.8) / 2, FENCE_Z),
		Color = Color3.fromRGB(255, 60, 80),
		Material = Enum.Material.ForceField,
		Transparency = 1,
		CanCollide = false,
		CollisionGroup = "Gate" .. plot.index,
		Parent = folder,
	})
	plot.barrier = barrier
	local half = PLOT_SIZE / 2
	local wallHeight = 40
	local walls = {
		{ Vector3.new(half - GATE_HALF, wallHeight, 1), Vector3.new(-(GATE_HALF + half) / 2, wallHeight / 2, -half) },
		{ Vector3.new(half - GATE_HALF, wallHeight, 1), Vector3.new((GATE_HALF + half) / 2, wallHeight / 2, -half) },
		{ Vector3.new(1, wallHeight, PLOT_SIZE), Vector3.new(-half, wallHeight / 2, 0) },
		{ Vector3.new(1, wallHeight, PLOT_SIZE), Vector3.new(half, wallHeight / 2, 0) },
		{ Vector3.new(PLOT_SIZE, wallHeight, 1), Vector3.new(0, wallHeight / 2, half) },
	}
	for _, wall in walls do
		part({
			Name = "YardWall",
			Size = wall[1],
			CFrame = origin * CFrame.new(wall[2]),
			Transparency = 1,
			CanQuery = false,
			CollisionGroup = "Gate" .. plot.index,
			Parent = folder,
		})
	end

	-- The padlock post just inside the gate: the only place the owner can lock it from.
	local lockSpot = origin * CFrame.new(GATE_HALF + 3, 0, FENCE_Z + 4)
	local metal = Color3.fromRGB(55, 55, 65)
	part({
		Name = "LockPost",
		Size = Vector3.new(0.8, 3.4, 0.8),
		CFrame = lockSpot * CFrame.new(0, 1.7, 0),
		Color = metal,
		Material = Enum.Material.Metal,
		Parent = folder,
	})
	local lockBody = part({
		Name = "Padlock",
		Size = Vector3.new(1.6, 1.3, 0.6),
		CFrame = lockSpot * CFrame.new(0, 4.05, 0),
		Color = Color3.fromRGB(235, 185, 60),
		Material = Enum.Material.Metal,
		Parent = folder,
	})
	for _, x in { -0.5, 0.5 } do
		part({
			Name = "Shackle",
			Size = Vector3.new(0.22, 0.8, 0.22),
			CFrame = lockSpot * CFrame.new(x, 5.1, 0),
			Color = Color3.fromRGB(200, 200, 210),
			Material = Enum.Material.Metal,
			Parent = folder,
		})
	end
	part({
		Name = "Shackle",
		Size = Vector3.new(1.22, 0.22, 0.22),
		CFrame = lockSpot * CFrame.new(0, 5.5, 0),
		Color = Color3.fromRGB(200, 200, 210),
		Material = Enum.Material.Metal,
		Parent = folder,
	})
	plot.lockLight = part({
		Name = "LockLight",
		Size = Vector3.new(0.5, 0.5, 0.7),
		CFrame = lockSpot * CFrame.new(0, 3.95, 0),
		Color = Color3.fromRGB(255, 70, 70),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = folder,
	})
	local lockPrompt = Instance.new("ProximityPrompt")
	lockPrompt.Name = "LockPrompt"
	lockPrompt.ActionText = "Lock Gate"
	lockPrompt.ObjectText = "Gate"
	lockPrompt.HoldDuration = 0.4
	lockPrompt.MaxActivationDistance = 8
	lockPrompt.RequiresLineOfSight = false
	lockPrompt:SetAttribute("PlotIndex", plot.index)
	lockPrompt.Parent = lockBody
	plot.lockPrompt = lockPrompt
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
		CFrame = spot * CFrame.new(0, 9.5, -2),
		Transparency = 1,
		CanCollide = false,
		Parent = model,
	})
	local _, sign = billboard(signPart, UDim2.fromScale(10, 2.2), Vector3.zero, 70)
	sign.Font = Enum.Font.LuckiestGuy
	sign.Text = "⚡ RUN TO TRAIN SPEED"
	sign.TextColor3 = Color3.fromRGB(255, 225, 80)
	plot.treadmill = { belt = belt, spot = spot }
end

-- The yard: lawn, a stone path from the gate to the porch.
local function buildYard(plot, folder: Instance)
	local origin = plot.origin
	part({
		Name = "Lawn",
		Size = Vector3.new(PLOT_SIZE, 0.4, PLOT_SIZE),
		CFrame = origin * CFrame.new(0, 0.2, 0),
		Color = Color3.fromRGB(120, 200, 95),
		Material = Enum.Material.Grass,
		Parent = folder,
	})
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
	folder.Parent = Workspace:WaitForChild("Plots")

	local plot = {
		index = index,
		origin = origin,
		accent = ACCENTS[(index - 1) % #ACCENTS + 1],
		spawn = origin * CFrame.new(0, 3, FENCE_Z + 7) * CFrame.Angles(0, math.pi, 0),
		folder = folder,
		lockedUntil = math.huge,
		owner = nil,
	}
	buildYard(plot, folder)
	buildGate(plot, folder)
	buildTreadmill(plot, folder)

	local house = Instance.new("Model")
	house.Name = "House"
	house.Parent = folder
	plot.house = house
	local spots = Instance.new("Folder")
	spots.Name = "StealSpots"
	spots.Parent = folder
	plot.stealSpots = spots

	plots[index] = plot
	return plot
end

-- Rebuilds any slot whose part changed. steal = true adds steal prompts (the owner is
-- online); false clears them.
local function updateHouse(plot, layout, owner: Player?)
	for _, slot in Parts.SLOTS do
		local partId = layout[slot.id]
		local current = plot.house:FindFirstChild(slot.id)
		if not current or current:GetAttribute("Part") ~= partId then
			if current then
				current:Destroy()
			end
			local model = HouseModel.slot(slot.id, partId)
			model:PivotTo(plot.origin * model:GetPivot())
			model.Parent = plot.house
		end
		-- The steal prompt on every non-Basic part.
		local spot = plot.stealSpots:FindFirstChild(slot.id)
		local stealable = owner ~= nil and not Parts.isBasic(partId)
		if stealable and not spot then
			spot = part({
				Name = slot.id,
				Size = Vector3.one,
				CFrame = plot.origin * CFrame.new(HouseModel.ANCHORS[slot.id]),
				Transparency = 1,
				CanCollide = false,
				CanQuery = false,
				Parent = plot.stealSpots,
			})
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "StealPrompt"
			prompt.ActionText = "Steal"
			prompt.HoldDuration = Config.STEAL_HOLD_SECONDS
			prompt.MaxActivationDistance = 12
			prompt.RequiresLineOfSight = false
			prompt:SetAttribute("Slot", slot.id)
			prompt.Parent = spot
		elseif not stealable and spot then
			spot:Destroy()
			spot = nil
		end
		if spot then
			local prompt = spot:FindFirstChild("StealPrompt")
			prompt.ObjectText = Parts.byId[partId].name
			prompt:SetAttribute("OwnerUserId", owner and owner.UserId)
		end
	end
end

function PlotService.render(player: Player)
	local plot = plotOf[player]
	local data = DataService.get(player)
	if not plot or not data then
		return
	end
	-- Parts being carried off by a thief show as Basic until they're back (or gone).
	local layout = HouseUtil.layout(data)
	for slotId, uid in data.house do
		if Carried.is(player, uid) then
			layout[slotId] = Parts.basic(slotId)
		end
	end
	updateHouse(plot, layout, player)
	plot.signLabel.Text = string.upper(player.DisplayName) .. "'S HOME"
	local income = HouseUtil.houseIncome(data) * GamePasses.coinMultiplier(player)
	plot.incomeLabel.Text = Format.money(income) .. "/s"
	local gain = Config.treadmillGain(data.treadmill)
		* Config.speedMultiplier(data.rebirths)
		* GamePasses.speedMultiplier(player)
	plot.treadmillLabel.Text = "LV " .. data.treadmill .. "  +" .. Format.number(gain) .. " ⚡/s"
end

local function setGateLock(plot, lockedUntil: number)
	plot.lockedUntil = lockedUntil
	if plot.owner then
		plot.owner:SetAttribute("GateLockedUntil", lockedUntil)
	end
end

local function updateGate(plot)
	local left = plot.lockedUntil - Workspace:GetServerTimeNow()
	local locked = left > 0 and plot.owner ~= nil
	plot.barrier.CanCollide = left > 0
	plot.barrier.Transparency = if locked then 0.35 else 1
	plot.lockLight.Color = if locked then Color3.fromRGB(80, 255, 110) else Color3.fromRGB(255, 70, 70)
	plot.lockPrompt.ActionText = if locked then "Locked " .. Format.time(left) else "Lock Gate"
	if not plot.owner then
		plot.gateLabel.Text = ""
	elseif locked then
		plot.gateLabel.Text = "🔒 LOCKED " .. Format.time(left)
		plot.gateLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
	else
		plot.gateLabel.Text = "🔓 GATE OPEN"
		plot.gateLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	end
end

-- Lets the owner's character pass through their own gate and walls.
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
	setGateLock(plot, math.huge) -- empty homes stay shut
	plot.owner = nil
	updateHouse(plot, {}, nil)
	plot.signLabel.Text = "EMPTY HOME"
	plot.incomeLabel.Text = ""
	plot.treadmillLabel.Text = "TREADMILL"
	updateGate(plot)
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
			-- New arrivals get one free lock so they aren't robbed while loading in.
			setGateLock(plot, Workspace:GetServerTimeNow() + GamePasses.gateLockSeconds(player))
			player.CharacterAdded:Connect(function(character)
				setCollisionGroup(character, "Owner" .. plot.index)
				task.wait(0.1)
				PlotService.sendHome(player)
			end)
			if player.Character then
				setCollisionGroup(player.Character, "Owner" .. plot.index)
			end
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

-- The owner of the home whose yard this position is in (nil if none, or not in a yard).
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

function PlotService.isGateLocked(plot): boolean
	return Workspace:GetServerTimeNow() < plot.lockedUntil
end

-- Returns an error message, or nil if the gate was locked.
function PlotService.lockGate(player: Player): string?
	local plot = plotOf[player]
	if not plot then
		return "You don't have a home."
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
end

return PlotService
