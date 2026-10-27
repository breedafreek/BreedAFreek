-- Yard items, built from bricks. YardModel.build(itemId) returns a model standing on its
-- pivot (the middle of its footprint, front facing -Z) that fits a yard spot (about 11 x 11
-- studs).

local Bricks = require(script.Parent.Bricks)
local Items = require(script.Parent.Items)

local YardModel = {}

local rgb, block, ball, post, rod, cone, wedge =
	Bricks.rgb, Bricks.block, Bricks.ball, Bricks.post, Bricks.rod, Bricks.cone, Bricks.wedge
local M = Enum.Material
local WOOD = rgb(170, 115, 65)
local DARK = rgb(45, 45, 55)
local WATER = rgb(70, 190, 255)

local builders = {}

function builders.Gnome(m)
	post(m, 0.6, 3, CFrame.new(0, 0, 0), rgb(120, 200, 90)) -- grass tuft base
	cone(m, 2.4, 2.2, CFrame.new(0, 0.6, 0), rgb(60, 120, 230), nil, 4) -- body
	ball(m, 1.6, CFrame.new(0, 3.2, 0), rgb(255, 205, 170)) -- face
	ball(m, Vector3.new(1.5, 1.2, 1), CFrame.new(0, 2.7, -0.45), rgb(255, 255, 255)) -- beard
	ball(m, 0.45, CFrame.new(0, 3.25, -0.8), rgb(255, 150, 140)) -- nose
	cone(m, 2.2, 1.7, CFrame.new(0, 3.6, 0), rgb(230, 50, 60), nil, 5) -- hat
	for _, x in { -0.35, 0.35 } do
		ball(m, 0.25, CFrame.new(x, 3.5, -0.72), rgb(30, 30, 40))
	end
end

function builders.Lemonade(m)
	block(m, Vector3.new(6, 3.2, 3), CFrame.new(0, 1.6, 0), WOOD)
	block(m, Vector3.new(6.3, 0.4, 3.3), CFrame.new(0, 3.3, 0), rgb(255, 230, 90))
	for _, x in { -2.8, 2.8 } do
		block(m, Vector3.new(0.4, 4, 0.4), CFrame.new(x, 5.2, 1.2), WOOD)
	end
	-- Striped canopy.
	for i = 0, 5 do
		block(
			m,
			Vector3.new(1.1, 0.3, 3.4),
			CFrame.new(-2.75 + i * 1.1, 7.3, 0.5) * CFrame.Angles(math.rad(15), 0, 0),
			if i % 2 == 0 then rgb(255, 230, 60) else rgb(255, 255, 255)
		)
	end
	post(m, 1.4, 0.9, CFrame.new(-1.6, 3.5, -0.5), rgb(255, 235, 120), M.Glass)
	for i = 0, 2 do
		post(m, 0.7, 0.45, CFrame.new(0.2 + i * 0.7, 3.5, -0.6), rgb(255, 240, 150), M.Glass)
	end
	block(m, Vector3.new(4, 1.2, 0.2), CFrame.new(0, 1.8, -1.6), rgb(255, 255, 255))
	block(m, Vector3.new(3.4, 0.5, 0.25), CFrame.new(0, 1.8, -1.65), rgb(255, 200, 40))
end

function builders.Grill(m)
	block(m, Vector3.new(5, 2.4, 2.6), CFrame.new(0, 2.6, 0), rgb(200, 40, 50))
	block(m, Vector3.new(5.2, 0.5, 2.8), CFrame.new(0, 4, 0), DARK)
	for i = 0, 4 do
		block(m, Vector3.new(0.15, 0.2, 2.6), CFrame.new(-2 + i, 4.3, 0), rgb(150, 150, 160), M.Metal)
	end
	for i, food in { rgb(140, 70, 40), rgb(230, 120, 80), rgb(140, 70, 40) } do
		rod(m, 1.4, 0.45, CFrame.new(-1.5 + i, 4.6, 0) * CFrame.Angles(0, math.pi / 2, 0), food)
	end
	for _, x in { -2.2, 2.2 } do
		block(m, Vector3.new(0.4, 1.4, 0.4), CFrame.new(x, 0.7, -1), DARK)
		local wheel = rod(m, 0.4, 1, CFrame.new(x, 0.5, 1), DARK)
		wheel.CFrame = CFrame.new(x, 0.5, 1)
	end
	block(m, Vector3.new(1.2, 0.2, 2.6), CFrame.new(3.1, 3.6, 0), WOOD) -- side shelf
	ball(m, 0.8, CFrame.new(-0.5, 5.8, 0), rgb(220, 220, 225))
	ball(m, 1, CFrame.new(0.1, 6.6, 0), rgb(235, 235, 240))
