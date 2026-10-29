-- The crafted looks of the creatures (pets and guardians), like the owner's reference cat:
-- low-poly creatures built from many blocks and wedges, some set at angles, in a muted main
-- colour with one bright Neon accent (glowing eyes, toes, strips, gems), chunky and smooth,
-- with no LEGO studs (look.crafted marks the model "Crafted"; see Lego). Each keeps its
-- character (Golden Retriever, Tabby Cat, Unicorn, Alien...; the list is in Freeks.luau).
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

-- A tail of blocks that curls up from (0, y, z) and swishes side to side. segs =
-- { { y, z, tiltX, size } } from the base out; the last one is the tip colour.
local function tail(k, hinge, segs, color: Color3, tip: Color3?, amount: number?)
	for i, seg in segs do
		local size = seg[4] or 0.4
		k.box(
			{ size, size, 0.75 },
			{ 0, seg[1], seg[2] },
			{ seg[3], 0, 0 },
			if i == #segs and tip then tip else color,
			{
				swing = { hinge = hinge, axis = "Y", amount = amount or 0.8 },
			}
		)
	end
end

function CraftedFreeks.GoldenRetriever()
	-- A big friendly golden retriever: fluffy layered golden fur, a cream chest ruff and
	-- muzzle, long feathered ears, a black nose and pink tongue, glowing sky-blue eyes, a
	-- red collar with a glowing gold tag and a fluffy wagging tail.
	local k = kit()
	local fur, deep, cream = rgb(222, 162, 70), rgb(176, 118, 46), rgb(246, 222, 170)
	local glow = rgb(90, 210, 255)
	k.box({ 2.1, 1.55, 2.8 }, { 0, 1.9, 0.45 }, { -4, 0, 0 }, fur, { name = "Body" })
	k.box({ 1.9, 1.5, 0.9 }, { 0, 2.0, -0.85 }, { 10, 0, 0 }, cream)
	k.box({ 1.7, 0.35, 2.4 }, { 0, 2.72, 0.5 }, { -4, 0, 0 }, deep)
	-- Feathered fur hanging under the belly.
	for i, z in { -0.2, 0.5, 1.2 } do
		k.wedge({ 1.7, 0.4, 0.6 }, { 0, 1.05, z }, { 180, i * 10, 0 }, deep)
	end
	k.legs({ { -0.64, -0.55 }, { 0.64, -0.55 }, { -0.68, 1.45 }, { 0.68, 1.45 } }, 1.35, 0.6, { fur, cream, glow })
	local hy, hz = 3.45, -1.25
	k.box({ 2.0, 1.75, 1.8 }, { 0, hy, hz }, nil, fur, { name = "Head" })
	k.box({ 1.75, 0.3, 1.5 }, { 0, hy + 0.98, hz + 0.05 }, nil, deep)
	k.box({ 1.2, 0.7, 0.75 }, { 0, hy - 0.45, hz - 1.2 }, nil, cream)
	k.ink({ 0.46, 0.32, 0.24 }, { 0, hy - 0.14, hz - 1.56 })
	k.box({ 0.36, 0.5, 0.08 }, { 0.14, hy - 0.95, hz - 1.5 }, { 0, 0, -8 }, rgb(240, 110, 130), { detail = true })
	for _, side in { -1, 1 } do
		k.box({ 0.34, 1.45, 0.85 }, { side * 1.12, hy - 0.3, hz + 0.1 }, { 0, 0, side * 8 }, deep, {
			rig = "ear",
			side = side,
			pivot = { side * 1.0, hy + 0.5, hz + 0.1 },
		})
		k.wedge({ 0.34, 0.4, 0.85 }, { side * 1.2, hy - 1.15, hz + 0.1 }, { 180, 0, side * 8 }, deep, {
			rig = "ear",
			side = side,
			pivot = { side * 1.0, hy + 0.5, hz + 0.1 },
		})
	end
	k.eyes(hy + 0.25, hz - 0.9, 0.5, 0.44, 0.44, glow, "cute")
	k.box({ 1.8, 0.26, 1.65 }, { 0, hy - 0.98, hz + 0.15 }, nil, rgb(205, 40, 50), { detail = true })
	k.box({ 0.4, 0.4, 0.12 }, { 0, hy - 1.28, hz - 0.72 }, { 0, 0, 45 }, GOLD, { material = "Metal", detail = true })
	k.glow({ 0.2, 0.2, 0.06 }, { 0, hy - 1.28, hz - 0.8 }, { 0, 0, 45 }, glow)
	tail(
		k,
		{ 0, 2.5, 1.7 },
		{ { 2.6, 1.9, -40, 0.5 }, { 3.05, 2.2, -60, 0.5 }, { 3.5, 2.35, -80, 0.45 } },
		fur,
		cream,
		1
	)
	return k.done()
end

