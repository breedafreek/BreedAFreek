-- Every Freek species in the game.
--
-- id       unique key saved in player data; never rename one after release
-- income   money per second while in the yard
-- price    set only for starter Freeks: always allowed on the conveyor belt, at this price.
--          Other species appear on the belt once discovered, priced from their income.
-- season   optional Seasonal tag (a key in Seasons.luau): only obtainable during that season
-- look     how the model is built: either a placeholder (shape "Ball" or "Block", size in
--          studs, eyes 1-3, antennae 0-3) or a part list (see FreekModel), e.g. from human()
--
-- Fusing two different Freeks makes a hybrid (see Hybrids.luau); the only hand-made results
-- are the Ultra pairs that make Secrets, in ServerScriptService (Recipes).

local Freeks = {}

-- The Human line: Freeks shaped like little cartoon people. human() builds the shared body
-- (legs, hips, torso, arms, neck, a big head with googly eyes and a mouth) and adds each
-- one's own parts on top. The torso is the first part, so hybrids mix them like any other
-- Freek: one parent's legs and body, the other's head.
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Helpers for the Animal line: each animal is a list of parts like Oinkle's, built with
-- these so eyes, legs and pointy ears line up without hand-maths.
local function newParts()
	local list = {}
	local function add(spec)
		table.insert(list, spec)
		return #list
	end
	return list, add
end

-- A point on the front (-Z) of a ball centred at c with radius r, offset (x, y) from c.
local function onBall(c, r: number, x: number, y: number, out: number?)
	return { c[1] + x, c[2] + y, c[3] - math.sqrt(math.max(r * r - x * x - y * y, 0.01)) - (out or 0) }
end

-- Googly eyes on the front of a ball (head).
local function googly(add, c, r: number, spread: number, height: number, size: number, iris: Color3?)
	for _, side in { -1, 1 } do
		local p = onBall(c, r, side * spread, height, -size * 0.25)
		add({ shape = "Ball", size = size, pos = p, color = rgb(255, 255, 255), detail = true })
		if iris then
			add({
				shape = "Ball",
				size = size * 0.7,
				pos = { p[1], p[2], p[3] - size * 0.2 },
				color = iris,
				detail = true,
			})
		end
		add({
			shape = "Ball",
			size = size * 0.45,
			pos = { p[1], p[2], p[3] - size * 0.36 },
			color = rgb(20, 20, 25),
			detail = true,
		})
	end
end

-- Straight legs standing on the ground, centred at each (x, z).
local function legs(add, spots, height: number, width: number, color: Color3, paw: Color3?)
	for _, spot in spots do
		add({
			shape = "Cylinder",
			size = { height, width, width },
			pos = { spot[1], height / 2, spot[2] },
			rot = { 0, 0, 90 },
			color = color,
		})
		if paw then
			add({
				shape = "Ball",
				size = width + 0.15,
				pos = { spot[1], (width + 0.15) / 2, spot[2] - 0.08 },
				color = paw,
			})
		end
	end
end

-- A pointy ear (a triangle seen from the front), made of two wedges back to back.
local function pointyEar(add, x: number, y: number, z: number, width: number, height: number, color: Color3)
	for _, side in { -1, 1 } do
		add({
			shape = "Wedge",
			size = { 0.25, height, width / 2 },
			pos = { x + side * width / 4, y, z },
			rot = { 0, side * -90, 0 },
			color = color,
		})
	end
end

local function human(o)
	local parts = {}
	local function add(spec)
		table.insert(parts, spec)
		return #parts
	end
	local torsoW, torsoD = o.torsoWidth or 1.9, o.torsoDepth or 1.1
	local armD = o.armSize or 0.5
	local head = o.head or 2.1
	local torsoY = 1.6 + 0.85
	local torsoTop = 1.6 + 1.7
	local headY = torsoTop + 0.15 + head * 0.45
	local r = head / 2
	-- How far forward the face is at (x, y) relative to the head's centre.
	local function face(x: number, y: number, out: number?): number
		return -math.sqrt(math.max(r * r - x * x - y * y, 0.01)) - (out or 0)
	end

	add({ name = "Body", shape = "Block", size = { torsoW, 1.7, torsoD }, pos = { 0, torsoY, 0 }, color = o.shirt })
	add({ shape = "Block", size = { torsoW - 0.1, 0.5, torsoD - 0.05 }, pos = { 0, 1.4, 0 }, color = o.pants })
	for _, x in { -0.45, 0.45 } do
		add({ shape = "Cylinder", size = { 1.2, 0.6, 0.6 }, pos = { x, 0.75, 0 }, rot = { 0, 0, 90 }, color = o.pants })
		add({
			shape = "Block",
			size = o.shoeSize or { 0.7, 0.35, 1.05 },
			pos = { x, 0.18, -0.15 },
			color = o.shoes,
			detail = true,
		})
	end
	local shoulderX = torsoW / 2 + armD / 2 - 0.02
	for _, side in { -1, 1 } do
		add({
			shape = "Cylinder",
			size = { 1.45, armD, armD },
			pos = { side * shoulderX, 2.5, 0 },
			rot = { 0, 0, 90 + side * 6 },
			color = o.sleeves or o.skin,
		})
		add({ shape = "Ball", size = armD + 0.12, pos = { side * (shoulderX + 0.08), 1.72, 0 }, color = o.skin })
	end
	add({
		shape = "Cylinder",
		size = { 0.35, 0.55, 0.55 },
		pos = { 0, torsoTop + 0.1, 0 },
		rot = { 0, 0, 90 },
		color = o.skin,
	})
	add({ name = "Head", shape = "Ball", size = head, pos = { 0, headY, 0 }, color = o.skin })
	local eyeX, eyeY = head * 0.17, head * 0.06
	for _, side in { -1, 1 } do
		local z = face(eyeX, eyeY, -0.12)
		add({
			shape = "Ball",
			size = 0.55,
			pos = { side * eyeX, headY + eyeY, z },
			color = rgb(255, 255, 255),
			detail = true,
		})
		add({
			shape = "Ball",
			size = 0.28,
			pos = { side * eyeX, headY + eyeY, z - 0.22 },
			color = rgb(25, 25, 30),
			detail = true,
		})
	end
	if not o.noMouth then
		add({
			shape = "Block",
			size = { 0.6, 0.1, 0.1 },
			pos = { 0, headY - head * 0.2, face(0, head * 0.2, -0.04) },
			color = rgb(110, 40, 60),
			detail = true,
		})
	end

	local effects = {}
	if o.extra then
		o.extra({
			add = add,
			face = face,
			skin = o.skin,
			headY = headY,
			head = head,
			torsoTop = torsoTop,
			torsoY = torsoY,
			torsoW = torsoW,
			torsoD = torsoD,
			shoulderX = shoulderX,
			eyeX = eyeX,
			eyeY = eyeY,
			effects = effects,
		})
	end
	return { parts = parts, effects = effects }
