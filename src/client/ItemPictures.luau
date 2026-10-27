-- 3D pictures for shop items (the treadmill, game passes), items, eggs and the side menu,
-- built from parts like everything else in the game and shown in ViewportFrames.
-- ItemPictures.view(key, height) returns a ViewportFrame; keys are "Treadmill" or a game
-- pass key from GamePasses.luau. ItemPictures.part(itemId) pictures any item (house part,
-- pet, yard item, plant), ItemPictures.egg(zone) a zone's egg and ItemPictures.icon(key) a
-- menu icon.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EggModel = require(ReplicatedStorage.Shared.EggModel)
local HouseModel = require(ReplicatedStorage.Shared.HouseModel)
local ItemModel = require(ReplicatedStorage.Shared.ItemModel)
local Lego = require(ReplicatedStorage.Shared.Lego)

local ItemPictures = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local GOLD = rgb(255, 200, 55)

local function part(model: Model, props)
	local p = Instance.new(props.ClassName or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		if key ~= "ClassName" then
			p[key] = value
		end
	end
	p.Parent = model
	return p
end

-- A ball, or a squashed ball (a sphere mesh) when the size isn't the same every way.
local function ball(model, position: Vector3, size: Vector3 | number, color: Color3, material: Enum.Material?)
	local vector = if typeof(size) == "number" then Vector3.one * size else size
	local round = vector.X == vector.Y and vector.Y == vector.Z
	local p = part(model, {
		Shape = if round then Enum.PartType.Ball else Enum.PartType.Block,
		Size = vector,
		CFrame = CFrame.new(position),
		Color = color,
		Material = material,
	})
	if not round then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	return p
end

local function cylinder(model, cframe: CFrame, height: number, diameter: number, color: Color3, material)
	return part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = cframe * CFrame.Angles(0, 0, math.pi / 2), -- upright
		Color = color,
		Material = material,
	})
end

local function plus(model, position: Vector3, size: number)
	local green = rgb(80, 220, 100)
	part(model, { Size = Vector3.new(size, size * 0.32, size * 0.32), CFrame = CFrame.new(position), Color = green })
	part(model, { Size = Vector3.new(size * 0.32, size, size * 0.32), CFrame = CFrame.new(position), Color = green })
end

local BUILDERS = {}

-- A chunky orange backpack.
local function backpack(model, plusSign: boolean)
	local orange = rgb(255, 140, 50)
	ball(model, Vector3.new(0, 2.4, 0), Vector3.new(3.6, 4.4, 2.4), orange)
	ball(model, Vector3.new(0, 1.6, -1.05), Vector3.new(2.6, 2, 1), rgb(255, 175, 80))
	part(model, { Size = Vector3.new(2.4, 0.25, 0.3), CFrame = CFrame.new(0, 2.5, -1.25), Color = rgb(90, 60, 40) })
	ball(model, Vector3.new(0, 2.5, -1.4), 0.35, GOLD, Enum.Material.Foil)
	for _, x in { -1.1, 1.1 } do
		part(model, {
			Size = Vector3.new(0.45, 3.6, 0.3),
			CFrame = CFrame.new(x, 2.5, 1.25) * CFrame.Angles(0, 0, math.rad(x * 4)),
			Color = rgb(90, 60, 40),
		})
	end
	cylinder(model, CFrame.new(0, 4.6, 0) * CFrame.Angles(math.pi / 2, 0, 0), 0.4, 1.2, rgb(90, 60, 40))
	if plusSign then
		plus(model, Vector3.new(2.4, 4.2, -0.6), 1.6)
	end
end

function BUILDERS.ExtraSlot1(model)
	backpack(model, true)
end
BUILDERS.ExtraSlot2 = BUILDERS.ExtraSlot1
BUILDERS.ExtraSlot3 = BUILDERS.ExtraSlot1