function CraftedFreeks.TabbyCat()
	-- An orange tabby: a dusty-orange body with darker stripes, a cream chest and muzzle,
	-- big cute glowing green eyes, glowing whiskers, pointy ears with glowing insides, a
	-- collar with a gold bell and a striped tail curling up.
	local k = kit()
	local fur, dark, light = rgb(226, 138, 62), rgb(170, 92, 40), rgb(246, 214, 168)
	local glow = rgb(120, 255, 120)
	k.box({ 2.0, 1.4, 2.6 }, { 0, 1.6, 0.5 }, { -6, 0, 0 }, fur, { name = "Body" })
	k.box({ 1.8, 1.5, 0.9 }, { 0, 1.8, -0.75 }, { 8, 0, 0 }, light)
	for _, z in { -0.1, 0.55, 1.2 } do
		k.box({ 2.08, 0.26, 0.3 }, { 0, 2.05, z }, { -6, 0, 0 }, dark)
	end
	k.legs({ { -0.62, -0.5 }, { 0.62, -0.5 }, { -0.66, 1.35 }, { 0.66, 1.35 } }, 1.1, 0.56, { fur, light, glow })
	local hy, hz = 3.2, -1.15
	k.box({ 2.2, 1.7, 1.75 }, { 0, hy, hz }, nil, fur, { name = "Head" })
	k.box({ 1.9, 0.32, 1.55 }, { 0, hy + 0.95, hz + 0.05 }, nil, dark)
	for _, x in { -0.4, 0, 0.4 } do
		k.box({ 0.18, 0.5, 0.06 }, { x, hy + 0.55, hz - 0.9 }, nil, dark, { detail = true })
	end
	k.box({ 1.2, 0.6, 0.5 }, { 0, hy - 0.5, hz - 1.0 }, nil, light)
	k.box({ 0.38, 0.24, 0.14 }, { 0, hy - 0.24, hz - 1.3 }, nil, rgb(240, 120, 140), { detail = true })
	for _, side in { -1, 1 } do
		k.wedge({ 0.32, 0.9, 0.7 }, { side * 0.7, hy + 1.35, hz + 0.1 }, { 0, 90, side * -14 }, fur, {
			rig = "ear",
			side = side,
			pivot = { side * 0.7, hy + 0.95, hz + 0.1 },
		})
		k.wedge({ 0.12, 0.55, 0.42 }, { side * 0.7, hy + 1.28, hz - 0.08 }, { 0, 90, side * -14 }, rgb(255, 160, 190), {
			detail = true,
		})
		for i, tilt in { -12, 0, 12 } do
			k.glow({ 1.0, 0.06, 0.08 }, { side * 1.0, hy - 0.4 + (i - 2) * 0.13, hz - 0.95 }, {
				0,
				side * 12,
				side * tilt,
			}, glow)
		end
	end
	k.eyes(hy + 0.2, hz - 0.86, 0.5, 0.52, 0.56, glow, "cute")
	k.box({ 1.9, 0.22, 1.7 }, { 0, hy - 0.92, hz + 0.1 }, nil, rgb(60, 120, 230), { detail = true })
	k.add({
		shape = "Ball",
		size = 0.42,
		pos = { 0, hy - 1.15, hz - 0.88 },
		color = GOLD,
		material = "Metal",
		detail = true,
	})
	tail(k, { 0, 1.8, 1.7 }, {
		{ 1.85, 1.95, -30, 0.4 },
		{ 2.35, 2.3, -55, 0.4 },
		{ 2.95, 2.45, -80, 0.4 },
		{ 3.5, 2.3, -110, 0.42 },
	}, fur, dark, 0.6)
	return k.done()
end

function CraftedFreeks.PetBunny()
	-- A fluffy white bunny: a round body of soft white blocks, tall ears with glowing pink
	-- insides, big cute glowing pink eyes, a twitchy pink nose, buck teeth, big back feet and
	-- a cotton tail.
	local k = kit()
	local fur, shade, pink = rgb(240, 238, 236), rgb(205, 200, 205), rgb(255, 150, 190)
	local glow = rgb(255, 110, 190)
	k.box({ 2.0, 1.7, 2.1 }, { 0, 1.3, 0.35 }, nil, fur, { name = "Body" })
	k.box({ 1.7, 0.35, 1.8 }, { 0, 2.2, 0.35 }, nil, shade)
	k.box({ 1.6, 1.3, 0.4 }, { 0, 1.3, -0.75 }, nil, rgb(252, 250, 248))
	for i, spot in { { -0.55, -0.6 }, { 0.55, -0.6 } } do
		local swing = { hinge = { spot[1], 0.7, spot[2] }, phase = (i - 1) * 0.5 }
		k.box({ 0.5, 0.7, 0.5 }, { spot[1], 0.35, spot[2] }, nil, fur, { swing = swing })
	end
	for i, side in { -1, 1 } do
		local swing = { hinge = { side * 0.8, 0.6, 0.9 }, phase = i * 0.5 }
		k.box({ 0.62, 0.45, 1.5 }, { side * 0.8, 0.22, 0.6 }, nil, shade, { swing = swing })
		k.glow({ 0.4, 0.08, 0.5 }, { side * 0.8, 0.05, 0.05 }, nil, glow, { swing = swing })
	end
	local hy, hz = 2.75, -0.7
	k.box({ 1.8, 1.5, 1.55 }, { 0, hy, hz }, nil, fur, { name = "Head" })
	k.box({ 0.95, 0.55, 0.4 }, { 0, hy - 0.4, hz - 0.85 }, nil, rgb(252, 250, 248))
	k.box({ 0.32, 0.22, 0.12 }, { 0, hy - 0.18, hz - 1.06 }, nil, pink, { detail = true })
	k.box({ 0.36, 0.3, 0.06 }, { 0, hy - 0.72, hz - 1.04 }, nil, WHITE, { detail = true })
	k.ink({ 0.04, 0.3, 0.07 }, { 0, hy - 0.72, hz - 1.08 })
	for _, side in { -1, 1 } do
		local ear = { rig = "ear", side = side, pivot = { side * 0.45, hy + 0.7, hz + 0.1 } }
		k.box({ 0.5, 1.9, 0.3 }, { side * 0.48, hy + 1.65, hz + 0.15 }, { 0, 0, side * -8 }, fur, ear)
		k.glow({ 0.26, 1.5, 0.05 }, { side * 0.48, hy + 1.65, hz - 0.02 }, { 0, 0, side * -8 }, glow, ear)
		k.box({ 0.42, 0.42, 0.42 }, { side * 0.48, hy + 2.7, hz + 0.15 }, { 0, 0, side * -8 }, shade, ear)
	end
	k.eyes(hy + 0.15, hz - 0.8, 0.45, 0.42, 0.5, glow, "cute")
	k.box({ 0.8, 0.8, 0.8 }, { 0, 1.5, 1.5 }, { 20, 20, 0 }, WHITE, {
		swing = { hinge = { 0, 1.4, 1.3 }, axis = "Y", amount = 0.6 },
	})
	return k.done()
end

