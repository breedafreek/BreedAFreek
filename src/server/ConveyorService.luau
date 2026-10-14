-- Runs the conveyor: two lanes down the middle of the map, each fed by its own Freek House.
-- Spawns a random Freek on each lane every few seconds (odds by rarity, see Belt.luau) and
-- sells them first come, first served.
--
-- Only Commons and species someone has already discovered by breeding can appear, so the
-- belt never hands out a Discovery Book first. Limited Freeks appear only during their event.
--
-- Clients animate the Freeks along the belt themselves (smooth, no network traffic); the
-- server works out where each one is from its spawn time when checking a purchase.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Belt = require(ReplicatedStorage.Shared.Belt)
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
local DataService = require(script.Parent.DataService)
local DiscoveryService = require(script.Parent.DiscoveryService)
local PlotService = require(script.Parent.PlotService)

local ConveyorService = {}

local notifyRemote = Remotes.get("Notify")
local rng = Random.new()
local folder: Folder
local items = {} -- [id] = { species, mutation, price, spawnTime, lane, model }
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

local function sign(parent: BasePart, text: string, offset: Vector3, color: Color3)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(16, 3)
	gui.StudsOffset = offset
	gui.MaxDistance = 300
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	gui.Parent = parent
end

-- A little house with a gabled roof and a glowing doorway the lane comes out of.
local function buildHouse(model: Model, z: number, wallColor: Color3, roofColor: Color3)
	local x = Belt.START_X - 9
	local walls = part({
		Name = "FreekHouse",
		Size = Vector3.new(14, 11, 10),
		CFrame = CFrame.new(x, 5.5, z),
		Color = wallColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = model,
	})
	-- Two wedges meeting at the ridge make the roof.
	for _, side in { -1, 1 } do
		local roof = Instance.new("WedgePart")
		roof.Anchored = true
		roof.Name = "Roof"
		roof.Size = Vector3.new(15, 4, 6)
		roof.CFrame = CFrame.new(x, 13, z + side * 3) * CFrame.Angles(0, if side > 0 then math.pi else 0, 0)
		roof.Color = roofColor
		roof.Material = Enum.Material.SmoothPlastic
		roof.Parent = model
	end
	part({
		Name = "Doorway",
		Size = Vector3.new(0.4, 6, 7.5),
		CFrame = CFrame.new(Belt.START_X - 1.9, 4, z),
		Color = Color3.fromRGB(255, 220, 120),
		Material = Enum.Material.Neon,
		Parent = model,
	})
	sign(walls, "FREEK HOUSE", Vector3.new(0, 12, 0), Color3.fromRGB(255, 230, 120))
end

local function buildBelt()
	local model = Instance.new("Model")
	model.Name = "Conveyor"
	model.Parent = Workspace

	local length = Belt.LENGTH + 6
	local centerX = Belt.START_X + Belt.LENGTH / 2
	for _, z in Belt.LANES do
		part({
			Name = "Belt",
			Size = Vector3.new(length, 1, 9),
			CFrame = CFrame.new(centerX, 0.5, z),
			Color = Color3.fromRGB(55, 55, 65),
			Material = Enum.Material.DiamondPlate,
			Parent = model,
		})
		for _, side in { -1, 1 } do
			part({
				Name = "Rail",
				Size = Vector3.new(length, 1.4, 0.8),
				CFrame = CFrame.new(centerX, 1.2, z + side * 4.9),
				Color = Color3.fromRGB(255, 200, 40),
				Material = Enum.Material.SmoothPlastic,
				Parent = model,
			})
		end
		part({
			Name = "Chute",
			Size = Vector3.new(6, 3, 9.5),
			CFrame = CFrame.new(Belt.START_X + Belt.LENGTH + 5, 1.5, z),
			Color = Color3.fromRGB(30, 30, 35),
			Material = Enum.Material.Metal,
			Parent = model,
		})
	end
	buildHouse(model, Belt.LANES[1], Color3.fromRGB(150, 80, 220), Color3.fromRGB(90, 40, 150))
	buildHouse(model, Belt.LANES[2], Color3.fromRGB(80, 170, 230), Color3.fromRGB(40, 100, 160))

	folder = Instance.new("Folder")
	folder.Name = "BeltFreeks"
	folder.Parent = Workspace
end

local function priceOf(species, mutation: string?): number
	local base = species.price or math.floor(species.income * Belt.PRICE_SECONDS)
	return math.floor(base * Mutations.mult(mutation))
end

-- Species that can come out of the machine right now, grouped by rarity.
local function eligibleByRarity()
	local groups = {}
	for _, species in Freeks.list do
		local allowed = species.price ~= nil or DiscoveryService.isDiscovered(species.id)
		if allowed and Seasons.available(species) then
			groups[species.rarity] = groups[species.rarity] or {}
			table.insert(groups[species.rarity], species)
		end
	end
	return groups
end

