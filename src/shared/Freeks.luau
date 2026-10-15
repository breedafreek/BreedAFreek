-- Every Freek species in the game.
--
-- id       unique key saved in player data; never rename one after release
-- income   money per second while in the yard
-- price    set only for starter Freeks: always allowed on the conveyor belt, at this price.
--          Other species appear on the belt once discovered, priced from their income.
-- season   optional Seasonal tag (a key in Seasons.luau): only obtainable during that season
-- walk     how it moves around the town square: waddle, trot, prowl, slither, flap, stomp,
--          bounce, strut, catwalk, shamble or float (see the client)
-- exclusive only from Monster Crates (never from cannons, the wheel or anywhere else)
-- look     how the model is built: either a placeholder (shape "Ball" or "Block", size in
--          studs, eyes 1-3, antennae 0-3) or a part list (see FreekModel), e.g. from human()
--
-- Fusing two different Freeks makes a hybrid (see Hybrids.luau); the only hand-made results
-- are the Ultra pairs that make Secrets, in ServerScriptService (Recipes).

local Accessories = require(script.Parent.Accessories)

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

-- Straight legs standing on the ground, centred at each (x, z). Given front-left,
-- front-right, back-left, back-right, they walk in diagonal pairs.
local DIAGONAL = { 0, 0.5, 0.5, 0 }
local function legs(add, spots, height: number, width: number, color: Color3, paw: Color3?)
	for i, spot in spots do
		local swing = { hinge = { spot[1], height, spot[2] }, phase = DIAGONAL[i] or 0 }
		add({
			shape = "Cylinder",
			size = { height, width, width },
			pos = { spot[1], height / 2, spot[2] },
			rot = { 0, 0, 90 },
			color = color,
			swing = swing,
		})
		if paw then
			add({
				shape = "Ball",
				size = width + 0.15,
				pos = { spot[1], (width + 0.15) / 2, spot[2] - 0.08 },
				color = paw,
				swing = swing,
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
			rig = "ear",
			side = if x < 0 then -1 else 1,
			pivot = { x, y - height / 2, z },
		})
	end
end

-- The face kit: big glossy eyes, blush and a curved smile, in the style of today's popular
-- Roblox pets. Every helper takes a point on a ball face: the ball's centre c, radius r, and
-- an offset (x, y) across the face. FreekModel adds sparkle highlights to the pupils.

-- One big cute eye on a ball: a tall white, a coloured iris and a black pupil (FreekModel
-- gives the pupil its sparkles).
local function oneEye(add, c, r: number, x: number, y: number, size: number, iris: Color3?)
	local p = onBall(c, r, x, y, -size * 0.18)
	add({
		shape = "Ellipsoid",
		size = { size * 0.9, size * 1.08, size * 0.55 },
		pos = p,
		color = rgb(255, 255, 255),
		detail = true,
	})
	add({
		shape = "Ellipsoid",
		size = { size * 0.66, size * 0.8, size * 0.3 },
		pos = { p[1], p[2] - size * 0.06, p[3] - size * 0.2 },
		color = iris or rgb(95, 60, 35),
		detail = true,
	})
	add({
		shape = "Ball",
		size = size * 0.38,
		pos = { p[1], p[2] - size * 0.06, p[3] - size * 0.3 },
		color = rgb(15, 12, 20),
		detail = true,
	})
end

-- A pair of big cute eyes.
local function cuteEyes(add, c, r: number, spread: number, height: number, size: number, iris: Color3?)
	for _, side in { -1, 1 } do
		oneEye(add, c, r, side * spread, height, size, iris)
	end
end

-- Little hooves at the bottom of legs made by legs() (same spots and height).
local function hooves(add, spots, height: number, width: number, color: Color3)
	for i, spot in spots do
		add({
			shape = "Cylinder",
			size = { 0.24, width, width },
			pos = { spot[1], 0.12, spot[2] },
			rot = { 0, 0, 90 },
			color = color,
			detail = true,
			swing = { hinge = { spot[1], height, spot[2] }, phase = DIAGONAL[i] or 0 },
		})
	end
end

-- Soft pink cheeks.
local function blush(add, c, r: number, spread: number, height: number, size: number, color: Color3?)
	for _, side in { -1, 1 } do
		add({
			shape = "Ellipsoid",
			size = { size, size * 0.55, size * 0.25 },
			pos = onBall(c, r, side * spread, height, -size * 0.05),
			color = color or rgb(255, 135, 165),
			transparency = 0.25,
			detail = true,
		})
	end
end

-- A curved smile: little beads along a U shape.
local function smile(add, c, r: number, height: number, width: number, color: Color3?, thickness: number?)
	local t = thickness or 0.12
	local beads = math.max(13, math.ceil(width / t * 2.2))
	for k = 0, beads - 1 do
		local f = k / (beads - 1) * 2 - 1
		local x = f * width / 2
		local y = height - (1 - f * f) * width * 0.22
		add({
			shape = "Ball",
			size = t,
			pos = onBall(c, r, x, y, -t * 0.2),
			color = color or rgb(90, 35, 45),
			detail = true,
			shine = false,
		})
	end
end