function CraftedFreeks.BeachCrab()
	-- A chunky red beach crab: a wide shell of layered plates with glowing orange seams, eyes
	-- on stalks, six walking legs and two big snapping claws, and a tiny sailor hat.
	local k = kit()
	local shell, deep, belly = rgb(220, 70, 50), rgb(160, 40, 34), rgb(250, 190, 150)
	local glow = rgb(255, 170, 40)
	k.box({ 3.2, 1.0, 2.4 }, { 0, 1.45, 0.2 }, nil, shell, { name = "Body" })
	k.box({ 2.6, 0.45, 2.0 }, { 0, 2.1, 0.2 }, nil, deep)
	k.box({ 2.8, 0.3, 2.0 }, { 0, 0.9, 0.2 }, nil, belly)
	for _, x in { -0.9, 0, 0.9 } do
		k.glow({ 0.08, 0.06, 2.1 }, { x, 2.34, 0.2 }, nil, glow)
	end
	for i, z in { -0.5, 0.2, 0.9 } do
		for _, side in { -1, 1 } do
			local swing = { hinge = { side * 1.5, 1.2, z }, axis = "Z", phase = (i + side) % 2 * 0.5, amount = 0.6 }
			k.box({ 1.1, 0.25, 0.3 }, { side * 2.0, 1.25, z }, { 0, 0, side * -25 }, shell, { swing = swing })
			k.box({ 0.25, 1.0, 0.3 }, { side * 2.5, 0.55, z }, { 0, 0, side * 12 }, deep, { swing = swing })
			k.glow({ 0.2, 0.12, 0.2 }, { side * 2.6, 0.06, z }, nil, glow, { swing = swing })
		end
	end
	-- Claws: an arm and a two-part pincer.
	for _, side in { -1, 1 } do
		local arm = { rig = "arm", side = side, swing = { hinge = { side * 1.3, 1.5, -0.8 }, amount = 0.5 } }
		k.box({ 0.4, 0.4, 1.2 }, { side * 1.6, 1.6, -1.3 }, { 0, side * -20, 0 }, shell, arm)
		k.box({ 1.1, 0.9, 1.0 }, { side * 1.95, 1.75, -2.1 }, { 0, side * -15, 0 }, shell, arm)
		k.wedge({ 0.5, 0.7, 0.9 }, { side * 2.15, 2.15, -2.8 }, { 0, side * -15, 0 }, deep, arm)
		k.wedge({ 0.5, 0.5, 0.8 }, { side * 2.15, 1.45, -2.75 }, { 180, side * 15, 0 }, deep, arm)
		k.glow({ 0.1, 0.5, 0.1 }, { side * 2.15, 1.8, -3.0 }, nil, glow, arm)
	end
	-- Eye stalks (the head part, so the eyes look around).
	k.box({ 1.4, 0.4, 0.5 }, { 0, 2.3, -0.75 }, nil, shell, { name = "Head" })
	for _, side in { -1, 1 } do
		k.box({ 0.22, 0.9, 0.22 }, { side * 0.45, 2.75, -0.8 }, nil, shell)
		k.box({ 0.55, 0.55, 0.5 }, { side * 0.45, 3.35, -0.8 }, nil, WHITE)
		k.glow({ 0.34, 0.34, 0.06 }, { side * 0.45, 3.35, -1.06 }, nil, glow)
		k.ink({ 0.16, 0.2, 0.05 }, { side * 0.45, 3.33, -1.1 })
	end
	k.ink({ 0.7, 0.1, 0.06 }, { 0, 1.55, -1.02 })
	-- A tiny sailor hat.
	k.box({ 0.9, 0.3, 0.7 }, { 0, 2.5, 0.25 }, { 0, 0, -10 }, WHITE, { detail = true })
	k.box({ 0.95, 0.1, 0.75 }, { 0, 2.4, 0.25 }, { 0, 0, -10 }, rgb(60, 120, 230), { detail = true })
	return k.done()
end

function CraftedFreeks.BrownBear()
	-- A big brown bear: a hulking body with a shoulder hump, shaggy layered fur, a cream
	-- muzzle and belly, round ears, glowing amber eyes, chunky paws with glowing claws and a
	-- stubby tail.
	local k = kit()
	local fur, deep, cream = rgb(120, 78, 46), rgb(86, 54, 32), rgb(214, 176, 128)
	local glow = rgb(255, 180, 50)
	k.box({ 2.6, 1.9, 3.2 }, { 0, 2.1, 0.5 }, nil, fur, { name = "Body" })
	k.box({ 2.4, 0.7, 1.4 }, { 0, 3.15, -0.4 }, { 8, 0, 0 }, deep)
	k.box({ 2.0, 0.9, 2.4 }, { 0, 1.3, 0.5 }, nil, cream)
	for i, z in { -0.6, 0.4, 1.4 } do
		k.wedge({ 2.7, 0.45, 0.6 }, { 0, 2.8 - i * 0.05, z }, { 0, 0, 0 }, deep)
	end
	k.legs({ { -0.8, -0.6 }, { 0.8, -0.6 }, { -0.85, 1.6 }, { 0.85, 1.6 } }, 1.5, 0.85, { fur, deep, glow })
	local hy, hz = 3.4, -1.55
	k.box({ 2.2, 1.8, 1.7 }, { 0, hy, hz }, nil, fur, { name = "Head" })
	k.box({ 1.9, 0.35, 1.4 }, { 0, hy + 1.0, hz + 0.05 }, nil, deep)
	k.box({ 1.2, 0.8, 0.8 }, { 0, hy - 0.45, hz - 1.15 }, nil, cream)
	k.ink({ 0.5, 0.35, 0.2 }, { 0, hy - 0.15, hz - 1.56 })
	k.ink({ 0.5, 0.08, 0.06 }, { 0, hy - 0.68, hz - 1.56 })
	for _, side in { -1, 1 } do
		k.box({ 0.6, 0.6, 0.4 }, { side * 0.85, hy + 1.1, hz + 0.1 }, nil, fur, {
			rig = "ear",
			side = side,
			pivot = { side * 0.85, hy + 0.85, hz + 0.1 },
		})
		k.box({ 0.36, 0.36, 0.1 }, { side * 0.85, hy + 1.1, hz - 0.12 }, nil, cream, { detail = true })
	end
	k.eyes(hy + 0.3, hz - 0.86, 0.55, 0.4, 0.38, glow, "fierce")
	k.box({ 0.5, 0.5, 0.5 }, { 0, 2.6, 2.15 }, { 20, 0, 0 }, deep, {
		swing = { hinge = { 0, 2.5, 2.0 }, axis = "Y", amount = 0.4 },
	})
	return k.done()
