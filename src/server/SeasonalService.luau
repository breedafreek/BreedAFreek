-- Seasonal themes: while an event is running, the map dresses up for it (recoloured
-- trees, props, lighting) and goes back to normal when the event ends. Checked every two
-- minutes, so themes switch on and off without restarting servers.
--
-- To add a theme for another event, add an entry to THEMES keyed by its Seasons id.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local HouseModel = require(ReplicatedStorage.Shared.HouseModel)
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

local function facingSquare(position: Vector3): CFrame
	return CFrame.lookAt(position, Vector3.new(position.X, position.Y, 0))
end

local THEMES = {}

THEMES.Halloween = {
	leaves = Decor.FALL_LEAVES,
	grass = Color3.fromRGB(150, 165, 75),
	lawn = Color3.fromRGB(150, 170, 80),
	bulb = Color3.fromRGB(255, 140, 40),
	-- A warm autumn evening: low golden sun, a light pink-purple haze, a little extra glow
	-- on lights and pumpkins (still bright enough to see everything clearly).
	lighting = {
		Lighting = {
			ClockTime = 17.2,
			Brightness = 2.4,
			Ambient = Color3.fromRGB(100, 85, 110),
			OutdoorAmbient = Color3.fromRGB(150, 130, 160),
		},
		Atmosphere = {
			Density = 0.22,
			Color = Color3.fromRGB(225, 175, 200),
			Decay = Color3.fromRGB(120, 80, 130),
			Haze = 1,
			Glare = 0.3,
		},
		ColorCorrectionEffect = {
			TintColor = Color3.fromRGB(255, 240, 238),
			Saturation = 0.1,
			Contrast = 0.12,
		},
		BloomEffect = { Intensity = 0.6 },
	},
	build = function(props: Folder)
		local gateHalf, fenceZ = HouseModel.GATE_HALF, HouseModel.FENCE_Z
		-- Every home: jack-o'-lanterns flanking the gate and either side of the path, cobwebs
		-- on the gate posts, and a pile of leaves behind the house. (Spots kept clear of the
		-- nests, beds, yard spots and treadmill: see PlotService.)
		for i, origin in PlotService.origins() do
			for _, side in { -1, 1 } do
				Decor.pumpkin(props, origin * CFrame.new(side * (gateHalf + 4), 0.4, fenceZ - 2.5), 1)
				Decor.pumpkin(props, origin * CFrame.new(side * 6, 0.4, fenceZ + 5) * CFrame.Angles(0, math.pi, 0), 0.8)
				Decor.leafPile(props, origin * CFrame.new(side * 16, 0.4, 28), i * 10 + side)
				HalloweenDecor.cobweb(
					props,
					origin
						* CFrame.new(side * gateHalf, 10.2, fenceZ - 0.8)
						* CFrame.Angles(0, if side > 0 then math.pi else 0, 0),
					3
				)
			end
		end
		-- Pumpkins along both sidewalks, facing the road.
		for x = -182, 182, 52 do
			for _, z in { -14, 14 } do
				Decor.pumpkin(props, facingSquare(Vector3.new(x, 0.5, z)), 0.9)
			end
		end
		-- Hay bales topped with pumpkins by the spawn and the Mystery Box stand.
		for _, spot in
			{
				Vector3.new(176, 0, -24),
				Vector3.new(176, 0, 24),
				Vector3.new(212, 0, -24),
				Vector3.new(212, 0, 24),
			}
		do
			local ground = facingSquare(spot)
			Decor.hayBale(props, ground)
			Decor.pumpkin(props, ground * CFrame.new(0, 2.4, 0), 0.8)
		end
		-- Jack-o'-lanterns flanking the Mystery Box stand.
		for _, z in { -21, 21 } do
			Decor.pumpkin(props, CFrame.new(190, 0, z) * CFrame.Angles(0, math.pi / 2, 0), 1.4)
		end
		-- Leaf piles along the hedges at the back of the town.
		for x = -190, 170, 38 do
			for _, z in { -129, 129 } do
				Decor.leafPile(props, CFrame.new(x, 0, z), x + z)
			end
		end

		-- String lights between the street lamps on both sidewalks, and low fog on the road.
		for x = -208, 156, 52 do
			for _, z in { -17.5, 17.5 } do
				HalloweenDecor.stringLights(props, Vector3.new(x, 7.6, z), Vector3.new(x + 52, 7.6, z), 18, 3)
			end
		end
		for x = -180, 160, 40 do
			HalloweenDecor.fog(props, Vector3.new(x, 0.5, 0))
		end

		-- A little graveyard by the way into the zones (in the strip between the last home and
		-- the zones' wall), with dead trees and a cauldron.
		for row = 0, 2 do
			for col = 0, 2 do
				local ground = CFrame.new(-225 + col * 6, 0, 34 + row * 8) * CFrame.Angles(0, -math.pi / 2, 0)
				HalloweenDecor.tombstone(props, ground, row * 10 + col)
			end
		end
		HalloweenDecor.deadTree(props, CFrame.new(-218, 0, -26), 1.2, 3)
		HalloweenDecor.deadTree(props, CFrame.new(-218, 0, 26), 1.1, 4)
		HalloweenDecor.deadTree(props, CFrame.new(220, 0, -26), 1.2, 1)
		HalloweenDecor.cauldron(props, CFrame.new(-216, 0, 64))

		-- Ghosts drifting over the street; bats circling the title and the spawn.
		for i, x in { -105, -35, 35, 105 } do
			HalloweenDecor.ghost(props, Vector3.new(x, 0, 0), 16, 14, if i % 2 == 0 then 0.18 else -0.18, i)
		end
		HalloweenDecor.ghost(props, Vector3.new(-216, 0, 46), 14, 9, 0.3, 1)
		for i = 1, 4 do
			HalloweenDecor.bat(props, Vector3.new(170, 0, 0), 10 + i * 2, 14 + i, -0.7, i * 1.5)
		end
		for i = 1, 6 do
			HalloweenDecor.bat(props, Vector3.zero, 22 + i * 3, 30 + i, 0.5, i * 1.6)
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
