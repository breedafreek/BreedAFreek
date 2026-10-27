-- Builds houses and house parts out of simple parts, in the game's chunky cartoon style.
--
-- HouseModel.house(parts) builds a whole house: parts = { [slotId] = partId } (missing slots
-- get Basic). It's built at the origin with its front facing -Z: the front wall sits on
-- z = 0 and the yard (porch, garden, mailbox, fence) is in front of it, all inside a
-- 64 x 64 plot centred on the origin. Every slot's pieces go in a Model named after the slot
-- (with a "Part" attribute), so a slot can be rebuilt on its own (HouseModel.slot).
--
-- HouseModel.item(partId) builds one part on its own at carrying size (about 5 studs), for
-- the zone piles, carrying over your head and the UI pictures.

local Lego = require(script.Parent.Lego)
local Parts = require(script.Parent.Parts)

local HouseModel = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local M = Enum.Material

-- How each style looks. Flags add each style's signature details.
local LOOKS = {
	Basic = {
		wall = rgb(238, 224, 196),
		trim = rgb(255, 255, 255),
		roof = rgb(205, 85, 70),
		door = rgb(160, 100, 60),
		glass = rgb(150, 210, 255),
		accent = rgb(90, 175, 90),
		shape = "gable",
		shutters = true,
	},
	Scrap = {
		wall = rgb(120, 160, 175),
		wallMat = M.CorrodedMetal,
		trim = rgb(120, 122, 130),
		trimMat = M.Metal,
		roof = rgb(200, 120, 70),
		roofMat = M.CorrodedMetal,
		door = rgb(195, 160, 110),
		doorMat = M.WoodPlanks,
		glass = rgb(150, 200, 180),
		accent = rgb(60, 170, 170),
		shape = "gable",
		patches = true,
	},
	Log = {
		wall = rgb(160, 100, 55),
		wallMat = M.Wood,
		trim = rgb(110, 68, 35),
		trimMat = M.Wood,
		roof = rgb(70, 125, 70),
		roofMat = M.WoodPlanks,
		door = rgb(125, 72, 40),
		doorMat = M.WoodPlanks,
		glass = rgb(255, 225, 140),
		accent = rgb(215, 60, 50),
		shape = "gable",
		logs = true,
		shutters = true,
	},
	Stone = {
		wall = rgb(165, 165, 170),
		wallMat = M.Cobblestone,
		trim = rgb(115, 115, 122),
		trimMat = M.Slate,
		roof = rgb(75, 90, 135),
		roofMat = M.Slate,
		door = rgb(120, 80, 50),
		doorMat = M.WoodPlanks,
		glass = rgb(160, 210, 255),
		accent = rgb(70, 160, 70),
		shape = "gable",
		ivy = true,
	},
	Sand = {
		wall = rgb(242, 208, 148),
		wallMat = M.Sandstone,
		trim = rgb(250, 238, 205),
		trimMat = M.Sandstone,
		roof = rgb(45, 195, 205),
		door = rgb(130, 60, 150),
		glass = rgb(110, 220, 255),
		accent = rgb(255, 200, 50),
		accentMat = M.Foil,
		shape = "dome",
		arched = true,
	},
	Ice = {
		wall = rgb(125, 205, 255),
		wallMat = M.Ice,
		trim = rgb(235, 250, 255),
		trimMat = M.Snow,
		roof = rgb(250, 252, 255),
		roofMat = M.Snow,
		door = rgb(80, 165, 230),
		glass = rgb(120, 240, 255),
		glassMat = M.Neon,
		accent = rgb(110, 225, 255),
		accentMat = M.Neon,
		shape = "gable",
		icicles = true,
	},
	Candy = {
		wall = rgb(255, 160, 205),
		trim = rgb(255, 255, 255),
		roof = rgb(120, 65, 40),
		door = rgb(110, 230, 185),
		glass = rgb(255, 240, 150),
		accent = rgb(255, 70, 110),
		shape = "gable",
		stripes = true,
		icing = true,
	},
	Lava = {
		wall = rgb(50, 38, 55),
		wallMat = M.Basalt,
		trim = rgb(255, 115, 30),
		trimMat = M.Neon,
		roof = rgb(32, 26, 38),
		roofMat = M.Basalt,
		door = rgb(90, 30, 20),
		glass = rgb(255, 150, 40),
		glassMat = M.Neon,
		accent = rgb(255, 80, 20),
		accentMat = M.Neon,
		shape = "pointy",
		cracks = true,
	},
	Royal = {
		wall = rgb(245, 240, 230),
		wallMat = M.Marble,
		trim = rgb(255, 200, 60),
		trimMat = M.Foil,
		roof = rgb(55, 85, 215),
		door = rgb(160, 30, 55),
		glass = rgb(150, 210, 255),
		accent = rgb(225, 40, 60),
		shape = "castle",
		arched = true,
	},
	Crystal = {
		wall = rgb(165, 110, 255),
		wallMat = M.Glass,
		trim = rgb(110, 240, 255),
		trimMat = M.Neon,
		roof = rgb(205, 145, 255),
		roofMat = M.Glass,
		door = rgb(90, 50, 185),
		glass = rgb(225, 195, 255),
		glassMat = M.Neon,
		accent = rgb(120, 255, 235),
		accentMat = M.Neon,
		shape = "spikes",
		arched = true,
		gems = true,
	},
	Cloud = {
		wall = rgb(250, 250, 255),
		trim = rgb(255, 215, 90),
		trimMat = M.Foil,
		roof = rgb(150, 205, 255),
		door = rgb(255, 245, 210),
		glass = rgb(200, 235, 255),
		accent = rgb(255, 255, 255),
		shape = "dome",
		arched = true,
		clouds = true,
	},
	Rainbow = {
		wall = rgb(255, 255, 255),
		trim = rgb(255, 255, 255),
		trimMat = M.Neon,
		roof = rgb(255, 90, 160),
		door = rgb(120, 90, 255),
		glass = rgb(255, 255, 200),
		glassMat = M.Neon,
		accent = rgb(255, 230, 80),
		accentMat = M.Neon,
		shape = "pointy",
		rainbow = true,
	},
}
HouseModel.LOOKS = LOOKS

local RAINBOW = {
	rgb(255, 70, 90),
	rgb(255, 150, 40),
	rgb(255, 225, 50),
	rgb(80, 220, 100),
	rgb(60, 170, 255),
	rgb(150, 90, 255),
}

-- Full-size house measurements (the item versions are smaller).
local BODY = { w = 30, d = 20, h = 13 }
local BASE = 1 -- foundation height
HouseModel.BODY = BODY

--------------------------------------------------------------------------------
-- Building blocks
--------------------------------------------------------------------------------

local function block(model: Instance, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or M.SmoothPlastic
	if p.Material == M.Glass then
		p.Transparency = 0.2
	end
	p.Parent = model
	return p
end

-- A solid block (walls and floors people bump into).
local function solid(model, size, cframe, color, material)
	local p = block(model, size, cframe, color, material)
	p.CanCollide = true
	return p
end

local function ball(model, size: Vector3 | number, cframe: CFrame, color: Color3, material: Enum.Material?)
	local vector = if typeof(size) == "number" then Vector3.one * size else size
	local p = block(model, vector, cframe, color, material)
	if vector.X == vector.Y and vector.Y == vector.Z then
		p.Shape = Enum.PartType.Ball
	else
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	return p
end

-- A cylinder standing up, its base centred on `cframe`.
local function post(model, height: number, diameter: number, cframe: CFrame, color: Color3, material)
	local p = block(
		model,
		Vector3.new(height, diameter, diameter),
		cframe * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.pi / 2),
		color,
		material
	)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- A cylinder lying along the cframe's X axis.
