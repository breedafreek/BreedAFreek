-- The crafted looks of the Freeks (pets and guardians), like the owner's reference cat:
-- low-poly creatures built from many blocks and wedges, some set at angles, in a muted main
-- colour with one bright Neon accent (glowing eyes, toes, strips, gems), chunky and smooth,
-- with no LEGO studs (look.crafted marks the model "Crafted"; see Lego). Each keeps its
-- character and signature item from Freeks.luau.
--
-- CraftedFreeks[id]() returns a look for FreekModel (see the part list format there): face
-- toward -Z, feet on y = 0, the first part is the body, a part named "Head" turns to look
-- around, parts with a swing hinge walk.

local CraftedFreeks = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local INK = rgb(28, 24, 26)
local WHITE = rgb(245, 245, 240)
local GOLD = rgb(255, 200, 60)
local DIAGONAL = { 0, 0.5, 0.5, 0 } -- leg phases: front-left, front-right, back-left, back-right

-- The kit: a part list and helpers that add to it.
local function kit()
	local list = {}
	local k = {}
	function k.add(spec)
		table.insert(list, spec)
		return #list
	end
	-- A block (or `extra.shape`), at pos, turned by rot (degrees).
	function k.box(size, pos, rot, color, extra)
		local spec = { shape = "Block", size = size, pos = pos, rot = rot, color = color }
		for key, value in extra or {} do
			spec[key] = value
		end
		return k.add(spec)
	end
	function k.wedge(size, pos, rot, color, extra)
		local spec = { shape = "Wedge" }
		for key, value in extra or {} do
			spec[key] = value
		end
		return k.box(size, pos, rot, color, spec)
	end
	-- A glowing detail (keeps its colour when mutated).
	function k.glow(size, pos, rot, color, extra)
		local spec = { material = "Neon", detail = true }
		for key, value in extra or {} do
			spec[key] = value
		end
		return k.box(size, pos, rot, color, spec)
	end
	-- A dark detail (pupils, brows, mouths).
	function k.ink(size, pos, rot, extra)
		local spec = { detail = true }
		for key, value in extra or {} do
			spec[key] = value
		end
		return k.box(size, pos, rot, INK, spec)
	end
	-- Four block legs at (x, z) (front-left, front-right, back-left, back-right), `height`
	-- tall, with chunky paws and glowing toes. colors = { leg, paw, toe }.
	function k.legs(spots, height: number, width: number, colors)
		for i, spot in spots do
			local x, z = spot[1], spot[2]
			local swing = { hinge = { x, height, z }, phase = DIAGONAL[i] or 0 }
			k.box({ width, height, width * 1.1 }, { x, height / 2 + 0.15, z }, nil, colors[1], { swing = swing })
			k.box({ width + 0.16, 0.3, width * 1.1 + 0.3 }, { x, 0.15, z - 0.12 }, nil, colors[2] or colors[1], {
				swing = swing,
			})
			if colors[3] then
				for _, t in { -0.2, 0, 0.2 } do
					k.glow(
						{ 0.13, 0.12, 0.14 },
						{ x + t * width * 1.4, 0.18, z - 0.12 - (width * 1.1 + 0.3) / 2 },
						nil,
						colors[3],
						{
							swing = swing,
						}
					)
				end
			end
		end
	end
	-- Two glowing eyes on a face at depth z (the face's front), centred at height y, `gap`
	-- from the middle. mood: "fierce" (slit pupils, cross brows), "cute" (big square pupils
	-- with a shine) or "sleepy" (heavy lids, in lidColor).
	function k.eyes(y: number, z: number, gap: number, w: number, h: number, color: Color3, mood: string, lidColor)
		for _, side in { -1, 1 } do
			local x = side * gap
			k.glow({ w, h, 0.1 }, { x, y, z - 0.04 }, nil, color)
			if mood == "fierce" then
				k.ink({ w * 0.2, h * 0.85, 0.06 }, { x - side * w * 0.06, y, z - 0.1 })
				k.ink({ w * 1.25, 0.16, 0.18 }, { x, y + h * 0.5 + 0.14, z - 0.08 }, { 0, 0, side * 18 })
			elseif mood == "sleepy" then
				k.ink({ w * 0.36, h * 0.4, 0.06 }, { x, y - h * 0.15, z - 0.1 })
				k.box({ w * 1.15, h * 0.5, 0.14 }, { x, y + h * 0.3, z - 0.1 }, { 0, 0, side * -6 }, lidColor or INK, {
					detail = true,
				})
			else
				k.ink({ w * 0.46, h * 0.62, 0.06 }, { x + side * w * 0.08, y - h * 0.06, z - 0.1 })
				k.box({ w * 0.16, w * 0.16, 0.05 }, { x + side * w * 0.2, y + h * 0.18, z - 0.14 }, nil, WHITE, {
					material = "Neon",
					detail = true,
				})
			end
		end
	end
	function k.done(effects)
		return { parts = list, crafted = true, effects = effects }
	end
	return k
end

-- A chibi person (the Human and Monster lines): block legs and shoes, hips, a torso (the
-- body), arms that swing (or stick out in front with o.armsForward) and a big block head.
-- o = { skin, shirt, pants, shoes, sleeves?, accent (shoe glow), torsoWidth?, head? }.
-- Returns the kit and where the head is: { y, z = its front, w = its width, top }.
local function person(o)
	local k = kit()
	local torsoW = o.torsoWidth or 1.85
	local head = o.head or { 2.0, 1.8, 1.75 }
	k.box({ torsoW, 1.5, 1.05 }, { 0, 2.4, 0 }, nil, o.shirt, { name = "Body" })
	k.box({ torsoW * 0.92, 0.55, 1.0 }, { 0, 1.5, 0 }, nil, o.pants)
	for i, x in { -0.42, 0.42 } do
		local swing = { hinge = { x, 1.35, 0 }, phase = (i - 1) * 0.5 }
		k.box({ 0.62, 1.1, 0.66 }, { x, 0.8, 0 }, nil, o.pants, { swing = swing })
		k.box({ 0.74, 0.36, 0.98 }, { x, 0.2, -0.14 }, nil, o.shoes, { swing = swing, detail = true })
		k.glow({ 0.62, 0.07, 0.07 }, { x, 0.08, -0.64 }, nil, o.accent, { swing = swing })
	end
	local shoulder = torsoW / 2 + 0.3
	for _, side in { -1, 1 } do
		if o.armsForward then
			local swing = { hinge = { side * shoulder, 2.9, 0 }, phase = if side < 0 then 0.5 else 0, amount = 0.25 }
			k.box({ 0.5, 0.5, 1.4 }, { side * shoulder, 2.9, -0.65 }, nil, o.sleeves or o.skin, { swing = swing })
			k.box({ 0.56, 0.5, 0.45 }, { side * shoulder, 2.9, -1.5 }, nil, o.skin, { swing = swing })
		else
			local swing = { hinge = { side * shoulder, 3.05, 0 }, phase = if side < 0 then 0.5 else 0, amount = 0.8 }
			local arm = { swing = swing, rig = "arm", side = side }
			k.box({ 0.5, 1.3, 0.55 }, { side * shoulder, 2.45, 0 }, { 0, 0, side * 6 }, o.sleeves or o.skin, arm)
			k.box({ 0.58, 0.46, 0.6 }, { side * (shoulder + 0.08), 1.62, 0 }, nil, o.skin, {
				swing = swing,
				rig = "arm",
				side = side,
			})
		end
	end
	k.box({ 0.6, 0.3, 0.6 }, { 0, 3.28, 0 }, nil, o.skin)
	local y = 3.35 + head[2] / 2
	k.box(head, { 0, y, 0 }, nil, o.skin, { name = "Head" })
	return k, { y = y, z = -head[3] / 2, w = head[1], top = y + head[2] / 2 }
end

--------------------------------------------------------------------------------
-- Animals
--------------------------------------------------------------------------------

function CraftedFreeks.Oinkle()
	-- A chubby piglet: a round-ish body of layered blocks, a big snout, floppy wedge ears,
	-- glowing pink eyes, little hooves and a curly tail, and its signature bow.
	local k = kit()
	local pink, deep, pale = rgb(222, 140, 155), rgb(186, 104, 122), rgb(245, 186, 196)
	local glow = rgb(255, 80, 170)
	k.box({ 2.3, 1.6, 2.6 }, { 0, 1.5, 0.4 }, nil, pink, { name = "Body" })
	k.box({ 2.0, 0.4, 2.2 }, { 0, 2.42, 0.4 }, nil, deep)
	k.box({ 1.9, 0.4, 2.2 }, { 0, 0.7, 0.4 }, nil, pale)
	k.legs({ { -0.65, -0.45 }, { 0.65, -0.45 }, { -0.65, 1.2 }, { 0.65, 1.2 } }, 0.9, 0.55, { pink, rgb(90, 60, 66) })
	local hy, hz = 2.45, -1.35
	k.box({ 2.0, 1.75, 1.6 }, { 0, hy, hz }, nil, pink, { name = "Head" })
	k.box({ 1.7, 0.3, 1.4 }, { 0, hy + 0.98, hz + 0.05 }, nil, deep)
	k.box({ 1.05, 0.72, 0.42 }, { 0, hy - 0.35, hz - 0.98 }, nil, pale)
	for _, side in { -1, 1 } do
		k.ink({ 0.18, 0.28, 0.06 }, { side * 0.22, hy - 0.35, hz - 1.22 })
		k.wedge({ 0.25, 0.8, 0.7 }, { side * 0.72, hy + 1.05, hz - 0.2 }, { 35, 0, side * -20 }, deep, {
			rig = "ear",
			side = side,
			pivot = { side * 0.72, hy + 0.85, hz },
		})
	end
	k.eyes(hy + 0.3, hz - 0.8, 0.52, 0.42, 0.42, glow, "cute")
	k.glow({ 0.5, 0.08, 0.06 }, { 0, hy - 0.82, hz - 0.82 }, nil, glow)
	-- Curly tail and its glowing tip.
	for i, seg in { { 0, 1.9, 1.85, 30 }, { 0.15, 2.2, 2.0, -20 }, { 0, 2.42, 1.85, 60 } } do
		k.box({ 0.28, 0.28, 0.42 }, { seg[1], seg[2], seg[3] }, { seg[4], 0, 0 }, if i == 3 then glow else deep, {
			swing = { hinge = { 0, 1.8, 1.7 }, axis = "Y", amount = 0.6 },
			material = if i == 3 then "Neon" else nil,
		})
	end
	-- Its signature bow, on top of the head.
	for _, side in { -1, 1 } do
		k.wedge(
			{ 0.2, 0.55, 0.5 },
			{ 0.55 + side * 0.32, hy + 1.3, hz - 0.1 },
			{ 0, side * 90, 0 },
			rgb(255, 80, 150),
			{
				detail = true,
			}
		)
	end
	k.glow({ 0.22, 0.22, 0.22 }, { 0.55, hy + 1.3, hz - 0.1 }, nil, glow)
	return k.done()
end

function CraftedFreeks.Woofles()
	-- A golden puppy: cream chest and muzzle, a black nose and tongue out, long floppy ears,
	-- glowing sky-blue eyes, a red collar with a glowing tag and a wagging tail.
	local k = kit()
	local fur, deep, cream = rgb(205, 150, 72), rgb(160, 108, 50), rgb(240, 214, 168)
	local glow = rgb(90, 210, 255)
	k.box({ 2.0, 1.5, 2.6 }, { 0, 1.85, 0.45 }, { -5, 0, 0 }, fur, { name = "Body" })
	k.box({ 1.8, 1.4, 0.9 }, { 0, 1.95, -0.85 }, { 8, 0, 0 }, cream)
	k.box({ 1.6, 0.35, 2.2 }, { 0, 2.65, 0.5 }, { -5, 0, 0 }, deep)
	k.legs({ { -0.62, -0.5 }, { 0.62, -0.5 }, { -0.66, 1.4 }, { 0.66, 1.4 } }, 1.3, 0.58, { fur, cream, glow })
	local hy, hz = 3.35, -1.2
	k.box({ 1.95, 1.7, 1.75 }, { 0, hy, hz }, nil, fur, { name = "Head" })
	k.box({ 1.7, 0.3, 1.5 }, { 0, hy + 0.95, hz + 0.05 }, nil, deep)
	k.box({ 1.15, 0.66, 0.65 }, { 0, hy - 0.45, hz - 1.15 }, nil, cream)
	k.ink({ 0.44, 0.3, 0.22 }, { 0, hy - 0.16, hz - 1.48 })
	k.box({ 0.36, 0.42, 0.08 }, { 0.12, hy - 0.92, hz - 1.4 }, { 0, 0, -8 }, rgb(240, 110, 130), { detail = true })
	for _, side in { -1, 1 } do
		k.box({ 0.32, 1.25, 0.8 }, { side * 1.1, hy - 0.2, hz + 0.1 }, { 0, 0, side * 10 }, deep, {
			rig = "ear",
			side = side,
			pivot = { side * 1.0, hy + 0.5, hz + 0.1 },
		})
	end
	k.eyes(hy + 0.25, hz - 0.88, 0.48, 0.44, 0.44, glow, "cute")
	-- Collar and its glowing tag.
	k.box({ 1.75, 0.24, 1.6 }, { 0, hy - 0.95, hz + 0.15 }, nil, rgb(205, 40, 50), { detail = true })
	k.glow({ 0.34, 0.34, 0.1 }, { 0, hy - 1.2, hz - 0.68 }, { 0, 0, 45 }, glow)
	-- A wagging tail.
	for i, seg in { { 0, 2.6, 1.8, -40 }, { 0, 3.05, 2.05, -60 }, { 0, 3.5, 2.15, -80 } } do
		k.box({ 0.36, 0.36, 0.7 }, { seg[1], seg[2], seg[3] }, { seg[4], 0, 0 }, if i == 3 then cream else fur, {
			swing = { hinge = { 0, 2.4, 1.6 }, axis = "Y", amount = 1 },
		})
	end
	return k.done()
end

function CraftedFreeks.Whiskerz()
	-- A low-poly prowling cat: a dusty-orange body with darker stripes, glowing amber eyes
	-- under cross brows, glowing whiskers, toes and spine strips, a layered cheek ruff, a
	-- collar and bell, and a jointed tail curling up.
	local k = kit()
	local fur, dark, light = rgb(196, 118, 66), rgb(140, 78, 44), rgb(232, 196, 150)
	local glow = rgb(255, 176, 40)
	k.box({ 2.1, 1.5, 2.8 }, { 0, 1.75, 0.55 }, { -6, 0, 0 }, fur, { name = "Body" })
	k.box({ 1.9, 1.7, 1.0 }, { 0, 2.0, -0.85 }, { 8, 0, 0 }, light)
	k.box({ 1.7, 0.4, 2.3 }, { 0, 2.62, 0.55 }, { -6, 0, 0 }, dark)
	for _, z in { -0.15, 0.55, 1.25 } do
		k.box({ 2.18, 0.28, 0.32 }, { 0, 2.2, z }, { -6, 0, 0 }, dark)
	end
	for _, x in { -0.42, 0.42 } do
		k.glow({ 0.16, 0.08, 1.9 }, { x, 2.84, 0.6 }, { -6, 0, 0 }, glow)
	end
	k.legs({ { -0.68, -0.55 }, { 0.68, -0.55 }, { -0.72, 1.45 }, { 0.72, 1.45 } }, 1.25, 0.62, { fur, light, glow })
	local hy, hz = 3.55, -1.25
	k.box({ 2.3, 1.75, 1.8 }, { 0, hy, hz }, nil, fur, { name = "Head" })
	k.box({ 2.0, 0.35, 1.6 }, { 0, hy + 0.98, hz + 0.05 }, nil, dark)
	k.box({ 1.25, 0.62, 0.55 }, { 0, hy - 0.5, hz - 1.05 }, nil, light)
	k.box({ 0.42, 0.26, 0.16 }, { 0, hy - 0.22, hz - 1.36 }, nil, rgb(240, 120, 140), { detail = true })
	k.ink({ 0.5, 0.08, 0.06 }, { 0, hy - 0.62, hz - 1.34 })
	for _, side in { -1, 1 } do
		k.box({ 0.3, 0.7, 0.9 }, { side * 1.2, hy - 0.4, hz - 0.15 }, { 0, 0, side * 14 }, fur)
		k.box({ 0.24, 0.45, 0.7 }, { side * 1.3, hy - 0.62, hz - 0.1 }, { 0, 0, side * 32 }, light)
		k.wedge({ 0.32, 0.95, 0.75 }, { side * 0.72, hy + 1.45, hz + 0.1 }, { 0, 90, side * -14 }, dark, {
			rig = "ear",
			side = side,
			pivot = { side * 0.72, hy + 1.0, hz + 0.1 },
		})
		k.wedge({ 0.12, 0.6, 0.45 }, { side * 0.72, hy + 1.38, hz - 0.08 }, { 0, 90, side * -14 }, glow, {
			material = "Neon",
			detail = true,
		})
		for i, tilt in { -14, 0, 14 } do
			k.glow({ 1.1, 0.06, 0.08 }, { side * 1.05, hy - 0.42 + (i - 2) * 0.13, hz - 1.05 }, {
				0,
				side * 12,
				side * tilt,
			}, glow)
		end
	end
	k.eyes(hy + 0.2, hz - 0.88, 0.5, 0.62, 0.44, glow, "fierce")
	-- Collar and its gold bell.
	k.box({ 1.95, 0.24, 1.75 }, { 0, hy - 0.95, hz + 0.1 }, nil, rgb(200, 40, 50), { detail = true })
	k.add({
		shape = "Ball",
		size = 0.45,
		pos = { 0, hy - 1.18, hz - 0.9 },
		color = GOLD,
		material = "Metal",
		detail = true,
	})
	for i, seg in { { 0, 1.95, 2.15, -30 }, { 0, 2.45, 2.55, -55 }, { 0, 3.1, 2.7, -80 }, { 0, 3.7, 2.55, -110 } } do
		k.box({ 0.42, 0.42, 0.8 }, { seg[1], seg[2], seg[3] }, { seg[4], 0, 0 }, if i % 2 == 0 then dark else fur, {
			swing = { hinge = { 0, 1.9, 1.9 }, axis = "Y", amount = 0.6 },
		})
	end
	k.glow({ 0.46, 0.46, 0.18 }, { 0, 4.0, 2.35 }, { -110, 0, 0 }, glow)
	return k.done()
end

function CraftedFreeks.Lizzle()
	-- A happy lizard: a low flat body with glowing spine plates, a wide flat head with a big
	-- grin, bulgy eye turrets on top, splayed legs, a long tapering tail, and its signature
	-- flower on its head.
	local k = kit()
	local scale, deep, belly = rgb(112, 168, 78), rgb(74, 122, 56), rgb(214, 214, 140)
	local glow = rgb(255, 225, 60)
	k.box({ 2.1, 0.95, 2.8 }, { 0, 1.0, 0.35 }, nil, scale, { name = "Body" })
	k.box({ 1.7, 0.3, 2.4 }, { 0, 0.55, 0.35 }, nil, belly)
	for i, z in { -0.6, 0.1, 0.8, 1.5 } do
		k.wedge({ 0.3, 0.45, 0.45 }, { 0, 1.7, z }, nil, deep)
		k.glow({ 0.1, 0.2, 0.2 }, { 0, 1.82 + (i % 2) * 0.02, z + 0.1 }, nil, glow)
	end
	for i, leg in { { -1, -0.45 }, { 1, -0.45 }, { -1, 1.2 }, { 1, 1.2 } } do
		local swing = { hinge = { leg[1] * 0.85, 0.85, leg[2] }, phase = DIAGONAL[i] }
		k.box({ 0.8, 0.42, 0.5 }, { leg[1] * 1.2, 0.7, leg[2] }, { 0, 0, leg[1] * -25 }, scale, { swing = swing })
		k.box({ 0.5, 0.5, 0.5 }, { leg[1] * 1.55, 0.3, leg[2] }, nil, deep, { swing = swing })
		k.glow({ 0.55, 0.1, 0.12 }, { leg[1] * 1.55, 0.08, leg[2] - 0.3 }, nil, glow, { swing = swing })
	end
	local hy, hz = 1.35, -1.75
	k.box({ 2.2, 0.95, 1.6 }, { 0, hy, hz }, nil, scale, { name = "Head" })
	k.box({ 1.9, 0.3, 1.0 }, { 0, hy - 0.5, hz - 0.15 }, nil, belly)
	k.ink({ 1.5, 0.12, 0.08 }, { 0, hy - 0.18, hz - 0.82 })
	k.box({ 0.9, 0.16, 0.08 }, { 0, hy - 0.3, hz - 0.82 }, nil, rgb(240, 110, 130), { detail = true })
	for _, side in { -1, 1 } do
		k.box({ 0.62, 0.55, 0.62 }, { side * 0.6, hy + 0.7, hz - 0.2 }, nil, scale)
	end
	k.eyes(hy + 0.72, hz - 0.52, 0.6, 0.42, 0.4, glow, "cute")
	-- Tail: tapering segments that swish.
	for i, seg in { { 1.95, 0.85 }, { 2.7, 0.7 }, { 3.4, 0.55 }, { 4.0, 0.4 } } do
		k.box({ seg[2], seg[2] * 0.8, 0.8 }, { 0, 0.8 - i * 0.08, seg[1] }, nil, if i % 2 == 0 then deep else scale, {
			swing = { hinge = { 0, 0.9, 1.7 }, axis = "Y", amount = 0.9 },
		})
	end
	-- Its signature flower.
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		k.box({ 0.32, 0.12, 0.32 }, { 0.55 + math.cos(a) * 0.28, hy + 0.95, hz + 0.45 + math.sin(a) * 0.28 }, {
			0,
			math.deg(a),
			0,
		}, rgb(255, 120, 170), { detail = true })
	end
	k.glow({ 0.24, 0.16, 0.24 }, { 0.55, hy + 1.0, hz + 0.45 }, nil, glow)
	return k.done()
end

function CraftedFreeks.Hootsworth()
	-- A posh owl: a tall layered body with feather chevrons, a pale face disc with two big
	-- glowing orange eyes (one behind a gold monocle), ear tufts, a beak, wings that flap, and
	-- its signature top hat.
	local k = kit()
	local brown, deep, cream = rgb(132, 92, 60), rgb(92, 62, 40), rgb(232, 212, 176)
	local glow = rgb(255, 160, 30)
	k.box({ 2.1, 2.2, 1.9 }, { 0, 1.65, 0.1 }, nil, brown, { name = "Body" })
	k.box({ 1.5, 1.7, 0.3 }, { 0, 1.5, -0.88 }, nil, cream)
	for _, y in { 1.0, 1.45, 1.9 } do
		for _, x in { -0.35, 0.35 } do
			k.wedge({ 0.36, 0.22, 0.12 }, { x, y, -1.06 }, { 0, 180, 0 }, deep, { detail = true })
		end
	end
	for _, side in { -1, 1 } do
		k.box({ 0.35, 1.7, 1.5 }, { side * 1.2, 1.7, 0.15 }, { 0, 0, side * -6 }, deep, {
			swing = { hinge = { side * 1.05, 2.5, 0.15 }, axis = "Z", amount = 1 },
		})
		k.box({ 0.6, 0.3, 0.7 }, { side * 0.45, 0.15, -0.2 }, nil, rgb(240, 150, 40), {
			swing = { hinge = { side * 0.45, 0.6, 0 }, phase = if side < 0 then 0 else 0.5 },
		})
	end
	local hy, hz = 3.45, 0
	k.box({ 2.3, 1.5, 1.95 }, { 0, hy, hz }, nil, brown, { name = "Head" })
	k.box({ 2.0, 1.15, 0.2 }, { 0, hy - 0.05, hz - 1.0 }, nil, cream)
	for _, side in { -1, 1 } do
		k.wedge({ 0.3, 0.7, 0.55 }, { side * 0.9, hy + 1.0, hz }, { 0, 90, side * -18 }, deep, {
			rig = "ear",
			side = side,
			pivot = { side * 0.9, hy + 0.7, hz },
		})
	end
	k.eyes(hy + 0.05, hz - 1.08, 0.5, 0.62, 0.62, glow, "cute")
	k.wedge({ 0.32, 0.45, 0.3 }, { 0, hy - 0.45, hz - 1.25 }, { 180, 0, 0 }, rgb(240, 150, 40), { detail = true })
	-- A gold monocle on the right eye.
	k.box({ 0.82, 0.08, 0.08 }, { 0.5, hy + 0.41, hz - 1.18 }, nil, GOLD, { material = "Metal", detail = true })
	k.box({ 0.82, 0.08, 0.08 }, { 0.5, hy - 0.31, hz - 1.18 }, nil, GOLD, { material = "Metal", detail = true })
	k.box({ 0.08, 0.8, 0.08 }, { 0.12, hy + 0.05, hz - 1.18 }, nil, GOLD, { material = "Metal", detail = true })
	k.box({ 0.08, 0.8, 0.08 }, { 0.88, hy + 0.05, hz - 1.18 }, nil, GOLD, { material = "Metal", detail = true })
	k.box(
		{ 0.05, 0.9, 0.05 },
		{ 0.92, hy - 0.75, hz - 1.15 },
		{ 0, 0, 12 },
		GOLD,
		{ material = "Metal", detail = true }
	)
	-- Its signature top hat, with a glowing band.
	k.box({ 1.6, 0.12, 1.5 }, { 0, hy + 0.8, hz }, nil, INK, { detail = true })
	k.box({ 1.0, 1.0, 0.95 }, { 0, hy + 1.35, hz }, nil, INK, { detail = true })
	k.glow({ 1.04, 0.16, 0.99 }, { 0, hy + 1.0, hz }, nil, glow)
	return k.done()
end

function CraftedFreeks.Chompers()
	-- A cool croc: a long low body with ridges down the back, a long snout with the jaws
	-- open and full of teeth, eye bumps behind black shades with a glowing rim, a gold chain
	-- and a long tapering tail that swishes.
	local k = kit()
	local green, deep, belly = rgb(72, 118, 70), rgb(46, 82, 50), rgb(196, 200, 140)
	local glow = rgb(60, 255, 170)
	k.box({ 2.0, 1.0, 3.4 }, { 0, 1.0, 0.4 }, nil, green, { name = "Body" })
	k.box({ 1.7, 0.3, 3.0 }, { 0, 0.55, 0.4 }, nil, belly)
	for i, z in { -0.9, -0.2, 0.5, 1.2, 1.9 } do
		for _, x in { -0.45, 0.45 } do
			k.wedge({ 0.26, 0.35, 0.4 }, { x, 1.62, z }, nil, deep)
		end
		if i % 2 == 1 then
			k.glow({ 0.08, 0.08, 0.36 }, { 0, 1.53, z }, nil, glow)
		end
	end
	for i, leg in { { -1, -0.6 }, { 1, -0.6 }, { -1, 1.4 }, { 1, 1.4 } } do
		local swing = { hinge = { leg[1] * 0.85, 0.85, leg[2] }, phase = DIAGONAL[i] }
		k.box({ 0.7, 0.45, 0.55 }, { leg[1] * 1.15, 0.7, leg[2] }, { 0, 0, leg[1] * -25 }, green, { swing = swing })
		k.box({ 0.55, 0.5, 0.6 }, { leg[1] * 1.45, 0.3, leg[2] }, nil, deep, { swing = swing })
	end
	local hy, hz = 1.3, -1.45
	k.box({ 1.8, 0.95, 1.3 }, { 0, hy, hz }, nil, green, { name = "Head" })
	k.box({ 1.5, 0.42, 2.1 }, { 0, hy + 0.05, hz - 1.6 }, { -6, 0, 0 }, green)
	k.box({ 1.4, 0.3, 1.9 }, { 0, hy - 0.5, hz - 1.45 }, { 10, 0, 0 }, deep)
	k.box({ 1.2, 0.08, 1.6 }, { 0, hy - 0.3, hz - 1.45 }, { 4, 0, 0 }, rgb(200, 70, 80), { detail = true })
	for i = 0, 4 do
		for _, side in { -1, 1 } do
			k.wedge({ 0.12, 0.2, 0.16 }, { side * 0.62, hy - 0.22, hz - 0.85 - i * 0.36 }, { 180, 0, 0 }, WHITE, {
				detail = true,
			})
		end
	end
	for _, side in { -1, 1 } do
		k.box({ 0.6, 0.5, 0.6 }, { side * 0.5, hy + 0.65, hz - 0.1 }, nil, green)
		-- Black shades with a glowing rim.
		k.box({ 0.62, 0.32, 0.08 }, { side * 0.5, hy + 0.7, hz - 0.45 }, nil, INK, { detail = true })
		k.glow({ 0.64, 0.05, 0.09 }, { side * 0.5, hy + 0.88, hz - 0.45 }, nil, glow)
	end
	k.ink({ 0.4, 0.06, 0.06 }, { 0, hy + 0.78, hz - 0.45 })
	-- A gold chain round the neck.
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		k.box(
			{ 0.26, 0.18, 0.26 },
			{ math.cos(a) * 0.95, hy - 0.45 + math.sin(a) * 0.05, hz + 0.55 + math.sin(a) * 0.7 },
			{
				0,
				math.deg(a),
				0,
			},
			GOLD,
			{ material = "Metal", detail = true }
		)
	end
	-- Tail: tapering segments that swish.
	for i, seg in { { 2.5, 0.85 }, { 3.3, 0.7 }, { 4.0, 0.55 }, { 4.6, 0.4 } } do
		k.box({ seg[2], seg[2] * 0.75, 0.9 }, { 0, 0.85 - i * 0.08, seg[1] }, nil, if i % 2 == 0 then deep else green, {
			swing = { hinge = { 0, 0.9, 2.1 }, axis = "Y", amount = 0.9 },
		})
	end
	return k.done()
end

function CraftedFreeks.Stompy()
	-- A chunky armoured rhino: layered plates on shoulders and hips, a big snout, fierce
	-- purple glowing eyes, a tall ivory horn with a glowing tip, toenails and a tufted tail.
	local k = kit()
	local hide, plate, ivory = rgb(124, 118, 134), rgb(86, 82, 98), rgb(236, 226, 200)
	local glow = rgb(190, 90, 255)
	k.box({ 2.7, 2.0, 3.4 }, { 0, 2.15, 0.4 }, nil, hide, { name = "Body" })
	for _, z in { -0.7, 1.4 } do
		k.box({ 3.0, 0.9, 1.1 }, { 0, 2.75, z }, { 0, 0, 0 }, plate)
		k.box({ 2.6, 0.3, 0.9 }, { 0, 3.3, z }, nil, plate)
		k.glow({ 0.12, 0.1, 0.9 }, { 0, 3.47, z }, nil, glow)
	end
	k.legs({ { -0.85, -0.7 }, { 0.85, -0.7 }, { -0.85, 1.5 }, { 0.85, 1.5 } }, 1.35, 0.85, { hide, plate })
	for _, spot in { { -0.85, -0.7 }, { 0.85, -0.7 }, { -0.85, 1.5 }, { 0.85, 1.5 } } do
		for _, t in { -0.25, 0.25 } do
			k.box({ 0.22, 0.18, 0.12 }, { spot[1] + t, 0.18, spot[2] - 0.75 }, nil, ivory, { detail = true })
		end
	end
	local hy, hz = 2.55, -1.9
	k.box({ 1.95, 1.65, 1.8 }, { 0, hy, hz }, nil, hide, { name = "Head" })
	k.box({ 1.5, 1.0, 1.0 }, { 0, hy - 0.4, hz - 1.2 }, nil, hide)
	k.box({ 1.7, 0.3, 1.5 }, { 0, hy + 0.95, hz + 0.1 }, nil, plate)
	for _, side in { -1, 1 } do
		k.ink({ 0.16, 0.22, 0.06 }, { side * 0.3, hy - 0.55, hz - 1.72 })
		k.wedge({ 0.25, 0.6, 0.5 }, { side * 0.85, hy + 1.1, hz + 0.4 }, { 0, 90, side * -20 }, plate, {
			rig = "ear",
			side = side,
			pivot = { side * 0.85, hy + 0.9, hz + 0.4 },
		})
	end
	k.eyes(hy + 0.25, hz - 0.92, 0.6, 0.48, 0.34, glow, "fierce")
	-- The horn: stacked ivory blocks narrowing to a glowing tip; a little one behind.
	for i, s in { 0.6, 0.48, 0.36, 0.25 } do
		k.box(
			{ s, 0.36, s },
			{ 0, hy + 0.25 + i * 0.32, hz - 1.55 - i * 0.08 },
			{ -12, 45, 0 },
			ivory,
			{ detail = true }
		)
	end
	k.glow({ 0.16, 0.36, 0.16 }, { 0, hy + 1.85, hz - 1.95 }, { -12, 45, 0 }, glow)
	k.box({ 0.3, 0.4, 0.3 }, { 0, hy + 0.35, hz - 0.95 }, { 0, 45, 0 }, ivory, { detail = true })
	-- Tufted tail.
	k.box({ 0.26, 0.26, 0.8 }, { 0, 2.4, 2.45 }, { 30, 0, 0 }, hide, {
		swing = { hinge = { 0, 2.6, 2.1 }, axis = "Y", amount = 0.6 },
	})
	k.box(
		{ 0.36, 0.5, 0.36 },
		{ 0, 2.0, 2.75 },
		nil,
		plate,
		{ swing = { hinge = { 0, 2.6, 2.1 }, axis = "Y", amount = 0.6 } }
	)
	return k.done()
end

function CraftedFreeks.Blinky()
	-- A one-eyed monster: a chunky purple body with glowing spikes down its back, one huge
	-- eye with a glowing green iris, a wide toothy grin, stubby arms and legs, and its
	-- signature horns.
	local k = kit()
	local purple, deep = rgb(122, 76, 196), rgb(84, 46, 150)
	local glow = rgb(80, 230, 160)
	k.box({ 2.6, 2.5, 2.3 }, { 0, 1.95, 0.1 }, nil, purple, { name = "Body" })
	k.box({ 2.3, 0.4, 2.0 }, { 0, 3.35, 0.1 }, nil, deep)
	for _, y in { 2.2, 2.9, 3.5 } do
		k.wedge({ 0.4, 0.5, 0.5 }, { 0, y, 1.35 }, { 0, 180, 0 }, deep)
		k.glow({ 0.14, 0.3, 0.3 }, { 0, y + 0.02, 1.5 }, { 0, 180, 0 }, glow)
	end
	k.legs({ { -0.65, -0.1 }, { 0.65, -0.1 } }, 0.7, 0.7, { deep, purple, glow })
	for _, side in { -1, 1 } do
		k.box({ 0.55, 1.0, 0.6 }, { side * 1.55, 1.9, -0.1 }, { 0, 0, side * 18 }, purple, {
			swing = { hinge = { side * 1.35, 2.35, -0.1 }, phase = if side < 0 then 0.5 else 0, amount = 0.8 },
			rig = "arm",
			side = side,
		})
	end
	-- One huge eye.
	k.box({ 1.55, 1.25, 0.12 }, { 0, 2.55, -1.1 }, nil, WHITE, { detail = true })
	k.glow({ 0.85, 0.85, 0.1 }, { 0, 2.5, -1.18 }, nil, glow)
	k.ink({ 0.4, 0.5, 0.06 }, { 0, 2.5, -1.25 })
	k.box({ 0.16, 0.16, 0.05 }, { 0.2, 2.72, -1.29 }, nil, WHITE, { material = "Neon", detail = true })
	k.box({ 1.7, 0.18, 0.16 }, { 0, 3.25, -1.12 }, nil, deep, { detail = true })
	-- A wide toothy grin.
	k.ink({ 1.6, 0.4, 0.08 }, { 0, 1.5, -1.12 })
	for i = 0, 4 do
		k.wedge({ 0.18, 0.2, 0.1 }, { -0.6 + i * 0.3, 1.6, -1.18 }, { 180, 0, 0 }, WHITE, { detail = true })
	end
	-- Its signature horns.
	for _, side in { -1, 1 } do
		for i, s in { 0.5, 0.38, 0.26 } do
			k.box(
				{ s, 0.32, s },
				{ side * (0.85 + i * 0.12), 3.4 + i * 0.3, 0 },
				{ 0, 0, side * -18 },
				rgb(240, 225, 190),
				{
					detail = true,
				}
			)
		end
	end
	return k.done()
end

function CraftedFreeks.Stormy()
	-- A grumpy storm cloud: a puffy cloud of grey-blue blocks, glowing yellow eyes under cross
	-- brows, puffy arms, a crackling glowing lightning bolt underneath and glowing raindrops.
	local k = kit()
	local cloud, deep, light = rgb(132, 146, 170), rgb(96, 108, 132), rgb(176, 188, 208)
	local glow = rgb(255, 230, 70)
	k.box({ 2.6, 1.6, 2.0 }, { 0, 2.9, 0 }, nil, cloud, { name = "Body" })
	for _, puff in
		{
			{ -1.2, 2.7, 0, 1.3, cloud },
			{ 1.2, 2.75, 0.1, 1.35, cloud },
			{ -0.55, 3.75, 0.05, 1.3, light },
			{ 0.55, 3.85, -0.05, 1.45, light },
			{ 0, 2.25, 0.1, 1.2, deep },
			{ 0.1, 3.0, 0.75, 1.4, deep },
		}
	do
		k.box(
			{ puff[4], puff[4] * 0.85, puff[4] * 0.9 },
			{ puff[1], puff[2], puff[3] },
			{ 0, puff[1] * 12, 0 },
			puff[5]
		)
	end
	k.eyes(3.1, -1.0, 0.5, 0.5, 0.42, glow, "fierce")
	k.ink({ 0.6, 0.1, 0.06 }, { 0, 2.55, -1.04 }, { 0, 0, 6 })
	for _, side in { -1, 1 } do
		k.box({ 0.7, 0.6, 0.7 }, { side * 2.0, 2.6, -0.1 }, nil, cloud, {
			swing = { hinge = { side * 1.7, 2.8, -0.1 }, axis = "Z", amount = 1 },
		})
	end
	-- The lightning bolt underneath.
	for _, bit in { { 0.15, 1.65, -25 }, { -0.05, 1.05, 30 }, { 0.15, 0.45, -25 } } do
		k.glow({ 0.3, 0.75, 0.2 }, { bit[1], bit[2], 0 }, { 0, 0, bit[3] }, glow)
	end
	for _, drop in { { -0.9, 1.4, 0.3 }, { 0.9, 1.1, -0.2 }, { -0.5, 0.7, -0.4 }, { 0.7, 0.4, 0.4 } } do
		k.glow({ 0.12, 0.3, 0.12 }, drop, nil, rgb(90, 190, 255))
	end
	return k.done({ { type = "Sparkles", part = 1, color = glow } })
end

--------------------------------------------------------------------------------
-- People and monsters
--------------------------------------------------------------------------------

function CraftedFreeks.Chuckles()
	-- A clown: yellow shirt with glowing pom-pom buttons, blue pants, huge red shoes, a frilly
	-- collar, a rainbow afro, a huge grin and its signature glowing red nose.
	local glow = rgb(255, 60, 60)
	local k, h = person({
		skin = rgb(250, 222, 196),
		shirt = rgb(240, 200, 60),
		pants = rgb(60, 104, 210),
		shoes = rgb(220, 44, 44),
		accent = rgb(80, 220, 255),
	})
	for _, y in { 2.0, 2.45, 2.9 } do
		k.glow({ 0.22, 0.22, 0.1 }, { 0, y, -0.56 }, nil, rgb(80, 220, 255))
	end
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		k.wedge(
			{ 0.5, 0.3, 0.4 },
			{ math.cos(a) * 0.95, 3.28, math.sin(a) * 0.65 },
			{ 0, -math.deg(a) + 90, 0 },
			if i % 2 == 0 then rgb(255, 120, 180) else WHITE
		)
	end
	local hy, fz = h.y, h.z
	k.eyes(hy + 0.2, fz, 0.48, 0.42, 0.42, rgb(80, 220, 255), "cute")
	k.glow({ 0.5, 0.45, 0.4 }, { 0, hy - 0.15, fz - 0.25 }, nil, glow)
	k.ink({ 1.2, 0.3, 0.08 }, { 0, hy - 0.6, fz - 0.04 })
	k.box({ 1.0, 0.1, 0.06 }, { 0, hy - 0.5, fz - 0.1 }, nil, WHITE, { detail = true })
	-- Rainbow afro: a big puff of coloured blocks over the top and sides of the head.
	local colors = {
		rgb(255, 60, 60),
		rgb(255, 160, 40),
		rgb(255, 220, 50),
		rgb(80, 210, 90),
		rgb(70, 140, 255),
		rgb(170, 90, 240),
	}
	local n = 0
	for _, x in { -1.0, 0, 1.0 } do
		for _, z in { -0.55, 0.2, 0.95 } do
			n += 1
			k.box(
				{ 1.0, 0.9, 0.95 },
				{ x, h.top + 0.3 + (n % 2) * 0.12, z },
				{ 0, n * 7, (n % 3 - 1) * 8 },
				colors[n % #colors + 1],
				{
					detail = true,
				}
			)
		end
	end
	for _, side in { -1, 1 } do
		for i, y in { 0.35, -0.25 } do
			k.box(
				{ 0.7, 0.8, 0.9 },
				{ side * 1.2, hy + y, 0.2 + i * 0.3 },
				{ 0, 0, side * 10 },
				colors[(i + (side + 1)) % #colors + 1],
				{
					detail = true,
				}
			)
		end
	end
	return k.done()
end

function CraftedFreeks.Nerdle()
	-- A nerd: green sweater vest over a white shirt, neat brown hair with a side part, thick
	-- black glasses with glowing blue lenses, a pocket protector with glowing pens and a bow tie.
	local glow = rgb(70, 170, 255)
	local k, h = person({
		skin = rgb(244, 210, 180),
		shirt = rgb(86, 140, 86),
		sleeves = WHITE,
		pants = rgb(134, 106, 78),
		shoes = rgb(70, 50, 40),
		accent = glow,
	})
	k.box({ 0.5, 0.5, 0.08 }, { 0.5, 2.65, -0.56 }, nil, WHITE, { detail = true })
	for i, c in { rgb(255, 80, 80), glow } do
		k.glow({ 0.06, 0.4, 0.06 }, { 0.38 + i * 0.12, 2.9, -0.6 }, nil, c)
	end
	for _, side in { -1, 1 } do
		k.wedge(
			{ 0.15, 0.3, 0.3 },
			{ side * 0.18, 3.2, -0.6 },
			{ 0, side * 90, 0 },
			rgb(200, 40, 50),
			{ detail = true }
		)
	end
	local hy, fz = h.y, h.z
	k.eyes(hy + 0.15, fz, 0.46, 0.36, 0.36, glow, "cute")
	-- Thick glasses.
	for _, side in { -1, 1 } do
		local x = side * 0.46
		k.ink({ 0.66, 0.1, 0.08 }, { x, hy + 0.42, fz - 0.14 })
		k.ink({ 0.66, 0.1, 0.08 }, { x, hy - 0.12, fz - 0.14 })
		k.ink({ 0.1, 0.62, 0.08 }, { x - 0.3, hy + 0.15, fz - 0.14 })
		k.ink({ 0.1, 0.62, 0.08 }, { x + 0.3, hy + 0.15, fz - 0.14 })
	end
	k.ink({ 0.3, 0.08, 0.08 }, { 0, hy + 0.2, fz - 0.14 })
	k.ink({ 0.4, 0.08, 0.06 }, { 0, hy - 0.5, fz - 0.04 })
	-- Neat hair with a side part.
	local hair = rgb(96, 62, 38)
	k.box({ 2.1, 0.45, 1.85 }, { 0, h.top + 0.1, 0.05 }, nil, hair, { detail = true })
	k.box({ 2.1, 1.0, 0.4 }, { 0, hy + 0.35, 0.75 }, nil, hair, { detail = true })
	k.wedge({ 1.3, 0.35, 0.6 }, { -0.35, h.top + 0.2, -0.65 }, { 0, 180, -6 }, hair, { detail = true })
	return k.done()
end

function CraftedFreeks.Flexo()
	-- A gym buddy: a wide torso in a red tank top, bulging shoulders and arms, a flat-top,
	-- a thick moustache, fierce glowing orange eyes and its signature sweatband.
	local glow = rgb(255, 140, 40)
	local skin = rgb(220, 160, 112)
	local k, h = person({
		skin = skin,
		shirt = rgb(210, 44, 44),
		pants = rgb(44, 44, 58),
		shoes = rgb(30, 30, 34),
		accent = glow,
		torsoWidth = 2.3,
	})
	for _, side in { -1, 1 } do
		k.box({ 0.85, 0.7, 0.9 }, { side * 1.2, 3.05, 0 }, { 0, 0, side * -10 }, skin)
		k.box({ 0.7, 0.55, 0.7 }, { side * 1.5, 2.35, -0.05 }, nil, skin, { rig = "arm", side = side })
	end
	k.glow({ 1.8, 0.1, 0.08 }, { 0, 1.82, -0.54 }, nil, glow)
	local hy, fz = h.y, h.z
	k.eyes(hy + 0.15, fz, 0.48, 0.48, 0.32, glow, "fierce")
	k.box({ 1.1, 0.26, 0.16 }, { 0, hy - 0.3, fz - 0.08 }, nil, rgb(40, 30, 25), { detail = true })
	k.ink({ 0.6, 0.08, 0.06 }, { 0, hy - 0.58, fz - 0.04 })
	-- Flat-top hair and the sweatband.
	k.box({ 2.05, 0.6, 1.8 }, { 0, h.top + 0.25, 0.02 }, nil, rgb(40, 30, 25), { detail = true })
	k.box({ 2.12, 0.32, 1.87 }, { 0, h.top - 0.25, 0 }, nil, rgb(230, 50, 50), { detail = true })
	k.glow({ 2.14, 0.08, 1.89 }, { 0, h.top - 0.25, 0 }, nil, WHITE)
	return k.done()
end

function CraftedFreeks.Glamora()
	-- A glamorous star: a pink dress with a flared skirt of wedges, long golden hair with
	-- bangs, cute glowing magenta eyes with lashes, pink lips and its signature tiara with
	-- glowing gems.
	local glow = rgb(255, 80, 200)
	local k, h = person({
		skin = rgb(252, 218, 200),
		shirt = rgb(240, 110, 180),
		pants = rgb(250, 206, 190),
		shoes = rgb(240, 60, 150),
		accent = glow,
	})
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		k.wedge(
			{ 0.65, 0.9, 0.5 },
			{ math.cos(a) * 1.0, 1.45, math.sin(a) * 0.65 },
			{ 0, -math.deg(a) - 90, 0 },
			if i % 2 == 0 then rgb(240, 110, 180) else rgb(250, 150, 205)
		)
	end
	local hy, fz = h.y, h.z
	k.eyes(hy + 0.15, fz, 0.48, 0.42, 0.44, glow, "cute")
	for _, side in { -1, 1 } do
		k.ink({ 0.5, 0.08, 0.06 }, { side * 0.5, hy + 0.45, fz - 0.08 }, { 0, 0, side * -12 })
	end
	k.box({ 0.42, 0.14, 0.06 }, { 0, hy - 0.5, fz - 0.04 }, nil, rgb(230, 40, 110), { detail = true })
	-- Long golden hair: a big back, side locks and bangs.
	local gold = rgb(240, 196, 70)
	k.box({ 2.2, 0.45, 1.95 }, { 0, h.top + 0.1, 0.05 }, nil, gold, { detail = true })
	k.box({ 2.2, 2.4, 0.5 }, { 0, hy - 0.4, 0.85 }, nil, gold, { detail = true })
	for _, side in { -1, 1 } do
		k.box({ 0.4, 1.8, 0.6 }, { side * 1.1, hy - 0.4, -0.2 }, nil, gold, { detail = true })
		k.wedge(
			{ 0.9, 0.5, 0.3 },
			{ side * 0.5, h.top - 0.15, fz - 0.1 },
			{ 0, 180, side * 10 },
			gold,
			{ detail = true }
		)
	end
	-- Its signature tiara.
	k.box({ 1.4, 0.14, 0.12 }, { 0, h.top + 0.38, fz + 0.25 }, nil, GOLD, { material = "Metal", detail = true })
	for i, x in { -0.45, 0, 0.45 } do
		k.box({ 0.18, if i == 2 then 0.42 else 0.28, 0.1 }, { x, h.top + 0.6, fz + 0.25 }, { 0, 0, 45 }, glow, {
			material = "Neon",
			detail = true,
		})
	end
	return k.done({ { type = "Sparkles", part = 1, color = rgb(255, 170, 230) } })
end

function CraftedFreeks.BooBoo()
	-- A friendly ghost: a floating stack of pale blocks with a ragged hem, stubby arms, big
	-- glowing cyan eyes, an open mouth, and its signature witch hat with a glowing band.
	local k = kit()
	local ghost, shade = rgb(222, 230, 248), rgb(186, 198, 226)
	local glow = rgb(90, 230, 255)
	k.box({ 2.3, 1.9, 2.0 }, { 0, 2.9, 0 }, nil, ghost, { name = "Body" })
	k.box({ 2.5, 1.1, 2.2 }, { 0, 1.75, 0 }, nil, ghost)
	k.box({ 1.9, 0.5, 1.7 }, { 0, 4.05, 0 }, nil, shade)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		k.box(
			{ 0.6, 0.6, 0.5 },
			{ math.cos(a) * 1.0, 0.95 - (i % 2) * 0.2, math.sin(a) * 0.85 },
			{ 0, -math.deg(a), 0 },
			if i % 2 == 0 then ghost else shade
		)
	end
	for _, side in { -1, 1 } do
		k.box({ 0.55, 0.8, 0.6 }, { side * 1.4, 2.4, -0.2 }, { 0, 0, side * 30 }, ghost, {
			swing = { hinge = { side * 1.2, 2.7, -0.2 }, axis = "Z", amount = 0.7 },
		})
	end
	k.eyes(3.15, -1.0, 0.5, 0.52, 0.6, glow, "cute")
	k.ink({ 0.45, 0.45, 0.06 }, { 0, 2.35, -1.02 })
	k.box({ 0.6, 0.16, 0.06 }, { 0.7, 2.75, -1.04 }, nil, rgb(255, 170, 200), { detail = true })
	k.box({ 0.6, 0.16, 0.06 }, { -0.7, 2.75, -1.04 }, nil, rgb(255, 170, 200), { detail = true })
	-- Its signature witch hat.
	local hat = rgb(70, 40, 110)
	k.box({ 2.6, 0.16, 2.3 }, { 0, 4.35, 0 }, { 0, 0, -4 }, hat, { detail = true })
	for i, s in { 1.4, 1.05, 0.7, 0.38 } do
		k.box({ s, 0.48, s }, { 0.1 * i, 4.55 + i * 0.42, 0.05 * i }, { 0, 20 * i, -6 * i }, hat, { detail = true })
	end
	k.glow({ 1.44, 0.14, 1.44 }, { 0.1, 4.75, 0.05 }, { 0, 20, -6 }, rgb(255, 150, 40))
	return k.done({ { type = "Glow", part = 1, color = rgb(190, 220, 255), size = 8 } })
end

function CraftedFreeks.Zomboy()
	-- A zombie kid: green skin, a torn blue shirt, arms out in front, messy hair with a peek
	-- of brain, stitches, one glowing green eye and one droopy one, and its signature neck
	-- bolts with glowing tips.
	local glow = rgb(140, 255, 90)
	local skin = rgb(132, 186, 106)
	local k, h = person({
		skin = skin,
		shirt = rgb(76, 112, 176),
		pants = rgb(104, 78, 60),
		shoes = rgb(60, 50, 45),
		accent = glow,
		armsForward = true,
	})
	for i = 0, 3 do
		k.wedge({ 0.4, 0.4, 0.2 }, { -0.7 + i * 0.45, 1.75, -0.55 }, { 180, 0, 0 }, rgb(76, 112, 176))
	end
	local hy, fz = h.y, h.z
	-- One wide glowing eye, one droopy.
	k.glow({ 0.5, 0.5, 0.1 }, { -0.48, hy + 0.15, fz - 0.04 }, nil, glow)
	k.ink({ 0.16, 0.3, 0.06 }, { -0.48, hy + 0.15, fz - 0.1 })
	k.eyes(hy + 0.08, fz, 0.48, 0.38, 0.32, glow, "sleepy", skin)
	k.ink({ 0.8, 0.12, 0.06 }, { 0, hy - 0.52, fz - 0.04 }, { 0, 0, -8 })
	for i = 0, 2 do
		k.ink({ 0.06, 0.24, 0.06 }, { -0.25 + i * 0.25, hy - 0.52, fz - 0.06 })
	end
	k.ink({ 0.6, 0.06, 0.06 }, { 0.55, hy - 0.2, fz - 0.04 }, { 0, 0, 30 })
	-- Messy hair and a peek of brain.
	local hair = rgb(60, 45, 35)
	for _, tuft in { { -0.6, 0.2, -20 }, { -0.1, 0.3, 10 }, { 0.5, 0.15, 25 }, { 0, 0.1, 0 } } do
		k.wedge({ 0.6, 0.55, 1.6 }, { tuft[1], h.top + tuft[2], 0.1 }, { 0, 0, tuft[3] }, hair, { detail = true })
	end
	k.box({ 0.7, 0.4, 0.6 }, { 0.5, h.top + 0.1, -0.4 }, nil, rgb(255, 150, 170), { detail = true })
	-- Its signature neck bolts.
	for _, side in { -1, 1 } do
		k.box(
			{ 0.5, 0.22, 0.22 },
			{ side * 0.5, 3.3, 0 },
			nil,
			rgb(150, 150, 160),
			{ material = "Metal", detail = true }
		)
		k.glow({ 0.12, 0.26, 0.26 }, { side * 0.78, 3.3, 0 }, nil, glow)
	end
	return k.done()
end

function CraftedFreeks.Mumbles()
	-- A mummy: wrapped head to toe in bandage strips set every which way, arms out in front,
	-- one glowing cyan eye peeking out, and a loose end dangling down the back.
	local glow = rgb(90, 230, 255)
	local wrap, strip = rgb(232, 222, 192), rgb(198, 186, 152)
	local k, h = person({
		skin = wrap,
		shirt = wrap,
		pants = rgb(222, 212, 180),
		shoes = rgb(206, 194, 162),
		accent = glow,
		armsForward = true,
	})
	-- Strips wound round the body and head at angles.
	for i, spot in
		{
			{ 2.0, 8 },
			{ 2.5, -10 },
			{ 2.95, 6 },
			{ 1.5, -5 },
		}
	do
		k.box({ 1.95, 0.16, 1.12 }, { 0, spot[1], 0 }, { 0, 0, spot[2] }, if i % 2 == 0 then strip else wrap)
	end
	local hy, fz = h.y, h.z
	for i, spot in { { 0.55, -8 }, { 0.1, 12 }, { -0.35, -6 }, { -0.75, 9 } } do
		k.box({ 2.08, 0.22, 1.85 }, { 0, hy + spot[1], 0 }, { 0, 0, spot[2] }, if i % 2 == 0 then strip else wrap)
	end
	k.glow({ 0.4, 0.3, 0.1 }, { 0.45, hy + 0.12, fz - 0.06 }, nil, glow)
	k.ink({ 0.14, 0.24, 0.06 }, { 0.45, hy + 0.12, fz - 0.12 })
	k.ink({ 0.5, 0.14, 0.06 }, { -0.45, hy + 0.12, fz - 0.06 })
	-- A loose end dangling down the back.
	k.box({ 0.3, 1.4, 0.08 }, { 0.4, 2.6, 0.6 }, { 0, 0, 10 }, strip, {
		swing = { hinge = { 0.4, 3.3, 0.6 }, axis = "Z", amount = 0.4 },
	})
	return k.done()
end

function CraftedFreeks.CountFangula()
	-- A vampire: pale lavender skin, a black suit with a glowing red brooch, slicked hair with
	-- a widow's peak, fierce glowing red eyes, fangs, and its signature high-collared cape.
	local glow = rgb(255, 40, 60)
	local suit = rgb(34, 28, 44)
	local k, h = person({
		skin = rgb(222, 212, 238),
		shirt = suit,
		sleeves = suit,
		pants = suit,
		shoes = rgb(15, 15, 20),
		accent = glow,
	})
	k.box({ 0.6, 0.9, 0.08 }, { 0, 2.6, -0.56 }, nil, WHITE, { detail = true })
	k.glow({ 0.3, 0.3, 0.1 }, { 0, 3.0, -0.62 }, { 0, 0, 45 }, glow)
	local hy, fz = h.y, h.z
	k.eyes(hy + 0.12, fz, 0.46, 0.46, 0.32, glow, "fierce")
	k.ink({ 0.6, 0.08, 0.06 }, { 0, hy - 0.5, fz - 0.04 })
	for _, side in { -1, 1 } do
		k.wedge({ 0.12, 0.22, 0.08 }, { side * 0.18, hy - 0.62, fz - 0.06 }, { 180, 0, 0 }, WHITE, { detail = true })
	end
	-- Slicked hair with a widow's peak.
	local hair = rgb(20, 15, 25)
	k.box({ 2.1, 0.4, 1.9 }, { 0, h.top + 0.05, 0.05 }, nil, hair, { detail = true })
	k.box({ 2.1, 1.3, 0.4 }, { 0, hy + 0.25, 0.75 }, nil, hair, { detail = true })
	k.wedge({ 0.6, 0.5, 0.2 }, { 0, h.top - 0.25, fz - 0.05 }, { 180, 0, 0 }, hair, { detail = true })
	-- Its signature cape: a high collar and a long back, red inside.
	for _, side in { -1, 1 } do
		k.wedge({ 0.2, 1.2, 0.9 }, { side * 1.05, 3.6, 0.25 }, { 0, side * 90, side * -15 }, rgb(150, 20, 40), {
			detail = true,
			onHead = false,
		})
	end
	k.box({ 2.5, 3.0, 0.2 }, { 0, 2.0, 0.7 }, { -6, 0, 0 }, suit, { onHead = false })
	k.box({ 2.3, 2.8, 0.06 }, { 0, 2.05, 0.58 }, { -6, 0, 0 }, rgb(150, 20, 40), { detail = true, onHead = false })
	return k.done()
end

function CraftedFreeks.Howlz()
	-- A werewolf: brown fur, a torn purple shirt, a wolf head with a snout and pointy ears,
	-- fierce glowing yellow eyes, a fluffy tail and its signature spiked collar.
	local glow = rgb(255, 210, 50)
	local fur, light = rgb(120, 86, 62), rgb(196, 168, 138)
	local k, h = person({
		skin = fur,
		shirt = rgb(108, 60, 138),
		sleeves = fur,
		pants = rgb(60, 60, 80),
		shoes = fur,
		accent = glow,
	})
	for i = 0, 3 do
		k.wedge({ 0.42, 0.4, 0.2 }, { -0.7 + i * 0.45, 1.75, -0.55 }, { 180, 0, 0 }, rgb(108, 60, 138))
	end
	local hy, fz = h.y, h.z
	k.box({ 1.0, 0.7, 0.8 }, { 0, hy - 0.35, fz - 0.35 }, nil, light)
	k.ink({ 0.4, 0.26, 0.2 }, { 0, hy - 0.08, fz - 0.78 })
	k.ink({ 0.6, 0.08, 0.06 }, { 0, hy - 0.6, fz - 0.76 })
	k.eyes(hy + 0.25, fz, 0.5, 0.46, 0.3, glow, "fierce")
	for _, side in { -1, 1 } do
		k.wedge({ 0.3, 0.9, 0.7 }, { side * 0.7, h.top + 0.4, 0 }, { 0, 90, side * -12 }, fur, {
			rig = "ear",
			side = side,
			pivot = { side * 0.7, h.top, 0 },
		})
		k.box({ 0.35, 0.8, 0.9 }, { side * 1.05, hy - 0.35, -0.1 }, { 0, 0, side * 14 }, light)
	end
	-- Its signature spiked collar.
	k.box({ 1.0, 0.28, 0.95 }, { 0, 3.28, 0 }, nil, INK, { detail = true })
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		k.wedge(
			{ 0.16, 0.26, 0.16 },
			{ math.cos(a) * 0.55, 3.28, math.sin(a) * 0.52 },
			{ 0, 0, -math.deg(a) - 90 },
			rgb(200, 200, 210),
			{
				material = "Metal",
				detail = true,
			}
		)
	end
	-- A fluffy tail.
	for i, seg in { { 1.5, 0.75, 0.7 }, { 1.2, 1.25, 0.6 }, { 1.1, 1.7, 0.45 } } do
		k.box(
			{ seg[3], seg[3], 0.7 },
			{ 0, seg[1], 0.6 + i * 0.35 },
			{ -30 - i * 10, 0, 0 },
			if i == 3 then light else fur,
			{
				swing = { hinge = { 0, 1.6, 0.55 }, axis = "Y", amount = 0.7 },
			}
		)
	end
	return k.done()
end

return CraftedFreeks
