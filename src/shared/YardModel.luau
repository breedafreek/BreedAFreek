-- Yard items in the crafted look (low-poly, smooth, no studs; see Lego): built from blocks
-- and wedges, some set at angles, in muted main colours with glowing bits and gold trims.
-- YardModel.build(itemId) returns a model standing on its pivot (the middle of its
-- footprint, front facing -Z) that fits a yard spot (about 11 x 11 studs).

local Bricks = require(script.Parent.Bricks)
local Items = require(script.Parent.Items)

local YardModel = {}

local rgb, block, wedge, glow, octo, ring =
	Bricks.rgb, Bricks.block, Bricks.wedge, Bricks.glow, Bricks.octo, Bricks.ring
local M = Enum.Material
local WOOD = rgb(160, 108, 66)
local WOOD_DARK = rgb(116, 76, 46)
local DARK = rgb(44, 44, 54)
local STONE = rgb(150, 150, 160)
local WATER = rgb(60, 170, 235)
local GOLD = rgb(255, 200, 60)
local WHITE_PAINT = rgb(245, 245, 240)
local SAND = rgb(240, 215, 150)
local SAND_DARK = rgb(215, 185, 120)

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

-- A wheel lying on its side at (x, y, z): a dark tyre and a coloured hub.
local function wheel(m, x: number, y: number, z: number, diameter: number, hub: Color3)
	Bricks.rod(m, 0.7, diameter, cf(x, y, z), DARK)
	Bricks.rod(m, 0.75, diameter * 0.55, cf(x, y, z), hub, M.Metal)
end

--------------------------------------------------------------------------------
-- The Neighborhood
--------------------------------------------------------------------------------

function builders.RedMailbox(m)
	-- A classic red mailbox on a wooden post: a rounded box of stacked slabs, a raised flag,
	-- a gold house number and a glowing letter peeking out.
	block(m, Vector3.new(2.2, 0.3, 2.2), cf(0, 0.15, 0), WOOD_DARK)
	block(m, Vector3.new(0.7, 3.4, 0.7), cf(0, 2.0, 0, 0, 8, 0), WOOD)
	local red, deep = rgb(220, 40, 45), rgb(170, 28, 34)
	block(m, Vector3.new(1.9, 1.3, 3.0), cf(0, 4.25, 0), red)
	block(m, Vector3.new(1.5, 0.3, 3.0), cf(0, 5.05, 0), red)
	block(m, Vector3.new(1.0, 0.2, 3.0), cf(0, 5.3, 0), deep)
	block(m, Vector3.new(1.95, 1.75, 0.15), cf(0, 4.45, -1.55), deep)
	block(m, Vector3.new(0.35, 0.25, 0.15), cf(0, 4.4, -1.65), GOLD, M.Metal)
	block(m, Vector3.new(0.12, 1.6, 0.12), cf(1.05, 5.2, 0.6), DARK)
	block(m, Vector3.new(0.12, 0.6, 0.8), cf(1.05, 5.75, 0.25), rgb(255, 210, 40))
	glow(m, Vector3.new(1.2, 0.1, 0.8), cf(0, 4.95, -1.7, -20, 0, 0), rgb(255, 255, 230))
	for i = 0, 2 do
		block(m, Vector3.new(0.3, 0.45, 0.06), cf(-0.55 + i * 0.4, 3.85, -1.63), GOLD, M.Metal)
	end
end

function builders.GardenBench(m)
	-- A park bench: green cast-iron sides with scrolls, wooden slats on the seat and back,
	-- gold bolts and a glowing lamp post beside it.
	local iron = rgb(40, 110, 70)
	for _, x in { -2.4, 2.4 } do
		block(m, Vector3.new(0.35, 2.0, 0.35), cf(x, 1.0, -0.9), iron)
		block(m, Vector3.new(0.35, 3.6, 0.35), cf(x, 1.8, 0.9, -12, 0, 0), iron)
		block(m, Vector3.new(0.35, 0.3, 2.2), cf(x, 1.6, 0), iron)
		block(m, Vector3.new(0.35, 0.3, 1.6), cf(x, 2.5, -0.5), iron)
		ring(m, 0.8, 0.12, 0.3, cf(x, 0.6, 0, 0, 0, 90), iron, nil, 6)
	end
	for i = 0, 3 do
		block(
			m,
			Vector3.new(5.4, 0.22, 0.42),
			cf(0, 1.75, -0.75 + i * 0.5, 0, 0, (i % 2 - 0.5) * 1.5),
			if i % 2 == 0 then WOOD else WOOD_DARK
		)
	end
	for i = 0, 2 do
		block(
			m,
			Vector3.new(5.4, 0.42, 0.18),
			cf(0, 2.6 + i * 0.55, 1.05 + i * 0.12, -12, 0, 0),
			if i % 2 == 0 then WOOD_DARK else WOOD
		)
	end
	for _, x in { -2.4, 2.4 } do
		block(m, Vector3.new(0.4, 0.15, 0.15), cf(x, 1.75, -0.95), GOLD, M.Metal)
	end
	block(m, Vector3.new(0.3, 5.5, 0.3), cf(3.5, 2.75, 0.8), DARK)
	block(m, Vector3.new(0.9, 0.9, 0.9), cf(3.5, 5.9, 0.8), DARK)
	glow(m, Vector3.new(0.7, 0.7, 0.7), cf(3.5, 5.9, 0.8), rgb(255, 225, 140))
end

function builders.Doghouse(m)
	-- A doghouse: plank walls, a red shingled roof, an arched door, a gold bone sign, a food
	-- bowl and a glowing name plate.
	block(m, Vector3.new(5.0, 0.3, 5.0), cf(0, 0.15, 0), WOOD_DARK)
	for i = 0, 4 do
		block(
			m,
			Vector3.new(4.4, 0.6, 4.0),
			cf(0, 0.6 + i * 0.6, 0, 0, (i % 2) * 1.5, 0),
			if i % 2 == 0 then WOOD else rgb(176, 122, 76)
		)
	end
	block(m, Vector3.new(1.8, 2.0, 0.2), cf(0, 1.3, -2.0), DARK)
	octo(m, 1.8, 0.2, cf(0, 2.3, -2.0, 90, 0, 0), DARK)
	-- The roof: two big slanted red slabs with a darker shingle stripe on each.
	for _, side in { -1, 1 } do
		local slab = cf(side * 1.15, 4.05, 0, 0, 0, side * -42)
		block(m, Vector3.new(3.4, 0.35, 5.2), slab, rgb(210, 50, 50))
		block(m, Vector3.new(3.42, 0.37, 0.5), slab * CFrame.new(0, 0, -1.2), rgb(170, 35, 40))
		block(m, Vector3.new(3.42, 0.37, 0.5), slab * CFrame.new(0, 0, 1.2), rgb(170, 35, 40))
	end
	block(m, Vector3.new(4.8, 0.3, 0.3), cf(0, 4.8, 0), rgb(150, 25, 30))
	block(m, Vector3.new(1.4, 0.4, 0.12), cf(0, 3.7, -2.08), GOLD, M.Metal)
	glow(m, Vector3.new(1.1, 0.2, 0.06), cf(0, 3.7, -2.15), rgb(255, 240, 200))
	octo(m, 1.2, 0.35, CFrame.new(1.9, 0, -2.8), rgb(60, 120, 230))
	octo(m, 0.9, 0.1, CFrame.new(1.9, 0.33, -2.8), rgb(140, 90, 50))
end

--------------------------------------------------------------------------------
-- The Beach
--------------------------------------------------------------------------------

function builders.Lifebuoy(m)
	-- A red and white lifebuoy ring standing on a wooden post with a coiled rope and a
	-- glowing strip.
	block(m, Vector3.new(2.0, 0.3, 2.0), cf(0, 0.15, 0), WOOD_DARK)
	block(m, Vector3.new(0.6, 4.6, 0.6), cf(0, 2.6, 0.5), WOOD)
	local ringAt = cf(0, 3.5, -0.1, 90, 0, 0)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		block(
			m,
			Vector3.new(1.4, 0.75, 0.75),
			ringAt * CFrame.Angles(0, -a, 0) * CFrame.new(0, 0, 1.5),
			if i % 2 == 0 then rgb(230, 40, 45) else WHITE_PAINT
		)
	end
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + math.pi / 8
		glow(
			m,
			Vector3.new(0.4, 0.1, 0.8),
			ringAt * CFrame.Angles(0, -a, 0) * CFrame.new(0, 0.38, 1.5),
			rgb(255, 230, 120)
		)
	end
	ring(m, 1.4, 0.2, 0.2, CFrame.new(0, 1.0, 0.5), rgb(220, 200, 150), nil, 8)
	ring(m, 1.2, 0.2, 0.2, CFrame.new(0, 1.25, 0.5), rgb(220, 200, 150), nil, 8)
end

function builders.Surfboard(m)
	-- A surfboard standing up in the sand: a long board with a pointed nose, a stripe and a
	-- glowing fin, beside a little sand pile and a shell.
	octo(m, 3.4, 0.5, CFrame.new(), SAND)
	local board = cf(0, 3.8, 0, 0, 20, -6)
	block(m, Vector3.new(1.8, 6.0, 0.3), board, rgb(70, 190, 230))
	wedge(m, Vector3.new(1.8, 1.4, 0.3), board * CFrame.new(0, 3.7, 0), rgb(70, 190, 230))
	block(m, Vector3.new(0.4, 6.4, 0.32), board * CFrame.new(0, 0.2, 0), rgb(255, 210, 60))
	block(m, Vector3.new(1.8, 0.3, 0.32), board * CFrame.new(0, 1.2, 0), rgb(240, 90, 60))
	glow(m, Vector3.new(0.1, 0.8, 0.6), board * CFrame.new(0, -2.4, 0.4), rgb(255, 120, 220))
	block(m, Vector3.new(0.7, 0.3, 0.6), cf(1.2, 0.6, -0.9, 0, 30, 0), rgb(250, 200, 210))
end

function builders.BeachUmbrella(m)
	-- A beach umbrella: a striped canopy of wedges round a tall pole, with a gold tip, over a
	-- towel and a little cooler.
	block(m, Vector3.new(0.25, 6.0, 0.25), cf(0, 3.0, 0, 0, 0, 6), WHITE_PAINT)
	for i = 0, 7 do
		local a = i * 45
		wedge(
			m,
			Vector3.new(2.9, 1.2, 3.6),
			CFrame.new(-0.35, 6.0, 0) * CFrame.Angles(0, math.rad(a), 0) * cf(0, 0, 1.8, 0, 180, 0),
			if i % 2 == 0 then rgb(240, 70, 80) else WHITE_PAINT
		)
	end
	block(m, Vector3.new(0.4, 0.5, 0.4), cf(-0.35, 6.85, 0), GOLD, M.Metal)
	block(m, Vector3.new(2.6, 0.08, 4.4), cf(1.3, 0.05, 0.5), rgb(60, 170, 230))
	for i = 0, 3 do
		block(m, Vector3.new(2.6, 0.1, 0.4), cf(1.3, 0.08, -1.2 + i * 1.1), rgb(255, 220, 60))
	end
	block(m, Vector3.new(1.4, 1.0, 0.9), cf(-1.6, 0.5, -1.3), rgb(60, 120, 230))
	block(m, Vector3.new(1.5, 0.25, 1.0), cf(-1.6, 1.1, -1.3), WHITE_PAINT)
end

function builders.Sandcastle(m)
	-- A sandcastle: a stepped base, four towers with battlements, a gate, a moat with water
	-- and a little flag with a glowing star.
	octo(m, 8.0, 0.3, CFrame.new(), SAND)
	water(m, Vector3.new(7.0, 0.15, 7.0), CFrame.new(0, 0.25, 0) * CFrame.Angles(0, math.rad(22), 0), 2)
	block(m, Vector3.new(5.0, 1.6, 5.0), cf(0, 1.0, 0), SAND)
	block(m, Vector3.new(3.6, 1.4, 3.6), cf(0, 2.5, 0), SAND_DARK)
	for _, x in { -2.2, 2.2 } do
		for _, z in { -2.2, 2.2 } do
			octo(m, 1.4, 3.2, CFrame.new(x, 0, z), SAND_DARK)
			for k = 0, 3 do
				block(
					m,
					Vector3.new(0.4, 0.4, 0.4),
					cf(x + math.cos(k * 1.57) * 0.5, 3.4, z + math.sin(k * 1.57) * 0.5),
					SAND
				)
			end
		end
	end
	octo(m, 1.8, 1.6, CFrame.new(0, 3.2, 0), SAND)
	block(m, Vector3.new(1.0, 1.1, 0.2), cf(0, 1.0, -2.55), rgb(150, 110, 70))
	block(m, Vector3.new(0.1, 1.6, 0.1), cf(0, 5.6, 0), WOOD_DARK)
	block(m, Vector3.new(0.9, 0.6, 0.06), cf(0.5, 6.1, 0), rgb(240, 60, 70))
	glow(m, Vector3.new(0.25, 0.25, 0.08), cf(0.5, 6.1, -0.05, 0, 0, 45), rgb(255, 240, 150))
