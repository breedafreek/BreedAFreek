-- 3D pictures for shop items (barn slots, weapons, game passes), built from parts like
-- everything else in the game and shown in ViewportFrames on the item cards.
-- ItemPictures.view(key, height) returns a ViewportFrame; keys are "BarnSlot", a weapon
-- id from Weapons.luau, or a game pass key from GamePasses.luau.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FreekModel = require(ReplicatedStorage.Shared.FreekModel)
local WeaponModel = require(ReplicatedStorage.Shared.WeaponModel)
local Weapons = require(ReplicatedStorage.Shared.Weapons)

local ItemPictures = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local GOLD = rgb(255, 200, 55)

local function part(model: Model, props)
	local p = Instance.new(props.ClassName or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		if key ~= "ClassName" then
			p[key] = value
		end
	end
	p.Parent = model
	return p
end

-- A ball, or a squashed ball (a sphere mesh) when the size isn't the same every way.
local function ball(model, position: Vector3, size: Vector3 | number, color: Color3, material: Enum.Material?)
	local vector = if typeof(size) == "number" then Vector3.one * size else size
	local round = vector.X == vector.Y and vector.Y == vector.Z
	local p = part(model, {
		Shape = if round then Enum.PartType.Ball else Enum.PartType.Block,
		Size = vector,
		CFrame = CFrame.new(position),
		Color = color,
		Material = material,
	})
	if not round then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	return p
end

local function cylinder(model, cframe: CFrame, height: number, diameter: number, color: Color3, material)
	return part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = cframe * CFrame.Angles(0, 0, math.pi / 2), -- upright
		Color = color,
		Material = material,
	})
end

-- A thick arc of blocks (handles, shackles).
local function arc(model, center: CFrame, radius: number, from: number, to: number, thickness: number, color: Color3)
	local last
	for i = 0, 10 do
		local a = from + (to - from) * i / 10
		local point = (center * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0)).Position
		if last then
			part(model, {
				Size = Vector3.new(thickness, thickness, (point - last).Magnitude + thickness * 0.6),
				CFrame = CFrame.lookAt((point + last) / 2, point),
				Color = color,
				Material = Enum.Material.Metal,
			})
		end
		last = point
	end
end

-- A big green "+" sign.
local function plus(model, position: Vector3, size: number)
	local green = rgb(80, 220, 100)
	part(model, { Size = Vector3.new(size, size * 0.32, size * 0.32), CFrame = CFrame.new(position), Color = green })
	part(model, { Size = Vector3.new(size * 0.32, size, size * 0.32), CFrame = CFrame.new(position), Color = green })
end

-- A glowing pad like the ones in the barn, with a Freek standing on it.
local function padWithFreek(model, species: string)
	cylinder(model, CFrame.new(0, 0.3, 0), 0.6, 5, rgb(70, 70, 85))
	cylinder(model, CFrame.new(0, 0.62, 0), 0.06, 4.4, rgb(90, 230, 255), Enum.Material.Neon)
	local freek, height = FreekModel.build(species)
	freek:PivotTo(CFrame.new(0, 0.65, 0))
	for _, p in freek:GetDescendants() do
		if p:IsA("BasePart") then
			p.Parent = model
		end
	end
	freek:Destroy()
	return height
end

local BUILDERS = {}

-- An extra barn slot: a pad with a Freek on it and a big plus.
function BUILDERS.BarnSlot(model)
	local height = padWithFreek(model, "Oinkle")
	plus(model, Vector3.new(-2.6, height + 0.8, 0), 1.8)
end
BUILDERS.ExtraSlot1 = BUILDERS.BarnSlot
BUILDERS.ExtraSlot2 = BUILDERS.BarnSlot
BUILDERS.ExtraSlot3 = BUILDERS.BarnSlot

