-- Seasonal themes: while an event is running, the map dresses up for it (recoloured
-- trees, props, lighting) and goes back to normal when the event ends. Checked every two
-- minutes, so themes switch on and off without restarting servers.
--
-- To add a theme for another event, add an entry to THEMES keyed by its Seasons id.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Belt = require(ReplicatedStorage.Shared.Belt)
local Seasons = require(ReplicatedStorage.Shared.Seasons)

local Decor = require(script.Parent.Decor)
local HalloweenDecor = require(script.Parent.HalloweenDecor)
local PlotService = require(script.Parent.PlotService)

local SeasonalService = {}

local current = nil -- id of the theme on show, or nil
local folder = nil -- props added by the current theme
local defaults = {} -- lighting/terrain values to restore

-- Pick a colour from a palette based on a part's position, so it's stable but varied.
local function pick(palette, part: BasePart)
	local p = part.Position
	local index = math.floor(math.abs(p.X * 7 + p.Y * 13 + p.Z * 3)) % #palette + 1
	return palette[index]
end

local function facingBelt(position: Vector3): CFrame
	return CFrame.lookAt(position, Vector3.new(position.X, position.Y, 0))
end

local THEMES = {}

THEMES.Halloween = {
	leaves = Decor.FALL_LEAVES,
	grass = Color3.fromRGB(150, 165, 75),
	lawn = Color3.fromRGB(150, 170, 80),
	bulb = Color3.fromRGB(255, 140, 40),
	-- Spooky twilight: sun on the horizon, purple haze, extra glow on lights and pumpkins.
	lighting = {
		Lighting = {
			ClockTime = 18.1,
			Brightness = 1.8,
			Ambient = Color3.fromRGB(80, 60, 100),
			OutdoorAmbient = Color3.fromRGB(135, 110, 160),
		},
		Atmosphere = {
			Density = 0.36,
			Color = Color3.fromRGB(190, 130, 190),
			Decay = Color3.fromRGB(70, 35, 90),
			Haze = 2.2,
			Glare = 0.4,
		},
		ColorCorrectionEffect = {
			TintColor = Color3.fromRGB(255, 228, 240),
			Saturation = 0.25,
			Contrast = 0.12,
		},
		BloomEffect = { Intensity = 0.9 },
	},
	build = function(props: Folder)
		-- Every yard: jack-o'-lanterns flanking the gate, one inside by the pens, and a
		-- pile of leaves under each corner tree.
		for i, origin in PlotService.origins() do
			for _, side in { -1, 1 } do
				Decor.pumpkin(props, origin * CFrame.new(side * 10.5, 0, -33.5), 1) -- outside, on the grass
				Decor.pumpkin(props, origin * CFrame.new(side * 21, 1, -24.5), 0.8) -- on the lawn
				Decor.leafPile(props, origin * CFrame.new(side * 27, 1, -21), i * 10 + side)
			end
		end
		-- Pumpkins between the lamps along both walkways, facing the conveyor.
		for x = Belt.START_X + 27.5, Belt.START_X + Belt.LENGTH - 10, 35 do
			for _, z in { -27.5, 27.5 } do
				Decor.pumpkin(props, facingBelt(Vector3.new(x, 0.3, z)), 0.9)
			end
		end
		-- Hay bales topped with pumpkins by the Freek Houses and the spawn.
		local houseX = Belt.START_X - 9
		for _, spot in
			{
				Vector3.new(houseX, 0, -15),
				Vector3.new(houseX, 0, 15),
				Vector3.new(houseX + 8, 0, -16),
				Vector3.new(houseX + 8, 0, 16),
				Vector3.new(150, 0, -7),
				Vector3.new(150, 0, 7),
			}
		do
			local ground = facingBelt(spot)
			Decor.hayBale(props, ground)
			Decor.pumpkin(props, ground * CFrame.new(0, 2.4, 0), 0.8)
		end
		for _, z in { -9, 9 } do
			Decor.pumpkin(props, CFrame.new(132, 0, z) * CFrame.Angles(0, math.pi / 2, 0), 1.2)
		end
		-- Leaf piles scattered along the tree line.
		for x = -190, 190, 38 do
			for _, z in { -142, 142 } do
				Decor.leafPile(props, CFrame.new(x, 0, z), x + z)
			end
		end

		-- Every yard's gate arch: cobwebs in the top corners and string lights along the beam.
		local half = 31.5
		for _, origin in PlotService.origins() do
			HalloweenDecor.cobweb(props, origin * CFrame.new(-6.8, 10.8, -half - 0.8), 3)
			HalloweenDecor.cobweb(props, origin * CFrame.new(6.8, 10.8, -half - 0.8) * CFrame.Angles(0, math.pi, 0), 3)
			HalloweenDecor.stringLights(
				props,
				(origin * CFrame.new(-7.6, 10.7, -half - 0.9)).Position,
				(origin * CFrame.new(7.6, 10.7, -half - 0.9)).Position,
				10,
				0.8
			)
		end

		-- String lights between the street lamps along both walkways, and low fog.
		for x = Belt.START_X + 10, Belt.START_X + Belt.LENGTH - 45, 35 do
			for _, z in { -28, 28 } do
				HalloweenDecor.stringLights(props, Vector3.new(x, 7.6, z), Vector3.new(x + 35, 7.6, z), 14, 1.8)
			end
		end
		for x = Belt.START_X, Belt.START_X + Belt.LENGTH, 40 do
			for _, z in { -20, 20 } do
				HalloweenDecor.fog(props, Vector3.new(x, 0.5, z))
			end
		end

		-- Witch hats on both Freek Houses.
		HalloweenDecor.witchHat(props, CFrame.new(houseX + 2, 14.6, Belt.LANES[1]), 0.9, Color3.fromRGB(70, 30, 110))
		HalloweenDecor.witchHat(props, CFrame.new(houseX + 2, 14.6, Belt.LANES[2]), 0.9, Color3.fromRGB(40, 25, 60))

		-- A graveyard past the spawn, with dead trees, fog and a bubbling cauldron.
		for row = 0, 1 do
			for col = 0, 4 do
				local ground = CFrame.new(172 + row * 9, 0, -16 + col * 8) * CFrame.Angles(0, -math.pi / 2, 0)
				HalloweenDecor.tombstone(props, ground, row * 10 + col)
			end
		end
		HalloweenDecor.deadTree(props, CFrame.new(190, 0, -22), 1.2, 1)
		HalloweenDecor.deadTree(props, CFrame.new(188, 0, 21), 1, 2)
		HalloweenDecor.deadTree(props, CFrame.new(-150, 0, -24), 1.1, 3)
		HalloweenDecor.deadTree(props, CFrame.new(-150, 0, 26), 1.2, 4)
		for _, spot in { Vector3.new(176, 0.5, -10), Vector3.new(180, 0.5, 8), Vector3.new(170, 0.5, 18) } do
			HalloweenDecor.fog(props, spot)
		end
		HalloweenDecor.cauldron(props, CFrame.new(160, 0, 0))

		-- Ghosts drifting around; bats circling the Freek Houses, the graveyard and the title.
		local houses = Vector3.new(houseX, 0, 0)
		HalloweenDecor.ghost(props, houses, 22, 16, 0.25, 0)
		HalloweenDecor.ghost(props, houses, 26, 20, -0.2, 2)
		HalloweenDecor.ghost(props, Vector3.new(178, 0, 0), 14, 9, 0.3, 1)
		HalloweenDecor.ghost(props, Vector3.new(178, 0, 0), 18, 12, -0.22, 4)
		for i, x in { -70, 0, 70 } do
			HalloweenDecor.ghost(props, Vector3.new(x, 0, 0), 16, 14, if i % 2 == 0 then 0.18 else -0.18, i)
		end
		for i = 1, 6 do
			HalloweenDecor.bat(props, houses, 12 + i * 2, 20 + i % 3 * 2, 0.6 + i * 0.05, i)
		end
		for i = 1, 4 do
			HalloweenDecor.bat(props, Vector3.new(178, 0, 0), 10 + i * 2, 14 + i, -0.7, i * 1.5)
		end
		for i = 1, 4 do
			HalloweenDecor.bat(props, Vector3.zero, 22 + i * 3, 26 + i, 0.5, i * 1.6)
		end
	end,
}