end

function builders.FlamingoFloat(m)
	-- A pink flamingo pool float: a fat ring of pink tubes, a curved neck and head with a
	-- black-tipped beak and glowing eyes, wings, in a splash of water.
	water(m, Vector3.new(8.0, 0.2, 8.0), CFrame.new(0, 0.1, 0), 3)
	local pink, deep = rgb(255, 130, 170), rgb(230, 90, 140)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		block(
			m,
			Vector3.new(1.9, 1.3, 1.3),
			CFrame.new(0, 0.85, 0) * CFrame.Angles(0, -a, 0) * CFrame.new(0, 0, 2.5),
			if i % 2 == 0 then pink else deep
		)
	end
	for _, side in { -1, 1 } do
		wedge(m, Vector3.new(0.3, 1.2, 2.4), cf(side * 2.6, 1.8, 0.6, 0, 0, side * -20), deep)
	end
	for i = 0, 4 do
		block(
			m,
			Vector3.new(0.8, 0.9, 0.8),
			cf(0, 1.6 + i * 0.8, -2.6 - math.sin(i * 0.6) * 0.8, -15 + i * 8, 0, 0),
			pink
		)
	end
	block(m, Vector3.new(1.2, 1.1, 1.4), cf(0, 5.6, -2.3), pink)
	wedge(m, Vector3.new(0.6, 0.7, 1.0), cf(0, 5.2, -3.4, 180, 0, 0), rgb(250, 240, 230))
	block(m, Vector3.new(0.5, 0.3, 0.4), cf(0, 4.85, -3.75), DARK)
	for _, side in { -1, 1 } do
		glow(m, Vector3.new(0.08, 0.3, 0.3), cf(side * 0.62, 5.8, -2.6), rgb(90, 220, 255))
	end
end

function builders.DolphinSprinkler(m)
	-- A dolphin sprinkler: a blue dolphin leaping out of a round splash pool, spraying a
	-- glowing arc of water from its blowhole.
	octo(m, 7.0, 0.5, CFrame.new(), rgb(230, 230, 240))
	water(m, Vector3.new(5.8, 0.2, 5.8), CFrame.new(0, 0.55, 0), 3)
	local blue, belly = rgb(70, 140, 230), rgb(220, 235, 250)
	local body = cf(0, 2.6, 0, -30, 0, 0)
	block(m, Vector3.new(1.4, 1.3, 3.8), body, blue)
	block(m, Vector3.new(1.0, 0.6, 3.2), body * CFrame.new(0, -0.5, 0), belly)
	block(m, Vector3.new(0.8, 0.7, 1.2), body * CFrame.new(0, 0.2, -2.3), blue)
	block(m, Vector3.new(0.5, 0.4, 1.0), body * CFrame.new(0, -0.1, -3.2), blue)
	wedge(m, Vector3.new(0.2, 1.0, 1.0), body * CFrame.new(0, 1.0, 0.2), blue)
	block(m, Vector3.new(2.2, 0.2, 0.7), body * CFrame.new(0, 0.1, 2.1), blue)
	for _, side in { -1, 1 } do
		block(
			m,
			Vector3.new(1.0, 0.15, 0.6),
			body * CFrame.new(side * 0.9, -0.4, -0.6) * CFrame.Angles(0, 0, side * 0.4),
			blue
		)
		glow(m, Vector3.new(0.06, 0.22, 0.22), body * CFrame.new(side * 0.42, 0.35, -2.6), rgb(255, 255, 255))
	end
	for i = 0, 6 do
		local t = i / 6
		glow(
			m,
			Vector3.new(0.3, 0.3, 0.3),
			cf(0, 4.4 + math.sin(t * math.pi) * 2.4, -1.0 + t * 4.4),
			rgb(140, 230, 255)
		)
	end
end

--------------------------------------------------------------------------------
-- The Wilderness
--------------------------------------------------------------------------------

function builders.Campfire(m)
	-- A campfire: a ring of grey stones, crossed logs, glowing flames in three colours and a
	-- marshmallow on a stick, beside a log to sit on.
	ring(m, 3.4, 0.7, 0.5, CFrame.new(0, 0.25, 0), STONE, nil, 9)
	for i = 0, 2 do
		block(m, Vector3.new(0.5, 0.5, 2.8), cf(0, 0.55, 0, 0, i * 60, 12), WOOD_DARK)
	end
	for i, f in { { 1.4, 1.6, rgb(255, 90, 30) }, { 1.0, 2.2, rgb(255, 160, 40) }, { 0.55, 2.8, rgb(255, 230, 90) } } do
		glow(m, Vector3.new(f[1], f[2], f[1]), cf(0, 0.6 + f[2] / 2, 0, 0, i * 25, 0), f[3])
	end
	local fire = Instance.new("PointLight")
	fire.Color = rgb(255, 170, 70)
	fire.Range = 14
	fire.Brightness = 2
	fire.Parent = m:FindFirstChildWhichIsA("BasePart")
	block(m, Vector3.new(0.08, 0.08, 2.6), cf(1.4, 1.6, -1.0, 20, -30, 0), WOOD)
	block(m, Vector3.new(0.3, 0.3, 0.3), cf(0.8, 2.0, -0.1), WHITE_PAINT)
	block(m, Vector3.new(4.0, 0.8, 0.8), cf(0, 0.4, 2.6), WOOD)
	block(m, Vector3.new(0.82, 0.82, 0.1), cf(2.0, 0.4, 2.6, 0, 90, 0), rgb(220, 180, 120))
end

function builders.CampingTent(m)
	-- A camping tent: an orange A-frame of two big slanted panels with a darker door flap
	-- tied open, guy ropes, a glowing lantern inside and a sleeping bag peeking out.
	block(m, Vector3.new(6.0, 0.15, 6.4), cf(0, 0.08, 0), rgb(90, 80, 70))
	local orange, deep = rgb(250, 150, 40), rgb(215, 110, 30)
	for _, side in { -1, 1 } do
		block(m, Vector3.new(0.2, 4.6, 6.0), cf(side * 1.55, 2.0, 0, 0, 0, side * 38), orange)
	end
	wedge(m, Vector3.new(5.6, 3.6, 0.2), cf(0, 1.8, 3.0), deep)
	for _, side in { -1, 1 } do
		wedge(m, Vector3.new(1.4, 3.4, 0.2), cf(side * 2.0, 1.7, -3.0, 0, 180, 0), deep)
	end
	glow(m, Vector3.new(0.6, 0.8, 0.6), cf(0, 0.6, 0), rgb(255, 225, 140))
	block(m, Vector3.new(1.4, 0.3, 2.4), cf(0.2, 0.25, -2.0), rgb(60, 120, 230))
	block(m, Vector3.new(0.3, 3.8, 0.3), cf(0, 1.9, -3.1), WOOD_DARK)
	block(m, Vector3.new(0.12, 0.12, 6.4), cf(0, 3.7, 0), DARK)
	for _, side in { -1, 1 } do
		block(m, Vector3.new(0.06, 0.06, 2.6), cf(side * 2.6, 1.6, -3.6, 45, side * 30, 0), rgb(230, 230, 220))
		block(m, Vector3.new(0.25, 0.4, 0.25), cf(side * 3.4, 0.2, -4.4), WOOD_DARK)
	end
end

function builders.Canoe(m)
	-- A red canoe on wooden stands: a long hull pointed at both ends, wooden seats, a gold
	-- stripe, two paddles leaning on it and a glowing name stripe.
	for _, z in { -2.2, 2.2 } do
		block(m, Vector3.new(2.6, 1.0, 0.4), cf(0, 0.5, z), WOOD_DARK)
	end
	local red, deep = rgb(210, 50, 45), rgb(160, 32, 32)
	block(m, Vector3.new(2.2, 1.0, 6.6), cf(0, 1.6, 0), red)
	block(m, Vector3.new(1.6, 0.4, 6.0), cf(0, 1.0, 0), deep)
	-- Pointed ends: the hull narrows in steps.
	for _, side in { -1, 1 } do
		block(m, Vector3.new(1.5, 1.0, 1.0), cf(0, 1.65, side * 3.8), red)
		block(m, Vector3.new(0.8, 1.0, 0.8), cf(0, 1.75, side * 4.6), red)
		block(m, Vector3.new(0.35, 0.9, 0.6), cf(0, 1.9, side * 5.2), deep)
	end
	block(m, Vector3.new(1.8, 0.4, 6.2), cf(0, 1.9, 0), rgb(50, 40, 40))
	for _, z in { -1.8, 0, 1.8 } do
		block(m, Vector3.new(2.0, 0.15, 0.5), cf(0, 2.0, z), WOOD)
	end
	block(m, Vector3.new(2.25, 0.15, 6.7), cf(0, 1.85, 0), GOLD, M.Metal)
	glow(m, Vector3.new(0.06, 0.25, 2.0), cf(1.13, 1.5, 0.8), rgb(255, 230, 140))
	for _, z in { -1.0, 1.3 } do
		block(m, Vector3.new(0.18, 3.6, 0.18), cf(1.7, 1.9, z, 0, 0, 18), WOOD)
		block(m, Vector3.new(0.5, 1.0, 0.12), cf(2.25, 0.4, z, 0, 0, 18), WOOD_DARK)
	end
end

function builders.LogCabin(m)
	-- A little log cabin: walls of stacked round logs with crossed corners, a green roof, a
	-- stone chimney with glowing embers, a door and warm glowing windows.
	block(m, Vector3.new(7.6, 0.4, 6.6), cf(0, 0.2, 0), STONE)
	for i = 0, 5 do
		local y = 0.75 + i * 0.6
		for _, z in { -2.6, 2.6 } do
			Bricks.rod(m, 7.2, 0.62, cf(0, y, z), if i % 2 == 0 then WOOD else rgb(176, 122, 76))
		end
		for _, x in { -3.3, 3.3 } do
			Bricks.rod(m, 5.8, 0.62, cf(x, y + 0.3, 0, 0, 90, 0), if i % 2 == 0 then rgb(176, 122, 76) else WOOD)
		end
	end
	for _, side in { -1, 1 } do
		block(m, Vector3.new(0.3, 4.8, 7.8), cf(side * 1.9, 5.3, 0, 0, 0, side * 50), rgb(70, 130, 70))
	end
	for _, z in { -2.6, 2.6 } do
		wedge(m, Vector3.new(6.4, 2.4, 0.4), cf(0, 5.0, z, 0, if z < 0 then 0 else 180, 0), WOOD_DARK)
	end
	block(m, Vector3.new(1.2, 5.4, 1.2), cf(2.3, 4.6, 1.2), STONE)
	glow(m, Vector3.new(0.8, 0.2, 0.8), cf(2.3, 7.35, 1.2), rgb(255, 140, 50))
	block(m, Vector3.new(1.4, 2.4, 0.2), cf(0, 1.6, -2.95), WOOD_DARK)
	block(m, Vector3.new(0.2, 0.2, 0.1), cf(0.45, 1.6, -3.08), GOLD, M.Metal)
	for _, x in { -2.0, 2.0 } do
		glow(m, Vector3.new(1.2, 1.0, 0.1), cf(x, 2.2, -2.97), rgb(255, 210, 120))
		block(m, Vector3.new(1.4, 0.12, 0.15), cf(x, 2.2, -3.02), WOOD_DARK)
		block(m, Vector3.new(0.12, 1.2, 0.15), cf(x, 2.2, -3.02), WOOD_DARK)
	end
end

--------------------------------------------------------------------------------
-- The Dream Home
--------------------------------------------------------------------------------

-- A plush rug the furniture stands on (so it looks at home in the yard).
local function rug(m, w: number, d: number, color: Color3, trim: Color3)
	block(m, Vector3.new(w, 0.12, d), cf(0, 0.06, 0), color)
	block(m, Vector3.new(w + 0.3, 0.08, d + 0.3), cf(0, 0.04, 0), trim)