-- An open happy mouth: a dark rounded opening with a pink tongue.
local function openMouth(add, c, r: number, height: number, width: number)
	local p = onBall(c, r, 0, height, -0.02)
	add({
		shape = "Ellipsoid",
		size = { width, width * 0.6, 0.18 },
		pos = p,
		color = rgb(90, 25, 40),
		detail = true,
	})
	add({
		shape = "Ellipsoid",
		size = { width * 0.6, width * 0.28, 0.12 },
		pos = { p[1], p[2] - width * 0.14, p[3] - 0.06 },
		color = rgb(255, 120, 150),
		detail = true,
	})
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

	-- A rounded bean of a torso with soft shoulders, and rounded hips.
	add({
		name = "Body",
		shape = "Ellipsoid",
		size = { torsoW, 2.0, torsoD * 1.15 },
		pos = { 0, torsoY + 0.05, 0 },
		color = o.shirt,
	})
	add({ shape = "Ellipsoid", size = { torsoW * 0.96, 0.95, torsoD * 1.05 }, pos = { 0, 1.5, 0 }, color = o.pants })
	-- Legs swing in turn, and each arm swings with the opposite leg.
	for i, x in { -0.45, 0.45 } do
		local swing = { hinge = { x, 1.35, 0 }, phase = (i - 1) * 0.5 }
		add({
			shape = "Cylinder",
			size = { 1.2, 0.6, 0.6 },
			pos = { x, 0.75, 0 },
			rot = { 0, 0, 90 },
			color = o.pants,
			swing = swing,
		})
		-- Chunky rounded sneakers with a pale sole.
		local shoe = o.shoeSize or { 0.7, 0.35, 1.05 }
		add({
			shape = "Ellipsoid",
			size = { shoe[1] + 0.12, shoe[2] + 0.2, shoe[3] + 0.1 },
			pos = { x, 0.24, -0.15 },
			color = o.shoes,
			detail = true,
			swing = swing,
		})
		add({
			shape = "Ellipsoid",
			size = { shoe[1] + 0.16, 0.16, shoe[3] + 0.16 },
			pos = { x, 0.08, -0.15 },
			color = o.sole or rgb(245, 245, 240),
			detail = true,
			swing = swing,
		})
	end
	local shoulderX = torsoW / 2 + armD / 2 - 0.02
	for _, side in { -1, 1 } do
		if o.armsForward then
			-- Arms stuck straight out in front (zombies, mummies), barely swinging.
			local swing = { hinge = { side * shoulderX, 2.95, 0 }, phase = if side < 0 then 0.5 else 0, amount = 0.25 }
			add({
				shape = "Cylinder",
				size = { 1.5, armD, armD },
				pos = { side * shoulderX, 2.95, -0.7 },
				rot = { 0, 90, 0 },
				color = o.sleeves or o.skin,
				swing = swing,
			})
			add({
				shape = "Ball",
				size = armD + 0.12,
				pos = { side * shoulderX, 2.95, -1.5 },
				color = o.skin,
				swing = swing,
			})
		else
			local swing = { hinge = { side * shoulderX, 3.2, 0 }, phase = if side < 0 then 0.5 else 0, amount = 0.8 }
			add({
				shape = "Cylinder",
				size = { 1.45, armD, armD },
				pos = { side * shoulderX, 2.5, 0 },
				rot = { 0, 0, 90 + side * 6 },
				color = o.sleeves or o.skin,
				swing = swing,
				rig = "arm",
				side = side,
			})
			add({
				shape = "Ball",
				size = armD + 0.12,
				pos = { side * (shoulderX + 0.08), 1.72, 0 },
				color = o.skin,
				swing = swing,
				rig = "arm",
				side = side,
			})
		end
	end
	add({
		shape = "Cylinder",
		size = { 0.35, 0.55, 0.55 },
		pos = { 0, torsoTop + 0.1, 0 },
		rot = { 0, 0, 90 },
		color = o.skin,
	})
	add({ name = "Head", shape = "Ball", size = head, pos = { 0, headY, 0 }, color = o.skin })
	local headC = { 0, headY, 0 }
	local eyeX, eyeY = head * 0.19, head * 0.04
	-- Little ears on the sides of the head.
	for _, side in { -1, 1 } do
		add({
			shape = "Ellipsoid",
			size = { 0.28, 0.5, 0.36 },
			pos = { side * r * 0.98, headY - 0.05, 0.05 },
			color = o.skin,
		})
	end
	cuteEyes(add, headC, r, eyeX, eyeY, head * 0.3, o.eyeColor)
	if not o.noBrows then
		for _, side in { -1, 1 } do
			add({
				shape = "Ellipsoid",
				size = { head * 0.2, 0.09, 0.08 },
				pos = onBall(headC, r, side * eyeX, eyeY + head * 0.22, -0.02),
				rot = { 0, 0, side * (o.browTilt or -8) },
				color = o.brows or rgb(70, 45, 30),
				detail = true,
			})
		end
	end
	if not o.noBlush then
		blush(add, headC, r, eyeX + head * 0.1, -head * 0.1, head * 0.17)
	end
	if not o.noMouth then
		smile(add, headC, r, -head * 0.16, head * 0.24)
	end

	local effects = {}
	local before = #parts
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
	-- Anything the extras put on an arm (biceps, claws, a dumbbell, a book) moves with it.
	if not o.armsForward then
		for i = before + 1, #parts do
			local spec = parts[i]
			local x, y = spec.pos[1], spec.pos[2]
			if not spec.swing and not spec.rig and y < torsoTop and math.abs(x) >= shoulderX - armD * 0.5 then
				local side = if x < 0 then -1 else 1
				spec.swing = { hinge = { side * shoulderX, 3.2, 0 }, phase = if side < 0 then 0.5 else 0, amount = 0.8 }
				spec.rig = "arm"
				spec.side = side
			end
		end
	end
	return { parts = parts, effects = effects }
end

