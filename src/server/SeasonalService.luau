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
	lighting = {
		ClockTime = 16.9,
		atmosphere = {
			Density = 0.34,
			Color = Color3.fromRGB(255, 205, 165),
			Decay = Color3.fromRGB(130, 80, 100),
			Haze = 1.6,
		},
		color = { TintColor = Color3.fromRGB(255, 232, 210), Saturation = 0.2 },
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
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	local color = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	defaults = {
		ClockTime = Lighting.ClockTime,
		atmosphere = atmosphere and {
			Density = atmosphere.Density,
			Color = atmosphere.Color,
			Decay = atmosphere.Decay,
			Haze = atmosphere.Haze,
		},
		color = color and { TintColor = color.TintColor, Saturation = color.Saturation },
		grass = Workspace.Terrain:GetMaterialColor(Enum.Material.Grass),
	}
end

local function applyLighting(settings)
	Lighting.ClockTime = settings.ClockTime
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere and settings.atmosphere then
		for key, value in settings.atmosphere do
			atmosphere[key] = value
		end
	end
	local color = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if color and settings.color then
		for key, value in settings.color do
			color[key] = value
		end
	end
end

local function clearTheme()
	if folder then
		folder:Destroy()
		folder = nil
	end
	recolour(Decor.TAGS.leaves, nil)
	recolour(Decor.TAGS.lawn, nil)
	setLamps(nil)
	applyLighting(defaults)
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