end

function builders.Swing(m)
	local red = rgb(230, 60, 60)
	for _, x in { -4.5, 4.5 } do
		for _, z in { -1.6, 1.6 } do
			block(
				m,
				Vector3.new(0.6, 7.6, 0.6),
				CFrame.new(x, 3.6, z * 0.7) * CFrame.Angles(math.rad(z * 8), 0, 0),
				red
			)
		end
	end
	block(m, Vector3.new(9.8, 0.7, 0.7), CFrame.new(0, 7.3, 0), rgb(60, 140, 255))
	for i, x in { -2, 2 } do
		for _, rx in { -0.9, 0.9 } do
			block(m, Vector3.new(0.12, 4.6, 0.12), CFrame.new(x + rx, 4.9, 0), rgb(80, 80, 90))
		end
		block(
			m,
			Vector3.new(2.2, 0.3, 1),
			CFrame.new(x, 2.5, 0),
			if i == 1 then rgb(255, 210, 50) else rgb(80, 210, 120)
		)
	end
	-- A little slide on the side.
	wedge(m, Vector3.new(1.8, 3.4, 4.6), CFrame.new(6.6, 1.7, -1.5), rgb(255, 210, 50))
end

function builders.Trampoline(m)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		block(m, Vector3.new(0.5, 1.6, 0.5), CFrame.new(math.cos(a) * 4, 0.8, math.sin(a) * 4), DARK)
		block(m, Vector3.new(0.3, 4.5, 0.3), CFrame.new(math.cos(a) * 4.6, 3.6, math.sin(a) * 4.6), rgb(60, 140, 255))
	end
	rod(m, 0.6, 9.6, CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.pi / 2), rgb(60, 140, 255))
	rod(m, 0.7, 8, CFrame.new(0, 1.75, 0) * CFrame.Angles(0, 0, math.pi / 2), DARK)
	-- A padded ring round the top of the net poles.
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		block(
			m,
			Vector3.new(2.5, 0.35, 0.35),
			CFrame.new(math.cos(a) * 4.6, 5.8, math.sin(a) * 4.6) * CFrame.Angles(0, -a + math.pi / 2, 0),
			rgb(255, 220, 60)
		)
	end
	ball(m, 1.2, CFrame.new(1, 3.8, 0.5), rgb(255, 90, 90)) -- a bouncy ball mid-air
end

function builders.KiddiePool(m)
	rod(m, 1.4, 8, CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, math.pi / 2), rgb(80, 150, 255))
	rod(m, 1.42, 6.6, CFrame.new(0, 0.72, 0) * CFrame.Angles(0, 0, math.pi / 2), WATER, M.Glass)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		ball(
			m,
			0.7,
			CFrame.new(math.cos(a) * 3.7, 1.4, math.sin(a) * 3.7),
			if k % 2 == 0 then rgb(255, 255, 255) else rgb(255, 90, 90)
		)
	end
	-- A rubber duck.
	ball(m, Vector3.new(1.4, 1, 1.8), CFrame.new(0.8, 1.6, 0.5), rgb(255, 220, 40))
	ball(m, 0.9, CFrame.new(0.8, 2.3, -0.1), rgb(255, 220, 40))
	block(m, Vector3.new(0.5, 0.2, 0.5), CFrame.new(0.8, 2.25, -0.6), rgb(255, 140, 30))
end

