-- Yard items in the crafted look (low-poly, smooth, no studs; see Lego): built from blocks
-- and wedges, some set at angles, in muted main colours with glowing bits and gold trims.
-- YardModel.build(itemId) returns a model standing on its pivot (the middle of its
-- footprint, front facing -Z) that fits a yard spot (about 11 x 11 studs).

local Bricks = require(script.Parent.Bricks)
local Items = require(script.Parent.Items)

local YardModel = {}

local rgb, block, post, wedge, glow, octo, ring =
	Bricks.rgb, Bricks.block, Bricks.post, Bricks.wedge, Bricks.glow, Bricks.octo, Bricks.ring
local M = Enum.Material
local WOOD = rgb(160, 108, 66)
local WOOD_DARK = rgb(116, 76, 46)
local DARK = rgb(44, 44, 54)
local STONE = rgb(150, 150, 160)
local WATER = rgb(60, 170, 235)
local GOLD = rgb(255, 200, 60)

local function cf(x, y, z, rx, ry, rz)
	return CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
end

-- Water: a see-through slab with glowing ripple lines on top.
local function water(m, size: Vector3, at: CFrame, ripples: number?)
	local p = block(m, size, at, WATER, M.Glass)
	p.Transparency = 0.25
	for i = 1, ripples or 3 do
		local z = (i / ((ripples or 3) + 1) - 0.5) * size.Z
		glow(
			m,
			Vector3.new(size.X * 0.5, 0.05, 0.08),
			at * CFrame.new((i % 2 - 0.5) * size.X * 0.2, size.Y / 2, z),
			rgb(170, 235, 255)
		)
	end
end

local builders = {}

function builders.Gnome(m)
	-- A garden gnome on a stone plinth, holding a glowing lantern.
	octo(m, 3.2, 0.5, CFrame.new(), STONE)
	octo(m, 2.6, 0.3, CFrame.new(0, 0.5, 0), rgb(120, 190, 90))
	for _, x in { -0.35, 0.35 } do
		block(m, Vector3.new(0.55, 0.4, 0.8), cf(x, 1.0, -0.1), DARK)
	end
	block(m, Vector3.new(1.6, 1.1, 1.3), cf(0, 1.75, 0), rgb(60, 110, 210))
	block(m, Vector3.new(1.3, 0.8, 1.1), cf(0, 2.65, 0), rgb(70, 125, 225))
	block(m, Vector3.new(1.65, 0.22, 1.35), cf(0, 2.2, 0), rgb(70, 50, 40))
	block(m, Vector3.new(0.35, 0.3, 0.1), cf(0, 2.2, -0.7), GOLD, M.Metal)
	block(m, Vector3.new(1.2, 1.0, 1.0), cf(0, 3.5, 0), rgb(245, 205, 175))
	wedge(m, Vector3.new(1.3, 1.1, 0.5), cf(0, 2.75, -0.62, 0, 180, 0), rgb(240, 240, 235))
	block(m, Vector3.new(1.25, 0.35, 0.45), cf(0, 3.3, -0.55), rgb(240, 240, 235))
	block(m, Vector3.new(0.32, 0.3, 0.3), cf(0, 3.55, -0.62), rgb(240, 140, 130))
	for _, x in { -0.28, 0.28 } do
		glow(m, Vector3.new(0.16, 0.16, 0.06), cf(x, 3.75, -0.52), rgb(120, 220, 255))
	end
	for i, s in { 1.35, 1.05, 0.75, 0.45 } do
		block(m, Vector3.new(s, 0.45, s), cf(0.05 * i, 4.15 + i * 0.36, 0.04 * i, 0, 15 * i, -5 * i), rgb(220, 50, 60))
	end
	glow(m, Vector3.new(0.22, 0.22, 0.22), cf(0.25, 5.75, 0.2), GOLD)
	-- The lantern.
	block(m, Vector3.new(0.3, 0.9, 0.3), cf(0.95, 2.1, -0.4, 0, 0, -20), rgb(70, 125, 225))
	block(m, Vector3.new(0.5, 0.6, 0.5), cf(1.2, 1.5, -0.55), DARK)
	glow(m, Vector3.new(0.36, 0.42, 0.36), cf(1.2, 1.5, -0.55), rgb(255, 210, 90))
end

