-- The scenery of each zone, after the owner's reference sheet: its ground (each zone has its
-- own colour, which is how you tell zones apart; there are no signs), its walls, a row of
-- props along each wall (mostly the zone's own items) and a big backdrop beyond the low walls
-- (houses, giant flowers, the sea, a pine forest and mountains, a skyline, mansions, giant
-- crystals, UFOs and a ringed planet, floating islands and rainbows).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FreekModel = require(ReplicatedStorage.Shared.FreekModel)
local HouseModel = require(ReplicatedStorage.Shared.HouseModel)
local ItemModel = require(ReplicatedStorage.Shared.ItemModel)
local Items = require(ReplicatedStorage.Shared.Items)
local ZoneLayout = require(ReplicatedStorage.Shared.ZoneLayout)
local Decor = require(script.Parent.Decor)

local ZoneDecor = {}

local M = Enum.Material

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function block(parent, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?, collide: boolean?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = collide == true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or M.SmoothPlastic
	p.Parent = parent
	return p
end

local GOLD_COLOR = rgb(255, 200, 60)

local function wedge(parent, size: Vector3, cframe: CFrame, color: Color3)
	local p = Instance.new("WedgePart")
	p.Anchored = true
	p.CanCollide = false
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = M.SmoothPlastic
	p.Parent = parent
	return p
end

local RAINBOW =
	{ rgb(255, 70, 90), rgb(255, 150, 40), rgb(255, 225, 50), rgb(80, 220, 100), rgb(60, 170, 255), rgb(150, 90, 255) }

--------------------------------------------------------------------------------
-- Building blocks for the scenery
--------------------------------------------------------------------------------

-- One of the game's item models (Items.luau) as scenery, `scale` times its size, standing
-- on `cf` and facing its -Z. It's only decoration: no item attribute, nothing to touch.
local function item(parent, id: string, cf: CFrame, scale: number?)
	local model = ItemModel.buildNormal(id)
	model:SetAttribute("Item", nil)
	model.Name = "Decor_" .. id
	if scale and scale ~= 1 then
		Items.scaleModel(model, scale)
	end
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
		end
	end
	model:PivotTo(cf)
	model.Parent = parent
	return model
end

-- A creature (Freeks.luau) as a statue-still piece of scenery.
local function creature(parent, species: string, cf: CFrame, scale: number)
	local model = FreekModel.build(species)
	Items.scaleModel(model, scale)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
		end
	end
	model:PivotTo(cf)
	model.Parent = parent
	return model
end

-- A whole house (HouseModel) in `style`, its front facing the -Z of `origin`.
local HOUSE_SLOTS = { "Walls", "Roof", "Door", "Windows", "Chimney", "Porch" }
local function house(parent, style: string, origin: CFrame, scale: number)
	local model = Instance.new("Model")
	model.Name = "Decor_House"
	for _, slot in HOUSE_SLOTS do
		local piece = HouseModel.slot(slot, style .. "_" .. slot)
		piece.Parent = model
	end
	-- HouseModel puts the front wall at z = 6; centre it on the origin.
	model.WorldPivot = CFrame.new(0, 0, 16)
	Items.scaleModel(model, scale)
	model:PivotTo(origin)
	model.Parent = parent
	return model
end

-- A mountain of stepped grey slabs with a snowy top.
local function mountain(parent, cf: CFrame, size: number, rock: Color3)
	for i = 0, 4 do
		local s = size * (1 - i * 0.19)
		block(
			parent,
			Vector3.new(s, size * 0.2, s * 0.8),
			cf * CFrame.new(0, size * 0.1 + i * size * 0.2, 0) * CFrame.Angles(0, math.rad(i * 9), 0),
			if i >= 3 then rgb(245, 248, 255) else rock
		)
	end
end

-- A puffy cloud of white blocks, `size` across.
local function cloud(parent, cf: CFrame, size: number)
	for i = 0, 5 do
		local a = i * 1.9
		local s = size * (0.35 + (i % 3) * 0.12)
		block(
			parent,
			Vector3.new(s, s * 0.55, s * 0.8),
			cf * CFrame.new(math.cos(a) * size * 0.3, (i % 2) * size * 0.1, math.sin(a) * size * 0.15),
			rgb(250, 250, 255)
		)
	end
end

-- A rainbow arch of glowing blocks, `radius` tall, standing on `cf` (across its X axis).
local function rainbow(parent, cf: CFrame, radius: number, thickness: number)
	for i, color in RAINBOW do
		local r = radius - (i - 1) * thickness
		for k = 0, 16 do
			local a = k / 16 * math.pi
			local p = block(
				parent,
				Vector3.new(thickness * 1.6, thickness, thickness),
				cf * CFrame.new(math.cos(a) * r, math.sin(a) * r, 0) * CFrame.Angles(0, 0, a),
				color,
				M.Neon
			)
			p.CastShadow = false
		end
	end
end

-- A city building: a tall block with rows of glowing windows and a roof detail.
local function building(parent, cf: CFrame, w: number, h: number, color: Color3, lit: Color3)
	block(parent, Vector3.new(w, h, w), cf * CFrame.new(0, h / 2, 0), color)
	for row = 0, math.floor(h / 5) - 1 do
		local p = block(
			parent,
			Vector3.new(w * 0.86, 1.6, 0.4),
			cf * CFrame.new(0, 3 + row * 5, -w / 2 - 0.1),
			if row % 3 == 1 then rgb(255, 225, 140) else lit,
			M.Neon
		)
		p.CastShadow = false
	end
	block(parent, Vector3.new(w * 0.5, 3, w * 0.5), cf * CFrame.new(0, h + 1.5, 0), color:Lerp(rgb(0, 0, 0), 0.2))
end

-- A planet hanging in the sky: a ball of stacked octagons in bands of `colors`, with an
-- optional glowing ring.
local function planet(parent, cf: CFrame, d: number, colors, ringColor: Color3?)
	local n = 7
	for i = 0, n - 1 do
		local y = (i + 0.5) / n * 2 - 1 -- -1 .. 1
		local w = d * math.sqrt(1 - y * y) + d * 0.08
		local width = w * math.tan(math.pi / 8)
		for k = 0, 3 do
			block(
				parent,
				Vector3.new(w, d / n + 0.05, width),
				cf * CFrame.new(0, y * d / 2, 0) * CFrame.Angles(0, k * math.pi / 4, 0),
				colors[i % #colors + 1]
			)
		end
	end
	if ringColor then
		for k = 0, 23 do
			local a = k / 24 * math.pi * 2
			local p = block(
				parent,
				Vector3.new(d * 0.32, 0.6, d * 0.12),
				cf * CFrame.Angles(0, -a, 0) * CFrame.new(0, 0, d * 0.85),
				ringColor,
				M.Neon
			)
			p.CastShadow = false
		end
	end
end

-- A floating island: a cloud-topped grass slab with a rocky underside.
local function island(parent, cf: CFrame, size: number)
	block(parent, Vector3.new(size, size * 0.12, size * 0.8), cf, rgb(110, 210, 90))
	for i = 0, 2 do
		local s = size * (0.8 - i * 0.25)
		block(
			parent,
			Vector3.new(s, size * 0.14, s * 0.7),
			cf * CFrame.new(0, -size * 0.13 * (i + 1), 0),
			rgb(150, 120, 100):Lerp(rgb(120, 100, 90), i / 2)
		)
	end
	cloud(parent, cf * CFrame.new(-size * 0.4, -size * 0.1, 0), size * 0.5)
end

--------------------------------------------------------------------------------
-- The zones, in order out from town. Each has its ground colour (neighbours differ; the
-- colour change is the border), its walls, a row of props along each wall (often the zone's
-- own items), and a backdrop beyond the low walls that sets the scene.
--
-- props(parent, cf, rng, i): one prop at `cf` (facing the middle of the zone), i counts up.
-- backdrop(parent, east, west, width): scenery outside the walls.
--------------------------------------------------------------------------------

local THEMES = {}

THEMES[1] = { -- The Neighborhood: picket fences, houses behind them, trees and mailboxes
	ground = rgb(90, 210, 90),
	wall = rgb(245, 245, 240),
	trim = rgb(110, 200, 90),
	wallHeight = 5,
	accent = rgb(255, 120, 170),
	props = function(parent, cf, _rng, i)
		local pick = ({ "Plant_AppleTree", "Yard_RedMailbox", "Plant_FlowerPot", "Yard_GardenBench", "Yard_Doghouse" })[i % 5 + 1]
		item(parent, pick, cf, if pick == "Plant_AppleTree" then 1.6 else 1.15)
		if i % 3 == 0 then
			Decor.lamp(parent, cf * CFrame.new(5, 0, 0))
		end
	end,
	backdrop = function(parent, east, west, width)
		local styles = { "Basic", "Log", "Stone", "Candy", "Basic", "Ice" }
		local n = 0
		for _, side in { -1, 1 } do
			for x = east - 22, west + 22, -38 do
				n += 1
				local pos = Vector3.new(x, 0, side * (width / 2 + 26))
				house(parent, styles[n % #styles + 1], CFrame.lookAt(pos, Vector3.new(x, 0, 0)), 0.85)
				Decor.tree(parent, CFrame.new(x - 17, 0, side * (width / 2 + 14)), 1.4, n)
			end
		end
	end,
}

THEMES[2] = { -- The Garden: hedges, giant flowers and veg beyond them, beds along the walls
	ground = rgb(150, 205, 60),
	wall = rgb(60, 150, 60),
	trim = rgb(255, 120, 170),
	wallHeight = 8,
	wallMat = M.Grass,
	accent = rgb(255, 210, 60),
	props = function(parent, cf, _rng, i)
		local pick = ({
			"Plant_RoseBush",
			"Yard_GardenGnome",
			"Plant_StrawberryBush",
			"Plant_FlowerPot",
			"Plant_Cactus",
			"Plant_GiantMushroom",
		})[i % 6 + 1]
		item(parent, pick, cf, 1.3)
		Decor.flowerBed(parent, cf * CFrame.new(5, 0, 0), 3, 2, i)
	end,
	backdrop = function(parent, east, west, width)
		local big = {
			"Plant_GiantSunflower",
			"Plant_GiantPumpkin",
			"Plant_GiantSunflower",
			"Plant_GiantMushroom",
			"Plant_RoseBush",
		}
		local n = 0
		for _, side in { -1, 1 } do
			for x = east - 12, west + 12, -20 do
				n += 1
				local id = big[n % #big + 1]
				local pos = Vector3.new(x + (n % 2) * 6, 0, side * (width / 2 + 14 + (n % 3) * 6))
				item(
					parent,
					id,
					CFrame.lookAt(pos, Vector3.new(pos.X, 0, 0)),
					if id == "Plant_GiantSunflower" then 4.2 else 3.4
				)
			end
		end
	end,
}

THEMES[3] = { -- The Beach: sand, the sea on one side, palms on the other
	ground = rgb(245, 220, 150),
	wall = rgb(230, 200, 130),
	trim = rgb(60, 200, 230),
	wallHeight = 3,
	accent = rgb(60, 200, 230),
	props = function(parent, cf, _rng, i)
		local pick = ({
			"Yard_BeachUmbrella",
			"Plant_PalmTree",
			"Yard_Surfboard",
			"Yard_Lifebuoy",
			"Yard_Sandcastle",
			"Plant_PalmTree",
		})[i % 6 + 1]
		item(parent, pick, cf, if pick == "Plant_PalmTree" then 1.8 else 1.3)
	end,
	backdrop = function(parent, east, west, width)
		local length = east - west
		local center = (east + west) / 2
		-- The sea along the +Z side: a wide band of glowing blue water with surf lines.
		local sea = block(
			parent,
			Vector3.new(length, 1, 120),
			CFrame.new(center, -0.2, width / 2 + 66),
			rgb(40, 150, 220),
			M.Glass
		)
		sea.Transparency = 0.15
		block(parent, Vector3.new(length, 0.4, 14), CFrame.new(center, 0.1, width / 2 + 10), rgb(245, 220, 150))
		for k = 0, 3 do
			local p = block(
				parent,
				Vector3.new(length, 0.15, 0.8),
				CFrame.new(center, 0.35, width / 2 + 18 + k * 12),
				rgb(220, 245, 255),
				M.Neon
			)
			p.CastShadow = false
		end
		item(
			parent,
			"Yard_LuxuryYacht",
			CFrame.new(center - 30, 0, width / 2 + 70) * CFrame.Angles(0, math.rad(70), 0),
			3
		)
		item(parent, "Yard_FlamingoFloat", CFrame.new(center + 25, 0, width / 2 + 34), 2)
		creature(parent, "BeachCrab", CFrame.new(center + 10, 0, width / 2 + 12) * CFrame.Angles(0, math.pi, 0), 1.6)
		-- Palms and beach huts along the -Z side.
		local n = 0
		for x = east - 10, west + 10, -16 do
			n += 1
			local pos = Vector3.new(x, 0, -(width / 2 + 12 + (n % 2) * 8))
			item(parent, "Plant_PalmTree", CFrame.lookAt(pos, Vector3.new(x, 0, 0)), 3.2 + (n % 3) * 0.4)
		end
	end,
}

THEMES[4] = { -- The Wilderness: a pine forest and snowy mountains, a camp along the walls
	ground = rgb(45, 145, 65),
	wall = rgb(110, 75, 45),
	trim = rgb(70, 140, 70),
	wallHeight = 4,
	wallMat = M.Wood,
	accent = rgb(255, 150, 40),
	props = function(parent, cf, _rng, i)
		local pick = ({
			"Plant_PineTree",
			"Yard_CampingTent",
			"Plant_PineTree",
			"Yard_Campfire",
			"Yard_Canoe",
			"Plant_PineTree",
		})[i % 6 + 1]
		item(parent, pick, cf, if pick == "Plant_PineTree" then 1.9 else 1.25)
	end,
	backdrop = function(parent, east, west, width)
		local n = 0
		for _, side in { -1, 1 } do
			for x = east - 6, west + 6, -11 do
				for row = 0, 2 do
					n += 1
					local pos = Vector3.new(x + row * 5, 0, side * (width / 2 + 10 + row * 12))
					item(parent, "Plant_PineTree", CFrame.new(pos) * CFrame.Angles(0, n, 0), 3.2 + ((n * 7) % 5) * 0.35)
				end
			end
			for x = east - 40, west + 30, -70 do
				mountain(parent, CFrame.new(x, 0, side * (width / 2 + 95)), 70, rgb(130, 130, 145))
			end
		end
		item(
			parent,
			"Yard_LogCabin",
			CFrame.lookAt(Vector3.new((east + west) / 2, 0, width / 2 + 14), Vector3.new((east + west) / 2, 0, 0)),
			2.2
		)
		creature(parent, "BabyDeer", CFrame.new(east - 30, 0, -(width / 2 + 12)), 1.8)
	end,
}

THEMES[5] = { -- The Dream Home: a huge purple hall, furniture along the walls, windows
	ground = rgb(205, 170, 235),
	wall = rgb(150, 100, 200),
	trim = rgb(255, 255, 255),
	wallHeight = 30,
	accent = rgb(255, 200, 80),
	props = function(parent, cf, _rng, i)
		local pick = ({
			"Yard_LuxurySofa",
			"Yard_GiantTV",
			"Yard_SmartFridge",
			"Yard_GrandPiano",
			"Yard_VanityMirror",
			"Yard_GamingSetup",
			"Yard_KingBed",
		})[i % 7 + 1]
		item(parent, pick, cf, 1.35)
	end,
	-- Windows and lamps on the inside of the hall's walls.
	wallArt = function(parent, east, west, width)
		for _, side in { -1, 1 } do
			local face = side * (width / 2 - 0.1)
			for x = east - 12, west + 12, -24 do
				block(parent, Vector3.new(10, 14, 0.4), CFrame.new(x, 15, face), rgb(255, 255, 255))
				local glass = block(
					parent,
					Vector3.new(8.6, 12.6, 0.3),
					CFrame.new(x, 15, face - side * 0.15),
					rgb(170, 220, 255),
					M.Neon
				)
				glass.CastShadow = false
				block(parent, Vector3.new(0.5, 12.6, 0.5), CFrame.new(x, 15, face - side * 0.3), rgb(255, 255, 255))
				block(parent, Vector3.new(8.6, 0.5, 0.5), CFrame.new(x, 15, face - side * 0.3), rgb(255, 255, 255))
				block(parent, Vector3.new(11, 1, 1.5), CFrame.new(x, 7.6, face - side * 0.6), rgb(255, 255, 255))
				local lamp = block(
					parent,
					Vector3.new(1.4, 1.4, 1.4),
					CFrame.new(x - 12, 18, face - side * 0.8),
					rgb(255, 230, 160),
					M.Neon
				)
				lamp.CastShadow = false
				block(
					parent,
					Vector3.new(0.5, 2.5, 0.5),
					CFrame.new(x - 12, 16.5, face - side * 0.5),
					GOLD_COLOR,
					M.Metal
				)
			end
		end
	end,
	backdrop = function() end,
}

THEMES[6] = { -- The City: skyscrapers, parked cars, street lamps, neon
	ground = rgb(95, 95, 120),
	wall = rgb(160, 160, 170),
	trim = rgb(255, 220, 40),
	wallHeight = 2,
	accent = rgb(255, 80, 200),
	props = function(parent, cf, _rng, i)
		local pick = ({
			"Yard_YellowTaxi",
			"Yard_VendingMachine",
			"Yard_RedSupercar",
			"Yard_ATM",
			"Yard_ElectricScooter",
			"Yard_YellowTaxi",
		})[i % 6 + 1]
		item(
			parent,
			pick,
			cf * CFrame.Angles(0, if string.find(pick, "car") or string.find(pick, "Taxi") then math.pi / 2 else 0, 0),
			1.25
		)
		if i % 2 == 0 then
			Decor.lamp(parent, cf * CFrame.new(6, 0, 0), rgb(255, 230, 160))
		end
	end,
	backdrop = function(parent, east, west, width)
		local colors = { rgb(70, 90, 150), rgb(60, 70, 110), rgb(90, 100, 140), rgb(110, 80, 150) }
		local lit = { rgb(150, 220, 255), rgb(255, 120, 220), rgb(140, 255, 220) }
		local n = 0
		for _, side in { -1, 1 } do
			-- A sidewalk along the wall, then towers.
			block(
				parent,
				Vector3.new(east - west, 0.6, 8),
				CFrame.new((east + west) / 2, 0.3, side * (width / 2 + 7)),
				rgb(190, 190, 200)
			)
			for x = east - 12, west + 12, -20 do
				n += 1
				local w = 14 + (n % 3) * 3
				local h = 40 + ((n * 37) % 7) * 12
				building(
					parent,
					CFrame.lookAt(Vector3.new(x, 0, side * (width / 2 + 22 + (n % 2) * 6)), Vector3.new(x, 0, 0)),
					w,
					h,
					colors[n % #colors + 1],
					lit[n % #lit + 1]
				)
			end
		end
		item(
			parent,
			"Yard_Helicopter",
			CFrame.new((east + west) / 2, 70, width / 2 + 30) * CFrame.Angles(0, 1.2, 0),
			2.5
		)
	end,
}

THEMES[7] = { -- The Millionaire: marble, gold, palms and mansions
	ground = rgb(245, 230, 190),
	wall = rgb(250, 248, 240),
	trim = rgb(255, 200, 50),
	wallHeight = 4,
	accent = rgb(255, 200, 50),
	props = function(parent, cf, _rng, i)
		local pick = ({
			"Plant_PalmTree",
			"Yard_GoldSupercar",
			"Yard_Diamond",
			"Plant_PalmTree",
			"Yard_GoldenThrone",
			"Yard_DiamondWatch",
		})[i % 6 + 1]
		item(
			parent,
			pick,
			cf * CFrame.Angles(0, if pick == "Yard_GoldSupercar" then math.pi / 2 else 0, 0),
			if pick == "Plant_PalmTree" then 1.8 else 1.3
		)
	end,
	backdrop = function(parent, east, west, width)
		local n = 0
		for _, side in { -1, 1 } do
			for x = east - 25, west + 25, -45 do
				n += 1
				local pos = Vector3.new(x, 0, side * (width / 2 + 30))
				item(parent, "Yard_MansionModel", CFrame.lookAt(pos, Vector3.new(x, 0, 0)), 4)
				item(parent, "Plant_PalmTree", CFrame.new(x - 20, 0, side * (width / 2 + 12)), 3.2)
				item(parent, "Yard_GardenFountain", CFrame.new(x + 20, 0, side * (width / 2 + 14)), 1.6)
			end
		end
		creature(
			parent,
			"WhiteTiger",
			CFrame.lookAt(Vector3.new(east - 20, 0, width / 2 + 12), Vector3.new(east - 20, 0, 0)),
			1.6
		)
	end,
}

THEMES[8] = { -- The Enchanted Life: glowing crystals, giant mushrooms and magic trees
	ground = rgb(175, 90, 210),
	wall = rgb(110, 60, 160),
	trim = rgb(120, 240, 255),
	wallHeight = 4,
	accent = rgb(255, 120, 220),
	props = function(parent, cf, _rng, i)
		local pick = ({
			"Yard_CrystalCluster",
			"Plant_GiantMushroom",
			"Yard_PotionCauldron",
			"Plant_CrystalTree",
			"Yard_MagicWand",
			"Yard_MushroomHouse",
		})[i % 6 + 1]
		item(parent, pick, cf, if pick == "Yard_MushroomHouse" then 1.0 else 1.4)
	end,
	backdrop = function(parent, east, west, width)
		local big = {
			"Plant_CrystalTree",
			"Yard_CrystalCluster",
			"Plant_GiantMushroom",
			"Plant_CrystalTree",
			"Yard_MushroomHouse",
		}
		local n = 0
		for _, side in { -1, 1 } do
			for x = east - 10, west + 10, -18 do
				n += 1
				local id = big[n % #big + 1]
				local pos = Vector3.new(x, 0, side * (width / 2 + 14 + (n % 3) * 8))
				item(
					parent,
					id,
					CFrame.lookAt(pos, Vector3.new(x, 0, 0)),
					if id == "Yard_MushroomHouse" then 2.4 else 4
				)
			end
		end
		creature(
			parent,
			"Unicorn",
			CFrame.lookAt(Vector3.new(east - 25, 0, -(width / 2 + 12)), Vector3.new(east - 25, 0, 0)),
			1.8
		)
	end,
}

THEMES[9] = { -- The Alien Life: glowing alien plants, UFOs, rockets and a ringed planet
	ground = rgb(70, 50, 120),
	wall = rgb(50, 40, 80),
	trim = rgb(120, 255, 120),
	wallHeight = 4,
	wallMat = M.DiamondPlate,
	accent = rgb(120, 255, 120),
	props = function(parent, cf, _rng, i)
		local pick = ({
			"Plant_AlienPlant",
			"Yard_CrystalReactor",
			"Plant_AlienPlant",
			"Yard_TeleportPortal",
			"Yard_Saturn",
		})[i % 5 + 1]
		item(parent, pick, cf, 1.3)
	end,
	backdrop = function(parent, east, west, width)
		local n = 0
		for _, side in { -1, 1 } do
			for x = east - 12, west + 12, -22 do
				n += 1
				local pos = Vector3.new(x, 0, side * (width / 2 + 16 + (n % 2) * 10))
				local id = if n % 3 == 0 then "Yard_RocketShip" else "Plant_AlienPlant"
				item(parent, id, CFrame.lookAt(pos, Vector3.new(x, 0, 0)), if id == "Yard_RocketShip" then 3 else 4)
			end
			item(parent, "Yard_UFO", CFrame.new((east + west) / 2 + side * 20, 30, side * (width / 2 + 40)), 3)
		end
		planet(parent, CFrame.new((east + west) / 2, 80, width / 2 + 90) * CFrame.Angles(0, 0, math.rad(15)), 40, {
			rgb(230, 200, 140),
			rgb(220, 160, 90),
			rgb(240, 220, 170),
		}, rgb(255, 210, 140))
	end,
}

THEMES[10] = { -- The Ultimate Life: clouds, rainbows, floating islands and a golden palace
	ground = rgb(235, 245, 255),
	wall = rgb(250, 250, 255),
	trim = rgb(255, 200, 80),
	wallHeight = 3,
	accent = rgb(255, 200, 80),
	props = function(parent, cf, _rng, i)
		local pick = ({
			"Yard_CelestialCrown",
			"Plant_CosmicTree",
			"Yard_LivingPlanet",
			"Yard_RainbowWaterfall",
			"Yard_MiniGalaxy",
		})[i % 5 + 1]
		item(parent, pick, cf, 1.3)
	end,
	backdrop = function(parent, east, west, width)
		local center = (east + west) / 2
		for _, side in { -1, 1 } do
			for x = east - 15, west + 15, -30 do
				cloud(parent, CFrame.new(x, 2, side * (width / 2 + 12)), 22)
			end
			rainbow(parent, CFrame.new(center, 0, side * (width / 2 + 45)), 50, 3)
			for k = 0, 2 do
				local x = center + (k - 1) * 70
				local cf = CFrame.new(x, 40 + k * 12, side * (width / 2 + 60 + k * 10))
				island(parent, cf, 34)
				if k == 1 then
					item(
						parent,
						"Yard_GoldenPalace",
						cf * CFrame.new(0, 2, 0) * CFrame.Angles(0, if side > 0 then math.pi else 0, 0),
						2.5
					)
				else
					item(parent, "Plant_CosmicTree", cf * CFrame.new(0, 2, 0), 3)
				end
			end
		end
		planet(
			parent,
			CFrame.new(center + 40, 70, -(width / 2 + 45)),
			26,
			{ rgb(60, 140, 230), rgb(90, 190, 90), rgb(60, 140, 230) }
		)
		planet(
			parent,
			CFrame.new(center - 60, 85, -(width / 2 + 70)),
			14,
			{ rgb(255, 150, 80), rgb(255, 200, 120) },
			rgb(200, 150, 255)
		)
		creature(
			parent,
			"RainbowPhoenix",
			CFrame.new(center - 50, 50, width / 2 + 30) * CFrame.Angles(0, math.pi, 0),
			3
		)
	end,
}

-- The theme for zone `index`.
function ZoneDecor.theme(index: number)
	return THEMES[index] or THEMES[1]
end

ZoneDecor.propSpots = {} -- [zone index] = { Vector3 } where the props stand

function ZoneDecor.build(parent: Instance, index: number)
	local theme = ZoneDecor.theme(index)
	local east, west = ZoneLayout.edges(index)
	local length, width = ZoneLayout.length(index), ZoneLayout.WIDTH
	local centerX = (east + west) / 2
	local folder = Instance.new("Folder")
	folder.Name = "Zone" .. index .. "_" .. Items.ZONES[index].name
	folder.Parent = parent

	-- A checkerboard floor in two shades of the zone's own ground colour: the colour
	-- change is what tells you you've walked into the next zone (there are no signs).
	-- Floors keep their own colours (see Lego: they're marked AnyColor).
	local tile = 13
	local countX, countZ = math.round(length / tile), math.round(width / tile)
	local groundA, groundB = theme.ground, theme.ground:Lerp(rgb(0, 0, 0), 0.1)
	for i = 0, countX - 1 do
		for k = 0, countZ - 1 do
			local w, d = length / countX, width / countZ
			local floor = block(
				folder,
				Vector3.new(w, 2, d),
				CFrame.new(east - (i + 0.5) * w, -0.98, -width / 2 + (k + 0.5) * d),
				if (i + k) % 2 == 0 then groundA else groundB,
				M.SmoothPlastic,
				true
			)
			floor.Name = "Tile"
			floor:SetAttribute("AnyColor", true)
		end
	end
	-- The ground beyond the walls, where the backdrop stands, in a darker shade.
	for _, side in { -1, 1 } do
		local outside = block(
			folder,
			Vector3.new(length, 2, 200),
			CFrame.new(centerX, -1.02, side * (width / 2 + 103)),
			theme.ground:Lerp(rgb(0, 0, 0), 0.18),
			M.SmoothPlastic
		)
		outside:SetAttribute("AnyColor", true)
	end
	-- Walls along both sides: low ones (so the scenery beyond shows) with a coloured strip
	-- on top, and an invisible wall all the way up so nobody can get out of the zone.
	local wallHeight = theme.wallHeight or 6
	for _, side in { -1, 1 } do
		local z = side * (width / 2 + 3)
		block(
			folder,
			Vector3.new(length, wallHeight, 6),
			CFrame.new(centerX, wallHeight / 2, z),
			theme.wall,
			theme.wallMat,
			true
		)
		block(folder, Vector3.new(length, 1, 6.4), CFrame.new(centerX, wallHeight + 0.5, z), theme.trim, theme.wallMat)
		local barrier = block(folder, Vector3.new(length, 240, 6), CFrame.new(centerX, 120, z), theme.wall, nil, true)
		barrier.Name = "ZoneBarrier"
		barrier.Transparency = 1
		barrier.CanQuery = false
	end
	if index == 1 then
		-- Picket tops along the Neighborhood's low white walls.
		for _, side in { -1, 1 } do
			local z = side * (width / 2 + 3)
			for x = east - 1, west + 1, -2 do
				wedge(folder, Vector3.new(1.2, 1.2, 0.8), CFrame.new(x, wallHeight + 1.6, z), theme.wall)
			end
		end
	end
	if index == #Items.ZONES then
		block(folder, Vector3.new(6, 32, width + 12), CFrame.new(west - 3, 16, 0), theme.wall, theme.wallMat, true)
		local barrier =
			block(folder, Vector3.new(6, 240, width + 12), CFrame.new(west - 3, 120, 0), theme.wall, nil, true)
		barrier.Name = "ZoneBarrier"
		barrier.Transparency = 1
		barrier.CanQuery = false
	end
	if theme.wallArt then
		theme.wallArt(folder, east, west, width)
	end
	local scenery = Instance.new("Folder")
	scenery.Name = "Scenery"
	scenery.Parent = folder
	theme.backdrop(scenery, east, west, width)

	-- A row of the zone's props tucked against each side wall, facing the middle. The
	-- middle stays open for the eggs. Their spots are kept (ZoneDecor.propSpots) so eggs
	-- don't land inside them.
	local spots = {}
	ZoneDecor.propSpots[index] = spots
	local rng = Random.new(index * 7919)
	local borderV = width / 2 - 7
	local step = 15
	local n = 0
	for u = 10, length - 8, step do
		for _, side in { -1, 1 } do
			local uu = u + (if side > 0 then step / 2 else 0)
			if uu < length - 6 then
				n += 1
				local pos = Vector3.new(east - uu, 0, side * borderV)
				table.insert(spots, pos)
				theme.props(folder, CFrame.lookAt(pos, Vector3.new(pos.X, 0, 0)), rng, n)
			end
		end
	end
	return folder
end

return ZoneDecor