function builders.HotTub(m)
	block(m, Vector3.new(8, 2.6, 8), CFrame.new(0, 1.3, 0), WOOD)
	block(m, Vector3.new(7, 0.3, 7), CFrame.new(0, 2.5, 0), rgb(80, 230, 255), M.Neon)
	for _, x in { -3.9, 3.9 } do
		block(m, Vector3.new(0.4, 0.4, 8.2), CFrame.new(x, 2.7, 0), rgb(130, 85, 45))
	end
	block(m, Vector3.new(3, 0.8, 1.6), CFrame.new(0, 0.4, -4.8), rgb(130, 85, 45)) -- step
	for k = 0, 9 do
		ball(
			m,
			0.4 + (k % 3) * 0.15,
			CFrame.new(math.sin(k * 2.4) * 2.5, 2.9, math.cos(k * 1.7) * 2.5),
			rgb(230, 250, 255)
		)
	end
end

function builders.Fountain(m)
	local stone = rgb(200, 200, 210)
	rod(m, 1.6, 9, CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.pi / 2), stone)
	rod(m, 1.62, 7.6, CFrame.new(0, 0.85, 0) * CFrame.Angles(0, 0, math.pi / 2), WATER, M.Glass)
	post(m, 4, 1.4, CFrame.new(0, 1, 0), stone)
	rod(m, 0.8, 4.4, CFrame.new(0, 4.6, 0) * CFrame.Angles(0, 0, math.pi / 2), stone)
	rod(m, 0.82, 3.4, CFrame.new(0, 4.65, 0) * CFrame.Angles(0, 0, math.pi / 2), WATER, M.Glass)
	post(m, 2, 0.8, CFrame.new(0, 5, 0), stone)
	ball(m, 1.4, CFrame.new(0, 7.4, 0), WATER, M.Glass)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		ball(m, 0.5, CFrame.new(math.cos(a) * 1.6, 6.2, math.sin(a) * 1.6), rgb(150, 220, 255), M.Glass)
	end
end

function builders.Treehouse(m)
	block(m, Vector3.new(2, 7, 2), CFrame.new(0, 3.5, 0), rgb(120, 80, 50))
	block(m, Vector3.new(7, 0.6, 7), CFrame.new(0, 7.2, 0), WOOD)
	block(m, Vector3.new(5, 3.6, 4.4), CFrame.new(0, 9.3, 0.4), rgb(230, 170, 90))
	block(m, Vector3.new(1.4, 2.2, 0.3), CFrame.new(0, 8.6, -1.85), rgb(110, 70, 40))
	block(m, Vector3.new(1.2, 1.2, 0.3), CFrame.new(1.6, 9.6, -1.85), rgb(150, 220, 255))
	for _, side in { 1, -1 } do
		wedge(
			m,
			Vector3.new(5.6, 2, 2.6),
			CFrame.new(0, 12.1, 0.4 + side * -1.3) * CFrame.Angles(0, if side == 1 then 0 else math.pi, 0),
			rgb(220, 60, 60)
		)
	end
	-- Leaves round the top and a ladder.
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2 + 0.4
		block(m, Vector3.new(3.4, 2.6, 3.4), CFrame.new(math.cos(a) * 3.6, 10.5, math.sin(a) * 3.6), rgb(70, 170, 70))
	end
	for i = 0, 5 do
		block(m, Vector3.new(1.6, 0.25, 0.25), CFrame.new(2.2, 1 + i * 1.1, -2.3), WOOD)
	end
	for _, x in { 1.5, 2.9 } do
		block(m, Vector3.new(0.25, 7, 0.25), CFrame.new(x, 3.5, -2.3), WOOD)
	end
end