function builders.Lemonade(m)
	-- A wooden lemonade stand with a striped awning, lemons and a glowing jug.
	block(m, Vector3.new(6, 0.3, 3), cf(0, 0.15, 0), WOOD_DARK)
	for i = 0, 3 do
		block(
			m,
			Vector3.new(6.2, 0.5, 0.25),
			cf(0, 0.6 + i * 0.55, -1.4, 0, 0, (i % 2 - 0.5) * 2),
			if i % 2 == 0 then WOOD else WOOD_DARK
		)
	end
	block(m, Vector3.new(6.4, 0.25, 3.2), cf(0, 2.75, 0), WOOD)
	for _, x in { -2.9, 2.9 } do
		block(m, Vector3.new(0.35, 5.2, 0.35), cf(x, 2.6, 1.2), WOOD_DARK)
		block(m, Vector3.new(0.35, 2.8, 0.35), cf(x, 1.4, -1.4), WOOD_DARK)
	end
	for i = 0, 7 do
		wedge(
			m,
			Vector3.new(0.8, 0.9, 2.2),
			cf(-2.8 + i * 0.8, 5.3, -0.2, 0, 180, 0),
			if i % 2 == 0 then rgb(255, 215, 60) else rgb(245, 245, 240)
		)
	end
	glow(m, Vector3.new(6.4, 0.08, 0.1), cf(0, 4.88, -1.32), rgb(255, 230, 90))
	-- A sign board, lemons and the jug.
	block(m, Vector3.new(3.4, 0.9, 0.15), cf(0, 1.45, -1.62), rgb(255, 230, 120))
	glow(m, Vector3.new(3.0, 0.1, 0.06), cf(0, 1.45, -1.72), rgb(255, 190, 40))
	for i, spot in { { -2, 0.3 }, { -1.5, -0.4 }, { 1.8, 0.2 } } do
		block(m, Vector3.new(0.5, 0.45, 0.5), cf(spot[1], 3.1, spot[2], 0, i * 30, 10), rgb(255, 220, 50))
	end
	block(m, Vector3.new(0.9, 1.1, 0.9), cf(0.4, 3.45, 0), rgb(220, 240, 255), M.Glass)
	glow(m, Vector3.new(0.75, 0.7, 0.75), cf(0.4, 3.3, 0), rgb(255, 235, 90))
end

function builders.Grill(m)
	-- A kettle grill with the lid up, glowing coals and sausages, and a side tray.
	for _, a in { 0, 120, 240 } do
		block(m, Vector3.new(0.25, 2.2, 0.25), CFrame.Angles(0, math.rad(a), 0) * cf(0, 1.0, 0.9, 12, 0, 0), DARK)
	end
	octo(m, 3.0, 0.9, CFrame.new(0, 1.9, 0), rgb(190, 40, 45))
	octo(m, 2.4, 0.3, CFrame.new(0, 1.6, 0), rgb(150, 30, 36))
	glow(m, Vector3.new(2.2, 0.12, 2.2), cf(0, 2.72, 0), rgb(255, 120, 30))
	for i = -3, 3 do
		block(m, Vector3.new(2.5, 0.06, 0.08), cf(0, 2.86, i * 0.35), rgb(70, 70, 80), M.Metal)
	end
	for i, x in { -0.6, 0, 0.6 } do
		block(m, Vector3.new(0.3, 0.3, 1.2), cf(x, 3.0, 0, 0, i * 10, 0), rgb(170, 70, 50))
	end
	-- The lid, tipped up behind.
	block(m, Vector3.new(2.9, 0.4, 2.9), cf(0, 3.6, 1.6, -65, 0, 0), rgb(190, 40, 45))
	block(m, Vector3.new(0.8, 0.2, 0.2), cf(0, 4.5, 1.3, -65, 0, 0), DARK)
	block(m, Vector3.new(1.4, 0.15, 1.4), cf(2.2, 2.4, 0), WOOD)
	block(m, Vector3.new(0.15, 0.6, 0.15), cf(2.2, 2.1, 0.5), DARK)
end

function builders.Swing(m)
	-- A wooden swing set: A-frame legs, a top bar with a glowing strip, two swings.
	for _, x in { -3.3, 3.3 } do
		for _, z in { -1, 1 } do
			block(m, Vector3.new(0.4, 5.6, 0.4), cf(x, 2.7, z * 0.85, z * -17, 0, 0), WOOD)
		end
		block(m, Vector3.new(0.3, 0.3, 2.2), cf(x, 1.4, 0), WOOD_DARK)
	end
	block(m, Vector3.new(7.2, 0.45, 0.45), cf(0, 5.4, 0), WOOD_DARK)
	glow(m, Vector3.new(6.6, 0.08, 0.08), cf(0, 5.66, 0), rgb(255, 200, 60))
	for i, x in { -1.5, 1.5 } do
		for _, dx in { -0.45, 0.45 } do
			block(m, Vector3.new(0.07, 3.8, 0.07), cf(x + dx, 3.4, 0), rgb(90, 90, 100), M.Metal)
		end
		block(m, Vector3.new(1.2, 0.18, 0.6), cf(x, 1.5, 0), if i == 1 then rgb(220, 60, 60) else rgb(60, 140, 230))
	end