end

function CraftedFreeks.RedFox()
	-- A sly red fox: a slim orange body, white chest and cheeks, black socks, tall pointed
	-- ears with black tips, a narrow snout, cute glowing gold eyes and a huge bushy tail with
	-- a white tip.
	local k = kit()
	local fur, deep, white = rgb(232, 112, 40), rgb(178, 74, 26), rgb(250, 244, 236)
	local glow = rgb(255, 210, 60)
	k.box({ 1.7, 1.25, 2.7 }, { 0, 1.75, 0.45 }, { -5, 0, 0 }, fur, { name = "Body" })
	k.box({ 1.5, 1.2, 0.8 }, { 0, 1.85, -0.85 }, { 10, 0, 0 }, white)
	k.box({ 1.4, 0.3, 2.2 }, { 0, 2.4, 0.5 }, { -5, 0, 0 }, deep)
	k.legs({ { -0.5, -0.5 }, { 0.5, -0.5 }, { -0.52, 1.4 }, { 0.52, 1.4 } }, 1.3, 0.46, { INK, INK, glow })
	local hy, hz = 3.2, -1.15
	k.box({ 1.75, 1.45, 1.5 }, { 0, hy, hz }, nil, fur, { name = "Head" })
	k.box({ 0.85, 0.55, 1.0 }, { 0, hy - 0.4, hz - 1.1 }, nil, fur)
	k.box({ 0.9, 0.3, 0.95 }, { 0, hy - 0.62, hz - 1.05 }, nil, white)
	k.ink({ 0.3, 0.24, 0.16 }, { 0, hy - 0.25, hz - 1.62 })
	for _, side in { -1, 1 } do
		k.box({ 0.45, 0.6, 0.7 }, { side * 0.85, hy - 0.4, hz - 0.3 }, { 0, 0, side * 15 }, white)
		local ear = { rig = "ear", side = side, pivot = { side * 0.55, hy + 0.7, hz + 0.1 } }
		k.wedge({ 0.3, 1.0, 0.75 }, { side * 0.55, hy + 1.2, hz + 0.1 }, { 0, 90, side * -10 }, fur, ear)
		k.wedge({ 0.32, 0.35, 0.3 }, { side * 0.55, hy + 1.6, hz + 0.1 }, { 0, 90, side * -10 }, INK, ear)
	end
	k.eyes(hy + 0.15, hz - 0.78, 0.4, 0.4, 0.42, glow, "cute")
	-- The big bushy tail.
	for i, seg in
		{ { 1.9, 1.95, -20, 0.7 }, { 2.3, 2.55, -35, 0.95 }, { 2.85, 3.05, -55, 0.9 }, { 3.4, 3.3, -75, 0.7 } }
	do
		k.box({ seg[4], seg[4], 0.85 }, { 0, seg[1], seg[2] }, { seg[3], 0, 0 }, if i == 4 then white else fur, {
			swing = { hinge = { 0, 1.8, 1.7 }, axis = "Y", amount = 0.6 },
		})
	end
	return k.done()
end

function CraftedFreeks.BabyDeer()
	-- A baby deer (fawn): a tan body with white spots, long slim legs, big ears, a white
	-- tail, little glowing antler buds and huge cute glowing eyes.
	local k = kit()
	local fur, deep, white = rgb(196, 132, 78), rgb(150, 96, 52), rgb(250, 242, 228)
	local glow = rgb(140, 255, 170)
	k.box({ 1.6, 1.2, 2.5 }, { 0, 2.3, 0.45 }, nil, fur, { name = "Body" })
	k.box({ 1.4, 0.25, 2.2 }, { 0, 2.95, 0.45 }, nil, deep)
	for _, spot in { { -0.5, 0.0 }, { 0.4, 0.6 }, { -0.3, 1.1 }, { 0.55, -0.2 }, { 0.0, 0.35 } } do
		k.box({ 0.24, 0.06, 0.24 }, { spot[1], 3.09, spot[2] + 0.45 }, nil, white, { detail = true })
	end
	k.legs({ { -0.45, -0.4 }, { 0.45, -0.4 }, { -0.45, 1.3 }, { 0.45, 1.3 } }, 1.9, 0.36, { fur, INK, glow })
	local hy, hz = 3.85, -1.1
	k.box({ 0.6, 1.0, 0.6 }, { 0, 3.15, -0.75 }, { -25, 0, 0 }, fur)
	k.box({ 1.5, 1.3, 1.35 }, { 0, hy, hz }, nil, fur, { name = "Head" })
	k.box({ 0.8, 0.55, 0.75 }, { 0, hy - 0.4, hz - 0.9 }, nil, white)
	k.ink({ 0.32, 0.22, 0.12 }, { 0, hy - 0.22, hz - 1.3 })
	for _, side in { -1, 1 } do
		local ear = { rig = "ear", side = side, pivot = { side * 0.7, hy + 0.45, hz + 0.1 } }
		k.box({ 1.0, 0.4, 0.22 }, { side * 1.15, hy + 0.55, hz + 0.1 }, { 0, 0, side * 25 }, fur, ear)
		k.box({ 0.7, 0.24, 0.06 }, { side * 1.15, hy + 0.55, hz - 0.03 }, { 0, 0, side * 25 }, rgb(255, 180, 190), ear)
		k.box({ 0.16, 0.5, 0.16 }, { side * 0.35, hy + 0.85, hz + 0.1 }, { 0, 0, side * -15 }, deep)
		k.glow({ 0.2, 0.2, 0.2 }, { side * 0.42, hy + 1.12, hz + 0.1 }, nil, glow)
	end
	k.eyes(hy + 0.15, hz - 0.7, 0.4, 0.42, 0.5, glow, "cute")
	k.box({ 0.4, 0.55, 0.3 }, { 0, 2.65, 1.8 }, { -30, 0, 0 }, white, {
		swing = { hinge = { 0, 2.8, 1.7 }, axis = "Y", amount = 0.8 },
	})
	return k.done()
end