-- 2x Coins: a pile of gold coins and a green cash stack.
function BUILDERS.DoubleCoins(model)
	for i = 0, 2 do
		part(model, {
			Size = Vector3.new(3.4, 0.6, 1.8),
			CFrame = CFrame.new(0.4, 0.3 + i * 0.62, 0.6) * CFrame.Angles(0, math.rad(i * 7), 0),
			Color = rgb(90, 200, 90),
		})
		part(model, {
			Size = Vector3.new(0.6, 0.66, 1.86),
			CFrame = CFrame.new(0.4, 0.3 + i * 0.62, 0.6) * CFrame.Angles(0, math.rad(i * 7), 0),
			Color = rgb(255, 240, 200),
		})
	end
	for i, spot in
		{
			Vector3.new(-1.4, 0.2, -0.6),
			Vector3.new(-1.4, 0.55, -0.6),
			Vector3.new(-1.4, 0.9, -0.6),
			Vector3.new(-0.3, 0.2, -1.2),
		}
	do
		cylinder(model, CFrame.new(spot) * CFrame.Angles(0, i, 0), 0.32, 1.7, GOLD, Enum.Material.Foil)
	end
	-- One big coin standing up in front.
	part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 2.4, 2.4),
		CFrame = CFrame.new(-0.6, 1.6, -1.6) * CFrame.Angles(0, math.rad(80), 0),
		Color = GOLD,
		Material = Enum.Material.Foil,
	})
end

-- Fast Fusing: a pink potion with a lightning bolt.
function BUILDERS.FastBreeding(model)
	ball(model, Vector3.new(0, 1.8, 0), 3.4, rgb(200, 235, 255), Enum.Material.Glass).Transparency = 0.6
	ball(model, Vector3.new(0, 1.55, 0), Vector3.new(2.9, 2.4, 2.9), rgb(255, 60, 170), Enum.Material.Neon)
	cylinder(model, CFrame.new(0, 3.8, 0), 1.4, 1.1, rgb(200, 235, 255), Enum.Material.Glass).Transparency = 0.4
	cylinder(model, CFrame.new(0, 4.6, 0), 0.7, 1.3, rgb(150, 95, 50))
	-- A zig-zag bolt beside it.
	local yellow = rgb(255, 220, 40)
	for _, bit in { { 2.3, 3.6, -30 }, { 2.0, 2.4, 35 }, { 2.4, 1.2, -30 } } do
		part(model, {
			Size = Vector3.new(0.7, 1.6, 0.5),
			CFrame = CFrame.new(bit[1], bit[2], -0.6) * CFrame.Angles(0, 0, math.rad(bit[3])),
			Color = yellow,
			Material = Enum.Material.Neon,
		})
	end
end

-- Longer Gate Lock: a big gold padlock.
function BUILDERS.LongerLock(model)
	part(model, {
		Size = Vector3.new(3.2, 2.6, 1.2),
		CFrame = CFrame.new(0, 1.3, 0),
		Color = GOLD,
		Material = Enum.Material.Foil,
	})
	arc(model, CFrame.new(0, 2.6, 0), 1.1, 0, math.pi, 0.45, rgb(170, 170, 180))
	ball(model, Vector3.new(0, 1.5, -0.6), 0.6, rgb(60, 45, 30))
	part(model, { Size = Vector3.new(0.3, 0.8, 0.2), CFrame = CFrame.new(0, 1.05, -0.62), Color = rgb(60, 45, 30) })
end

-- VIP: a gold crown with gems.
function BUILDERS.VIP(model)
	cylinder(model, CFrame.new(0, 0.8, 0), 1.6, 3.6, GOLD, Enum.Material.Foil)
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		local spot = Vector3.new(math.sin(a) * 1.5, 2.2, -math.cos(a) * 1.5)
		part(model, {
			Size = Vector3.new(0.9, 1.6, 0.9),
			CFrame = CFrame.new(spot) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.rad(45)),
			Color = GOLD,
			Material = Enum.Material.Foil,
		})
		ball(model, spot + Vector3.new(0, 1.1, 0), 0.55, GOLD, Enum.Material.Foil)
	end
	for k, color in { rgb(255, 50, 80), rgb(80, 160, 255), rgb(90, 220, 110) } do
		local a = (k - 2) * 0.7
		ball(model, Vector3.new(math.sin(a) * 1.8, 0.8, -math.cos(a) * 1.8), 0.7, color, Enum.Material.Neon)
	end
end

