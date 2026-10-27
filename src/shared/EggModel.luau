-- The eggs you steal from the zones: plain egg shapes covered in LEGO studs, coloured by
-- what's inside. The shell is the item's main colour, and its second colour picks out a
-- pattern in the studs for its kind (spots for pets, a zig-zag band of grass for plants,
-- stripes for yard items, alternating rows like bricks for house parts). Legendary and up
-- get a gold band, Mystic and up a glowing one. Secret eggs glow and flash in every colour
-- (an aura round the shell and a light, tagged SECRET_TAG; each client animates them, see
-- Main). Without an item (the zone's egg in general, e.g. in the Shop) it's the zone's
-- colours (Items.ZONES eggColor / spotColor) with spots.
--
-- EggModel.build(zoneIndex, itemId?) returns the model (standing on its pivot, the bottom
-- of the egg; PrimaryPart = the shell) and its height.

local ItemModel = require(script.Parent.ItemModel)
local Items = require(script.Parent.Items)
local Rarities = require(script.Parent.Rarities)

local EggModel = {}

EggModel.SECRET_TAG = "SecretEgg"

local W, H = 2.6, 3.4 -- the shell's width and height
local GOLD = Color3.fromRGB(255, 205, 60)

local function part(model: Model, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		p[key] = value
	end
	p.Parent = model
	return p
end

local function egg(model: Model, size: Vector3, cframe: CFrame, color: Color3, material)
	local p = part(model, { Size = size, CFrame = cframe, Color = color, Material = material })
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

local function brightness(c: Color3): number
	return c.R * 0.3 + c.G * 0.59 + c.B * 0.11
end

-- The item's two main colours: the colours covering the most of it, by volume.
local function palette(model: Model): (Color3, Color3)
	local totals, colors = {}, {}
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 0.5 then
			local key = string.format("%d,%d,%d", p.Color.R * 20, p.Color.G * 20, p.Color.B * 20)
			local s = p.Size
			totals[key] = (totals[key] or 0) + math.min(s.X * s.Y * s.Z, 60)
			colors[key] = p.Color
		end
	end
	local order = {}
	for key in totals do
		table.insert(order, key)
	end
	table.sort(order, function(a, b)
		return totals[a] > totals[b]
	end)
	local main = order[1] and colors[order[1]] or Color3.fromRGB(240, 240, 240)
	local second = nil
	for i = 2, #order do
		local c = colors[order[i]]
		local d = math.abs(c.R - main.R) + math.abs(c.G - main.G) + math.abs(c.B - main.B)
		if d > 0.35 then
			second = c
			break
		end
	end
	if not second then
		-- One-colour items get a lighter or darker shade for their pattern.
		second = if brightness(main) > 0.6
			then main:Lerp(Color3.new(0, 0, 0), 0.35)
			else main:Lerp(Color3.new(1, 1, 1), 0.45)
	end
	return main, second
end

-- The pattern on the shell, by what kind of thing is inside.
local STUD = 0.42 -- stud diameter
local STUD_HEIGHT = 0.12 -- how far a stud stands out of the shell
local STUD_GAP = 0.66 -- distance between stud centres

-- Covers the shell in rows of studs. Each stud's colour comes from `colorAt(ring, rings,
-- angle, y)` (ring 1 is the lowest; y is -1 at the bottom to 1 at the top).
local function studs(model: Model, colorAt: (number, number, number, number) -> Color3, skipY: number?)
	local rings = 11
	for ring = 1, rings do
		local phi = math.rad(-72 + (ring - 1) * 144 / (rings - 1)) -- latitude, bottom to top
		local y = math.sin(phi)
		if skipY and math.abs(y - skipY) < 0.12 then
			continue -- leave room for the band
		end
		local r = math.cos(phi) * W / 2
		local count = math.max(3, math.floor(2 * math.pi * r / STUD_GAP))
		local twist = (ring % 2) * 0.5
		for k = 0, count - 1 do
			local a = (k + twist) / count * math.pi * 2
			local spot = Vector3.new(math.cos(a) * r, H / 2 + y * H / 2, math.sin(a) * r)
			-- The shell's surface normal there (it's an ellipsoid).
			local normal = Vector3.new(spot.X / (W / 2) ^ 2, (spot.Y - H / 2) / (H / 2) ^ 2, spot.Z / (W / 2) ^ 2).Unit
			local stud = part(model, {
				Name = "Stud",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(STUD_HEIGHT * 2, STUD, STUD),
				-- The cylinder's axis (its X) points out of the shell; half of it is inside.
				CFrame = CFrame.lookAt(spot, spot + normal) * CFrame.Angles(0, math.pi / 2, 0),
				Color = colorAt(ring, rings, a, y),
			})
			stud.CastShadow = false
		end
	end
	-- One on the very top.
	part(model, {
		Name = "Stud",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(STUD_HEIGHT * 2, STUD, STUD),
		CFrame = CFrame.new(0, H, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = colorAt(rings + 1, rings, 0, 1),
	})
end

-- How the studs are coloured for each kind of item: the pattern, in the second colour.
local function patternFor(kind: string?, main: Color3, second: Color3, rng: Random)
	local stud = main:Lerp(Color3.new(1, 1, 1), 0.1) -- plain studs, a touch lighter than the shell
	if kind == "Yard" then
		return function(ring)
			return if ring == 3 or ring == 6 then second else stud
		end
	elseif kind == "House" then
		return function(ring)
			return if ring % 2 == 0 then second else stud
		end
	elseif kind == "Plant" then
		return function(_ring, _rings, a, y)
			-- A zig-zag band of grass round the bottom.
			local edge = -0.35 + 0.22 * math.abs(math.sin(a * 3))
			return if y < edge then second else stud
		end
	end
	-- Spots: a few round patches of the second colour.
	local centres = {}
	for _ = 1, 5 do
		table.insert(centres, { a = rng:NextNumber() * math.pi * 2, y = rng:NextNumber(-0.7, 0.7) })
	end
	return function(_ring, _rings, a, y)
		for _, c in centres do
			local da = math.abs((a - c.a + math.pi) % (2 * math.pi) - math.pi)
			if da * da * 0.5 + (y - c.y) ^ 2 < 0.16 then
				return second
			end
		end
		return stud
	end
end

function EggModel.build(zoneIndex: number, itemId: string?): (Model, number)
	local zone = Items.ZONES[zoneIndex] or Items.ZONES[1]
	local info = itemId and Items.byId[itemId]
	local model = Instance.new("Model")
	model.Name = "Egg"
	model:SetAttribute("Zone", zoneIndex)
	if info then
		model:SetAttribute("Item", itemId)
	end

	local main, second = zone.eggColor, zone.spotColor
	if info then
		local sample = ItemModel.buildNormal(itemId)
		main, second = palette(sample)
		sample:Destroy()
	end
	local shell = egg(model, Vector3.new(W, H, W), CFrame.new(0, H / 2, 0), main)
	shell.Name = "Shell"
	-- The model's pivot is the bottom of the egg, so it stands on whatever it's put on.
	shell.PivotOffset = CFrame.new(0, -H / 2, 0)
	model.PrimaryPart = shell

	local rank = Rarities.rank[if info then info.rarity else "Common"] or 1
	local banded = (info and rank >= Rarities.rank.Legendary) or (not info and zoneIndex >= 5)
	local rng = Random.new(if itemId then #itemId * 131 + zoneIndex else zoneIndex * 97)
	studs(model, patternFor(info and info.kind, main, second, rng), if banded then -0.08 else nil)

	if banded then
		-- A band round the middle: gold, or glowing in the rarity's colour for Mystic and up.
		local glowing = info and rank >= Rarities.rank.Mystic
		local band = part(model, {
			Shape = Enum.PartType.Cylinder,
			CFrame = CFrame.new(0, H * 0.46, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Size = Vector3.new(0.5, W * 1.08, W * 1.08),
			Color = if glowing then Rarities.info[info.rarity].color else GOLD,
			Material = if glowing then Enum.Material.Neon else Enum.Material.Foil,
		})
		band.Name = "Band"
	end

	local top = H + 0.15
	if info and info.rarity == "Secret" then
		-- A glowing aura round the shell, a light and sparkles; clients make them flash.
		local glow = egg(
			model,
			Vector3.new(W, H, W) * 1.18,
			CFrame.new(0, H / 2, 0),
			Rarities.info.Secret.color,
			Enum.Material.Neon
		)
		glow.Name = "SecretGlow"
		glow.Transparency = 0.55
		glow.CastShadow = false
		local light = Instance.new("PointLight")
		light.Name = "SecretLight"
		light.Range = 14
		light.Brightness = 3
		light.Color = Rarities.info.Secret.color
		light.Parent = shell
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.fromRGB(255, 255, 255)
		sparkles.Parent = glow
		model:SetAttribute("Secret", true)
		game:GetService("CollectionService"):AddTag(model, EggModel.SECRET_TAG)
	end
	return model, top
end

return EggModel
