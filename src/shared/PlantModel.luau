-- Plants in the crafted look (low-poly, smooth, no studs; see Lego): built from blocks and
-- wedges, some set at angles, in muted greens and bold flower colours with glowing bits.
-- PlantModel.build(itemId) returns a model standing on its pivot (the middle of a garden
-- bed, about 7 x 7 studs).

local Bricks = require(script.Parent.Bricks)
local Items = require(script.Parent.Items)

local PlantModel = {}

local rgb, block, wedge, glow, octo = Bricks.rgb, Bricks.block, Bricks.wedge, Bricks.glow, Bricks.octo
local M = Enum.Material
local STEM = rgb(70, 150, 70)
local LEAF = rgb(62, 160, 74)
local LEAF_DARK = rgb(46, 122, 60)
local TRUNK = rgb(120, 82, 50)
local SOIL = rgb(92, 64, 44)
local GOLD = rgb(255, 200, 60)

local function cf(x, y, z, rx, ry, rz)
	return CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
end

-- A low mound of soil clods.
local function soil(m, width: number)
	block(m, Vector3.new(width, 0.3, width), cf(0, 0.15, 0), SOIL)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		block(
			m,
			Vector3.new(0.7, 0.3, 0.6),
			cf(math.cos(a) * width * 0.32, 0.35, math.sin(a) * width * 0.32, 0, i * 37, 0),
			rgb(110, 78, 52)
		)
	end
end

-- A flower head facing -Z: `petals` petal blocks round a middle.
local function flower(m, at: CFrame, size: number, petal: Color3, middle: Color3, petals: number?, glowing: boolean?)
	local n = petals or 8
	for i = 0, n - 1 do
		local a = i / n * math.pi * 2
		block(
			m,
			Vector3.new(size * 0.42, size * 0.24, 0.12),
			at * CFrame.Angles(0, 0, a) * CFrame.new(size * 0.38, 0, 0),
			petal
		)
	end
	if glowing then
		glow(m, Vector3.new(size * 0.38, size * 0.38, 0.16), at * CFrame.new(0, 0, -0.02), middle)
	else
		block(m, Vector3.new(size * 0.38, size * 0.38, 0.16), at * CFrame.new(0, 0, -0.02), middle)
	end
end

