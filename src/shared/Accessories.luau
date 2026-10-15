-- Signature accessories: one per species (Freeks.luau `signature`), worn by the species
-- itself and mixed onto fusions, so a fused Freek shows off both parents' signatures (the
-- nerd's glasses on a pig's head, the pig's bow, ...).
--
-- Each accessory is a list of parts in the Freeks.luau part format, built for a head of
-- radius 1 centred at the origin, facing -Z. Neck accessories are built round a neck point
-- (the origin) instead, sized for a head of radius 1 above it. `slot` says where it goes,
-- so two accessories never fight over the same spot.

local Accessories = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- How far forward the front of a radius-1 head is at (x, y).
local function front(x: number, y: number): number
	return -math.sqrt(math.max(1 - x * x - y * y, 0.01))
end

local GOLD = rgb(255, 205, 60)

local list = {}

-- Nerdle: big round glasses.
list.glasses = {
	slot = "eyes",
	build = function()
		local parts: { any } = {}
		for _, side in { -1, 1 } do
			local x = side * 0.38
			local z = front(x, 0.15) - 0.14
			table.insert(parts, {
				shape = "Cylinder",
				size = { 0.08, 0.5, 0.5 },
				pos = { x, 0.15, z },
				rot = { 0, 90, 0 },
				color = rgb(30, 30, 40),
				detail = true,
			})
			table.insert(parts, {
				shape = "Cylinder",
				size = { 0.09, 0.4, 0.4 },
				pos = { x, 0.15, z },
				rot = { 0, 90, 0 },
				color = rgb(220, 240, 255),
				transparency = 0.55,
				detail = true,
			})
			table.insert(parts, {
				shape = "Block",
				size = { 0.06, 0.06, 0.8 },
				pos = { side * 0.72, 0.18, z + 0.42 },
				color = rgb(30, 30, 40),
				detail = true,
			})
		end
		table.insert(parts, {
			shape = "Block",
			size = { 0.28, 0.07, 0.07 },
			pos = { 0, 0.2, front(0, 0.2) - 0.14 },
			color = rgb(30, 30, 40),
			detail = true,
		})
		return parts
	end,
}

-- Chompers: cool black shades with a shine.
list.shades = {
	slot = "eyes",
	build = function()
		local parts: { any } = {}
		for _, side in { -1, 1 } do
			local x = side * 0.36
			local z = front(x, 0.15) - 0.16
			table.insert(parts, {
				shape = "Ellipsoid",
				size = { 0.52, 0.34, 0.1 },
				pos = { x, 0.15, z },
				color = rgb(20, 20, 28),
				detail = true,
			})
			table.insert(parts, {
				shape = "Block",
				size = { 0.08, 0.2, 0.04 },
				pos = { x - 0.1, 0.19, z - 0.05 },
				rot = { 0, 0, -30 },
				color = rgb(255, 255, 255),
				detail = true,
				shine = false,
			})
		end
		table.insert(parts, {
			shape = "Block",
			size = { 0.3, 0.07, 0.07 },
			pos = { 0, 0.2, front(0, 0.2) - 0.16 },
			color = rgb(20, 20, 28),
			detail = true,
		})
		return parts
	end,
}

-- Hootsworth: a posh top hat with a red band.
list.tophat = {
	slot = "top",
	build = function()
		return {
			{
				shape = "Cylinder",
				size = { 0.08, 1.25, 1.25 },
				pos = { 0, 0.86, 0.05 },
				rot = { 0, 0, 90 },
				color = rgb(25, 25, 32),
			},
			{
				shape = "Cylinder",
				size = { 0.85, 0.8, 0.8 },
				pos = { 0, 1.3, 0.05 },
				rot = { 0, 0, 90 },
				color = rgb(25, 25, 32),
			},
			{
				shape = "Cylinder",
				size = { 0.16, 0.82, 0.82 },
				pos = { 0, 1.0, 0.05 },
				rot = { 0, 0, 90 },
				color = rgb(220, 40, 50),
			},
		}
	end,
}

-- Glamora: a sparkling tiara.
list.tiara = {
	slot = "top",
	build = function()
		local parts: { any } = {}
		for k = -3, 3 do
			local a = math.rad(k * 16)
			local x, z = math.sin(a) * 0.6, -math.cos(a) * 0.6 + 0.12
			table.insert(parts, {
				shape = "Ball",
				size = if k == 0 then 0.24 else 0.15,
				pos = { x, 0.82 + (3 - math.abs(k)) * 0.04, z },
				color = if k == 0 then rgb(255, 120, 200) else GOLD,
				material = if k == 0 then "Neon" else "Foil",
				detail = true,
				shine = false,
			})
		end
		return parts
	end,
}

