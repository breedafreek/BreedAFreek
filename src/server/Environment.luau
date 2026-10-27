-- Lighting, sky, terrain and the town: the street between the two rows of homes, the
-- spawn, the title sign and the edges of the map.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Lego = require(ReplicatedStorage.Shared.Lego)
local ZoneLayout = require(ReplicatedStorage.Shared.ZoneLayout)

local Decor = require(script.Parent.Decor)

local Environment = {}

local function effect(className: string, props)
	local existing = Lighting:FindFirstChildOfClass(className)
	local instance = existing or Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = Lighting
	return instance
end

local function setupLighting()
	-- Bright, clean daylight that makes shiny plastic look like plastic: a high sun, crisp
	-- soft-edged shadows, gentle reflections and colour correction that doesn't overdo it.
	Lighting.ClockTime = 14
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(95, 95, 110)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 150)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.15
	Lighting.GeographicLatitude = 35

	effect("Sky", { SunAngularSize = 14, MoonAngularSize = 9, StarCount = 3000 })
	effect("Atmosphere", {
		Density = 0.12, -- clear air, so far-off colours stay bright
		Offset = 0.15,
		Color = Color3.fromRGB(200, 215, 240),
		Decay = Color3.fromRGB(110, 130, 170),
		Glare = 0.25,
		Haze = 0.2,
	})
	effect("BloomEffect", { Intensity = 0.4, Size = 24, Threshold = 2 })
	effect("SunRaysEffect", { Intensity = 0.04, Spread = 0.6 })
	effect("ColorCorrectionEffect", {
		Brightness = 0.02,
		Contrast = 0.1,
		Saturation = 0.12,
		TintColor = Color3.fromRGB(255, 252, 245),
	})

	local clouds = Workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.55
	clouds.Density = 0.6
	clouds.Color = Color3.fromRGB(255, 255, 255)
	clouds.Parent = Workspace.Terrain
end

local function setupTerrain()
	local terrain = Workspace.Terrain
	-- Clear all terrain near or above ground level over the whole map. The town, the yards
	-- and the zones have their own brick floors at y = 0; terrain is stored in 4-stud voxels,
	-- so even grass meant to stop at y = 0 can bulge up through them and bury the yards.
	-- Done in small chunks: one huge fill can fail outright.
	local west = ZoneLayout.westEnd() - 100
	local CHUNK = 256
	local function fill(x0: number, x1: number, z0: number, z1: number, y0: number, y1: number, material)
		for x = x0, x1 - 1, CHUNK do
			for z = z0, z1 - 1, CHUNK do
				local sx, sz = math.min(CHUNK, x1 - x), math.min(CHUNK, z1 - z)
				local ok, err = pcall(function()
					terrain:FillBlock(
						CFrame.new(x + sx / 2, (y0 + y1) / 2, z + sz / 2),
						Vector3.new(sx, y1 - y0, sz),
						material
					)
				end)
				if not ok then
					warn("[Environment] terrain fill failed: " .. tostring(err))
				end
			end
		end
	end
	fill(west, 512, -512, 512, -12, 256, Enum.Material.Air)
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(95, 175, 80))
	terrain:SetMaterialColor(Enum.Material.Pavement, Color3.fromRGB(196, 190, 180))
	-- No tall grass blades: they hide the feet of anything standing on the grass.
	pcall(function()
		terrain.Decoration = false
	end)
end

local OUTLINE = Color3.fromRGB(20, 22, 48)

local STREET_EAST = 232
local STREET_WEST = ZoneLayout.START_X
local TOWN_HALF = 134 -- how far north and south the town goes (past the back of the homes)

local function outlinedBillboard(parent: Instance, text: string, color: Color3, size: UDim2, maxDistance: number)
	local gui = Instance.new("BillboardGui")
	gui.Size = size
	gui.MaxDistance = maxDistance
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.LuckiestGuy
	label.Text = text
	label.TextColor3 = color
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE
	stroke.Thickness = 5
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	gui.Parent = parent
	return label
end