-- Extra Fusion Den: two hay bales and a pink heart.
function BUILDERS.ExtraPen(model)
	for _, x in { -1.4, 1.4 } do
		part(model, {
			Size = Vector3.new(2.4, 1.5, 1.6),
			CFrame = CFrame.new(x, 0.75, 0),
			Color = rgb(225, 190, 95),
			Material = Enum.Material.Sand,
		})
		part(model, { Size = Vector3.new(0.2, 1.55, 1.65), CFrame = CFrame.new(x, 0.75, 0), Color = rgb(140, 100, 55) })
	end
	local pink = rgb(255, 90, 170)
	ball(model, Vector3.new(-0.45, 3, 0), 1.2, pink, Enum.Material.Neon)
	ball(model, Vector3.new(0.45, 3, 0), 1.2, pink, Enum.Material.Neon)
	part(model, {
		Size = Vector3.new(1.25, 1.25, 1),
		CFrame = CFrame.new(0, 2.5, 0) * CFrame.Angles(0, 0, math.rad(45)),
		Color = pink,
		Material = Enum.Material.Neon,
	})
end

--------------------------------------------------------------------------------
-- Menu icons: the pictures on the side buttons (keys "Menu" .. tab name). They're built
-- flat-on, facing the camera (-Z), and shown by ItemPictures.icon.
--------------------------------------------------------------------------------

-- An isosceles triangle slab from two wedges: base centred on `base`, `across` along the
-- base, `toward` pointing at the tip.
local function triangle(model, base: Vector3, across: Vector3, toward: Vector3, width, height, depth, color, material)
	for _, side in { 1, -1 } do
		local u = across * side
		part(model, {
			ClassName = "WedgePart",
			Size = Vector3.new(depth, height, width / 2),
			CFrame = CFrame.fromMatrix(base + toward * (height / 2) + u * (width / 4), u:Cross(toward), toward, -u),
			Color = color,
			Material = material,
		})
	end
end

-- A five-pointed star standing up, facing the camera.
local function star(model, center: Vector3, outer: number, inner: number, depth: number, color: Color3)
	local half = math.rad(36)
	for k = 0, 4 do
		local a = math.rad(k * 72)
		local toward = Vector3.new(math.sin(a), math.cos(a), 0)
		local across = Vector3.new(math.cos(a), -math.sin(a), 0)
		local base = center + toward * inner * math.cos(half)
		local width = 2 * inner * math.sin(half)
		triangle(model, base, across, toward, width, outer - inner * math.cos(half), depth, color)
		triangle(model, base, across, -toward, width, inner * math.cos(half), depth, color)
	end
end

-- A little four-point sparkle.
local function sparkle(model, position: Vector3, size: number)
	local white = rgb(255, 255, 235)
	for _, angle in { 0, 90 } do
		part(model, {
			Size = Vector3.new(size * 0.22, size, size * 0.1),
			CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(angle)),
			Color = white,
			Material = Enum.Material.Neon,
		})
	end
end

