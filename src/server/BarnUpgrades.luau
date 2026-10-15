-- The barn gets cooler with every rebirth. Each level keeps everything from the levels
-- before it:
--   1  cupola with a weathervane, picket fence with lanterns, bunting flags
--   2  hayloft balcony with a hanging hay bale, a silo, a stone statue of your best Freek
--   3  gold trim, glowing neon roof edges, a bubbling slime fountain
--   4  a whole extra storey, castle turrets with flags, a giant gold Freek on the roof
--   5  gold shingle roof, rainbow roof edges, crystal spires and a crystal cupola top
--   6  sky spotlights, a sparkle aura, gems orbiting above the cupola
--   7  red carpet with velvet ropes, a trophy wall of your rarest Freeks, fireworks
--   8  the Golden Barn: gold walls and white marble trim
-- (The door frame and name plaque upgrade separately, see GateTiers.)
--
-- Coordinates are the plot's (see Barn.luau): doors on the -Z side, floor top at y = 1.
-- The client animates the moving bits (BarnFX.luau): spinners, rainbow parts, fireworks.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Barn = require(script.Parent.Barn)
local Decor = require(script.Parent.Decor)
local FreekModel = require(ReplicatedStorage.Shared.FreekModel)
local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local Freeks = require(ReplicatedStorage.Shared.Freeks)
local Rarities = require(ReplicatedStorage.Shared.Rarities)

local BarnUpgrades = {}

BarnUpgrades.MAX_LEVEL = 8
BarnUpgrades.STOREY = 10 -- how much taller the extra storey makes the barn
BarnUpgrades.SPINNER_TAG = "BarnSpinner"
BarnUpgrades.FIREWORKS_TAG = "BarnFireworks"

local RED = Color3.fromRGB(168, 40, 36)
local WHITE = Color3.fromRGB(245, 242, 235)
local GOLD = Color3.fromRGB(255, 196, 55)
local MARBLE = Color3.fromRGB(250, 248, 242)
local STONE = Color3.fromRGB(175, 172, 170)
local DARK = Color3.fromRGB(40, 36, 44)
local ROOF = Color3.fromRGB(72, 58, 62)
local CRYSTAL = Color3.fromRGB(150, 225, 255)
local SLIME = Color3.fromRGB(120, 255, 90)
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

local part = Decor.part

local function wedge(props)
	return part(props, "WedgePart")
end

local function noCollide(p: BasePart)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end

--------------------------------------------------------------------------------
-- Changing the barn itself (colours and the roof height), undoably
--------------------------------------------------------------------------------

local function paint(p: BasePart, color: Color3, material: Enum.Material?)
	if p:GetAttribute("UpgradeColor") == nil then
		p:SetAttribute("UpgradeColor", p.Color)
		p:SetAttribute("UpgradeMaterial", p.Material.Name)
	end
	p.Color = color
	if material then
		p.Material = material
	end
end

local function lift(p: BasePart, height: number)
	if p:GetAttribute("UpgradeCFrame") == nil then
		p:SetAttribute("UpgradeCFrame", p.CFrame)
	end
	p.CFrame = (p:GetAttribute("UpgradeCFrame") :: CFrame) + Vector3.new(0, height, 0)
end

local function restore(container: Instance)
	for _, p in container:GetDescendants() do
		if p:IsA("BasePart") then
			local color = p:GetAttribute("UpgradeColor")
			if typeof(color) == "Color3" then
				p.Color = color
				p.Material = Enum.Material[p:GetAttribute("UpgradeMaterial") :: string]
				p:SetAttribute("UpgradeColor", nil)
				p:SetAttribute("UpgradeMaterial", nil)
			end
			local cframe = p:GetAttribute("UpgradeCFrame")
			if typeof(cframe) == "CFrame" then
				p.CFrame = cframe
				p:SetAttribute("UpgradeCFrame", nil)
			end
		end
	end
end

local function eachNamed(container: Instance, names: { [string]: boolean }, fn: (BasePart) -> ())
	for _, p in container:GetDescendants() do
		if p:IsA("BasePart") and names[p.Name] then
			fn(p)
		end
	end
end

local TRIM_NAMES =
	{ CornerTrim = true, EaveTrim = true, RoofTrim = true, WindowFrame = true, WindowBar = true, DoorTrim = true }
local WALL_NAMES = { Wall = true, Gable = true, DoorPanel = true }

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- Turns a model into a statue: every part one colour and material, no effects.
local function statue(model: Model, color: Color3, material: Enum.Material)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Color = color
			d.Material = material
			d.Anchored = true
			noCollide(d)
			CollectionService:RemoveTag(d, FreekModel.RAINBOW_TAG)
		elseif d:IsA("Sparkles") or d:IsA("Fire") or d:IsA("Light") or d:IsA("ParticleEmitter") then
			d:Destroy()
		end
	end
end

-- Scales a model about its pivot (works without Model:ScaleTo).
local function scaleModel(model: Model, scale: number)
	local pivot = model:GetPivot()
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local relative = pivot:ToObjectSpace(d.CFrame)
			d.Size *= scale
			d.CFrame = pivot * (relative.Rotation + relative.Position * scale)
		end
	end
end

-- A Freek model scaled to `height` studs tall, standing at `ground` facing its -Z.
local function freekFigure(species: string, height: number, ground: CFrame): Model?
	local ok, model, tall = pcall(FreekModel.build, species)
	if not ok or not model then
		return nil
	end
	model:PivotTo(CFrame.new())
	scaleModel(model, height / math.max(tall, 0.5))
	model:PivotTo(ground)
	return model
end