-- The treadmill (Shop): a belt, rails and a glowing console.
function BUILDERS.Treadmill(model)
	local frame = rgb(60, 62, 75)
	part(
		model,
		{ Size = Vector3.new(3, 0.6, 6), CFrame = CFrame.new(0, 0.3, 0), Color = frame, Material = Enum.Material.Metal }
	)
	part(model, { Size = Vector3.new(2.4, 0.2, 5.2), CFrame = CFrame.new(0, 0.7, 0.3), Color = rgb(30, 30, 36) })
	for _, x in { -1.4, 1.4 } do
		part(model, { Size = Vector3.new(0.3, 0.3, 5.6), CFrame = CFrame.new(x, 0.8, 0.2), Color = rgb(90, 200, 255) })
		part(model, { Size = Vector3.new(0.25, 2.6, 0.25), CFrame = CFrame.new(x, 1.9, -2.6), Color = frame })
	end
	part(model, { Size = Vector3.new(3, 0.3, 0.3), CFrame = CFrame.new(0, 3.1, -2.6), Color = rgb(90, 200, 255) })
	part(model, {
		Size = Vector3.new(2.2, 1.1, 0.3),
		CFrame = CFrame.new(0, 3.8, -2.8) * CFrame.Angles(math.rad(20), 0, 0),
		Color = rgb(90, 220, 255),
		Material = Enum.Material.Neon,
	})
	-- A lightning bolt over it.
	local yellow = rgb(255, 220, 40)
	for _, bit in { { 1.9, 5, -30 }, { 1.6, 3.9, 35 }, { 2, 2.8, -30 } } do
		part(model, {
			Size = Vector3.new(0.6, 1.4, 0.4),
			CFrame = CFrame.new(bit[1], bit[2], -0.6) * CFrame.Angles(0, 0, math.rad(bit[3])),
			Color = yellow,
			Material = Enum.Material.Neon,
		})
	end
end

-- 2x Coins: a pile of gold coins and a green cash stack.
function BUILDERS.DoubleCoins(model)
	for i = 0, 2 do
		part(model, {
			Size = Vector3.new(3.4, 0.6, 1.8),
			CFrame = CFrame.new(0.4, 0.3 + i * 0.62, 0.6) * CFrame.Angles(0, math.rad(i * 7), 0),
			Color = rgb(90, 200, 90),
		})
		part(model, {
			Size = Vector3.new(0.6, 0.66, 1.86),
			CFrame = CFrame.new(0.4, 0.3 + i * 0.62, 0.6) * CFrame.Angles(0, math.rad(i * 7), 0),
			Color = rgb(255, 240, 200),
		})
	end
	for i, spot in
		{
			Vector3.new(-1.4, 0.2, -0.6),
			Vector3.new(-1.4, 0.55, -0.6),
			Vector3.new(-1.4, 0.9, -0.6),
			Vector3.new(-0.3, 0.2, -1.2),
		}
	do
		cylinder(model, CFrame.new(spot) * CFrame.Angles(0, i, 0), 0.32, 1.7, GOLD, Enum.Material.Foil)
	end
	-- One big coin standing up in front.
	part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 2.4, 2.4),
		CFrame = CFrame.new(-0.6, 1.6, -1.6) * CFrame.Angles(0, math.rad(80), 0),
		Color = GOLD,
		Material = Enum.Material.Foil,
	})
end

-- Fast Fusing: a pink potion with a lightning bolt.
-- Copies an egg's parts into a picture model at a spot.
local function addEgg(model, zoneIndex: number, cframe: CFrame)
	local egg = EggModel.build(zoneIndex)
	egg:PivotTo(cframe)
	for _, p in egg:GetDescendants() do
		if p:IsA("BasePart") then
			p.Parent = model
		end
	end
	egg:Destroy()
end

-- A chunky zig-zag lightning bolt.
local function bolt(model, offset: Vector3, size: number)
	local yellow = rgb(255, 220, 40)
	for _, bit in { { 0.3, 1.2, -30 }, { 0, 0, 35 }, { 0.4, -1.2, -30 } } do
		part(model, {
			Size = Vector3.new(0.7, 1.6, 0.5) * size,
			CFrame = CFrame.new(offset + Vector3.new(bit[1], bit[2], 0) * size) * CFrame.Angles(0, 0, math.rad(bit[3])),
			Color = yellow,
			Material = Enum.Material.Neon,
		})
	end