function CraftedFreeks.WhiteTiger()
	-- A rare white tiger: a powerful white body with bold black stripes, an icy-blue glow on
	-- its eyes, toes and spine, a chunky head with a white muzzle and pink nose, round ears
	-- and a long striped tail.
	local k = kit()
	local fur, shade, stripe = rgb(240, 240, 244), rgb(200, 205, 214), rgb(34, 30, 38)
	local glow = rgb(90, 200, 255)
	k.box({ 2.3, 1.6, 3.2 }, { 0, 2.0, 0.55 }, { -4, 0, 0 }, fur, { name = "Body" })
	k.box({ 2.0, 1.5, 0.9 }, { 0, 2.05, -0.95 }, { 10, 0, 0 }, shade)
	for i, z in { -0.4, 0.3, 1.0, 1.7 } do
		for _, side in { -1, 1 } do
			k.box({ 0.12, 1.1, 0.26 }, { side * 1.16, 2.1, z }, { i * 5, 0, side * 6 }, stripe, { detail = true })
		end
		k.box({ 1.5, 0.08, 0.24 }, { 0, 2.82, z }, { -4, 0, 0 }, stripe, { detail = true })
	end
	k.glow({ 0.14, 0.06, 2.6 }, { 0, 2.88, 0.6 }, { -4, 0, 0 }, glow)
	k.legs({ { -0.72, -0.65 }, { 0.72, -0.65 }, { -0.76, 1.6 }, { 0.76, 1.6 } }, 1.4, 0.68, { fur, shade, glow })
	local hy, hz = 3.5, -1.45
	k.box({ 2.3, 1.8, 1.8 }, { 0, hy, hz }, nil, fur, { name = "Head" })
	for _, x in { -0.5, 0, 0.5 } do
		k.box({ 0.14, 0.55, 0.06 }, { x, hy + 0.6, hz - 0.92 }, nil, stripe, { detail = true })
	end
	k.box({ 1.3, 0.7, 0.55 }, { 0, hy - 0.5, hz - 1.1 }, nil, WHITE)
	k.box({ 0.42, 0.26, 0.14 }, { 0, hy - 0.2, hz - 1.4 }, nil, rgb(240, 130, 150), { detail = true })
	for _, side in { -1, 1 } do
		k.box({ 0.55, 0.55, 0.35 }, { side * 0.85, hy + 1.05, hz + 0.1 }, nil, fur, {
			rig = "ear",
			side = side,
			pivot = { side * 0.85, hy + 0.8, hz + 0.1 },
		})
		k.box({ 0.12, 0.6, 0.06 }, { side * 1.16, hy - 0.1, hz - 0.6 }, { 0, 0, side * 20 }, stripe, { detail = true })
	end
	k.eyes(hy + 0.2, hz - 0.92, 0.52, 0.5, 0.4, glow, "fierce")
	tail(k, { 0, 2.3, 2.0 }, {
		{ 2.3, 2.3, -20, 0.42 },
		{ 2.6, 2.9, -35, 0.42 },
		{ 3.1, 3.3, -60, 0.4 },
		{ 3.65, 3.45, -85, 0.38 },
	}, fur, stripe, 0.7)
	return k.done()
end

function CraftedFreeks.BabyDragon()
	-- A baby dragon: a chubby teal body with a cream belly of plates, glowing orange spikes
	-- down its back, little horns, cute glowing eyes, flapping bat wings with glowing
	-- edges, short legs with claws and a tail with an arrow tip.
	local k = kit()
	local scale, deep, belly = rgb(60, 170, 160), rgb(36, 118, 120), rgb(250, 220, 160)
	local glow = rgb(255, 140, 40)
	k.box({ 2.2, 1.9, 2.4 }, { 0, 1.75, 0.4 }, nil, scale, { name = "Body" })
	for i, y in { 1.2, 1.7, 2.2 } do
		k.box({ 1.5 - i * 0.15, 0.4, 0.3 }, { 0, y, -0.85 }, nil, belly)
	end
	for i, z in { -0.4, 0.3, 1.0, 1.6 } do
		k.wedge({ 0.25, 0.6 - i * 0.05, 0.5 }, { 0, 2.95, z }, nil, glow, { material = "Neon", detail = true })
	end
	k.legs({ { -0.7, -0.45 }, { 0.7, -0.45 }, { -0.7, 1.2 }, { 0.7, 1.2 } }, 0.9, 0.62, { scale, deep, glow })
	for _, side in { -1, 1 } do
		local wing = { swing = { hinge = { side * 1.0, 2.6, 0.5 }, axis = "Z", amount = 1.1 } }
		k.box({ 1.8, 0.15, 1.2 }, { side * 1.9, 3.0, 0.5 }, { 0, 0, side * 25 }, deep, wing)
		k.wedge({ 0.15, 1.6, 1.4 }, { side * 2.5, 2.4, 0.6 }, { 0, 0, side * 25 }, deep, wing)
		k.glow({ 1.9, 0.08, 0.1 }, { side * 1.95, 3.1, -0.1 }, { 0, 0, side * 25 }, glow, wing)
	end
	local hy, hz = 3.35, -0.95
	k.box({ 1.9, 1.6, 1.7 }, { 0, hy, hz }, nil, scale, { name = "Head" })
	k.box({ 1.3, 0.7, 0.8 }, { 0, hy - 0.4, hz - 1.1 }, nil, scale)
	k.box({ 1.1, 0.25, 0.7 }, { 0, hy - 0.68, hz - 1.1 }, nil, belly)
	for _, side in { -1, 1 } do
		k.ink({ 0.12, 0.12, 0.06 }, { side * 0.3, hy - 0.2, hz - 1.52 })
		k.wedge({ 0.3, 0.8, 0.5 }, { side * 0.55, hy + 1.1, hz + 0.3 }, { -20, 0, side * -15 }, belly, {
			rig = "ear",
			side = side,
			pivot = { side * 0.55, hy + 0.8, hz + 0.3 },
		})
	end
	k.eyes(hy + 0.25, hz - 0.88, 0.45, 0.42, 0.48, glow, "cute")
	for i, seg in { { 1.3, 1.9, -10 }, { 1.0, 2.6, -5 }, { 0.75, 3.25, 0 } } do
		k.box({ 0.7 - i * 0.15, 0.6 - i * 0.12, 0.8 }, { 0, seg[1], seg[2] }, { seg[3], 0, 0 }, scale, {
			swing = { hinge = { 0, 1.4, 1.6 }, axis = "Y", amount = 0.7 },
		})
	end
	k.wedge({ 0.15, 0.6, 0.6 }, { 0, 0.85, 3.75 }, { 0, 0, 0 }, glow, {
		material = "Neon",
		swing = { hinge = { 0, 1.4, 1.6 }, axis = "Y", amount = 0.7 },
	})
	return k.done()
