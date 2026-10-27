-- The scenery of each zone: its ground, the cliffs along its sides, the entrance arch with
-- its name and speed requirement, a path to the pile, and themed props (junk piles, pine
-- trees, cacti, lollipops, lava pools, crystals...).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local ZoneLayout = require(ReplicatedStorage.Shared.ZoneLayout)

local ZoneDecor = {}

local M = Enum.Material
local OUTLINE = Color3.fromRGB(20, 22, 48)

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

local function ball(parent, size: Vector3 | number, cframe: CFrame, color: Color3, material: Enum.Material?)
	local vector = if typeof(size) == "number" then Vector3.one * size else size
	local p = block(parent, vector, cframe, color, material)
	if vector.X == vector.Y and vector.Y == vector.Z then
		p.Shape = Enum.PartType.Ball
	else
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	return p
end

local function post(parent, height: number, diameter: number, cframe: CFrame, color: Color3, material: Enum.Material?)
	local p = block(
		parent,
		Vector3.new(height, diameter, diameter),
		cframe * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.pi / 2),
		color,
		material
	)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function cone(parent, height: number, diameter: number, cframe: CFrame, color: Color3, material, steps: number?)
	local n = steps or 5
	for i = 0, n - 1 do
		post(
			parent,
			height / n + 0.02,
			diameter * (1 - i / n),
			cframe * CFrame.new(0, i * height / n, 0),
			color,
			material
		)
	end
end

local RAINBOW =
	{ rgb(255, 70, 90), rgb(255, 150, 40), rgb(255, 225, 50), rgb(80, 220, 100), rgb(60, 170, 255), rgb(150, 90, 255) }

--------------------------------------------------------------------------------
-- Props, one set per zone. Each takes (parent, ground CFrame, rng, size).
--------------------------------------------------------------------------------

local props = {}

props[1] = function(parent, cf, rng, s) -- Junkyard: tyre stacks, crates, an old car, barrels
	local kind = rng:NextInteger(1, 4)
	if kind == 1 then
		for i = 0, rng:NextInteger(2, 4) do
			local tyre = block(
				parent,
				Vector3.new(1.2 * s, 3 * s, 3 * s),
				cf * CFrame.new(0, (0.6 + i * 1.15) * s, 0) * CFrame.Angles(0, rng:NextNumber() * 3, math.pi / 2),
				rgb(40, 40, 45)
			)
			tyre.Shape = Enum.PartType.Cylinder
		end
	elseif kind == 2 then
		for i = 0, 2 do
			block(
				parent,
				Vector3.one * 3 * s,
				cf * CFrame.new((i - 1) * 3.2 * s, 1.5 * s, 0) * CFrame.Angles(0, rng:NextNumber() * 0.4, 0),
				rgb(180, 130, 80),
				M.WoodPlanks,
				true
			)
		end
		block(
			parent,
			Vector3.one * 3 * s,
			cf * CFrame.new(0, 4.5 * s, 0) * CFrame.Angles(0, 0.3, 0),
			rgb(160, 115, 70),
			M.WoodPlanks,
			true
		)
	elseif kind == 3 then
		local color = ({ rgb(90, 160, 200), rgb(200, 90, 80), rgb(220, 190, 80) })[rng:NextInteger(1, 3)]
		block(
			parent,
			Vector3.new(9 * s, 2.4 * s, 4.4 * s),
			cf * CFrame.new(0, 1.8 * s, 0) * CFrame.Angles(0, 0, math.rad(4)),
			color,
			M.CorrodedMetal,
			true
		)
		block(
			parent,
			Vector3.new(5 * s, 2 * s, 4 * s),
			cf * CFrame.new(-0.5 * s, 3.8 * s, 0) * CFrame.Angles(0, 0, math.rad(4)),
			color,
			M.CorrodedMetal,
			true
		)
		block(
			parent,
			Vector3.new(0.2, 1.4 * s, 3.6 * s),
			cf * CFrame.new(2.1 * s, 3.8 * s, 0),
			rgb(160, 200, 220),
			M.Glass
		)
		for _, x in { -3, 3 } do
			for _, z in { -2.3, 2.3 } do
				local wheel = block(
					parent,
					Vector3.new(0.8 * s, 2 * s, 2 * s),
					cf * CFrame.new(x * s, 0.9 * s, z * s) * CFrame.Angles(0, math.pi / 2, math.pi / 2),
					rgb(35, 35, 40)
				)
				wheel.Shape = Enum.PartType.Cylinder
			end
		end
	else
		for i = 0, 2 do
			post(
				parent,
				3.2 * s,
				2.2 * s,
				cf * CFrame.new((i - 1) * 2.4 * s, 0, (i % 2) * s),
				({ rgb(60, 130, 170), rgb(200, 80, 60), rgb(80, 150, 90) })[i + 1],
				M.CorrodedMetal
			)
		end
	end
