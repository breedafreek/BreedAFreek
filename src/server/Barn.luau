-- Each player's yard is a big red barn: plank floor, red walls with white trim, a gambrel
-- roof, and two big doors at the front that always stand slid open. When the owner locks
-- up, a red barrier fills the doorway. The Freek pads and the Fusion Dens are inside
-- (PlotService places those).
--
-- Coordinates are the plot's: origin on the ground at the plot's centre, the doors on
-- the -Z side facing the town square, the floor's top at y = 1.
--
-- The roof is solid, so the camera stays under it while you're inside; an invisible
-- ceiling on top of the walls also stops anyone getting in from above.

local Decor = require(script.Parent.Decor)

local Barn = {}

Barn.SIZE = 64
Barn.WALL_HEIGHT = 18
Barn.DOOR_WIDTH = 14
Barn.DOOR_HEIGHT = 13

local RED = Color3.fromRGB(168, 40, 36)
local WHITE = Color3.fromRGB(245, 242, 235)
local ROOF = Color3.fromRGB(72, 58, 62)
local FLOOR = Color3.fromRGB(150, 108, 72)

local part = Decor.part

local function wedge(props)
	return part(props, "WedgePart")
end

-- A sliding door: red planks with a white frame and a white X.
local function buildDoor(parent: Instance, closed: CFrame, index: number)
	local model = Instance.new("Model")
	model.Name = "BarnDoor"
	local w, h = Barn.DOOR_WIDTH / 2 + 0.2, Barn.DOOR_HEIGHT + 0.2
	local panel = part({
		Name = "DoorPanel",
		Size = Vector3.new(w, h, 0.6),
		CFrame = closed,
		Color = RED,
		Material = Enum.Material.WoodPlanks,
		CollisionGroup = "Gate" .. index,
		Parent = model,
	})
	model.PrimaryPart = panel
	local trim = {
		{ Vector3.new(w, 0.6, 0.8), Vector3.new(0, h / 2 - 0.3, 0) },
		{ Vector3.new(w, 0.6, 0.8), Vector3.new(0, -h / 2 + 0.3, 0) },
		{ Vector3.new(0.6, h, 0.8), Vector3.new(w / 2 - 0.3, 0, 0) },
		{ Vector3.new(0.6, h, 0.8), Vector3.new(-w / 2 + 0.3, 0, 0) },
	}
	for _, piece in trim do
		part({
			Name = "DoorTrim",
			Size = piece[1],
			CFrame = closed * CFrame.new(piece[2]),
			Color = WHITE,
			CanCollide = false,
			Parent = model,
		})
	end
	local length = math.sqrt((w - 1.2) ^ 2 + (h - 1.2) ^ 2)
	local angle = math.atan2(h - 1.2, w - 1.2)
	for _, sign in { -1, 1 } do
		part({
			Name = "DoorTrim",
			Size = Vector3.new(length, 0.6, 0.8),
			CFrame = closed * CFrame.Angles(0, 0, sign * angle),
			Color = WHITE,
			CanCollide = false,
			Parent = model,
		})
	end
	model.Parent = parent
	return model
end

-- The finishing touches, in the chunky cartoon style of the big farm games: board-and-batten
-- walls, a hayloft door with hay spilling out and a hoist above it, shingle rows on the
-- roof, shutters and flower boxes on the windows, a window on the front opposite the name
-- plaque, and barrels, a water trough and milk churns outside. Roof pieces go in the Roof
-- folder so they rise with the extra storey (BarnUpgrades).
local BATTEN = Color3.fromRGB(135, 28, 30)
local SHUTTER = Color3.fromRGB(60, 150, 110)
local WOOD = Color3.fromRGB(150, 100, 60)
local DARK_WOOD = Color3.fromRGB(105, 68, 40)
local HAY = Color3.fromRGB(240, 205, 95)
local FLOWERS = {
	Color3.fromRGB(255, 90, 140),
	Color3.fromRGB(255, 210, 60),
	Color3.fromRGB(150, 110, 255),
	Color3.fromRGB(255, 140, 60),
	Color3.fromRGB(90, 200, 255),
}

