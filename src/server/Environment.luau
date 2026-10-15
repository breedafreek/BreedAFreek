-- Lighting, sky, terrain and the scenery around the yards and conveyor.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Drops = require(ReplicatedStorage.Shared.Drops)

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
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(70, 70, 90)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 135, 150)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.25
	Lighting.GeographicLatitude = 35

	effect("Sky", { SunAngularSize = 14, MoonAngularSize = 9, StarCount = 3000 })
	effect("Atmosphere", {
		Density = 0.28,
		Offset = 0.15,
		Color = Color3.fromRGB(200, 215, 240),
		Decay = Color3.fromRGB(110, 130, 170),
		Glare = 0.25,
		Haze = 1.2,
	})
	effect("BloomEffect", { Intensity = 0.6, Size = 26, Threshold = 1.6 })
	effect("SunRaysEffect", { Intensity = 0.06, Spread = 0.7 })
	effect("ColorCorrectionEffect", {
		Brightness = 0.02,
		Contrast = 0.08,
		Saturation = 0.15,
		TintColor = Color3.fromRGB(255, 250, 242),
	})

	local clouds = Workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.55
	clouds.Density = 0.6
	clouds.Color = Color3.fromRGB(255, 255, 255)
	clouds.Parent = Workspace.Terrain
end

local function setupTerrain()
	local terrain = Workspace.Terrain
	-- Grass everywhere, with the top of the terrain at y = 0.
	terrain:FillBlock(CFrame.new(0, -4, 0), Vector3.new(600, 8, 600), Enum.Material.Grass)
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(95, 175, 80))
	terrain:SetMaterialColor(Enum.Material.Pavement, Color3.fromRGB(196, 190, 180))
end

local function buildScenery()
	local folder = Instance.new("Folder")
	folder.Name = "Scenery"
	folder.Parent = Workspace

	-- The town square between the barn rows, where cannon Freeks land and wander: grass in
	-- the middle, a paved walkway in front of each row of barns, and street lamps in the
	-- gaps between the barns.
	local length = (Drops.AREA.maxX - Drops.AREA.minX) + 40
	local centerX = (Drops.AREA.maxX + Drops.AREA.minX) / 2
	for _, side in { -1, 1 } do
		Decor.part({
			Name = "Walkway",
			Size = Vector3.new(length, 0.3, 8),
			CFrame = CFrame.new(centerX, 0.15, side * 28),
			Color = Color3.fromRGB(200, 194, 184),
			Material = Enum.Material.Pavement,
			Parent = folder,
		})
		Decor.part({
			Name = "Curb",
			Size = Vector3.new(length, 0.5, 0.8),
			CFrame = CFrame.new(centerX, 0.25, side * 23.8),
			Color = Color3.fromRGB(150, 145, 140),
			Material = Enum.Material.Concrete,
			Parent = folder,
		})
		for _, x in { -140, -70, 0, 70, 140 } do
			Decor.lamp(folder, CFrame.new(x, 0.3, side * 28.5))
		end
	end

	-- A ring of trees around the edge of the map.
	local seed = 10
	for x = -200, 200, 26 do
		for _, z in { -150, 150 } do
			seed += 1
			Decor.tree(folder, CFrame.new(x + (seed % 5) * 2, 0, z + (seed % 3) * 4), 1.2 + (seed % 4) * 0.15, seed)
		end
	end
	for z = -124, 124, 26 do
		for _, x in { -210, 210 } do
			seed += 1
			Decor.tree(folder, CFrame.new(x + (seed % 3) * 4, 0, z), 1.2 + (seed % 4) * 0.15, seed)
		end
	end
	-- Bushes and flowers by the spawn.
	Decor.flowerBed(folder, CFrame.new(150, 0, -12), 10, 3, 4)
	Decor.flowerBed(folder, CFrame.new(150, 0, 12), 10, 3, 5)
	Decor.bush(folder, CFrame.new(158, 0, -18), 1.3, 6)
	Decor.bush(folder, CFrame.new(158, 0, 18), 1.3, 7)
end

function Environment.init()
	setupLighting()
	setupTerrain()
	buildScenery()
end

return Environment