end

function builders.SmartFridge(m)
	-- A big double-door smart fridge: brushed silver doors, long handles, a glowing touch
	-- screen with a snowflake, an ice dispenser and a little row of magnets.
	rug(m, 4.6, 3.8, rgb(90, 90, 110), rgb(60, 60, 75))
	local silver, deep = rgb(205, 210, 220), rgb(160, 166, 178)
	block(m, Vector3.new(4.0, 7.2, 2.8), cf(0, 3.75, 0.3), deep, M.Metal)
	for _, x in { -1.0, 1.0 } do
		block(m, Vector3.new(1.95, 6.8, 0.25), cf(x, 3.75, -1.2), silver, M.Metal)
		block(m, Vector3.new(0.18, 3.6, 0.3), cf(x * 0.12, 4.0, -1.45), DARK)
	end
	block(m, Vector3.new(1.3, 1.6, 0.1), cf(-1.0, 5.4, -1.34), rgb(20, 24, 34))
	glow(m, Vector3.new(1.1, 1.4, 0.06), cf(-1.0, 5.4, -1.38), rgb(90, 200, 255))
	glow(m, Vector3.new(0.5, 0.1, 0.06), cf(-1.0, 5.4, -1.42, 0, 0, 45), WHITE_PAINT)
	glow(m, Vector3.new(0.5, 0.1, 0.06), cf(-1.0, 5.4, -1.42, 0, 0, -45), WHITE_PAINT)
	block(m, Vector3.new(0.9, 1.2, 0.2), cf(1.0, 4.6, -1.35), rgb(40, 44, 54))
	glow(m, Vector3.new(0.5, 0.08, 0.06), cf(1.0, 5.0, -1.47), rgb(140, 230, 255))
	for i, c in { rgb(255, 90, 90), rgb(255, 210, 60), rgb(90, 200, 120) } do
		block(m, Vector3.new(0.3, 0.3, 0.08), cf(0.5 + i * 0.35, 2.4, -1.37), c)
	end
end

function builders.LuxurySofa(m)
	-- A big cream sofa: a deep seat with three plump cushions, rolled arms, a tall back,
	-- gold feet, two coloured throw pillows and a glowing reading lamp beside it.
	rug(m, 7.6, 5.0, rgb(200, 90, 110), rgb(150, 60, 80))
	local cream, deep = rgb(240, 228, 205), rgb(210, 195, 170)
	block(m, Vector3.new(6.2, 1.2, 2.8), cf(0, 1.0, 0.2), deep)
	for i = -1, 1 do
		block(m, Vector3.new(1.9, 0.6, 2.4), cf(i * 1.95, 1.9, 0.0, 0, 0, i * 1.5), cream)
		block(m, Vector3.new(1.9, 1.8, 0.7), cf(i * 1.95, 2.9, 1.25, -10, 0, 0), cream)
	end
	block(m, Vector3.new(6.4, 1.0, 0.7), cf(0, 2.2, 1.55), deep)
	for _, side in { -1, 1 } do
		block(m, Vector3.new(0.9, 2.2, 2.9), cf(side * 3.4, 1.6, 0.2), deep)
		Bricks.rod(m, 2.9, 1.1, cf(side * 3.4, 2.75, 0.2, 0, 90, 0), cream)
		block(
			m,
			Vector3.new(0.9, 0.7, 0.3),
			cf(side * 2.2, 2.6, 0.6, -20, side * 15, 0),
			if side < 0 then rgb(230, 70, 110) else rgb(80, 160, 230)
		)
		for _, z in { -1.0, 1.4 } do
			block(m, Vector3.new(0.3, 0.4, 0.3), cf(side * 3.6, 0.2, z), GOLD, M.Metal)
		end
	end
	block(m, Vector3.new(0.2, 4.8, 0.2), cf(4.6, 2.5, 1.2), GOLD, M.Metal)
	octo(m, 1.4, 1.0, CFrame.new(4.6, 4.9, 1.2), rgb(255, 245, 220))
	glow(m, Vector3.new(0.9, 0.3, 0.9), cf(4.6, 4.9, 1.2), rgb(255, 230, 160))
end

function builders.GiantTV(m)
	-- A giant TV on a low media cabinet: a huge thin black screen showing a glowing sunset
	-- picture, speakers either side with glowing rings, and a game controller.
	rug(m, 8.0, 4.0, rgb(60, 60, 80), rgb(40, 40, 52))
	block(m, Vector3.new(7.0, 1.4, 1.8), cf(0, 0.85, 0.6), WOOD_DARK)
	glow(m, Vector3.new(6.6, 0.08, 0.08), cf(0, 0.3, -0.31), rgb(120, 90, 255))
	block(m, Vector3.new(7.6, 4.4, 0.35), cf(0, 4.2, 0.6), rgb(20, 20, 26))
	glow(m, Vector3.new(7.1, 1.4, 0.06), cf(0, 5.3, 0.4), rgb(255, 150, 80))
	glow(m, Vector3.new(7.1, 1.2, 0.06), cf(0, 4.0, 0.4), rgb(255, 90, 150))
	glow(m, Vector3.new(7.1, 1.2, 0.06), cf(0, 2.8, 0.4), rgb(90, 70, 200))
	octo(m, 1.4, 0.06, cf(0.9, 4.4, 0.36, 90, 0, 0), rgb(255, 240, 160))
	block(m, Vector3.new(1.2, 0.3, 0.6), cf(0, 1.7, 0.8), DARK)
	for _, side in { -1, 1 } do
		block(m, Vector3.new(1.2, 3.6, 1.2), cf(side * 4.6, 1.8, 0.6), DARK)
		for _, y in { 1.2, 2.6 } do
			octo(m, 0.8, 0.1, cf(side * 4.6, y, -0.05, 90, 0, 0), rgb(70, 70, 80))
			ring(m, 0.9, 0.1, 0.1, cf(side * 4.6, y, -0.08, 90, 0, 0), rgb(90, 200, 255), M.Neon, 8)
		end
	end
	block(m, Vector3.new(0.9, 0.2, 0.5), cf(-1.8, 1.65, 0.2), rgb(240, 240, 245))
end

function builders.KingBed(m)
	-- A king-size bed: a tall padded headboard with gold buttons, a thick mattress with a
	-- puffy blue duvet folded back, four big pillows, a glowing night light and gold posts.
	rug(m, 8.0, 9.0, rgb(240, 220, 200), rgb(200, 170, 150))
	block(m, Vector3.new(6.8, 1.0, 8.0), cf(0, 0.8, 0.3), WOOD_DARK)
	block(m, Vector3.new(6.4, 1.0, 7.6), cf(0, 1.8, 0.3), WHITE_PAINT)
	block(m, Vector3.new(6.6, 0.6, 5.0), cf(0, 2.5, -1.0), rgb(70, 110, 220))
	block(m, Vector3.new(6.6, 0.4, 1.0), cf(0, 2.6, 1.8), rgb(110, 150, 240))
	for _, x in { -2.3, -0.8, 0.8, 2.3 } do
		block(m, Vector3.new(1.4, 0.6, 1.0), cf(x, 2.6, 3.2, 0, 0, x * 2), WHITE_PAINT)
	end
	block(m, Vector3.new(7.2, 4.6, 0.6), cf(0, 2.8, 4.3), rgb(150, 80, 160))
	for i = 0, 5 do
		for j = 0, 2 do
			block(m, Vector3.new(0.2, 0.2, 0.08), cf(-2.5 + i, 3.0 + j, 3.98), GOLD, M.Metal)
		end
	end
	for _, x in { -3.6, 3.6 } do
		block(m, Vector3.new(0.4, 5.6, 0.4), cf(x, 2.8, 4.3), GOLD, M.Metal)
		octo(m, 0.6, 0.4, CFrame.new(x, 5.6, 4.3), GOLD, M.Metal)
	end
	block(m, Vector3.new(1.0, 1.4, 1.0), cf(4.4, 0.7, 3.4), WOOD)
	glow(m, Vector3.new(0.5, 0.6, 0.5), cf(4.4, 1.7, 3.4), rgb(255, 210, 140))
end

function builders.VanityMirror(m)
	-- A golden vanity: a tall oval mirror in an ornate gold frame with a ring of glowing
	-- bulbs, a white dresser with gold handles, perfume bottles and a pink stool.
	rug(m, 6.0, 4.4, rgb(255, 190, 220), rgb(230, 140, 180))
	block(m, Vector3.new(5.0, 2.6, 2.0), cf(0, 1.4, 0.6), WHITE_PAINT)
	block(m, Vector3.new(5.2, 0.2, 2.2), cf(0, 2.8, 0.6), GOLD, M.Metal)
	for _, x in { -1.6, 0, 1.6 } do
		block(m, Vector3.new(1.4, 0.8, 0.08), cf(x, 1.6, -0.43), rgb(240, 236, 245))
		block(m, Vector3.new(0.4, 0.12, 0.12), cf(x, 1.6, -0.5), GOLD, M.Metal)
	end
	local mirror = cf(0, 5.2, 1.2)
	ring(m, 3.6, 0.45, 0.3, mirror * CFrame.Angles(math.pi / 2, 0, 0), GOLD, M.Metal, 12)
	local glass = block(m, Vector3.new(3.0, 3.4, 0.1), mirror, rgb(200, 230, 255), M.Glass)
	glass.Reflectance = 0.4
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		glow(
			m,
			Vector3.new(0.3, 0.3, 0.3),
			mirror * CFrame.new(math.cos(a) * 2.05, math.sin(a) * 2.05, -0.15),
			rgb(255, 240, 200)
		)
	end
	block(m, Vector3.new(0.6, 0.8, 0.6), cf(0, 7.2, 1.2, 0, 0, 45), GOLD, M.Metal)
	for i, c in { rgb(255, 120, 200), rgb(150, 110, 255), rgb(90, 220, 220) } do
		block(m, Vector3.new(0.35, 0.6, 0.35), cf(-2.0 + i * 0.45, 3.2, 0.2), c, M.Glass)
		block(m, Vector3.new(0.15, 0.15, 0.15), cf(-2.0 + i * 0.45, 3.55, 0.2), GOLD, M.Metal)
	end
	octo(m, 1.3, 1.3, CFrame.new(0, 0, -1.4), rgb(255, 150, 200))
end

function builders.GamingSetup(m)
	-- An RGB gaming setup: a black desk with a glowing rainbow edge, three monitors showing
	-- glowing game screens, a lit keyboard, a gaming chair with neon stripes and a tower PC
	-- with a rainbow fan.
	rug(m, 8.0, 6.0, rgb(40, 40, 52), rgb(120, 70, 255))
	block(m, Vector3.new(7.2, 0.3, 2.6), cf(0, 2.8, 1.0), rgb(30, 30, 36))
	for _, x in { -3.3, 3.3 } do
		block(m, Vector3.new(0.3, 2.7, 2.2), cf(x, 1.35, 1.0), rgb(30, 30, 36))
	end
	for i, c in Bricks.RAINBOW do
		glow(m, Vector3.new(1.2, 0.08, 0.08), cf(-3.0 + (i - 1) * 1.2, 2.65, -0.32), c)
	end
	for i, angle in { -25, 0, 25 } do
		local x = (i - 2) * 2.3
		local screen = cf(x, 4.4, 1.6 + math.abs(i - 2) * -0.3, 0, angle, 0)
		block(m, Vector3.new(2.2, 1.4, 0.2), screen, DARK)
		glow(m, Vector3.new(2.0, 1.2, 0.06), screen * CFrame.new(0, 0, -0.12), Bricks.RAINBOW[i * 2])
		block(m, Vector3.new(0.2, 1.0, 0.2), cf(x, 3.3, 1.8), DARK)
	end
	block(m, Vector3.new(2.6, 0.12, 0.8), cf(0, 3.0, 0.3), rgb(40, 40, 46))
	glow(m, Vector3.new(2.4, 0.04, 0.6), cf(0, 3.07, 0.3), rgb(255, 80, 200))
	block(m, Vector3.new(2.0, 0.5, 2.0), cf(0, 1.6, -1.4), DARK)
	block(m, Vector3.new(2.0, 3.0, 0.5), cf(0, 3.3, -2.3, 10, 0, 0), DARK)
	for _, x in { -0.6, 0.6 } do
		glow(m, Vector3.new(0.2, 2.6, 0.06), cf(x, 3.3, -2.03, 10, 0, 0), rgb(255, 60, 120))
	end
	block(m, Vector3.new(0.3, 1.2, 0.3), cf(0, 0.8, -1.4), DARK)
	block(m, Vector3.new(1.8, 0.2, 1.8), cf(0, 0.2, -1.4, 0, 45, 0), DARK)
	block(m, Vector3.new(1.3, 2.4, 2.2), cf(4.6, 1.2, 1.0), rgb(30, 30, 36))
	ring(m, 0.9, 0.12, 0.1, cf(4.6, 1.6, -0.12, 90, 0, 0), rgb(120, 90, 255), M.Neon, 8)
	glow(m, Vector3.new(0.3, 0.3, 0.06), cf(4.6, 1.6, -0.14), rgb(90, 220, 255))