Freeks.list = {
	-- Starter Freeks (shop)
	{
		id = "Oinkle",
		signature = "bow",
		walk = "waddle",
		name = "Oinkle",
		rarity = "Common",
		income = 1,
		price = 50,
		look = (function()
			-- A chubby piglet: round body with a pale belly, a big head with a shiny snout,
			-- floppy ears, little hooves and a curly tail.
			local list, add = newParts()
			local pink, deep, pale = rgb(255, 172, 192), rgb(240, 140, 165), rgb(255, 212, 222)
			add({ name = "Body", shape = "Ellipsoid", size = { 3.3, 2.9, 3.6 }, pos = { 0, 2.0, 0.25 }, color = pink })
			add({ shape = "Ellipsoid", size = { 2.3, 1.9, 0.9 }, pos = { 0, 1.75, -1.3 }, color = pale })
			legs(add, { { -0.8, -0.7 }, { 0.8, -0.7 }, { -0.8, 1.15 }, { 0.8, 1.15 } }, 1.05, 0.72, pink)
			hooves(
				add,
				{ { -0.8, -0.7 }, { 0.8, -0.7 }, { -0.8, 1.15 }, { 0.8, 1.15 } },
				1.05,
				0.78,
				rgb(200, 110, 135)
			)
			local c, r = { 0, 2.95, -1.35 }, 1.25
			add({ name = "Head", shape = "Ball", size = r * 2, pos = c, color = pink })
			-- Snout with nostrils.
			local snout = onBall(c, r, 0, -0.3, -0.18)
			add({ shape = "Ellipsoid", size = { 1.15, 0.85, 0.55 }, pos = snout, color = deep })
			for _, side in { -1, 1 } do
				add({
					shape = "Ellipsoid",
					size = { 0.2, 0.3, 0.1 },
					pos = { snout[1] + side * 0.22, snout[2], snout[3] - 0.28 },
					color = rgb(150, 60, 85),
					detail = true,
				})
			end
			cuteEyes(add, c, r, 0.46, 0.3, 0.62, rgb(70, 40, 35))
			blush(add, c, r, 0.85, -0.18, 0.42)
			smile(add, c, r, -0.72, 0.42)
			-- Its signature pink bow, between the ears.
			Accessories.put(add, "bow", { c[1] - 0.66, c[2], c[3] }, r)
			-- Floppy ears, pink inside.
			for _, side in { -1, 1 } do
				add({
					shape = "Wedge",
					size = { 0.22, 1.0, 0.95 },
					pos = { side * 0.8, 4.1, -1.1 },
					rot = { -25, side * 90, side * 25 },
					color = deep,
					rig = "ear",
					pivot = { side * 0.55, 4.45, -1.1 },
				})
				add({
					shape = "Wedge",
					size = { 0.1, 0.65, 0.6 },
					pos = { side * 0.8, 4.02, -1.24 },
					rot = { -25, side * 90, side * 25 },
					color = rgb(255, 120, 150),
					detail = true,
					rig = "ear",
					pivot = { side * 0.55, 4.45, -1.1 },
				})
			end
			-- Curly tail.
			for k, p in { { 0, 2.3, 1.95 }, { 0.18, 2.48, 2.08 }, { 0.05, 2.68, 2.16 }, { -0.14, 2.55, 2.22 } } do
				add({
					shape = "Ball",
					size = 0.32 - k * 0.02,
					pos = p,
					color = deep,
					swing = { hinge = { 0, 2.3, 1.85 }, axis = "Y", amount = 0.7 },
				})
			end
			return { parts = list }
		end)(),
	},

	-- The Animal line (Oinkle is the pig)
	{
		id = "Woofles",
		signature = "collar",
		walk = "trot",
		name = "Woofles",
		rarity = "Common",
		income = 3,
		look = (function()
			-- A golden puppy: fluffy chest, big head with a cream muzzle and shiny nose,
			-- tongue out, long floppy ears, a red collar with a gold tag and a wagging tail.
			local list, add = newParts()
			local tan, dark, cream = rgb(235, 185, 120), rgb(170, 110, 60), rgb(252, 236, 210)
			add({ name = "Body", shape = "Ellipsoid", size = { 2.6, 2.4, 3.4 }, pos = { 0, 1.95, 0.45 }, color = tan })
			add({ shape = "Ellipsoid", size = { 1.7, 1.7, 0.9 }, pos = { 0, 2.0, -0.95 }, color = cream })
			legs(add, { { -0.7, -0.55 }, { 0.7, -0.55 }, { -0.7, 1.35 }, { 0.7, 1.35 } }, 1.1, 0.62, tan, cream)
			add({ shape = "Ellipsoid", size = { 1.3, 0.35, 1.2 }, pos = { 0.55, 3.1, 0.8 }, color = dark })
			local c, r = { 0, 3.65, -1.0 }, 1.25
			add({ name = "Head", shape = "Ball", size = r * 2, pos = c, color = tan })
			local muzzle = onBall(c, r, 0, -0.4, -0.38)
			add({ shape = "Ellipsoid", size = { 1.45, 1.0, 0.95 }, pos = muzzle, color = cream })
			add({
				shape = "Ball",
				size = 0.45,
				pos = { 0, muzzle[2] + 0.22, muzzle[3] - 0.44 },
				color = rgb(30, 22, 22),
				detail = true,
			})
			openMouth(add, c, r + 0.32, -0.66, 0.5)
			cuteEyes(add, c, r, 0.48, 0.28, 0.6, rgb(90, 55, 30))
			blush(add, c, r, 0.85, -0.15, 0.38)
			for _, side in { -1, 1 } do
				-- Eyebrow dots, and long floppy ears.
				add({
					shape = "Ellipsoid",
					size = { 0.3, 0.16, 0.1 },
					pos = onBall(c, r, side * 0.42, 0.72, -0.02),
					color = dark,
					detail = true,
				})
				add({
					shape = "Ellipsoid",
					size = { 0.4, 1.6, 0.95 },
					pos = { side * 1.22, 3.45, -0.85 },
					rot = { 0, 0, side * 14 },
					color = dark,
					rig = "ear",
					pivot = { side * 1.05, 4.2, -0.85 },
				})
			end
			-- Collar and tag.
			add({
				shape = "Cylinder",
				size = { 0.3, 2.05, 2.05 },
				pos = { 0, 2.75, -0.7 },
				rot = { 0, 0, 90 },
				color = rgb(225, 40, 55),
				onHead = false,
			})
			add({
				shape = "Cylinder",
				size = { 0.1, 0.42, 0.42 },
				pos = { 0, 2.4, -1.72 },
				rot = { 0, 90, 0 },
				color = rgb(255, 205, 60),
				material = "Foil",
				onHead = false,
			})
			-- Wagging tail with a cream tip.
			local wag = { hinge = { 0, 2.5, 1.9 }, axis = "Y", amount = 1.5 }
			add({
				shape = "Cylinder",
				size = { 1.1, 0.34, 0.34 },
				pos = { 0, 2.85, 2.2 },
				rot = { 0, -90, 55 },
				color = tan,
				swing = wag,
			})
			add({ shape = "Ball", size = 0.42, pos = { 0, 3.3, 2.55 }, color = cream, swing = wag })
			return { parts = list }
		end)(),
	},
	{
		id = "Whiskerz",
		signature = "bell",
		walk = "prowl",
		name = "Whiskerz",
		rarity = "Uncommon",
		income = 14,
		look = (function()
			-- An orange tabby: cream chest and muzzle, cheek fluff, green eyes, pink nose
			-- and a :3 mouth, tabby stripes, whiskers and a curling tail.
			local list, add = newParts()
			local orange, stripe, cream = rgb(255, 168, 78), rgb(220, 115, 40), rgb(255, 236, 210)
			add({ name = "Body", shape = "Ellipsoid", size = { 2.4, 2.2, 3.0 }, pos = { 0, 1.75, 0.4 }, color = orange })
			add({ shape = "Ellipsoid", size = { 1.5, 1.5, 0.75 }, pos = { 0, 1.8, -0.85 }, color = cream })
			legs(add, { { -0.6, -0.45 }, { 0.6, -0.45 }, { -0.6, 1.1 }, { 0.6, 1.1 } }, 0.95, 0.52, orange, cream)
			for _, z in { 0.1, 0.7, 1.3 } do
				add({
					shape = "Ellipsoid",
					size = { 1.9, 0.25, 0.32 },
					pos = { 0, 2.82, z },
					rot = { 0, 0, 0 },
					color = stripe,
				})
			end
			local c, r = { 0, 3.4, -0.85 }, 1.25
			add({ name = "Head", shape = "Ball", size = r * 2, pos = c, color = orange })
			for _, side in { -1, 1 } do
				add({
					shape = "Ellipsoid",
					size = { 0.95, 0.65, 0.75 },
					pos = onBall(c, r, side * 0.82, -0.38, -0.25),
					color = orange,
				})
				pointyEar(add, side * 0.72, 4.55, -0.7, 0.9, 1.0, orange)
				pointyEar(add, side * 0.72, 4.48, -0.84, 0.5, 0.6, rgb(255, 160, 185))
			end
			local muzzle = onBall(c, r, 0, -0.42, -0.12)
			add({ shape = "Ellipsoid", size = { 0.95, 0.6, 0.42 }, pos = muzzle, color = cream })
			add({
				shape = "Ellipsoid",
				size = { 0.32, 0.2, 0.14 },
				pos = { 0, muzzle[2] + 0.14, muzzle[3] - 0.2 },
				color = rgb(255, 120, 150),
				detail = true,
			})
			for _, side in { -1, 1 } do
				smile(add, { side * 0.16, c[2], c[3] }, r, -0.58, 0.3, nil, 0.08)
			end
			cuteEyes(add, c, r, 0.46, 0.25, 0.62, rgb(110, 205, 80))
			blush(add, c, r, 0.82, -0.12, 0.36)
			-- Its signature ribbon and bell.
			Accessories.put(add, "bell", { c[1], c[2] - 0.75 * r, c[3] + 0.25 * r }, r)
			for _, x in { -0.25, 0, 0.25 } do
				add({
					shape = "Ellipsoid",
					size = { 0.12, 0.42, 0.08 },
					pos = onBall(c, r, x, 0.8, 0.0),
					rot = { -35, 0, 0 },
					color = stripe,
					detail = true,
				})
			end
			for _, side in { -1, 1 } do
				for i, tilt in { -12, 0, 12 } do
					add({
						shape = "Block",
						size = { 0.95, 0.04, 0.04 },
						pos = { side * 0.95, muzzle[2] + (i - 2) * 0.12, muzzle[3] + 0.1 },
						rot = { 0, 0, side * tilt },
						color = rgb(255, 255, 255),
						detail = true,
					})
				end
			end
			for k, p in
				{
					{ 0, 1.9, 1.75 },
					{ 0, 2.3, 2.1 },
					{ 0, 2.8, 2.3 },
					{ 0, 3.3, 2.3 },
					{ 0, 3.7, 2.1 },
					{ 0, 3.9, 1.8 },
				}
			do
				add({
					shape = "Ball",
					size = 0.48,
					pos = p,
					color = if k % 2 == 0 then stripe else orange,
					swing = { hinge = { 0, 1.9, 1.6 }, axis = "Y", amount = 0.6 },
				})
			end
			return { parts = list }
		end)(),
	},
	{
		id = "Lizzle",
		signature = "flower",
		walk = "slither",
		name = "Lizzle",
		rarity = "Uncommon",
		income = 18,
		look = (function()
			-- A happy lizard: wide flat head with a big smile, bulgy eyes on top, pale belly,
			-- spots down the back, splayed legs with little toes and a curly tail.
			local list, add = newParts()
			local lime, spot, belly = rgb(130, 225, 80), rgb(70, 170, 60), rgb(240, 240, 160)
			add({ name = "Body", shape = "Ellipsoid", size = { 2.4, 1.6, 2.6 }, pos = { 0, 1.2, 0.35 }, color = lime })
			add({ shape = "Ellipsoid", size = { 1.8, 1.1, 0.6 }, pos = { 0, 1.0, -0.8 }, color = belly })
			for i, leg in { { -1, -0.3 }, { 1, -0.3 }, { -1, 0.95 }, { 1, 0.95 } } do
				local swing = { hinge = { leg[1] * 0.6, 0.95, leg[2] }, phase = DIAGONAL[i] }
				add({
					shape = "Cylinder",
					size = { 1, 0.42, 0.42 },
					pos = { leg[1] * 0.95, 0.65, leg[2] },
					rot = { 0, 0, leg[1] * -35 },
					color = lime,
					swing = swing,
				})
				add({
					shape = "Ellipsoid",
					size = { 0.6, 0.3, 0.55 },
					pos = { leg[1] * 1.35, 0.2, leg[2] - 0.1 },
					color = lime,
					swing = swing,
				})
				for _, toe in { -0.2, 0, 0.2 } do
					add({
						shape = "Ball",
						size = 0.2,
						pos = { leg[1] * 1.35 + toe, 0.12, leg[2] - 0.4 },
						color = spot,
						swing = swing,
					})
				end
			end
			local head = { 0, 1.75, -1.15 }
			add({ name = "Head", shape = "Ellipsoid", size = { 2.3, 1.5, 1.9 }, pos = head, color = lime })
			for _, side in { -1, 1 } do
				local bump = { side * 0.62, 2.45, -1.3 }
				add({ shape = "Ball", size = 0.95, pos = bump, color = lime })
				oneEye(add, bump, 0.48, 0, 0.02, 0.66, rgb(230, 170, 30))
			end
			smile(add, head, 0.95, -0.15, 1.05, rgb(60, 110, 40), 0.1)
			blush(add, head, 0.95, 0.75, 0.05, 0.36)
			-- Its signature flower, on top between the eyes.
			Accessories.put(add, "flower", { 0.52, 1.68, -0.685 }, 1.15)
			for _, p in { { -0.5, 1.95, 0.4 }, { 0.55, 1.9, 0.05 }, { 0.1, 2.0, 0.85 }, { -0.2, 1.95, -0.2 } } do
				add({ shape = "Ellipsoid", size = { 0.45, 0.2, 0.45 }, pos = p, color = spot })
			end
			for i = 0, 11 do
				local a = i * 0.55
				local radius = 0.9 - i * 0.06
				add({
					shape = "Ball",
					size = 0.55 - i * 0.03,
					pos = {
						0,
						1.3 + math.sin(a) * radius + i * 0.05,
						1.75 + math.cos(a) * radius * 0.4 + (if i < 3 then i * 0.35 else 0.9),
					},
					color = if i % 3 == 0 then spot else lime,
					swing = { hinge = { 0, 1.3, 1.5 }, axis = "Y", amount = 0.5 },
				})
			end
			return { parts = list }
		end)(),
	},
	{
		id = "Hootsworth",
		signature = "tophat",
		walk = "flap",
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
					swing = { hinge = { side * 1.45, 2.85, 0.15 }, axis = "Z", amount = side * 1.4 },
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
			-- Little feather marks on the cream belly.
			for row, y in { 1.3, 1.75, 2.2 } do
				for k = -1, 1 do
					local x = k * 0.5 + (if row % 2 == 0 then 0.25 else 0)
					if math.abs(x) < 0.8 then
						add({
							shape = "Ellipsoid",
							size = { 0.32, 0.14, 0.08 },
							pos = onBall({ 0, 1.75, -0.6 }, 1.15, x, y - 1.75, -0.02),
							color = rgb(200, 165, 120),
							detail = true,
						})
					end
				end
			end
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
		signature = "shades",
		walk = "slither",
		name = "Chompers",
		rarity = "Legendary",
		income = 260,
		look = (function()
			-- A cool croc: smooth body with ridges down the back, a long snout with the jaws
			-- open and full of teeth, eyes up on bumps behind black shades, a gold chain and a
			-- long tapering tail that swishes.
			local list, add = newParts()
			local green, belly, dark = rgb(85, 165, 70), rgb(215, 225, 150), rgb(55, 120, 50)
			local ivory = rgb(255, 252, 235)
			add({ name = "Body", shape = "Ellipsoid", size = { 2.8, 1.6, 4.8 }, pos = { 0, 1.3, 0.5 }, color = green })
			add({ shape = "Ellipsoid", size = { 2.4, 0.8, 4.4 }, pos = { 0, 0.95, 0.5 }, color = belly })
			for z = -1.4, 2.6, 0.7 do
				for _, side in { -1, 1 } do
					add({
						shape = "Ellipsoid",
						size = { 0.45, 0.4, 0.55 },
						pos = { side * 0.45, 2.02, z },
						color = dark,
					})
				end
			end
			for i, leg in { { -1, -1.1 }, { 1, -1.1 }, { -1, 2.0 }, { 1, 2.0 } } do
				local swing = { hinge = { leg[1] * 1.3, 0.9, leg[2] }, phase = DIAGONAL[i] }
				add({
					shape = "Cylinder",
					size = { 0.8, 0.7, 0.7 },
					pos = { leg[1] * 1.3, 0.45, leg[2] },
					rot = { 0, 0, 90 },
					color = green,
					swing = swing,
				})
				add({
					shape = "Ellipsoid",
					size = { 0.85, 0.35, 1.0 },
					pos = { leg[1] * 1.38, 0.17, leg[2] - 0.2 },
					color = green,
					swing = swing,
				})
				for _, toe in { -0.25, 0, 0.25 } do
					add({
						shape = "Ball",
						size = 0.18,
						pos = { leg[1] * 1.38 + toe, 0.12, leg[2] - 0.7 },
						color = ivory,
						detail = true,
						swing = swing,
					})
				end
			end
			-- Head and the open jaws.
			add({ name = "Head", shape = "Ellipsoid", size = { 2.2, 1.3, 2.0 }, pos = { 0, 1.7, -2.2 }, color = green })
			add({ shape = "Ellipsoid", size = { 1.75, 0.7, 2.7 }, pos = { 0, 1.82, -3.65 }, color = green })
			add({
				shape = "Ellipsoid",
				size = { 1.6, 0.5, 2.4 },
				pos = { 0, 1.02, -3.4 },
				rot = { -8, 0, 0 },
				color = green,
			})
			add({
				shape = "Ellipsoid",
				size = { 1.35, 0.4, 2.2 },
				pos = { 0, 1.36, -3.45 },
				color = rgb(235, 95, 120),
				detail = true,
			})
			for k = 0, 5 do
				local z = -2.75 - k * 0.38
				for _, side in { -1, 1 } do
					add({
						shape = "Wedge",
						size = { 0.14, 0.26, 0.2 },
						pos = { side * 0.62, 1.52, z },
						rot = { 180, 0, 0 },
						color = ivory,
						detail = true,
					})
					add({
						shape = "Wedge",
						size = { 0.14, 0.22, 0.2 },
						pos = { side * 0.56, 1.25, z - 0.18 },
						color = ivory,
						detail = true,
					})
				end
			end
			for _, side in { -1, 1 } do
				add({
					shape = "Ball",
					size = 0.2,
					pos = { side * 0.25, 2.12, -4.75 },
					color = dark,
					detail = true,
					shine = false,
				})
				add({ shape = "Ellipsoid", size = { 0.8, 0.75, 0.8 }, pos = { side * 0.55, 2.3, -2.4 }, color = green })
			end
			-- Black shades with a shine, sitting on the eye bumps.
			for _, side in { -1, 1 } do
				add({
					shape = "Ellipsoid",
					size = { 0.85, 0.6, 0.18 },
					pos = { side * 0.5, 2.35, -2.85 },
					color = rgb(18, 18, 26),
					detail = true,
				})
				add({
					shape = "Ellipsoid",
					size = { 0.18, 0.5, 0.05 },
					pos = { side * 0.5 - 0.15, 2.38, -2.95 },
					rot = { 0, 0, -30 },
					color = rgb(255, 255, 255),
					transparency = 0.35,
					detail = true,
				})
			end
			add({
				shape = "Block",
				size = { 0.3, 0.1, 0.1 },
				pos = { 0, 2.45, -2.85 },
				color = rgb(18, 18, 26),
				detail = true,
			})
			-- Gold chain.
			for k = 0, 13 do
				local a = k / 14 * math.pi * 2
				add({
					shape = "Ball",
					size = 0.26,
					pos = { math.cos(a) * 1.15, 1.3 + math.sin(a) * 0.12, -1.45 + math.sin(a) * 0.55 },
					color = rgb(255, 200, 50),
					material = "Foil",
					detail = true,
				})
			end
			-- Long tapering tail.
			local swish = { hinge = { 0, 1.1, 2.8 }, axis = "Y", amount = 0.5 }
			for k, seg in
				{ { 1.9, 1.1, 1.9, 3.5 }, { 1.4, 0.85, 1.9, 4.9 }, { 0.95, 0.6, 1.8, 6.2 }, { 0.55, 0.4, 1.5, 7.3 } }
			do
				add({
					shape = "Ellipsoid",
					size = { seg[1], seg[2], seg[3] },
					pos = { 0, 1.15 - k * 0.1, seg[4] },
					color = green,
					swing = swish,
				})
				add({
					shape = "Ellipsoid",
					size = { 0.35, 0.3, 0.45 },
					pos = { 0, 1.15 - k * 0.1 + seg[2] / 2, seg[4] },
					color = dark,
					swing = swish,
				})
			end
			return { parts = list }
		end)(),
	},
	{
		id = "Stompy",
		signature = "horn",
		walk = "stomp",
		name = "Stompy",
		rarity = "Mystic",
		income = 1000,
		look = (function()
			-- A chunky armoured rhino: plated shoulders and hips, a big snout, purple eyes and a
			-- tall ivory horn with a glowing tip, toenails and a tufted tail.
			local list, add = newParts()
			local grey, dark, light = rgb(152, 155, 175), rgb(120, 122, 145), rgb(185, 188, 205)
			local ivory = rgb(245, 238, 215)
			add({ name = "Body", shape = "Ellipsoid", size = { 3.6, 3.0, 4.6 }, pos = { 0, 2.6, 0.6 }, color = grey })
			add({ shape = "Ellipsoid", size = { 2.8, 1.6, 3.6 }, pos = { 0, 1.85, 0.6 }, color = light })
			for _, side in { -1, 1 } do
				add({ shape = "Ellipsoid", size = { 1.1, 1.7, 1.5 }, pos = { side * 1.5, 2.85, -0.6 }, color = dark })
				add({ shape = "Ellipsoid", size = { 1.0, 1.6, 1.5 }, pos = { side * 1.45, 2.75, 1.8 }, color = dark })
			end
			local spots = { { -1.1, -0.7 }, { 1.1, -0.7 }, { -1.1, 1.9 }, { 1.1, 1.9 } }
			legs(add, spots, 1.45, 1.15, grey)
			for i, leg in spots do
				for _, toe in { -0.32, 0, 0.32 } do
					add({
						shape = "Ball",
						size = 0.32,
						pos = { leg[1] + toe, 0.16, leg[2] - 0.5 },
						color = ivory,
						detail = true,
						swing = { hinge = { leg[1], 1.45, leg[2] }, phase = DIAGONAL[i] },
					})
				end
			end
			local c, r = { 0, 2.95, -2.25 }, 1.25
			add({ name = "Head", shape = "Ellipsoid", size = { 2.5, 2.3, 2.6 }, pos = c, color = grey })
			local snout = { 0, 2.35, -3.45 }
			add({ shape = "Ellipsoid", size = { 2.0, 1.5, 1.6 }, pos = snout, color = light })
			for _, side in { -1, 1 } do
				add({
					shape = "Ellipsoid",
					size = { 0.22, 0.3, 0.1 },
					pos = { side * 0.35, 2.4, -4.24 },
					color = rgb(70, 70, 85),
					detail = true,
				})
			end
			smile(add, snout, 0.8, -0.35, 0.6)
			cuteEyes(add, c, r, 0.72, 0.4, 0.56, rgb(150, 90, 230))
			blush(add, c, r, 1.0, -0.05, 0.4)
			for _, side in { -1, 1 } do
				pointyEar(add, side * 0.85, 4.2, -1.75, 0.55, 0.75, dark)
				pointyEar(add, side * 0.85, 4.15, -1.85, 0.3, 0.45, rgb(230, 170, 190))
			end
			-- The horn: a cone of rings, with a glowing tip; a little one behind.
			for k = 0, 9 do
				local width = 0.8 - k * 0.07
				add({
					shape = "Cylinder",
					size = { 0.18, width, width },
					pos = { 0, 3.05 + k * 0.16, -3.75 + k * 0.03 },
					rot = { 0, 0, 90 },
					color = ivory,
				})
			end
			local tip = add({
				shape = "Ball",
				size = 0.3,
				pos = { 0, 4.7, -3.45 },
				color = rgb(190, 110, 255),
				material = "Neon",
				detail = true,
			})
			add({
				shape = "Cylinder",
				size = { 0.45, 0.55, 0.55 },
				pos = { 0, 4.05, -2.95 },
				rot = { 0, 0, 90 },
				color = ivory,
			})
			add({ shape = "Ball", size = 0.35, pos = { 0, 4.35, -2.95 }, color = ivory })
			-- Tail with a tuft.
			add({
				shape = "Cylinder",
				size = { 0.9, 0.2, 0.2 },
				pos = { 0, 2.9, 3.05 },
				rot = { 0, -90, -30 },
				color = dark,
				swing = { hinge = { 0, 3.1, 2.75 }, axis = "Y", amount = 0.7 },
			})
			add({
				shape = "Ellipsoid",
				size = { 0.35, 0.5, 0.35 },
				pos = { 0, 2.55, 3.4 },
				color = rgb(80, 80, 100),
				swing = { hinge = { 0, 3.1, 2.75 }, axis = "Y", amount = 0.7 },
			})
			return { parts = list, effects = { { type = "Glow", part = tip, color = rgb(190, 110, 255) } } }
		end)(),
	},

	-- The Human line
	{
		id = "Chuckles",
		signature = "clownnose",
		walk = "bounce",
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
				openMouth(h.add, { 0, h.headY, 0 }, h.head / 2, -h.head * 0.24, 0.95)
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
		signature = "glasses",
		walk = "strut",
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
		signature = "sweatband",
		walk = "stomp",
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
				-- Its signature sweatband.
				Accessories.put(h.add, "sweatband", { 0, h.headY, 0 }, h.head / 2)
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
		signature = "tiara",
		walk = "catwalk",
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

	-- The Monster line: only from Monster Crates (exclusive = true keeps them out of the
	-- cannons and everywhere else).
	{
		id = "BooBoo",
		signature = "witchhat",
		name = "Boo-Boo",
		rarity = "Uncommon",
		exclusive = true,
		walk = "float",
		income = 25,
		look = (function()
			local list, add = newParts()
			local white = rgb(240, 245, 255)
			local body = { 0, 2.9, 0 }
			add({ name = "Body", shape = "Ball", size = 3, pos = body, color = white, transparency = 0.1 })
			-- Its signature witch hat.
			Accessories.put(add, "witchhat", body, 1.5)
			-- A wavy hem floating above the ground.
			for i = 0, 7 do
				local a = i / 8 * math.pi * 2
				add({
					shape = "Ball",
					size = 1.05,
					pos = { math.cos(a) * 1.05, 1.55, math.sin(a) * 1.05 },
					color = white,
					transparency = 0.1,
				})
			end
			for _, side in { -1, 1 } do
				add({
					shape = "Ball",
					size = 0.62,
					pos = onBall(body, 1.5, side * 0.45, 0.25, -0.1),
					color = rgb(25, 25, 40),
					detail = true,
				})
				add({
					shape = "Ball",
					size = 0.2,
					pos = onBall(body, 1.5, side * 0.38, 0.38, 0.12),
					color = rgb(255, 255, 255),
					detail = true,
				})
				add({
					shape = "Ball",
					size = 0.4,
					pos = onBall(body, 1.5, side * 0.85, -0.15, -0.12),
					color = rgb(255, 170, 200),
					detail = true,
				})
				add({
					shape = "Ball",
					size = 0.75,
					pos = { side * 1.6, 2.5, -0.2 },
					color = white,
					transparency = 0.1,
					swing = {
						hinge = { side * 1.3, 2.9, -0.2 },
						phase = if side < 0 then 0 else 0.5,
						axis = "Z",
						amount = side * 0.8,
					},
				})
			end
			openMouth(add, body, 1.5, -0.42, 0.42)
			return { parts = list, effects = { { type = "Glow", part = 1, color = rgb(190, 220, 255), size = 8 } } }
		end)(),
	},
	{
		id = "Zomboy",
		signature = "bolts",
		name = "Zomboy",
		rarity = "Uncommon",
		exclusive = true,
		walk = "shamble",
		income = 30,
		look = human({
			skin = rgb(140, 200, 110),
			shirt = rgb(80, 120, 190),
			pants = rgb(110, 80, 60),
			shoes = rgb(60, 50, 45),
			armsForward = true,
			head = 2.15,
			extra = function(h)
				-- Its signature neck bolts.
				Accessories.put(h.add, "bolts", { 0, h.headY, 0 }, h.head / 2)
				-- Messy hair, a peek of brain, stitches and a torn shirt.
				h.add({
					shape = "Ball",
					size = h.head + 0.1,
					pos = { 0, h.headY + 0.35, 0.25 },
					color = rgb(60, 45, 35),
				})
				h.add({ shape = "Ball", size = 0.6, pos = { 0.45, h.headY + 0.95, -0.3 }, color = rgb(255, 150, 170) })
				h.add({ shape = "Ball", size = 0.45, pos = { 0.75, h.headY + 0.8, -0.1 }, color = rgb(255, 150, 170) })
				for i = -1, 1 do
					h.add({
						shape = "Block",
						size = { 0.06, 0.3, 0.06 },
						pos = { -0.6 + i * 0.15, h.headY + 0.45, h.face(-0.6 + i * 0.15, 0.45, -0.02) },
						color = rgb(40, 40, 40),
						detail = true,
					})
				end
				h.add({
					shape = "Block",
					size = { 0.5, 0.05, 0.06 },
					pos = { -0.6, h.headY + 0.45, h.face(-0.6, 0.45, -0.03) },
					color = rgb(40, 40, 40),
					detail = true,
				})
				for _, x in { -0.5, 0.1, 0.6 } do
					h.add({
						shape = "Wedge",
						size = { 0.3, 0.35, 0.3 },
						pos = { x, 1.75, -h.torsoD / 2 - 0.05 },
						rot = { 180, 0, 0 },
						color = rgb(80, 120, 190),
					})
				end
			end,
		}),
	},
	{
		id = "Mumbles",
		signature = "bandage",
		name = "Mumbles",
		rarity = "Rare",
		exclusive = true,
		walk = "shamble",
		income = 100,
		look = human({
			skin = rgb(235, 225, 195),
			shirt = rgb(235, 225, 195),
			pants = rgb(225, 214, 182),
			shoes = rgb(210, 198, 165),
			armsForward = true,
			head = 2.15,
			extra = function(h)
				-- Bandage strips wrapped every which way, one eye peeking out.
				local strip = rgb(200, 188, 155)
				for i, y in { 1.9, 2.35, 2.8, 3.15 } do
					h.add({
						shape = "Block",
						size = { h.torsoW + 0.08, 0.14, h.torsoD + 0.08 },
						pos = { 0, y, 0 },
						rot = { 0, 0, if i % 2 == 0 then 8 else -8 },
						color = strip,
					})
				end
				for i, dy in { -0.55, 0.05, 0.6 } do
					h.add({
						shape = "Cylinder",
						size = { 0.16, h.head + 0.06, h.head + 0.06 },
						pos = { 0, h.headY + dy, 0 },
						rot = { 0, 0, 90 + (if i == 2 then 10 else -6) },
						color = strip,
					})
				end
				h.add({
					shape = "Block",
					size = { 0.75, 0.55, 0.2 },
					pos = { h.eyeX, h.headY + h.eyeY, h.face(h.eyeX, h.eyeY, 0.2) },
					rot = { 0, 0, 12 },
					color = rgb(235, 225, 195),
				})
				-- A loose end dangling down the back.
				h.add({
					shape = "Block",
					size = { 0.25, 1.2, 0.08 },
					pos = { 0.9, h.headY - 1.0, 0.4 },
					rot = { 0, 0, 15 },
					color = strip,
				})
			end,
		}),
	},
	{
		id = "CountFangula",
		signature = "capecollar",
		name = "Count Fangula",
		rarity = "Legendary",
		exclusive = true,
		walk = "strut",
		income = 400,
		look = human({
			skin = rgb(225, 215, 240),
			shirt = rgb(30, 25, 40),
			sleeves = rgb(30, 25, 40),
			pants = rgb(30, 25, 40),
			shoes = rgb(15, 15, 20),
			head = 2.2,
			extra = function(h)
				-- Slicked black hair with a widow's peak, red eyes, fangs, and a big cape.
				h.add({
					shape = "Ball",
					size = h.head + 0.12,
					pos = { 0, h.headY + 0.32, 0.3 },
					color = rgb(20, 15, 25),
				})
				h.add({
					shape = "Block",
					size = { 0.5, 0.5, 0.3 },
					pos = { 0, h.headY + 0.8, h.face(0, 0.8, -0.2) },
					rot = { 0, 0, 45 },
					color = rgb(20, 15, 25),
				})
				for _, side in { -1, 1 } do
					local p = { side * h.eyeX, h.headY + h.eyeY, h.face(h.eyeX, h.eyeY, -0.12) }
					h.add({
						shape = "Ball",
						size = 0.38,
						pos = { p[1], p[2], p[3] - 0.12 },
						color = rgb(220, 30, 50),
						detail = true,
					})
					h.add({
						shape = "Wedge",
						size = { 0.1, 0.3, 0.12 },
						pos = { side * 0.18, h.headY - h.head * 0.2 - 0.18, h.face(0.18, h.head * 0.2 + 0.18, 0.02) },
						rot = { 180, 0, 0 },
						color = rgb(255, 255, 255),
						detail = true,
					})
				end
				local red = rgb(190, 20, 40)
				h.add({
					shape = "Block",
					size = { h.torsoW + 0.7, 3.1, 0.15 },
					pos = { 0, 1.75, h.torsoD / 2 + 0.2 },
					color = red,
				})
				h.add({
					shape = "Block",
					size = { h.torsoW + 0.9, 3.2, 0.12 },
					pos = { 0, 1.75, h.torsoD / 2 + 0.32 },
					color = rgb(20, 15, 25),
				})
				for _, side in { -1, 1 } do
					h.add({
						shape = "Block",
						size = { 0.9, 1.2, 0.12 },
						pos = { side * 0.75, h.torsoTop + 0.45, 0.35 },
						rot = { -15, side * 25, 0 },
						color = red,
					})
				end
				h.add({
					shape = "Ball",
					size = 0.3,
					pos = { 0, h.torsoTop - 0.3, -h.torsoD / 2 - 0.08 },
					color = red,
					material = "Neon",
					detail = true,
				})
			end,
		}),
	},
	{
		id = "Howlz",
		signature = "spikedcollar",
		name = "Howlz",
		rarity = "Mystic",
		exclusive = true,
		walk = "prowl",
		income = 1500,
		look = human({
			skin = rgb(120, 85, 60),
			shirt = rgb(110, 60, 140),
			sleeves = rgb(120, 85, 60),
			pants = rgb(60, 60, 80),
			shoes = rgb(120, 85, 60),
			torsoWidth = 2.2,
			torsoDepth = 1.3,
			armSize = 0.6,
			head = 2.1,
			noMouth = true,
			extra = function(h)
				local fur, light = rgb(120, 85, 60), rgb(200, 170, 140)
				-- Its signature spiked collar.
				Accessories.put(h.add, "spikedcollar", { 0, h.headY - h.head / 2, 0 }, h.head / 2)
				-- Wolf snout, nose, pointy ears, yellow eyes and a fluffy tail.
				h.add({ shape = "Ball", size = 1.1, pos = { 0, h.headY - 0.35, h.face(0, -0.35, -0.3) }, color = light })
				h.add({
					shape = "Ball",
					size = 0.4,
					pos = { 0, h.headY - 0.15, h.face(0, -0.15, 0.25) },
					color = rgb(20, 15, 15),
					detail = true,
				})
				h.add({
					shape = "Block",
					size = { 0.5, 0.08, 0.08 },
					pos = { 0, h.headY - 0.7, h.face(0, -0.7, 0.1) },
					color = rgb(60, 20, 20),
					detail = true,
				})
				for _, side in { -1, 1 } do
					pointyEar(h.add, side * 0.62, h.headY + 1.15, 0, 0.7, 0.9, fur)
					local p = { side * h.eyeX, h.headY + h.eyeY, h.face(h.eyeX, h.eyeY, -0.12) }
					h.add({
						shape = "Ball",
						size = 0.36,
						pos = { p[1], p[2], p[3] - 0.12 },
						color = rgb(255, 210, 40),
						detail = true,
					})
					-- Claws.
					for _, dx in { -0.12, 0, 0.12 } do
						h.add({
							shape = "Block",
							size = { 0.06, 0.25, 0.06 },
							pos = { side * (h.shoulderX + 0.08) + dx, 1.4, -0.2 },
							color = rgb(250, 245, 230),
							detail = true,
						})
					end
				end
				for i = 0, 3 do
					h.add({
						shape = "Ball",
						size = 0.75 - i * 0.08,
						pos = { 0, 1.9 + i * 0.3, h.torsoD / 2 + 0.4 + i * 0.25 },
						color = if i == 3 then light else fur,
						swing = { hinge = { 0, 1.9, h.torsoD / 2 + 0.2 }, axis = "Y", amount = 0.8 },
					})
				end
				h.add({
					shape = "Block",
					size = { 0.8, 0.5, 0.1 },
					pos = { 0, h.torsoTop - 0.35, -h.torsoD / 2 - 0.02 },
					color = light,
				})
			end,
		}),
	},
	{
		id = "Blinky",
		signature = "horns",
		name = "Blinky",
		rarity = "Ultra",
		exclusive = true,
		walk = "bounce",
		income = 6000,
		look = (function()
			local list, add = newParts()
			local purple, dark = rgb(140, 80, 220), rgb(95, 45, 170)
			local body = { 0, 2.6, 0 }
			add({ name = "Body", shape = "Ball", size = 3.6, pos = body, color = purple })
			legs(add, { { -0.75, -0.2 }, { 0.75, -0.2 } }, 1.0, 0.7, dark, dark)
			-- One huge eye.
			local eye = onBall(body, 1.8, 0, 0.35, -0.5)
			add({ shape = "Ball", size = 1.8, pos = eye, color = rgb(255, 255, 255), detail = true })
			add({
				shape = "Ball",
				size = 1.1,
				pos = { eye[1], eye[2], eye[3] - 0.42 },
				color = rgb(80, 220, 160),
				detail = true,
			})
			add({
				shape = "Ball",
				size = 0.55,
				pos = { eye[1], eye[2], eye[3] - 0.72 },
				color = rgb(15, 15, 20),
				detail = true,
			})
			add({
				shape = "Ball",
				size = 0.22,
				pos = { eye[1] + 0.25, eye[2] + 0.25, eye[3] - 0.85 },
				color = rgb(255, 255, 255),
				detail = true,
			})
			-- A wide toothy grin.
			openMouth(add, body, 1.8, -0.78, 1.25)
			for _, x in { -0.35, 0, 0.35 } do
				add({
					shape = "Wedge",
					size = { 0.1, 0.22, 0.18 },
					pos = onBall(body, 1.8, x, -0.6, 0.06),
					rot = { 180, 0, 0 },
					color = rgb(255, 255, 255),
					detail = true,
				})
			end
			blush(add, body, 1.8, 1.05, -0.35, 0.5)
			-- Two little horns (stacked rings) and stubby arms.
			for _, side in { -1, 1 } do
				for k = 0, 3 do
					local width = 0.5 - k * 0.11
					add({
						shape = "Cylinder",
						size = { 0.22, width, width },
						pos = { side * (0.75 + k * 0.08), 4.25 + k * 0.2, 0 },
						rot = { 0, 0, 90 - side * 20 },
						color = rgb(255, 220, 120),
					})
				end
				add({
					shape = "Ball",
					size = 0.8,
					pos = { side * 1.9, 2.4, -0.1 },
					color = purple,
					swing = { hinge = { side * 1.6, 2.6, -0.1 }, phase = if side < 0 then 0.5 else 0, amount = 0.6 },
					rig = "arm",
					side = side,
				})
			end
			return {
				parts = list,
				effects = {
					{ type = "Sparkles", part = 1, color = rgb(200, 255, 230) },
					{ type = "Glow", part = 1, color = rgb(80, 220, 160), size = 12 },
				},
			}
		end)(),
	},
}

-- Every Freek belongs to a series (shown first when a Monster Egg hatches).
Freeks.SERIES = {
	Animal = { name = "Animal Series", icon = "🐾", color = Color3.fromRGB(90, 220, 110) },
	Human = { name = "Human Series", icon = "🧑", color = Color3.fromRGB(80, 170, 255) },
	Monster = { name = "Monster Series", icon = "🎃", color = Color3.fromRGB(255, 130, 40) },
	Hybrid = { name = "Hybrid", icon = "🧪", color = Color3.fromRGB(255, 95, 200) },
}
local HUMAN_LINE = { Chuckles = true, Nerdle = true, Flexo = true, Glamora = true }

local base = {}
for i, species in Freeks.list do
	species.order = i
	species.series = if species.exclusive then "Monster" elseif HUMAN_LINE[species.id] then "Human" else "Animal"
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