end

-- Fast Hatching: a fancy egg with a lightning bolt.
function BUILDERS.FastBreeding(model)
	addEgg(model, 6, CFrame.new(0, 0, 0))
	bolt(model, Vector3.new(2.3, 2.4, -0.6), 1)
end

-- 2x Speed: a big lightning bolt with a running shoe.
function BUILDERS.LongerLock(model)
	bolt(model, Vector3.new(0, 2.6, 0), 1.6)
	part(model, { Size = Vector3.new(1.6, 1, 3), CFrame = CFrame.new(-1.8, 0.5, 0), Color = rgb(255, 80, 80) })
	part(model, { Size = Vector3.new(1.7, 0.35, 3.2), CFrame = CFrame.new(-1.8, 0.1, 0), Color = rgb(255, 255, 255) })
	part(model, { Size = Vector3.new(1.6, 1, 1.2), CFrame = CFrame.new(-1.8, 1.4, 0.9), Color = rgb(255, 80, 80) })
end

-- VIP: a gold crown with gems.
function BUILDERS.VIP(model)
	cylinder(model, CFrame.new(0, 0.8, 0), 1.6, 3.6, GOLD, Enum.Material.Foil)
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		local spot = Vector3.new(math.sin(a) * 1.5, 2.2, -math.cos(a) * 1.5)
		part(model, {
			Size = Vector3.new(0.9, 1.6, 0.9),
			CFrame = CFrame.new(spot) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.rad(45)),
			Color = GOLD,
			Material = Enum.Material.Foil,
		})
		ball(model, spot + Vector3.new(0, 1.1, 0), 0.55, GOLD, Enum.Material.Foil)
	end
	for k, color in { rgb(255, 50, 80), rgb(80, 160, 255), rgb(90, 220, 110) } do
		local a = (k - 2) * 0.7
		ball(model, Vector3.new(math.sin(a) * 1.8, 0.8, -math.cos(a) * 1.8), 0.7, color, Enum.Material.Neon)
	end
end

-- Extra Nests: a straw nest with two eggs in it.
function BUILDERS.ExtraPen(model)
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		part(model, {
			Size = Vector3.new(1.6, 0.9, 1),
			CFrame = CFrame.new(math.cos(a) * 2.1, 0.5 + (k % 2) * 0.15, math.sin(a) * 2.1)
				* CFrame.Angles(0, -a + math.pi / 2, 0),
			Color = if k % 2 == 0 then rgb(230, 185, 90) else rgb(205, 155, 70),
		})
	end
	cylinder(model, CFrame.new(0, 0.2, 0), 0.4, 4, rgb(190, 140, 65))
	addEgg(model, 3, CFrame.new(-0.8, 0.3, 0.2) * CFrame.Angles(0, 0, math.rad(12)))
	addEgg(model, 8, CFrame.new(0.9, 0.3, -0.2) * CFrame.Angles(0, 0, math.rad(-10)))
	plus(model, Vector3.new(2.6, 3.6, -0.6), 1.6)
end

--------------------------------------------------------------------------------
-- Menu icons: the pictures on the side buttons (keys "Menu" .. tab name). They're built
-- flat-on, facing the camera (-Z), and shown by ItemPictures.icon.
--------------------------------------------------------------------------------

-- An isosceles triangle slab from two wedges: base centred on `base`, `across` along the
-- base, `toward` pointing at the tip.
local function triangle(model, base: Vector3, across: Vector3, toward: Vector3, width, height, depth, color, material)
	for _, side in { 1, -1 } do
		local u = across * side
		part(model, {
			ClassName = "WedgePart",
			Size = Vector3.new(depth, height, width / 2),
			CFrame = CFrame.fromMatrix(base + toward * (height / 2) + u * (width / 4), u:Cross(toward), toward, -u),
			Color = color,
			Material = material,
		})
	end
