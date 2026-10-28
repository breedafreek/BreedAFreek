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

-- A stem from the ground up to `top`, with a leaf on each side.
local function stem(m, x: number, z: number, top: number, lean: number?)
	block(m, Vector3.new(0.18, top, 0.18), cf(x, top / 2, z, 0, 0, lean or 0), STEM)
	for _, side in { -1, 1 } do
		wedge(m, Vector3.new(0.12, 0.35, 0.9), cf(x + side * 0.4, top * 0.4, z, 0, 90 * side, 35 * side), LEAF)
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

function builders.Daisy(m)
	soil(m, 3.2)
	for i, spot in { { -0.7, 2.2, 0.1, -8 }, { 0.6, 2.7, -0.2, 6 }, { 0.1, 1.8, 0.7, 0 } } do
		stem(m, spot[1], spot[3], spot[2], spot[4])
		flower(
			m,
			cf(spot[1] - spot[4] * 0.02, spot[2], spot[3], -20, i * 15, 0),
			1.2,
			rgb(245, 245, 240),
			rgb(255, 210, 50),
			8,
			i == 2
		)
	end
end

function builders.Tulip(m)
	soil(m, 3.2)
	local colors = { rgb(235, 60, 80), rgb(255, 200, 50), rgb(240, 110, 180) }
	for i, spot in { { -0.8, 2.4, 0 }, { 0.15, 2.9, -0.3 }, { 0.9, 2.2, 0.4 } } do
		stem(m, spot[1], spot[3], spot[2])
		for k = 0, 3 do
			local a = k * 90 + 45
			wedge(
				m,
				Vector3.new(0.12, 0.85, 0.5),
				cf(spot[1], spot[2] + 0.4, spot[3], 0, a, 0)
					* CFrame.new(0, 0, 0.18)
					* CFrame.Angles(math.rad(-10), 0, 0),
				colors[i]
			)
		end
		glow(m, Vector3.new(0.22, 0.22, 0.22), cf(spot[1], spot[2] + 0.35, spot[3]), rgb(255, 230, 120))
	end
end

function builders.Sunflower(m)
	soil(m, 3.4)
	block(m, Vector3.new(0.35, 5.2, 0.35), cf(0, 2.6, 0), STEM)
	for i, y in { 1.4, 2.6, 3.6 } do
		local side = if i % 2 == 0 then -1 else 1
		wedge(m, Vector3.new(0.14, 0.6, 1.6), cf(side * 0.8, y, 0, 0, 90 * side, 30 * side), LEAF)
	end
	local head = cf(0, 5.7, -0.2, -15, 0, 0)
	for i = 0, 13 do
		local a = i / 14 * math.pi * 2
		wedge(
			m,
			Vector3.new(0.14, 0.9, 0.45),
			head * CFrame.Angles(0, 0, a) * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, math.pi / 2, 0),
			rgb(255, 200, 40)
		)
	end
	block(m, Vector3.new(1.6, 1.6, 0.3), head, rgb(110, 70, 40))
	for i = 0, 4 do
		glow(
			m,
			Vector3.new(0.14, 0.14, 0.06),
			head * CFrame.new((i - 2) * 0.28, (i % 2 - 0.5) * 0.4, -0.17),
			rgb(255, 170, 40)
		)
	end
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

function builders.Pumpkin(m)
	-- A giant pumpkin of ribbed slabs with a carved, glowing jack-o'-lantern face.
	local orange, deep = rgb(240, 130, 40), rgb(205, 100, 28)
	for i = 0, 7 do
		local a = i * 45
		block(
			m,
			Vector3.new(1.6, 2.6, 0.9),
			cf(0, 1.4, 0, 0, a, 0) * CFrame.new(0, 0, 1.4),
			if i % 2 == 0 then orange else deep
		)
	end
	octo(m, 3.2, 2.4, CFrame.new(0, 0.2, 0), orange)
	block(m, Vector3.new(0.4, 0.9, 0.4), cf(0.1, 3.0, 0.1, 0, 0, 12), rgb(90, 120, 50))
	wedge(m, Vector3.new(0.1, 0.5, 1.4), cf(0.8, 2.7, 0.6, 0, 40, 30), LEAF)
	-- The face.
	for _, side in { -1, 1 } do
		wedge(m, Vector3.new(0.6, 0.55, 0.1), cf(side * 0.6, 1.9, -1.86), rgb(255, 200, 60), M.Neon)
	end
	glow(m, Vector3.new(1.4, 0.32, 0.1), cf(0, 1.05, -1.86), rgb(255, 200, 60))
	for i = 0, 2 do
		block(m, Vector3.new(0.2, 0.2, 0.12), cf(-0.4 + i * 0.4, 1.25, -1.88), deep)
	end
end