end

props[2] = function(parent, cf, rng, s) -- Pine Woods: pines, logs, mushrooms
	local kind = rng:NextInteger(1, 5)
	if kind <= 3 then
		local h = (9 + rng:NextNumber() * 6) * s
		post(parent, h * 0.25, 1.4 * s, cf, rgb(110, 70, 40), M.Wood)
		cone(
			parent,
			h,
			h * 0.55,
			cf * CFrame.new(0, h * 0.2, 0),
			rgb(45, 125, 65):Lerp(rgb(30, 95, 55), rng:NextNumber()),
			nil,
			5
		)
	elseif kind == 4 then
		local log = block(
			parent,
			Vector3.new(8 * s, 2 * s, 2 * s),
			cf * CFrame.new(0, 1 * s, 0) * CFrame.Angles(0, rng:NextNumber() * 3, 0),
			rgb(130, 85, 45),
			M.Wood,
			true
		)
		log.Shape = Enum.PartType.Cylinder
	else
		for i = 0, 2 do
			local spot = cf * CFrame.new((i - 1) * 2 * s, 0, (i % 2) * 1.5 * s)
			post(parent, (1 + i * 0.4) * s, 0.6 * s, spot, rgb(250, 240, 220))
			ball(
				parent,
				Vector3.new(2 * s, 1.1 * s, 2 * s),
				spot * CFrame.new(0, (1 + i * 0.4) * s, 0),
				rgb(225, 50, 50)
			)
		end
	end
end

props[3] = function(parent, cf, rng, s) -- Rocky Quarry: boulders and a minecart
	if rng:NextNumber() < 0.75 then
		for i = 0, rng:NextInteger(1, 3) do
			local size = (2.5 + rng:NextNumber() * 3) * s
			ball(
				parent,
				Vector3.new(size * 1.3, size, size),
				cf * CFrame.new(i * 2.5 * s, size * 0.35, (i % 2) * 2 * s),
				rgb(150, 145, 140):Lerp(rgb(110, 105, 100), rng:NextNumber()),
				M.Slate
			)
		end
	else
		block(parent, Vector3.new(4 * s, 2.4 * s, 3 * s), cf * CFrame.new(0, 2 * s, 0), rgb(110, 90, 70), M.Metal, true)
		ball(
			parent,
			Vector3.new(3.4 * s, 1.4 * s, 2.6 * s),
			cf * CFrame.new(0, 3.3 * s, 0),
			rgb(160, 150, 140),
			M.Slate
		)
		for _, x in { -1.4, 1.4 } do
			local wheel = block(
				parent,
				Vector3.new(3.4 * s, 1.2 * s, 1.2 * s),
				cf * CFrame.new(x * s, 0.6 * s, 0),
				rgb(50, 50, 55),
				M.Metal
			)
			wheel.Shape = Enum.PartType.Cylinder
			wheel.CFrame = cf * CFrame.new(x * s, 0.6 * s, 0) * CFrame.Angles(0, math.pi / 2, 0)
		end
	end
end