end

-- A five-pointed star standing up, facing the camera.
local function star(model, center: Vector3, outer: number, inner: number, depth: number, color: Color3)
	local half = math.rad(36)
	for k = 0, 4 do
		local a = math.rad(k * 72)
		local toward = Vector3.new(math.sin(a), math.cos(a), 0)
		local across = Vector3.new(math.cos(a), -math.sin(a), 0)
		local base = center + toward * inner * math.cos(half)
		local width = 2 * inner * math.sin(half)
		triangle(model, base, across, toward, width, outer - inner * math.cos(half), depth, color)
		triangle(model, base, across, -toward, width, inner * math.cos(half), depth, color)
	end
end

-- A little four-point sparkle.
local function sparkle(model, position: Vector3, size: number)
	local white = rgb(255, 255, 235)
	for _, angle in { 0, 90 } do
		part(model, {
			Size = Vector3.new(size * 0.22, size, size * 0.1),
			CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(angle)),
			Color = white,
			Material = Enum.Material.Neon,
		})
	end
end

-- Shop: a red shopping cart full of goodies.
BUILDERS.MenuShop = function(model)
	local red, white, dark = rgb(240, 70, 85), rgb(255, 245, 245), rgb(55, 55, 70)
	local w, d, h = 3.8, 2.4, 2
	local y0 = 1.3
	part(model, { Size = Vector3.new(w - 0.6, 0.25, d), CFrame = CFrame.new(0, y0, 0), Color = red })
	for _, z in { -d / 2, d / 2 } do
		-- Front and back walls.
		part(model, { Size = Vector3.new(w, h, 0.2), CFrame = CFrame.new(0, y0 + h / 2, z), Color = red })
		-- White grille stripes.
		for k = 1, 2 do
			part(model, {
				Size = Vector3.new(w - 0.4, 0.14, 0.24),
				CFrame = CFrame.new(0, y0 + h * k / 3, z),
				Color = white,
			})
		end
	end
	for _, x in { -w / 2 + 0.15, w / 2 - 0.15 } do
		part(model, { Size = Vector3.new(0.2, h, d), CFrame = CFrame.new(x, y0 + h / 2, 0), Color = red })
	end
	-- The rim and the push handle.
	part(model, { Size = Vector3.new(w + 0.1, 0.25, 0.3), CFrame = CFrame.new(0, y0 + h, -d / 2), Color = white })
	part(model, { Size = Vector3.new(w + 0.1, 0.25, 0.3), CFrame = CFrame.new(0, y0 + h, d / 2), Color = white })
	part(model, {
		Size = Vector3.new(0.25, 1.4, 0.25),
		CFrame = CFrame.new(w / 2 + 0.2, y0 + h + 0.4, -d / 2) * CFrame.Angles(0, 0, math.rad(-30)),
		Color = dark,
	})
	part(model, {
		Size = Vector3.new(0.25, 1.4, 0.25),
		CFrame = CFrame.new(w / 2 + 0.2, y0 + h + 0.4, d / 2) * CFrame.Angles(0, 0, math.rad(-30)),
		Color = dark,
	})
	part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(d + 0.6, 0.45, 0.45),
		CFrame = CFrame.new(w / 2 + 0.55, y0 + h + 1, 0) * CFrame.Angles(0, math.pi / 2, 0),
		Color = rgb(255, 200, 60),
	})
	-- Legs and wheels.
	part(model, { Size = Vector3.new(w - 0.8, 0.2, 0.2), CFrame = CFrame.new(0, 0.55, -d / 2 + 0.2), Color = dark })
	part(model, { Size = Vector3.new(w - 0.8, 0.2, 0.2), CFrame = CFrame.new(0, 0.55, d / 2 - 0.2), Color = dark })
	for _, x in { -w / 2 + 0.6, w / 2 - 0.6 } do
		for _, z in { -d / 2 + 0.2, d / 2 - 0.2 } do
			part(
				model,
				{ Size = Vector3.new(0.2, y0 - 0.5, 0.2), CFrame = CFrame.new(x, (y0 + 0.5) / 2, z), Color = dark }
			)
			part(model, {
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.35, 0.8, 0.8),
				CFrame = CFrame.new(x, 0.4, z) * CFrame.Angles(0, math.pi / 2, 0),
				Color = rgb(35, 35, 45),
			})
			part(model, {
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.4, 0.35, 0.35),
				CFrame = CFrame.new(x, 0.4, z) * CFrame.Angles(0, math.pi / 2, 0),
				Color = rgb(200, 200, 210),
			})
		end
	end
	-- Goodies poking out of the top.
	part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.35, 1.8, 1.8),
		CFrame = CFrame.new(-0.7, y0 + h + 0.3, 0.2) * CFrame.Angles(0, math.rad(80), math.rad(10)),
		Color = GOLD,
		Material = Enum.Material.Foil,
	})
	ball(model, Vector3.new(0.6, y0 + h, 0.3), 1.5, rgb(90, 210, 255))
	part(model, {
		Size = Vector3.new(1.3, 1.3, 1.3),
		CFrame = CFrame.new(1.2, y0 + h - 0.1, -0.1) * CFrame.Angles(0, math.rad(20), math.rad(-12)),
		Color = rgb(170, 100, 255),
	})
	part(model, {
		Size = Vector3.new(0.3, 1.36, 1.36),
		CFrame = CFrame.new(1.2, y0 + h - 0.1, -0.1) * CFrame.Angles(0, math.rad(20), math.rad(-12)),
		Color = rgb(255, 220, 60),
	})