-- A white X-braced panel (door or shutter look) centred at cframe, facing its -Z.
local function bracedPanel(parent: Instance, cframe: CFrame, w: number, h: number, color: Color3, name: string)
	part({ Name = name, Size = Vector3.new(w, h, 0.4), CFrame = cframe, Color = color, Parent = parent })
	local t = math.min(w, h) * 0.12
	for _, piece in
		{
			{ Vector3.new(w, t, 0.5), Vector3.new(0, h / 2 - t / 2, 0) },
			{ Vector3.new(w, t, 0.5), Vector3.new(0, -h / 2 + t / 2, 0) },
			{ Vector3.new(t, h, 0.5), Vector3.new(w / 2 - t / 2, 0, 0) },
			{ Vector3.new(t, h, 0.5), Vector3.new(-w / 2 + t / 2, 0, 0) },
		}
	do
		part({
			Name = "DoorTrim",
			Size = piece[1],
			CFrame = cframe * CFrame.new(piece[2]) * CFrame.new(0, 0, -0.05),
			Color = WHITE,
			CanCollide = false,
			Parent = parent,
		})
	end
	local length = math.sqrt((w - 2 * t) ^ 2 + (h - 2 * t) ^ 2)
	local angle = math.atan2(h - 2 * t, w - 2 * t)
	for _, sign in { -1, 1 } do
		part({
			Name = "DoorTrim",
			Size = Vector3.new(length, t * 0.9, 0.5),
			CFrame = cframe * CFrame.new(0, 0, -0.05) * CFrame.Angles(0, 0, sign * angle),
			Color = WHITE,
			CanCollide = false,
			Parent = parent,
		})
	end
end

-- A flower box hanging under a window: a wooden box of soil with a row of bright blooms.
local function flowerBox(parent: Instance, cframe: CFrame, width: number, seed: number)
	part({
		Name = "FlowerBox",
		Size = Vector3.new(width, 1, 1.2),
		CFrame = cframe,
		Color = WOOD,
		Material = Enum.Material.WoodPlanks,
		CanCollide = false,
		Parent = parent,
	})
	local count = math.floor(width / 1.1)
	for k = 1, count do
		local x = (k - (count + 1) / 2) * (width / count)
		part({
			Name = "Leaf",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.9,
			CFrame = cframe * CFrame.new(x, 0.6, 0),
			Color = Color3.fromRGB(80, 170, 70),
			CanCollide = false,
			Parent = parent,
		})
		part({
			Name = "Flower",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.8,
			CFrame = cframe * CFrame.new(x, 1.15, -0.1),
			Color = FLOWERS[(k + seed) % #FLOWERS + 1],
			CanCollide = false,
			Parent = parent,
		})
	end
end

local function barrel(parent: Instance, ground: CFrame)
	part({
		Name = "Barrel",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(3.2, 2.6, 2.6),
		CFrame = ground * CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = WOOD,
		Material = Enum.Material.WoodPlanks,
		Parent = parent,
	})
	for _, y in { 0.6, 2.6 } do
		part({
			Name = "BarrelHoop",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, 2.75, 2.75),
			CFrame = ground * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Color = Color3.fromRGB(70, 70, 80),
			Material = Enum.Material.Metal,
			CanCollide = false,
			Parent = parent,
		})
	end
end

local function churn(parent: Instance, ground: CFrame)
	part({
		Name = "MilkChurn",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, 1.3, 1.3),
		CFrame = ground * CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(200, 205, 215),
		Material = Enum.Material.Metal,
		Parent = parent,
	})
	part({
		Name = "MilkChurn",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, 0.8, 0.8),
		CFrame = ground * CFrame.new(0, 2.2, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(80, 160, 230),
		CanCollide = false,
		Parent = parent,
	})
end

