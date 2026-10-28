-- The eggs you steal from the zones, in the "crafted" look (detailed low-poly, no LEGO
-- studs; attribute "Crafted"): a shell of many small dark plates, each set a little in or
-- out and tilted, over a glowing core that shines through every seam; glowing strips and
-- rune marks on some plates, gold rivets, a gold spike on top, a soft light and a few
-- drifting sparks. The plates are tinted by what's inside (the item's main colour, darkened;
-- its second colour picks out a pattern for its kind: patches for pets, a band of grass
-- for plants, stripes for yard items, alternate rows for house parts) and the glow is the
-- rarity's colour. Legendary and up get a gold band, Mystic and up a glowing one. Secret
-- eggs flash in every colour (an aura and a light, tagged SECRET_TAG; each client animates
-- them, see Main). Without an item (the zone's egg in general) it's the zone's colours.
--
-- EggModel.build(zoneIndex, itemId?) returns the model (standing on its pivot, the bottom
-- of the egg; PrimaryPart = the shell) and its height.

local ItemModel = require(script.Parent.ItemModel)
local Items = require(script.Parent.Items)
local Rarities = require(script.Parent.Rarities)

local EggModel = {}

EggModel.SECRET_TAG = "SecretEgg"

local W, H = 3.2, 4.2 -- the shell's width and height (about chest height on a player)
local GOLD = Color3.fromRGB(255, 200, 70)
local DARK = Color3.fromRGB(26, 30, 38)

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

-- The glow for each rarity (Common's grey would look dead, so it glows cyan).
local function glowColor(rarity: string): Color3
	if rarity == "Common" then
		return Color3.fromRGB(80, 220, 255)
	end
	return Rarities.info[rarity].color
end

-- Which plates get the second colour, by what kind of thing is inside. `ring` 1 is the
-- lowest band, `y` is -1 at the bottom to 1 at the top, `a` the angle round.
local function patternFor(kind: string?, rng: Random)
	if kind == "Yard" then
		return function(ring)
			return ring == 3 or ring == 7
		end
	elseif kind == "House" then
		return function(ring)
			return ring % 2 == 0
		end
	elseif kind == "Plant" then
		return function(_ring, a, y)
			return y < -0.3 + 0.2 * math.abs(math.sin(a * 3))
		end
	end
	local centres = {}
	for _ = 1, 4 do
		table.insert(centres, { a = rng:NextNumber() * math.pi * 2, y = rng:NextNumber(-0.6, 0.6) })
	end
	return function(_ring, a, y)
		for _, c in centres do
			local da = math.abs((a - c.a + math.pi) % (2 * math.pi) - math.pi)
			if da * da * 0.6 + (y - c.y) ^ 2 < 0.14 then
				return true
			end
		end
		return false
	end
end

-- A point on the shell's surface (phi = latitude, a = angle round), its outward normal and
-- the direction "up" along the shell there.
local function surface(phi: number, a: number): (Vector3, Vector3, Vector3)
	-- Egg-shaped: narrower towards the top. The plates sit on a surface a little inside
	-- W x H so, with their thickness, the whole egg is about W x H.
	local function at(p: number): Vector3
		local r = (W / 2 - 0.22) * (1 - 0.13 * math.sin(p))
		return Vector3.new(
			math.cos(p) * math.cos(a) * r,
			H / 2 + math.sin(p) * (H / 2 - 0.1),
			math.cos(p) * math.sin(a) * r
		)
	end
	local point = at(phi)
	local up = (at(phi + 0.01) - at(phi - 0.01)).Unit
	local around = Vector3.new(-math.sin(a), 0, math.cos(a))
	local normal = around:Cross(up).Unit
	if normal:Dot(point - Vector3.new(0, H / 2, 0)) < 0 then
		normal = -normal
	end
	return point, normal, up
end

local RINGS = 7
local PHI_MIN, PHI_MAX = math.rad(-80), math.rad(80)

function EggModel.build(zoneIndex: number, itemId: string?): (Model, number)
	local zone = Items.ZONES[zoneIndex] or Items.ZONES[1]
	local info = itemId and Items.byId[itemId]
	local model = Instance.new("Model")
	model.Name = "Egg"
	model:SetAttribute("Round", true)
	model:SetAttribute("Crafted", true) -- keeps its own look (see Lego)
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
	local rarity = if info then info.rarity else "Common"
	local rank = Rarities.rank[rarity] or 1
	local glow = glowColor(rarity)
	local rng = Random.new(if itemId then #itemId * 131 + zoneIndex else zoneIndex * 97)

	-- The glowing core: it shows through every seam between the plates.
	local core = egg(model, Vector3.new(W * 0.74, H * 0.9, W * 0.74), CFrame.new(0, H / 2, 0), glow, Enum.Material.Neon)
	core.Name = "Shell"
	core.PivotOffset = CFrame.new(0, -H / 2, 0) -- the model stands on the bottom of the egg
	model.PrimaryPart = core
	local light = Instance.new("PointLight")
	light.Name = "CoreLight"
	light.Color = glow
	light.Range = 9
	light.Brightness = 1.2
	light.Parent = core

	-- The plates, ring by ring.
	local plate = main:Lerp(DARK, 0.7)
	local accent = second:Lerp(DARK, 0.55)
	local isAccent = patternFor(info and info.kind, rng)
	local band = rank >= (Rarities.rank.Legendary or 99)
	for ring = 1, RINGS do
		local phi0 = PHI_MIN + (ring - 1) * (PHI_MAX - PHI_MIN) / RINGS
		local phi1 = PHI_MIN + ring * (PHI_MAX - PHI_MIN) / RINGS
		local phi = (phi0 + phi1) / 2
		local y = math.sin(phi)
		local radius = math.cos(phi) * (W / 2 - 0.22) * (1 - 0.13 * y)
		local count = math.max(5, math.floor(2 * math.pi * radius / 0.5 + 0.5))
		local twist = (ring % 2) * 0.5 + rng:NextNumber(-0.15, 0.15)
		local bottom = surface(phi0, 0)
		local top = surface(phi1, 0)
		local height = (top - bottom).Magnitude
		local width = 2 * math.pi * radius / count
		local isBand = band and ring == math.ceil(RINGS / 2) + 1
		for k = 0, count - 1 do
			local a = (k + twist) / count * math.pi * 2
			local point, normal, up = surface(phi, a)
			local out = rng:NextNumber(-0.02, 0.1)
			local cframe = CFrame.lookAt(point + normal * (0.06 + out), point + normal * 2, up)
				* CFrame.Angles(
					math.rad(rng:NextNumber(-5, 5)),
					math.rad(rng:NextNumber(-5, 5)),
					math.rad(rng:NextNumber(-4, 4))
				)
			local shade = rng:NextNumber(-0.06, 0.06)
			local color = if isBand then GOLD elseif isAccent(ring, a, y) then accent else plate
			color = color:Lerp(if shade > 0 then Color3.new(1, 1, 1) else Color3.new(0, 0, 0), math.abs(shade))
			part(model, {
				Name = "Plate",
				Size = Vector3.new(width * rng:NextNumber(0.84, 0.92), height * rng:NextNumber(0.84, 0.94), 0.18),
				CFrame = cframe,
				Color = color,
				Material = if isBand then Enum.Material.Metal else Enum.Material.SmoothPlastic,
			})
			-- A second, smaller plate layered on some, a shade lighter or darker.
			if not isBand and rng:NextNumber() < 0.3 then
				part(model, {
					Name = "Layer",
					Size = Vector3.new(width * 0.55, height * rng:NextNumber(0.3, 0.5), 0.1),
					CFrame = cframe
						* CFrame.new(rng:NextNumber(-0.15, 0.15) * width, rng:NextNumber(-0.2, 0.2) * height, -0.12)
						* CFrame.Angles(0, 0, math.rad(rng:NextNumber(-8, 8))),
					Color = color:Lerp(
						if rng:NextNumber() < 0.5 then Color3.new(1, 1, 1) else Color3.new(0, 0, 0),
						0.18
					),
				})
			end
			-- Details on some plates: a glowing strip, a rune, or a gold rivet.
			local roll = rng:NextNumber()
			if not isBand and roll < 0.2 then
				part(model, {
					Name = "Strip",
					Size = Vector3.new(0.09, height * 0.55, 0.06),
					CFrame = cframe * CFrame.new(rng:NextNumber(-0.15, 0.15) * width, 0, -0.14),
					Color = glow,
					Material = Enum.Material.Neon,
				})
			elseif not isBand and roll < 0.27 and math.abs(y) < 0.6 then
				-- A rune: two short glowing strokes in a V or a cross.
				local spread = if rng:NextNumber() < 0.5 then 25 else 50
				for _, angle in { spread, -spread } do
					part(model, {
						Name = "Rune",
						Size = Vector3.new(0.07, height * 0.4, 0.05),
						CFrame = cframe * CFrame.new(0, 0, -0.14) * CFrame.Angles(0, 0, math.rad(angle)),
						Color = glow,
						Material = Enum.Material.Neon,
					})
				end
			elseif roll > 0.86 then
				local rivet = part(model, {
					Name = "Rivet",
					Shape = Enum.PartType.Ball,
					Size = Vector3.one * 0.16,
					CFrame = cframe * CFrame.new(width * 0.3, height * 0.3, -0.14),
					Color = GOLD,
					Material = Enum.Material.Metal,
				})
				rivet.CastShadow = false
			end
		end
	end

	-- A glowing ring round the middle for Mystic and up.
	if info and rank >= (Rarities.rank.Mystic or 99) then
		local ring = part(model, {
			Name = "GlowBand",
			Shape = Enum.PartType.Cylinder,
			CFrame = CFrame.new(0, H * 0.46, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Size = Vector3.new(0.12, W * 1.1, W * 1.1),
			Color = glow,
			Material = Enum.Material.Neon,
		})
		ring.Transparency = 0.2
	end

	-- Caps: a dark collar at the bottom, a gold spike on top.
	part(model, {
		Name = "Base",
		Shape = Enum.PartType.Cylinder,
		CFrame = CFrame.new(0, 0.12, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Size = Vector3.new(0.24, W * 0.4, W * 0.4),
		Color = plate,
	})
	for i, size in { 0.55, 0.38, 0.22, 0.1 } do
		part(model, {
			Name = "Spike",
			Size = Vector3.new(size, 0.22, size),
			CFrame = CFrame.new(0, H - 0.05 + (i - 1) * 0.2, 0) * CFrame.Angles(0, math.rad(45), 0),
			Color = GOLD,
			Material = Enum.Material.Metal,
		})
	end
	local tip = part(model, {
		Name = "Tip",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 0.2,
		CFrame = CFrame.new(0, H + 0.75, 0),
		Color = glow,
		Material = Enum.Material.Neon,
	})
	tip.CastShadow = false

	-- Drifting sparks (shown in the world, not in pictures).
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparks"
	sparks.Color = ColorSequence.new(glow:Lerp(GOLD, 0.3))
	sparks.LightEmission = 1
	sparks.Rate = 3
	sparks.Lifetime = NumberRange.new(1.5, 2.5)
	sparks.Speed = NumberRange.new(0.4, 1.2)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.14), NumberSequenceKeypoint.new(1, 0) })
	sparks.Parent = core

	local top = H + 0.9
	if info and info.rarity == "Secret" then
		-- A glowing aura round the shell and a brighter light; clients make them flash.
		local aura = egg(
			model,
			Vector3.new(W, H, W) * 1.12,
			CFrame.new(0, H / 2, 0),
			Rarities.info.Secret.color,
			Enum.Material.Neon
		)
		aura.Name = "SecretGlow"
		aura.Transparency = 0.7
		aura.CastShadow = false
		local secretLight = Instance.new("PointLight")
		secretLight.Name = "SecretLight"
		secretLight.Range = 14
		secretLight.Brightness = 3
		secretLight.Color = Rarities.info.Secret.color
		secretLight.Parent = core
		model:SetAttribute("Secret", true)
		game:GetService("CollectionService"):AddTag(model, EggModel.SECRET_TAG)
	end
	return model, top
end

return EggModel