local function buildScenery()
	local folder = Instance.new("Folder")
	folder.Name = "Scenery"
	folder.Parent = Workspace

	-- A big checkerboard baseplate under the whole town, studs and all.
	Decor.checkerFloor(
		folder,
		CFrame.new((STREET_EAST + STREET_WEST) / 2, 0.02, 0),
		STREET_EAST - STREET_WEST + 16,
		TOWN_HALF * 2 + 4,
		12,
		Color3.fromRGB(64, 196, 70),
		Color3.fromRGB(52, 176, 60),
		"Baseplate"
	)

	-- The street: a road with a dashed line, sidewalks with curbs, lamps.
	local length = STREET_EAST - STREET_WEST
	local centerX = (STREET_EAST + STREET_WEST) / 2
	Decor.part({
		Name = "Road",
		Size = Vector3.new(length, 0.3, 20),
		CFrame = CFrame.new(centerX, 0.15, 0),
		Color = Color3.fromRGB(70, 72, 82),
		Material = Enum.Material.Asphalt,
		Parent = folder,
	})
	for x = STREET_WEST + 6, STREET_EAST - 6, 12 do
		Decor.part({
			Name = "RoadLine",
			Size = Vector3.new(6, 0.32, 0.8),
			CFrame = CFrame.new(x, 0.16, 0),
			Color = Color3.fromRGB(255, 215, 70),
			CanCollide = false,
			Parent = folder,
		})
	end
	for _, side in { -1, 1 } do
		Decor.part({
			Name = "Sidewalk",
			Size = Vector3.new(length, 0.5, 8),
			CFrame = CFrame.new(centerX, 0.25, side * 14),
			Color = Color3.fromRGB(205, 200, 192),
			Material = Enum.Material.Pavement,
			Parent = folder,
		})
		Decor.part({
			Name = "Curb",
			Size = Vector3.new(length, 0.6, 0.8),
			CFrame = CFrame.new(centerX, 0.3, side * 10.2),
			Color = Color3.fromRGB(150, 145, 140),
			Material = Enum.Material.Concrete,
			Parent = folder,
		})
		for x = -208, 208, 52 do
			Decor.lamp(folder, CFrame.new(x, 0.5, side * 17.5))
		end
		-- Trees on the verge between the homes.
		for x = -104, 104, 104 do
			Decor.tree(folder, CFrame.new(x, 0, side * 26), 1.2, math.abs(x) + side)
		end
	end

	-- The spawn at the east end, with flower beds.
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(STREET_EAST - 22, 0.5, 0)
	spawn.Color = Color3.fromRGB(255, 220, 120)
	spawn.Material = Enum.Material.Marble
	spawn.TopSurface = Enum.SurfaceType.Smooth
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	spawn.Parent = folder
	Decor.flowerBed(folder, CFrame.new(STREET_EAST - 22, 0, -12), 10, 3, 4)
	Decor.flowerBed(folder, CFrame.new(STREET_EAST - 22, 0, 12), 10, 3, 5)

	-- The title, high over the street.
	local title = Decor.part({
		Name = "TitleSign",
		Size = Vector3.one,
		CFrame = CFrame.new(0, 58, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = folder,
	})
	outlinedBillboard(title, "STEAL A LIFE", Color3.fromRGB(255, 225, 80), UDim2.fromScale(44, 9), 500)

	-- A signpost at the west end of the street pointing to the zones.
	local signpost = CFrame.new(STREET_WEST + 10, 0, -14)
	Decor.part({
		Name = "SignPost",
		Size = Vector3.new(1, 12, 1),
		CFrame = signpost * CFrame.new(0, 6, 0),
		Color = Color3.fromRGB(120, 80, 50),
		Material = Enum.Material.Wood,
		Parent = folder,
	})
	local board = Decor.part({
		Name = "SignBoard",
		Size = Vector3.new(1, 3.4, 12),
		CFrame = signpost * CFrame.new(0, 10, 4),
		Color = Color3.fromRGB(255, 230, 150),
		Material = Enum.Material.WoodPlanks,
		Parent = folder,
	})
	outlinedBillboard(board, "🥚 EGG ZONES ➜", Color3.fromRGB(255, 120, 80), UDim2.fromScale(12, 3), 160)

	-- Edges of the map: hedges along the back of the homes, invisible walls all round the
	-- town (the zones have their own cliffs).
	for _, side in { -1, 1 } do
		for x = STREET_WEST, STREET_EAST, 9 do
			Decor.bush(folder, CFrame.new(x, 0, side * (TOWN_HALF - 2)), 1.5, x + side)
		end
	end
	local walls = {
		{ Vector3.new(length + 10, 60, 2), Vector3.new(centerX, 30, TOWN_HALF) },
		{ Vector3.new(length + 10, 60, 2), Vector3.new(centerX, 30, -TOWN_HALF) },
		{ Vector3.new(2, 60, TOWN_HALF * 2), Vector3.new(STREET_EAST, 30, 0) },
	}
	-- West edge of town, either side of the way into the zones.
	local gapHalf = ZoneLayout.WIDTH / 2 + 6
	local westLength = TOWN_HALF - gapHalf
	for _, side in { -1, 1 } do
		table.insert(
			walls,
			{ Vector3.new(2, 60, westLength), Vector3.new(STREET_WEST, 30, side * (gapHalf + westLength / 2)) }
		)
	end
	for _, wall in walls do
		Decor.part({
			Name = "MapEdge",
			Size = wall[1],
			CFrame = CFrame.new(wall[2]),
			Transparency = 1,
			CanQuery = false,
			Parent = folder,
		})
	end
end

function Environment.init()
	-- Everything built from here on gets the LEGO look (Environment starts first).
	Lego.watch(Workspace)
	setupLighting()
	setupTerrain()
	buildScenery()
end

return Environment