end

-- Luck: a shiny four-leaf clover.
BUILDERS.MenuLuck = function(model)
	local green, light, dark = rgb(30, 165, 65), rgb(120, 235, 120), rgb(15, 105, 45)
	local center = Vector3.new(0, 2.6, 0)
	-- The stem, curling down to the right.
	part(model, {
		Size = Vector3.new(0.35, 1.8, 0.35),
		CFrame = CFrame.new(center + Vector3.new(0.35, -1.5, 0.15)) * CFrame.Angles(0, 0, math.rad(-18)),
		Color = dark,
	})
	part(model, {
		Size = Vector3.new(0.35, 1.0, 0.35),
		CFrame = CFrame.new(center + Vector3.new(0.85, -2.6, 0.15)) * CFrame.Angles(0, 0, math.rad(-40)),
		Color = dark,
	})
	for k = 0, 3 do
		local a = math.rad(45 + k * 90)
		local out = Vector3.new(math.sin(a), math.cos(a), 0)
		local side = Vector3.new(math.cos(a), -math.sin(a), 0)
		-- A heart: two round lobes and a diamond point toward the middle.
		for _, s in { -1, 1 } do
			ball(model, center + out * 1.45 + side * s * 0.5, Vector3.new(1.45, 1.45, 0.6), green)
			ball(
				model,
				center + out * 1.6 + side * s * 0.5 + Vector3.new(0, 0, -0.22),
				Vector3.new(0.6, 0.6, 0.2),
				light
			)
		end
		part(model, {
			Size = Vector3.new(1.15, 1.15, 0.55),
			CFrame = CFrame.new(center + out * 0.75) * CFrame.Angles(0, 0, -a + math.rad(45)),
			Color = green,
		})
		-- A darker vein down the middle of the leaf.
		part(model, {
			Size = Vector3.new(0.14, 1.3, 0.1),
			CFrame = CFrame.new(center + out * 1.05 + Vector3.new(0, 0, -0.3)) * CFrame.Angles(0, 0, -a),
			Color = dark,
		})
	end
	ball(model, center + Vector3.new(0, 0, -0.1), Vector3.new(0.7, 0.7, 0.5), dark)
	sparkle(model, center + Vector3.new(-2, 2, -0.6), 0.9)
	sparkle(model, center + Vector3.new(2.2, -1.2, -0.6), 0.6)