local function addDetails(decor: Instance, roof: Instance, origin: CFrame, index: number)
	local half = Barn.SIZE / 2 - 0.5
	local top = 1 + Barn.WALL_HEIGHT
	local doorHalf = Barn.DOOR_WIDTH / 2
	local battenHeight = Barn.WALL_HEIGHT - 2.2
	local battenY = 1.6 + battenHeight / 2
	local function batten(cframe: CFrame)
		part({
			Name = "Batten",
			Size = Vector3.new(0.6, battenHeight, 0.3),
			CFrame = cframe,
			Color = BATTEN,
			Material = Enum.Material.WoodPlanks,
			CanCollide = false,
			Parent = decor,
		})
	end
	-- Board-and-batten: dark strips down the outside of every wall, skipping the doorway and
	-- the windows.
	for x = -half + 4, half - 4, 4 do
		if math.abs(x) > doorHalf + 2 and math.abs(x - 21) > 4.5 then
			batten(origin * CFrame.new(x, battenY, -half - 0.6))
		end
		batten(origin * CFrame.new(x, battenY, half + 0.6))
	end
	for z = -half + 4, half - 4, 4 do
		if math.abs(math.abs(z) - 12) > 4 then
			for _, side in { -1, 1 } do
				batten(origin * CFrame.new(side * (half + 0.6), battenY, z) * CFrame.Angles(0, math.pi / 2, 0))
			end
		end
	end

	-- Shutters and flower boxes on the side windows (outside).
	for _, side in { -1, 1 } do
		for k, z in { -12, 12 } do
			local face = origin * CFrame.new(side * (half + 0.75), 11, z) * CFrame.Angles(0, side * -math.pi / 2, 0)
			for _, dx in { -1, 1 } do
				bracedPanel(decor, face * CFrame.new(dx * 4.4, 0, 0), 2.6, 6.2, SHUTTER, "Shutter")
			end
			flowerBox(decor, face * CFrame.new(0, -3.7, -0.4), 6.4, index + k + side)
		end
	end

	-- The front window opposite the name plaque, with shutters and a flower box.
	local front = origin * CFrame.new(21, 9, -half - 0.6) * CFrame.Angles(0, 0, 0)
	part({
		Name = "WindowFrame",
		Size = Vector3.new(6, 6, 0.4),
		CFrame = front,
		Color = WHITE,
		CanCollide = false,
		Parent = decor,
	})
	part({
		Name = "WindowPane",
		Size = Vector3.new(5, 5, 0.45),
		CFrame = front,
		Color = Color3.fromRGB(255, 220, 140),
		Material = Enum.Material.Neon,
		Transparency = 0.25,
		CanCollide = false,
		Parent = decor,
	})
	for _, bar in { Vector3.new(0.4, 5, 0.5), Vector3.new(5, 0.4, 0.5) } do
		part({ Name = "WindowBar", Size = bar, CFrame = front, Color = WHITE, CanCollide = false, Parent = decor })
	end
	for _, dx in { -1, 1 } do
		bracedPanel(decor, front * CFrame.new(dx * 4.4, 0, -0.1), 2.6, 6.2, SHUTTER, "Shutter")
	end
	flowerBox(decor, front * CFrame.new(0, -3.7, -0.5), 6.4, index)

	-- Hayloft door high on the front gable, hay spilling out, and the hoist beam above.
	local loft = origin * CFrame.new(0, top + 4.6, -half - 0.6)
	part({
		Name = "LoftDark",
		Size = Vector3.new(7.4, 6.4, 0.3),
		CFrame = loft * CFrame.new(0, 0, 0.1),
		Color = Color3.fromRGB(45, 25, 20),
		CanCollide = false,
		Parent = roof,
	})
	for _, dx in { -1, 1 } do
		-- The two loft doors stand open, swung out to the sides.
		bracedPanel(roof, loft * CFrame.new(dx * 5.6, 0, -0.1), 3.6, 6.4, RED, "DoorPanel")
	end
	part({
		Name = "LoftSill",
		Size = Vector3.new(8.2, 0.6, 1.6),
		CFrame = loft * CFrame.new(0, -3.4, -0.6),
		Color = WHITE,
		CanCollide = false,
		Parent = roof,
	})
	for k = 1, 7 do
		part({
			Name = "Hay",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * (1.2 + (k % 3) * 0.35),
			CFrame = loft * CFrame.new((k - 4) * 0.95, -2.5 + (k % 2) * 0.4, -0.6),
			Color = HAY:Lerp(Color3.fromRGB(210, 165, 60), (k % 3) / 3),
			Material = Enum.Material.Sand,
			CanCollide = false,
			Parent = roof,
		})
	end
	part({
		Name = "HoistBeam",
		Size = Vector3.new(1.2, 1.2, 5),
		CFrame = loft * CFrame.new(0, 5, -2.2),
		Color = DARK_WOOD,
		Material = Enum.Material.WoodPlanks,
		CanCollide = false,
		Parent = roof,
	})
	part({
		Name = "HoistRope",
		Size = Vector3.new(0.2, 4, 0.2),
		CFrame = loft * CFrame.new(0, 2.6, -4.2),
		Color = Color3.fromRGB(200, 170, 110),
		CanCollide = false,
		Parent = roof,
	})
	part({
		Name = "HoistHook",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 0.7,
		CFrame = loft * CFrame.new(0, 0.5, -4.2),
		Color = Color3.fromRGB(70, 70, 80),
		Material = Enum.Material.Metal,
		CanCollide = false,
		Parent = roof,
	})
	-- A round window high on the back gable.
	local back = origin * CFrame.new(0, top + 6, half + 0.6)
	part({
		Name = "WindowFrame",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 6, 6),
		CFrame = back * CFrame.Angles(0, math.pi / 2, 0),
		Color = WHITE,
		CanCollide = false,
		Parent = roof,
	})
	part({
		Name = "WindowPane",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.45, 4.6, 4.6),
		CFrame = back * CFrame.Angles(0, math.pi / 2, 0),
		Color = Color3.fromRGB(255, 220, 140),
		Material = Enum.Material.Neon,
		Transparency = 0.25,
		CanCollide = false,
		Parent = roof,
	})

	-- Shingle rows across each roof slope.
	local profile = {
		Vector2.new(-(half + 1.5), top - 0.6),
		Vector2.new(-23, top + 10.4),
		Vector2.new(0, top + 15.4),
		Vector2.new(23, top + 10.4),
		Vector2.new(half + 1.5, top - 0.6),
	}
	for i = 1, #profile - 1 do
		local a, b = profile[i], profile[i + 1]
		local angle = math.atan2(b.Y - a.Y, b.X - a.X)
		local normal = Vector2.new(-math.sin(angle), math.cos(angle))
		local rows = if (b - a).Magnitude > 15 then 4 else 2
		for k = 1, rows do
			local p = a:Lerp(b, k / (rows + 1)) + normal * 0.55
			part({
				Name = "RoofShingle",
				Size = Vector3.new(0.9, 0.45, Barn.SIZE + 2),
				CFrame = origin * CFrame.new(p.X, p.Y, 0) * CFrame.Angles(0, 0, angle),
				Color = ROOF:Lerp(Color3.new(0, 0, 0), 0.3),
				Material = Enum.Material.Slate,
				CanCollide = false,
				Parent = roof,
			})
		end
	end

	-- Outside: barrels by the front left corner, a water trough and churns by the right.
	barrel(decor, origin * CFrame.new(-29, 0, -half - 3))
	barrel(decor, origin * CFrame.new(-26.2, 0, -half - 2.6))
	churn(decor, origin * CFrame.new(-27.7, 0, -half - 5))
	local trough = origin * CFrame.new(28.5, 0, -half - 3.2)
	part({
		Name = "Trough",
		Size = Vector3.new(6, 1.8, 2.6),
		CFrame = trough * CFrame.new(0, 1.2, 0),
		Color = WOOD,
		Material = Enum.Material.WoodPlanks,
		Parent = decor,
	})
	part({
		Name = "TroughWater",
		Size = Vector3.new(5.2, 0.2, 1.9),
		CFrame = trough * CFrame.new(0, 2, 0),
		Color = Color3.fromRGB(90, 190, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.2,
		CanCollide = false,
		Parent = decor,
	})
	for _, dx in { -2.4, 2.4 } do
		part({
			Name = "TroughLeg",
			Size = Vector3.new(0.6, 0.6, 3),
			CFrame = trough * CFrame.new(dx, 0.3, 0),
			Color = DARK_WOOD,
			CanCollide = false,
			Parent = decor,
		})
	end
	churn(decor, origin * CFrame.new(24.6, 0, -half - 3))
end

-- Builds the barn. Returns { barrier, locked } for Barn.setLocked.
function Barn.build(folder: Instance, decor: Instance, origin: CFrame, index: number)
	local half = Barn.SIZE / 2 - 0.5 -- wall centre lines
	local top = 1 + Barn.WALL_HEIGHT
	local doorHalf = Barn.DOOR_WIDTH / 2
	local doorTop = 1 + Barn.DOOR_HEIGHT

	part({
		Name = "Base",
		Size = Vector3.new(Barn.SIZE, 1, Barn.SIZE),
		CFrame = origin * CFrame.new(0, 0.5, 0),
		Color = FLOOR,
		Material = Enum.Material.WoodPlanks,
		Parent = folder,
	})

	-- Walls, with the doorway in the middle of the front.
	local side = (Barn.SIZE - Barn.DOOR_WIDTH) / 2
	local walls = {
		{ Vector3.new(Barn.SIZE, Barn.WALL_HEIGHT, 1), Vector3.new(0, 1 + Barn.WALL_HEIGHT / 2, half) },
		{ Vector3.new(1, Barn.WALL_HEIGHT, Barn.SIZE), Vector3.new(-half, 1 + Barn.WALL_HEIGHT / 2, 0) },
		{ Vector3.new(1, Barn.WALL_HEIGHT, Barn.SIZE), Vector3.new(half, 1 + Barn.WALL_HEIGHT / 2, 0) },
		{
			Vector3.new(side, Barn.WALL_HEIGHT, 1),
			Vector3.new(-(doorHalf + side / 2), 1 + Barn.WALL_HEIGHT / 2, -half),
		},
		{ Vector3.new(side, Barn.WALL_HEIGHT, 1), Vector3.new(doorHalf + side / 2, 1 + Barn.WALL_HEIGHT / 2, -half) },
		{ Vector3.new(Barn.DOOR_WIDTH, top - doorTop, 1), Vector3.new(0, (top + doorTop) / 2, -half) },
	}
	for _, wall in walls do
		part({
			Name = "Wall",
			Size = wall[1],
			CFrame = origin * CFrame.new(wall[2]),
			Color = RED,
			Material = Enum.Material.WoodPlanks,
			Parent = folder,
		})
	end
	part({
		Name = "Ceiling",
		Size = Vector3.new(Barn.SIZE - 1, 1.2, Barn.SIZE - 1),
		CFrame = origin * CFrame.new(0, top + 0.6, 0),
		Transparency = 1,
		Parent = folder,
	})

	-- White corner posts, a white band along the top of the walls, and a stone footing.
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			part({
				Name = "CornerTrim",
				Size = Vector3.new(1.6, Barn.WALL_HEIGHT + 0.4, 1.6),
				CFrame = origin * CFrame.new(x * (half + 0.1), 1 + Barn.WALL_HEIGHT / 2, z * (half + 0.1)),
				Color = WHITE,
				Parent = decor,
			})
		end
	end
	for _, band in
		{
			{ Vector3.new(Barn.SIZE + 0.4, 0.8, 1.4), Vector3.new(0, top - 0.4, -half) },
			{ Vector3.new(Barn.SIZE + 0.4, 0.8, 1.4), Vector3.new(0, top - 0.4, half) },
			{ Vector3.new(1.4, 0.8, Barn.SIZE + 0.4), Vector3.new(-half, top - 0.4, 0) },
			{ Vector3.new(1.4, 0.8, Barn.SIZE + 0.4), Vector3.new(half, top - 0.4, 0) },
		}
	do
		part({ Name = "EaveTrim", Size = band[1], CFrame = origin * CFrame.new(band[2]), Color = WHITE, Parent = decor })
		part({
			Name = "Footing",
			Size = band[1] + Vector3.new(0.4, 0.6, 0.4),
			CFrame = origin * CFrame.new(band[2].X, 0.7, band[2].Z),
			Color = Color3.fromRGB(150, 145, 140),
			Material = Enum.Material.Slate,
			Parent = decor,
		})
	end

	-- Windows on both side walls (inside and out).
	for _, x in { -1, 1 } do
		for _, z in { -12, 12 } do
			for _, face in { 1, -1 } do
				local spot = origin * CFrame.new(x * (half + face * 0.55), 11, z)
				part({
					Name = "WindowFrame",
					Size = Vector3.new(0.3, 6, 6),
					CFrame = spot,
					Color = WHITE,
					CanCollide = false,
					Parent = decor,
				})
				part({
					Name = "WindowPane",
					Size = Vector3.new(0.35, 5, 5),
					CFrame = spot,
					Color = Color3.fromRGB(70, 95, 120),
					Material = Enum.Material.Glass,
					CanCollide = false,
					Parent = decor,
				})
				for _, bar in { Vector3.new(0.4, 5, 0.4), Vector3.new(0.4, 0.4, 5) } do
					part({
						Name = "WindowBar",
						Size = bar,
						CFrame = spot,
						Color = WHITE,
						CanCollide = false,
						Parent = decor,
					})
				end
			end
		end
	end

	-- Gambrel roof: four slopes along the barn, front to back, plus the gable ends.
	local roof = Instance.new("Folder")
	roof.Name = "Roof"
	roof.Parent = folder
	local profile = {
		Vector2.new(-(half + 1.5), top - 0.6),
		Vector2.new(-23, top + 10.4),
		Vector2.new(0, top + 15.4),
		Vector2.new(23, top + 10.4),
		Vector2.new(half + 1.5, top - 0.6),
	}
	for i = 1, #profile - 1 do
		local a, b = profile[i], profile[i + 1]
		local middle = (a + b) / 2
		local length = (b - a).Magnitude
		local angle = math.atan2(b.Y - a.Y, b.X - a.X)
		part({
			Name = "RoofSlope",
			Size = Vector3.new(length + 0.6, 1, Barn.SIZE + 2),
			CFrame = origin * CFrame.new(middle.X, middle.Y, 0) * CFrame.Angles(0, 0, angle),
			Color = ROOF,
			Material = Enum.Material.Slate,
			Parent = roof,
		})
		-- White trim along the roof edge at both gable ends.
		for _, z in { -(half + 1.05), half + 1.05 } do
			part({
				Name = "RoofTrim",
				Size = Vector3.new(length + 0.6, 0.7, 0.4),
				CFrame = origin * CFrame.new(middle.X, middle.Y - 0.2, z) * CFrame.Angles(0, 0, angle),
				Color = WHITE,
				Parent = roof,
			})
		end
	end
	part({
		Name = "RidgeCap",
		Size = Vector3.new(1.4, 1.2, Barn.SIZE + 2.4),
		CFrame = origin * CFrame.new(0, top + 15.9, 0),
		Color = Color3.fromRGB(50, 40, 44),
		Material = Enum.Material.Slate,
		Parent = roof,
	})
	-- Gable ends: a rectangle plus four wedges filling the gambrel shape.
	for _, z in { -half, half } do
		part({
			Name = "Gable",
			Size = Vector3.new(46, 10, 1),
			CFrame = origin * CFrame.new(0, top + 5, z),
			Color = RED,
			Material = Enum.Material.WoodPlanks,
			Parent = roof,
		})
		for _, piece in
			{
				{ Vector3.new(1, 10, half - 23 + 0.5), Vector3.new(-(23 + half + 0.5) / 2, top + 5, z), math.pi / 2 },
				{ Vector3.new(1, 10, half - 23 + 0.5), Vector3.new((23 + half + 0.5) / 2, top + 5, z), -math.pi / 2 },
				{ Vector3.new(1, 5, 23), Vector3.new(-11.5, top + 12.5, z), math.pi / 2 },
				{ Vector3.new(1, 5, 23), Vector3.new(11.5, top + 12.5, z), -math.pi / 2 },
			}
		do
			wedge({
				Name = "Gable",
				Size = piece[1],
				CFrame = origin * CFrame.new(piece[2]) * CFrame.Angles(0, piece[3], 0),
				Color = RED,
				Material = Enum.Material.WoodPlanks,
				Parent = roof,
			})
		end
	end

	-- Hanging lanterns so the inside isn't dark.
	for _, x in { -14, 14 } do
		for _, z in { -6, 16 } do
			part({
				Name = "LanternChain",
				Size = Vector3.new(0.2, 2.6, 0.2),
				CFrame = origin * CFrame.new(x, top - 1.3, z),
				Color = Color3.fromRGB(60, 60, 60),
				CanCollide = false,
				Parent = decor,
			})
			local lantern = part({
				Name = "Lantern",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * 1.4,
				CFrame = origin * CFrame.new(x, top - 3, z),
				Color = Color3.fromRGB(255, 215, 140),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = decor,
			})
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 210, 150)
			light.Range = 30
			light.Brightness = 1.4
			light.Shadows = false
			light.Parent = lantern
		end
	end

	-- Hay bales in the front corners inside, and outside by the doors.
	for _, x in { -26, 26 } do
		Decor.hayBale(decor, origin * CFrame.new(x, 1, -27) * CFrame.Angles(0, math.pi / 2, 0))
	end
	for _, x in { -1, 1 } do
		Decor.lamp(decor, origin * CFrame.new(x * 12, 0.3, -half - 3))
		Decor.tree(decor, origin * CFrame.new(x * 24, 0, half + 8), 0.9, index * 10 + x)
	end

	-- The rail the doors slide along, and the doors themselves.
	part({
		Name = "DoorRail",
		Size = Vector3.new(Barn.DOOR_WIDTH * 2 + 4, 0.6, 0.6),
		CFrame = origin * CFrame.new(0, doorTop + 0.9, -half - 1.1),
		Color = Color3.fromRGB(45, 45, 52),
		Material = Enum.Material.Metal,
		CanCollide = false,
		Parent = decor,
	})
	-- The doors always stand slid open; locking fills the doorway with a red barrier.
	for _, x in { -1, 1 } do
		local w = doorHalf + 0.2
		local closed = origin * CFrame.new(x * w / 2, 1 + (Barn.DOOR_HEIGHT + 0.2) / 2, -half - 0.85)
		local door = buildDoor(folder, closed * CFrame.new(x * (w + 0.4), 0, 0), index)
		door.PrimaryPart.CanCollide = false
	end
	local barrier = part({
		Name = "Barrier",
		Size = Vector3.new(Barn.DOOR_WIDTH, Barn.DOOR_HEIGHT, 0.6),
		CFrame = origin * CFrame.new(0, 1 + Barn.DOOR_HEIGHT / 2, -half),
		Color = Color3.fromRGB(255, 50, 50),
		Material = Enum.Material.ForceField,
		CollisionGroup = "Gate" .. index,
		CastShadow = false,
		Parent = folder,
	})
	addDetails(decor, roof, origin, index)
	return { barrier = barrier, locked = nil }
end

-- Puts the red barrier up (solid to everyone but the owner) or takes it down.
function Barn.setLocked(barn, locked: boolean)
	if barn.locked == locked then
		return
	end
	barn.locked = locked
	barn.barrier.CanCollide = locked
	barn.barrier.Transparency = if locked then 0.15 else 1
end

return Barn