local function recolour(tag: string, palette)
	for _, part in CollectionService:GetTagged(tag) do
		if palette == nil then
			part.Color = part:GetAttribute("BaseColor") or part.Color
		elseif typeof(palette) == "Color3" then
			part.Color = palette
		else
			part.Color = pick(palette, part)
		end
	end
end

local function setLamps(color: Color3?)
	for _, bulb in CollectionService:GetTagged(Decor.TAGS.bulb) do
		bulb.Color = color or bulb:GetAttribute("BaseColor") or bulb.Color
		local light = bulb:FindFirstChildOfClass("PointLight")
		if light then
			light.Color = color or bulb.Color
		end
	end
end

local function captureDefaults()
	defaults = { grass = Workspace.Terrain:GetMaterialColor(Enum.Material.Grass) }
end

-- Applies a theme's lighting ({ ClassName = { Property = value } }, where "Lighting" is the
-- Lighting service itself) and remembers the old values so clearTheme can put them back.
local saved = {}
local function applyLighting(settings)
	for className, props in settings or {} do
		local target = if className == "Lighting" then Lighting else Lighting:FindFirstChildOfClass(className)
		if target then
			saved[target] = saved[target] or {}
			for key, value in props do
				if saved[target][key] == nil then
					saved[target][key] = target[key]
				end
				target[key] = value
			end
		end
	end
end

local function restoreLighting()
	for target, props in saved do
		for key, value in props do
			target[key] = value
		end
	end
	table.clear(saved)
end

local function clearTheme()
	if folder then
		folder:Destroy()
		folder = nil
	end
	recolour(Decor.TAGS.leaves, nil)
	recolour(Decor.TAGS.lawn, nil)
	setLamps(nil)
	restoreLighting()
	Workspace.Terrain:SetMaterialColor(Enum.Material.Grass, defaults.grass)
	current = nil
end

local function applyTheme(id: string)
	local theme = THEMES[id]
	folder = Instance.new("Folder")
	folder.Name = "Seasonal_" .. id
	folder.Parent = Workspace
	theme.build(folder)
	recolour(Decor.TAGS.leaves, theme.leaves)
	recolour(Decor.TAGS.lawn, theme.lawn)
	setLamps(theme.bulb)
	applyLighting(theme.lighting)
	Workspace.Terrain:SetMaterialColor(Enum.Material.Grass, theme.grass)
	current = id
end

local function update()
	local wanted = nil
	for _, id in Seasons.active() do
		if THEMES[id] then
			wanted = id
			break
		end
	end
	if wanted == current then
		return
	end
	if current then
		clearTheme()
	end
	if wanted then
		applyTheme(wanted)
	end
end

function SeasonalService.init()
	captureDefaults()
	update()
	task.spawn(function()
		while true do
			task.wait(120)
			update()
		end
	end)
end

return SeasonalService