end

-- Book: the Catalog, open, with a ribbon.
BUILDERS.MenuBook = function(model)
	local cover, pages, lines = rgb(225, 45, 80), rgb(255, 250, 235), rgb(190, 180, 170)
	local center = Vector3.new(0, 2, 0)
	for _, s in { -1, 1 } do
		local hinge = CFrame.new(center) * CFrame.Angles(math.rad(-25), 0, 0) * CFrame.Angles(0, math.rad(-s * 24), 0)
		part(model, {
			Size = Vector3.new(2.45, 3.25, 0.35),
			CFrame = hinge * CFrame.new(s * 1.2, 0, 0.3),
			Color = cover,
		})
		part(model, {
			Size = Vector3.new(2.1, 2.85, 0.3),
			CFrame = hinge * CFrame.new(s * 1.07, 0.02, 0),
			Color = pages,
		})
		for k = 0, 3 do
			part(model, {
				Size = Vector3.new(if k == 0 then 1 else 1.5, 0.12, 0.05),
				CFrame = hinge * CFrame.new(s * 1.07, 0.9 - k * 0.45, -0.17),
				Color = lines,
			})
		end
	end
	-- A little face on the left page and a ribbon hanging out.
	ball(model, center + Vector3.new(-1.05, 0.2, -0.45), Vector3.new(0.9, 0.9, 0.3), rgb(255, 160, 190))
	ball(model, center + Vector3.new(-1.25, 0.3, -0.62), Vector3.new(0.22, 0.22, 0.1), rgb(30, 30, 40))
	ball(model, center + Vector3.new(-0.85, 0.3, -0.62), Vector3.new(0.22, 0.22, 0.1), rgb(30, 30, 40))
	part(model, {
		Size = Vector3.new(0.35, 1.4, 0.06),
		CFrame = CFrame.new(center + Vector3.new(0.15, -1.9, -0.1)) * CFrame.Angles(0, 0, math.rad(8)),
		Color = rgb(235, 60, 80),
	})
	sparkle(model, center + Vector3.new(2.2, 1.9, -0.4), 0.8)
end

-- House: a little house made of real house parts.
BUILDERS.MenuHouse = function(model)
	local function add(partId: string, offset: CFrame)
		local item = HouseModel.item(partId)
		item:PivotTo(offset)
		for _, p in item:GetDescendants() do
			if p:IsA("BasePart") then
				p.Parent = model
			end
		end
		item:Destroy()
	end
	add("Candy_Walls", CFrame.new(0, 0, 0))
	add("Royal_Roof", CFrame.new(0, 4.8, 0))
	add("Basic_Door", CFrame.new(0, 0.4, -2.3) * CFrame.new(0, 0, 0))
end

-- My Life: the little house with a sunflower and a pet beside it.
BUILDERS.MenuLife = function(model)
	BUILDERS.MenuHouse(model)
	for _, entry in
		{ { "Plant_Sunflower", CFrame.new(3.6, 0, -0.4), 0.45 }, { "Pet_Oinkle", CFrame.new(-3.4, 0, -1.2), 0.9 } }
	do
		local item = ItemModel.build(entry[1])
		local pivot = item:GetPivot()
		for _, p in item:GetDescendants() do
			if p:IsA("BasePart") then
				local rel = pivot:ToObjectSpace(p.CFrame)
				p.Size *= entry[3]
				p.CFrame = entry[2] * (rel.Rotation + rel.Position * entry[3])
				p.Parent = model
			end
		end
		item:Destroy()
	end
end

-- Bag: the backpack.
BUILDERS.MenuBag = function(model)
	backpack(model, false)
end

-- Catalog: the book.
BUILDERS.MenuCatalog = function(model)
	BUILDERS.MenuBook(model)
end