function builders.SportsCar(m)
	local red = rgb(230, 30, 40)
	block(m, Vector3.new(4.6, 1.4, 9), CFrame.new(0, 1.3, 0), red)
	block(m, Vector3.new(4, 1.2, 4.2), CFrame.new(0, 2.6, 0.6), red)
	block(
		m,
		Vector3.new(3.8, 1.1, 0.2),
		CFrame.new(0, 2.6, -1.55) * CFrame.Angles(math.rad(-30), 0, 0),
		rgb(160, 220, 255),
		M.Glass
	)
	block(m, Vector3.new(4.8, 0.3, 1), CFrame.new(0, 3, 4.3), DARK) -- spoiler
	for _, x in { -1.6, 1.6 } do
		block(m, Vector3.new(0.3, 0.8, 0.3), CFrame.new(x, 2.4, 4.3), DARK)
	end
	for _, x in { -2.3, 2.3 } do
		for _, z in { -3, 3 } do
			local wheel = rod(m, 0.8, 1.8, CFrame.new(x, 0.9, z), DARK)
			wheel.CFrame = CFrame.new(x, 0.9, z)
			rod(m, 0.85, 0.9, CFrame.new(x, 0.9, z), rgb(200, 200, 210), M.Metal)
		end
	end
	for _, x in { -1.6, 1.6 } do
		block(m, Vector3.new(0.9, 0.4, 0.2), CFrame.new(x, 1.5, -4.5), rgb(255, 250, 200), M.Neon)
	end
	block(m, Vector3.new(4.7, 0.3, 0.3), CFrame.new(0, 1.9, -4.5), rgb(255, 255, 255))
end

function builders.Pool(m)
	local tile = rgb(240, 240, 245)
	block(m, Vector3.new(11, 0.6, 11), CFrame.new(0, 0.3, 0), tile)
	block(m, Vector3.new(9, 0.62, 9), CFrame.new(0, 0.32, 0), WATER, M.Glass)
	block(m, Vector3.new(8.6, 0.1, 8.6), CFrame.new(0, 0.05, 0), rgb(40, 130, 230))
	-- Diving board and ladder.
	block(m, Vector3.new(1.4, 0.3, 4), CFrame.new(-3, 1.6, -5.6), rgb(60, 140, 255))
	block(m, Vector3.new(1.4, 1.3, 0.8), CFrame.new(-3, 0.75, -7.2), tile)
	for _, x in { 3, 4 } do
		rod(m, 0.2, 2.4, CFrame.new(x, 1.4, -4.3) * CFrame.Angles(0, 0, math.pi / 2), rgb(200, 200, 210), M.Metal)
	end
	-- A floaty ring.
	rod(m, 0.6, 2.2, CFrame.new(1.5, 0.75, 1.5) * CFrame.Angles(0, 0, math.pi / 2), rgb(255, 90, 140))
	rod(m, 0.62, 1.2, CFrame.new(1.5, 0.76, 1.5) * CFrame.Angles(0, 0, math.pi / 2), WATER, M.Glass)
end

function builders.Rocket(m)
	local white = rgb(245, 245, 250)
	post(m, 9, 3.4, CFrame.new(0, 1.5, 0), white)
	cone(m, 3.6, 3.4, CFrame.new(0, 10.5, 0), rgb(230, 40, 60), nil, 6)
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		wedge(
			m,
			Vector3.new(0.4, 3, 2.4),
			CFrame.new(math.cos(a) * 2.2, 2.7, math.sin(a) * 2.2) * CFrame.Angles(0, -a + math.pi / 2, 0),
			rgb(230, 40, 60)
		)
	end
	rod(m, 0.3, 1.6, CFrame.new(0, 7.5, -1.62) * CFrame.Angles(0, math.pi / 2, 0), rgb(120, 200, 255), M.Glass)
	rod(m, 0.25, 2, CFrame.new(0, 7.5, -1.58) * CFrame.Angles(0, math.pi / 2, 0), rgb(255, 200, 60), M.Foil)
	post(m, 1.2, 2.2, CFrame.new(0, 0.3, 0), DARK)
	-- Flames.
	cone(m, 1.6, 2, CFrame.new(0, -1.3, 0) * CFrame.Angles(math.pi, 0, 0), rgb(255, 150, 30), M.Neon, 3)
	-- Launch pad.
	block(m, Vector3.new(7, 0.4, 7), CFrame.new(0, 0.2, 0), rgb(120, 120, 135))
	for i, color in Bricks.RAINBOW do
		block(m, Vector3.new(0.4, 0.42, 1), CFrame.new(-3 + i * 0.86, 0.22, -3.4), color, M.Neon)
	end
end

function YardModel.build(itemId: string): Model
	local item = Items.byId[itemId]
	local model = Instance.new("Model")
	model.Name = itemId
	model:SetAttribute("Item", itemId)
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