end

function builders.Trampoline(m)
	-- A round trampoline: a black mat on a padded blue rim with a glowing edge, on legs.
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		block(m, Vector3.new(0.25, 1.4, 0.25), CFrame.new(math.cos(a) * 3.6, 0.7, math.sin(a) * 3.6), DARK)
	end
	octo(m, 7.0, 0.25, CFrame.new(0, 1.3, 0), rgb(36, 36, 44))
	ring(m, 7.6, 0.7, 0.35, CFrame.new(0, 1.5, 0), rgb(50, 120, 220), nil, 12)
	ring(m, 6.8, 0.1, 0.06, CFrame.new(0, 1.57, 0), rgb(110, 220, 255), M.Neon, 12)
	glow(m, Vector3.new(1.2, 0.05, 1.2), cf(0, 1.45, 0, 0, 45, 0), rgb(110, 220, 255))
end

function builders.KiddiePool(m)
	-- An inflatable paddling pool: a ring of fat coloured tubes, water and a rubber duck.
	local colors = { rgb(255, 90, 120), rgb(255, 210, 60), rgb(80, 200, 255), rgb(120, 220, 110) }
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		block(m, Vector3.new(2.6, 1.1, 1.0), CFrame.Angles(0, -a, 0) * cf(0, 0.55, 2.9), colors[i % 4 + 1])
	end
	octo(m, 5.6, 0.15, CFrame.new(0, 0, 0), rgb(70, 160, 220))
	water(m, Vector3.new(4.6, 0.6, 4.6), CFrame.new(0, 0.4, 0) * CFrame.Angles(0, math.rad(22), 0), 3)
	-- The duck.
	block(m, Vector3.new(0.8, 0.5, 1.0), cf(0.8, 0.95, -0.4, 0, 30, 0), rgb(255, 220, 50))
	block(m, Vector3.new(0.5, 0.5, 0.5), cf(0.6, 1.4, -0.75, 0, 30, 0), rgb(255, 220, 50))
	block(m, Vector3.new(0.3, 0.15, 0.3), cf(0.48, 1.35, -1.0, 0, 30, 0), rgb(255, 140, 40))
end

function builders.HotTub(m)
	-- A square wooden hot tub with a gold rim, glowing water, bubbles and a step.
	for i = 0, 3 do
		local a = i * 90
		for j = 0, 2 do
			block(
				m,
				Vector3.new(6.2, 0.6, 0.45),
				CFrame.Angles(0, math.rad(a), 0) * cf(0, 0.35 + j * 0.62, 2.9, 0, 0, (j % 2 - 0.5) * 1.5),
				if j % 2 == 0 then WOOD else WOOD_DARK
			)
		end
		block(m, Vector3.new(6.4, 0.2, 0.6), CFrame.Angles(0, math.rad(a), 0) * cf(0, 2.15, 2.95), GOLD, M.Metal)
	end
	water(m, Vector3.new(5.4, 0.4, 5.4), CFrame.new(0, 1.75, 0), 3)
	glow(m, Vector3.new(5.2, 0.1, 5.2), cf(0, 1.0, 0), rgb(80, 230, 255))
	for i = 1, 7 do
		block(
			m,
			Vector3.new(0.2, 0.2, 0.2),
			cf(math.sin(i * 2.1) * 2, 2.05, math.cos(i * 1.7) * 2, 0, i * 20, 0),
			rgb(240, 250, 255)
		)
	end
	block(m, Vector3.new(2.4, 0.6, 1.0), cf(0, 0.3, -3.6), WOOD_DARK)
end

