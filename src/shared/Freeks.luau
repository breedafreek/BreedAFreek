-- Every Freek species in the game. These are PLACEHOLDERS until the real list arrives.
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
	{
		id = "Blobby",
		name = "Blobby",
		rarity = "Common",
		income = 1,
		price = 50,
		look = { color = Color3.fromRGB(120, 200, 255), shape = "Ball", size = 3, eyes = 2, antennae = 0 },
	},
	{
		id = "Snorp",
		name = "Snorp",
		rarity = "Common",
		income = 2,
		price = 120,
		look = { color = Color3.fromRGB(255, 140, 180), shape = "Ball", size = 3.2, eyes = 1, antennae = 1 },
	},
	{
		id = "Wigglet",
		name = "Wigglet",
		rarity = "Common",
		income = 3,
		price = 250,
		look = { color = Color3.fromRGB(140, 230, 110), shape = "Block", size = 2.8, eyes = 2, antennae = 2 },
	},
	{
		id = "Grumbo",
		name = "Grumbo",
		rarity = "Common",
		income = 5,
		price = 500,
		look = { color = Color3.fromRGB(170, 120, 80), shape = "Block", size = 3.4, eyes = 3, antennae = 0 },
	},

	-- Bred only
	{
		id = "Snoblob",
		name = "Snoblob",
		rarity = "Uncommon",
		income = 12,
		look = { color = Color3.fromRGB(190, 150, 255), shape = "Ball", size = 3.6, eyes = 2, antennae = 1 },
	},
	{
		id = "Wigglump",
		name = "Wigglump",
		rarity = "Uncommon",
		income = 18,
		look = { color = Color3.fromRGB(230, 220, 90), shape = "Block", size = 3.6, eyes = 3, antennae = 2 },
	},
	{
		id = "Blobwig",
		name = "Blobwig",
		rarity = "Uncommon",
		income = 15,
		look = { color = Color3.fromRGB(90, 220, 200), shape = "Ball", size = 3.4, eyes = 3, antennae = 2 },
	},
	{
		id = "Grumsnorp",
		name = "Grumsnorp",
		rarity = "Uncommon",
		income = 22,
		look = { color = Color3.fromRGB(255, 120, 70), shape = "Block", size = 3.8, eyes = 1, antennae = 1 },
	},

	{
		id = "Chonkler",
		name = "Chonkler",
		rarity = "Rare",
		income = 60,
		look = { color = Color3.fromRGB(255, 90, 90), shape = "Ball", size = 4.6, eyes = 2, antennae = 0 },
	},
	{
		id = "Zorpdorp",
		name = "Zorpdorp",
		rarity = "Rare",
		income = 75,
		look = { color = Color3.fromRGB(60, 120, 255), shape = "Block", size = 4.2, eyes = 3, antennae = 3 },
	},

	{
		id = "EyeballEarl",
		name = "Eyeball Earl",
		rarity = "Legendary",
		income = 250,
		look = { color = Color3.fromRGB(245, 245, 245), shape = "Ball", size = 5, eyes = 1, antennae = 2 },
	},

	{
		id = "KingGoob",
		name = "King Goob",
		rarity = "Mystic",
		income = 1000,
		look = { color = Color3.fromRGB(120, 255, 120), shape = "Ball", size = 6, eyes = 2, antennae = 3 },
	},

	{
		id = "CosmicSnorp",
		name = "Cosmic Snorp",
		rarity = "Ultra",
		income = 4000,
		look = { color = Color3.fromRGB(40, 20, 90), shape = "Ball", size = 6.5, eyes = 3, antennae = 1 },
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

	-- Seasonal
	{
		id = "PumpkinBlob",
		name = "Pumpkin Blob",
		rarity = "Rare",
		season = "Halloween",
		income = 90,
		look = { color = Color3.fromRGB(255, 130, 20), shape = "Ball", size = 4.2, eyes = 2, antennae = 1 },
	},

	{
		id = "TheFreek",
		name = "The Freek",
		rarity = "Secret",
		income = 15000,
		look = { color = Color3.fromRGB(15, 15, 15), shape = "Block", size = 7, eyes = 3, antennae = 3 },
	},
}

local base = {}
for i, species in Freeks.list do
	species.order = i
	base[species.id] = species
end

-- Freeks.byId[id] also answers for hybrid ids ("Blobby+Oinkle"), built on first use.
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