-- Shop: a red shopping cart full of goodies.
BUILDERS.MenuShop = function(model)
	local red, white, dark = rgb(240, 70, 85), rgb(255, 245, 245), rgb(55, 55, 70)
	local w, d, h = 3.8, 2.4, 2
	local y0 = 1.3
	part(model, { Size = Vector3.new(w - 0.6, 0.25, d), CFrame = CFrame.new(0, y0, 0), Color = red })
	for _, z in { -d / 2, d / 2 } do
		-- Front and back walls.
		part(model, { Size = Vector3.new(w, h, 0.2), CFrame = CFrame.new(0, y0 + h / 2, z), Color = red })
		-- White grille stripes.
		for k = 1, 2 do
			part(model, {
				Size = Vector3.new(w - 0.4, 0.14, 0.24),
				CFrame = CFrame.new(0, y0 + h * k / 3, z),
				Color = white,
			})
		end
	end
	for _, x in { -w / 2 + 0.15, w / 2 - 0.15 } do
		part(model, { Size = Vector3.new(0.2, h, d), CFrame = CFrame.new(x, y0 + h / 2, 0), Color = red })
	end
	-- The rim and the push handle.
	part(model, { Size = Vector3.new(w + 0.1, 0.25, 0.3), CFrame = CFrame.new(0, y0 + h, -d / 2), Color = white })
	part(model, { Size = Vector3.new(w + 0.1, 0.25, 0.3), CFrame = CFrame.new(0, y0 + h, d / 2), Color = white })
	part(model, {
		Size = Vector3.new(0.25, 1.4, 0.25),
		CFrame = CFrame.new(w / 2 + 0.2, y0 + h + 0.4, -d / 2) * CFrame.Angles(0, 0, math.rad(-30)),
		Color = dark,
	})
	part(model, {
		Size = Vector3.new(0.25, 1.4, 0.25),
		CFrame = CFrame.new(w / 2 + 0.2, y0 + h + 0.4, d / 2) * CFrame.Angles(0, 0, math.rad(-30)),
		Color = dark,
	})
	part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(d + 0.6, 0.45, 0.45),
		CFrame = CFrame.new(w / 2 + 0.55, y0 + h + 1, 0) * CFrame.Angles(0, math.pi / 2, 0),
		Color = rgb(255, 200, 60),
	})
	-- Legs and wheels.
	part(model, { Size = Vector3.new(w - 0.8, 0.2, 0.2), CFrame = CFrame.new(0, 0.55, -d / 2 + 0.2), Color = dark })
	part(model, { Size = Vector3.new(w - 0.8, 0.2, 0.2), CFrame = CFrame.new(0, 0.55, d / 2 - 0.2), Color = dark })
	for _, x in { -w / 2 + 0.6, w / 2 - 0.6 } do
		for _, z in { -d / 2 + 0.2, d / 2 - 0.2 } do
			part(
				model,
				{ Size = Vector3.new(0.2, y0 - 0.5, 0.2), CFrame = CFrame.new(x, (y0 + 0.5) / 2, z), Color = dark }
			)
			part(model, {
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.35, 0.8, 0.8),
				CFrame = CFrame.new(x, 0.4, z) * CFrame.Angles(0, math.pi / 2, 0),
				Color = rgb(35, 35, 45),
			})
			part(model, {
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.4, 0.35, 0.35),
				CFrame = CFrame.new(x, 0.4, z) * CFrame.Angles(0, math.pi / 2, 0),
				Color = rgb(200, 200, 210),
			})
		end
	end
	-- Goodies poking out of the top.
	part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.35, 1.8, 1.8),
		CFrame = CFrame.new(-0.7, y0 + h + 0.3, 0.2) * CFrame.Angles(0, math.rad(80), math.rad(10)),
		Color = GOLD,
		Material = Enum.Material.Foil,
	})
	ball(model, Vector3.new(0.6, y0 + h, 0.3), 1.5, rgb(90, 210, 255))
	part(model, {
		Size = Vector3.new(1.3, 1.3, 1.3),
		CFrame = CFrame.new(1.2, y0 + h - 0.1, -0.1) * CFrame.Angles(0, math.rad(20), math.rad(-12)),
		Color = rgb(170, 100, 255),
	})
	part(model, {
		Size = Vector3.new(0.3, 1.36, 1.36),
		CFrame = CFrame.new(1.2, y0 + h - 0.1, -0.1) * CFrame.Angles(0, math.rad(20), math.rad(-12)),
		Color = rgb(255, 220, 60),
	})
end

-- Luck: a shiny four-leaf clover.
BUILDERS.MenuLuck = function(model)
	local green, light, dark = rgb(30, 165, 65), rgb(120, 235, 120), rgb(15, 105, 45)
	local center = Vector3.new(0, 2.6, 0)
	-- The stem, curling down to the right.
	part(model, {
		Size = Vector3.new(0.35, 1.8, 0.35),
		CFrame = CFrame.new(center + Vector3.new(0.35, -1.5, 0.15)) * CFrame.Angles(0, 0, math.rad(-18)),
		Color = dark,
	})
	part(model, {
		Size = Vector3.new(0.35, 1.0, 0.35),
		CFrame = CFrame.new(center + Vector3.new(0.85, -2.6, 0.15)) * CFrame.Angles(0, 0, math.rad(-40)),
		Color = dark,
	})
	for k = 0, 3 do
		local a = math.rad(45 + k * 90)
		local out = Vector3.new(math.sin(a), math.cos(a), 0)
		local side = Vector3.new(math.cos(a), -math.sin(a), 0)
		-- A heart: two round lobes and a diamond point toward the middle.
		for _, s in { -1, 1 } do
			ball(model, center + out * 1.45 + side * s * 0.5, Vector3.new(1.45, 1.45, 0.6), green)
			ball(
				model,
				center + out * 1.6 + side * s * 0.5 + Vector3.new(0, 0, -0.22),
				Vector3.new(0.6, 0.6, 0.2),
				light
			)
		end
		part(model, {
			Size = Vector3.new(1.15, 1.15, 0.55),
			CFrame = CFrame.new(center + out * 0.75) * CFrame.Angles(0, 0, -a + math.rad(45)),
			Color = green,
		})
		-- A darker vein down the middle of the leaf.
		part(model, {
			Size = Vector3.new(0.14, 1.3, 0.1),
			CFrame = CFrame.new(center + out * 1.05 + Vector3.new(0, 0, -0.3)) * CFrame.Angles(0, 0, -a),
			Color = dark,
		})
	end
	ball(model, center + Vector3.new(0, 0, -0.1), Vector3.new(0.7, 0.7, 0.5), dark)
	sparkle(model, center + Vector3.new(-2, 2, -0.6), 0.9)
	sparkle(model, center + Vector3.new(2.2, -1.2, -0.6), 0.6)