-- Home: a fancy front door (it takes you home).
BUILDERS.MenuHome = function(model)
	local item = HouseModel.item("Royal_Door")
	for _, p in item:GetDescendants() do
		if p:IsA("BasePart") then
			p.Parent = model
		end
	end
	item:Destroy()
	sparkle(model, Vector3.new(2, 4.6, -0.8), 0.9)
end

-- Rebirth: a big gold star with a bevel.
BUILDERS.MenuRebirth = function(model)
	star(model, Vector3.new(0, 2.4, 0), 2.4, 1.05, 0.8, rgb(255, 180, 30))
	star(model, Vector3.new(0, 2.45, -0.42), 1.75, 0.76, 0.15, rgb(255, 225, 90))
	ball(model, Vector3.new(-0.45, 2.95, -0.55), Vector3.new(0.35, 0.55, 0.1), rgb(255, 255, 230))
	sparkle(model, Vector3.new(2.1, 4.3, -0.5), 0.9)
	sparkle(model, Vector3.new(-2.2, 0.8, -0.5), 0.6)
end

-- Store: a cut diamond, built facet by facet.
BUILDERS.MenuStore = function(model)
	local girdle = Vector3.new(0, 2.6, 0)
	local radius, depth, top, tableRadius = 2.2, 2.4, 0.85, 1.35
	local up = Vector3.yAxis
	local function around(angle: number, r: number, y: number): Vector3
		local a = math.rad(angle)
		return girdle + Vector3.new(math.sin(a) * r, y, math.cos(a) * r)
	end
	local function facet(p1: Vector3, p2: Vector3, apex: Vector3, color: Color3)
		local base = (p1 + p2) / 2
		local toward = apex - base
		triangle(model, base, (p2 - p1).Unit, toward.Unit, (p2 - p1).Magnitude, toward.Magnitude, 0.15, color)
	end
	local tip = girdle - up * depth
	for k = 0, 7 do
		local a = k * 45
		local p1, p2 = around(a, radius, 0), around(a + 45, radius, 0)
		local light = k % 2 == 0
		-- The point underneath, the crown's slopes, and the little gaps between them.
		facet(p1, p2, tip, if light then rgb(110, 225, 255) else rgb(40, 170, 245))
		local q = around(a + 22.5, tableRadius, top)
		facet(p1, p2, q, if light then rgb(180, 242, 255) else rgb(95, 205, 255))
		facet(q, around(a + 67.5, tableRadius, top), p2, if light then rgb(140, 230, 255) else rgb(200, 248, 255))
	end
	part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, tableRadius * 2.05, tableRadius * 2.05),
		CFrame = CFrame.new(girdle + up * top) * CFrame.Angles(0, 0, math.pi / 2),
		Color = rgb(225, 252, 255),
	})
	sparkle(model, girdle + Vector3.new(-1.3, 1.6, -1.8), 1)
	sparkle(model, girdle + Vector3.new(1.9, -1.2, -1.6), 0.7)
end

-- The box round everything you can see (counting stretched sphere meshes).
local function visibleBounds(model: Model): (Vector3, Vector3)
	local lo, hi
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			local size = p.Size
			local mesh = p:FindFirstChildOfClass("SpecialMesh")
			if mesh then
				size *= mesh.Scale
			end
			for _, x in { -0.5, 0.5 } do
				for _, y in { -0.5, 0.5 } do
					for _, z in { -0.5, 0.5 } do
						local point = p.CFrame:PointToWorldSpace(size * Vector3.new(x, y, z))
						lo = if lo then lo:Min(point) else point
						hi = if hi then hi:Max(point) else point
					end
				end
			end
		end
	end
	return lo or Vector3.zero, hi or Vector3.zero
end