function builders.Fountain(m)
	-- A tiered stone fountain: a wide pool, two bowls, glowing water spouts and a gold top.
	octo(m, 8.0, 0.9, CFrame.new(), STONE)
	water(m, Vector3.new(6.2, 0.3, 6.2), CFrame.new(0, 0.85, 0) * CFrame.Angles(0, math.rad(22), 0), 4)
	ring(m, 8.0, 0.6, 0.35, CFrame.new(0, 1.05, 0), rgb(175, 175, 185), nil, 8)
	block(m, Vector3.new(1.0, 2.6, 1.0), cf(0, 2.2, 0), STONE)
	octo(m, 3.6, 0.5, CFrame.new(0, 3.3, 0), rgb(175, 175, 185))
	water(m, Vector3.new(2.6, 0.2, 2.6), CFrame.new(0, 3.75, 0), 2)
	block(m, Vector3.new(0.6, 1.4, 0.6), cf(0, 4.4, 0), STONE)
	octo(m, 1.8, 0.35, CFrame.new(0, 5.0, 0), rgb(175, 175, 185))
	glow(m, Vector3.new(0.3, 1.2, 0.3), cf(0, 5.9, 0), rgb(130, 220, 255))
	block(m, Vector3.new(0.5, 0.5, 0.5), cf(0, 6.6, 0, 45, 45, 0), GOLD, M.Metal)
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + math.pi / 4
		glow(
			m,
			Vector3.new(0.18, 1.2, 0.18),
			CFrame.new(math.cos(a) * 1.5, 2.7, math.sin(a) * 1.5)
				* CFrame.Angles(math.sin(a) * 0.5, 0, -math.cos(a) * 0.5),
			rgb(130, 220, 255)
		)
	end
end

function builders.Treehouse(m)
	-- A treehouse: a chunky trunk, a plank platform, a little house with a peaked roof and a
	-- glowing window, a ladder and leafy blocks round the top.
	for i = 0, 3 do
		block(
			m,
			Vector3.new(1.4 - i * 0.05, 1.5, 1.4 - i * 0.05),
			cf(0, 0.75 + i * 1.5, 0, 0, i * 12, 0),
			if i % 2 == 0 then WOOD_DARK else rgb(128, 86, 52)
		)
	end
	block(m, Vector3.new(6.2, 0.35, 5.6), cf(0, 5.6, 0), WOOD)
	block(m, Vector3.new(4.4, 2.8, 3.6), cf(0, 7.2, 0.4), rgb(200, 150, 90))
	for _, side in { -1, 1 } do
		wedge(
			m,
			Vector3.new(4.0, 1.8, 2.5),
			cf(0, 9.5, 0.4 + side * 1.2, 0, if side < 0 then 0 else 180, 0),
			rgb(200, 60, 60)
		)
	end
	block(m, Vector3.new(1.2, 1.0, 0.1), cf(0, 7.4, -1.42), DARK)
	glow(m, Vector3.new(1.0, 0.8, 0.08), cf(0, 7.4, -1.46), rgb(255, 200, 90))
	for i = 0, 4 do
		block(m, Vector3.new(1.1, 0.15, 0.2), cf(1.6, 1.0 + i * 1.0, -1.0), WOOD_DARK)
	end
	for _, x in { 1.05, 2.15 } do
		block(m, Vector3.new(0.18, 5.4, 0.18), cf(x, 2.9, -1.0), WOOD)
	end
	for i, spot in { { -2.6, 8.2, 1.8 }, { 2.7, 8.6, 1.5 }, { -2.2, 10.2, 0.8 }, { 1.8, 10.6, 1.6 }, { 0, 11.0, 2.2 } } do
		block(
			m,
			Vector3.new(2.4, 1.8, 2.2),
			cf(spot[1], spot[2], spot[3], 0, i * 23, i * 7),
			if i % 2 == 0 then rgb(70, 150, 70) else rgb(90, 175, 80)
		)
	end
end

function builders.SportsCar(m)
	-- A low red sports car: wedge nose and tail, dark glass, glowing headlights, underglow,
	-- a spoiler and gold rims.
	local red, deep = rgb(210, 40, 45), rgb(150, 26, 34)
	block(m, Vector3.new(3.6, 0.9, 7.4), cf(0, 1.15, 0), red)
	wedge(m, Vector3.new(3.6, 0.6, 2.2), cf(0, 1.9, -2.6), red)
	block(m, Vector3.new(3.2, 0.9, 2.6), cf(0, 2.05, 0.4), deep)
	wedge(m, Vector3.new(3.0, 0.85, 1.4), cf(0, 2.05, -1.55), rgb(30, 40, 60), M.Glass)
	block(m, Vector3.new(3.25, 0.6, 2.2), cf(0, 2.1, 0.4), rgb(30, 40, 60), M.Glass)
	wedge(m, Vector3.new(3.4, 0.6, 1.6), cf(0, 1.9, 2.5, 0, 180, 0), red)
	block(m, Vector3.new(3.4, 0.15, 0.8), cf(0, 2.65, 3.4), DARK)
	for _, x in { -1.3, 1.3 } do
		block(m, Vector3.new(0.15, 0.6, 0.15), cf(x, 2.3, 3.4), DARK)
		glow(m, Vector3.new(0.8, 0.25, 0.08), cf(x, 1.3, -3.72), rgb(255, 250, 220))
		glow(m, Vector3.new(0.8, 0.2, 0.08), cf(x, 1.3, 3.72), rgb(255, 40, 40))
	end
	for _, x in { -1.8, 1.8 } do
		for _, z in { -2.3, 2.3 } do
			local wheel = post(
				m,
				0.7,
				1.5,
				CFrame.new(x, 0.75, z) * CFrame.Angles(0, 0, math.pi / 2) * CFrame.new(0, -0.35, 0),
				DARK
			)
			wheel.Shape = Enum.PartType.Cylinder
			post(
				m,
				0.75,
				0.8,
				CFrame.new(x, 0.75, z) * CFrame.Angles(0, 0, math.pi / 2) * CFrame.new(0, -0.375, 0),
				GOLD,
				M.Metal
			)
		end
	end
	glow(m, Vector3.new(3.0, 0.08, 6.6), cf(0, 0.55, 0), rgb(255, 60, 200))