end

function CraftedFreeks.Unicorn()
	-- A unicorn: a white pony with a flowing rainbow mane and tail, a golden spiral horn with
	-- a glowing tip, gold hooves, cute glowing pink eyes and a sparkly star on its flank.
	local k = kit()
	local fur, shade = rgb(250, 248, 252), rgb(220, 210, 236)
	local glow = rgb(255, 120, 220)
	local rainbow = {
		rgb(255, 90, 110),
		rgb(255, 170, 60),
		rgb(255, 230, 80),
		rgb(110, 220, 120),
		rgb(90, 170, 255),
		rgb(170, 110, 255),
	}
	k.box({ 1.9, 1.5, 3.0 }, { 0, 2.55, 0.5 }, nil, fur, { name = "Body" })
	k.box({ 1.7, 0.3, 2.6 }, { 0, 1.75, 0.5 }, nil, shade)
	k.glow({ 0.06, 0.5, 0.5 }, { 0.97, 2.6, 1.2 }, { 45, 0, 0 }, rgb(255, 220, 90))
	k.legs({ { -0.55, -0.6 }, { 0.55, -0.6 }, { -0.55, 1.6 }, { 0.55, 1.6 } }, 1.85, 0.48, { fur, GOLD, glow })
	k.box({ 0.9, 1.5, 0.9 }, { 0, 3.5, -0.85 }, { -25, 0, 0 }, fur)
	local hy, hz = 4.35, -1.4
	k.box({ 1.4, 1.4, 1.7 }, { 0, hy, hz }, nil, fur, { name = "Head" })
	k.box({ 1.0, 0.8, 1.1 }, { 0, hy - 0.4, hz - 1.3 }, nil, fur)
	k.box({ 0.95, 0.3, 1.0 }, { 0, hy - 0.72, hz - 1.3 }, nil, shade)
	for _, side in { -1, 1 } do
		k.ink({ 0.1, 0.2, 0.06 }, { side * 0.25, hy - 0.35, hz - 1.87 })
		k.wedge({ 0.25, 0.6, 0.4 }, { side * 0.45, hy + 0.95, hz + 0.3 }, { 0, 90, side * -10 }, fur, {
			rig = "ear",
			side = side,
			pivot = { side * 0.45, hy + 0.7, hz + 0.3 },
		})
	end
	k.eyes(hy + 0.15, hz - 0.88, 0.4, 0.38, 0.46, rgb(170, 110, 255), "cute")
	-- The horn: stacked gold blocks, each turned a little, and a glowing tip.
	for i = 0, 3 do
		local s = 0.42 - i * 0.08
		k.box({ s, 0.35, s }, { 0, hy + 0.85 + i * 0.32, hz - 0.45 - i * 0.08 }, { -15, i * 30, 0 }, GOLD, {
			material = "Metal",
			detail = true,
		})
	end
	k.glow({ 0.14, 0.3, 0.14 }, { 0, hy + 2.15, hz - 0.8 }, { -15, 0, 0 }, rgb(255, 255, 200))
	-- The rainbow mane down the back of the neck (sticking out so it shows), a rainbow
	-- forelock, and the rainbow tail.
	for i, c in rainbow do
		k.box({ 0.55, 0.55, 0.6 }, { 0, hy + 0.75 - i * 0.3, hz + 0.95 + i * 0.17 }, { -20, 0, 0 }, c, {
			detail = true,
		})
		k.box({ 0.45, 0.55, 0.45 }, { 0, 3.15 - i * 0.3, 2.15 + i * 0.14 }, { 25, 0, 0 }, c, {
			detail = true,
			swing = { hinge = { 0, 3.0, 2.0 }, axis = "Y", amount = 0.5 },
		})
	end
	for i, c in { rainbow[1], rainbow[3], rainbow[5] } do
		k.box({ 0.3, 0.45, 0.3 }, { (i - 2) * 0.22, hy + 0.65, hz - 0.75 }, { 15, 0, (i - 2) * -15 }, c, {
			detail = true,
		})
	end
	return k.done()
end

