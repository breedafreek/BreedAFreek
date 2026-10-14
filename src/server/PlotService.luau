-- Builds the map and gives every player a yard. Yards are public so players can walk
-- around and show off. The whole yard is rebuilt whenever its owner's data changes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local FreekModel = require(ReplicatedStorage.Shared.FreekModel)
local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)

local PLOT_SIZE = 64
local RING_RADIUS = 100
local PAD_COLUMNS = 4

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

	part({
		Name = "Ground",
		Size = Vector3.new(400, 2, 400),
		CFrame = CFrame.new(0, -1, 0),
		Color = Color3.fromRGB(100, 190, 90),
		Material = Enum.Material.Grass,
		Parent = map,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 0.5, 0)
	spawn.Color = Color3.fromRGB(255, 220, 120)
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = map

	local post = part({
		Name = "TitleSign",
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(0, 14, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = map,
	})
	local _, title = billboard(post, UDim2.fromScale(40, 8), Vector3.zero, 400)
	title.Text = "BREED A FREEK"
	title.TextColor3 = Color3.fromRGB(255, 230, 90)
end

local function buildPlot(index: number)
	local angle = (index - 1) / Config.PLOT_COUNT * math.pi * 2
	local center = Vector3.new(math.cos(angle) * RING_RADIUS, 0, math.sin(angle) * RING_RADIUS)
	-- Local -Z (the plot's front) faces the middle of the map.
	local origin = CFrame.lookAt(center, Vector3.zero)

	local folder = Instance.new("Model")
	folder.Name = "Plot" .. index
	folder.Parent = Workspace:WaitForChild("Plots")

	part({
		Name = "Base",
		Size = Vector3.new(PLOT_SIZE, 1, PLOT_SIZE),
		CFrame = origin * CFrame.new(0, 0.5, 0),
		Color = Color3.fromRGB(150, 110, 70),
		Material = Enum.Material.Ground,
		Parent = folder,
	})

	local pads = {}
	for i = 1, Config.MAX_SLOTS do
		local column = (i - 1) % PAD_COLUMNS
		local row = (i - 1) // PAD_COLUMNS
		local pad = part({
			Name = "Pad" .. i,
			Size = Vector3.new(9, 0.5, 9),
			CFrame = origin * CFrame.new((column - (PAD_COLUMNS - 1) / 2) * 13, 1.25, 4 + row * 10),
			Material = Enum.Material.SmoothPlastic,
			Parent = folder,
		})
		local lockGui, lockLabel = billboard(pad, UDim2.fromScale(4, 2), Vector3.new(0, 1.5, 0), 60)
		lockLabel.Text = "LOCKED"
		lockLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		pads[i] = { part = pad, lock = lockGui }
	end

	local pen = part({
		Name = "BreedingPen",
		Size = Vector3.new(22, 0.5, 10),
		CFrame = origin * CFrame.new(0, 1.25, -14),
		Color = Color3.fromRGB(255, 150, 200),
		Material = Enum.Material.SmoothPlastic,
		Parent = folder,
	})
	local _, penLabel = billboard(pen, UDim2.fromScale(14, 2.5), Vector3.new(0, 9, 0), 80)

	local signPost = part({
		Name = "Sign",
		Size = Vector3.new(1, 1, 1),
		CFrame = origin * CFrame.new(0, 16, PLOT_SIZE / 2 - 2),
		Transparency = 1,
		CanCollide = false,
		Parent = folder,
	})
	local _, signLabel = billboard(signPost, UDim2.fromScale(30, 5), Vector3.zero, 250)

	local freekFolder = Instance.new("Folder")
	freekFolder.Name = "Freeks"
	freekFolder.Parent = folder

	local plot = {
		index = index,
		origin = origin,
		spawn = origin * CFrame.new(0, 4, -(PLOT_SIZE / 2 - 4)) * CFrame.Angles(0, math.pi, 0),
		pads = pads,
		pen = pen,
		penLabel = penLabel,
		sign = signLabel,
		freeks = freekFolder,
		owner = nil,
	}
	plots[index] = plot
	return plot
end

local function placeFreek(plot, freek, ground: CFrame)
	local model, height = FreekModel.build(freek.species, freek.mutation)
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
	name.TextColor3 = if freek.mutation
		then Mutations.byId[freek.mutation].color
		else Rarities.info[species.rarity].color
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
end

local function updatePenLabel(plot, data)
	local breeding = data and data.breeding
	if not breeding then
		plot.penLabel.Text = "Breeding Pen"
		return
	end
	local left = breeding.endsAt - os.time()
	plot.penLabel.Text = if left > 0 then "Breeding... " .. Format.time(left) else "Baby ready!"
end

function PlotService.render(player: Player)
	local plot = plotOf[player]
	local data = DataService.get(player)
	if not plot or not data then
		return
	end

	plot.freeks:ClearAllChildren()
	plot.sign.Text = player.DisplayName .. "'s Yard"

	for i, pad in plot.pads do
		local unlocked = i <= data.slots
		pad.part.Color = if unlocked then Color3.fromRGB(235, 225, 200) else Color3.fromRGB(90, 90, 90)
		pad.part.Transparency = if unlocked then 0 else 0.5
		pad.lock.Enabled = not unlocked
	end

	for _, freek in data.freeks do
		local pad = freek.slot and plot.pads[freek.slot]
		if pad then
			placeFreek(plot, freek, pad.part.CFrame * CFrame.new(0, 0.25, 0))
		end
	end

	if data.breeding then
		local penTop = plot.pen.CFrame * CFrame.new(0, 0.25, 0)
		local a = data.freeks[data.breeding.a]
		local b = data.freeks[data.breeding.b]
		if a then
			placeFreek(plot, a, penTop * CFrame.new(-5.5, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0))
		end
		if b then
			placeFreek(plot, b, penTop * CFrame.new(5.5, 0, 0) * CFrame.Angles(0, math.pi / 2, 0))
		end
	end
	updatePenLabel(plot, data)
end

local function clearPlot(plot)
	plot.owner = nil
	plot.freeks:ClearAllChildren()
	plot.sign.Text = "Empty Yard"
	plot.penLabel.Text = ""
	for _, pad in plot.pads do
		pad.part.Color = Color3.fromRGB(90, 90, 90)
		pad.part.Transparency = 0.5
		pad.lock.Enabled = false
	end
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
			player.CharacterAdded:Connect(function()
				task.wait(0.1)
				sendHome(player)
			end)
			sendHome(player)
			PlotService.render(player)
			return
		end
	end
	Remotes.get("Notify"):FireClient(player, "This server is full of yards! Try another server.", "error")
end

function PlotService.init()
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
			task.wait(1)
			for player, plot in plotOf do
				local data = DataService.get(player)
				if data and data.breeding then
					updatePenLabel(plot, data)
				end
			end
		end
	end)
end

return PlotService