props[4] = function(parent, cf, rng, s) -- Sunny Desert: cacti, palms, a small pyramid
	local kind = rng:NextInteger(1, 4)
	local green = rgb(70, 170, 80)
	if kind <= 2 then
		local h = (5 + rng:NextNumber() * 4) * s
		post(parent, h, 1.6 * s, cf, green)
		ball(parent, 1.6 * s, cf * CFrame.new(0, h, 0), green)
		for _, side in { -1, 1 } do
			local arm = cf * CFrame.new(side * 1.3 * s, h * (0.35 + rng:NextNumber() * 0.2), 0)
			block(parent, Vector3.new(1.3 * s, 1 * s, 1 * s), arm, green)
			post(parent, 2 * s, 1 * s, arm * CFrame.new(side * 0.5 * s, 0, 0), green)
		end
		ball(parent, 0.8 * s, cf * CFrame.new(0, h + 0.7 * s, 0), rgb(255, 110, 160))
	elseif kind == 3 then
		local h = 10 * s
		for i = 0, 5 do
			local p = block(
				parent,
				Vector3.new(1.3 * s, h / 6 + 0.1, 1.3 * s),
				cf * CFrame.new(i * 0.25 * s, (i + 0.5) * h / 6, 0) * CFrame.Angles(0, 0, math.rad(-4)),
				rgb(160, 115, 70),
				M.Wood
			)
			p.Shape = Enum.PartType.Block
		end
		for k = 0, 5 do
			local a = math.rad(k * 60)
			local leaf = cf * CFrame.new(1.5 * s, h, 0) * CFrame.Angles(0, a, math.rad(-25)) * CFrame.new(2.2 * s, 0, 0)
			ball(parent, Vector3.new(5 * s, 0.5 * s, 1.6 * s), leaf, rgb(80, 180, 80))
		end
	else
		for i = 0, 3 do
			local w = (8 - i * 2) * s
			block(
				parent,
				Vector3.new(w, 2 * s, w),
				cf * CFrame.new(0, (i + 0.5) * 2 * s, 0),
				rgb(235, 200, 130),
				M.Sandstone,
				true
			)
		end
	end
end

props[5] = function(parent, cf, rng, s) -- Frosty Peaks: snowy pines, snowmen, ice spikes
	local kind = rng:NextInteger(1, 4)
	if kind <= 2 then
		local h = (9 + rng:NextNumber() * 5) * s
		post(parent, h * 0.2, 1.3 * s, cf, rgb(100, 70, 50), M.Wood)
		cone(parent, h, h * 0.5, cf * CFrame.new(0, h * 0.15, 0), rgb(50, 120, 90), nil, 4)
		cone(parent, h * 0.6, h * 0.3, cf * CFrame.new(0, h * 0.62, 0), rgb(250, 252, 255), M.Snow, 3)
	elseif kind == 3 then
		ball(parent, 3.4 * s, cf * CFrame.new(0, 1.6 * s, 0), rgb(255, 255, 255), M.Snow)
		ball(parent, 2.5 * s, cf * CFrame.new(0, 4 * s, 0), rgb(255, 255, 255), M.Snow)
		ball(parent, 1.8 * s, cf * CFrame.new(0, 5.8 * s, 0), rgb(255, 255, 255), M.Snow)
		block(parent, Vector3.new(0.3 * s, 0.3 * s, 1 * s), cf * CFrame.new(0, 5.8 * s, -1.2 * s), rgb(255, 140, 40))
		post(parent, 1 * s, 1.5 * s, cf * CFrame.new(0, 6.5 * s, 0), rgb(40, 40, 50))
	else
		for i = 0, 3 do
			local h = (4 + rng:NextNumber() * 4) * s
			block(
				parent,
				Vector3.new(1.4 * s, h, 1.4 * s),
				cf
					* CFrame.new((i - 1.5) * 1.6 * s, h * 0.45, (i % 2) * s)
					* CFrame.Angles(0, math.rad(45), math.rad((i - 1.5) * 12)),
				rgb(140, 220, 255),
				M.Ice
			)
		end
	end
end