end

-- Freeks: Oinkle, the mascot.
BUILDERS.MenuFreeks = function(model)
	local freek = FreekModel.build("Oinkle")
	freek:PivotTo(CFrame.new())
	for _, p in freek:GetDescendants() do
		if p:IsA("BasePart") then
			p.Parent = model
		end
	end
	freek:Destroy()
end

-- Fuse: a round potion flask bubbling purple-to-pink.
BUILDERS.MenuFuse = function(model)
	local glass = rgb(215, 240, 255)
	ball(model, Vector3.new(0, 1.9, 0), 3.6, glass, Enum.Material.Glass).Transparency = 0.55
	ball(model, Vector3.new(0, 1.65, 0), Vector3.new(3.15, 2.7, 3.15), rgb(170, 80, 255))
	ball(model, Vector3.new(0, 2.55, 0), Vector3.new(2.7, 0.7, 2.7), rgb(255, 80, 190))
	-- A highlight on the glass.
	ball(model, Vector3.new(-0.9, 2.7, -1.25), Vector3.new(0.45, 0.9, 0.2), rgb(255, 255, 255))
	cylinder(model, CFrame.new(0, 4.0, 0), 1.3, 1.1, glass, Enum.Material.Glass).Transparency = 0.35
	cylinder(model, CFrame.new(0, 4.55, 0), 0.25, 1.35, glass)
	cylinder(model, CFrame.new(0, 4.95, 0), 0.7, 0.95, rgb(160, 100, 55))
	-- Bubbles.
	for _, b in { { 0.5, 1.4, 0.45 }, { -0.6, 1.0, 0.35 }, { 0.2, 2.0, 0.3 }, { 0.9, 5.7, 0.4 }, { 0.3, 6.4, 0.3 } } do
		ball(model, Vector3.new(b[1], b[2], -0.8), b[3], rgb(255, 210, 245), Enum.Material.Neon)
	end
	sparkle(model, Vector3.new(-1.9, 4.6, -0.5), 0.8)
end

-- Book: the Freekdex, open, with a ribbon.
BUILDERS.MenuBook = function(model)
	local cover, pages, lines = rgb(225, 45, 80), rgb(255, 250, 235), rgb(190, 180, 170)
	local center = Vector3.new(0, 2, 0)
	for _, s in { -1, 1 } do
		local hinge = CFrame.new(center) * CFrame.Angles(math.rad(-25), 0, 0) * CFrame.Angles(0, math.rad(-s * 24), 0)
		part(model, {
			Size = Vector3.new(2.45, 3.25, 0.35),
			CFrame = hinge * CFrame.new(s * 1.2, 0, 0.3),
			Color = cover,
		})
		part(model, {
			Size = Vector3.new(2.1, 2.85, 0.3),
			CFrame = hinge * CFrame.new(s * 1.07, 0.02, 0),
			Color = pages,
		})
		for k = 0, 3 do
			part(model, {
				Size = Vector3.new(if k == 0 then 1 else 1.5, 0.12, 0.05),
				CFrame = hinge * CFrame.new(s * 1.07, 0.9 - k * 0.45, -0.17),
				Color = lines,
			})
		end
	end
	-- A little Freek face on the left page and a ribbon hanging out.
	ball(model, center + Vector3.new(-1.05, 0.2, -0.45), Vector3.new(0.9, 0.9, 0.3), rgb(255, 160, 190))
	ball(model, center + Vector3.new(-1.25, 0.3, -0.62), Vector3.new(0.22, 0.22, 0.1), rgb(30, 30, 40))
	ball(model, center + Vector3.new(-0.85, 0.3, -0.62), Vector3.new(0.22, 0.22, 0.1), rgb(30, 30, 40))
	part(model, {
		Size = Vector3.new(0.35, 1.4, 0.06),
		CFrame = CFrame.new(center + Vector3.new(0.15, -1.9, -0.1)) * CFrame.Angles(0, 0, math.rad(8)),
		Color = rgb(235, 60, 80),
	})
	sparkle(model, center + Vector3.new(2.2, 1.9, -0.4), 0.8)