local function rod(model, length: number, diameter: number, cframe: CFrame, color: Color3, material)
	local p = block(model, Vector3.new(length, diameter, diameter), cframe, color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function wedge(model, size: Vector3, cframe: CFrame, color: Color3, material)
	local p = Instance.new("WedgePart")
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or M.SmoothPlastic
	if p.Material == M.Glass then
		p.Transparency = 0.2
	end
	p.Parent = model
	return p
end

-- A cone made of stacked discs (tower tops, spires).
local function cone(model, height: number, diameter: number, cframe: CFrame, color: Color3, material, steps: number?)
	local n = steps or 6
	for i = 0, n - 1 do
		local d = diameter * (1 - i / n)
		post(model, height / n + 0.02, d, cframe * CFrame.new(0, i * height / n, 0), color, material)
	end
	ball(model, diameter * 0.18, cframe * CFrame.new(0, height, 0), color, material)
end

local function puff(model, cframe: CFrame, size: number, color: Color3?)
	local white = color or rgb(255, 255, 255)
	ball(model, size, cframe, white)
	ball(model, size * 0.75, cframe * CFrame.new(size * 0.55, -size * 0.1, 0), white)
	ball(model, size * 0.7, cframe * CFrame.new(-size * 0.55, -size * 0.12, 0), white)
end

local function rainbowColor(i: number): Color3
	return RAINBOW[(i - 1) % #RAINBOW + 1]
end

-- A style's look, with any mutation's tint applied (Golden turns the main colours gold...).
local function lookFor(styleId: string)
	return LOOKS[styleId] or LOOKS.Basic
end

--------------------------------------------------------------------------------
-- Slot builders. Each takes (model, cf, look, size): cf is where the piece stands (its
-- ground point, facing -Z), size is how big to build it.
--------------------------------------------------------------------------------

local builders = {}

-- Walls: the house body. size = { w, d, h } (the front face is at cf's z = 0).
function builders.Walls(model, cf: CFrame, look, size)
	local w, d, h = size.w, size.d, size.h
	local base = size.base or BASE
	local trimMat = look.trimMat
	solid(
		model,
		Vector3.new(w + 1, base, d + 1),
		cf * CFrame.new(0, base / 2, d / 2),
		look.trim:Lerp(rgb(0, 0, 0), 0.25),
		trimMat
	)
	local body = solid(model, Vector3.new(w, h, d), cf * CFrame.new(0, base + h / 2, d / 2), look.wall, look.wallMat)
	body.Name = "Body"
	-- Corner posts and a band along the top.
	local t = math.max(0.8, w / 25)
	for _, x in { -w / 2, w / 2 } do
		for _, z in { 0, d } do
			block(model, Vector3.new(t, h, t), cf * CFrame.new(x, base + h / 2, z), look.trim, trimMat)
		end
	end
	block(model, Vector3.new(w + t, t * 0.8, t), cf * CFrame.new(0, base + h - t * 0.4, 0), look.trim, trimMat)
	block(model, Vector3.new(w + t, t * 0.8, t), cf * CFrame.new(0, base + h - t * 0.4, d), look.trim, trimMat)
	local front = -0.08 -- just in front of the front face

	-- LEGO bricks: seams between the courses and staggered joints, on the front and sides.
	if Lego.ENABLED and not look.logs and not look.stripes and not look.rainbow and look.wallMat ~= M.Glass then
		local seam = look.wall:Lerp(rgb(0, 0, 0), 0.22)
		local course = math.max(0.6, math.min(1.2, h / 4))
		local brick = course * 3.2
		local rows = math.floor(h / course)
		local faces = {
			{ cf * CFrame.new(0, 0, -0.03), w }, -- front
			{ cf * CFrame.new(w / 2 + 0.03, 0, d / 2) * CFrame.Angles(0, -math.pi / 2, 0), d }, -- right side
			{ cf * CFrame.new(-w / 2 - 0.03, 0, d / 2) * CFrame.Angles(0, math.pi / 2, 0), d }, -- left side
		}
		for _, face in faces do
			local faceCf, width = face[1], face[2]
			for row = 1, rows - 1 do
				block(model, Vector3.new(width, 0.1, 0.06), faceCf * CFrame.new(0, base + row * course, 0), seam).Name =
					"Seam"
			end
			for row = 0, rows - 1 do
				local shift = if row % 2 == 0 then 0 else brick / 2
				local x = -width / 2 + shift + brick
				while x < width / 2 - 0.2 do
					block(
						model,
						Vector3.new(0.1, course, 0.06),
						faceCf * CFrame.new(x, base + (row + 0.5) * course, 0),
						seam
					).Name =
						"Seam"
					x += brick
				end
			end
		end
	end

	if look.logs then
		-- Logs stacked up the front with their round ends poking out at the corners.
		local rows = math.floor(h / (t * 1.2))
		for i = 0, rows - 1 do
			local y = base + (i + 0.5) * h / rows
			rod(
				model,
				w + t * 1.6,
				h / rows * 0.95,
				cf * CFrame.new(0, y, front),
				look.wall:Lerp(rgb(80, 45, 20), (i % 2) * 0.2),
				M.Wood
			)
		end
	end
	if look.stripes or look.rainbow then
		-- Candy stripes (or rainbow bands) up the walls.
		local count = math.max(3, math.floor(w / 3))
		for i = 1, count - 1, 2 do
			local x = -w / 2 + i * w / count
			local color = if look.rainbow then rainbowColor(i) else look.trim
			block(
				model,
				Vector3.new(w / count, h - t, 0.2),
				cf * CFrame.new(x, base + h / 2 - t * 0.4, front),
				color,
				if look.rainbow then M.Neon else nil
			)
		end
	end
	if look.patches then
		-- Mismatched sheets of scrap riveted on.
		local spots =
			{ { -0.3, 0.3, rgb(120, 160, 170) }, { 0.32, 0.65, rgb(200, 150, 80) }, { 0.05, 0.75, rgb(140, 140, 150) } }
		for _, s in spots do
			block(
				model,
				Vector3.new(w * 0.22, h * 0.25, 0.2),
				cf * CFrame.new(s[1] * w, base + s[2] * h, front) * CFrame.Angles(0, 0, math.rad(s[1] * 20)),
				s[3],
				M.CorrodedMetal
			)
		end
	end
	if look.ivy then
		for i = 0, 5 do
			ball(
				model,
				Vector3.new(w * 0.09, h * 0.12, 0.4),
				cf * CFrame.new(-w / 2 + t + (i % 3) * w * 0.06, base + h * (0.2 + i * 0.13), front),
				look.accent:Lerp(rgb(30, 90, 30), (i % 2) * 0.3)
			)
		end
	end
	if look.cracks then
		for i, s in { { -0.35, 0.3, 25 }, { 0.3, 0.55, -30 }, { -0.1, 0.8, 70 } } do
			block(
				model,
				Vector3.new(w * 0.14, 0.25, 0.2),
				cf * CFrame.new(s[1] * w, base + s[2] * h, front) * CFrame.Angles(0, 0, math.rad(s[3] + i)),
				look.accent,
				M.Neon
			)
		end
	end
	if look.gems then
		for i, x in { -0.4, 0.4 } do
			block(
				model,
				Vector3.new(t * 1.2, t * 2.4, 0.6),
				cf * CFrame.new(x * w, base + h * 0.5, front) * CFrame.Angles(0, 0, math.rad(45 * i)),
				look.accent,
				M.Neon
			)
		end
	end
	if look.clouds then
		for _, x in { -w / 2, w / 2 } do
			puff(model, cf * CFrame.new(x, base + 0.4, -0.3), t * 2.2)
		end
	end
	if look.icicles then
		for i = 0, math.floor(w / 2.5) do
			local x = -w / 2 + i * 2.5
			wedge(
				model,
				Vector3.new(0.4, 1 + (i % 3) * 0.6, 0.5),
				cf * CFrame.new(x, base + h - t - 0.5 - (i % 3) * 0.3, front) * CFrame.Angles(math.pi, 0, 0),
				look.accent,
				M.Ice
			)
		end
	end
end

-- Roof: sits on top of walls of size { w, d } at height y. size = { w, d, y }.
function builders.Roof(model, cf: CFrame, look, size)
	local w, d, y = size.w, size.d, size.y
	local mat = look.roofMat
	local shape = look.shape
	local center = cf * CFrame.new(0, y, d / 2)
	local over = math.max(0.6, w / 20) -- overhang

	if shape == "gable" or shape == "pointy" then
		local rise = if shape == "pointy" then d * 0.85 else d * 0.42
		local half = d / 2 + over
		-- Two wedges meeting at the ridge (along X).
		for _, side in { 1, -1 } do
			local color = look.roof:Lerp(rgb(0, 0, 0), if side == 1 then 0 else 0.12)
			if look.rainbow then
				color = rainbowColor(if side == 1 then 1 else 4)
			end
			wedge(
				model,
				Vector3.new(w + over * 2, rise, half),
				center * CFrame.Angles(0, if side == 1 then 0 else math.pi, 0) * CFrame.new(0, rise / 2, -half / 2),
				color,
				mat
			)
		end
		-- Eaves trim and a ridge cap.
		rod(model, w + over * 2.4, math.max(0.6, w / 22), center * CFrame.new(0, rise, 0), look.trim, look.trimMat)
		-- Gable-end triangles in wall colour fill the space above the walls.
		if look.icing then
			-- Icing dripping down the front edge.
			for i = 0, math.floor((w + over * 2) / 1.6) do
				local x = -w / 2 - over + i * 1.6
				ball(
					model,
					Vector3.new(1.3, 0.9 + (i % 2) * 0.8, 0.8),
					center * CFrame.new(x, 0.1, -half + 0.2),
					rgb(255, 255, 255)
				)
			end
			for i = 0, 4 do
				ball(
					model,
					0.55,
					center * CFrame.new(-w * 0.35 + i * w * 0.18, rise * 0.55, -half * 0.45),
					rainbowColor(i + 1)
				)
			end
		end
		if look.icicles or shape == "gable" and look.wallMat == M.Ice then
			for i = 0, math.floor((w + over * 2) / 1.8) do
				wedge(
					model,
					Vector3.new(0.35, 0.9 + (i % 3) * 0.5, 0.45),
					center * CFrame.new(-w / 2 - over + i * 1.8, -0.5, -half) * CFrame.Angles(math.pi, 0, 0),
					look.accent,
					M.Ice
				)
			end
		end
		if shape == "pointy" then
			-- Little spires at each end of the ridge.
			for _, x in { -w / 2, w / 2 } do
				cone(
					model,
					rise * 0.5,
					math.max(1, w / 12),
					center * CFrame.new(x, rise, 0),
					look.accent,
					look.accentMat,
					5
				)
			end
		end
	elseif shape == "dome" then
		solid(
			model,
			Vector3.new(w + over * 2, math.max(0.6, w / 30), d + over * 2),
			center * CFrame.new(0, 0.3, 0),
			look.trim,
			look.trimMat
		)
		local r = math.min(w, d) * 0.8
		post(model, r * 0.25, r, center * CFrame.new(0, 0.5, 0), look.trim, look.trimMat)
		ball(model, Vector3.new(r, r * 0.95, r), center * CFrame.new(0, 0.5 + r * 0.25, 0), look.roof, look.roofMat)
		cone(model, r * 0.45, r * 0.12, center * CFrame.new(0, 0.5 + r * 0.7, 0), look.accent, look.accentMat, 4)
		-- Two small domes on the corners.
		for _, x in { -w / 2 + w * 0.1, w / 2 - w * 0.1 } do
			ball(model, w * 0.16, center * CFrame.new(x, 0.6 + w * 0.05, -d / 2 + d * 0.15), look.roof, look.roofMat)
		end
		if look.clouds then
			for _, x in { -w * 0.35, 0, w * 0.35 } do
				puff(model, center * CFrame.new(x, 0.6, -d / 2), w * 0.09)
			end
			-- A golden halo floating over the dome.
			local halo = block(
				model,
				Vector3.new(0.3, r * 0.55, r * 0.55),
				center * CFrame.new(0, 0.5 + r * 1.3, 0) * CFrame.Angles(0, 0, math.pi / 2),
				look.trim,
				M.Neon
			)
			halo.Shape = Enum.PartType.Cylinder
			block(
				model,
				Vector3.new(0.32, r * 0.4, r * 0.4),
				center * CFrame.new(0, 0.5 + r * 1.3, 0) * CFrame.Angles(0, 0, math.pi / 2),
				look.roof
			).Shape =
				Enum.PartType.Cylinder
		end
	elseif shape == "castle" then
		local slab = math.max(0.8, w / 25)
		solid(
			model,
			Vector3.new(w + over * 2, slab, d + over * 2),
			center * CFrame.new(0, slab / 2, 0),
			look.wall,
			look.wallMat
		)
		block(
			model,
			Vector3.new(w + over * 2 + 0.2, slab * 0.5, d + over * 2 + 0.2),
			center * CFrame.new(0, slab * 0.25, 0),
			look.trim,
			look.trimMat
		)
		-- Battlements round the edge.
		local merlon = math.max(1.2, w / 12)
		local count = math.floor((w + over * 2) / (merlon * 2))
		for i = 0, count do
			local x = -w / 2 - over + i * (w + over * 2) / count
			for _, z in { -d / 2 - over, d / 2 + over } do
				block(
					model,
					Vector3.new(merlon, merlon, merlon * 0.8),
					center * CFrame.new(x, slab + merlon / 2, z),
					look.wall,
					look.wallMat
				)
			end
		end
		-- A pointed blue keep roof and flags.
		local keep = math.min(w, d) * 0.5
		post(model, keep * 0.7, keep, center * CFrame.new(0, slab, 0), look.wall, look.wallMat)
		cone(model, keep * 1.1, keep * 1.15, center * CFrame.new(0, slab + keep * 0.7, 0), look.roof, look.roofMat, 7)
		post(
			model,
			keep * 0.9,
			math.max(0.2, w / 120),
			center * CFrame.new(0, slab + keep * 1.8, 0),
			look.trim,
			look.trimMat
		)
		block(
			model,
			Vector3.new(keep * 0.5, keep * 0.28, 0.1),
			center * CFrame.new(keep * 0.25, slab + keep * 2.5, 0),
			look.accent
		)
	elseif shape == "spikes" then
		local slab = math.max(0.8, w / 25)
		solid(
			model,
			Vector3.new(w + over * 2, slab, d + over * 2),
			center * CFrame.new(0, slab / 2, 0),
			look.roof,
			look.roofMat
		)
		-- A cluster of crystal spikes, tallest in the middle.
		local spikes = {
			{ 0, 0, 1, 0 },
			{ -0.28, 0.1, 0.7, -14 },
			{ 0.3, -0.1, 0.75, 12 },
			{ -0.12, -0.25, 0.55, -8 },
			{ 0.15, 0.25, 0.6, 9 },
			{ -0.42, -0.2, 0.45, -20 },
			{ 0.42, 0.2, 0.45, 18 },
		}
		local tall = math.min(w, d) * 0.9
		for i, s in spikes do
			local height = tall * s[3]
			local thick = math.max(0.8, w / 9) * (0.6 + s[3] * 0.4)
			local spot = center
				* CFrame.new(s[1] * w, slab, s[2] * d)
				* CFrame.Angles(math.rad(s[2] * 30), 0, math.rad(s[4]))
			local color = if i % 2 == 0 then look.accent else look.roof
			block(
				model,
				Vector3.new(thick, height, thick),
				spot * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, math.rad(45), 0),
				color,
				if i % 2 == 0 then M.Neon else M.Glass
			)
			-- A point on top.
			wedge(
				model,
				Vector3.new(thick, thick, thick * 0.7),
				spot * CFrame.new(0, height + thick / 2, 0) * CFrame.Angles(0, math.rad(45), 0),
				color,
				if i % 2 == 0 then M.Neon else M.Glass
			)
		end
	end
end

-- Door: size = { w, h } (the door slab); cf is the bottom middle of the doorway.
function builders.Door(model, cf: CFrame, look, size)
	local w, h = size.w, size.h
	local frame = math.max(0.4, w / 9)
	block(
		model,
		Vector3.new(w + frame * 2, h + frame, 0.6),
		cf * CFrame.new(0, (h + frame) / 2, -0.15),
		look.trim,
		look.trimMat
	)
	local doorColor = look.door
	local slab = block(model, Vector3.new(w, h, 0.5), cf * CFrame.new(0, h / 2, -0.35), doorColor, look.doorMat)
	slab.Name = "DoorSlab"
	if look.arched then
		-- A round arch over the door.
		local arch = block(
			model,
			Vector3.new(0.62, w + frame * 2, w + frame * 2),
			cf * CFrame.new(0, h, -0.15) * CFrame.Angles(0, math.pi / 2, 0),
			look.trim,
			look.trimMat
		)
		arch.Shape = Enum.PartType.Cylinder
		local inner = block(
			model,
			Vector3.new(0.52, w, w),
			cf * CFrame.new(0, h, -0.35) * CFrame.Angles(0, math.pi / 2, 0),
			doorColor,
			look.doorMat
		)
		inner.Shape = Enum.PartType.Cylinder
	end
	-- Panels and a knob.
	for _, y in { 0.28, 0.68 } do
		block(
			model,
			Vector3.new(w * 0.62, h * 0.26, 0.12),
			cf * CFrame.new(0, h * y, -0.62),
			doorColor:Lerp(rgb(0, 0, 0), 0.18),
			look.doorMat
		)
	end
	ball(
		model,
		math.max(0.4, w / 7),
		cf * CFrame.new(w * 0.32, h * 0.47, -0.7),
		look.accent,
		if look.accentMat == M.Neon then M.Neon else M.Foil
	)
	if look.stripes or look.rainbow then
		for i = 0, 3 do
			block(
				model,
				Vector3.new(w * 0.2, h * 0.95, 0.1),
				cf * CFrame.new(-w * 0.3 + i * w * 0.2, h / 2, -0.6) * CFrame.Angles(0, 0, math.rad(25)),
				if look.rainbow then rainbowColor(i + 1) else look.trim
			)
		end
	end
	if look.gems or look.cracks then
		block(
			model,
			Vector3.new(w * 0.25, w * 0.25, 0.3),
			cf * CFrame.new(0, h * 0.85, -0.65) * CFrame.Angles(0, 0, math.rad(45)),
			look.accent,
			M.Neon
		)
	end
	if look.clouds then
		puff(model, cf * CFrame.new(0, h + frame, -0.5), w * 0.35)
	end
end

-- One window: size = { w, h }; cf is the window's centre on the wall face.
local function window(model, cf: CFrame, look, w: number, h: number)
	local frame = math.max(0.3, w / 10)
	block(model, Vector3.new(w + frame * 2, h + frame * 2, 0.5), cf * CFrame.new(0, 0, -0.1), look.trim, look.trimMat)
	local glass = block(model, Vector3.new(w, h, 0.3), cf * CFrame.new(0, 0, -0.3), look.glass, look.glassMat)
	glass.Name = "Glass"
	if look.arched then
		local arch = block(
			model,
			Vector3.new(0.5, w + frame * 2, w + frame * 2),
			cf * CFrame.new(0, h / 2, -0.1) * CFrame.Angles(0, math.pi / 2, 0),
			look.trim,
			look.trimMat
		)
		arch.Shape = Enum.PartType.Cylinder
		local top = block(
			model,
			Vector3.new(0.3, w, w),
			cf * CFrame.new(0, h / 2, -0.3) * CFrame.Angles(0, math.pi / 2, 0),
			look.glass,
			look.glassMat
		)
		top.Shape = Enum.PartType.Cylinder
	end
	-- Cross bars.
	block(model, Vector3.new(frame * 0.6, h, 0.2), cf * CFrame.new(0, 0, -0.5), look.trim, look.trimMat)
	block(model, Vector3.new(w, frame * 0.6, 0.2), cf * CFrame.new(0, 0, -0.5), look.trim, look.trimMat)
	-- A sill.
	block(
		model,
		Vector3.new(w + frame * 3, frame, 0.9),
		cf * CFrame.new(0, -h / 2 - frame, -0.35),
		look.trim,
		look.trimMat
	)
	if look.shutters then
		for _, s in { -1, 1 } do
			block(
				model,
				Vector3.new(w * 0.45, h + frame * 2, 0.25),
				cf * CFrame.new(s * (w / 2 + frame + w * 0.25), 0, -0.2),
				look.accent:Lerp(rgb(0, 0, 0), 0.1)
			)
		end
	end
	if look.icing or look.clouds then
		for i = 0, 2 do
			ball(
				model,
				w * 0.28,
				cf * CFrame.new(-w * 0.35 + i * w * 0.35, -h / 2 - frame * 1.6, -0.5),
				if look.icing then rainbowColor(i * 2 + 1) else rgb(255, 255, 255)
			)
		end
	end
	if look.ivy then
		ball(model, Vector3.new(w * 0.8, w * 0.35, 0.5), cf * CFrame.new(0, -h / 2 - frame * 1.6, -0.6), look.accent)
		for i = 0, 2 do
			ball(
				model,
				w * 0.18,
				cf * CFrame.new(-w * 0.3 + i * w * 0.3, -h / 2 - frame * 1.2, -0.85),
				rgb(255, 120, 160)
			)
		end
	end
end

-- Windows: two on the front and one on each side of a house of size { w, d, h }, or (for
-- the item version, size.single) just one.
function builders.Windows(model, cf: CFrame, look, size)
	if size.single then
		window(model, cf * CFrame.new(0, size.wh / 2 + 0.6, 0), look, size.ww, size.wh)
		return
	end
	local w, d, h = size.w, size.d, size.h
	local y = BASE + h * 0.58
	for _, x in { -w * 0.3, w * 0.3 } do
		window(model, cf * CFrame.new(x, y, 0), look, 5, 5)
	end
	for _, s in { -1, 1 } do
		window(model, cf * CFrame.new(s * w / 2, y, d / 2) * CFrame.Angles(0, s * math.pi / 2, 0), look, 5, 5)
	end
end

-- Chimney: cf is its base (inside the roof); size = { h, s } height and width.
function builders.Chimney(model, cf: CFrame, look, size)
	local h, s = size.h, size.s
	if look.shape == "dome" or look.clouds then
		-- A tall slender minaret-style chimney.
		post(model, h, s, cf, look.wall, look.wallMat)
		post(model, s * 0.2, s * 1.35, cf * CFrame.new(0, h, 0), look.trim, look.trimMat)
		ball(model, s * 1.1, cf * CFrame.new(0, h + s * 0.5, 0), look.roof, look.roofMat)
	elseif look.wallMat == M.CorrodedMetal then
		-- A crooked pipe.
		post(model, h, s * 0.8, cf, look.trim, M.Metal)
		post(model, s * 0.4, s * 1.1, cf * CFrame.new(0, h - s * 0.4, 0), look.accent, M.Metal)
		block(
			model,
			Vector3.new(s * 1.3, s * 0.2, s * 1.3),
			cf * CFrame.new(0, h + s * 0.5, 0) * CFrame.Angles(0, 0, math.rad(12)),
			look.trim,
			M.Metal
		)
	else
		local color = if look.stripes
			then look.trim
			else look.wall:Lerp(rgb(160, 60, 50), if look.wallMat then 0 else 0.7)
		solid(model, Vector3.new(s, h, s), cf * CFrame.new(0, h / 2, 0), color, look.wallMat or M.Brick)
		block(model, Vector3.new(s * 1.3, s * 0.3, s * 1.3), cf * CFrame.new(0, h, 0), look.trim, look.trimMat)
		if look.stripes or look.rainbow then
			for i = 0, 3 do
				block(
					model,
					Vector3.new(s * 1.04, s * 0.25, s * 1.04),
					cf * CFrame.new(0, h * (0.2 + i * 0.2), 0),
					if look.rainbow then rainbowColor(i + 1) else look.accent
				)
			end
		end
	end
	-- What comes out of the top.
	if look.cracks then
		ball(model, s * 0.9, cf * CFrame.new(0, h + s * 0.5, 0), look.accent, M.Neon)
	elseif look.icicles then
		ball(
			model,
			Vector3.new(s * 1.4, s * 0.5, s * 1.4),
			cf * CFrame.new(0, h + s * 0.25, 0),
			rgb(255, 255, 255),
			M.Snow
		)
	elseif look.gems then
		block(
			model,
			Vector3.new(s * 0.5, s * 1.2, s * 0.5),
			cf * CFrame.new(0, h + s * 0.6, 0) * CFrame.Angles(0, math.rad(45), 0),
			look.accent,
			M.Neon
		)
	elseif not (look.shape == "dome") then
		for i = 0, 2 do
			ball(
				model,
				s * (0.6 + i * 0.25),
				cf * CFrame.new(i * s * 0.35, h + s * (0.7 + i * 0.75), 0),
				rgb(235, 235, 240)
			)
		end
	end
end

-- Porch: steps, a floor, two posts and a canopy in front of the door. size = { w, h }
-- (h = height of the canopy).
function builders.Porch(model, cf: CFrame, look, size)
	local w, h = size.w, size.h
	local depth = w * 0.5
	local floorY = size.floor or BASE
	solid(
		model,
		Vector3.new(w, floorY, depth),
		cf * CFrame.new(0, floorY / 2, -depth / 2),
		look.trim:Lerp(rgb(0, 0, 0), 0.15),
		look.trimMat
	)
	-- Two steps.
	for i = 1, 2 do
		solid(
			model,
			Vector3.new(w * 0.55, floorY * (1 - i * 0.33), depth * 0.18),
			cf * CFrame.new(0, floorY * (1 - i * 0.33) / 2, -depth - depth * 0.18 * (i - 0.5)),
			look.trim,
			look.trimMat
		)
	end
	-- Posts.
	for _, s in { -1, 1 } do
		local spot = cf * CFrame.new(s * (w / 2 - w * 0.06), floorY, -depth + w * 0.06)
		if look.stripes then
			post(model, h - floorY, w * 0.08, spot, look.trim)
			for i = 0, 4 do
				block(
					model,
					Vector3.new(w * 0.085, (h - floorY) * 0.06, w * 0.085),
					spot * CFrame.new(0, (h - floorY) * (0.1 + i * 0.2), 0),
					look.accent
				)
			end
		elseif look.arched or look.trimMat == M.Foil then
			post(model, h - floorY, w * 0.09, spot, look.wall, look.wallMat)
			post(model, w * 0.03, w * 0.13, spot, look.trim, look.trimMat)
			post(model, w * 0.03, w * 0.13, spot * CFrame.new(0, h - floorY - w * 0.03, 0), look.trim, look.trimMat)
		elseif look.wallMat == M.Wood then
			post(model, h - floorY, w * 0.09, spot, look.trim, M.Wood)
		else
			block(
				model,
				Vector3.new(w * 0.07, h - floorY, w * 0.07),
				spot * CFrame.new(0, (h - floorY) / 2, 0),
				look.trim,
				look.trimMat
			)
		end
	end
	-- Canopy, sloping down to the front.
	local canopy = cf * CFrame.new(0, h, -depth / 2) * CFrame.Angles(math.rad(-12), 0, 0)
	block(model, Vector3.new(w + w * 0.08, w * 0.04, depth * 1.15), canopy, look.roof, look.roofMat)
	block(
		model,
		Vector3.new(w + w * 0.1, w * 0.05, w * 0.05),
		canopy * CFrame.new(0, 0, -depth * 0.58),
		look.trim,
		look.trimMat
	)
	if look.clouds or look.icing then
		for i = 0, 3 do
			ball(
				model,
				w * 0.16,
				canopy * CFrame.new(-w * 0.4 + i * w * 0.27, w * 0.05, -depth * 0.5),
				if look.icing then rgb(255, 255, 255) else rgb(255, 255, 255)
			)
		end
	end
	if look.cracks or look.gems or look.rainbow then
		-- Glowing lanterns on the posts.
		for _, s in { -1, 1 } do
			ball(
				model,
				w * 0.1,
				cf * CFrame.new(s * (w / 2 - w * 0.06), h - w * 0.12, -depth + w * 0.06),
				look.accent,
				M.Neon
			)
		end
	end
end

-- Tower: a round tower standing beside the house. size = { r, h } radius and height.
function builders.Tower(model, cf: CFrame, look, size)
	local d, h = size.r * 2, size.h
	post(model, h, d, cf, look.wall, look.wallMat)
	post(model, d * 0.06, d * 1.08, cf, look.trim:Lerp(rgb(0, 0, 0), 0.2), look.trimMat)
	-- Bands of trim and a couple of windows.
	for _, y in { 0.45, 0.98 } do
		post(model, d * 0.05, d * 1.06, cf * CFrame.new(0, h * y, 0), look.trim, look.trimMat)
	end
	for _, y in { 0.3, 0.7 } do
		block(
			model,
			Vector3.new(d * 0.22, d * 0.32, d * 0.1),
			cf * CFrame.new(0, h * y, -d / 2),
			look.trim,
			look.trimMat
		)
		block(
			model,
			Vector3.new(d * 0.15, d * 0.25, d * 0.1),
			cf * CFrame.new(0, h * y, -d / 2 - 0.05),
			look.glass,
			look.glassMat
		)
	end
	if look.logs then
		for i = 0, 6 do
			post(
				model,
				h / 8,
				d * 1.02,
				cf * CFrame.new(0, i * h / 7, 0),
				look.wall:Lerp(rgb(80, 45, 20), (i % 2) * 0.2),
				M.Wood
			)
		end
	end
	if look.stripes or look.rainbow then
		for i = 0, 5 do
			post(
				model,
				h / 14,
				d * 1.03,
				cf * CFrame.new(0, h * (0.08 + i * 0.15), 0),
				if look.rainbow then rainbowColor(i + 1) else look.trim,
				if look.rainbow then M.Neon else nil
			)
		end
	end
	if look.cracks then
		for i = 0, 2 do
			block(
				model,
				Vector3.new(d * 0.08, h * 0.25, d * 0.1),
				cf
					* CFrame.new(d * 0.2 * (i - 1), h * (0.25 + i * 0.22), -d / 2)
					* CFrame.Angles(0, 0, math.rad(20 * (i - 1))),
				look.accent,
				M.Neon
			)
		end
	end
	local top = cf * CFrame.new(0, h, 0)
	if look.shape == "castle" then
		post(model, d * 0.15, d * 1.2, top, look.wall, look.wallMat)
		for i = 0, 7 do
			local a = math.rad(i * 45)
			block(
				model,
				Vector3.new(d * 0.2, d * 0.2, d * 0.2),
				top * CFrame.new(math.sin(a) * d * 0.55, d * 0.25, math.cos(a) * d * 0.55),
				look.wall,
				look.wallMat
			)
		end
		cone(model, d * 0.9, d * 0.7, top * CFrame.new(0, d * 0.15, 0), look.roof, look.roofMat, 6)
		post(model, d * 0.5, d * 0.04, top * CFrame.new(0, d * 1.05, 0), look.trim, look.trimMat)
		block(model, Vector3.new(d * 0.3, d * 0.16, 0.1), top * CFrame.new(d * 0.15, d * 1.45, 0), look.accent)
	elseif look.shape == "dome" then
		post(model, d * 0.1, d * 1.15, top, look.trim, look.trimMat)
		ball(model, d * 0.95, top * CFrame.new(0, d * 0.15, 0), look.roof, look.roofMat)
		cone(model, d * 0.5, d * 0.12, top * CFrame.new(0, d * 0.55, 0), look.accent, look.accentMat, 4)
	elseif look.shape == "spikes" then
		post(model, d * 0.1, d * 1.1, top, look.roof, look.roofMat)
		for i, s in { { 0, 1 }, { -0.25, 0.6 }, { 0.25, 0.65 } } do
			local height = d * 1.2 * s[2]
			block(
				model,
				Vector3.new(d * 0.22, height, d * 0.22),
				top * CFrame.new(s[1] * d, height / 2, 0) * CFrame.Angles(0, math.rad(45), math.rad(s[1] * 40)),
				if i == 1 then look.accent else look.roof,
				if i == 1 then M.Neon else M.Glass
			)
		end
	else
		-- A pointed cone roof that overhangs.
		local color = if look.rainbow then rainbowColor(5) else look.roof
		cone(model, d * (if look.shape == "pointy" then 1.4 else 0.9), d * 1.3, top, color, look.roofMat, 7)
		if look.icing then
			for i = 0, 7 do
				local a = math.rad(i * 45)
				ball(
					model,
					d * 0.18,
					top * CFrame.new(math.sin(a) * d * 0.6, 0, math.cos(a) * d * 0.6),
					rgb(255, 255, 255)
				)
			end
		end
		if look.icicles then
			for i = 0, 7 do
				local a = math.rad(i * 45)
				wedge(
					model,
					Vector3.new(d * 0.05, d * 0.2, d * 0.07),
					top
						* CFrame.new(math.sin(a) * d * 0.62, -d * 0.1, math.cos(a) * d * 0.62)
						* CFrame.Angles(math.pi, a, 0),
					look.accent,
					M.Ice
				)
			end
		end
	end
	if look.clouds then
		puff(model, cf * CFrame.new(0, d * 0.1, -d * 0.5), d * 0.4)
	end
end

-- Garden: a flower bed with plants in the style's theme. size = { w, d }.
function builders.Garden(model, cf: CFrame, look, size)
	local w, d = size.w, size.d
	local edge = math.max(0.3, w / 25)
	-- Border and soil.
	block(
		model,
		Vector3.new(w, edge * 1.5, d),
		cf * CFrame.new(0, edge * 0.75, 0),
		look.trim:Lerp(rgb(0, 0, 0), 0.1),
		look.trimMat
	)
	block(
		model,
		Vector3.new(w - edge * 2, edge * 1.6, d - edge * 2),
		cf * CFrame.new(0, edge * 0.8, 0),
		rgb(110, 75, 50),
		M.Ground
	)
	local top = edge * 1.6
	local function spot(fx, fz)
		return cf * CFrame.new(fx * (w / 2 - edge * 3), top, fz * (d / 2 - edge * 3))
	end
	local spots = { { -0.8, 0.5 }, { -0.3, -0.5 }, { 0.2, 0.4 }, { 0.7, -0.3 }, { -0.75, -0.6 }, { 0.75, 0.6 } }
	local u = math.min(w, d) / 7 -- unit size of things in the bed

	if look.icing or look.stripes then
		-- Lollipops and gumdrops.
		for i, s in spots do
			if i <= 3 then
				post(model, u * 3, u * 0.25, spot(s[1], s[2]), rgb(255, 255, 255))
				local pop = block(
					model,
					Vector3.new(u * 0.4, u * 1.8, u * 1.8),
					spot(s[1], s[2]) * CFrame.new(0, u * 3.6, 0) * CFrame.Angles(0, math.pi / 2, 0),
					rainbowColor(i * 2)
				)
				pop.Shape = Enum.PartType.Cylinder
				pop.Size = Vector3.new(u * 0.4, u * 1.8, u * 1.8)
			else
				ball(
					model,
					Vector3.new(u * 1.4, u * 1.1, u * 1.4),
					spot(s[1], s[2]) * CFrame.new(0, u * 0.4, 0),
					rainbowColor(i),
					M.Glass
				)
			end
		end
	elseif look.wallMat == M.Sandstone then
		-- Cacti.
		for i, s in spots do
			if i <= 3 then
				local cactus = spot(s[1], s[2])
				local green = rgb(70, 170, 80)
				post(model, u * 3.2, u * 0.9, cactus, green)
				ball(model, u * 0.9, cactus * CFrame.new(0, u * 3.2, 0), green)
				post(model, u * 1.2, u * 0.55, cactus * CFrame.new(u * 0.7, u * 1.2, 0), green)
				ball(model, u * 0.5, cactus * CFrame.new(0, u * 3.7, 0), rgb(255, 110, 160))
			else
				ball(model, Vector3.new(u * 1.2, u * 0.7, u * 1.2), spot(s[1], s[2]), rgb(220, 190, 140), M.Sandstone)
			end
		end
	elseif look.cracks then
		-- Lava rocks with glowing cracks.
		for _, s in spots do
			ball(
				model,
				Vector3.new(u * 1.5, u * 1.1, u * 1.3),
				spot(s[1], s[2]) * CFrame.new(0, u * 0.4, 0),
				rgb(45, 35, 45),
				M.Basalt
			)
			ball(model, u * 0.55, spot(s[1], s[2]) * CFrame.new(0, u * 0.95, 0), look.accent, M.Neon)
		end
	elseif look.icicles then
		-- Ice crystals and a snowman.
		for i, s in spots do
			if i <= 4 then
				block(
					model,
					Vector3.new(u * 0.7, u * 2.4, u * 0.7),
					spot(s[1], s[2]) * CFrame.new(0, u * 1.1, 0) * CFrame.Angles(0, math.rad(45), math.rad(s[1] * 18)),
					look.accent,
					M.Ice
				)
			end
		end
		local snow = spot(0.6, 0.2)
		ball(model, u * 1.8, snow * CFrame.new(0, u * 0.8, 0), rgb(255, 255, 255), M.Snow)
		ball(model, u * 1.3, snow * CFrame.new(0, u * 2.1, 0), rgb(255, 255, 255), M.Snow)
		ball(model, u * 0.25, snow * CFrame.new(0, u * 2.2, -u * 0.62), rgb(255, 140, 40))
	elseif look.gems then
		for i, s in spots do
			local h = u * (1.6 + (i % 3) * 0.7)
			block(
				model,
				Vector3.new(u * 0.7, h, u * 0.7),
				spot(s[1], s[2]) * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, math.rad(45), math.rad(s[1] * 15)),
				if i % 2 == 0 then look.accent else look.wall,
				if i % 2 == 0 then M.Neon else M.Glass
			)
		end
	elseif look.clouds then
		for i, s in spots do
			if i <= 3 then
				puff(model, spot(s[1], s[2]) * CFrame.new(0, u * 0.6, 0), u * 1.2)
			else
				post(model, u * 1.4, u * 0.15, spot(s[1], s[2]), rgb(90, 190, 90))
				ball(model, u * 0.9, spot(s[1], s[2]) * CFrame.new(0, u * 1.5, 0), look.trim, M.Foil)
			end
		end
	elseif look.shape == "castle" then
		-- Topiary balls and a little fountain.
		for i, s in spots do
			if i <= 4 then
				post(model, u * 1, u * 0.3, spot(s[1], s[2]), rgb(120, 80, 50))
				ball(model, u * 1.6, spot(s[1], s[2]) * CFrame.new(0, u * 1.6, 0), rgb(60, 160, 70))
			end
		end
		local fountain = spot(0.3, 0.1)
		post(model, u * 0.6, u * 2.4, fountain, look.wall, look.wallMat)
		post(model, u * 0.2, u * 2, fountain * CFrame.new(0, u * 0.55, 0), rgb(90, 190, 255))
		post(model, u * 1.6, u * 0.4, fountain, look.trim, look.trimMat)
		ball(model, u * 0.8, fountain * CFrame.new(0, u * 1.9, 0), rgb(120, 210, 255), M.Glass)
	elseif look.wallMat == M.CorrodedMetal then
		-- Flowers growing out of old tyres.
		for i, s in spots do
			if i <= 3 then
				local tyre = block(
					model,
					Vector3.new(u * 0.7, u * 1.8, u * 1.8),
					spot(s[1], s[2]) * CFrame.new(0, u * 0.35, 0) * CFrame.Angles(0, 0, math.pi / 2),
					rgb(40, 40, 45)
				)
				tyre.Shape = Enum.PartType.Cylinder
				ball(model, u * 0.7, spot(s[1], s[2]) * CFrame.new(0, u * 1, 0), rainbowColor(i * 2))
			end
		end
	elseif look.logs then
		-- A pine tree and mushrooms.
		local tree = spot(-0.5, 0.2)
		post(model, u * 1.6, u * 0.6, tree, rgb(110, 70, 40), M.Wood)
		cone(model, u * 4.2, u * 3.2, tree * CFrame.new(0, u * 1.2, 0), rgb(50, 130, 70), nil, 5)
		for i, s in { { 0.4, -0.3 }, { 0.75, 0.4 }, { 0.1, 0.5 } } do
			post(model, u * 0.6, u * 0.3, spot(s[1], s[2]), rgb(250, 240, 220))
			ball(
				model,
				Vector3.new(u * 1, u * 0.55, u * 1),
				spot(s[1], s[2]) * CFrame.new(0, u * 0.65, 0),
				if i == 2 then rgb(255, 200, 60) else rgb(225, 50, 50)
			)
		end
	elseif look.ivy then
		-- A rock garden with a bush.
		for i, s in spots do
			ball(
				model,
				Vector3.new(u * 1.3, u * 0.9, u * 1.1),
				spot(s[1], s[2]) * CFrame.new(0, u * 0.3, 0),
				rgb(150, 150, 155):Lerp(rgb(110, 110, 115), (i % 2) * 0.5),
				M.Slate
			)
		end
		ball(model, Vector3.new(u * 2.4, u * 1.8, u * 2), spot(0, 0) * CFrame.new(0, u * 0.8, 0), look.accent)
		ball(model, u * 0.5, spot(0, 0) * CFrame.new(u * 0.5, u * 1.6, -u * 0.6), rgb(255, 120, 170))
	else
		-- Plain flowers on stems.
		for i, s in spots do
			post(model, u * 1.4, u * 0.18, spot(s[1], s[2]), rgb(70, 160, 70))
			ball(model, u * 0.9, spot(s[1], s[2]) * CFrame.new(0, u * 1.5, 0), rainbowColor(i))
			ball(model, u * 0.35, spot(s[1], s[2]) * CFrame.new(0, u * 1.5, -u * 0.35), rgb(255, 230, 80))
		end
		ball(model, Vector3.new(u * 2, u * 1.4, u * 1.6), spot(0.1, 0) * CFrame.new(0, u * 0.6, 0), look.accent)
	end
	if look.rainbow then
		-- A little rainbow arc over the bed.
		for i = 1, 6 do
			local r = u * (3.6 - i * 0.35)
			for k = 0, 8 do
				local a = math.rad(k * 22.5)
				ball(
					model,
					u * 0.4,
					cf * CFrame.new(math.cos(a) * r, top + math.sin(a) * r, d * 0.25),
					rainbowColor(i),
					M.Neon
				)
			end
		end
	end
end

-- Mailbox: a post and box. size = { h } (post height).
function builders.Mailbox(model, cf: CFrame, look, size)
	local h = size.h
	local s = h / 4
	if look.clouds then
		puff(model, cf * CFrame.new(0, s * 0.6, 0), s * 1.4)
	end
	post(model, h, s * 0.45, cf, look.trim, look.trimMat)
	local box = cf * CFrame.new(0, h + s * 0.5, 0)
	local color = if look.rainbow then rainbowColor(5) else look.accent
	local mat = if look.accentMat == M.Neon and not look.cracks then nil else look.accentMat
	if look.cracks then
		color, mat = look.wall, look.wallMat
	end
	block(model, Vector3.new(s * 1.3, s, s * 2.2), box, color, mat)
	local top = block(
		model,
		Vector3.new(s * 2.2, s * 1.3, s * 1.3),
		box * CFrame.new(0, s * 0.5, 0) * CFrame.Angles(0, math.pi / 2, 0),
		color,
		mat
	)
	top.Shape = Enum.PartType.Cylinder
	-- Little red flag.
	block(model, Vector3.new(0.15, s * 0.9, 0.15), box * CFrame.new(s * 0.72, s * 0.4, s * 0.3), rgb(230, 50, 60))
	block(model, Vector3.new(0.12, s * 0.4, s * 0.6), box * CFrame.new(s * 0.72, s * 0.75, s * 0.55), rgb(230, 50, 60))
	-- A letter poking out.
	block(
		model,
		Vector3.new(s * 0.9, s * 0.08, s * 0.6),
		box * CFrame.new(0, 0, -s * 1.15) * CFrame.Angles(math.rad(-25), 0, 0),
		rgb(255, 255, 255)
	)
	if look.cracks or look.gems then
		ball(model, s * 0.5, box * CFrame.new(0, s * 1.3, 0), look.accent, M.Neon)
	elseif look.icing then
		ball(model, Vector3.new(s * 1.5, s * 0.4, s * 2.4), box * CFrame.new(0, s * 1.1, 0), rgb(255, 255, 255))
		ball(model, s * 0.45, box * CFrame.new(0, s * 1.4, 0), rgb(230, 30, 50))
	elseif look.icicles then
		ball(
			model,
			Vector3.new(s * 1.6, s * 0.45, s * 2.5),
			box * CFrame.new(0, s * 1.1, 0),
			rgb(255, 255, 255),
			M.Snow
		)
	elseif look.shape == "castle" then
		cone(model, s * 0.8, s * 0.7, box * CFrame.new(0, s * 1.1, 0), look.trim, look.trimMat, 4)
	end
end

-- Fence: runs along cf's X axis from x = 0 to x = length. size = { length, h }.
function builders.Fence(model, cf: CFrame, look, size)
	local length, h = size.length, size.h
	local gap = h * 0.75
	local count = math.max(1, math.floor(length / gap))
	local color, mat = look.trim, look.trimMat
	if look.wallMat == M.Cobblestone or look.wallMat == M.Sandstone or look.wallMat == M.Ice then
		-- A low wall with caps.
		solid(
			model,
			Vector3.new(length, h * 0.7, h * 0.35),
			cf * CFrame.new(length / 2, h * 0.35, 0),
			look.wall,
			look.wallMat
		)
		block(
			model,
			Vector3.new(length + 0.2, h * 0.12, h * 0.45),
			cf * CFrame.new(length / 2, h * 0.72, 0),
			look.trim,
			look.trimMat
		)
		for i = 0, count do
			block(
				model,
				Vector3.new(h * 0.42, h * 0.95, h * 0.42),
				cf * CFrame.new(i * length / count, h * 0.47, 0),
				look.trim,
				look.trimMat
			)
			if look.icicles then
				ball(
					model,
					Vector3.new(h * 0.5, h * 0.2, h * 0.5),
					cf * CFrame.new(i * length / count, h * 0.98, 0),
					rgb(255, 255, 255),
					M.Snow
				)
			end
		end
		return
	end
	if look.wallMat == M.CorrodedMetal then
		-- Mismatched sheets of tin.
		for i = 0, count - 1 do
			block(
				model,
				Vector3.new(length / count * 1.05, h * (0.8 + (i % 3) * 0.1), 0.2),
				cf
					* CFrame.new((i + 0.5) * length / count, h * 0.42, 0)
					* CFrame.Angles(0, 0, math.rad((i % 3 - 1) * 3)),
				if i % 2 == 0 then look.wall else look.trim,
				M.CorrodedMetal
			)
		end
		return
	end
	if look.wallMat == M.Wood then
		color, mat = look.wall, M.Wood
	end
	local railColor = if look.rainbow then rgb(255, 255, 255) else color
	-- Rails.
	for _, y in { 0.35, 0.72 } do
		block(model, Vector3.new(length, h * 0.1, h * 0.08), cf * CFrame.new(length / 2, h * y, 0), railColor, mat)
	end
	for i = 0, count do
		local x = i * length / count
		local spot = cf * CFrame.new(x, 0, 0)
		local postColor = if look.rainbow then rainbowColor(i + 1) else color
		if look.stripes then
			post(model, h, h * 0.16, spot, look.trim)
			for k = 0, 2 do
				block(
					model,
					Vector3.new(h * 0.17, h * 0.08, h * 0.17),
					spot * CFrame.new(0, h * (0.2 + k * 0.3), 0),
					look.accent
				)
			end
			-- Candy cane hook.
			block(model, Vector3.new(h * 0.3, h * 0.14, h * 0.14), spot * CFrame.new(h * 0.12, h, 0), look.accent)
		elseif look.cracks then
			wedge(
				model,
				Vector3.new(h * 0.18, h * 1.2, h * 0.18),
				spot * CFrame.new(0, h * 0.6, 0),
				look.wall,
				look.wallMat
			)
			ball(model, h * 0.14, spot * CFrame.new(0, h * 0.3, -h * 0.08), look.accent, M.Neon)
		elseif look.gems then
			block(
				model,
				Vector3.new(h * 0.18, h * 1.1, h * 0.18),
				spot * CFrame.new(0, h * 0.55, 0) * CFrame.Angles(0, math.rad(45), 0),
				if i % 2 == 0 then look.accent else look.wall,
				if i % 2 == 0 then M.Neon else M.Glass
			)
		elseif look.clouds then
			post(model, h * 0.9, h * 0.1, spot, look.trim, look.trimMat)
			ball(model, h * 0.35, spot * CFrame.new(0, h * 0.95, 0), rgb(255, 255, 255))
		elseif look.shape == "castle" then
			post(model, h * 1.1, h * 0.08, spot, rgb(40, 40, 50), M.Metal)
			wedge(
				model,
				Vector3.new(h * 0.12, h * 0.2, h * 0.12),
				spot * CFrame.new(0, h * 1.2, 0),
				look.trim,
				look.trimMat
			)
		else
			-- Pickets with pointed tops.
			block(model, Vector3.new(h * 0.18, h * 0.85, h * 0.1), spot * CFrame.new(0, h * 0.42, 0), postColor, mat)
			wedge(
				model,
				Vector3.new(h * 0.1, h * 0.15, h * 0.09),
				spot * CFrame.new(0, h * 0.92, 0.0) * CFrame.Angles(0, math.pi / 2, 0),
				postColor,
				mat
			)
		end
	end
end

--------------------------------------------------------------------------------
-- Where each slot goes on a full house (plot space: origin at the plot's centre, front -Z).
--------------------------------------------------------------------------------

local HOUSE_Z = 6 -- the front wall's z
local FENCE_Z = -46.5
local GATE_HALF = 8

local PLACEMENTS = {
	Walls = function(model, look)
		builders.Walls(model, CFrame.new(0, 0, HOUSE_Z), look, { w = BODY.w, d = BODY.d, h = BODY.h })
	end,
	Roof = function(model, look)
		builders.Roof(model, CFrame.new(0, 0, HOUSE_Z), look, { w = BODY.w, d = BODY.d, y = BASE + BODY.h })
	end,
	Door = function(model, look)
		builders.Door(model, CFrame.new(0, BASE, HOUSE_Z), look, { w = 5, h = 8 })
	end,
	Windows = function(model, look)
		builders.Windows(model, CFrame.new(0, 0, HOUSE_Z), look, { w = BODY.w, d = BODY.d, h = BODY.h })
	end,
	Chimney = function(model, look)
		builders.Chimney(
			model,
			CFrame.new(BODY.w * 0.3, BASE + BODY.h, HOUSE_Z + BODY.d * 0.72),
			look,
			{ h = 11, s = 3 }
		)
	end,
	Porch = function(model, look)
		builders.Porch(model, CFrame.new(0, 0, HOUSE_Z), look, { w = 11, h = 10.5 })
	end,
	Tower = function(model, look)
		builders.Tower(model, CFrame.new(-BODY.w / 2 - 4.5, 0, HOUSE_Z + BODY.d * 0.45), look, { r = 5.5, h = 24 })
	end,
	Garden = function(model, look)
		builders.Garden(model, CFrame.new(-31, 0, -12), look, { w = 16, d = 9 })
	end,
	Mailbox = function(model, look)
		builders.Mailbox(model, CFrame.new(GATE_HALF + 3, 0, FENCE_Z + 3), look, { h = 4 })
	end,
	Fence = function(model, look)
		local h = 3.2
		local edge = 47
		builders.Fence(model, CFrame.new(-edge, 0, FENCE_Z), look, { length = edge - GATE_HALF, h = h })
		builders.Fence(model, CFrame.new(GATE_HALF, 0, FENCE_Z), look, { length = edge - GATE_HALF, h = h })
		-- Down both sides and along the back.
		builders.Fence(
			model,
			CFrame.new(-edge, 0, FENCE_Z) * CFrame.Angles(0, -math.pi / 2, 0),
			look,
			{ length = edge * 2 - 0.5, h = h }
		)
		builders.Fence(
			model,
			CFrame.new(edge, 0, -FENCE_Z) * CFrame.Angles(0, math.pi / 2, 0),
			look,
			{ length = edge * 2 - 0.5, h = h }
		)
		builders.Fence(model, CFrame.new(-edge, 0, -FENCE_Z), look, { length = edge * 2, h = h })
	end,
}
HouseModel.FENCE_Z = FENCE_Z
HouseModel.GATE_HALF = GATE_HALF
HouseModel.HOUSE_Z = HOUSE_Z

-- Where to put each slot's "steal" prompt on a full house (plot space).
HouseModel.ANCHORS = {
	Walls = Vector3.new(BODY.w * 0.3, 4, HOUSE_Z - 0.5),
	Roof = Vector3.new(0, BASE + BODY.h + 3, HOUSE_Z + 2),
	Door = Vector3.new(0, 4, HOUSE_Z - 1),
	Windows = Vector3.new(-BODY.w * 0.3, BASE + BODY.h * 0.58, HOUSE_Z - 1),
	Chimney = Vector3.new(BODY.w * 0.3, BASE + BODY.h + 6, HOUSE_Z + BODY.d * 0.6),
	Porch = Vector3.new(4, 2, HOUSE_Z - 4),
	Tower = Vector3.new(-BODY.w / 2 - 4.5, 4, HOUSE_Z + BODY.d * 0.45 - 6),
	Garden = Vector3.new(-31, 1.5, -12),
	Mailbox = Vector3.new(GATE_HALF + 3, 3, FENCE_Z + 3),
	Fence = Vector3.new(-26, 2, FENCE_Z + 1),
}

--------------------------------------------------------------------------------
-- Public
--------------------------------------------------------------------------------

-- One slot of a full house, as its own Model.
function HouseModel.slot(slotId: string, partId: string?): Model
	local id = partId or Parts.basic(slotId)
	local part = Parts.byId[id]
	local look = lookFor(part and part.style or "Basic")
	local model = Instance.new("Model")
	model.Name = slotId
	model:SetAttribute("Part", id)
	PLACEMENTS[slotId](model, look)
	return model
end

-- A whole house: parts = { [slotId] = partId }.
function HouseModel.house(parts): Model
	local model = Instance.new("Model")
	model.Name = "House"
	for _, slot in Parts.SLOTS do
		HouseModel.slot(slot.id, parts and parts[slot.id]).Parent = model
	end
	return model
end

-- One part on its own, about 5 studs across, standing on the origin and facing -Z.
local ITEMS = {
	Walls = function(model, look)
		builders.Walls(model, CFrame.new(0, 0, -1), look, { w = 5.5, d = 2.2, h = 4.4, base = 0.4 })
		-- A window so it reads as a piece of wall, not a box.
		window(model, CFrame.new(0, 2.7, -1.05), look, 1.7, 1.7)
	end,
	Roof = function(model, look)
		builders.Roof(model, CFrame.new(0, 0, -2), look, { w = 5.5, d = 4, y = 0 })
	end,
	Door = function(model, look)
		builders.Door(model, CFrame.new(0, 0, 0), look, { w = 3, h = 4.8 })
	end,
	Windows = function(model, look)
		builders.Windows(model, CFrame.new(0, 0, 0), look, { single = true, ww = 3.4, wh = 3.4 })
	end,
	Chimney = function(model, look)
		builders.Chimney(model, CFrame.new(0, 0, 0), look, { h = 4, s = 1.8 })
	end,
	Porch = function(model, look)
		builders.Porch(model, CFrame.new(0, 0, 1.4), look, { w = 5.5, h = 5, floor = 0.5 })
	end,
	Tower = function(model, look)
		builders.Tower(model, CFrame.new(0, 0, 0), look, { r = 1.5, h = 5 })
	end,
	Garden = function(model, look)
		builders.Garden(model, CFrame.new(0, 0, 0), look, { w = 5.5, d = 3.6 })
	end,
	Mailbox = function(model, look)
		builders.Mailbox(model, CFrame.new(0, 0, 0), look, { h = 3.2 })
	end,
	Fence = function(model, look)
		builders.Fence(model, CFrame.new(-2.7, 0, 0), look, { length = 5.4, h = 3 })
	end,
}

function HouseModel.item(partId: string): Model
	local part = Parts.byId[partId]
	local model = Instance.new("Model")
	model.Name = partId
	model:SetAttribute("Part", partId)
	if part then
		ITEMS[part.slot](model, lookFor(part.style))
	end
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
		end
	end
	-- Stand it on its base. Roblox puts a new model's pivot in the middle of its parts, which
	-- would sink it halfway into whatever it's put on.
	model.WorldPivot = CFrame.identity
	return model
end

return HouseModel