props[6] = function(parent, cf, rng, s) -- Candy Land: lollipops, gumdrops, candy canes, cupcakes
	local kind = rng:NextInteger(1, 4)
	if kind == 1 then
		local h = (6 + rng:NextNumber() * 4) * s
		post(parent, h, 0.6 * s, cf, rgb(255, 255, 255))
		local pop = block(
			parent,
			Vector3.new(0.8 * s, 5 * s, 5 * s),
			cf * CFrame.new(0, h + 2 * s, 0) * CFrame.Angles(0, rng:NextNumber() * 3, 0),
			RAINBOW[rng:NextInteger(1, 6)]
		)
		pop.Shape = Enum.PartType.Cylinder
		pop.CFrame = cf * CFrame.new(0, h + 2 * s, 0) * CFrame.Angles(0, rng:NextNumber() * 3, 0)
	elseif kind == 2 then
		for i = 0, 2 do
			ball(
				parent,
				Vector3.new(3 * s, 2.6 * s, 3 * s),
				cf * CFrame.new((i - 1) * 3 * s, 1 * s, (i % 2) * 2 * s),
				RAINBOW[rng:NextInteger(1, 6)],
				M.Glass
			)
		end
	elseif kind == 3 then
		local h = 8 * s
		post(parent, h, 1 * s, cf, rgb(255, 255, 255))
		for i = 0, 4 do
			post(parent, h * 0.08, 1.05 * s, cf * CFrame.new(0, h * (0.1 + i * 0.2), 0), rgb(230, 40, 60))
		end
		block(parent, Vector3.new(2.6 * s, 1 * s, 1 * s), cf * CFrame.new(1 * s, h, 0), rgb(230, 40, 60))
	else
		post(parent, 2.4 * s, 4 * s, cf, rgb(255, 210, 120))
		ball(parent, Vector3.new(4.4 * s, 3 * s, 4.4 * s), cf * CFrame.new(0, 2.8 * s, 0), rgb(255, 170, 210))
		ball(parent, 1 * s, cf * CFrame.new(0, 4.4 * s, 0), rgb(230, 30, 50))
	end
end

props[7] = function(parent, cf, rng, s) -- Lava Volcano: lava pools and glowing rocks
	if rng:NextNumber() < 0.5 then
		local size = (5 + rng:NextNumber() * 5) * s
		local pool = block(
			parent,
			Vector3.new(0.3, size, size * 1.3),
			cf * CFrame.new(0, 0.12, 0) * CFrame.Angles(0, 0, math.pi / 2),
			rgb(255, 110, 20),
			M.Neon
		)
		pool.Shape = Enum.PartType.Cylinder
		local rim = block(
			parent,
			Vector3.new(0.25, size + 1.4, size * 1.3 + 1.4),
			cf * CFrame.new(0, 0.08, 0) * CFrame.Angles(0, 0, math.pi / 2),
			rgb(40, 30, 35),
			M.Basalt
		)
		rim.Shape = Enum.PartType.Cylinder
	else
		for i = 0, 2 do
			local size = (2.5 + rng:NextNumber() * 2.5) * s
			ball(
				parent,
				Vector3.new(size * 1.2, size, size),
				cf * CFrame.new(i * 2.4 * s, size * 0.35, (i % 2) * 2 * s),
				rgb(50, 38, 45),
				M.Basalt
			)
			ball(
				parent,
				size * 0.35,
				cf * CFrame.new(i * 2.4 * s, size * 0.7, (i % 2) * 2 * s - size * 0.4),
				rgb(255, 100, 20),
				M.Neon
			)
		end
	end
end

props[8] = function(parent, cf, rng, s) -- Royal Kingdom: topiaries, statues, banners
	local kind = rng:NextInteger(1, 3)
	if kind == 1 then
		block(parent, Vector3.new(3 * s, 1.6 * s, 3 * s), cf * CFrame.new(0, 0.8 * s, 0), rgb(240, 235, 225), M.Marble)
		post(parent, 1.8 * s, 0.6 * s, cf * CFrame.new(0, 1.6 * s, 0), rgb(120, 80, 50))
		ball(parent, 3.2 * s, cf * CFrame.new(0, 4.6 * s, 0), rgb(60, 160, 70))
		ball(parent, 2.2 * s, cf * CFrame.new(0, 6.8 * s, 0), rgb(60, 160, 70))
	elseif kind == 2 then
		block(
			parent,
			Vector3.new(3.4 * s, 2 * s, 3.4 * s),
			cf * CFrame.new(0, 1 * s, 0),
			rgb(240, 235, 225),
			M.Marble,
			true
		)
		post(parent, 4 * s, 1.6 * s, cf * CFrame.new(0, 2 * s, 0), rgb(255, 200, 60), M.Foil)
		ball(parent, 2 * s, cf * CFrame.new(0, 7 * s, 0), rgb(255, 200, 60), M.Foil)
	else
		post(parent, 10 * s, 0.4 * s, cf, rgb(255, 200, 60), M.Foil)
		block(parent, Vector3.new(0.2, 4 * s, 2.6 * s), cf * CFrame.new(0, 7.5 * s, 1.3 * s), rgb(220, 40, 60))
		block(
			parent,
			Vector3.new(0.22, 1 * s, 2.6 * s),
			cf * CFrame.new(0, 8.6 * s, 1.3 * s),
			rgb(255, 200, 60),
			M.Foil
		)
	end