end

function builders.GrandPiano(m)
	-- A black grand piano: a curved body of stepped blocks with its lid propped open, gold
	-- strings, black and white keys, gold pedals and legs, a bench and glowing music notes.
	rug(m, 8.0, 8.0, rgb(150, 30, 40), rgb(110, 20, 30))
	local black = rgb(22, 22, 28)
	for i = 0, 4 do
		local w = 5.0 - i * 0.7
		block(m, Vector3.new(w, 1.2, 1.3), cf((5.0 - w) / -2, 3.0, -1.3 + i * 1.25), black)
	end
	block(m, Vector3.new(4.6, 0.08, 5.4), cf(-0.3, 3.62, 1.2), GOLD, M.Metal)
	block(m, Vector3.new(4.8, 0.15, 5.6), cf(-0.6, 5.3, 1.6, -35, 0, -2), black)
	block(m, Vector3.new(0.12, 2.6, 0.12), cf(1.4, 4.4, 1.6, 0, 0, 10), black)
	block(m, Vector3.new(5.0, 0.5, 1.2), cf(0, 2.5, -2.4), black)
	block(m, Vector3.new(4.8, 0.18, 0.8), cf(0, 2.82, -2.6), WHITE_PAINT)
	for i = 0, 9 do
		block(m, Vector3.new(0.18, 0.16, 0.5), cf(-2.1 + i * 0.47, 2.95, -2.45), black)
	end
	for _, spot in { { -2.0, -1.8 }, { 2.0, -1.8 }, { -1.2, 3.4 } } do
		block(m, Vector3.new(0.5, 2.5, 0.5), cf(spot[1], 1.25, spot[2]), black)
		block(m, Vector3.new(0.55, 0.3, 0.55), cf(spot[1], 0.15, spot[2]), GOLD, M.Metal)
	end
	for _, x in { -0.3, 0.3 } do
		block(m, Vector3.new(0.18, 0.08, 0.5), cf(x, 0.3, -2.7), GOLD, M.Metal)
	end
	block(m, Vector3.new(3.0, 0.5, 1.2), cf(0, 1.6, -4.0), black)
	block(m, Vector3.new(2.8, 0.15, 1.0), cf(0, 1.92, -4.0), rgb(150, 30, 40))
	for _, x in { -1.2, 1.2 } do
		block(m, Vector3.new(0.3, 1.4, 0.3), cf(x, 0.7, -4.0), black)
	end
	for i, spot in { { -1.6, 6.6, 0.4 }, { 0.2, 7.3, 1.0 }, { 1.8, 6.4, 0.2 } } do
		local at = cf(spot[1], spot[2], spot[3], 0, 0, i * 8)
		glow(m, Vector3.new(0.45, 0.35, 0.1), at, rgb(255, 220, 90))
		glow(m, Vector3.new(0.1, 1.0, 0.1), at * CFrame.new(0.2, 0.5, 0), rgb(255, 220, 90))
	end
end

--------------------------------------------------------------------------------
-- The City
--------------------------------------------------------------------------------

-- A car: a body in `color` (and `deep` for the top), dark glass, glowing lights, wheels with
-- `rim` hubs and an underglow. Returns the height of its roof.
local function car(m, color: Color3, deep: Color3, rim: Color3, under: Color3, low: boolean?)
	local h = if low then 0 else 0.4
	block(m, Vector3.new(3.6, 0.9, 7.4), cf(0, 1.15 + h, 0), color)
	wedge(m, Vector3.new(3.6, 0.6, 2.2), cf(0, 1.9 + h, -2.6), color)
	wedge(m, Vector3.new(3.4, 0.6, 1.6), cf(0, 1.9 + h, 2.5, 0, 180, 0), color)
	local roofH = if low then 0.9 else 1.4
	block(m, Vector3.new(3.2, roofH, 2.8), cf(0, 1.6 + h + roofH / 2, 0.4), deep)
	wedge(m, Vector3.new(3.0, roofH * 0.95, 1.4), cf(0, 1.6 + h + roofH / 2, -1.65), rgb(30, 40, 60), M.Glass)
	block(m, Vector3.new(3.25, roofH * 0.65, 2.4), cf(0, 1.6 + h + roofH / 2, 0.4), rgb(30, 40, 60), M.Glass)
	for _, x in { -1.3, 1.3 } do
		glow(m, Vector3.new(0.8, 0.25, 0.08), cf(x, 1.3 + h, -3.72), rgb(255, 250, 220))
		glow(m, Vector3.new(0.8, 0.2, 0.08), cf(x, 1.3 + h, 3.72), rgb(255, 40, 40))
	end
	for _, x in { -1.8, 1.8 } do
		for _, z in { -2.3, 2.3 } do
			wheel(m, x, 0.75, z, 1.5, rim)
		end
	end
	glow(m, Vector3.new(3.0, 0.08, 6.6), cf(0, 0.5, 0), under)
	return 1.6 + h + roofH
end

function builders.ElectricScooter(m)
	-- An electric scooter: a slim deck with a glowing strip, a tall stem and handlebar with a
	-- glowing screen, small wheels and a kickstand, beside a charging post.
	block(m, Vector3.new(1.1, 0.3, 4.4), cf(0, 0.75, 0), rgb(40, 44, 54))
	glow(m, Vector3.new(0.1, 0.12, 4.0), cf(0.57, 0.75, 0), rgb(90, 220, 255))
	glow(m, Vector3.new(0.1, 0.12, 4.0), cf(-0.57, 0.75, 0), rgb(90, 220, 255))
	block(m, Vector3.new(0.3, 4.4, 0.3), cf(0, 2.9, -2.1, -8, 0, 0), rgb(60, 200, 160))
	block(m, Vector3.new(2.4, 0.25, 0.25), cf(0, 5.05, -2.4), rgb(40, 44, 54))
	for _, side in { -1, 1 } do
		block(m, Vector3.new(0.5, 0.3, 0.3), cf(side * 1.2, 5.05, -2.4), DARK)
	end
	block(m, Vector3.new(0.7, 0.45, 0.1), cf(0, 4.6, -2.45, -8, 0, 0), DARK)
	glow(m, Vector3.new(0.55, 0.32, 0.06), cf(0, 4.6, -2.52, -8, 0, 0), rgb(120, 255, 160))
	for _, z in { -2.0, 2.0 } do
		wheel(m, 0, 0.5, z, 1.0, rgb(60, 200, 160))
	end
	block(m, Vector3.new(0.7, 3.2, 0.7), cf(2.6, 1.6, 1.0), rgb(230, 230, 240))
	glow(m, Vector3.new(0.5, 0.5, 0.06), cf(2.6, 2.6, 0.62), rgb(120, 255, 160))
end