function CraftedFreeks.RainbowPhoenix()
	-- A rainbow phoenix: a proud bird of flame-coloured feathers, a golden beak, glowing gold
	-- eyes, a crest of glowing plumes, huge flapping wings of rainbow layers and a long
	-- trailing rainbow tail.
	local k = kit()
	local body = rgb(255, 120, 60)
	local glow = rgb(255, 220, 80)
	local rainbow = {
		rgb(255, 70, 90),
		rgb(255, 150, 40),
		rgb(255, 225, 50),
		rgb(80, 220, 100),
		rgb(60, 170, 255),
		rgb(150, 90, 255),
	}
	k.box({ 1.8, 2.0, 2.0 }, { 0, 2.3, 0.3 }, { -15, 0, 0 }, body, { name = "Body" })
	k.box({ 1.4, 1.5, 0.4 }, { 0, 2.2, -0.65 }, { -15, 0, 0 }, rgb(255, 200, 90))
	for _, side in { -1, 1 } do
		k.box({ 0.25, 1.0, 0.25 }, { side * 0.4, 0.75, 0.3 }, nil, GOLD, {
			material = "Metal",
			swing = { hinge = { side * 0.4, 1.3, 0.3 }, phase = if side < 0 then 0 else 0.5 },
		})
		k.box({ 0.6, 0.15, 0.7 }, { side * 0.4, 0.1, 0.15 }, nil, GOLD, {
			material = "Metal",
			swing = { hinge = { side * 0.4, 1.3, 0.3 }, phase = if side < 0 then 0 else 0.5 },
		})
		-- Wings: rows of rainbow feathers raised in a V, longest at the top.
		for i, c in rainbow do
			k.box(
				{ 2.8 - i * 0.25, 0.16, 0.7 },
				{ side * (1.7 - i * 0.05), 3.7 - i * 0.28, 0.2 + i * 0.1 },
				{
					0,
					0,
					side * 38,
				},
				c,
				{
					material = if i % 2 == 0 then "Neon" else nil,
					swing = { hinge = { side * 0.8, 3.0, 0.3 }, axis = "Z", amount = 1.2 },
				}
			)
		end
	end
	local hy, hz = 3.75, -0.7
	k.box({ 1.4, 1.3, 1.3 }, { 0, hy, hz }, nil, body, { name = "Head" })
	k.wedge({ 0.5, 0.5, 0.7 }, { 0, hy - 0.2, hz - 0.95 }, { 180, 0, 0 }, GOLD, { material = "Metal", detail = true })
	k.eyes(hy + 0.15, hz - 0.66, 0.35, 0.34, 0.34, glow, "fierce")
	for i, c in { rgb(255, 225, 50), rgb(255, 150, 40), rgb(255, 70, 90) } do
		k.wedge({ 0.18, 0.9 - i * 0.15, 0.5 }, { 0, hy + 0.95, hz + (i - 2) * 0.35 }, { -25, 0, 0 }, c, {
			material = "Neon",
			detail = true,
		})
	end
	for i, c in rainbow do
		k.box({ 0.35, 0.12, 1.6 }, { (i - 3.5) * 0.18, 1.3 - i * 0.04, 2.0 + i * 0.12 }, { 30, (i - 3.5) * 6, 0 }, c, {
			material = if i % 2 == 1 then "Neon" else nil,
			swing = { hinge = { 0, 1.6, 1.0 }, axis = "Y", amount = 0.4 },
		})
	end
	return k.done({ { type = "Sparkles", color = glow } })
end

--------------------------------------------------------------------------------
-- Robots, aliens and the gnome
--------------------------------------------------------------------------------

function CraftedFreeks.RobotButler()
	-- A robot butler: a polished silver body in a black tuxedo with a bow tie and glowing
	-- buttons, a screen face with glowing blue eyes and a smile, an antenna, and a tray held
	-- out with a glowing drink.
	local glow = rgb(90, 200, 255)
	local metal = rgb(196, 202, 212)
	local k, head = person({
		skin = metal,
		shirt = rgb(40, 40, 48),
		pants = rgb(40, 40, 48),
		shoes = rgb(30, 30, 36),
		sleeves = rgb(40, 40, 48),
		accent = glow,
		head = { 2.0, 1.6, 1.6 },
	})
	k.box({ 0.8, 1.3, 0.08 }, { 0, 2.4, -0.56 }, nil, WHITE, { detail = true })
	for _, y in { 2.2, 2.55, 2.9 } do
		k.glow({ 0.16, 0.16, 0.06 }, { 0, y, -0.62 }, nil, glow)
	end
	for _, side in { -1, 1 } do
		k.wedge({ 0.4, 0.3, 0.12 }, { side * 0.22, 3.05, -0.6 }, { 0, 0, side * 90 }, rgb(200, 30, 40), {
			detail = true,
		})
	end
	k.box({ 1.7, 1.2, 0.08 }, { 0, head.y, head.z - 0.04 }, nil, rgb(20, 24, 34), { detail = true })
	k.eyes(head.y + 0.15, head.z - 0.06, 0.4, 0.42, 0.42, glow, "cute")
	k.glow({ 0.7, 0.1, 0.06 }, { 0, head.y - 0.35, head.z - 0.1 }, nil, glow)
	k.box({ 0.12, 0.7, 0.12 }, { 0, head.top + 0.35, 0 }, nil, metal, { material = "Metal" })
	k.glow({ 0.3, 0.3, 0.3 }, { 0, head.top + 0.8, 0 }, nil, rgb(255, 80, 80))
	-- The tray, held out on the right with a glowing drink.
	k.box({ 1.3, 0.1, 1.0 }, { 1.4, 2.15, -0.8 }, nil, rgb(220, 220, 228), { material = "Metal", detail = true })
	k.box({ 0.35, 0.6, 0.35 }, { 1.4, 2.5, -0.8 }, nil, rgb(200, 230, 255), { material = "Glass", detail = true })
	k.glow({ 0.25, 0.3, 0.25 }, { 1.4, 2.45, -0.8 }, nil, rgb(120, 255, 160))
	return k.done()
end

function CraftedFreeks.Alien()
	-- A little green alien: a big bulb head with huge glowing black-and-green eyes, two
	-- antennae with glowing tips, a silver jumpsuit with a glowing belt, and a ray gun.
	local glow = rgb(120, 255, 120)
	local skin = rgb(120, 210, 110)
	local k, head = person({
		skin = skin,
		shirt = rgb(180, 190, 205),
		pants = rgb(150, 160, 178),
		shoes = rgb(70, 70, 90),
		sleeves = rgb(180, 190, 205),
		accent = glow,
		torsoWidth = 1.5,
		head = { 2.4, 2.1, 2.0 },
	})
	k.glow({ 1.55, 0.18, 1.1 }, { 0, 1.75, 0 }, nil, glow)
	k.box({ 2.0, 0.6, 1.7 }, { 0, head.top - 0.1, 0 }, nil, skin)
	for _, side in { -1, 1 } do
		k.box({ 0.85, 0.65, 0.1 }, { side * 0.55, head.y, head.z - 0.04 }, { 0, 0, side * -15 }, INK, { detail = true })
		k.glow({ 0.3, 0.22, 0.06 }, { side * 0.6, head.y + 0.08, head.z - 0.1 }, { 0, 0, side * -15 }, glow)
		k.box({ 0.12, 0.9, 0.12 }, { side * 0.5, head.top + 0.6, 0 }, { 0, 0, side * -20 }, skin, {
			rig = "ear",
			side = side,
			pivot = { side * 0.5, head.top + 0.1, 0 },
		})
		k.glow({ 0.32, 0.32, 0.32 }, { side * 0.68, head.top + 1.1, 0 }, nil, glow, {
			rig = "ear",
			side = side,
			pivot = { side * 0.5, head.top + 0.1, 0 },
		})
	end
	k.ink({ 0.4, 0.08, 0.06 }, { 0, head.y - 0.65, head.z - 0.04 })
	-- A ray gun in the right hand.
	k.box({ 0.3, 0.35, 0.9 }, { 1.4, 1.6, -0.5 }, nil, rgb(200, 205, 215), { material = "Metal", detail = true })
	k.glow({ 0.2, 0.2, 0.2 }, { 1.4, 1.62, -1.0 }, nil, glow)
	return k.done()