end

props[9] = function(parent, cf, rng, s) -- Crystal Caves: crystal clusters
	local colors = { rgb(160, 110, 255), rgb(110, 240, 255), rgb(255, 120, 230) }
	local color = colors[rng:NextInteger(1, 3)]
	for i = 0, rng:NextInteger(3, 5) do
		local h = (3 + rng:NextNumber() * 7) * s
		local tilt = (rng:NextNumber() - 0.5) * 50
		local spot = cf
			* CFrame.new((rng:NextNumber() - 0.5) * 4 * s, 0, (rng:NextNumber() - 0.5) * 4 * s)
			* CFrame.Angles(math.rad(tilt * 0.6), rng:NextNumber() * 3, math.rad(tilt))
		block(
			parent,
			Vector3.new(1.2 * s, h, 1.2 * s),
			spot * CFrame.new(0, h / 2, 0),
			color,
			if i % 2 == 0 then M.Neon else M.Glass
		)
	end
end

props[10] = function(parent, cf, rng, s) -- Sky Islands: cloud puffs, golden pillars, rainbows
	local kind = rng:NextInteger(1, 3)
	if kind == 1 then
		for i = 0, 3 do
			ball(
				parent,
				(3 + rng:NextNumber() * 3) * s,
				cf * CFrame.new((i - 1.5) * 2.6 * s, (1 + rng:NextNumber()) * s, rng:NextNumber() * 2 * s),
				rgb(255, 255, 255)
			)
		end
	elseif kind == 2 then
		post(parent, 12 * s, 2 * s, cf, rgb(250, 248, 240), M.Marble)
		post(parent, 0.6 * s, 2.8 * s, cf * CFrame.new(0, 12 * s, 0), rgb(255, 210, 80), M.Foil)
		post(parent, 0.6 * s, 2.8 * s, cf, rgb(255, 210, 80), M.Foil)
	else
		for i, color in RAINBOW do
			local r = (9 - i * 0.8) * s
			for k = 0, 10 do
				local a = math.rad(k * 18)
				ball(parent, 1.2 * s, cf * CFrame.new(math.cos(a) * r, math.sin(a) * r, 0), color, M.Neon)
			end
		end
	end
end