end

Freeks.list = {
	-- Starter Freeks (shop)
	{
		id = "Oinkle",
		name = "Oinkle",
		rarity = "Common",
		income = 1,
		price = 50,
		look = {
			parts = {
				-- Body
				{ shape = "Ball", size = 3.4, pos = { 0, 2.1, 0 }, color = Color3.fromRGB(255, 170, 190) },
				-- Legs
				{
					shape = "Cylinder",
					size = { 1, 0.75, 0.75 },
					pos = { -0.8, 0.5, -0.75 },
					rot = { 0, 0, 90 },
					color = Color3.fromRGB(240, 145, 170),
				},
				{
					shape = "Cylinder",
					size = { 1, 0.75, 0.75 },
					pos = { 0.8, 0.5, -0.75 },
					rot = { 0, 0, 90 },
					color = Color3.fromRGB(240, 145, 170),
				},
				{
					shape = "Cylinder",
					size = { 1, 0.75, 0.75 },
					pos = { -0.8, 0.5, 0.75 },
					rot = { 0, 0, 90 },
					color = Color3.fromRGB(240, 145, 170),
				},
				{
					shape = "Cylinder",
					size = { 1, 0.75, 0.75 },
					pos = { 0.8, 0.5, 0.75 },
					rot = { 0, 0, 90 },
					color = Color3.fromRGB(240, 145, 170),
				},
				-- Snout and nostrils
				{
					shape = "Cylinder",
					size = { 0.55, 1.15, 1.15 },
					pos = { 0, 1.95, -1.72 },
					rot = { 0, 90, 0 },
					color = Color3.fromRGB(255, 135, 160),
				},
				{
					shape = "Ball",
					size = 0.24,
					pos = { -0.22, 1.95, -2.0 },
					color = Color3.fromRGB(110, 40, 60),
					detail = true,
				},
				{
					shape = "Ball",
					size = 0.24,
					pos = { 0.22, 1.95, -2.0 },
					color = Color3.fromRGB(110, 40, 60),
					detail = true,
				},
				-- Eyes
				{
					shape = "Ball",
					size = 0.62,
					pos = { -0.6, 2.75, -1.42 },
					color = Color3.new(1, 1, 1),
					detail = true,
				},
				{
					shape = "Ball",
					size = 0.32,
					pos = { -0.6, 2.75, -1.68 },
					color = Color3.new(0, 0, 0),
					detail = true,
				},
				{ shape = "Ball", size = 0.62, pos = { 0.6, 2.75, -1.42 }, color = Color3.new(1, 1, 1), detail = true },
				{ shape = "Ball", size = 0.32, pos = { 0.6, 2.75, -1.68 }, color = Color3.new(0, 0, 0), detail = true },
				-- Rosy cheeks
				{
					shape = "Ball",
					size = 0.5,
					pos = { -1.0, 2.0, -1.22 },
					color = Color3.fromRGB(255, 110, 140),
					detail = true,
				},
				{
					shape = "Ball",
					size = 0.5,
					pos = { 1.0, 2.0, -1.22 },
					color = Color3.fromRGB(255, 110, 140),
					detail = true,
				},
				-- Smile
				{
					shape = "Block",
					size = { 0.55, 0.1, 0.1 },
					pos = { 0, 1.18, -1.45 },
					color = Color3.fromRGB(110, 40, 60),
					detail = true,
				},
				-- Floppy ears
				{
					shape = "Wedge",
					size = { 0.2, 1.1, 1 },
					pos = { -0.85, 3.55, -0.4 },
					rot = { -15, 90, 20 },
					color = Color3.fromRGB(240, 140, 165),
				},
				{
					shape = "Wedge",
					size = { 0.2, 1.1, 1 },
					pos = { 0.85, 3.55, -0.4 },
					rot = { -15, -90, -20 },
					color = Color3.fromRGB(240, 140, 165),
				},
				-- Curly tail
				{ shape = "Ball", size = 0.3, pos = { 0, 2.25, 1.75 }, color = Color3.fromRGB(240, 145, 170) },
				{ shape = "Ball", size = 0.3, pos = { 0.18, 2.42, 1.88 }, color = Color3.fromRGB(240, 145, 170) },
				{ shape = "Ball", size = 0.3, pos = { 0.05, 2.62, 1.96 }, color = Color3.fromRGB(240, 145, 170) },
				{ shape = "Ball", size = 0.3, pos = { -0.14, 2.5, 2.02 }, color = Color3.fromRGB(240, 145, 170) },
			},
		},
	},

	-- The Animal line (Oinkle is the pig)
	{
		id = "Woofles",
		name = "Woofles",
		rarity = "Common",
		income = 3,
		look = (function()
			local list, add = newParts()
			local tan, dark, light = rgb(225, 175, 110), rgb(140, 95, 55), rgb(250, 232, 205)
			add({ name = "Body", shape = "Ball", size = 3, pos = { 0, 2, 0.3 }, color = tan })
			legs(add, { { -0.75, -0.45 }, { 0.75, -0.45 }, { -0.75, 1.1 }, { 0.75, 1.1 } }, 1.1, 0.6, tan, light)
			local head = { 0, 3.55, -1 }
			add({ name = "Head", shape = "Ball", size = 2.3, pos = head, color = tan })
			add({ shape = "Ball", size = 1.15, pos = { 0, 3.15, -2.05 }, color = light })
			add({ shape = "Ball", size = 0.45, pos = { 0, 3.42, -2.62 }, color = rgb(25, 20, 20), detail = true })
			add({
				shape = "Block",
				size = { 0.34, 0.55, 0.1 },
				pos = { 0.12, 2.68, -2.42 },
				rot = { 15, 0, 0 },
				color = rgb(255, 110, 140),
				detail = true,
			})
			googly(add, head, 1.15, 0.45, 0.32, 0.5)
			for _, side in { -1, 1 } do
				add({
					shape = "Block",
					size = { 0.25, 1.4, 0.8 },
					pos = { side * 1.15, 3.35, -0.9 },
					rot = { 0, 0, side * 12 },
					color = dark,
				})
			end
			add({ shape = "Ball", size = 1.3, pos = { 0.85, 2.7, 0.9 }, color = dark })
			add({
				shape = "Cylinder",
				size = { 1.1, 0.32, 0.32 },
				pos = { 0, 2.8, 1.95 },
				rot = { 0, -90, 55 },
				color = tan,
			})
			add({
				shape = "Cylinder",
				size = { 0.3, 2, 2 },
				pos = { 0, 2.75, -0.75 },
				rot = { 0, 0, 90 },
				color = rgb(220, 40, 50),
			})
			add({ shape = "Ball", size = 0.38, pos = { 0, 2.45, -1.72 }, color = rgb(255, 205, 60), material = "Foil" })
			return { parts = list }
		end)(),
	},
	{
		id = "Whiskerz",
		name = "Whiskerz",
		rarity = "Uncommon",
		income = 14,
		look = (function()
			local list, add = newParts()
			local orange, stripe, light = rgb(255, 165, 70), rgb(215, 105, 30), rgb(255, 232, 205)
			add({ name = "Body", shape = "Ball", size = 2.8, pos = { 0, 1.8, 0.3 }, color = orange })
			legs(add, { { -0.6, -0.4 }, { 0.6, -0.4 }, { -0.6, 1 }, { 0.6, 1 } }, 0.95, 0.5, orange, light)
			local head = { 0, 3.3, -0.9 }
			add({ name = "Head", shape = "Ball", size = 2.3, pos = head, color = orange })
			for _, side in { -1, 1 } do
				pointyEar(add, side * 0.68, 4.45, -0.75, 0.85, 0.95, orange)
				pointyEar(add, side * 0.68, 4.4, -0.9, 0.45, 0.55, rgb(255, 160, 180))
			end
			for _, side in { -1, 1 } do
				local p = onBall(head, 1.15, side * 0.43, 0.25, -0.12)
				add({ shape = "Ball", size = 0.6, pos = p, color = rgb(255, 255, 255), detail = true })
				add({
					shape = "Ball",
					size = 0.45,
					pos = { p[1], p[2], p[3] - 0.13 },
					color = rgb(120, 220, 90),
					detail = true,
				})
				add({
					shape = "Block",
					size = { 0.08, 0.34, 0.05 },
					pos = { p[1], p[2], p[3] - 0.3 },
					color = rgb(20, 20, 25),
					detail = true,
				})
				for i, tilt in { -12, 0, 12 } do
					add({
						shape = "Block",
						size = { 0.95, 0.04, 0.04 },
						pos = { side * 0.85, 2.95 + (i - 2) * 0.12, -1.95 },
						rot = { 0, 0, side * tilt },
						color = rgb(255, 255, 255),
						detail = true,
					})
				end
			end
			add({
				shape = "Ball",
				size = 0.28,
				pos = onBall(head, 1.15, 0, -0.1, 0.05),
				color = rgb(255, 120, 150),
				detail = true,
			})
			add({
				shape = "Block",
				size = { 0.4, 0.07, 0.07 },
				pos = onBall(head, 1.15, 0, -0.4, -0.02),
				color = rgb(110, 40, 60),
				detail = true,
			})
			-- Tabby marks on the forehead.
			for _, x in { -0.25, 0, 0.25 } do
				add({
					shape = "Block",
					size = { 0.1, 0.38, 0.06 },
					pos = onBall(head, 1.15, x, 0.72, 0.01),
					rot = { -35, 0, 0 },
					color = stripe,
					detail = true,
				})
			end
			local tail = {
				{ 0, 1.9, 1.6 },
				{ 0, 2.3, 1.95 },
				{ 0, 2.8, 2.15 },
				{ 0, 3.3, 2.15 },
				{ 0, 3.7, 1.95 },
				{ 0, 3.9, 1.65 },
			}
			for _, p in tail do
				add({ shape = "Ball", size = 0.45, pos = p, color = orange })
			end
			return { parts = list }
		end)(),
	},
	{
		id = "Lizzle",
		name = "Lizzle",
		rarity = "Uncommon",
		income = 18,
		look = (function()
			local list, add = newParts()
			local lime, spot, belly = rgb(130, 225, 80), rgb(60, 160, 60), rgb(235, 240, 150)
			add({ name = "Body", shape = "Ball", size = 2.1, pos = { 0, 1.25, 0.3 }, color = lime })
			add({ shape = "Ball", size = 1.6, pos = { 0, 1.05, -0.2 }, color = belly })
			for _, leg in { { -1, -0.3 }, { 1, -0.3 }, { -1, 0.9 }, { 1, 0.9 } } do
				add({
					shape = "Cylinder",
					size = { 1, 0.4, 0.4 },
					pos = { leg[1] * 0.95, 0.65, leg[2] },
					rot = { 0, 0, leg[1] * -35 },
					color = lime,
				})
				add({ shape = "Ball", size = 0.5, pos = { leg[1] * 1.35, 0.25, leg[2] - 0.1 }, color = lime })
			end
			local head = { 0, 1.75, -1.25 }
			add({ name = "Head", shape = "Ball", size = 1.7, pos = head, color = lime })
			for _, side in { -1, 1 } do
				local p = { side * 0.62, 2.35, -1.35 }
				add({ shape = "Ball", size = 0.85, pos = p, color = lime })
				add({
					shape = "Ball",
					size = 0.6,
					pos = { p[1], p[2] + 0.05, p[3] - 0.25 },
					color = rgb(255, 255, 255),
					detail = true,
				})
				add({
					shape = "Ball",
					size = 0.3,
					pos = { p[1], p[2] + 0.05, p[3] - 0.48 },
					color = rgb(20, 20, 25),
					detail = true,
				})
			end
			add({
				shape = "Block",
				size = { 0.16, 0.06, 1.1 },
				pos = { 0, 1.45, -2.45 },
				color = rgb(255, 90, 130),
				detail = true,
			})
			add({ shape = "Ball", size = 0.3, pos = { 0, 1.45, -3.0 }, color = rgb(255, 90, 130), detail = true })
			for _, p in { { -0.45, 2.25, 0.4 }, { 0.5, 2.15, 0.1 }, { 0.1, 2.3, 0.75 } } do
				add({ shape = "Ball", size = 0.4, pos = p, color = spot })
			end
			-- A tail that curls up into a spiral.
			for i = 0, 11 do
				local a = i * 0.55
				local radius = 0.9 - i * 0.06
				add({
					shape = "Ball",
					size = 0.55 - i * 0.03,
					pos = {
						0,
						1.3 + math.sin(a) * radius + i * 0.05,
						1.7 + math.cos(a) * radius * 0.4 + (if i < 3 then i * 0.35 else 0.9),
					},
					color = if i % 3 == 0 then spot else lime,
				})
			end
			return { parts = list }
		end)(),
	},
	{
		id = "Hootsworth",
		name = "Hootsworth",
		rarity = "Rare",
		income = 70,
		look = (function()
			local list, add = newParts()
			local brown, dark, cream = rgb(135, 90, 55), rgb(95, 60, 35), rgb(240, 220, 185)
			local body = { 0, 2.1, 0 }
			add({ name = "Body", shape = "Ball", size = 3.2, pos = body, color = brown })
			add({ shape = "Ball", size = 2.3, pos = { 0, 1.75, -0.6 }, color = cream })
			-- Big round eyes in pale face discs.
			for _, side in { -1, 1 } do
				local p = onBall(body, 1.6, side * 0.55, 0.75, 0)
				add({ shape = "Cylinder", size = { 0.15, 1.45, 1.45 }, pos = p, rot = { 0, 90, 0 }, color = cream })
				add({
					shape = "Ball",
					size = 0.95,
					pos = { p[1], p[2], p[3] - 0.12 },
					color = rgb(255, 255, 255),
					detail = true,
				})
				add({
					shape = "Ball",
					size = 0.65,
					pos = { p[1], p[2], p[3] - 0.3 },
					color = rgb(255, 165, 30),
					detail = true,
				})
				add({
					shape = "Ball",
					size = 0.35,
					pos = { p[1], p[2], p[3] - 0.5 },
					color = rgb(20, 20, 25),
					detail = true,
				})
				pointyEar(add, side * 0.9, 3.75, -0.2, 0.6, 0.7, dark)
				add({
					shape = "Block",
					size = { 0.35, 1.8, 1.5 },
					pos = { side * 1.6, 2.05, 0.15 },
					rot = { 0, 0, side * 10 },
					color = dark,
				})
				for _, toe in { -0.22, 0, 0.22 } do
					add({
						shape = "Ball",
						size = 0.3,
						pos = { side * 0.55 + toe, 0.15, -0.75 },
						color = rgb(255, 165, 30),
					})
				end
			end
			add({
				shape = "Block",
				size = { 0.32, 0.32, 0.32 },
				pos = onBall(body, 1.6, 0, 0.3, 0.12),
				rot = { 0, 0, 45 },
				color = rgb(255, 165, 30),
				detail = true,
			})
			-- A monocle and a top hat: very posh.
			local eye = onBall(body, 1.6, 0.55, 0.75, 0.55)
			add({
				shape = "Cylinder",
				size = { 0.08, 1.05, 1.05 },
				pos = eye,
				rot = { 0, 90, 0 },
				color = rgb(255, 205, 60),
				material = "Foil",
				detail = true,
			})
			add({
				shape = "Block",
				size = { 0.05, 1.1, 0.05 },
				pos = { eye[1] + 0.35, eye[2] - 0.75, eye[3] + 0.1 },
				rot = { 0, 0, 20 },
				color = rgb(255, 205, 60),
				detail = true,
			})
			add({
				shape = "Cylinder",
				size = { 0.12, 2.2, 2.2 },
				pos = { 0, 3.6, 0 },
				rot = { 0, 0, 90 },
				color = rgb(25, 25, 30),
			})
			add({
				shape = "Cylinder",
				size = { 1.3, 1.4, 1.4 },
				pos = { 0, 4.3, 0 },
				rot = { 0, 0, 90 },
				color = rgb(25, 25, 30),
			})
			add({
				shape = "Cylinder",
				size = { 0.25, 1.45, 1.45 },
				pos = { 0, 3.85, 0 },
				rot = { 0, 0, 90 },
				color = rgb(200, 30, 40),
			})
			return { parts = list }
		end)(),
	},
	{
		id = "Chompers",
		name = "Chompers",
		rarity = "Legendary",
		income = 260,
		look = (function()
			local list, add = newParts()
			local green, belly, dark = rgb(70, 145, 65), rgb(185, 210, 130), rgb(45, 100, 45)
			add({ name = "Body", shape = "Block", size = { 2.6, 1.5, 4.6 }, pos = { 0, 1.35, 0.4 }, color = green })
			add({ shape = "Block", size = { 2.4, 0.3, 4.4 }, pos = { 0, 0.62, 0.4 }, color = belly })
			for _, leg in { { -1, -1.2 }, { 1, -1.2 }, { -1, 1.9 }, { 1, 1.9 } } do
				add({
					shape = "Cylinder",
					size = { 0.9, 0.7, 0.7 },
					pos = { leg[1] * 1.35, 0.45, leg[2] },
					rot = { 0, 0, 90 },
					color = green,
				})
				add({
					shape = "Block",
					size = { 0.8, 0.3, 1 },
					pos = { leg[1] * 1.45, 0.15, leg[2] - 0.2 },
					color = green,
				})
			end
			-- Big jaws, slightly open, full of teeth.
			add({ shape = "Block", size = { 2.2, 0.9, 2.8 }, pos = { 0, 1.6, -3 }, color = green })
			add({ shape = "Block", size = { 2, 0.5, 2.6 }, pos = { 0, 0.82, -2.9 }, color = green })
			add({
				shape = "Block",
				size = { 1.9, 0.18, 2.4 },
				pos = { 0, 1.15, -2.95 },
				color = rgb(230, 90, 110),
				detail = true,
			})
			for i = 0, 5 do
				for _, side in { -1, 1 } do
					add({
						shape = "Block",
						size = { 0.18, 0.3, 0.18 },
						pos = { side * 0.92, 1.05, -1.9 - i * 0.45 },
						color = rgb(255, 255, 250),
						detail = true,
					})
				end
			end
			for _, side in { -1, 1 } do
				add({ shape = "Ball", size = 0.85, pos = { side * 0.6, 2.15, -2.1 }, color = green })
				add({ shape = "Ball", size = 0.28, pos = { side * 0.35, 2.0, -4.25 }, color = dark, detail = true })
			end
			-- Cool sunglasses.
			add({
				shape = "Block",
				size = { 2.0, 0.42, 0.15 },
				pos = { 0, 2.3, -2.55 },
				color = rgb(20, 20, 25),
				detail = true,
			})
			add({
				shape = "Block",
				size = { 1.8, 0.1, 0.16 },
				pos = { 0, 2.45, -2.6 },
				color = rgb(90, 90, 100),
				detail = true,
			})
			-- Ridges down the back, and a long tail.
			for z = -1.4, 2.4, 0.6 do
				for _, side in { -1, 1 } do
					add({
						shape = "Block",
						size = { 0.35, 0.35, 0.35 },
						pos = { side * 0.5, 2.15, z },
						rot = { 45, 0, 0 },
						color = dark,
					})
				end
			end
			add({ shape = "Block", size = { 1.8, 1.1, 1.7 }, pos = { 0, 1.15, 3.4 }, color = green })
			add({ shape = "Block", size = { 1.3, 0.8, 1.7 }, pos = { 0, 1.0, 4.95 }, color = green })
			add({ shape = "Block", size = { 0.8, 0.5, 1.7 }, pos = { 0, 0.85, 6.45 }, color = green })
			return { parts = list }
		end)(),
	},
	{
		id = "Stompy",
		name = "Stompy",
		rarity = "Mystic",
		income = 1000,
		look = (function()
			local list, add = newParts()
			local grey, dark, ivory = rgb(150, 150, 165), rgb(115, 115, 130), rgb(240, 232, 205)
			add({ name = "Body", shape = "Ball", size = 3.8, pos = { 0, 2.65, 0.3 }, color = grey })
			add({ shape = "Ball", size = 3.3, pos = { 0, 2.5, 1.6 }, color = grey })
			legs(add, { { -1.1, -0.6 }, { 1.1, -0.6 }, { -1.1, 2 }, { 1.1, 2 } }, 1.5, 1.2, grey)
			for _, leg in { { -1.1, -0.6 }, { 1.1, -0.6 } } do
				for _, toe in { -0.3, 0, 0.3 } do
					add({
						shape = "Ball",
						size = 0.3,
						pos = { leg[1] + toe, 0.15, leg[2] - 0.55 },
						color = ivory,
						detail = true,
					})
				end
			end
			add({ name = "Head", shape = "Block", size = { 2.3, 2.1, 2.4 }, pos = { 0, 2.8, -2.2 }, color = grey })
			add({ shape = "Block", size = { 1.9, 1.4, 1.3 }, pos = { 0, 2.3, -3.6 }, color = grey })
			for _, side in { -1, 1 } do
				add({
					shape = "Ball",
					size = 0.55,
					pos = { side * 0.95, 3.25, -3.3 },
					color = rgb(255, 255, 255),
					detail = true,
				})
				add({
					shape = "Ball",
					size = 0.28,
					pos = { side * 0.95, 3.25, -3.55 },
					color = rgb(20, 20, 25),
					detail = true,
				})
				add({
					shape = "Ball",
					size = 0.25,
					pos = { side * 0.4, 2.2, -4.25 },
					color = rgb(60, 60, 70),
					detail = true,
				})
				pointyEar(add, side * 0.85, 4.15, -1.4, 0.5, 0.7, dark)
			end
			-- A big horn (a cone of thin rings) with a glowing tip, and a little one behind it.
			for k = 0, 7 do
				local width = 1 - k * 0.11
				add({
					shape = "Cylinder",
					size = { 0.22, width, width },
					pos = { 0, 3.05 + k * 0.2, -3.75 + k * 0.04 },
					rot = { 0, 0, 90 },
					color = ivory,
				})
			end
			local tip = add({
				shape = "Ball",
				size = 0.36,
				pos = { 0, 4.7, -3.43 },
				color = rgb(190, 110, 255),
				material = "Neon",
				detail = true,
			})
			add({
				shape = "Cylinder",
				size = { 0.45, 0.55, 0.55 },
				pos = { 0, 3.95, -2.9 },
				rot = { 0, 0, 90 },
				color = ivory,
			})
			add({ shape = "Ball", size = 0.35, pos = { 0, 4.25, -2.9 }, color = ivory })
			add({
				shape = "Cylinder",
				size = { 0.9, 0.2, 0.2 },
				pos = { 0, 2.9, 3.25 },
				rot = { 0, -90, -30 },
				color = dark,
			})
			return { parts = list, effects = { { type = "Glow", part = tip, color = rgb(190, 110, 255) } } }
		end)(),
	},

	-- The Human line
	{
		id = "Chuckles",
		name = "Chuckles",
		rarity = "Common",
		income = 4,
		look = human({
			skin = rgb(255, 225, 200),
			shirt = rgb(255, 215, 60),
			pants = rgb(60, 110, 230),
			shoes = rgb(230, 40, 40),
			shoeSize = { 0.8, 0.45, 1.7 },
			head = 2.2,
			noMouth = true,
			extra = function(h)
				-- Big red nose and a huge grin.
				h.add({
					shape = "Ball",
					size = 0.7,
					pos = { 0, h.headY - 0.1, h.face(0, -0.1, 0.12) },
					color = rgb(235, 30, 40),
				})
				h.add({
					shape = "Block",
					size = { 1.15, 0.22, 0.12 },
					pos = { 0, h.headY - 0.5, h.face(0, -0.5, -0.03) },
					color = rgb(200, 30, 50),
					detail = true,
				})
				h.add({
					shape = "Block",
					size = { 0.8, 0.1, 0.12 },
					pos = { 0, h.headY - 0.44, h.face(0, -0.44, 0.01) },
					color = rgb(255, 255, 255),
					detail = true,
				})
				-- Rainbow afro.
				local rainbow = {
					rgb(255, 60, 60),
					rgb(255, 150, 40),
					rgb(255, 230, 60),
					rgb(70, 210, 90),
					rgb(60, 150, 255),
					rgb(170, 90, 255),
				}
				for i, color in rainbow do
					local a = (i - 0.5) / #rainbow * math.pi * 2
					h.add({
						shape = "Ball",
						size = 1.15,
						pos = { math.cos(a) * 0.95, h.headY + 0.95, math.sin(a) * 0.8 + 0.45 },
						color = color,
					})
				end
				h.add({ shape = "Ball", size = 1.3, pos = { 0, h.headY + 1.3, 0.4 }, color = rgb(255, 90, 180) })
				-- Polka dots, blue suspenders and a flower on the chest.
				for _, dot in { { -0.55, 2.0 }, { 0.5, 2.75 }, { -0.2, 2.9 }, { 0.6, 1.95 } } do
					h.add({
						shape = "Ball",
						size = 0.32,
						pos = { dot[1], dot[2], -h.torsoD / 2 - 0.02 },
						color = rgb(255, 80, 150),
						detail = true,
					})
				end
				for _, x in { -0.55, 0.55 } do
					h.add({
						shape = "Block",
						size = { 0.22, 1.72, h.torsoD + 0.06 },
						pos = { x, h.torsoY, 0 },
						color = rgb(60, 110, 230),
					})
				end
				h.add({
					shape = "Ball",
					size = 0.55,
					pos = { -0.15, 2.4, -h.torsoD / 2 - 0.12 },
					color = rgb(255, 120, 200),
				})
				h.add({
					shape = "Ball",
					size = 0.25,
					pos = { -0.15, 2.4, -h.torsoD / 2 - 0.36 },
					color = rgb(255, 230, 60),
					detail = true,
				})
			end,
		}),
	},
	{
		id = "Nerdle",
		name = "Nerdle",
		rarity = "Uncommon",
		income = 20,
		look = human({
			skin = rgb(250, 215, 185),
			shirt = rgb(90, 150, 90),
			sleeves = rgb(245, 245, 240),
			pants = rgb(140, 110, 80),
			shoes = rgb(70, 50, 40),
			torsoWidth = 1.6,
			armSize = 0.42,
			head = 2.25,
			extra = function(h)
				-- Neat brown hair with a side part: a dome over the top and back of the head.
				h.add({ shape = "Ball", size = h.head + 0.2, pos = { 0, h.headY + 0.3, 0.22 }, color = rgb(95, 60, 35) })
				h.add({
					shape = "Block",
					size = { 1.3, 0.3, 0.5 },
					pos = { 0.3, h.headY + 0.78, h.face(0.3, 0.78, -0.3) },
					rot = { 0, 0, -8 },
					color = rgb(95, 60, 35),
				})
				-- Big round glasses.
				local glassZ = h.face(h.eyeX, h.eyeY, 0.12)
				for _, side in { -1, 1 } do
					h.add({
						shape = "Cylinder",
						size = { 0.08, 0.85, 0.85 },
						pos = { side * h.eyeX, h.headY + h.eyeY, glassZ },
						rot = { 0, 90, 0 },
						color = rgb(20, 20, 25),
						detail = true,
					})
					h.add({
						shape = "Cylinder",
						size = { 0.1, 0.7, 0.7 },
						pos = { side * h.eyeX, h.headY + h.eyeY, glassZ - 0.02 },
						rot = { 0, 90, 0 },
						color = rgb(200, 235, 255),
						transparency = 0.6,
						detail = true,
					})
				end
				h.add({
					shape = "Block",
					size = { 0.3, 0.08, 0.08 },
					pos = { 0, h.headY + h.eyeY, glassZ },
					color = rgb(20, 20, 25),
					detail = true,
				})
				-- Buck teeth.
				for _, x in { -0.08, 0.08 } do
					h.add({
						shape = "Block",
						size = { 0.14, 0.24, 0.06 },
						pos = { x, h.headY - h.head * 0.2 - 0.14, h.face(x, h.head * 0.2 + 0.14, -0.02) },
						color = rgb(255, 255, 255),
						detail = true,
					})
				end
				-- Red bow tie, pocket protector with pens, and a book under the arm.
				for _, side in { -1, 1 } do
					h.add({
						shape = "Block",
						size = { 0.38, 0.3, 0.1 },
						pos = { side * 0.2, h.torsoTop - 0.15, -h.torsoD / 2 - 0.06 },
						rot = { 0, 0, side * 20 },
						color = rgb(220, 40, 50),
						detail = true,
					})
				end
				h.add({
					shape = "Ball",
					size = 0.2,
					pos = { 0, h.torsoTop - 0.15, -h.torsoD / 2 - 0.1 },
					color = rgb(180, 25, 35),
					detail = true,
				})
				h.add({
					shape = "Block",
					size = { 0.45, 0.5, 0.06 },
					pos = { 0.4, 2.65, -h.torsoD / 2 - 0.02 },
					color = rgb(245, 245, 245),
					detail = true,
				})
				for i, color in { rgb(30, 80, 220), rgb(220, 40, 40), rgb(30, 30, 30) } do
					h.add({
						shape = "Cylinder",
						size = { 0.5, 0.07, 0.07 },
						pos = { 0.25 + i * 0.1, 2.85, -h.torsoD / 2 - 0.06 },
						rot = { 0, 0, 90 },
						color = color,
						detail = true,
					})
				end
				h.add({
					shape = "Block",
					size = { 0.3, 1.1, 0.85 },
					pos = { -(h.shoulderX + 0.3), 2.1, -0.1 },
					color = rgb(40, 70, 170),
				})
			end,
		}),
	},
	{
		id = "Flexo",
		name = "Flexo",
		rarity = "Rare",
		income = 80,
		look = human({
			skin = rgb(225, 165, 115),
			shirt = rgb(220, 40, 40),
			pants = rgb(40, 40, 55),
			shoes = rgb(30, 30, 30),
			torsoWidth = 2.7,
			torsoDepth = 1.4,
			armSize = 0.8,
			head = 1.85,
			extra = function(h)
				-- Bulging shoulders and biceps.
				for _, side in { -1, 1 } do
					h.add({
						shape = "Ball",
						size = 1.25,
						pos = { side * (h.shoulderX + 0.05), 3.05, 0 },
						color = h.skin,
					})
					h.add({
						shape = "Ball",
						size = 1.0,
						pos = { side * (h.shoulderX + 0.12), 2.45, -0.12 },
						color = h.skin,
					})
				end
				-- Flat-top hair, a thick mustache, angry brows.
				h.add({
					shape = "Block",
					size = { 1.55, 0.55, 1.55 },
					pos = { 0, h.headY + 0.78, 0 },
					color = rgb(40, 30, 25),
				})
				h.add({
					shape = "Block",
					size = { 0.95, 0.2, 0.18 },
					pos = { 0, h.headY - 0.22, h.face(0, -0.22, -0.02) },
					color = rgb(40, 30, 25),
					detail = true,
				})
				for _, side in { -1, 1 } do
					h.add({
						shape = "Block",
						size = { 0.45, 0.12, 0.12 },
						pos = { side * h.eyeX, h.headY + h.eyeY + 0.38, h.face(h.eyeX, h.eyeY + 0.38, -0.04) },
						rot = { 0, 0, side * 15 },
						color = rgb(40, 30, 25),
						detail = true,
					})
				end
				-- Black belt with a gold buckle.
				h.add({
					shape = "Block",
					size = { h.torsoW + 0.06, 0.3, h.torsoD + 0.06 },
					pos = { 0, 1.65, 0 },
					color = rgb(25, 25, 25),
				})
				h.add({
					shape = "Block",
					size = { 0.55, 0.4, 0.1 },
					pos = { 0, 1.65, -h.torsoD / 2 - 0.06 },
					color = rgb(255, 200, 50),
					material = "Foil",
				})
				-- A dumbbell in his right hand.
				local hand = h.shoulderX + 0.08
				h.add({
					shape = "Cylinder",
					size = { 1.7, 0.2, 0.2 },
					pos = { hand, 1.72, 0 },
					rot = { 0, 90, 0 },
					color = rgb(120, 120, 130),
					material = "Metal",
				})
				for _, z in { -0.75, 0.75 } do
					h.add({
						shape = "Cylinder",
						size = { 0.35, 1.0, 1.0 },
						pos = { hand, 1.72, z },
						rot = { 0, 90, 0 },
						color = rgb(35, 35, 40),
						material = "Metal",
					})
				end
			end,
		}),
	},
	{
		id = "Glamora",
		name = "Glamora",
		rarity = "Legendary",
		income = 300,
		look = human({
			skin = rgb(255, 220, 200),
			shirt = rgb(255, 120, 190),
			pants = rgb(255, 210, 190),
			shoes = rgb(255, 60, 150),
			torsoWidth = 1.7,
			armSize = 0.42,
			head = 2.2,
			noMouth = true,
			extra = function(h)
				-- A flared pink skirt.
				h.add({
					shape = "Cylinder",
					size = { 0.5, 2.3, 2.3 },
					pos = { 0, 1.45, 0 },
					rot = { 0, 0, 90 },
					color = rgb(255, 120, 190),
				})
				h.add({
					shape = "Cylinder",
					size = { 0.45, 2.7, 2.7 },
					pos = { 0, 1.05, 0 },
					rot = { 0, 0, 90 },
					color = rgb(255, 150, 205),
				})
				-- Long golden hair: a big back, bangs and locks over the shoulders.
				local gold = rgb(255, 215, 100)
				h.add({ shape = "Ball", size = h.head + 0.3, pos = { 0, h.headY + 0.15, 0.25 }, color = gold })
				h.add({ shape = "Block", size = { 2.1, 2.2, 0.8 }, pos = { 0, h.headY - 1.0, 0.75 }, color = gold })
				for _, side in { -1, 1 } do
					h.add({
						shape = "Block",
						size = { 0.5, 1.9, 0.6 },
						pos = { side * 1.0, h.headY - 0.6, -0.25 },
						color = gold,
					})
				end
				h.add({
					shape = "Block",
					size = { 1.6, 0.45, 0.5 },
					pos = { 0, h.headY + 0.75, h.face(0, 0.75, -0.25) },
					color = gold,
				})
				-- Eyeliner with a flick at each outer corner, rosy cheeks and pink lips.
				for _, side in { -1, 1 } do
					h.add({
						shape = "Block",
						size = { 0.5, 0.07, 0.07 },
						pos = { side * h.eyeX, h.headY + h.eyeY + 0.26, h.face(h.eyeX, h.eyeY + 0.26, 0.1) },
						color = rgb(30, 20, 30),
						detail = true,
					})
					h.add({
						shape = "Block",
						size = { 0.22, 0.06, 0.06 },
						pos = {
							side * (h.eyeX + 0.3),
							h.headY + h.eyeY + 0.3,
							h.face(h.eyeX + 0.3, h.eyeY + 0.3, 0.08),
						},
						rot = { 0, 0, side * 35 },
						color = rgb(30, 20, 30),
						detail = true,
					})
					h.add({
						shape = "Ball",
						size = 0.38,
						pos = { side * (h.eyeX + 0.25), h.headY - 0.25, h.face(h.eyeX + 0.25, -0.25, -0.08) },
						color = rgb(255, 150, 170),
						detail = true,
					})
				end
				h.add({
					shape = "Ball",
					size = 0.4,
					pos = { 0, h.headY - h.head * 0.2, h.face(0, h.head * 0.2, -0.1) },
					color = rgb(235, 40, 110),
					detail = true,
				})
				-- A pearl necklace and a sparkling tiara.
				for i = -3, 3 do
					local a = i / 3 * 0.9
					h.add({
						shape = "Ball",
						size = 0.22,
						pos = { math.sin(a) * 0.55, h.torsoTop + 0.05 - math.cos(a) * 0.1, -0.45 - math.cos(a) * 0.1 },
						color = rgb(250, 248, 240),
						detail = true,
					})
				end
				h.add({
					shape = "Block",
					size = { 1.5, 0.22, 0.3 },
					pos = { 0, h.headY + 1.0, -0.35 },
					color = rgb(255, 205, 60),
					material = "Foil",
				})
				local gem = h.add({
					shape = "Ball",
					size = 0.45,
					pos = { 0, h.headY + 1.25, -0.42 },
					color = rgb(255, 90, 200),
					material = "Neon",
					detail = true,
				})
				table.insert(h.effects, { type = "Sparkles", part = gem, color = rgb(255, 220, 255) })
			end,
		}),
	},
}

local base = {}
for i, species in Freeks.list do
	species.order = i
	base[species.id] = species
end

-- Freeks.byId[id] also answers for hybrid ids ("Nerdle+Oinkle"), built on first use.
local Hybrids = require(script.Parent.Hybrids)
local hybridCache = {}
Freeks.byId = setmetatable(table.clone(base), {
	__index = function(_, id)
		if type(id) ~= "string" or not Hybrids.isHybrid(id) then
			return nil
		end
		if hybridCache[id] == nil then
			hybridCache[id] = Hybrids.info(id, function(baseId)
				return base[baseId]
			end) or false
		end
		return hybridCache[id] or nil
	end,
})

return Freeks
