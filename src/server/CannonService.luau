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
local Format = require(ReplicatedStorage.Shared.Format)
local FreekModel = require(ReplicatedStorage.Shared.FreekModel)
local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local Freeks = require(ReplicatedStorage.Shared.Freeks)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local Luck = require(ReplicatedStorage.Shared.Luck)
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

-- The bubble: rings of thin glass panels (thick enough to be seen from inside), shimmering
-- from blue at the bottom to pink at the top like a soap bubble, held by a fine white frame.
local function buildDome(model: Model)
	local radius = Drops.DOME_RADIUS
	local rings, around = 12, 48
	local step = (math.pi / 2) / rings
	local slice = math.pi * 2 / around
	local frame = Color3.fromRGB(235, 240, 255)
	local function glass(props)
		props.CastShadow = false
		props.CanCollide = false
		props.CanQuery = false
		props.CanTouch = false
		props.Parent = model
		return part(props)
	end
	for ring = 0, rings - 1 do
		local low, high = ring * step, (ring + 1) * step
		local middle = (low + high) / 2
		-- Each panel is a flat chord of the sphere, so neighbours meet edge to edge.
		local height = 2 * radius * math.sin(step / 2)
		local width = 2 * radius * math.cos(middle) * math.sin(slice / 2)
		local tint = Color3.fromRGB(170, 225, 255):Lerp(Color3.fromRGB(240, 190, 255), ring / (rings - 1))
		for i = 0, around - 1 do
			local angle = (i + 0.5) * slice
			local direction =
				Vector3.new(math.cos(angle) * math.cos(middle), math.sin(middle), math.sin(angle) * math.cos(middle))
			local center = direction * radius * math.cos(step / 2)
			glass({
				Name = "Bubble",
				Size = Vector3.new(width, height, 0.4),
				CFrame = CFrame.lookAt(center, center + direction),
				Color = tint,
				Material = Enum.Material.Glass,
				Transparency = 0.9,
			})
		end
		-- A frame ring along the bottom edge of each band.
		local ringRadius = radius * math.cos(low)
		for i = 0, around - 1 do
			local a0, a1 = i * slice, (i + 1) * slice
			local p0 = Vector3.new(math.cos(a0) * ringRadius, radius * math.sin(low), math.sin(a0) * ringRadius)
			local p1 = Vector3.new(math.cos(a1) * ringRadius, radius * math.sin(low), math.sin(a1) * ringRadius)
			glass({
				Name = "BubbleFrame",
				Size = Vector3.new(0.35, 0.35, (p1 - p0).Magnitude),
				CFrame = CFrame.lookAt((p0 + p1) / 2, p1),
				Color = frame,
				Material = Enum.Material.SmoothPlastic,
				Transparency = 0.3,
			})
		end
	end
	glass({
		Name = "Bubble",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 2 * radius * math.sin(step / 2) + 0.5, 2 * radius * math.sin(step / 2) + 0.5),
		CFrame = CFrame.new(0, radius, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(240, 190, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.9,
	})
end

-- A big black cannon with gold bands, bolted to the bubble by a bracket.
local function buildCannon(parent: Instance, index: number): Model
	local model = Instance.new("Model")
	model.Name = "Cannon" .. index
	local aim = Drops.cannonCFrame(index)
	local metal = Color3.fromRGB(40, 40, 48)
	local gold = Color3.fromRGB(255, 196, 55)
	-- Cylinders run along their X axis; turn them to point down the barrel (-Z).
	local along = CFrame.Angles(0, math.pi / 2, 0)
	local barrel = part({
		Name = "Barrel",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(16, 5, 5),
		CFrame = aim * CFrame.new(0, 0, -4) * along,
		Color = metal,
		Material = Enum.Material.Metal,
		Parent = model,
	})
	model.PrimaryPart = barrel
	part({
		Name = "Breech",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 6,
		CFrame = aim * CFrame.new(0, 0, 4),
		Color = metal,
		Material = Enum.Material.Metal,
		Parent = model,
	})
	for _, z in { -11.6, -6, 1 } do
		part({
			Name = "Band",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1, if z < -11 then 6.4 else 5.6, if z < -11 then 6.4 else 5.6),
			CFrame = aim * CFrame.new(0, 0, z) * along,
			Color = gold,
			Material = Enum.Material.Foil,
			Parent = model,
		})
	end
	part({
		Name = "Muzzle",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 3.6, 3.6),
		CFrame = aim * CFrame.new(0, 0, -12.2) * along,
		Color = Color3.fromRGB(10, 10, 12),
		Material = Enum.Material.SmoothPlastic,
		Parent = model,
	})
	-- Bracket back to the bubble wall.
	local wall = aim.Position.Unit * Drops.DOME_RADIUS
	local mount = (aim * CFrame.new(0, 0, 4)).Position
	local length = (wall - mount).Magnitude
	part({
		Name = "Bracket",
		Size = Vector3.new(2.5, 2.5, length),
		CFrame = CFrame.lookAt(mount, wall) * CFrame.new(0, 0, -length / 2),
		Color = gold,
		Material = Enum.Material.Foil,
		Parent = model,
	})
	part({
		Name = "Plate",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 9, 9),
		CFrame = CFrame.lookAt(wall, wall * 2) * along,
		Color = metal,
		Material = Enum.Material.Metal,
		Parent = model,
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
		if Seasons.available(species) and species.rarity ~= "Secret" and not species.exclusive then
			groups[species.rarity] = groups[species.rarity] or {}
			table.insert(groups[species.rarity], species)
		end
	end
	return groups
end

-- Lucky Skies (see Luck.luau) makes Rare and better more likely.
local function rollRarity(): string
	local event = Luck.current()
	local boost = event and event.rareBoost or 1
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
	local event = Luck.current()
	local boost = event and event.mutationBoost or 1 -- Rainbow Hour
	for _, mutation in Mutations.list do
		if rng:NextNumber() < mutation.chance * Drops.MUTATION_FACTOR * boost then
			return { mutation.id }
		end
	end
	return nil
end

local function fire(cannon: number)
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
	local species = pool[rng:NextInteger(1, #pool)]
	local mutations = rollMutations()
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
			local event = Luck.current()
			task.wait(Drops.FIRE_INTERVAL / Drops.CANNON_COUNT / (event and event.fireRate or 1)) -- Rapid Fire
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