local function rollRarity(): string
	local total = 0
	for _, entry in Belt.ODDS do
		total += entry.weight
	end
	local roll = rng:NextNumber() * total
	for _, entry in Belt.ODDS do
		roll -= entry.weight
		if roll <= 0 then
			return entry.rarity
		end
	end
	return Belt.ODDS[1].rarity
end

local function rollMutation(): string?
	for _, mutation in Mutations.list do
		if rng:NextNumber() < mutation.chance * Belt.MUTATION_FACTOR then
			return mutation.id
		end
	end
	return nil
end

local function spawnFreek(lane: number)
	local groups = eligibleByRarity()
	local rarity = rollRarity()
	-- Nothing of that rarity discovered yet: fall back down the tiers.
	while not groups[rarity] and Rarities.rank[rarity] > 1 do
		rarity = Rarities.order[Rarities.rank[rarity] - 1]
	end
	local pool = groups[rarity]
	if not pool then
		return
	end
	local species = pool[rng:NextInteger(1, #pool)]
	local mutation = rollMutation()
	local price = priceOf(species, mutation)
	local spawnTime = Workspace:GetServerTimeNow()

	nextId += 1
	local id = tostring(nextId)
	local model, height = FreekModel.build(species.id, mutation)
	model.Name = id
	model:SetAttribute("SpawnTime", spawnTime)
	model:SetAttribute("Lane", lane)
	model:PivotTo(Belt.cframeAt(lane, spawnTime, spawnTime))

	local anchor = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	local freek = { species = species.id, mutation = mutation }
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(180, 50)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height - (anchor.Position.Y - Belt.Y) + 1.2, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	local name = Instance.new("TextLabel")
	name.Size = UDim2.fromScale(1, 0.55)
	name.BackgroundTransparency = 1
	name.TextScaled = true
	name.Font = Enum.Font.FredokaOne
	name.Text = FreekUtil.displayName(freek)
	name.TextColor3 = if mutation then Mutations.byId[mutation].color else Rarities.info[species.rarity].color
	name.TextStrokeTransparency = 0.2
	name.Parent = gui
	local cost = name:Clone()
	cost.Size = UDim2.fromScale(1, 0.45)
	cost.Position = UDim2.fromScale(0, 0.55)
	cost.Text = Format.money(price) .. "  ·  " .. Format.money(FreekUtil.income(freek)) .. "/s"
	cost.TextColor3 = Color3.fromRGB(140, 255, 140)
	cost.Parent = gui
	gui.Parent = anchor

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy " .. Format.money(price)
	prompt.ObjectText = FreekUtil.displayName(freek)
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = Belt.BUY_DISTANCE - 2
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("ItemId", id)
	prompt.Parent = anchor

	model.Parent = folder
	items[id] = {
		species = species,
		mutation = mutation,
		price = price,
		spawnTime = spawnTime,
		lane = lane,
		model = model,
	}

	if Rarities.rank[species.rarity] >= Belt.ANNOUNCE_RANK then
		for _, player in Players:GetPlayers() do
			notify(
				player,
				"A " .. species.rarity .. " " .. FreekUtil.displayName(freek) .. " is on the belt!",
				"discovery"
			)
		end
	end
end

local function buy(player: Player, id: string)
	local item = items[id]
	local data = DataService.get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not item or not data or not root then
		return
	end
	local now = Workspace:GetServerTimeNow()
	local where = Belt.cframeAt(item.lane, item.spawnTime, now).Position
	if (root.Position - where).Magnitude > Belt.BUY_DISTANCE or Belt.isGone(item.spawnTime, now) then
		return
	end
	if not PlotService.getPlot(player) then
		return
	end
	if FreekUtil.count(data) >= GamePasses.maxFreeks(player) then
		return notify(player, "You have too many Freeks! Sell some first.", "error")
	end
	if data.money < item.price then
		return notify(player, "Not enough money! It costs " .. Format.money(item.price) .. ".", "error")
	end

	items[id] = nil
	item.model:Destroy()
	data.money -= item.price
	local name = FreekUtil.displayName({ species = item.species.id, mutation = item.mutation })
	ActionService.giveFreek(player, data, item.species.id, item.mutation)
	DataService.changed(player)
	notify(player, "You bought " .. name .. "! It's heading to your yard.", "success")
end

function ConveyorService.init()
	buildBelt()

	game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, player)
		local id = prompt.Name == "BuyPrompt" and prompt:GetAttribute("ItemId")
		if typeof(id) == "string" then
			buy(player, id)
		end
	end)

	-- Each lane has its own house; they take turns so a Freek appears every half interval.
	for lane in Belt.LANES do
		task.delay((lane - 1) * Belt.SPAWN_INTERVAL / 2, function()
			while true do
				spawnFreek(lane)
				task.wait(Belt.SPAWN_INTERVAL)
			end
		end)
	end

	-- Freeks nobody bought fall off the end.
	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = Workspace:GetServerTimeNow()
			for id, item in items do
				if Belt.isGone(item.spawnTime, now) then
					item.model:Destroy()
					items[id] = nil
				end
			end
		end
	end)
end

return ConveyorService