-- Oinkle: a big pink bow on one side of the head.
list.bow = {
	slot = "top",
	build = function()
		local pink, deep = rgb(255, 50, 140), rgb(200, 20, 100)
		return {
			{
				shape = "Ellipsoid",
				size = { 0.6, 0.46, 0.3 },
				pos = { 0.26, 0.98, -0.12 },
				rot = { 0, 0, 25 },
				color = pink,
				detail = true,
			},
			{
				shape = "Ellipsoid",
				size = { 0.6, 0.46, 0.3 },
				pos = { 0.82, 0.72, -0.12 },
				rot = { 0, 0, 25 },
				color = pink,
				detail = true,
			},
			{ shape = "Ball", size = 0.28, pos = { 0.54, 0.85, -0.18 }, color = deep, detail = true, shine = false },
		}
	end,
}

-- Lizzle: a little flower with a leaf.
list.flower = {
	slot = "top",
	build = function()
		local parts: { any } = {
			{
				shape = "Ball",
				size = 0.2,
				pos = { -0.45, 0.88, -0.12 },
				color = rgb(255, 210, 60),
				detail = true,
				shine = false,
			},
			{
				shape = "Ellipsoid",
				size = { 0.3, 0.08, 0.16 },
				pos = { -0.3, 0.84, 0 },
				rot = { 0, 30, -20 },
				color = rgb(90, 190, 80),
				detail = true,
			},
		}
		for k = 0, 4 do
			local a = k / 5 * math.pi * 2
			table.insert(parts, {
				shape = "Ball",
				size = 0.17,
				pos = { -0.45 + math.cos(a) * 0.15, 0.88 + math.sin(a) * 0.15, -0.1 },
				color = rgb(255, 255, 255),
				detail = true,
				shine = false,
			})
		end
		return parts
	end,
}

-- Stompy: an ivory horn on the forehead with a glowing tip.
list.horn = {
	slot = "forehead",
	build = function()
		local parts: { any } = {}
		for k = 0, 4 do
			local up = k * 0.13
			table.insert(parts, {
				shape = "Cylinder",
				size = { 0.14, 0.34 - k * 0.06, 0.34 - k * 0.06 },
				pos = { 0, 0.68 + up, -0.62 - up * 0.45 },
				rot = { 25, 0, 90 },
				color = rgb(250, 245, 225),
				detail = true,
			})
		end
		table.insert(parts, {
			shape = "Ball",
			size = 0.12,
			pos = { 0, 0.68 + 0.68, -0.62 - 0.31 },
			color = rgb(190, 120, 255),
			material = "Neon",
			detail = true,
			shine = false,
		})
		return parts
	end,
}

-- Blinky: two little golden horns.
list.horns = {
	slot = "top",
	build = function()
		local parts: { any } = {}
		for _, side in { -1, 1 } do
			for k = 0, 3 do
				table.insert(parts, {
					shape = "Cylinder",
					size = { 0.12, 0.26 - k * 0.055, 0.26 - k * 0.055 },
					pos = { side * (0.45 + k * 0.04), 0.85 + k * 0.1, 0 },
					rot = { 0, 0, 90 - side * 20 },
					color = rgb(255, 220, 120),
					detail = true,
				})
			end
		end
		return parts
	end,
}

-- Chuckles: a big red clown nose.
list.clownnose = {
	slot = "nose",
	build = function()
		return {
			{ shape = "Ball", size = 0.36, pos = { 0, -0.08, front(0, -0.08) - 0.08 }, color = rgb(235, 30, 40) },
		}
	end,
}

-- Flexo: a sporty sweatband round the forehead.
list.sweatband = {
	slot = "forehead",
	build = function()
		return {
			{
				shape = "Cylinder",
				size = { 0.2, 1.9, 1.9 },
				pos = { 0, 0.42, 0 },
				rot = { 0, 0, 90 },
				color = rgb(255, 255, 255),
			},
			{
				shape = "Cylinder",
				size = { 0.06, 1.92, 1.92 },
				pos = { 0, 0.47, 0 },
				rot = { 0, 0, 90 },
				color = rgb(230, 40, 50),
			},
			{
				shape = "Cylinder",
				size = { 0.06, 1.92, 1.92 },
				pos = { 0, 0.37, 0 },
				rot = { 0, 0, 90 },
				color = rgb(230, 40, 50),
			},
		}
	end,
}

-- Mumbles: a bandage wrapped round the forehead with a loose end.
list.bandage = {
	slot = "forehead",
	build = function()
		local cloth = rgb(240, 232, 205)
		return {
			{ shape = "Cylinder", size = { 0.24, 1.92, 1.92 }, pos = { 0, 0.4, 0 }, rot = { 0, 0, 82 }, color = cloth },
			{
				shape = "Block",
				size = { 0.2, 0.5, 0.06 },
				pos = { 0.55, 0.15, 0.78 },
				rot = { 0, 0, -20 },
				color = cloth,
			},
		}
	end,
}