-- A cloud of leafy blocks round `centre` (a tree's crown).
local function crown(m, centre: Vector3, radius: number, colors, count: number?)
	local n = count or 9
	for i = 0, n - 1 do
		local a = i * 2.4
		local r = radius * (0.35 + (i % 3) * 0.25)
		local y = (i % 4 - 1.5) * radius * 0.28
		local s = radius * (0.8 + (i % 2) * 0.25)
		block(
			m,
			Vector3.new(s, s * 0.8, s),
			CFrame.new(centre + Vector3.new(math.cos(a) * r, y, math.sin(a) * r))
				* CFrame.Angles(0, a, (i % 3 - 1) * 0.15),
			colors[i % #colors + 1]
		)
	end
end

-- A trunk of stacked, slightly twisted blocks.
local function trunk(m, height: number, width: number, color: Color3?)
	local n = math.max(2, math.floor(height / 1.2))
	for i = 0, n - 1 do
		local w = width * (1 - i * 0.06)
		block(m, Vector3.new(w, height / n + 0.05, w), cf(0, (i + 0.5) * height / n, 0, 0, i * 14, 0), color or TRUNK)
	end
end

local builders = {}

function builders.FlowerPot(m)
	-- A chunky terracotta pot with a rim, overflowing with pink and yellow flowers.
	octo(m, 2.4, 1.6, CFrame.new(), rgb(200, 110, 70))
	octo(m, 2.8, 0.4, CFrame.new(0, 1.6, 0), rgb(222, 130, 84))
	octo(m, 2.3, 0.2, CFrame.new(0, 1.95, 0), SOIL)
	crown(m, Vector3.new(0, 2.6, 0), 1.1, { LEAF, LEAF_DARK }, 8)
	for i, spot in { { -0.7, 3.2, -0.6 }, { 0.6, 3.4, -0.5 }, { 0, 3.7, 0.2 }, { -0.4, 2.9, 0.7 }, { 0.8, 2.9, 0.5 } } do
		flower(
			m,
			cf(spot[1], spot[2], spot[3], -40, i * 50, 0),
			1.5,
			if i % 2 == 0 then rgb(255, 120, 170) else rgb(255, 220, 60),
			rgb(255, 250, 220),
			6,
			true
		)
	end
end

function builders.StrawberryBush(m)
	-- A leafy bush hanging with big red strawberries (gold seeds), little white flowers and
	-- glowing ripe ones.
	soil(m, 4)
	crown(m, Vector3.new(0, 1.3, 0), 1.7, { LEAF, LEAF_DARK, rgb(80, 170, 80) }, 12)
	for i, spot in
		{
			{ -1.2, 1.1, -1.3 },
			{ 0.9, 1.6, -1.4 },
			{ 0, 2.3, -1.0 },
			{ 1.5, 1.0, -0.4 },
			{ -1.5, 2.0, -0.2 },
			{ 0.4, 0.9, -1.8 },
		}
	do
		local berry = cf(spot[1], spot[2], spot[3], 180, i * 30, 0)
		wedge(m, Vector3.new(0.95, 0.95, 0.8), berry, rgb(225, 40, 60))
		block(m, Vector3.new(0.95, 0.4, 0.8), berry * CFrame.new(0, -0.65, 0), rgb(225, 40, 60))
		block(m, Vector3.new(0.8, 0.14, 0.7), berry * CFrame.new(0, -0.9, 0), LEAF_DARK)
		for k = 0, 2 do
			block(m, Vector3.new(0.06, 0.06, 0.04), berry * CFrame.new((k - 1) * 0.18, 0.05, -0.32), GOLD)
		end
		if i % 3 == 0 then
			glow(m, Vector3.new(0.3, 0.3, 0.3), berry * CFrame.new(0, -0.2, 0), rgb(255, 120, 140))
		end
	end
	for _, spot in { { -0.6, 2.8, 0.4 }, { 1.0, 2.4, 0.8 } } do
		flower(m, cf(spot[1], spot[2], spot[3], -60, 0, 0), 0.6, rgb(250, 250, 245), rgb(255, 220, 60), 5)
	end
end

function builders.GiantSunflower(m)
	-- A towering sunflower: a thick stem with big leaves, a huge head of two rings of golden
	-- petals round a dark seed face with a glowing spiral of seeds.
	soil(m, 3.6)
	block(m, Vector3.new(0.5, 7.4, 0.5), cf(0, 3.7, 0), STEM)
	for i, y in { 1.6, 3.0, 4.4, 5.6 } do
		local side = if i % 2 == 0 then -1 else 1
		wedge(m, Vector3.new(0.16, 0.9, 2.2), cf(side * 1.1, y, 0, 0, 90 * side, 30 * side), LEAF)
	end
	local head = cf(0, 8.0, -0.3, -15, 0, 0)
	for ringIndex, ring in { { 1.75, 1.2, rgb(255, 190, 30) }, { 1.35, 1.0, rgb(255, 215, 60) } } do
		for i = 0, 15 do
			local a = i / 16 * math.pi * 2 + ringIndex * 0.2
			wedge(
				m,
				Vector3.new(0.16, ring[2], 0.55),
				head
					* CFrame.Angles(0, 0, a)
					* CFrame.new(0, ring[1], -0.02 * ringIndex)
					* CFrame.Angles(0, math.pi / 2, 0),
				ring[3]
			)
		end
	end
	block(m, Vector3.new(2.3, 2.3, 0.4), head, rgb(100, 62, 34))
	block(m, Vector3.new(1.6, 1.6, 0.1), head * CFrame.new(0, 0, -0.24), rgb(70, 44, 24))
	for i = 0, 11 do
		local a = i * 2.4
		local r = 0.2 + i * 0.06
		glow(
			m,
			Vector3.new(0.14, 0.14, 0.06),
			head * CFrame.new(math.cos(a) * r, math.sin(a) * r, -0.3),
			rgb(255, 170, 40)
		)
	end
end

function builders.GiantMushroom(m)
	-- A giant red toadstool: a thick white stem with a frilly ring, a wide domed red cap of
	-- layered slabs with white spots, and glowing gills underneath; a little one beside it.
	soil(m, 4)
	local red, deep, white = rgb(220, 45, 50), rgb(180, 30, 40), rgb(245, 240, 230)
	for _, spec in { { 0, 0, 3.4, 4.4, true }, { 1.5, -1.0, 1.4, 1.6, false } } do
		local x, z, h, s, big = spec[1], spec[2], spec[3], spec[4], spec[5]
		octo(m, s * 0.32, h, CFrame.new(x, 0, z), white)
		if big then
			octo(m, s * 0.42, 0.25, CFrame.new(x, h * 0.7, z), white)
		end
		glow(m, Vector3.new(s * 0.8, 0.08, s * 0.8), cf(x, h + 0.02, z), rgb(255, 210, 160))
		octo(m, s, s * 0.14, CFrame.new(x, h, z), deep)
		octo(m, s * 0.85, s * 0.16, CFrame.new(x, h + s * 0.14, z), red)
		octo(m, s * 0.6, s * 0.14, CFrame.new(x, h + s * 0.3, z), red)
		octo(m, s * 0.3, s * 0.08, CFrame.new(x, h + s * 0.44, z), red)
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2 + x
			block(
				m,
				Vector3.new(s * 0.12, s * 0.05, s * 0.12),
				cf(x + math.cos(a) * s * 0.3, h + s * 0.31, z + math.sin(a) * s * 0.3, 0, k * 20, 0),
				white
			)
		end
	end
end

function builders.GiantPumpkin(m)
	-- A prize giant pumpkin: fat ribbed slabs in two oranges, a curly green stem with a big
	-- leaf with glowing veins and a glowing gold sparkle.
	local orange, deep = rgb(245, 140, 40), rgb(210, 105, 28)
	for i = 0, 9 do
		block(
			m,
			Vector3.new(1.7, 2.9, 1.0),
			cf(0, 1.6, 0, 0, i * 36, 0) * CFrame.new(0, 0, 1.7),
			if i % 2 == 0 then orange else deep
		)
	end
	octo(m, 3.6, 2.8, CFrame.new(0, 0.2, 0), orange)
	octo(m, 2.4, 0.4, CFrame.new(0, 3.0, 0), deep)
	block(m, Vector3.new(0.5, 1.1, 0.5), cf(0.15, 3.7, 0.1, 0, 0, 14), rgb(90, 120, 50))
	block(m, Vector3.new(0.35, 0.35, 0.8), cf(0.35, 4.2, 0.4, 30, 0, 14), rgb(90, 120, 50))
	wedge(m, Vector3.new(0.12, 0.7, 1.8), cf(1.0, 3.3, 0.7, 0, 40, 25), LEAF)
	-- Glowing veins on the leaf and a glowing prize sparkle on top.
	glow(m, Vector3.new(0.06, 0.1, 1.5), cf(1.0, 3.35, 0.7, 0, 40, 25), rgb(190, 255, 120))
	glow(m, Vector3.new(0.3, 0.3, 0.3), cf(-0.6, 3.3, -0.4, 45, 45, 0), GOLD)
end

function builders.PalmTree(m)
	-- A coconut palm: a curved, ringed trunk, a crown of long drooping fronds and a cluster of
	-- coconuts, on a little mound of sand.
	octo(m, 3.6, 0.4, CFrame.new(), rgb(240, 215, 150))
	local x = 0
	for i = 0, 7 do
		x += 0.12 * i * 0.25
		block(m, Vector3.new(0.75 - i * 0.03, 0.85, 0.75 - i * 0.03), cf(x, 0.6 + i * 0.8, 0, 0, i * 20, -i * 2), TRUNK)
		block(
			m,
			Vector3.new(0.82 - i * 0.03, 0.12, 0.82 - i * 0.03),
			cf(x, 0.2 + i * 0.8, 0, 0, i * 20, -i * 2),
			rgb(95, 64, 38)
		)
	end
	local top = Vector3.new(x + 0.2, 6.9, 0)
	for i = 0, 7 do
		local a = i / 8 * 360
		local frond = CFrame.new(top) * CFrame.Angles(0, math.rad(a), 0)
		block(
			m,
			Vector3.new(0.9, 0.12, 2.6),
			frond * CFrame.new(0, 0, 1.3) * CFrame.Angles(math.rad(-20), 0, 0),
			if i % 2 == 0 then LEAF else LEAF_DARK
		)
		block(
			m,
			Vector3.new(0.7, 0.12, 1.6),
			frond * CFrame.new(0, -0.7, 2.9) * CFrame.Angles(math.rad(-45), 0, 0),
			if i % 2 == 0 then LEAF_DARK else LEAF
		)
	end
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2
		block(
			m,
			Vector3.new(0.55, 0.55, 0.55),
			CFrame.new(top + Vector3.new(math.cos(a) * 0.45, -0.55, math.sin(a) * 0.45)),
			rgb(110, 72, 40)
		)
	end
	glow(m, Vector3.new(0.3, 0.3, 0.3), CFrame.new(top + Vector3.new(0, 0.2, 0)), rgb(255, 230, 120))
end

function builders.PineTree(m)
	-- A tall pine: a stepped stack of dark green tiers, each with a frosty lighter rim and
	-- pine cones, on a brown trunk, with a glowing star at the top.
	trunk(m, 1.6, 0.8)
	for i = 0, 4 do
		local s = 4.2 - i * 0.75
		local y = 1.4 + i * 1.15
		octo(
			m,
			s,
			0.9,
			CFrame.new(0, y, 0) * CFrame.Angles(0, math.rad(i * 22), 0),
			if i % 2 == 0 then LEAF_DARK else rgb(40, 110, 60)
		)
		octo(
			m,
			s * 0.75,
			0.35,
			CFrame.new(0, y + 0.9, 0) * CFrame.Angles(0, math.rad(i * 22 + 11), 0),
			rgb(50, 130, 70)
		)
		block(m, Vector3.new(0.3, 0.4, 0.3), cf(s * 0.35, y - 0.1, -s * 0.2, 0, i * 40, 0), rgb(120, 80, 45))
	end
	glow(m, Vector3.new(0.6, 0.6, 0.15), cf(0, 7.6, 0, 0, 0, 45), rgb(255, 230, 120))
end

function builders.CrystalTree(m)
	-- A magical crystal tree: a twisting pale trunk and a crown of glowing teal and pink
	-- crystal shards pointing every way, with floating sparkle gems.
	trunk(m, 3.4, 1.0, rgb(200, 190, 230))
	local colors = { rgb(90, 230, 230), rgb(255, 120, 220), rgb(160, 120, 255) }
	for i = 0, 13 do
		local a = i * 2.4
		local r = 0.6 + (i % 3) * 0.5
		local y = 4.0 + (i % 4) * 0.55
		local shard = cf(math.cos(a) * r, y, math.sin(a) * r, (i % 3 - 1) * 30, math.deg(a), (i % 2 - 0.5) * 50)
		local p = block(m, Vector3.new(0.75, 2.3, 0.75), shard, colors[i % 3 + 1], M.Glass)
		p.Transparency = 0.15
		glow(m, Vector3.new(0.3, 1.8, 0.3), shard, colors[(i + 1) % 3 + 1])
	end
	for i = 0, 3 do
		local a = i * 1.57 + 0.4
		glow(
			m,
			Vector3.new(0.3, 0.3, 0.3),
			cf(math.cos(a) * 2.4, 6.2 + (i % 2) * 0.6, math.sin(a) * 2.4, 45, 45, 0),
			rgb(255, 255, 220)
		)
	end
end

function builders.AlienPlant(m)
	-- An alien plant: fat curling purple tentacle leaves with glowing green tips and spots,
	-- round a tall stalk topped with a glowing bulb, in dark glowing soil.
	octo(m, 3.6, 0.35, CFrame.new(), rgb(40, 30, 60))
	glow(m, Vector3.new(3.0, 0.06, 0.12), cf(0, 0.36, 0), rgb(120, 255, 120))
	local purple, deep, tip = rgb(150, 70, 200), rgb(100, 40, 150), rgb(120, 255, 140)
	for i = 0, 5 do
		local a = i / 6 * 360
		local leaf = CFrame.Angles(0, math.rad(a), 0)
		block(m, Vector3.new(0.6, 1.6, 0.6), leaf * cf(0, 0.9, 0.8, 25, 0, 0), purple)
		block(m, Vector3.new(0.5, 1.3, 0.5), leaf * cf(0, 2.0, 1.5, 55, 0, 0), deep)
		glow(m, Vector3.new(0.45, 0.6, 0.45), leaf * cf(0, 2.5, 2.3, 85, 0, 0), tip)
		glow(m, Vector3.new(0.12, 0.12, 0.06), leaf * cf(0, 1.1, 1.12, 25, 0, 0), tip)
	end
	block(m, Vector3.new(0.45, 3.6, 0.45), cf(0, 1.8, 0), deep)
	octo(m, 1.4, 1.2, CFrame.new(0, 3.6, 0), purple)
	glow(m, Vector3.new(0.9, 0.9, 0.9), cf(0, 4.25, 0, 0, 45, 0), tip)
end

function builders.CosmicTree(m)
	-- A cosmic tree: a dark violet trunk swirled with glowing starlight, and a crown of deep
	-- space blues and purples dotted with glowing stars, with a little moon and a ringed
	-- planet orbiting it.
	trunk(m, 3.6, 0.9, rgb(70, 40, 110))
	for i = 0, 5 do
		glow(
			m,
			Vector3.new(0.1, 0.5, 0.1),
			cf(math.cos(i) * 0.48, 0.6 + i * 0.55, math.sin(i) * 0.48, 0, 0, 20),
			rgb(150, 210, 255)
		)
	end
	crown(m, Vector3.new(0, 5.1, 0), 2.2, { rgb(50, 40, 130), rgb(90, 50, 170), rgb(30, 70, 150) }, 13)
	for i = 0, 11 do
		local a = i * 2.4
		local r = 1.0 + (i % 3) * 0.6
		glow(
			m,
			Vector3.new(0.18, 0.18, 0.18),
			cf(math.cos(a) * r, 4.2 + (i % 4) * 0.7, math.sin(a) * r, 45, 45, 0),
			if i % 3 == 0 then rgb(255, 230, 120) else rgb(255, 255, 255)
		)
	end
	octo(m, 0.9, 0.9, CFrame.new(2.9, 6.6, -0.5), rgb(230, 230, 240))
	octo(m, 1.0, 1.0, CFrame.new(-2.8, 3.5, -0.8), rgb(255, 150, 80))
	block(m, Vector3.new(2.0, 0.08, 2.0), cf(-2.8, 4.0, -0.8, 20, 30, 0), rgb(255, 220, 140))
end

function builders.RoseBush(m)
	soil(m, 4)
	crown(m, Vector3.new(0, 1.3, 0), 1.6, { LEAF, LEAF_DARK }, 11)
	for i, spot in
		{ { -0.9, 2.2, -1.0 }, { 0.8, 2.5, -0.8 }, { 0.1, 2.9, -0.2 }, { -0.4, 1.7, -1.4 }, { 1.2, 1.7, -1.1 } }
	do
		for k = 0, 2 do
			block(
				m,
				Vector3.new(0.6 - k * 0.15, 0.25, 0.6 - k * 0.15),
				cf(spot[1], spot[2] + k * 0.18, spot[3], 0, i * 20 + k * 30, 0),
				rgb(210, 30, 60)
			)
		end
		glow(m, Vector3.new(0.12, 0.12, 0.12), cf(spot[1], spot[2] + 0.55, spot[3]), rgb(255, 120, 150))
	end
end

function builders.Cactus(m)
	-- A saguaro in a clay pot, with spines and a glowing pink flower.
	octo(m, 2.6, 1.2, CFrame.new(), rgb(200, 110, 70))
	octo(m, 2.9, 0.3, CFrame.new(0, 1.2, 0), rgb(220, 128, 84))
	local green = rgb(70, 145, 85)
	block(m, Vector3.new(1.1, 4.2, 1.1), cf(0, 3.3, 0), green)
	for _, side in { -1, 1 } do
		local y = if side < 0 then 3.0 else 3.6
		block(m, Vector3.new(0.9, 0.7, 0.8), cf(side * 0.9, y, 0), green)
		block(m, Vector3.new(0.7, 1.5, 0.7), cf(side * 1.25, y + 0.9, 0), green)
	end
	for i = 0, 9 do
		block(m, Vector3.new(0.04, 0.04, 0.3), cf(((i % 3) - 1) * 0.35, 1.8 + i * 0.4, -0.65), rgb(245, 240, 220))
	end
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		block(
			m,
			Vector3.new(0.3, 0.15, 0.3),
			cf(math.cos(a) * 0.25, 5.5, math.sin(a) * 0.25, 0, k * 72, 20),
			rgb(255, 110, 170)
		)
	end
	glow(m, Vector3.new(0.22, 0.22, 0.22), cf(0, 5.6, 0), rgb(255, 200, 230))
end

function builders.AppleTree(m)
	trunk(m, 3.6, 0.9)
	crown(m, Vector3.new(0, 4.8, 0), 2.0, { LEAF, LEAF_DARK, rgb(80, 170, 80) }, 12)
	for i, spot in
		{ { -1.2, 4.2, -1.4 }, { 1.0, 5.0, -1.5 }, { 0.2, 3.9, -1.9 }, { -1.6, 5.4, -0.6 }, { 1.7, 4.3, -0.4 } }
	do
		block(m, Vector3.new(0.55, 0.5, 0.55), cf(spot[1], spot[2], spot[3], 0, i * 25, 0), rgb(220, 40, 50))
		block(m, Vector3.new(0.1, 0.25, 0.1), cf(spot[1], spot[2] + 0.35, spot[3]), TRUNK)
	end
end

function PlantModel.build(itemId: string): Model
	local item = Items.byId[itemId]
	local model = Instance.new("Model")
	model.Name = itemId
	model:SetAttribute("Item", itemId)
	Bricks.crafted(model)
	local builder = item and builders[item.model]
	if builder then
		builder(model)
	end
	-- Stand it on its base. Roblox puts a new model's pivot in the middle of its parts, which
	-- would sink it halfway into whatever it's put on.
	model.WorldPivot = CFrame.identity
	return model
end

return PlantModel