end

function builders.Pool(m)
	-- A swimming pool: a tiled deck, glowing lights in the walls, water, a diving board, a
	-- ladder and a float ring.
	block(m, Vector3.new(10.4, 0.5, 9.0), cf(0, 0.25, 0), rgb(235, 230, 215))
	for i = 0, 6 do
		block(m, Vector3.new(0.08, 0.04, 9.0), cf(-4.5 + i * 1.5, 0.52, 0), rgb(205, 200, 185))
	end
	block(m, Vector3.new(8.4, 0.2, 7.0), cf(0, 0.45, 0), rgb(60, 140, 200))
	water(m, Vector3.new(8.2, 0.25, 6.8), CFrame.new(0, 0.6, 0), 4)
	for _, x in { -4.15, 4.15 } do
		for _, z in { -2, 0, 2 } do
			glow(m, Vector3.new(0.08, 0.2, 0.6), cf(x, 0.55, z), rgb(110, 230, 255))
		end
	end
	block(m, Vector3.new(1.2, 0.25, 4.0), cf(0, 1.2, 4.6), rgb(60, 140, 230))
	block(m, Vector3.new(1.0, 0.8, 0.6), cf(0, 0.8, 5.8), rgb(200, 200, 210))
	for _, x in { 3.1, 3.9 } do
		block(m, Vector3.new(0.1, 1.6, 0.1), cf(x, 1.3, -3.6), rgb(200, 200, 210), M.Metal)
	end
	ring(m, 1.6, 0.4, 0.35, CFrame.new(-1.8, 0.85, -1.2), rgb(255, 80, 90), nil, 8)
end

function builders.Rocket(m)
	-- A rocket ship on its launch pad: a white and red body of stacked octagons, fins, a
	-- glowing round window, a pointed nose, a glowing flame and a rainbow-lit pad.
	octo(m, 7.5, 0.4, CFrame.new(), rgb(120, 120, 135))
	for i, color in Bricks.RAINBOW do
		glow(m, Vector3.new(0.6, 0.06, 0.9), cf(-3.0 + i * 0.86, 0.42, -3.0), color)
	end
	glow(m, Vector3.new(1.2, 0.8, 1.2), cf(0, 0.8, 0, 0, 45, 0), rgb(255, 150, 30))
	for i = 0, 5 do
		local width = 2.6 - math.max(0, i - 3) * 0.5
		octo(
			m,
			width,
			1.5,
			CFrame.new(0, 1.2 + i * 1.5, 0),
			if i % 3 == 1 then rgb(220, 50, 60) else rgb(240, 240, 245)
		)
	end
	for i, s in { 1.6, 1.1, 0.6 } do
		octo(m, s, 0.7, CFrame.new(0, 10.2 + i * 0.6, 0), rgb(220, 50, 60))
	end
	glow(m, Vector3.new(0.3, 0.4, 0.3), cf(0, 12.4, 0), GOLD)
	for i = 0, 3 do
		local a = i * 90 + 45
		wedge(
			m,
			Vector3.new(0.3, 2.2, 1.6),
			CFrame.Angles(0, math.rad(a), 0) * cf(0, 2.3, 1.7, 0, 180, 0),
			rgb(220, 50, 60)
		)
	end
	block(m, Vector3.new(1.1, 1.1, 0.15), cf(0, 7.0, -1.1, 0, 0, 45), rgb(200, 200, 210), M.Metal)
	glow(m, Vector3.new(0.8, 0.8, 0.1), cf(0, 7.0, -1.16, 0, 0, 45), rgb(110, 230, 255))
end

function YardModel.build(itemId: string): Model
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

return YardModel
