-- Plants, built from bricks. PlantModel.build(itemId) returns a model standing on its pivot
-- (the middle of a garden bed, about 7 x 7 studs).

local Bricks = require(script.Parent.Bricks)
local Items = require(script.Parent.Items)

local PlantModel = {}

local rgb, block, ball, post = Bricks.rgb, Bricks.block, Bricks.ball, Bricks.post
local M = Enum.Material
local STEM = rgb(70, 165, 70)
local LEAF = rgb(60, 180, 75)
local TRUNK = rgb(125, 85, 50)

-- A flower head: `petals` blocks round a centre ball, facing -Z.
local function flower(m, cf: CFrame, size: number, petal: Color3, middle: Color3, petals: number?)
	local n = petals or 8
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		ball(
			m,
			Vector3.new(size * 0.55, size * 0.3, size * 0.15),
			cf * CFrame.Angles(0, 0, a) * CFrame.new(size * 0.45, 0, 0),
			petal
		)
	end
	ball(m, Vector3.new(size * 0.45, size * 0.45, size * 0.25), cf * CFrame.new(0, 0, -0.05), middle)
end

local function leaves(m, cf: CFrame, size: number)
	for _, side in { -1, 1 } do
		ball(
			m,
			Vector3.new(size, size * 0.3, size * 0.55),
			cf * CFrame.new(side * size * 0.45, 0, 0) * CFrame.Angles(0, 0, math.rad(side * 25)),
			LEAF
		)
	end
end

-- A tree of stacked leaf bricks (like the town trees).
local function brickTree(m, height: number, width: number, colors: { Color3 }, trunk: Color3?)
	block(m, Vector3.new(width * 0.2, height * 0.45, width * 0.2), CFrame.new(0, height * 0.225, 0), trunk or TRUNK)
	local y = height * 0.38
	local layers = #colors
	for i, color in colors do
		local w = width * (1 - (i - 1) / (layers + 1))
		local h = height * 0.62 / layers
		block(
			m,
			Vector3.new(w, h, w),
			CFrame.new(0, y + h / 2, 0) * CFrame.Angles(0, if i % 2 == 0 then math.rad(45) else 0, 0),
			color
		)
		y += h
	end
	return y
end

local builders = {}

function builders.Daisy(m)
	for i, x in { -1.6, 0, 1.6 } do
		local h = 2.4 + (i % 2) * 0.8
		post(m, h, 0.25, CFrame.new(x, 0, (i % 2) * 0.8), STEM)
		flower(m, CFrame.new(x, h, (i % 2) * 0.8), 1.4, rgb(255, 255, 255), rgb(255, 210, 40))
		leaves(m, CFrame.new(x, h * 0.4, (i % 2) * 0.8), 0.9)
	end
end

function builders.Tulip(m)
	for i, x in { -1.8, 0, 1.8 } do
		local h = 3 + (i % 2) * 0.7
		local color = ({ rgb(255, 70, 110), rgb(255, 200, 40), rgb(190, 90, 255) })[i]
		post(m, h, 0.3, CFrame.new(x, 0, 0), STEM)
		ball(m, Vector3.new(1.2, 1.5, 1.2), CFrame.new(x, h + 0.6, 0), color)
		for k = 0, 2 do
			local a = k / 3 * math.pi * 2
			ball(m, Vector3.new(0.5, 1, 0.5), CFrame.new(x + math.cos(a) * 0.4, h + 1.2, math.sin(a) * 0.4), color)
		end
		leaves(m, CFrame.new(x, 0.9, 0), 1.1)
	end
end

function builders.Sunflower(m)
	post(m, 7, 0.5, CFrame.new(0, 0, 0), STEM)
	leaves(m, CFrame.new(0, 2.5, 0), 1.6)
	leaves(m, CFrame.new(0, 4.5, 0) * CFrame.Angles(0, math.pi / 2, 0), 1.4)
	local head = CFrame.new(0, 7.4, -0.3) * CFrame.Angles(math.rad(-15), 0, 0)
	flower(m, head, 3.6, rgb(255, 210, 30), rgb(120, 70, 30), 12)
	-- A face, for fun.
	for _, x in { -0.35, 0.35 } do
		ball(m, 0.3, head * CFrame.new(x, 0.25, -0.5), rgb(30, 25, 20))
	end
end

function builders.RoseBush(m)
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		ball(m, 2.6, CFrame.new(math.cos(a) * 1.4, 1.4 + (k % 2) * 0.5, math.sin(a) * 1.4), LEAF)
	end
	ball(m, 2.8, CFrame.new(0, 2.6, 0), rgb(50, 160, 65))
	for k = 0, 8 do
		local a = k / 9 * math.pi * 2
		ball(m, 0.8, CFrame.new(math.cos(a) * 1.9, 2 + (k % 3) * 0.6, math.sin(a) * 1.9), rgb(230, 30, 60))
	end
	ball(m, 0.9, CFrame.new(0, 4, 0), rgb(255, 60, 90))
end

function builders.Cactus(m)
	local green = rgb(60, 175, 80)
	block(m, Vector3.new(1.8, 7, 1.8), CFrame.new(0, 3.5, 0), green)
	for _, side in { -1, 1 } do
		block(m, Vector3.new(1.6, 1.2, 1.2), CFrame.new(side * 1.5, 3 + (side + 1) * 0.6, 0), green)
		block(m, Vector3.new(1.2, 2.6, 1.2), CFrame.new(side * 2, 4.4 + (side + 1) * 0.6, 0), green)
	end
	ball(m, 1.1, CFrame.new(0, 7.3, 0), rgb(255, 110, 170))
	-- A sandy pot.
	block(m, Vector3.new(3.4, 1, 3.4), CFrame.new(0, 0.5, 0), rgb(220, 120, 70))