props[11] = function(parent, cf, rng, s) -- Backyard Garden: hedges, flower patches, watering cans
	local kind = rng:NextInteger(1, 4)
	if kind <= 2 then
		local length = rng:NextInteger(2, 4) * 3 * s
		block(
			parent,
			Vector3.new(length, 3 * s, 2.4 * s),
			cf * CFrame.new(0, 1.5 * s, 0),
			rgb(50, 150, 60),
			M.Grass,
			true
		)
		for i = 0, math.floor(length / (2 * s)) do
			ball(
				parent,
				0.7 * s,
				cf * CFrame.new(-length / 2 + i * 2 * s + s, 3.1 * s, -1.2 * s),
				RAINBOW[rng:NextInteger(1, 6)]
			)
		end
	elseif kind == 3 then
		for i = 0, 5 do
			local spot = cf * CFrame.new((i % 3 - 1) * 1.6 * s, 0, (i // 3 - 0.5) * 1.6 * s)
			post(parent, 1.6 * s, 0.25 * s, spot, rgb(70, 165, 70))
			ball(parent, 0.9 * s, spot * CFrame.new(0, 1.8 * s, 0), RAINBOW[rng:NextInteger(1, 6)])
		end
	else
		block(parent, Vector3.new(2.2 * s, 2 * s, 1.6 * s), cf * CFrame.new(0, 1 * s, 0), rgb(80, 160, 230))
		block(
			parent,
			Vector3.new(0.4 * s, 0.4 * s, 2.4 * s),
			cf * CFrame.new(0, 1.6 * s, -1.6 * s) * CFrame.Angles(math.rad(-30), 0, 0),
			rgb(80, 160, 230)
		)
		block(parent, Vector3.new(0.4 * s, 1.4 * s, 0.4 * s), cf * CFrame.new(0, 2.6 * s, 0.4 * s), rgb(60, 130, 200))
	end
end

props[12] = function(parent, cf, rng, s) -- Toy Town: giant toy bricks, beach balls, rubber ducks
	local kind = rng:NextInteger(1, 4)
	if kind <= 2 then
		for i = 0, rng:NextInteger(1, 3) do
			local size = Vector3.new(rng:NextInteger(2, 4) * 2, 2.4, 4) * s
			block(
				parent,
				size,
				cf * CFrame.new((i % 2) * 2 * s, (i + 0.5) * 2.4 * s, 0) * CFrame.Angles(0, i * 0.5, 0),
				RAINBOW[rng:NextInteger(1, 6)],
				nil,
				true
			)
		end
	elseif kind == 3 then
		local r = (2 + rng:NextNumber() * 1.5) * s
		for i, color in { rgb(255, 70, 90), rgb(255, 255, 255), rgb(60, 140, 255), rgb(255, 220, 60) } do
			ball(
				parent,
				Vector3.new(r * 2, r * 2, r * (0.5 + i * 0.12)),
				cf * CFrame.new(0, r, 0) * CFrame.Angles(0, i * math.pi / 4, 0),
				color
			)
		end
	else
		ball(parent, Vector3.new(4 * s, 3 * s, 5 * s), cf * CFrame.new(0, 1.5 * s, 0), rgb(255, 220, 40))
		ball(parent, 2.6 * s, cf * CFrame.new(0, 3.6 * s, -1.6 * s), rgb(255, 220, 40))
		block(parent, Vector3.new(1.2 * s, 0.5 * s, 1.2 * s), cf * CFrame.new(0, 3.5 * s, -3 * s), rgb(255, 140, 30))
	end
end

-- Which look (theme and props, below) each zone uses, in zone order.
local LOOK = { 11, 1, 2, 12, 4, 6, 5, 8, 9, 10 }

-- Ground, cliffs and colours for each zone.
local THEMES = {
	{ -- Junkyard
		ground = rgb(214, 170, 112),
		groundMat = M.Ground,
		wall = rgb(190, 110, 60),
		trim = rgb(120, 200, 80),
		cliff = rgb(150, 120, 90),
		cliffMat = M.Slate,
		path = rgb(150, 115, 80),
		accent = rgb(255, 160, 50),
	},
	{ -- Pine Woods
		ground = rgb(64, 196, 70),
		groundMat = M.Grass,
		wall = rgb(40, 120, 70),
		trim = rgb(110, 225, 90),
		cliff = rgb(90, 120, 90),
		cliffMat = M.Rock,
		path = rgb(160, 115, 70),
		accent = rgb(120, 220, 90),
	},
	{ -- Rocky Quarry
		ground = rgb(170, 175, 185),
		groundMat = M.Slate,
		wall = rgb(95, 110, 150),
		trim = rgb(80, 190, 90),
		cliff = rgb(140, 140, 150),
		cliffMat = M.Rock,
		path = rgb(200, 190, 170),
		accent = rgb(160, 175, 230),
	},
	{ -- Sunny Desert
		ground = rgb(245, 205, 115),
		groundMat = M.Sand,
		wall = rgb(230, 140, 60),
		trim = rgb(255, 225, 140),
		cliff = rgb(220, 170, 100),
		cliffMat = M.Sandstone,
		path = rgb(225, 180, 110),
		accent = rgb(60, 210, 220),
	},
	{ -- Frosty Peaks
		ground = rgb(225, 240, 255),
		groundMat = M.Snow,
		wall = rgb(90, 160, 240),
		trim = rgb(250, 252, 255),
		cliff = rgb(190, 220, 245),
		cliffMat = M.Ice,
		path = rgb(190, 220, 245),
		accent = rgb(110, 210, 255),
	},
	{ -- Candy Land
		ground = rgb(255, 185, 220),
		groundMat = M.SmoothPlastic,
		wall = rgb(255, 100, 170),
		trim = rgb(255, 255, 255),
		cliff = rgb(255, 140, 195),
		cliffMat = M.SmoothPlastic,
		path = rgb(255, 255, 255),
		accent = rgb(255, 80, 150),
	},
	{ -- Lava Volcano
		ground = rgb(80, 60, 75),
		groundMat = M.Basalt,
		wall = rgb(50, 35, 50),
		trim = rgb(255, 110, 30),
		cliff = rgb(45, 35, 42),
		cliffMat = M.Basalt,
		path = rgb(110, 80, 80),
		accent = rgb(255, 110, 30),
	},
	{ -- Royal Kingdom
		ground = rgb(80, 200, 90),
		groundMat = M.Grass,
		wall = rgb(235, 230, 220),
		trim = rgb(255, 200, 60),
		cliff = rgb(225, 220, 210),
		cliffMat = M.Marble,
		path = rgb(220, 40, 60),
		accent = rgb(255, 200, 60),
	},
	{ -- Crystal Caves
		ground = rgb(85, 60, 130),
		groundMat = M.Slate,
		wall = rgb(110, 70, 210),
		trim = rgb(130, 240, 255),
		cliff = rgb(85, 62, 125),
		cliffMat = M.Rock,
		path = rgb(130, 95, 190),
		accent = rgb(140, 240, 255),
	},
	{ -- Sky Islands
		ground = rgb(245, 250, 255),
		groundMat = M.SmoothPlastic,
		wall = rgb(130, 190, 255),
		trim = rgb(255, 215, 90),
		cliff = rgb(235, 242, 255),
		cliffMat = M.SmoothPlastic,
		path = rgb(255, 225, 120),
		accent = rgb(255, 210, 80),
	},
	{ -- Backyard Garden
		ground = rgb(90, 210, 90),
		groundMat = M.Grass,
		wall = rgb(250, 245, 235),
		trim = rgb(255, 120, 160),
		cliff = rgb(230, 225, 215),
		cliffMat = M.WoodPlanks,
		path = rgb(200, 160, 110),
		accent = rgb(255, 120, 170),
	},
	{ -- Toy Town
		ground = rgb(120, 200, 255),
		groundMat = M.SmoothPlastic,
		wall = rgb(255, 210, 50),
		trim = rgb(255, 80, 90),
		cliff = rgb(255, 200, 60),
		cliffMat = M.SmoothPlastic,
		path = rgb(255, 255, 255),
		accent = rgb(255, 90, 90),
	},
}

-- The theme for zone `index`.
function ZoneDecor.theme(index: number)
	return THEMES[LOOK[index]]
end

-- The arch over a zone's entrance: its name and the Speed you need.
local function buildArch(parent, index: number, theme)
	local zone = Items.ZONES[index]
	local east = ZoneLayout.edges(index)
	local width = 26
	local height = 18
	for _, side in { -1, 1 } do
		local spot = CFrame.new(east, 0, side * (width / 2 + 2))
		block(
			parent,
			Vector3.new(4, height, 4),
			spot * CFrame.new(0, height / 2, 0),
			theme.cliff:Lerp(rgb(255, 255, 255), 0.15),
			theme.cliffMat,
			true
		)
		block(parent, Vector3.new(5, 1.2, 5), spot * CFrame.new(0, height + 0.6, 0), theme.accent)
		ball(parent, 2.6, spot * CFrame.new(0, height + 2.4, 0), theme.accent, M.Neon)
	end
	local beam =
		block(parent, Vector3.new(3, 6, width + 8), CFrame.new(east, height - 1, 0), rgb(255, 250, 235), nil, true)
	block(parent, Vector3.new(2.6, 6.8, width + 8.8), CFrame.new(east + 0.3, height - 1, 0), OUTLINE)
	-- Text on the town side of the beam (facing +X, toward players arriving).
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Right
	gui.CanvasSize = Vector2.new(700, 160)
	gui.LightInfluence = 0
	gui.Parent = beam
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(1, 0.58)
	name.TextScaled = true
	name.Font = Enum.Font.LuckiestGuy
	name.Text = string.upper(zone.name)
	name.TextColor3 = theme.accent
	name.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE
	stroke.Thickness = 5
	stroke.Parent = name
	local speed = name:Clone()
	speed.Position = UDim2.fromScale(0, 0.58)
	speed.Size = UDim2.fromScale(1, 0.42)
	local kind = Items.KINDS[zone.kind]
	speed.Text = (if zone.speed > 0 then "⚡ " .. ZoneDecor.formatSpeed(zone.speed) else "⚡ ANY")
		.. "  ·  "
		.. kind.icon
		.. " "
		.. string.upper(kind.egg)
		.. " EGGS"
	speed.TextColor3 = rgb(255, 225, 80)
	speed.Parent = gui
end

function ZoneDecor.formatSpeed(n: number): string
	if n >= 1e6 then
		return (string.format("%.1f", n / 1e6):gsub("%.0$", "")) .. "M"
	elseif n >= 1e3 then
		return (string.format("%.1f", n / 1e3):gsub("%.0$", "")) .. "K"
	end
	return tostring(math.floor(n))
end

function ZoneDecor.build(parent: Instance, index: number)
	local theme = ZoneDecor.theme(index)
	local east, west = ZoneLayout.edges(index)
	local length, width = ZoneLayout.LENGTH, ZoneLayout.WIDTH
	local centerX = (east + west) / 2
	local folder = Instance.new("Folder")
	folder.Name = "Zone" .. index .. "_" .. Items.ZONES[index].name
	folder.Parent = parent

	-- A checkerboard floor in two shades of the zone's colour, and the path to the pile.
	local tile = 13
	local countX, countZ = math.round(length / tile), math.round(width / tile)
	for i = 0, countX - 1 do
		for k = 0, countZ - 1 do
			local w, d = length / countX, width / countZ
			local floor = block(
				folder,
				Vector3.new(w, 2, d),
				CFrame.new(east - (i + 0.5) * w, -0.98, -width / 2 + (k + 0.5) * d),
				if (i + k) % 2 == 0 then theme.ground else theme.ground:Lerp(Color3.new(0, 0, 0), 0.12),
				theme.groundMat,
				true
			)
			floor.Name = "Tile"
		end
	end
	local path = block(
		folder,
		Vector3.new(ZoneLayout.HOME_U - 12, 0.2, 10),
		CFrame.new(east - (ZoneLayout.HOME_U - 12) / 2, 0.12, 0),
		theme.path,
		if index == 8 then M.Fabric else theme.groundMat
	)
	path.Name = "PathStone"
	-- Tall flat walls along both sides (and behind the last zone), so nobody wanders off the
	-- map, with a strip of the floor colour along the top like grass on a cliff.
	local wallHeight = 30
	for _, side in { -1, 1 } do
		local z = side * (width / 2 + 3)
		block(
			folder,
			Vector3.new(length, wallHeight, 6),
			CFrame.new(centerX, wallHeight / 2, z),
			theme.wall,
			theme.cliffMat,
			true
		)
		block(
			folder,
			Vector3.new(length, 1.6, 6.4),
			CFrame.new(centerX, wallHeight + 0.8, z),
			theme.trim,
			theme.cliffMat
		)
		-- An invisible wall on top, far up, so nobody (flung by a guardian, or jumping off
		-- something tall) can ever get over the side.
		local barrier =
			block(folder, Vector3.new(length, 200, 6), CFrame.new(centerX, wallHeight + 100, z), theme.wall, nil, true)
		barrier.Name = "ZoneBarrier"
		barrier.Transparency = 1
		barrier.CanQuery = false
		if index == 8 then
			-- Castle battlements on the walls of the Royal Kingdom.
			for i = 0, 15 do
				block(
					folder,
					Vector3.new(3, 3, 6.2),
					CFrame.new(east - (i + 0.5) * length / 16, wallHeight + 3, z),
					theme.cliff,
					theme.cliffMat
				)
			end
		end
	end
	if index == #Items.ZONES then
		block(folder, Vector3.new(6, 32, width + 12), CFrame.new(west - 3, 16, 0), theme.wall, theme.cliffMat, true)
	end
	buildArch(folder, index, theme)

	-- Themed props, kept off the path and out of the pile.
	local rng = Random.new(index * 7919)
	local placed = 0
	local tries = 0
	while placed < 22 and tries < 200 do
		tries += 1
		local u = rng:NextNumber(8, length - 6)
		local v = rng:NextNumber(-width / 2 + 7, width / 2 - 7)
		local nearPile = (Vector2.new(u, v) - Vector2.new(ZoneLayout.HOME_U, 0)).Magnitude < ZoneLayout.RING * 1.6
		if math.abs(v) > 10 and not nearPile then
			placed += 1
			local cf = CFrame.new(east - u, 0, v) * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
			props[LOOK[index]](folder, cf, rng, 0.9 + rng:NextNumber() * 0.5)
		end
	end
	return folder
end

return ZoneDecor