end

-- Trade: two fat arrows passing each other.
BUILDERS.MenuTrade = function(model)
	for _, arrow in { { 1, 1.1, rgb(80, 220, 110) }, { -1, -0.4, rgb(70, 160, 255) } } do
		local dir, y, color = arrow[1], arrow[2], arrow[3]
		local x0 = -dir * 0.6
		part(model, {
			Size = Vector3.new(2.6, 0.95, 0.7),
			CFrame = CFrame.new(x0, 2 + y, -dir * 0.1),
			Color = color,
		})
		triangle(
			model,
			Vector3.new(x0 + dir * 1.25, 2 + y, -dir * 0.1),
			Vector3.new(0, 1, 0),
			Vector3.new(dir, 0, 0),
			2.1,
			1.4,
			0.7,
			color
		)
		-- A light stripe along the top edge.
		part(model, {
			Size = Vector3.new(2.4, 0.2, 0.1),
			CFrame = CFrame.new(x0, 2 + y + 0.25, -dir * 0.1 - 0.36),
			Color = color:Lerp(Color3.new(1, 1, 1), 0.5),
		})
	end
end

-- Rebirth: a big gold star with a bevel.
BUILDERS.MenuRebirth = function(model)
	star(model, Vector3.new(0, 2.4, 0), 2.4, 1.05, 0.8, rgb(255, 180, 30))
	star(model, Vector3.new(0, 2.45, -0.42), 1.75, 0.76, 0.15, rgb(255, 225, 90))
	ball(model, Vector3.new(-0.45, 2.95, -0.55), Vector3.new(0.35, 0.55, 0.1), rgb(255, 255, 230))
	sparkle(model, Vector3.new(2.1, 4.3, -0.5), 0.9)
	sparkle(model, Vector3.new(-2.2, 0.8, -0.5), 0.6)
end

-- Store: a cut diamond, built facet by facet.
BUILDERS.MenuStore = function(model)
	local girdle = Vector3.new(0, 2.6, 0)
	local radius, depth, top, tableRadius = 2.2, 2.4, 0.85, 1.35
	local up = Vector3.yAxis
	local function around(angle: number, r: number, y: number): Vector3
		local a = math.rad(angle)
		return girdle + Vector3.new(math.sin(a) * r, y, math.cos(a) * r)
	end
	local function facet(p1: Vector3, p2: Vector3, apex: Vector3, color: Color3)
		local base = (p1 + p2) / 2
		local toward = apex - base
		triangle(model, base, (p2 - p1).Unit, toward.Unit, (p2 - p1).Magnitude, toward.Magnitude, 0.15, color)
	end
	local tip = girdle - up * depth
	for k = 0, 7 do
		local a = k * 45
		local p1, p2 = around(a, radius, 0), around(a + 45, radius, 0)
		local light = k % 2 == 0
		-- The point underneath, the crown's slopes, and the little gaps between them.
		facet(p1, p2, tip, if light then rgb(110, 225, 255) else rgb(40, 170, 245))
		local q = around(a + 22.5, tableRadius, top)
		facet(p1, p2, q, if light then rgb(180, 242, 255) else rgb(95, 205, 255))
		facet(q, around(a + 67.5, tableRadius, top), p2, if light then rgb(140, 230, 255) else rgb(200, 248, 255))
	end
	part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, tableRadius * 2.05, tableRadius * 2.05),
		CFrame = CFrame.new(girdle + up * top) * CFrame.Angles(0, 0, math.pi / 2),
		Color = rgb(225, 252, 255),
	})
	sparkle(model, girdle + Vector3.new(-1.3, 1.6, -1.8), 1)
	sparkle(model, girdle + Vector3.new(1.9, -1.2, -1.6), 0.7)