-- Boo-Boo: a spooky witch hat.
list.witchhat = {
	slot = "top",
	build = function()
		local purple = rgb(110, 50, 170)
		local parts: { any } = {
			{ shape = "Cylinder", size = { 0.08, 1.4, 1.4 }, pos = { 0, 0.85, 0 }, rot = { 0, 0, 90 }, color = purple },
			{
				shape = "Cylinder",
				size = { 0.14, 0.86, 0.86 },
				pos = { 0, 0.95, 0 },
				rot = { 0, 0, 90 },
				color = rgb(255, 150, 40),
			},
		}
		for k = 0, 5 do
			table.insert(parts, {
				shape = "Cylinder",
				size = { 0.2, 0.8 - k * 0.13, 0.8 - k * 0.13 },
				pos = { k * 0.035, 1.05 + k * 0.18, k * 0.02 },
				rot = { 0, 0, 90 - k * 4 },
				color = purple,
			})
		end
		return parts
	end,
}

-- Zomboy: bolts sticking out of the sides of the head.
list.bolts = {
	slot = "sides",
	build = function()
		local parts: { any } = {}
		for _, side in { -1, 1 } do
			table.insert(parts, {
				shape = "Cylinder",
				size = { 0.4, 0.16, 0.16 },
				pos = { side * 1.0, -0.25, 0 },
				color = rgb(150, 155, 165),
				material = "Metal",
				detail = true,
			})
			table.insert(parts, {
				shape = "Cylinder",
				size = { 0.12, 0.3, 0.3 },
				pos = { side * 1.2, -0.25, 0 },
				color = rgb(120, 125, 135),
				material = "Metal",
				detail = true,
			})
		end
		return parts
	end,
}

-- Neck accessories (the origin is the neck, under a radius-1 head).

-- Woofles: a red collar with a gold tag.
list.collar = {
	slot = "neck",
	build = function()
		return {
			{
				shape = "Cylinder",
				size = { 0.24, 1.6, 1.6 },
				pos = { 0, 0, 0 },
				rot = { 0, 0, 90 },
				color = rgb(225, 40, 55),
			},
			{
				shape = "Cylinder",
				size = { 0.08, 0.34, 0.34 },
				pos = { 0, -0.24, -0.8 },
				rot = { 0, 90, 0 },
				color = GOLD,
				material = "Foil",
			},
		}
	end,
}

-- Whiskerz: a pink ribbon with a gold bell.
list.bell = {
	slot = "neck",
	build = function()
		return {
			{
				shape = "Cylinder",
				size = { 0.2, 1.55, 1.55 },
				pos = { 0, 0, 0 },
				rot = { 0, 0, 90 },
				color = rgb(255, 120, 170),
			},
			{ shape = "Ball", size = 0.36, pos = { 0, -0.22, -0.8 }, color = GOLD, material = "Foil" },
			{
				shape = "Block",
				size = { 0.16, 0.04, 0.04 },
				pos = { 0, -0.27, -0.97 },
				color = rgb(60, 40, 20),
				detail = true,
			},
		}
	end,
}

-- Count Fangula: a tall popped cape collar, black outside and red inside.
list.capecollar = {
	slot = "neck",
	build = function()
		local parts: { any } = {}
		for _, side in { -1, 1 } do
			table.insert(parts, {
				shape = "Wedge",
				size = { 0.08, 0.9, 0.7 },
				pos = { side * 0.55, 0.35, 0.25 },
				rot = { 0, side * 50, 0 },
				color = rgb(25, 20, 30),
			})
			table.insert(parts, {
				shape = "Wedge",
				size = { 0.06, 0.8, 0.6 },
				pos = { side * 0.5, 0.33, 0.2 },
				rot = { 0, side * 50, 0 },
				color = rgb(200, 30, 45),
			})
		end
		table.insert(parts, {
			shape = "Cylinder",
			size = { 0.2, 1.45, 1.45 },
			pos = { 0, 0, 0 },
			rot = { 0, 0, 90 },
			color = rgb(25, 20, 30),
		})
		return parts
	end,
}

-- Howlz: a black spiked collar.
list.spikedcollar = {
	slot = "neck",
	build = function()
		local parts: { any } = {
			{
				shape = "Cylinder",
				size = { 0.26, 1.6, 1.6 },
				pos = { 0, 0, 0 },
				rot = { 0, 0, 90 },
				color = rgb(30, 30, 38),
			},
		}
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			table.insert(parts, {
				shape = "Ball",
				size = 0.18,
				pos = { math.cos(a) * 0.82, 0, math.sin(a) * 0.82 },
				color = rgb(210, 215, 225),
				material = "Metal",
			})
		end
		return parts
	end,
}

Accessories.list = list

-- Adds accessory `id` to a Freeks.luau part list, for a head of radius r centred at
-- `center` (or round a neck point, for a neck accessory).
function Accessories.put(add, id: string, center: { number }, r: number)
	local accessory = list[id]
	if not accessory then
		return
	end
	for _, spec in accessory.build() do
		local copy = table.clone(spec)
		copy.pos = { center[1] + spec.pos[1] * r, center[2] + spec.pos[2] * r, center[3] + spec.pos[3] * r }
		if type(spec.size) == "number" then
			copy.size = spec.size * r
		else
			copy.size = { spec.size[1] * r, spec.size[2] * r, spec.size[3] * r }
		end
		if accessory.slot == "neck" then
			copy.onHead = false -- stays on the body when the head turns
		end
		add(copy)
	end
end

return Accessories