-- A square icon (the side menu's pictures): framed to fill the square, seen almost
-- head-on. Returns the ViewportFrame and sway(t), which turns the picture gently from side
-- to side over time.
function ItemPictures.icon(key: string): (ViewportFrame, (number) -> ())
	local frame = Instance.new("ViewportFrame")
	frame.BackgroundTransparency = 1
	frame.Ambient = Color3.fromRGB(200, 200, 205)
	frame.LightColor = Color3.fromRGB(255, 250, 240)
	frame.LightDirection = Vector3.new(-0.8, -1.2, 1)

	local model = Instance.new("Model")
	BUILDERS[key](model)
	Lego.apply(model)
	model.Parent = frame

	local lo, hi = visibleBounds(model)
	local center = (lo + hi) / 2
	local extent = hi - lo
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	local fit = math.max(extent.X, extent.Y, extent.Z * 0.7) / 2 * 1.05
	local distance = fit / math.tan(math.rad(15)) + extent.Z / 2
	local direction = Vector3.new(0.3, 0.22, -1).Unit
	local function sway(t: number)
		local turn = CFrame.Angles(0, math.sin(t) * math.rad(14), 0)
		camera.CFrame = CFrame.lookAt(center + turn:VectorToWorldSpace(direction) * distance, center)
	end
	sway(0)
	camera.Parent = frame
	frame.CurrentCamera = camera
	return frame, sway
end

-- Frames a model in a ViewportFrame, seen a little from above and the side.
local function framed(model: Model, height: number?, silhouette: boolean?): ViewportFrame
	local frame = Instance.new("ViewportFrame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, height or 100)
	frame.Ambient = Color3.fromRGB(195, 195, 200)
	frame.LightColor = Color3.fromRGB(255, 250, 240)
	frame.LightDirection = Vector3.new(-1, -1.4, 1)
	frame.ImageColor3 = if silhouette then Color3.new(0, 0, 0) else Color3.new(1, 1, 1)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
		end
	end
	Lego.apply(model)
	model.Parent = frame
	local lo, hi = visibleBounds(model)
	local center = (lo + hi) / 2
	local extent = hi - lo
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	local fit = math.max(extent.Y, math.max(extent.X, extent.Z) * 0.8 / 1.6) / 2 * 1.12
	local distance = fit / math.tan(math.rad(15)) + extent.Z / 2
	camera.CFrame = CFrame.lookAt(center + Vector3.new(0.45, 0.4, -1).Unit * distance, center)
	camera.Parent = frame
	frame.CurrentCamera = camera
	return frame
end

-- Any item (house part, pet, yard item, plant). silhouette = true draws it solid black
-- ("???" in the Catalog).
function ItemPictures.part(itemId: string, height: number?, silhouette: boolean?, mutations): ViewportFrame
	return framed(ItemModel.build(itemId, mutations), height, silhouette)
end

-- A zone's egg.
function ItemPictures.egg(zoneIndex: number, height: number?): ViewportFrame
	return framed((EggModel.build(zoneIndex)), height)
end

function ItemPictures.has(key: string): boolean
	return BUILDERS[key] ~= nil
end

-- A ViewportFrame showing the item, framed to fit, seen a little from above and the side.
function ItemPictures.view(key: string, height: number?): ViewportFrame
	local frame = Instance.new("ViewportFrame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, height or 90)
	frame.Ambient = Color3.fromRGB(190, 190, 190)
	frame.LightColor = Color3.fromRGB(255, 250, 240)
	frame.LightDirection = Vector3.new(-1, -1.4, 1)

	local model = Instance.new("Model")
	if BUILDERS[key] then
		BUILDERS[key](model)
	end
	Lego.apply(model)
	model.Parent = frame

	local lo, hi = visibleBounds(model)
	local center = (lo + hi) / 2
	local extent = hi - lo
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	-- The picture strip is about twice as wide as it is tall, so wide items can use the
	-- width (the field of view is vertical).
	local aspect = 2
	local wide = math.max(extent.X, extent.Z) * 0.85
	local fit = math.max(extent.Y, wide / aspect) / 2 * 1.08
	local distance = fit / math.tan(math.rad(15)) + extent.Z / 2
	local direction = Vector3.new(0.45, 0.4, -1).Unit
	camera.CFrame = CFrame.lookAt(center + direction * distance, center)
	camera.Parent = frame
	frame.CurrentCamera = camera
	return frame
end

return ItemPictures