end

-- A weapon, laid on its side so the whole thing shows.
local function weaponModel(model, weaponId: string)
	local tool = WeaponModel.build(weaponId)
	local melee = Weapons.list[weaponId].kind == "melee"
	for _, p in tool:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			-- Melee weapons extend along +Z, guns point along -Z: turn them to lie across.
			p.CFrame = CFrame.Angles(
				0,
				if melee then math.rad(90) else math.rad(-90),
				if melee then math.rad(35) else 0
			) * p.CFrame
			p.Parent = model
		end
	end
	tool:Destroy()
end

-- The box round everything you can see (counting stretched sphere meshes).
local function visibleBounds(model: Model): (Vector3, Vector3)
	local lo, hi
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			local size = p.Size
			local mesh = p:FindFirstChildOfClass("SpecialMesh")
			if mesh then
				size *= mesh.Scale
			end
			for _, x in { -0.5, 0.5 } do
				for _, y in { -0.5, 0.5 } do
					for _, z in { -0.5, 0.5 } do
						local point = p.CFrame:PointToWorldSpace(size * Vector3.new(x, y, z))
						lo = if lo then lo:Min(point) else point
						hi = if hi then hi:Max(point) else point
					end
				end
			end
		end
	end
	return lo or Vector3.zero, hi or Vector3.zero
end

-- A square icon (the side menu's pictures): framed to fill the square, seen almost
-- head-on. Returns the ViewportFrame and sway(t), which turns the picture gently from side
-- to side over time.
function ItemPictures.icon(key: string): (ViewportFrame, (number) -> ())
	local frame = Instance.new("ViewportFrame")
	frame.BackgroundTransparency = 1
	frame.Ambient = Color3.fromRGB(200, 200, 205)
	frame.LightColor = Color3.fromRGB(255, 250, 240)
	frame.LightDirection = Vector3.new(-0.8, -1.2, 1)

	local model = Instance.new("Model")
	BUILDERS[key](model)
	model.Parent = frame

	local lo, hi = visibleBounds(model)
	local center = (lo + hi) / 2
	local extent = hi - lo
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	local fit = math.max(extent.X, extent.Y, extent.Z * 0.7) / 2 * 1.05
	local distance = fit / math.tan(math.rad(15)) + extent.Z / 2
	local direction = Vector3.new(0.3, 0.22, -1).Unit
	local function sway(t: number)
		local turn = CFrame.Angles(0, math.sin(t) * math.rad(14), 0)
		camera.CFrame = CFrame.lookAt(center + turn:VectorToWorldSpace(direction) * distance, center)
	end
	sway(0)
	camera.Parent = frame
	frame.CurrentCamera = camera
	return frame, sway
end

function ItemPictures.has(key: string): boolean
	return BUILDERS[key] ~= nil or Weapons.list[key] ~= nil
end

-- A ViewportFrame showing the item, framed to fit, seen a little from above and the side.
function ItemPictures.view(key: string, height: number?): ViewportFrame
	local frame = Instance.new("ViewportFrame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, height or 90)
	frame.Ambient = Color3.fromRGB(190, 190, 190)
	frame.LightColor = Color3.fromRGB(255, 250, 240)
	frame.LightDirection = Vector3.new(-1, -1.4, 1)

	local model = Instance.new("Model")
	if Weapons.list[key] then
		weaponModel(model, key)
	elseif BUILDERS[key] then
		BUILDERS[key](model)
	end
	model.Parent = frame

	local lo, hi = visibleBounds(model)
	local center = (lo + hi) / 2
	local extent = hi - lo
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	-- The picture strip is about twice as wide as it is tall, so wide items can use the
	-- width (the field of view is vertical).
	local aspect = 2
	local wide = math.max(extent.X, extent.Z) * 0.85
	local fit = math.max(extent.Y, wide / aspect) / 2 * 1.08
	local distance = fit / math.tan(math.rad(15)) + extent.Z / 2
	local direction = Vector3.new(0.45, 0.4, -1).Unit
	camera.CFrame = CFrame.lookAt(center + direction * distance, center)
	camera.Parent = frame
	frame.CurrentCamera = camera
	return frame
end

return ItemPictures