function builders.Blossom(m)
	trunk(m, 3.4, 0.8, rgb(100, 66, 50))
	block(m, Vector3.new(0.4, 1.6, 0.4), cf(0.7, 3.6, 0, 0, 0, -35), rgb(100, 66, 50))
	crown(m, Vector3.new(0, 4.6, 0), 2.1, { rgb(255, 170, 205), rgb(250, 140, 190), rgb(255, 205, 225) }, 12)
	for i = 0, 7 do
		local a = i * 0.8
		block(
			m,
			Vector3.new(0.18, 0.05, 0.18),
			cf(math.cos(a) * (1.5 + i * 0.2), 0.5 + (i % 4) * 0.8, math.sin(a) * 1.8, 20, i * 40, 30),
			rgb(255, 190, 215)
		)
	end
	for i = 0, 3 do
		glow(
			m,
			Vector3.new(0.2, 0.2, 0.2),
			cf(math.cos(i * 1.6) * 1.6, 5.2 + (i % 2) * 0.6, math.sin(i * 1.6) * 1.6),
			rgb(255, 230, 240)
		)
	end
end

function builders.CrystalFlower(m)
	-- Crystal shards round a glowing flower on a crystal stem.
	octo(m, 2.8, 0.4, CFrame.new(), rgb(90, 80, 120))
	for i = 0, 6 do
		local a = i / 7 * math.pi * 2
		local h = 0.9 + (i % 3) * 0.45
		local p = block(
			m,
			Vector3.new(0.4, h, 0.4),
			cf(math.cos(a) * 1.0, 0.4 + h / 2, math.sin(a) * 1.0, math.sin(a) * 20, i * 30, -math.cos(a) * 20),
			rgb(180, 140, 255),
			M.Glass
		)
		p.Transparency = 0.2
	end
	block(m, Vector3.new(0.22, 3.2, 0.22), cf(0, 2.0, 0), rgb(150, 220, 255), M.Glass)
	local head = cf(0, 3.8, -0.1, -15, 0, 0)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		wedge(
			m,
			Vector3.new(0.12, 1.0, 0.5),
			head * CFrame.Angles(0, 0, a) * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, math.pi / 2, 0),
			rgb(150, 220, 255),
			M.Glass
		)
	end
	glow(m, Vector3.new(0.6, 0.6, 0.6), head * CFrame.Angles(0, 0, math.pi / 4), rgb(200, 120, 255))
end

function builders.GlowShroom(m)
	-- A cluster of mushrooms with layered purple caps and glowing spots.
	soil(m, 3.6)
	for i, spec in { { 0, 0, 2.6, 2.2 }, { -1.2, 0.6, 1.6, 1.4 }, { 1.1, -0.5, 1.2, 1.1 } } do
		local x, z, h, s = spec[1], spec[2], spec[3], spec[4]
		block(m, Vector3.new(s * 0.32, h, s * 0.32), cf(x, h / 2, z), rgb(235, 230, 215))
		octo(m, s, s * 0.3, CFrame.new(x, h, z), rgb(130, 70, 200))
		octo(m, s * 0.7, s * 0.25, CFrame.new(x, h + s * 0.3, z), rgb(110, 55, 180))
		for k = 0, 3 do
			local a = k / 4 * math.pi * 2 + i
			glow(
				m,
				Vector3.new(0.18, 0.08, 0.18),
				cf(x + math.cos(a) * s * 0.3, h + s * 0.31, z + math.sin(a) * s * 0.3),
				rgb(110, 255, 230)
			)
		end
		glow(m, Vector3.new(0.2, 0.06, 0.2), cf(x, h + s * 0.56, z), rgb(110, 255, 230))
	end
end

function builders.MoneyTree(m)
	-- A tree in a gold pot with a crown of green bills and gold coins.
	octo(m, 2.6, 1.0, CFrame.new(), GOLD, M.Metal)
	trunk(m, 3.4, 0.7)
	crown(m, Vector3.new(0, 4.6, 0), 1.9, { rgb(80, 170, 90), rgb(60, 140, 75) }, 10)
	for i = 0, 9 do
		local a = i * 0.63
		local y = 3.8 + (i % 3) * 0.8
		block(
			m,
			Vector3.new(0.8, 0.04, 0.4),
			cf(math.cos(a) * 1.9, y, math.sin(a) * 1.9, 0, math.deg(a), 25),
			rgb(110, 200, 100)
		)
		glow(m, Vector3.new(0.12, 0.05, 0.12), cf(math.cos(a) * 1.9, y + 0.03, math.sin(a) * 1.9), rgb(200, 255, 180))
	end
	for i = 0, 5 do
		local a = i * 1.05 + 0.3
		block(
			m,
			Vector3.new(0.4, 0.4, 0.08),
			cf(math.cos(a) * 1.5, 4.0 + (i % 2) * 1.2, math.sin(a) * 1.5, 0, math.deg(a), 0),
			GOLD,
			M.Metal
		)
	end
end

function builders.RainbowTree(m)
	-- A tree whose crown is layered in every colour, with a glowing star on top.
	trunk(m, 3.0, 0.8, rgb(150, 110, 200))
	for i, color in Bricks.RAINBOW do
		local s = 3.6 - i * 0.45
		octo(m, s, 0.55, CFrame.new(0, 2.8 + i * 0.55, 0) * CFrame.Angles(0, math.rad(i * 12), 0), color)
	end
	glow(m, Vector3.new(0.7, 0.7, 0.2), cf(0, 6.9, 0, 0, 0, 45), rgb(255, 245, 200))
	glow(m, Vector3.new(0.7, 0.7, 0.2), cf(0, 6.9, 0, 0, 90, 45), rgb(255, 245, 200))
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
