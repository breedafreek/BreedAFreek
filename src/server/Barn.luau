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