end

function builders.AppleTree(m)
	local top = brickTree(m, 10, 6, { rgb(60, 170, 70), rgb(75, 185, 75), rgb(90, 200, 85) })
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		ball(m, 0.8, CFrame.new(math.cos(a) * 2.6, 6 + (k % 3) * 0.9, math.sin(a) * 2.6), rgb(230, 40, 40))
	end
	ball(m, 0.7, CFrame.new(0, top + 0.3, 0), rgb(230, 40, 40))
end

function builders.Pumpkin(m)
	local orange = rgb(255, 140, 30)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		ball(
			m,
			Vector3.new(2.6, 3.6, 2.6),
			CFrame.new(math.cos(a) * 1.4, 1.8, math.sin(a) * 1.4),
			orange:Lerp(rgb(230, 100, 20), (k % 2) * 0.4)
		)
	end
	ball(m, Vector3.new(3.6, 3.8, 3.6), CFrame.new(0, 1.9, 0), orange)
	post(m, 1.2, 0.6, CFrame.new(0, 3.6, 0), rgb(90, 140, 50))
	leaves(m, CFrame.new(0, 0.4, 2.4), 2)
end

function builders.Blossom(m)
	local pinks = { rgb(255, 160, 200), rgb(255, 185, 215), rgb(255, 210, 230) }
	local top = brickTree(m, 10, 6.5, pinks, rgb(100, 60, 50))
	for k = 0, 9 do
		local a = k * 2.3
		ball(m, 0.5, CFrame.new(math.cos(a) * 3, 3 + (k % 4) * 1.3, math.sin(a) * 3), rgb(255, 230, 240))
	end
	ball(m, 0.8, CFrame.new(0, top + 0.3, 0), rgb(255, 120, 180))
end

function builders.CrystalFlower(m)
	post(m, 4.6, 0.4, CFrame.new(0, 0, 0), rgb(90, 200, 190))
	leaves(m, CFrame.new(0, 1.6, 0), 1.2)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		block(
			m,
			Vector3.new(0.7, 2.6, 0.7),
			CFrame.new(0, 5.2, 0)
				* CFrame.Angles(math.rad(35) * math.cos(a), 0, math.rad(35) * math.sin(a))
				* CFrame.new(0, 1, 0),
			if k % 2 == 0 then rgb(130, 240, 255) else rgb(200, 140, 255),
			M.Neon
		)
	end
	ball(m, 1, CFrame.new(0, 5.2, 0), rgb(255, 255, 255), M.Neon)
end

function builders.GlowShroom(m)
	post(m, 3.6, 1.4, CFrame.new(0, 0, 0), rgb(245, 235, 215))
	ball(m, Vector3.new(5.6, 2.8, 5.6), CFrame.new(0, 4, 0), rgb(150, 60, 220))
	for k = 0, 6 do
		local a = k / 7 * math.pi * 2
		ball(m, 0.8, CFrame.new(math.cos(a) * 1.8, 4.6 + (k % 2) * 0.3, math.sin(a) * 1.8), rgb(120, 255, 200), M.Neon)
	end
	ball(m, 0.9, CFrame.new(0, 5.4, 0), rgb(120, 255, 200), M.Neon)
	-- Two little ones.
	for _, x in { -2.3, 2.2 } do
		post(m, 1.2, 0.5, CFrame.new(x, 0, -1.4), rgb(245, 235, 215))
		ball(m, Vector3.new(1.6, 0.9, 1.6), CFrame.new(x, 1.4, -1.4), rgb(150, 60, 220))
	end
end

function builders.MoneyTree(m)
	local greens = { rgb(70, 180, 80), rgb(90, 200, 90), rgb(110, 215, 100) }
	brickTree(m, 11, 6.5, greens)
	-- Bills and gold coins growing on it.
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		block(
			m,
			Vector3.new(1.2, 0.6, 0.1),
			CFrame.new(math.cos(a) * 3.1, 6 + (k % 3) * 1.1, math.sin(a) * 3.1) * CFrame.Angles(0, -a, math.rad(15)),
			rgb(120, 220, 110)
		)
	end
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.3
		local coin = Bricks.rod(
			m,
			0.2,
			0.9,
			CFrame.new(math.cos(a) * 2.4, 8.5 + (k % 2), math.sin(a) * 2.4) * CFrame.Angles(0, -a, 0),
			rgb(255, 205, 60),
			M.Foil
		)
		coin.Name = "Coin"
	end
	-- A pile of gold at the bottom.
	for k = 0, 3 do
		Bricks.rod(
			m,
			0.25,
			1.1,
			CFrame.new(-1.6 + k * 0.4, 0.15 + k * 0.25, -2) * CFrame.Angles(0, 0, math.pi / 2),
			rgb(255, 205, 60),
			M.Foil
		)
	end
end

function builders.RainbowTree(m)
	block(m, Vector3.new(1.4, 5, 1.4), CFrame.new(0, 2.5, 0), rgb(255, 255, 255))
	local y = 4.4
	for i, color in Bricks.RAINBOW do
		local w = 7.2 - i * 0.9
		block(
			m,
			Vector3.new(w, 1.1, w),
			CFrame.new(0, y + 0.55, 0) * CFrame.Angles(0, math.rad(i * 15), 0),
			color,
			if i % 2 == 0 then M.Neon else nil
		)
		y += 1.1
	end
	ball(m, 1.2, CFrame.new(0, y + 0.5, 0), rgb(255, 255, 220), M.Neon)
end

function PlantModel.build(itemId: string): Model
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

return PlantModel