function builders.VendingMachine(m)
	-- A bright vending machine: a red cabinet with a glass front full of colourful cans and
	-- snacks on glowing shelves, a keypad, a coin slot and a glowing logo.
	block(m, Vector3.new(4.0, 0.3, 3.0), cf(0, 0.15, 0), DARK)
	block(m, Vector3.new(3.6, 7.0, 2.6), cf(0, 3.8, 0.1), rgb(220, 45, 55))
	block(m, Vector3.new(2.5, 5.2, 0.1), cf(-0.4, 4.3, -1.22), rgb(200, 230, 255), M.Glass)
	for row = 0, 3 do
		glow(m, Vector3.new(2.4, 0.08, 0.6), cf(-0.4, 2.2 + row * 1.25, -0.9), rgb(255, 255, 230))
		for col = 0, 3 do
			block(
				m,
				Vector3.new(0.4, 0.75, 0.4),
				cf(-1.3 + col * 0.6, 2.65 + row * 1.25, -0.9),
				Bricks.RAINBOW[(row + col) % 6 + 1]
			)
		end
	end
	block(m, Vector3.new(0.7, 1.4, 0.15), cf(1.3, 4.6, -1.2), rgb(40, 40, 48))
	for i = 0, 5 do
		glow(m, Vector3.new(0.15, 0.15, 0.06), cf(1.15 + (i % 2) * 0.3, 4.9 - (i // 2) * 0.3, -1.3), rgb(120, 230, 255))
	end
	block(m, Vector3.new(0.4, 0.1, 0.12), cf(1.3, 3.6, -1.3), GOLD, M.Metal)
	block(m, Vector3.new(2.6, 0.8, 0.2), cf(-0.4, 1.0, -1.2), DARK)
	glow(m, Vector3.new(3.0, 0.6, 0.1), cf(0, 7.0, -1.18), rgb(255, 230, 120))
end

function builders.ATM(m)
	-- A cash machine: a chunky blue kiosk with a glowing screen showing a dollar sign, a
	-- keypad, a card slot, a stack of green cash poking out and a glowing sign on top.
	block(m, Vector3.new(3.4, 0.3, 3.0), cf(0, 0.15, 0), STONE)
	block(m, Vector3.new(2.8, 5.4, 2.2), cf(0, 3.0, 0.2), rgb(40, 100, 210))
	block(m, Vector3.new(2.8, 0.6, 1.4), cf(0, 3.3, -1.3, 20, 0, 0), rgb(50, 60, 80))
	block(m, Vector3.new(2.0, 1.4, 0.1), cf(0, 4.6, -0.95), DARK)
	glow(m, Vector3.new(1.8, 1.2, 0.06), cf(0, 4.6, -1.0), rgb(90, 220, 140))
	glow(m, Vector3.new(0.2, 0.8, 0.06), cf(0, 4.6, -1.05), WHITE_PAINT)
	glow(m, Vector3.new(0.6, 0.15, 0.06), cf(0, 4.85, -1.05), WHITE_PAINT)
	glow(m, Vector3.new(0.6, 0.15, 0.06), cf(0, 4.35, -1.05), WHITE_PAINT)
	for i = 0, 8 do
		block(
			m,
			Vector3.new(0.3, 0.1, 0.25),
			cf(-0.5 + (i % 3) * 0.4, 3.45, -1.25 - (i // 3) * 0.25, 20, 0, 0),
			rgb(220, 220, 230)
		)
	end
	block(m, Vector3.new(0.6, 0.1, 0.1), cf(0.9, 3.5, -1.5), GOLD, M.Metal)
	for i = 0, 2 do
		block(m, Vector3.new(1.4, 0.12, 0.7), cf(0, 2.4 + i * 0.13, -1.1, 0, (i - 1) * 5, 0), rgb(110, 200, 100))
	end
	block(m, Vector3.new(3.0, 0.9, 2.4), cf(0, 6.1, 0.2), rgb(30, 70, 160))
	glow(m, Vector3.new(2.4, 0.5, 0.06), cf(0, 6.1, -1.02), rgb(255, 220, 80))
end

function builders.YellowTaxi(m)
	-- A yellow taxi: the car with a black-and-white checker stripe and a glowing TAXI light
	-- on the roof.
	local roof = car(m, rgb(255, 205, 40), rgb(240, 180, 30), rgb(200, 200, 210), rgb(255, 220, 60))
	for i = 0, 11 do
		for _, side in { -1, 1 } do
			block(
				m,
				Vector3.new(0.06, 0.25, 0.55),
				cf(side * 1.82, 1.45 + (i % 2) * 0.25, -3.0 + i * 0.55),
				if i % 2 == 0 then DARK else WHITE_PAINT
			)
		end
	end
	block(m, Vector3.new(1.6, 0.6, 0.7), cf(0, roof + 0.3, 0.4), rgb(40, 40, 48))
	glow(m, Vector3.new(1.4, 0.45, 0.75), cf(0, roof + 0.32, 0.4), rgb(255, 240, 150))
end

-- A helicopter in `color`: a rounded cabin of blocks with a big glass bubble, a tail boom
-- with a tail rotor, skids, and a four-blade main rotor. glowing lights in `light`.
local function helicopter(m, color: Color3, deep: Color3, rim: Color3, light: Color3)
	for _, x in { -1.4, 1.4 } do
		block(m, Vector3.new(0.3, 0.3, 6.0), cf(x, 0.3, 0), rim, M.Metal)
		for _, z in { -1.4, 1.4 } do
			block(m, Vector3.new(0.2, 1.2, 0.2), cf(x, 0.9, z, 0, 0, x * -8), rim, M.Metal)
		end
	end
	block(m, Vector3.new(3.2, 2.6, 4.4), cf(0, 2.6, 0.2), color)
	block(m, Vector3.new(2.6, 0.5, 3.6), cf(0, 4.1, 0.4), deep)
	wedge(m, Vector3.new(3.0, 2.2, 1.6), cf(0, 2.8, -2.7), rgb(140, 210, 255), M.Glass)
	block(m, Vector3.new(3.25, 1.2, 2.0), cf(0, 3.0, -0.6), rgb(140, 210, 255), M.Glass)
	block(m, Vector3.new(1.0, 1.0, 5.2), cf(0, 3.0, 4.8), color)
	block(m, Vector3.new(0.2, 2.0, 1.2), cf(0, 3.9, 7.2), deep)
	Bricks.rod(m, 0.25, 2.4, cf(0.3, 3.6, 7.2), rim, M.Metal)
	octo(m, 0.8, 0.6, CFrame.new(0, 4.35, 0.4), rim, M.Metal)
	for i = 0, 3 do
		block(m, Vector3.new(0.6, 0.12, 6.0), cf(0, 5.0, 0.4, 0, i * 90 + 20, 0) * CFrame.new(0, 0, 3.0), DARK)
	end
	glow(m, Vector3.new(3.0, 0.1, 0.1), cf(0, 1.4, -1.9), light)
	glow(m, Vector3.new(0.3, 0.3, 0.3), cf(0, 4.6, 7.6), rgb(255, 60, 60))
end

function builders.Helicopter(m)
	-- A blue helicopter on a round landing pad with an H.
	octo(m, 9.0, 0.3, CFrame.new(), rgb(80, 85, 100))
	for _, x in { -1.0, 1.0 } do
		block(m, Vector3.new(0.5, 0.05, 3.0), cf(x, 0.32, 0), rgb(255, 220, 60))
	end
	block(m, Vector3.new(1.6, 0.05, 0.5), cf(0, 0.32, 0), rgb(255, 220, 60))
	ring(m, 8.6, 0.3, 0.06, CFrame.new(0, 0.32, 0), rgb(90, 220, 255), M.Neon, 12)
	local model = Instance.new("Model")
	helicopter(model, rgb(50, 120, 230), rgb(40, 90, 190), rgb(200, 200, 210), rgb(90, 220, 255))
	for _, p in model:GetChildren() do
		p.CFrame = CFrame.new(0, 0.3, -0.6) * p.CFrame
		p.Parent = m
	end
end

function builders.Skyscraper(m)
	-- A miniature skyscraper: a glass tower of stepped sections with rows of glowing windows,
	-- gold trim, a spire with a blinking red light and a little plaza around its base.
	block(m, Vector3.new(7.0, 0.3, 7.0), cf(0, 0.15, 0), rgb(200, 200, 210))
	local sections = { { 4.6, 4.0 }, { 3.8, 3.4 }, { 3.0, 2.8 }, { 2.0, 1.6 } }
	local y = 0.3
	for i, s in sections do
		block(
			m,
			Vector3.new(s[1], s[2], s[1]),
			cf(0, y + s[2] / 2, 0),
			if i % 2 == 0 then rgb(70, 110, 170) else rgb(60, 90, 150)
		)
		for row = 0, math.floor(s[2] / 0.7) - 1 do
			for _, face in { 0, 90, 180, 270 } do
				glow(
					m,
					Vector3.new(s[1] * 0.8, 0.25, 0.06),
					CFrame.Angles(0, math.rad(face), 0) * cf(0, y + 0.4 + row * 0.7, -s[1] / 2 - 0.02),
					if (row + i) % 3 == 0 then rgb(255, 230, 140) else rgb(150, 220, 255)
				)
			end
		end
		block(m, Vector3.new(s[1] + 0.2, 0.18, s[1] + 0.2), cf(0, y + s[2], 0), GOLD, M.Metal)
		y += s[2]
	end
	block(m, Vector3.new(0.2, 2.4, 0.2), cf(0, y + 1.2, 0), rgb(200, 200, 210), M.Metal)
	glow(m, Vector3.new(0.35, 0.35, 0.35), cf(0, y + 2.5, 0), rgb(255, 50, 50))
	for _, x in { -3.0, 3.0 } do
		octo(m, 0.9, 0.5, CFrame.new(x, 0.3, -3.0), rgb(90, 170, 90))
	end
end

--------------------------------------------------------------------------------
-- The Millionaire
--------------------------------------------------------------------------------

-- A faceted gem: a crown of angled facets on a girdle over a pointed base, `size` across,
-- centred on `at`, with a glowing core.
local function gem(m, size: number, at: CFrame, color: Color3, core: Color3)
	local s = size
	local p = block(m, Vector3.new(s, s * 0.18, s), at, color, M.Glass)
	p.Transparency = 0.1
	for i = 0, 7 do
		local a = i * 45
		local facet = wedge(
			m,
			Vector3.new(s * 0.42, s * 0.3, s * 0.32),
			at * CFrame.Angles(0, math.rad(a), 0) * CFrame.new(0, s * 0.24, s * 0.3),
			color,
			M.Glass
		)
		facet.Transparency = 0.1
		local lower = wedge(
			m,
			Vector3.new(s * 0.42, s * 0.62, s * 0.4),
			at * CFrame.Angles(0, math.rad(a), 0) * CFrame.new(0, -s * 0.4, s * 0.25) * CFrame.Angles(math.pi, 0, 0),
			color:Lerp(Color3.new(0, 0, 0), 0.15),
			M.Glass
		)
		lower.Transparency = 0.1
	end
	block(
		m,
		Vector3.new(s * 0.62, s * 0.1, s * 0.62),
		at * CFrame.new(0, s * 0.38, 0),
		color:Lerp(Color3.new(1, 1, 1), 0.4),
		M.Glass
	)
	glow(m, Vector3.new(s * 0.4, s * 0.4, s * 0.4), at * CFrame.Angles(0, math.rad(45), 0), core)
end

-- A round-ish ball of three stacked octagons, `d` across, centred on `at`.
local function blob(m, d: number, at: CFrame, color: Color3, material)
	octo(m, d * 0.7, d * 0.22, at * CFrame.new(0, -d * 0.5, 0), color, material)
	octo(m, d, d * 0.56, at * CFrame.new(0, -d * 0.28, 0), color, material)
	octo(m, d * 0.7, d * 0.22, at * CFrame.new(0, d * 0.28, 0), color, material)
end

-- A small velvet display stand with a gold rim.
local function plinth(m, size: number, height: number, velvet: Color3)
	octo(m, size, height, CFrame.new(), rgb(245, 240, 230))
	octo(m, size * 1.08, 0.2, CFrame.new(0, height, 0), GOLD, M.Metal)
	octo(m, size * 0.9, 0.15, CFrame.new(0, height + 0.2, 0), velvet)
end

function builders.DiamondWatch(m)
	-- A diamond watch on a velvet stand: a chunky gold case ringed with diamonds, a glowing
	-- blue face with gold hands, a crown and a gold link band draped over the stand.
	plinth(m, 4.0, 2.2, rgb(60, 30, 110))
	local face = cf(0, 4.2, 0, -15, 0, 0)
	octo(m, 2.6, 0.6, face * CFrame.Angles(math.pi / 2, 0, 0) * CFrame.new(0, -0.3, 0), GOLD, M.Metal)
	glow(m, Vector3.new(1.7, 1.7, 0.08), face * CFrame.new(0, 0, -0.32), rgb(60, 140, 255))
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		block(
			m,
			Vector3.new(0.22, 0.22, 0.12),
			face * CFrame.new(math.cos(a) * 1.15, math.sin(a) * 1.15, -0.33) * CFrame.Angles(0, 0, math.pi / 4),
			rgb(230, 245, 255),
			M.Glass
		)
	end
	block(m, Vector3.new(0.08, 0.7, 0.05), face * CFrame.new(0, 0.3, -0.38), GOLD, M.Metal)
	block(m, Vector3.new(0.5, 0.08, 0.05), face * CFrame.new(0.22, 0, -0.38), GOLD, M.Metal)
	block(m, Vector3.new(0.3, 0.3, 0.3), face * CFrame.new(1.45, 0, 0), GOLD, M.Metal)
	for i = 0, 4 do
		block(
			m,
			Vector3.new(1.2, 0.25, 0.6),
			cf(0, 2.55 - i * 0.05, -0.7 - i * 0.55, 10 + i * 12, 0, 0),
			if i % 2 == 0 then GOLD else rgb(230, 175, 50),
			M.Metal
		)
		block(
			m,
			Vector3.new(1.2, 0.25, 0.6),
			cf(0, 2.55 - i * 0.05, 0.7 + i * 0.55, -10 - i * 12, 0, 0),
			if i % 2 == 0 then GOLD else rgb(230, 175, 50),
			M.Metal
		)
	end
end

function builders.Diamond(m)
	-- A giant diamond on a velvet stand, sparkling with a glowing core and a soft light.
	plinth(m, 3.4, 1.8, rgb(150, 30, 60))
	gem(m, 3.6, CFrame.new(0, 4.6, 0), rgb(190, 235, 255), rgb(140, 220, 255))
	local light = Instance.new("PointLight")
	light.Color = rgb(170, 230, 255)
	light.Range = 12
	light.Brightness = 2
	light.Parent = m:FindFirstChildWhichIsA("BasePart")
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = rgb(200, 240, 255)
	sparkles.Parent = m:FindFirstChildWhichIsA("BasePart")
end

function builders.GoldenThrone(m)
	-- A golden throne on a red-carpeted dais: a tall arched back with a jewel, chunky gold
	-- arms with lion-paw ends, a red velvet seat and glowing gems on top.
	block(m, Vector3.new(6.4, 0.5, 5.6), cf(0, 0.25, 0), GOLD, M.Metal)
	block(m, Vector3.new(5.6, 0.5, 4.8), cf(0, 0.75, 0.2), rgb(170, 30, 45))
	block(m, Vector3.new(3.6, 1.6, 3.0), cf(0, 1.8, 0.4), GOLD, M.Metal)
	block(m, Vector3.new(3.2, 0.5, 2.6), cf(0, 2.85, 0.3), rgb(190, 30, 50))
	block(m, Vector3.new(3.6, 5.2, 0.7), cf(0, 5.1, 1.7), GOLD, M.Metal)
	block(m, Vector3.new(2.8, 4.0, 0.2), cf(0, 4.8, 1.3), rgb(190, 30, 50))
	for i = 0, 2 do
		wedge(m, Vector3.new(0.7, 1.0, 0.7), cf(-1.1 + i * 1.1, 8.2 - (i % 2) * -0.4, 1.7), GOLD, M.Metal)
		glow(
			m,
			Vector3.new(0.3, 0.3, 0.3),
			cf(-1.1 + i * 1.1, 8.9 + (i % 2) * 0.4, 1.7, 45, 45, 0),
			Bricks.RAINBOW[i * 2 + 1]
		)
	end
	gem(m, 0.9, cf(0, 6.6, 1.15, 90, 0, 0), rgb(255, 60, 90), rgb(255, 120, 150))
	for _, side in { -1, 1 } do
		block(m, Vector3.new(0.7, 1.0, 3.0), cf(side * 2.0, 3.4, 0.2), GOLD, M.Metal)
		block(m, Vector3.new(0.9, 0.9, 0.9), cf(side * 2.0, 3.6, -1.4), rgb(230, 175, 50), M.Metal)
		glow(m, Vector3.new(0.3, 0.3, 0.1), cf(side * 2.0, 3.6, -1.86), rgb(90, 220, 255))
	end
end

function builders.MansionModel(m)
	-- A model mansion on a green lawn: a white two-storey house with a blue roof, a columned
	-- porch, a gold door, rows of glowing windows, two wings and a fountain out front.
	block(m, Vector3.new(9.0, 0.3, 8.0), cf(0, 0.15, 0), rgb(110, 200, 90))
	block(m, Vector3.new(1.4, 0.32, 3.4), cf(0, 0.17, -2.4), rgb(235, 225, 200))
	local white, roof = rgb(245, 242, 235), rgb(60, 90, 160)
	block(m, Vector3.new(5.0, 4.2, 3.6), cf(0, 2.4, 1.0), white)
	for _, side in { -1, 1 } do
		block(m, Vector3.new(2.2, 3.0, 3.0), cf(side * 3.4, 1.8, 1.2), white)
		block(m, Vector3.new(2.5, 0.8, 3.3), cf(side * 3.4, 3.7, 1.2), roof)
	end
	block(m, Vector3.new(5.4, 0.6, 4.0), cf(0, 4.8, 1.0), roof)
	for _, side in { -1, 1 } do
		wedge(m, Vector3.new(5.4, 1.4, 2.0), cf(0, 5.8, 1.0 + side * 1.0, 0, if side < 0 then 0 else 180, 0), roof)
	end
	wedge(m, Vector3.new(3.0, 1.2, 0.4), cf(0, 4.1, -1.25), white)
	for _, x in { -1.2, -0.4, 0.4, 1.2 } do
		block(m, Vector3.new(0.3, 3.4, 0.3), cf(x, 2.0, -1.2), white)
	end
	block(m, Vector3.new(0.9, 1.5, 0.1), cf(0, 1.05, -0.82), GOLD, M.Metal)
	for row = 0, 1 do
		for _, x in { -1.8, -1.0, 1.0, 1.8 } do
			glow(m, Vector3.new(0.5, 0.7, 0.06), cf(x, 1.5 + row * 1.7, -0.83), rgb(255, 225, 140))
		end
		for _, x in { -3.8, -3.0, 3.0, 3.8 } do
			glow(m, Vector3.new(0.4, 0.6, 0.06), cf(x, 1.3 + row * 1.1, -0.33), rgb(255, 225, 140))
		end
	end
	octo(m, 1.6, 0.4, CFrame.new(0, 0.3, -3.2), rgb(220, 220, 230))
	glow(m, Vector3.new(0.2, 0.8, 0.2), cf(0, 1.1, -3.2), rgb(130, 220, 255))
end

function builders.LuxuryYacht(m)
	-- A luxury yacht on glowing water: a long white hull with a pointed bow, a dark stripe,
	-- two decks of tinted windows, a gold rail, a radar mast and a little pool on the back.
	water(m, Vector3.new(10.0, 0.25, 9.0), CFrame.new(0, 0.12, 0), 4)
	local white = rgb(248, 248, 250)
	block(m, Vector3.new(3.8, 1.6, 6.4), cf(0, 1.1, 0.8), white)
	wedge(m, Vector3.new(3.8, 1.6, 2.6), cf(0, 1.1, -3.7), white)
	block(m, Vector3.new(3.9, 0.3, 6.5), cf(0, 0.6, 0.8), rgb(30, 40, 70))
	wedge(m, Vector3.new(3.9, 0.3, 2.65), cf(0, 0.6, -3.7), rgb(30, 40, 70))
	block(m, Vector3.new(3.4, 1.2, 4.0), cf(0, 2.5, 0.8), white)
	block(m, Vector3.new(3.45, 0.6, 3.6), cf(0, 2.6, 0.7), rgb(30, 40, 60), M.Glass)
	block(m, Vector3.new(2.6, 1.0, 2.4), cf(0, 3.6, 0.9), white)
	block(m, Vector3.new(2.65, 0.5, 2.0), cf(0, 3.7, 0.8), rgb(30, 40, 60), M.Glass)
	block(m, Vector3.new(3.8, 0.15, 6.4), cf(0, 1.95, 0.8), GOLD, M.Metal)
	block(m, Vector3.new(0.2, 1.8, 0.2), cf(0, 5.0, 1.2), rgb(200, 200, 210), M.Metal)
	block(m, Vector3.new(1.4, 0.15, 0.3), cf(0, 5.6, 1.2), rgb(200, 200, 210), M.Metal)
	glow(m, Vector3.new(0.25, 0.25, 0.25), cf(0, 6.0, 1.2), rgb(255, 60, 60))
	block(m, Vector3.new(2.4, 0.2, 1.2), cf(0, 2.0, 3.4), rgb(80, 180, 230))
	glow(m, Vector3.new(2.2, 0.06, 1.0), cf(0, 2.12, 3.4), rgb(110, 230, 255))
	glow(m, Vector3.new(0.08, 0.15, 5.0), cf(1.95, 1.3, 0.4), rgb(110, 230, 255))
	glow(m, Vector3.new(0.08, 0.15, 5.0), cf(-1.95, 1.3, 0.4), rgb(110, 230, 255))
end

function builders.GoldHelicopter(m)
	-- A solid gold helicopter on a black-and-gold pad.
	octo(m, 9.0, 0.3, CFrame.new(), rgb(30, 30, 36))
	ring(m, 8.6, 0.3, 0.06, CFrame.new(0, 0.32, 0), GOLD, M.Metal, 12)
	local model = Instance.new("Model")
	helicopter(model, rgb(255, 200, 50), rgb(230, 170, 40), rgb(250, 230, 150), rgb(255, 245, 200))
	for _, p in model:GetChildren() do
		p.CFrame = CFrame.new(0, 0.3, -0.6) * p.CFrame
		if p.Material == M.SmoothPlastic and p.Color ~= DARK then
			p.Material = M.Metal
		end
		p.Parent = m
	end
end

function builders.RedSupercar(m)
	-- A low red supercar with gold rims, a spoiler and a pink underglow.
	car(m, rgb(220, 35, 40), rgb(160, 24, 30), GOLD, rgb(255, 60, 200), true)
	block(m, Vector3.new(3.4, 0.15, 0.8), cf(0, 2.65, 3.4), DARK)
	for _, x in { -1.3, 1.3 } do
		block(m, Vector3.new(0.15, 0.6, 0.15), cf(x, 2.3, 3.4), DARK)
	end
end

function builders.GoldSupercar(m)
	-- A solid gold supercar with black glass, diamond rims and a white underglow.
	car(m, rgb(255, 200, 50), rgb(230, 170, 40), rgb(220, 240, 255), rgb(255, 245, 200), true)
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and (p.Color == rgb(255, 200, 50) or p.Color == rgb(230, 170, 40)) then
			p.Material = M.Metal
		end
	end
	block(m, Vector3.new(3.4, 0.15, 0.8), cf(0, 2.65, 3.4), DARK)
	for _, x in { -1.3, 1.3 } do
		block(m, Vector3.new(0.15, 0.6, 0.15), cf(x, 2.3, 3.4), DARK)
	end
end

--------------------------------------------------------------------------------
-- The Enchanted Life
--------------------------------------------------------------------------------

function builders.MagicWand(m)
	-- A magic wand floating over a mossy stone: a dark wood wand with gold bands and a
	-- glowing star on the tip, trailing glowing sparkles in a spiral.
	block(m, Vector3.new(3.4, 1.2, 3.0), cf(0, 0.6, 0, 0, 15, 0), STONE)
	block(m, Vector3.new(3.0, 0.3, 2.6), cf(0, 1.3, 0, 0, 15, 0), rgb(80, 150, 80))
	local wand = cf(0, 4.4, 0, 0, 0, -30)
	block(m, Vector3.new(0.35, 4.6, 0.35), wand, rgb(70, 45, 35))
	for _, y in { -1.6, -0.6, 1.6 } do
		block(m, Vector3.new(0.45, 0.2, 0.45), wand * CFrame.new(0, y, 0), GOLD, M.Metal)
	end
	local tip = wand * CFrame.new(0, 2.7, 0)
	glow(m, Vector3.new(1.1, 1.1, 0.25), tip * CFrame.Angles(0, 0, math.rad(45)), rgb(255, 230, 120))
	glow(m, Vector3.new(1.1, 1.1, 0.25), tip, rgb(255, 230, 120))
	for i = 0, 9 do
		local a = i * 0.8
		glow(
			m,
			Vector3.new(0.2, 0.2, 0.2),
			cf(math.cos(a) * 1.4, 1.8 + i * 0.45, math.sin(a) * 1.4, 45, 45, 0),
			Bricks.RAINBOW[i % 6 + 1]
		)
	end
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = rgb(255, 230, 150)
	sparkles.Parent = m:FindFirstChildWhichIsA("BasePart")
end

function builders.PotionCauldron(m)
	-- A black witch's cauldron on stubby legs over glowing embers, bubbling with glowing
	-- green potion, with a ladle, bubbles floating up and potion bottles beside it.
	for i = 0, 2 do
		block(m, Vector3.new(0.6, 0.4, 2.8), cf(0, 0.3, 0, 0, i * 60, 0), WOOD_DARK)
	end
	glow(m, Vector3.new(1.6, 0.3, 1.6), cf(0, 0.45, 0, 0, 45, 0), rgb(255, 120, 40))
	local black = rgb(36, 34, 44)
	octo(m, 3.2, 0.6, CFrame.new(0, 0.9, 0), black)
	octo(m, 4.2, 1.6, CFrame.new(0, 1.5, 0), black)
	octo(m, 3.6, 0.5, CFrame.new(0, 3.1, 0), black)
	ring(m, 3.8, 0.4, 0.4, CFrame.new(0, 3.75, 0), rgb(60, 58, 70), nil, 10)
	glow(m, Vector3.new(3.0, 0.2, 3.0), cf(0, 3.6, 0, 0, 22, 0), rgb(110, 255, 120))
	for i = 0, 5 do
		glow(
			m,
			Vector3.new(0.4 - i * 0.04, 0.4 - i * 0.04, 0.4 - i * 0.04),
			cf(math.sin(i * 2) * 0.8, 4.0 + i * 0.55, math.cos(i * 2) * 0.6, 45, 45, 0),
			rgb(150, 255, 170)
		)
	end
	block(m, Vector3.new(0.18, 3.0, 0.18), cf(1.0, 4.4, 0.4, 0, 0, -25), WOOD)
	for i, c in { rgb(255, 80, 200), rgb(90, 160, 255), rgb(255, 210, 60) } do
		local x = 2.8 + (i - 2) * 0.7
		block(m, Vector3.new(0.5, 0.7, 0.5), cf(x, 0.35, -1.6), c, M.Glass)
		glow(m, Vector3.new(0.3, 0.4, 0.3), cf(x, 0.3, -1.6), c)
		block(m, Vector3.new(0.2, 0.3, 0.2), cf(x, 0.85, -1.6), WOOD)
	end
end

function builders.CrystalCluster(m)
	-- A cluster of giant crystals bursting from a rock: tall glowing shards in purple, pink
	-- and teal at different angles, each with a lighter glowing heart.
	block(m, Vector3.new(4.4, 1.0, 4.0), cf(0, 0.5, 0, 0, 20, 0), STONE)
	block(m, Vector3.new(3.0, 0.8, 3.2), cf(0.5, 1.2, -0.2, 0, 50, 8), rgb(130, 130, 145))
	local colors = { rgb(170, 90, 255), rgb(255, 110, 210), rgb(80, 220, 230) }
	for i, spec in
		{
			{ 0, 0, 6.0, 0, 0 },
			{ -1.3, 0.6, 4.2, -20, 25 },
			{ 1.3, -0.4, 4.6, 18, -20 },
			{ 0.6, 1.3, 3.2, 10, 30 },
			{ -0.8, -1.2, 3.6, -25, -15 },
			{ 1.7, 1.0, 2.6, 25, 10 },
		}
	do
		local x, z, h, rz, rx = spec[1], spec[2], spec[3], spec[4], spec[5]
		local c = colors[i % 3 + 1]
		local base = cf(x, 1.2, z, rx, i * 30, rz)
		local p = block(m, Vector3.new(h * 0.24, h, h * 0.24), base * CFrame.new(0, h / 2, 0), c, M.Glass)
		p.Transparency = 0.15
		local top =
			wedge(m, Vector3.new(h * 0.24, h * 0.22, h * 0.24), base * CFrame.new(0, h + h * 0.11, 0), c, M.Glass)
		top.Transparency = 0.15
		glow(
			m,
			Vector3.new(h * 0.1, h * 0.8, h * 0.1),
			base * CFrame.new(0, h / 2, 0),
			c:Lerp(Color3.new(1, 1, 1), 0.5)
		)
	end
end

function builders.MushroomHouse(m)
	-- A fairy mushroom house: a fat white stem with a round door and glowing windows, a big
	-- red cap with white spots and a little chimney, a path of stepping stones and lanterns.
	block(m, Vector3.new(7.0, 0.3, 7.0), cf(0, 0.15, 0), rgb(90, 170, 80))
	local stem, red = rgb(245, 235, 210), rgb(220, 50, 55)
	octo(m, 3.6, 4.2, CFrame.new(0, 0.3, 0), stem)
	octo(m, 3.9, 0.4, CFrame.new(0, 0.3, 0), rgb(220, 205, 175))
	octo(m, 1.4, 0.12, cf(0, 1.5, -1.85, 90, 0, 0), WOOD_DARK)
	block(m, Vector3.new(1.4, 1.2, 0.12), cf(0, 0.9, -1.85), WOOD_DARK)
	glow(m, Vector3.new(0.18, 0.18, 0.06), cf(0.4, 1.2, -1.93), GOLD)
	for _, spot in { { -1.0, 3.0 }, { 1.0, 3.2 } } do
		glow(m, Vector3.new(0.6, 0.6, 0.06), cf(spot[1], spot[2], -1.62), rgb(255, 215, 120))
	end
	octo(m, 7.2, 0.8, CFrame.new(0, 4.3, 0), rgb(190, 35, 45))
	octo(m, 6.4, 1.0, CFrame.new(0, 5.0, 0), red)
	octo(m, 4.6, 0.9, CFrame.new(0, 6.0, 0), red)
	octo(m, 2.4, 0.6, CFrame.new(0, 6.9, 0), red)
	for i = 0, 6 do
		local a = i / 7 * math.pi * 2
		local r = if i % 2 == 0 then 2.6 else 1.6
		block(
			m,
			Vector3.new(0.7, 0.2, 0.7),
			cf(math.cos(a) * r, 6.0 + (if r > 2 then -0.1 else 0.9), math.sin(a) * r, 0, i * 25, 0),
			WHITE_PAINT
		)
	end
	block(m, Vector3.new(0.6, 1.4, 0.6), cf(1.4, 7.4, 1.0), STONE)
	for i = 0, 2 do
		octo(m, 0.9, 0.15, CFrame.new(0.2 * i, 0.3, -2.6 - i * 0.9), STONE)
	end
	for _, x in { -2.6, 2.6 } do
		block(m, Vector3.new(0.15, 1.6, 0.15), cf(x, 1.1, -2.6), WOOD_DARK)
		glow(m, Vector3.new(0.45, 0.5, 0.45), cf(x, 2.1, -2.6), rgb(255, 220, 120))
	end
end

function builders.DragonFountain(m)
	-- A dragon fountain: a stone dragon rearing up from a round pool, wings spread, glowing
	-- eyes, spouting a glowing arc of water from its mouth into the pool.
	octo(m, 9.0, 0.9, CFrame.new(), STONE)
	water(m, Vector3.new(7.2, 0.3, 7.2), CFrame.new(0, 0.85, 0) * CFrame.Angles(0, math.rad(22), 0), 4)
	ring(m, 9.0, 0.6, 0.35, CFrame.new(0, 1.05, 0), rgb(175, 175, 185), nil, 8)
	local scale, deep = rgb(70, 140, 120), rgb(46, 100, 90)
	block(m, Vector3.new(2.2, 1.2, 2.2), cf(0, 1.6, 1.2), STONE)
	block(m, Vector3.new(1.8, 3.0, 1.6), cf(0, 3.4, 1.4, -15, 0, 0), scale)
	block(m, Vector3.new(1.2, 2.2, 1.0), cf(0, 5.4, 1.0, 10, 0, 0), scale)
	block(m, Vector3.new(1.6, 1.2, 2.0), cf(0, 6.6, 0.3), scale)
	block(m, Vector3.new(1.1, 0.7, 1.2), cf(0, 6.3, -0.9), scale)
	for _, side in { -1, 1 } do
		glow(m, Vector3.new(0.3, 0.25, 0.08), cf(side * 0.45, 6.9, -0.72), rgb(255, 160, 40))
		wedge(m, Vector3.new(0.3, 1.0, 0.6), cf(side * 0.5, 7.5, 0.8, -30, 0, side * -15), rgb(230, 220, 190))
		local wing = cf(side * 1.6, 5.0, 1.8, 0, side * -20, side * 30)
		block(m, Vector3.new(3.0, 0.2, 1.6), wing, deep)
		wedge(
			m,
			Vector3.new(0.2, 2.6, 2.0),
			wing * CFrame.new(side * 1.0, -1.2, 0) * CFrame.Angles(0, 0, side * -0.5),
			deep
		)
	end
	for i = 0, 3 do
		wedge(m, Vector3.new(0.2, 0.6, 0.6), cf(0, 4.4 + i * 0.7, 2.3 - i * 0.2), rgb(255, 160, 40), M.Neon)
	end
	for i = 0, 6 do
		local t = i / 6
		glow(
			m,
			Vector3.new(0.35, 0.35, 0.35),
			cf(0, 6.2 + math.sin(t * math.pi) * 1.2 - t * 5, -1.4 - t * 2.4),
			rgb(130, 220, 255)
		)
	end
end

--------------------------------------------------------------------------------
-- The Alien Life
--------------------------------------------------------------------------------

function builders.Saturn(m)
	-- A model of Saturn floating over a glowing stand: a banded planet of stacked octagons in
	-- creams and oranges, with a wide tilted ring of glowing bands and two little moons.
	octo(m, 3.0, 0.6, CFrame.new(), rgb(50, 50, 70))
	glow(m, Vector3.new(0.4, 2.0, 0.4), cf(0, 1.6, 0), rgb(150, 120, 255))
	local center = cf(0, 5.0, 0, 0, 0, 15)
	for i, c in { rgb(230, 200, 140), rgb(220, 160, 90), rgb(240, 220, 170), rgb(210, 150, 80), rgb(235, 205, 150) } do
		local y = (i - 3) * 0.65
		local d = 4.2 * math.cos(math.asin(math.clamp(y / 2.3, -0.95, 0.95)))
		octo(m, d, 0.66, center * CFrame.new(0, y - 0.33, 0), c)
	end
	ring(m, 6.8, 0.8, 0.1, center, rgb(240, 220, 170), nil, 16)
	ring(m, 7.8, 0.5, 0.08, center, rgb(255, 200, 120), M.Neon, 16)
	blob(m, 0.7, cf(3.6, 7.0, -0.5), rgb(200, 200, 210))
	blob(m, 0.5, cf(-3.4, 3.4, 0.6), rgb(170, 140, 230))
end

function builders.CrystalReactor(m)
	-- A sci-fi crystal reactor: a heavy metal base with glowing vents, three clamp arms and a
	-- tall glass chamber holding a huge glowing green crystal, with cables and a control panel.
	local metal, deep = rgb(110, 115, 130), rgb(70, 74, 88)
	octo(m, 6.0, 1.2, CFrame.new(), deep)
	octo(m, 4.8, 0.6, CFrame.new(0, 1.2, 0), metal)
	for i = 0, 7 do
		glow(
			m,
			Vector3.new(0.5, 0.2, 0.1),
			CFrame.Angles(0, math.rad(i * 45), 0) * cf(0, 0.6, -2.95),
			rgb(120, 255, 160)
		)
	end
	local glass = block(m, Vector3.new(2.6, 4.4, 2.6), cf(0, 4.0, 0), rgb(180, 255, 220), M.Glass)
	glass.Transparency = 0.6
	gem(m, 1.8, cf(0, 4.0, 0, 0, 0, 0) * CFrame.new(0, 0.6, 0), rgb(110, 255, 150), rgb(170, 255, 200))
	octo(m, 3.2, 0.6, CFrame.new(0, 6.2, 0), metal)
	glow(m, Vector3.new(1.0, 0.2, 1.0), cf(0, 6.85, 0, 0, 45, 0), rgb(120, 255, 160))
	for i = 0, 2 do
		local arm = CFrame.Angles(0, math.rad(i * 120), 0)
		block(m, Vector3.new(0.5, 4.8, 0.5), arm * cf(0, 4.0, 1.6), metal)
		block(m, Vector3.new(0.7, 0.7, 0.9), arm * cf(0, 4.0, 1.5), deep)
		glow(m, Vector3.new(0.15, 3.8, 0.1), arm * cf(0, 4.0, 1.9), rgb(120, 255, 160))
	end
	block(m, Vector3.new(1.6, 1.4, 0.8), cf(2.8, 1.9, -1.6, 0, -30, 0), deep)
	glow(m, Vector3.new(1.2, 0.8, 0.06), cf(2.8, 2.0, -2.02, 0, -30, 0), rgb(90, 220, 255))
end

function builders.UFO(m)
	-- A flying saucer hovering over glowing landing marks: a wide silver disc of stepped
	-- octagons, a glass dome with a little alien inside, a ring of glowing lights and a
	-- tractor beam underneath.
	ring(m, 7.0, 0.3, 0.06, CFrame.new(0, 0.05, 0), rgb(120, 255, 120), M.Neon, 12)
	local beam = block(m, Vector3.new(3.0, 3.2, 3.0), cf(0, 1.6, 0, 0, 45, 0), rgb(150, 255, 170), M.Neon)
	beam.Transparency = 0.6
	local silver, deep = rgb(200, 205, 215), rgb(140, 146, 160)
	octo(m, 4.0, 0.5, CFrame.new(0, 3.2, 0), deep, M.Metal)
	octo(m, 8.4, 0.7, CFrame.new(0, 3.7, 0), silver, M.Metal)
	octo(m, 6.6, 0.5, CFrame.new(0, 4.4, 0), silver, M.Metal)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		glow(
			m,
			Vector3.new(0.4, 0.3, 0.4),
			cf(math.cos(a) * 3.9, 4.0, math.sin(a) * 3.9),
			if i % 2 == 0 then rgb(120, 255, 120) else rgb(255, 230, 90)
		)
	end
	local dome = octo(m, 3.4, 1.6, CFrame.new(0, 4.9, 0), rgb(160, 230, 255), M.Glass)
	dome.Transparency = 0.4
	octo(m, 2.2, 0.6, CFrame.new(0, 6.5, 0), rgb(160, 230, 255), M.Glass)
	block(m, Vector3.new(1.0, 1.0, 1.0), cf(0, 5.6, 0), rgb(120, 210, 110))
	for _, side in { -1, 1 } do
		glow(m, Vector3.new(0.3, 0.25, 0.06), cf(side * 0.25, 5.7, -0.52), DARK)
	end
end

function builders.TeleportPortal(m)
	-- A teleport portal: a ring of dark metal segments with glowing blue runes standing on a
	-- stepped platform, with a swirling glowing vortex inside and floating sparks.
	octo(m, 7.0, 0.4, CFrame.new(), rgb(60, 60, 80))
	octo(m, 5.6, 0.4, CFrame.new(0, 0.4, 0), rgb(80, 80, 104))
	local center = cf(0, 4.2, 0, 90, 0, 0)
	ring(m, 6.4, 0.9, 0.8, center, rgb(50, 50, 70), M.Metal, 14)
	for i = 0, 13 do
		local a = i / 14 * math.pi * 2
		glow(
			m,
			Vector3.new(0.3, 0.12, 0.3),
			center * CFrame.Angles(0, -a, 0) * CFrame.new(0, 0.42, 3.2),
			rgb(90, 200, 255)
		)
	end
	for i, c in { rgb(60, 120, 255), rgb(120, 90, 255), rgb(90, 220, 255), rgb(200, 150, 255) } do
		local s = 5.4 - i * 1.15
		local p = glow(m, Vector3.new(s, s, 0.08), cf(0, 4.2, -0.05 * i, 0, 0, i * 20), c)
		p.Transparency = 0.15 * (i - 1)
	end
	for i = 0, 5 do
		local a = i * 1.1
		glow(
			m,
			Vector3.new(0.2, 0.2, 0.2),
			cf(math.cos(a) * 3.8, 4.2 + math.sin(a) * 3.8, -0.8, 45, 45, 0),
			rgb(200, 240, 255)
		)
	end
end

--------------------------------------------------------------------------------
-- The Ultimate Life
--------------------------------------------------------------------------------

-- A fluffy cloud of white blocks round `at`, `size` across.
local function cloud(m, at: CFrame, size: number)
	for i = 0, 6 do
		local a = i * 1.7
		local s = size * (0.35 + (i % 3) * 0.1)
		block(
			m,
			Vector3.new(s, s * 0.6, s),
			at * CFrame.new(math.cos(a) * size * 0.28, (i % 2) * size * 0.08, math.sin(a) * size * 0.2),
			rgb(250, 250, 255)
		)
	end
end

function builders.CelestialCrown(m)
	-- A celestial crown on a cloud cushion: a band of gold with tall points, each tipped with
	-- a glowing star, set with gems, and a glowing halo floating above.
	cloud(m, CFrame.new(0, 0.8, 0), 6.0)
	block(m, Vector3.new(3.8, 0.4, 3.8), cf(0, 1.6, 0, 0, 45, 0), rgb(120, 60, 200))
	ring(m, 3.4, 0.4, 1.2, CFrame.new(0, 2.5, 0), GOLD, M.Metal, 10)
	for i = 0, 6 do
		local a = i / 7 * 360
		local spot = CFrame.Angles(0, math.rad(a), 0) * CFrame.new(0, 3.6, 1.7)
		wedge(m, Vector3.new(0.6, 1.6, 0.3), spot, GOLD, M.Metal)
		glow(
			m,
			Vector3.new(0.35, 0.35, 0.12),
			spot * CFrame.new(0, 1.0, 0) * CFrame.Angles(0, 0, math.rad(45)),
			rgb(255, 250, 200)
		)
		glow(
			m,
			Vector3.new(0.3, 0.3, 0.1),
			CFrame.Angles(0, math.rad(a + 25), 0) * CFrame.new(0, 2.5, 1.78),
			Bricks.RAINBOW[i % 6 + 1]
		)
	end
	ring(m, 3.0, 0.2, 0.1, CFrame.new(0, 5.4, 0), rgb(255, 245, 190), M.Neon, 12)
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = rgb(255, 240, 180)
	sparkles.Parent = m:FindFirstChildWhichIsA("BasePart")
end

function builders.GoldenPalace(m)
	-- A golden palace on a floating cloud island: a gold hall with columns, a big central dome
	-- with a spire, four corner towers with onion domes and glowing windows.
	cloud(m, CFrame.new(0, 0.7, 0), 9.0)
	block(m, Vector3.new(7.0, 0.4, 6.0), cf(0, 1.4, 0), rgb(250, 245, 230))
	local gold, deep = rgb(255, 200, 50), rgb(230, 170, 40)
	block(m, Vector3.new(5.0, 2.6, 4.0), cf(0, 2.9, 0.3), gold, M.Metal)
	for _, x in { -2.0, -1.0, 0, 1.0, 2.0 } do
		block(m, Vector3.new(0.35, 2.6, 0.35), cf(x, 2.9, -1.9), rgb(250, 245, 230))
		glow(m, Vector3.new(0.4, 0.9, 0.06), cf(x + 0.5, 3.0, -1.72), rgb(255, 235, 170))
	end
	octo(m, 3.0, 1.0, CFrame.new(0, 4.2, 0.3), deep, M.Metal)
	octo(m, 2.4, 0.8, CFrame.new(0, 5.2, 0.3), gold, M.Metal)
	octo(m, 1.4, 0.6, CFrame.new(0, 6.0, 0.3), gold, M.Metal)
	block(m, Vector3.new(0.2, 1.6, 0.2), cf(0, 7.4, 0.3), gold, M.Metal)
	glow(m, Vector3.new(0.4, 0.4, 0.4), cf(0, 8.3, 0.3, 45, 45, 0), rgb(255, 250, 200))
	for _, x in { -3.0, 3.0 } do
		for _, z in { -2.4, 2.6 } do
			octo(m, 1.2, 3.8, CFrame.new(x, 1.6, z), rgb(250, 245, 230))
			octo(m, 1.4, 0.6, CFrame.new(x, 5.4, z), deep, M.Metal)
			octo(m, 0.9, 0.5, CFrame.new(x, 6.0, z), gold, M.Metal)
			glow(m, Vector3.new(0.3, 0.6, 0.3), cf(x, 6.8, z), rgb(255, 250, 200))
		end
	end
end

function builders.RainbowWaterfall(m)
	-- A rainbow waterfall: a cloud cliff with water pouring down in six glowing rainbow
	-- bands into a sparkling pool, with a rainbow arching over the top.
	octo(m, 8.0, 0.5, CFrame.new(), rgb(220, 225, 240))
	water(m, Vector3.new(6.6, 0.25, 4.0), CFrame.new(0, 0.5, -1.0), 3)
	block(m, Vector3.new(7.0, 6.4, 2.4), cf(0, 3.2, 2.2), rgb(220, 225, 240))
	cloud(m, CFrame.new(0, 6.8, 2.2), 7.6)
	for i, c in Bricks.RAINBOW do
		local x = -1.9 + (i - 1) * 0.76
		local band = glow(m, Vector3.new(0.72, 5.8, 0.3), cf(x, 3.4, 0.85), c)
		band.Transparency = 0.1
	end
	for i, c in Bricks.RAINBOW do
		local r = 4.8 - i * 0.35
		for k = 0, 10 do
			local a = k / 10 * math.pi
			glow(m, Vector3.new(0.4, 0.36, 0.4), cf(math.cos(a) * r, 6.5 + math.sin(a) * r * 0.6, 3.2), c)
		end
	end
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = rgb(255, 255, 255)
	sparkles.Parent = m:FindFirstChildWhichIsA("BasePart")
end

function builders.LivingPlanet(m)
	-- A living planet: a little blue-and-green world floating over a glowing stand, with
	-- blocky continents, white clouds, a happy face with glowing eyes and a tiny moon.
	octo(m, 3.0, 0.6, CFrame.new(), rgb(50, 50, 70))
	glow(m, Vector3.new(0.4, 1.6, 0.4), cf(0, 1.4, 0), rgb(120, 200, 255))
	local center = CFrame.new(0, 5.0, 0)
	blob(m, 5.0, center, rgb(60, 140, 230))
	for i, spot in
		{ { -1.2, 0.6, -1.9 }, { 1.4, -0.4, -1.8 }, { 0.2, 1.4, -1.5 }, { -2.0, -0.6, 0.6 }, { 1.8, 0.8, 1.2 } }
	do
		block(
			m,
			Vector3.new(1.4, 1.0, 1.0),
			center * CFrame.new(spot[1], spot[2], spot[3]) * CFrame.Angles(0, i, 0),
			if i % 2 == 0 then rgb(90, 190, 90) else rgb(70, 160, 80)
		)
	end
	for _, spot in { { -0.6, 2.0, -0.4 }, { 1.5, 1.3, -1.0 } } do
		block(m, Vector3.new(1.6, 0.4, 1.0), center * CFrame.new(spot[1], spot[2], spot[3]), rgb(250, 250, 255))
	end
	for _, side in { -1, 1 } do
		glow(m, Vector3.new(0.4, 0.5, 0.1), center * CFrame.new(side * 0.6, 0.2, -2.6), rgb(255, 255, 255))
		block(m, Vector3.new(0.2, 0.3, 0.05), center * CFrame.new(side * 0.6, 0.15, -2.68), DARK)
	end
	block(m, Vector3.new(1.0, 0.15, 0.1), center * CFrame.new(0, -0.6, -2.62), DARK)
	blob(m, 1.0, cf(3.4, 7.2, 0.5), rgb(220, 220, 230))
end

function builders.MiniGalaxy(m)
	-- A miniature galaxy in a glass dome: a swirling spiral of glowing stars in purples, blues
	-- and pinks round a bright core, on a gold stand.
	octo(m, 4.0, 0.6, CFrame.new(), GOLD, M.Metal)
	octo(m, 3.4, 0.4, CFrame.new(0, 0.6, 0), rgb(40, 30, 70))
	-- A glass dome: thin glowing ribs and a rim, so the galaxy inside shows.
	ring(m, 6.4, 0.3, 0.3, CFrame.new(0, 1.15, 0), GOLD, M.Metal, 12)
	for i = 0, 5 do
		local rib = CFrame.Angles(0, math.rad(i * 30), 0)
		for k = 0, 4 do
			local a = k / 4 * math.pi / 2
			local p = block(
				m,
				Vector3.new(0.12, 1.4, 0.12),
				rib * CFrame.new(math.cos(a) * 3.1, 1.2 + math.sin(a) * 4.0, 0) * CFrame.Angles(0, 0, a),
				rgb(190, 210, 255),
				M.Glass
			)
			p.Transparency = 0.4
			local q = block(
				m,
				Vector3.new(0.12, 1.4, 0.12),
				rib * CFrame.new(-math.cos(a) * 3.1, 1.2 + math.sin(a) * 4.0, 0) * CFrame.Angles(0, 0, -a),
				rgb(190, 210, 255),
				M.Glass
			)
			q.Transparency = 0.4
		end
	end
	local center = cf(0, 3.8, 0, 15, 0, 10)
	glow(m, Vector3.new(0.9, 0.9, 0.9), center * CFrame.Angles(0, math.rad(45), 0), rgb(255, 245, 210))
	local colors = { rgb(170, 110, 255), rgb(90, 160, 255), rgb(255, 120, 220), rgb(255, 255, 255) }
	for arm = 0, 1 do
		for i = 0, 15 do
			local t = i / 15
			local a = arm * math.pi + t * math.pi * 1.6
			local r = 0.6 + t * 2.4
			local s = 0.35 - t * 0.15
			glow(m, Vector3.new(s, s, s), center * CFrame.new(math.cos(a) * r, 0, math.sin(a) * r), colors[i % 4 + 1])
		end
	end
	local light = Instance.new("PointLight")
	light.Color = rgb(190, 150, 255)
	light.Range = 12
	light.Parent = m:FindFirstChildWhichIsA("BasePart")
end

function builders.PocketUniverse(m)
	-- A pocket universe: a floating black cube with a whole starry universe inside its glass
	-- walls (planets, a glowing sun, a nebula of rainbow lights), its edges lit gold, slowly
	-- spinning on a glowing pedestal.
	octo(m, 3.6, 0.8, CFrame.new(), rgb(30, 25, 45))
	glow(m, Vector3.new(0.5, 1.8, 0.5), cf(0, 1.7, 0), rgb(200, 150, 255))
	local center = cf(0, 5.4, 0, 35, 45, 0)
	local box = block(m, Vector3.new(4.4, 4.4, 4.4), center, rgb(20, 15, 40), M.Glass)
	box.Transparency = 0.35
	for _, edge in
		{
			{ 1, 1, 0 },
			{ 1, -1, 0 },
			{ -1, 1, 0 },
			{ -1, -1, 0 },
			{ 1, 0, 1 },
			{ 1, 0, -1 },
			{ -1, 0, 1 },
			{ -1, 0, -1 },
			{ 0, 1, 1 },
			{ 0, 1, -1 },
			{ 0, -1, 1 },
			{ 0, -1, -1 },
		}
	do
		local size = Vector3.new(
			if edge[1] == 0 then 4.5 else 0.18,
			if edge[2] == 0 then 4.5 else 0.18,
			if edge[3] == 0 then 4.5 else 0.18
		)
		glow(m, size, center * CFrame.new(edge[1] * 2.2, edge[2] * 2.2, edge[3] * 2.2), GOLD)
	end
	glow(m, Vector3.new(0.9, 0.9, 0.9), center * CFrame.Angles(0.3, 0.3, 0), rgb(255, 220, 120))
	blob(m, 0.8, center * CFrame.new(1.2, 0.6, -0.8), rgb(90, 160, 255))
	blob(m, 0.6, center * CFrame.new(-1.1, -0.9, 0.6), rgb(255, 120, 90))
	for i = 0, 17 do
		local a = i * 2.4
		glow(
			m,
			Vector3.new(0.14, 0.14, 0.14),
			center * CFrame.new(math.cos(a) * 1.7, (i % 6 - 2.5) * 0.6, math.sin(a) * 1.7),
			Bricks.RAINBOW[i % 6 + 1]
		)
	end
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = rgb(220, 200, 255)
	sparkles.Parent = m:FindFirstChildWhichIsA("BasePart")
end

--------------------------------------------------------------------------------
-- Kept from before (Garden Gnome, Hot Tub, Garden Fountain, Rocket Ship)
--------------------------------------------------------------------------------

function builders.GardenGnome(m)
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

function builders.GardenFountain(m)
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

function builders.RocketShip(m)
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