-- A downward-pointing pennant flag; `top` is the middle of its top edge, facing its -Z,
-- with its right along the string.
local function pennant(parent: Instance, top: CFrame, width: number, height: number, color: Color3)
	local base = top * CFrame.Angles(0, math.pi / 2, 0)
	for _, side in { 1, -1 } do
		noCollide(wedge({
			Name = "Bunting",
			Size = Vector3.new(0.12, height, width / 2),
			CFrame = base * CFrame.new(0, -height / 2, side * width / 4) * (if side == 1
				then CFrame.Angles(math.pi, 0, 0)
				else CFrame.Angles(0, math.pi, 0) * CFrame.Angles(math.pi, 0, 0)),
			Color = color,
			Parent = parent,
		}))
	end
end

-- A line of pennants from a to b, hanging on a string, facing `outward`.
local function buntingLine(parent: Instance, a: Vector3, b: Vector3, outward: Vector3, colors: { Color3 })
	local length = (b - a).Magnitude
	noCollide(part({
		Name = "BuntingString",
		Size = Vector3.new(0.12, 0.12, length),
		CFrame = CFrame.lookAt((a + b) / 2, b),
		Color = DARK,
		Parent = parent,
	}))
	local along = (b - a).Unit
	local count = math.floor(length / 2.4)
	for i = 0, count - 1 do
		local position = a + along * ((i + 0.5) * length / count)
		local top = CFrame.lookAt(position, position + outward)
		pennant(parent, top, 1.3, 1.5, colors[i % #colors + 1])
	end
end

-- A stepped cone (stacked discs), cartoon style. `ground` is the centre of its base.
local function steppedCone(parent: Instance, ground: CFrame, radius: number, height: number, color: Color3, material)
	local steps = 5
	local parts = {}
	for i = 0, steps - 1 do
		local r = radius * (1 - i / steps)
		local h = height / steps
		table.insert(
			parts,
			part({
				Name = "Cone",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(h, r * 2, r * 2),
				CFrame = ground * CFrame.new(0, h * (i + 0.5), 0) * CFrame.Angles(0, 0, math.pi / 2),
				Color = color,
				Material = material or Enum.Material.Slate,
				Parent = parent,
			})
		)
	end
	return parts
end

local function lantern(parent: Instance, ground: CFrame, height: number)
	part({
		Name = "LanternPost",
		Size = Vector3.new(0.7, height, 0.7),
		CFrame = ground * CFrame.new(0, height / 2, 0),
		Color = DARK,
		Material = Enum.Material.Metal,
		Parent = parent,
	})
	local bulb = noCollide(part({
		Name = "Lantern",
		Size = Vector3.new(1, 1.2, 1),
		CFrame = ground * CFrame.new(0, height + 0.6, 0),
		Color = Color3.fromRGB(255, 215, 140),
		Material = Enum.Material.Neon,
		Parent = parent,
	}))
	noCollide(part({
		Name = "LanternCap",
		Size = Vector3.new(1.4, 0.3, 1.4),
		CFrame = ground * CFrame.new(0, height + 1.35, 0),
		Color = DARK,
		Material = Enum.Material.Metal,
		Parent = parent,
	}))
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 210, 150)
	light.Range = 14
	light.Brightness = 1
	light.Shadows = false
	light.Parent = bulb
end

local function window(parent: Instance, spot: CFrame, trim: Color3)
	part({ Name = "WindowFrame", Size = Vector3.new(6, 6, 0.3), CFrame = spot, Color = trim, Parent = parent })
	part({
		Name = "WindowPane",
		Size = Vector3.new(5, 5, 0.35),
		CFrame = spot,
		Color = Color3.fromRGB(70, 95, 120),
		Material = Enum.Material.Glass,
		Parent = parent,
	})
	for _, bar in { Vector3.new(0.4, 5, 0.4), Vector3.new(5, 0.4, 0.4) } do
		part({ Name = "WindowBar", Size = bar, CFrame = spot, Color = trim, Parent = parent })
	end
end

local function spinner(model: Model, mode: string, speed: number, amount: number?)
	model:SetAttribute("Rest", model:GetPivot())
	model:SetAttribute("Mode", mode)
	model:SetAttribute("Speed", speed)
	model:SetAttribute("Amount", amount or 0)
	CollectionService:AddTag(model, BarnUpgrades.SPINNER_TAG)
end

local function emitter(parent: BasePart, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARKLE_TEXTURE
	e.LightEmission = 1
	for key, value in props do
		e[key] = value
	end
	e.Parent = parent
	return e
end

-- The Freeks a player is proudest of: distinct species, rarest (then richest) first.
local function proudest(data, count: number): { string }
	local best = {}
	for _, freek in (data and data.freeks or {}) do
		local species = Freeks.byId[freek.species]
		if species then
			local score = (Rarities.rank[species.rarity] or 0) * 1e9 + FreekUtil.baseIncome(freek)
			if not best[freek.species] or best[freek.species] < score then
				best[freek.species] = score
			end
		end
	end
	local list = {}
	for species in best do
		table.insert(list, species)
	end
	table.sort(list, function(a, b)
		return best[a] > best[b]
	end)
	while #list > count do
		table.remove(list)
	end
	return list
end

--------------------------------------------------------------------------------
-- Building
--------------------------------------------------------------------------------

local function build(plot, level: number, model: Model, champions: { string })
	local origin: CFrame = plot.origin
	local half: number = plot.half
	local accent: Color3 = plot.accent
	local barnFolder: Instance = plot.freeks.Parent
	local roofFolder = barnFolder:FindFirstChild("Roof")
	local storey = if level >= 4 then BarnUpgrades.STOREY else 0
	local top0 = 1 + Barn.WALL_HEIGHT
	local top = top0 + storey -- where the roof now starts
	local ridge = top + 16.5 -- top of the ridge cap
	local trimColor = if level >= 8 then MARBLE elseif level >= 3 then GOLD else WHITE
	local trimMaterial = if level >= 8
		then Enum.Material.Marble
		elseif level >= 3 then Enum.Material.Foil
		else Enum.Material.SmoothPlastic
	local wallColor = if level >= 8 then GOLD else RED
	local roofColor = if level >= 8 then MARBLE elseif level >= 5 then GOLD else ROOF
	local roofMaterial = if level >= 8
		then Enum.Material.Marble
		elseif level >= 5 then Enum.Material.Foil
		else Enum.Material.Slate
	local function at(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end

	-- Recolour and lift the barn itself.
	if level >= 3 then
		eachNamed(barnFolder, TRIM_NAMES, function(p)
			paint(p, trimColor, trimMaterial)
		end)
	end
	if level >= 8 then
		eachNamed(barnFolder, WALL_NAMES, function(p)
			paint(p, wallColor, Enum.Material.Foil)
		end)
		eachNamed(barnFolder, { Batten = true }, function(p)
			paint(p, wallColor:Lerp(Color3.new(0, 0, 0), 0.2), Enum.Material.Foil)
		end)
	end
	if roofFolder then
		if storey > 0 then
			for _, p in roofFolder:GetDescendants() do
				if p:IsA("BasePart") then
					lift(p, storey)
				end
			end
			local ceiling = barnFolder:FindFirstChild("Ceiling")
			if ceiling and ceiling:IsA("BasePart") then
				lift(ceiling, storey)
			end
		end
		if level >= 5 then
			eachNamed(roofFolder, { RoofSlope = true }, function(p)
				paint(p, roofColor, roofMaterial)
			end)
			eachNamed(roofFolder, { RoofShingle = true }, function(p)
				paint(p, roofColor:Lerp(Color3.new(0, 0, 0), 0.2), roofMaterial)
			end)
			eachNamed(roofFolder, { RidgeCap = true }, function(p)
				paint(p, if level >= 8 then GOLD else Color3.fromRGB(230, 165, 35), Enum.Material.Foil)
			end)
		end
	end

	-- Level 1 -----------------------------------------------------------------

	-- Cupola on the ridge with a weathervane.
	local cupolaBase = ridge - 0.8
	part({
		Name = "Cupola",
		Size = Vector3.new(5, 4.5, 5),
		CFrame = at(0, cupolaBase + 2.25, 0),
		Color = if level >= 8 then GOLD else WHITE,
		Material = if level >= 8 then Enum.Material.Foil else Enum.Material.SmoothPlastic,
		Parent = model,
	})
	for _, face in { 0, 1, 2, 3 } do
		local turn = CFrame.Angles(0, face * math.pi / 2, 0)
		for k = -1, 1 do
			noCollide(part({
				Name = "Louver",
				Size = Vector3.new(3.2, 0.35, 0.3),
				CFrame = at(0, cupolaBase + 2.3 + k * 0.8, 0) * turn * CFrame.new(0, 0, -2.55),
				Color = DARK,
				Parent = model,
			}))
		end
	end
	local cupolaRoof = steppedCone(
		model,
		at(0, cupolaBase + 4.5, 0),
		3.8,
		3,
		if level >= 5 then CRYSTAL else roofColor,
		if level >= 5 then Enum.Material.Glass else roofMaterial
	)
	if level >= 5 then
		for _, p in cupolaRoof do
			p.Transparency = 0.15
		end
		local sparkle = Instance.new("Sparkles")
		sparkle.SparkleColor = CRYSTAL
		sparkle.Parent = cupolaRoof[#cupolaRoof]
	end
	local vaneTop = cupolaBase + 7.5
	local vane = Instance.new("Model")
	vane.Name = "Weathervane"
	vane.Parent = model
	local vaneColor = if level >= 3 then GOLD else DARK
	local vaneMaterial = if level >= 3 then Enum.Material.Foil else Enum.Material.Metal
	local pole = noCollide(part({
		Name = "VanePole",
		Size = Vector3.new(0.3, 3.4, 0.3),
		CFrame = at(0, vaneTop + 1.7, 0),
		Color = vaneColor,
		Material = vaneMaterial,
		Parent = vane,
	}))
	vane.PrimaryPart = pole
	noCollide(part({
		Name = "VaneArrow",
		Size = Vector3.new(4.2, 0.2, 0.2),
		CFrame = at(0, vaneTop + 2.6, 0),
		Color = vaneColor,
		Material = vaneMaterial,
		Parent = vane,
	}))
	noCollide(wedge({
		Name = "VaneArrow",
		Size = Vector3.new(0.15, 0.8, 0.9),
		CFrame = at(2.4, vaneTop + 2.6, 0) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.Angles(math.pi / 4, 0, 0),
		Color = vaneColor,
		Material = vaneMaterial,
		Parent = vane,
	}))
	-- The rooster.
	for _, bit in
		{
			{ "Ball", Vector3.one * 1.3, Vector3.new(0, vaneTop + 3.7, 0), vaneColor },
			{ "Ball", Vector3.one * 0.75, Vector3.new(0.7, vaneTop + 4.5, 0), vaneColor },
			{ "Block", Vector3.new(0.3, 0.45, 0.15), Vector3.new(0.75, vaneTop + 5, 0), Color3.fromRGB(230, 40, 40) },
			{
				"Block",
				Vector3.new(0.35, 0.15, 0.15),
				Vector3.new(1.15, vaneTop + 4.45, 0),
				Color3.fromRGB(255, 190, 40),
			},
			{ "Block", Vector3.new(0.9, 1.2, 0.15), Vector3.new(-0.75, vaneTop + 4.1, 0), vaneColor },
		}
	do
		noCollide(part({
			Name = "Rooster",
			Shape = Enum.PartType[bit[1]],
			Size = bit[2],
			CFrame = at(bit[3].X, bit[3].Y, bit[3].Z),
			Color = bit[4],
			Material = if bit[4] == vaneColor then vaneMaterial else Enum.Material.SmoothPlastic,
			Parent = vane,
		}))
	end
	spinner(vane, "sway", 0.35, math.rad(70))

	-- Picket fence round the barn, open at the front, with lanterns.
	local fence = Instance.new("Folder")
	fence.Name = "Fence"
	fence.Parent = model
	local e = half + 1.7
	local function fenceLine(ax, az, bx, bz)
		Decor.picketFence(fence, at(ax, 0, az).Position, at(bx, 0, bz).Position, 3.2, trimColor)
	end
	fenceLine(-e, -e, -e, e)
	fenceLine(-e, e, e, e)
	fenceLine(e, e, e, -e)
	fenceLine(e, -e, 17, -e)
	fenceLine(-e, -e, -17, -e)
	for _, spot in { { -e, e }, { e, e }, { 17, -e }, { -17, -e }, { e, -e }, { -e, -e } } do
		if not (level >= 4 and spot[2] < 0 and math.abs(spot[1]) == e) then
			lantern(fence, at(spot[1], 0, spot[2]), 4.2)
		end
	end

	-- Bunting along the front gable and the side eaves.
	local flagColors = { accent, WHITE, GOLD }
	local profile = {
		Vector2.new(-(half + 1.5), top - 1.2),
		Vector2.new(-23, top + 9.8),
		Vector2.new(0, top + 14.8),
		Vector2.new(23, top + 9.8),
		Vector2.new(half + 1.5, top - 1.2),
	}
	for i = 1, #profile - 1 do
		local a, b = profile[i], profile[i + 1]
		buntingLine(
			model,
			at(a.X, a.Y, -(half + 1.5)).Position,
			at(b.X, b.Y, -(half + 1.5)).Position,
			origin.LookVector,
			flagColors
		)
	end
	for _, side in { -1, 1 } do
		local x = side * (half + 1.9)
		buntingLine(
			model,
			at(x, top - 1.2, -(half + 1)).Position,
			at(x, top - 1.2, half + 1).Position,
			origin.RightVector * side,
			flagColors
		)
	end

	if level < 2 then
		return
	end

	-- Level 2 -----------------------------------------------------------------

	-- Hayloft: an open loft door in the front gable, a balcony and a hanging hay bale.
	local loftZ = -half - 0.55
	local loftY = top + 4.6
	part({
		Name = "LoftOpening",
		Size = Vector3.new(7, 7, 0.3),
		CFrame = at(0, loftY, loftZ),
		Color = Color3.fromRGB(45, 28, 22),
		Parent = model,
	})
	for _, bar in
		{
			{ Vector3.new(8, 0.7, 0.5), Vector3.new(0, loftY + 3.6, 0) },
			{ Vector3.new(0.7, 7.6, 0.5), Vector3.new(-3.85, loftY, 0) },
			{ Vector3.new(0.7, 7.6, 0.5), Vector3.new(3.85, loftY, 0) },
		}
	do
		part({
			Name = "LoftTrim",
			Size = bar[1],
			CFrame = at(bar[2].X, bar[2].Y, loftZ - 0.1),
			Color = trimColor,
			Material = trimMaterial,
			Parent = model,
		})
	end
	for _, side in { -1, 1 } do
		-- The loft doors swung open against the gable.
		local door = at(side * 6, loftY, loftZ - 0.25)
		part({
			Name = "LoftDoor",
			Size = Vector3.new(3.4, 7, 0.35),
			CFrame = door,
			Color = wallColor,
			Material = Enum.Material.WoodPlanks,
			Parent = model,
		})
		for _, bar in { Vector3.new(3.4, 0.4, 0.45), Vector3.new(0.4, 7, 0.45) } do
			noCollide(part({
				Name = "LoftDoorTrim",
				Size = bar,
				CFrame = door * CFrame.new(0, 0, -0.05),
				Color = trimColor,
				Material = trimMaterial,
				Parent = model,
			}))
		end
	end
	local balconyY = top + 0.9
	part({
		Name = "Balcony",
		Size = Vector3.new(11, 0.6, 3.4),
		CFrame = at(0, balconyY, -half - 2.2),
		Color = Color3.fromRGB(150, 105, 65),
		Material = Enum.Material.WoodPlanks,
		Parent = model,
	})
	for _, x in { -5.2, -2.6, 0, 2.6, 5.2 } do
		part({
			Name = "Railing",
			Size = Vector3.new(0.35, 2.4, 0.35),
			CFrame = at(x, balconyY + 1.5, -half - 3.7),
			Color = trimColor,
			Material = trimMaterial,
			Parent = model,
		})
	end
	part({
		Name = "Railing",
		Size = Vector3.new(11, 0.4, 0.45),
		CFrame = at(0, balconyY + 2.6, -half - 3.7),
		Color = trimColor,
		Material = trimMaterial,
		Parent = model,
	})
	local beamY = loftY + 5.2
	part({
		Name = "HayBeam",
		Size = Vector3.new(0.9, 0.9, 5),
		CFrame = at(0, beamY, -half - 2.3),
		Color = Color3.fromRGB(110, 75, 45),
		Material = Enum.Material.WoodPlanks,
		Parent = model,
	})
	noCollide(part({
		Name = "Pulley",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 1.1, 1.1),
		CFrame = at(0, beamY - 0.8, -half - 4.4),
		Color = DARK,
		Material = Enum.Material.Metal,
		Parent = model,
	}))
	noCollide(part({
		Name = "Rope",
		Size = Vector3.new(0.15, 3.6, 0.15),
		CFrame = at(0, beamY - 3, -half - 4.4),
		Color = Color3.fromRGB(190, 160, 110),
		Material = Enum.Material.Fabric,
		Parent = model,
	}))
	Decor.hayBale(model, at(0, beamY - 7.2, -half - 4.4))

	-- Silo behind the barn.
	local siloX, siloZ = 10, half + 7.5
	local siloHeight = 35 + storey
	part({
		Name = "Silo",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(siloHeight, 11, 11),
		CFrame = at(siloX, siloHeight / 2, siloZ) * CFrame.Angles(0, 0, math.pi / 2),
		Color = if level >= 8 then GOLD else Color3.fromRGB(190, 200, 210),
		Material = if level >= 8 then Enum.Material.Foil else Enum.Material.CorrodedMetal,
		Parent = model,
	})
	for y = 6, siloHeight - 2, 7 do
		noCollide(part({
			Name = "SiloBand",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, 11.4, 11.4),
			CFrame = at(siloX, y, siloZ) * CFrame.Angles(0, 0, math.pi / 2),
			Color = trimColor,
			Material = trimMaterial,
			Parent = model,
		}))
	end
	part({
		Name = "SiloDome",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 11.6,
		CFrame = at(siloX, siloHeight, siloZ),
		Color = accent,
		Parent = model,
	})
	noCollide(part({
		Name = "SiloCap",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 1.6,
		CFrame = at(siloX, siloHeight + 6.2, siloZ),
		Color = trimColor,
		Material = trimMaterial,
		Parent = model,
	}))

	-- A stone statue of their best Freek by the door (left of it, opposite the plaque).
	local champion = champions[1]
	if champion then
		local spot = at(21, 0, -half - 4.6)
		part({
			Name = "StatuePlinth",
			Size = Vector3.new(5.5, 2.2, 5.5),
			CFrame = spot * CFrame.new(0, 1.1, 0),
			Color = STONE,
			Material = Enum.Material.Slate,
			Parent = model,
		})
		part({
			Name = "StatuePlinth",
			Size = Vector3.new(6.2, 0.5, 6.2),
			CFrame = spot * CFrame.new(0, 2.45, 0),
			Color = trimColor,
			Material = trimMaterial,
			Parent = model,
		})
		local figure = freekFigure(champion, 7, spot * CFrame.new(0, 2.7, 0))
		if figure then
			figure.Name = "Statue"
			statue(figure, Color3.fromRGB(200, 198, 192), Enum.Material.Slate)
			figure.Parent = model
		end
	end

	if level < 3 then
		return
	end

	-- Level 3 -----------------------------------------------------------------

	-- Glowing neon roof edges and corners (rainbow from level 5).
	local neon = {}
	local function neonBar(cframe: CFrame, size: Vector3)
		table.insert(
			neon,
			noCollide(part({
				Name = "NeonTrim",
				Size = size,
				CFrame = cframe,
				Color = accent,
				Material = Enum.Material.Neon,
				CastShadow = false,
				Parent = model,
			}))
		)
	end
	local edge = {
		Vector2.new(-(half + 1.5), top - 0.8),
		Vector2.new(-23, top + 10.2),
		Vector2.new(0, top + 15.2),
		Vector2.new(23, top + 10.2),
		Vector2.new(half + 1.5, top - 0.8),
	}
	for _, z in { -(half + 1.35), half + 1.35 } do
		for i = 1, #edge - 1 do
			local a, b = edge[i], edge[i + 1]
			local middle = (a + b) / 2
			local length = (b - a).Magnitude
			neonBar(
				at(middle.X, middle.Y, z) * CFrame.Angles(0, 0, math.atan2(b.Y - a.Y, b.X - a.X)),
				Vector3.new(length + 0.3, 0.35, 0.3)
			)
		end
	end
	for _, side in { -1, 1 } do
		neonBar(at(side * (half + 1.65), top - 1.15, 0), Vector3.new(0.3, 0.35, Barn.SIZE + 2))
		for _, z in { -1, 1 } do
			neonBar(at(side * (half + 0.95), (top + 1) / 2, z * (half + 0.95)), Vector3.new(0.3, top - 1, 0.3))
		end
	end
	if level >= 5 then
		for _, p in neon do
			CollectionService:AddTag(p, FreekModel.RAINBOW_TAG)
		end
	end

	-- A bubbling slime fountain in front of the plaque.
	local fountain = at(-21, 0, -half - 6)
	part({
		Name = "FountainBasin",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.6, 7, 7),
		CFrame = fountain * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = STONE,
		Material = Enum.Material.Slate,
		Parent = model,
	})
	local pool = noCollide(part({
		Name = "Slime",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 6, 6),
		CFrame = fountain * CFrame.new(0, 1.55, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = SLIME,
		Material = Enum.Material.Neon,
		Parent = model,
	}))
	part({
		Name = "FountainColumn",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(3.2, 1.2, 1.2),
		CFrame = fountain * CFrame.new(0, 3, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = STONE,
		Material = Enum.Material.Slate,
		Parent = model,
	})
	part({
		Name = "FountainBowl",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.7, 3.4, 3.4),
		CFrame = fountain * CFrame.new(0, 4.6, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = trimColor,
		Material = trimMaterial,
		Parent = model,
	})
	noCollide(part({
		Name = "Slime",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.9, 1.2, 2.9),
		CFrame = fountain * CFrame.new(0, 5, 0),
		Color = SLIME,
		Material = Enum.Material.Neon,
		Parent = model,
	}))
	for k = 0, 3 do
		local angle = k * math.pi / 2 + math.pi / 4
		noCollide(part({
			Name = "SlimeStream",
			Size = Vector3.new(0.35, 3.2, 0.35),
			CFrame = fountain * CFrame.new(math.cos(angle) * 1.8, 3.2, math.sin(angle) * 1.8),
			Color = SLIME,
			Material = Enum.Material.Neon,
			Transparency = 0.2,
			Parent = model,
		}))
	end
	emitter(pool, {
		Color = ColorSequence.new(SLIME),
		Rate = 6,
		Lifetime = NumberRange.new(0.8, 1.4),
		Speed = NumberRange.new(1.5, 3),
		Size = NumberSequence.new(0.5, 0),
		SpreadAngle = Vector2.new(25, 25),
		EmissionDirection = Enum.NormalId.Right,
	})
	local glow = Instance.new("PointLight")
	glow.Color = SLIME
	glow.Range = 12
	glow.Brightness = 1.5
	glow.Parent = pool

	if level < 4 then
		return
	end

	-- Level 4 -----------------------------------------------------------------

	-- The extra storey: walls between the old wall top and the lifted roof.
	for _, wall in
		{
			{ Vector3.new(Barn.SIZE, storey, 1), Vector3.new(0, top0 + storey / 2, half) },
			{ Vector3.new(Barn.SIZE, storey, 1), Vector3.new(0, top0 + storey / 2, -half) },
			{ Vector3.new(1, storey, Barn.SIZE), Vector3.new(-half, top0 + storey / 2, 0) },
			{ Vector3.new(1, storey, Barn.SIZE), Vector3.new(half, top0 + storey / 2, 0) },
		}
	do
		part({
			Name = "UpperWall",
			Size = wall[1],
			CFrame = at(wall[2].X, wall[2].Y, wall[2].Z),
			Color = wallColor,
			Material = if level >= 8 then Enum.Material.Foil else Enum.Material.WoodPlanks,
			Parent = model,
		})
	end
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			part({
				Name = "UpperCorner",
				Size = Vector3.new(1.6, storey + 0.4, 1.6),
				CFrame = at(x * (half + 0.1), top0 + storey / 2, z * (half + 0.1)),
				Color = trimColor,
				Material = trimMaterial,
				Parent = model,
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
		part({
			Name = "UpperEave",
			Size = band[1],
			CFrame = at(band[2].X, band[2].Y, band[2].Z),
			Color = trimColor,
			Material = trimMaterial,
			Parent = model,
		})
	end
	local upperY = top0 + storey / 2
	for _, x in { -18, 18 } do
		window(model, at(x, upperY, -half - 0.6), trimColor)
	end
	for _, side in { -1, 1 } do
		for _, z in { -12, 12 } do
			window(model, at(side * (half + 0.6), upperY, z) * CFrame.Angles(0, math.pi / 2, 0), trimColor)
		end
	end

	-- Castle turrets on the front corners, with flags.
	for _, side in { -1, 1 } do
		local base = at(side * half, 0, -half)
		local towerHeight = top + 3
		part({
			Name = "Turret",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(towerHeight, 5.4, 5.4),
			CFrame = base * CFrame.new(0, towerHeight / 2, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Color = if level >= 8 then MARBLE else Color3.fromRGB(215, 208, 200),
			Material = if level >= 8 then Enum.Material.Marble else Enum.Material.Slate,
			Parent = model,
		})
		part({
			Name = "TurretRing",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.2, 6.6, 6.6),
			CFrame = base * CFrame.new(0, towerHeight + 0.6, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Color = trimColor,
			Material = trimMaterial,
			Parent = model,
		})
		for _, y in { 8, 16, top - 2 } do
			noCollide(part({
				Name = "ArrowSlit",
				Size = Vector3.new(0.6, 2.2, 0.3),
				CFrame = base * CFrame.new(0, y, -2.65),
				Color = DARK,
				Parent = model,
			}))
		end
		steppedCone(
			model,
			base * CFrame.new(0, towerHeight + 1.2, 0),
			3.5,
			6,
			if level >= 5 then roofColor else Color3.fromRGB(70, 60, 110),
			if level >= 5 then roofMaterial else Enum.Material.Slate
		)
		local flagTop = towerHeight + 1.2 + 6 + 4
		noCollide(part({
			Name = "FlagPole",
			Size = Vector3.new(0.3, 4.4, 0.3),
			CFrame = base * CFrame.new(0, flagTop - 2.2, 0),
			Color = trimColor,
			Material = trimMaterial,
			Parent = model,
		}))
		noCollide(part({
			Name = "Flag",
			Size = Vector3.new(2.6, 1.6, 0.12),
			CFrame = base * CFrame.new(side * 1.45, flagTop - 1, 0),
			Color = accent,
			Parent = model,
		}))
	end

	-- A giant gold Freek standing on the ridge.
	if champion then
		local spot = at(0, ridge, -half + 9)
		part({
			Name = "RoofPlinth",
			Size = Vector3.new(4.5, 1.2, 4.5),
			CFrame = spot * CFrame.new(0, 0.6, 0),
			Color = GOLD,
			Material = Enum.Material.Foil,
			Parent = model,
		})
		local figure = freekFigure(champion, 9, spot * CFrame.new(0, 1.2, 0))
		if figure then
			figure.Name = "GoldStatue"
			statue(figure, GOLD, Enum.Material.Foil)
			figure.Parent = model
			local shine = Instance.new("Sparkles")
			shine.SparkleColor = Color3.fromRGB(255, 235, 150)
			shine.Parent = figure.PrimaryPart or figure:FindFirstChildWhichIsA("BasePart")
		end
	end

	if level < 5 then
		return
	end

	-- Level 5 -----------------------------------------------------------------

	-- Crystal spires at both ends of the ridge.
	for _, z in { -(half + 0.5), half + 0.5 } do
		local base = at(0, ridge - 0.4, z)
		for k, crystal in
			{
				{ 0, 0, 5.5, 1.4 },
				{ -1.1, -20, 3.6, 1 },
				{ 1.1, 20, 3.8, 1 },
				{ 0.5, 10, 2.6, 0.8 },
				{ -0.6, -12, 2.4, 0.8 },
			}
		do
			local shard = noCollide(part({
				Name = "Crystal",
				Size = Vector3.new(crystal[4], crystal[3], crystal[4]),
				CFrame = base
					* CFrame.new(crystal[1], 0, (k % 2) * 0.4)
					* CFrame.Angles(0, math.rad(45), math.rad(crystal[2]))
					* CFrame.new(0, crystal[3] / 2, 0),
				Color = CRYSTAL,
				Material = Enum.Material.Glass,
				Transparency = 0.15,
				Parent = model,
			}))
			if k == 1 then
				local sparkle = Instance.new("Sparkles")
				sparkle.SparkleColor = CRYSTAL
				sparkle.Parent = shard
				local light = Instance.new("PointLight")
				light.Color = CRYSTAL
				light.Range = 12
				light.Parent = shard
			end
		end
	end

	if level < 6 then
		return
	end

	-- Level 6 -----------------------------------------------------------------

	-- Sky spotlights on the front of the roof, sweeping back and forth.
	for _, side in { -1, 1 } do
		local x = side * 24
		local y = top - 0.6 + (half + 1.5 - 24) / 10 * 11 + 0.8
		local light = Instance.new("Model")
		light.Name = "Spotlight"
		light.Parent = model
		local base = part({
			Name = "SpotBase",
			Size = Vector3.new(2.4, 1.4, 2.4),
			CFrame = at(x, y, -half + 5),
			Color = DARK,
			Material = Enum.Material.Metal,
			Parent = light,
		})
		light.PrimaryPart = base
		local aim = at(x, y + 1.4, -half + 5) * CFrame.Angles(math.rad(-25), 0, math.rad(side * -15))
		noCollide(part({
			Name = "SpotDrum",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.4, 2.4, 2.4),
			CFrame = aim * CFrame.Angles(0, 0, math.pi / 2),
			Color = DARK,
			Material = Enum.Material.Metal,
			Parent = light,
		}))
		noCollide(part({
			Name = "SpotLens",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, 2.1, 2.1),
			CFrame = aim * CFrame.new(0, 1.25, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Color = Color3.fromRGB(255, 250, 220),
			Material = Enum.Material.Neon,
			Parent = light,
		}))
		noCollide(part({
			Name = "SpotBeam",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(140, 3, 3),
			CFrame = aim * CFrame.new(0, 71.3, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Color = Color3.fromRGB(255, 248, 210),
			Material = Enum.Material.Neon,
			Transparency = 0.78,
			CastShadow = false,
			Parent = light,
		}))
		spinner(light, "sway", 0.5 + side * 0.08, math.rad(50))
	end

	-- A sparkle aura and fireflies drifting round the whole barn.
	local aura = noCollide(part({
		Name = "SparkleAura",
		Size = Vector3.new(Barn.SIZE + 10, top + 8, Barn.SIZE + 10),
		CFrame = at(0, (top + 8) / 2, 0),
		Transparency = 1,
		CastShadow = false,
		Parent = model,
	}))
	emitter(aura, {
		Color = ColorSequence.new(Color3.fromRGB(255, 240, 170)),
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		Rate = 18,
		Lifetime = NumberRange.new(2.5, 4.5),
		Speed = NumberRange.new(0.4, 1.4),
		SpreadAngle = Vector2.new(180, 180),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 0.8),
			NumberSequenceKeypoint.new(1, 0),
		}),
	})
	emitter(aura, {
		Color = ColorSequence.new(Color3.fromRGB(200, 255, 120)),
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		Rate = 10,
		Lifetime = NumberRange.new(3, 6),
		Speed = NumberRange.new(0.3, 0.9),
		SpreadAngle = Vector2.new(180, 180),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.45),
			NumberSequenceKeypoint.new(1, 0),
		}),
	})

	-- Gems and a halo ring circling above the cupola.
	local orbit = Instance.new("Model")
	orbit.Name = "GemOrbit"
	orbit.Parent = model
	local orbitY = vaneTop + 9
	local hub = noCollide(part({
		Name = "OrbitHub",
		Size = Vector3.one,
		CFrame = at(0, orbitY, 0),
		Transparency = 1,
		Parent = orbit,
	}))
	orbit.PrimaryPart = hub
	local segments = 28
	local radius = 7
	for k = 0, segments - 1 do
		local a0, a1 = k / segments * math.pi * 2, (k + 1) / segments * math.pi * 2
		local p0 = at(math.cos(a0) * radius, orbitY, math.sin(a0) * radius).Position
		local p1 = at(math.cos(a1) * radius, orbitY, math.sin(a1) * radius).Position
		noCollide(part({
			Name = "Halo",
			Size = Vector3.new(0.4, 0.4, (p1 - p0).Magnitude + 0.1),
			CFrame = CFrame.lookAt((p0 + p1) / 2, p1),
			Color = GOLD,
			Material = Enum.Material.Neon,
			CastShadow = false,
			Parent = orbit,
		}))
	end
	local gemColors = {
		accent,
		Color3.fromRGB(80, 220, 255),
		Color3.fromRGB(190, 90, 255),
		GOLD,
		Color3.fromRGB(255, 80, 120),
		SLIME,
	}
	for k, color in gemColors do
		local angle = k / #gemColors * math.pi * 2
		noCollide(part({
			Name = "OrbitGem",
			Size = Vector3.new(1.3, 1.3, 1.3),
			CFrame = at(math.cos(angle) * radius, orbitY + 0.9, math.sin(angle) * radius)
				* CFrame.Angles(math.rad(45), 0, math.rad(45)),
			Color = color,
			Material = Enum.Material.Neon,
			CastShadow = false,
			Parent = orbit,
		}))
	end
	spinner(orbit, "spin", 0.5)

	if level < 7 then
		return
	end

	-- Level 7 -----------------------------------------------------------------

	-- Red carpet up to the doors, between velvet ropes on gold posts.
	local carpetLength = 16
	noCollide(part({
		Name = "RedCarpet",
		Size = Vector3.new(8, 0.12, carpetLength),
		CFrame = at(0, 0.36, -half - 1 - carpetLength / 2),
		Color = Color3.fromRGB(200, 25, 40),
		Material = Enum.Material.Fabric,
		Parent = model,
	}))
	for _, side in { -1, 1 } do
		noCollide(part({
			Name = "CarpetEdge",
			Size = Vector3.new(0.35, 0.14, carpetLength),
			CFrame = at(side * 4, 0.37, -half - 1 - carpetLength / 2),
			Color = GOLD,
			Material = Enum.Material.Foil,
			Parent = model,
		}))
		local posts = {}
		for k = 0, 3 do
			local z = -half - 3 - k * 4.5
			part({
				Name = "Stanchion",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(3, 0.4, 0.4),
				CFrame = at(side * 5.2, 1.8, z) * CFrame.Angles(0, 0, math.pi / 2),
				Color = GOLD,
				Material = Enum.Material.Foil,
				Parent = model,
			})
			noCollide(part({
				Name = "StanchionTop",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * 0.7,
				CFrame = at(side * 5.2, 3.4, z),
				Color = GOLD,
				Material = Enum.Material.Foil,
				Parent = model,
			}))
			part({
				Name = "StanchionBase",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.3, 1.4, 1.4),
				CFrame = at(side * 5.2, 0.45, z) * CFrame.Angles(0, 0, math.pi / 2),
				Color = GOLD,
				Material = Enum.Material.Foil,
				Parent = model,
			})
			table.insert(posts, at(side * 5.2, 3.1, z).Position)
		end
		for k = 1, #posts - 1 do
			-- Each rope dips in the middle: two halves meeting lower down.
			local a, b = posts[k], posts[k + 1]
			local dip = (a + b) / 2 - Vector3.new(0, 0.8, 0)
			for _, pair in { { a, dip }, { dip, b } } do
				noCollide(part({
					Name = "VelvetRope",
					Shape = Enum.PartType.Cylinder,
					Size = Vector3.new((pair[2] - pair[1]).Magnitude, 0.3, 0.3),
					CFrame = CFrame.lookAt((pair[1] + pair[2]) / 2, pair[2]) * CFrame.Angles(0, math.pi / 2, 0),
					Color = Color3.fromRGB(170, 20, 40),
					Material = Enum.Material.Fabric,
					Parent = model,
				}))
			end
		end
	end

	-- Trophy wall: their three rarest Freeks mounted on gold-rimmed shields on the upper
	-- storey, between its windows.
	for k, species in champions do
		local info = Freeks.byId[species]
		local color = info and Rarities.info[info.rarity] and Rarities.info[info.rarity].color or WHITE
		local spot = at((k - 2) * 7.6, upperY - 0.2, -half - 0.65)
		part({
			Name = "TrophyRim",
			Size = Vector3.new(6.4, 5.6, 0.3),
			CFrame = spot * CFrame.new(0, 0, 0.1),
			Color = GOLD,
			Material = Enum.Material.Foil,
			Parent = model,
		})
		part({
			Name = "TrophyBoard",
			Size = Vector3.new(5.6, 4.8, 0.4),
			CFrame = spot,
			Color = Color3.fromRGB(110, 70, 45),
			Material = Enum.Material.WoodPlanks,
			Parent = model,
		})
		noCollide(part({
			Name = "TrophyRibbon",
			Size = Vector3.new(5.6, 0.7, 0.45),
			CFrame = spot * CFrame.new(0, -2.05, -0.05),
			Color = color,
			Material = Enum.Material.Neon,
			Parent = model,
		}))
		part({
			Name = "TrophyShelf",
			Size = Vector3.new(4.4, 0.35, 1.8),
			CFrame = spot * CFrame.new(0, -1.4, -1),
			Color = GOLD,
			Material = Enum.Material.Foil,
			Parent = model,
		})
		local figure = freekFigure(species, 3.4, spot * CFrame.new(0, -1.22, -1))
		if figure then
			figure.Name = "Trophy"
			for _, d in figure:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					noCollide(d)
				end
			end
			figure.Parent = model
		end
	end

	-- Fireworks launch from the roof now and then (the client sets them off).
	local launcher = noCollide(part({
		Name = "FireworkLauncher",
		Size = Vector3.one,
		CFrame = at(0, ridge + 2, 0),
		Transparency = 1,
		Parent = model,
	}))
	CollectionService:AddTag(launcher, BarnUpgrades.FIREWORKS_TAG)
end

--------------------------------------------------------------------------------

-- Shows the barn for a level (0 = plain barn). data (the owner's save) picks the Freeks
-- for the statues and trophies; nil for an empty barn.
function BarnUpgrades.apply(plot, level: number, data)
	level = math.clamp(level or 0, 0, BarnUpgrades.MAX_LEVEL)
	local champions = if level >= 2 then proudest(data, 3) else {}
	local key = level .. "|" .. table.concat(champions, ",")
	if plot.upgradeKey == key then
		return
	end
	plot.upgradeKey = key
	local barnFolder: Instance = plot.freeks.Parent
	if plot.upgradeModel then
		plot.upgradeModel:Destroy()
		plot.upgradeModel = nil
	end
	restore(barnFolder)
	if level <= 0 then
		return
	end
	local model = Instance.new("Model")
	model.Name = "BarnUpgrades"
	model.Parent = barnFolder
	plot.upgradeModel = model
	build(plot, level, model, champions)
end

return BarnUpgrades