end

function CraftedFreeks.AlienRobot()
	-- A big alien robot: a chunky purple armoured body on stubby legs, one wide glowing
	-- visor eye, glowing circuit lines, shoulder pads, claw hands and a dish antenna.
	local k = kit()
	local armour, deep = rgb(110, 80, 170), rgb(70, 50, 120)
	local glow = rgb(80, 255, 220)
	k.box({ 2.6, 2.2, 1.9 }, { 0, 2.6, 0 }, nil, armour, { name = "Body" })
	k.box({ 2.2, 0.5, 1.6 }, { 0, 1.35, 0 }, nil, deep)
	for _, y in { 2.2, 2.8 } do
		k.glow({ 1.8, 0.08, 0.06 }, { 0, y, -0.98 }, nil, glow)
	end
	k.glow({ 0.5, 0.5, 0.06 }, { 0, 3.2, -0.98 }, { 0, 0, 45 }, glow)
	for i, x in { -0.6, 0.6 } do
		local swing = { hinge = { x, 1.3, 0 }, phase = (i - 1) * 0.5 }
		k.box({ 0.8, 1.1, 0.9 }, { x, 0.7, 0 }, nil, deep, { swing = swing })
		k.box({ 1.0, 0.35, 1.3 }, { x, 0.17, -0.15 }, nil, armour, { swing = swing })
	end
	for _, side in { -1, 1 } do
		k.box({ 1.0, 0.7, 1.4 }, { side * 1.5, 3.6, 0 }, { 0, 0, side * -12 }, deep)
		local arm = {
			swing = { hinge = { side * 1.6, 3.3, 0 }, phase = if side < 0 then 0.5 else 0, amount = 0.6 },
			rig = "arm",
			side = side,
		}
		k.box({ 0.55, 1.6, 0.6 }, { side * 1.65, 2.4, 0 }, nil, armour, arm)
		k.box({ 0.7, 0.5, 0.7 }, { side * 1.65, 1.4, 0 }, nil, deep, arm)
		k.wedge(
			{ 0.2, 0.5, 0.5 },
			{ side * 1.8, 1.0, -0.1 },
			{ 180, 0, 0 },
			glow,
			{ material = "Neon", swing = arm.swing }
		)
	end
	local hy = 4.4
	k.box({ 1.9, 1.2, 1.6 }, { 0, hy, 0 }, nil, armour, { name = "Head" })
	k.box({ 1.6, 0.45, 0.1 }, { 0, hy + 0.05, -0.82 }, nil, INK, { detail = true })
	k.glow({ 1.4, 0.25, 0.06 }, { 0, hy + 0.05, -0.88 }, nil, glow)
	k.box({ 0.12, 0.6, 0.12 }, { 0.5, hy + 0.9, 0 }, nil, deep)
	k.box({ 0.8, 0.1, 0.8 }, { 0.5, hy + 1.25, 0 }, { 20, 0, 0 }, rgb(200, 205, 215), { material = "Metal" })
	k.glow({ 0.2, 0.2, 0.2 }, { 0.5, hy + 1.4, -0.05 }, nil, glow)
	return k.done()
end

function CraftedFreeks.Gnome()
	-- A garden gnome (the Garden's guardian): a tall red pointy hat, a fluffy white beard, a
	-- rosy nose, a blue tunic with a brown belt and gold buckle, and a glowing lantern.
	local glow = rgb(255, 210, 90)
	local k, head = person({
		skin = rgb(246, 206, 176),
		shirt = rgb(60, 110, 210),
		pants = rgb(90, 70, 50),
		shoes = rgb(70, 50, 36),
		sleeves = rgb(60, 110, 210),
		accent = glow,
		head = { 1.9, 1.6, 1.7 },
	})
	k.box({ 1.9, 0.26, 1.1 }, { 0, 1.85, 0 }, nil, rgb(80, 56, 36), { detail = true })
	k.box({ 0.4, 0.3, 0.1 }, { 0, 1.85, -0.58 }, nil, GOLD, { material = "Metal", detail = true })
	-- The beard down over the tunic, and the rosy nose.
	k.wedge({ 1.7, 1.6, 0.5 }, { 0, head.y - 1.0, head.z - 0.1 }, { 0, 180, 0 }, WHITE)
	k.box({ 1.7, 0.6, 0.5 }, { 0, head.y - 0.35, head.z - 0.1 }, nil, WHITE)
	k.box({ 0.42, 0.38, 0.35 }, { 0, head.y + 0.05, head.z - 0.32 }, nil, rgb(240, 130, 120), { detail = true })
	k.eyes(head.y + 0.35, head.z - 0.06, 0.42, 0.3, 0.3, rgb(120, 220, 255), "cute")
	-- The tall red hat, each layer turned a little.
	for i, s in { 2.0, 1.6, 1.2, 0.85, 0.5 } do
		k.box({ s, 0.55, s }, { 0.06 * i, head.top + 0.1 + i * 0.5, 0.05 * i }, { 0, 12 * i, -6 * i }, rgb(215, 45, 55))
	end
	k.glow({ 0.25, 0.25, 0.25 }, { 0.35, head.top + 3.05, 0.3 }, nil, glow)
	-- A lantern in the right hand.
	k.box({ 0.55, 0.65, 0.55 }, { 1.45, 1.2, -0.35 }, nil, rgb(50, 50, 60), { detail = true })
	k.glow({ 0.4, 0.45, 0.4 }, { 1.45, 1.2, -0.35 }, nil, glow)
	return k.done()
end

return CraftedFreeks
