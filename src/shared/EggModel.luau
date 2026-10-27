-- The eggs you steal from the zones. Each egg is designed around the item inside it: the
-- shell is in the item's own colours with a pattern for its kind (round spots for pets,
-- leaves for plants, stripes for yard items, bricks for house parts), the top is cracked
-- open with a little copy of the item poking out, Legendary and up get a gold band and
-- Mystic and up a glowing one. Secret eggs glow and flash in every colour (an aura round
-- the shell and a light, tagged SECRET_TAG; each client animates them, see Main). Without an item (the zone's egg in general, e.g. in the Shop)
-- it's the zone's colours (Items.ZONES eggColor / spotColor) with spots.
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

-- A point on the shell's surface at height fraction y (-1 bottom to 1 top) and angle a,
-- facing outward.
local function onShell(y: number, a: number): CFrame
	local r = math.sqrt(math.max(1 - y * y, 0))
	local normal = Vector3.new(math.cos(a) * r, y * 1.25, math.sin(a) * r).Unit
	local spot = Vector3.new(math.cos(a) * r * W / 2, H / 2 + y * H / 2, math.sin(a) * r * W / 2)
	return CFrame.lookAt(spot, spot + normal) * CFrame.new(0, 0, -0.02)
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
local function pattern(model: Model, kind: string?, color: Color3, rng: Random)
	if kind == "Yard" then
		-- Two bold stripes round the egg.
		for _, y in { 0.3, 0.62 } do
			part(model, {
				Name = "Stripe",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.4, W * 0.98, W * 0.98),
				CFrame = CFrame.new(0, H * y, 0) * CFrame.Angles(0, 0, math.pi / 2),
				Color = color,
			})
		end
		return
	end
	if kind == "House" then
		-- Rows of little bricks.
		for row, y in { -0.45, -0.1, 0.25 } do
			for k = 0, 6 do
				local a = (k + (row % 2) * 0.5) / 7 * math.pi * 2
				part(model, {
					Name = "Brick",
					Size = Vector3.new(0.75, 0.32, 0.12),
					CFrame = onShell(y, a),
					Color = color,
				})
			end
		end
		return
	end
	for _ = 1, 11 do
		local a = rng:NextNumber() * math.pi * 2
		local y = rng:NextNumber(-0.75, 0.55)
		local size = rng:NextNumber(0.55, 0.9)
		if kind == "Plant" then
			-- Leaves, at an angle.
			egg(
				model,
				Vector3.new(size * 1.3, size * 0.55, 0.22),
				onShell(y, a) * CFrame.Angles(0, 0, rng:NextNumber(-0.8, 0.8)),
				color
			)
		else
			egg(model, Vector3.new(size, size, 0.25), onShell(y, a), color)
		end
	end
end

-- A cracked-open top: a ring of jagged shell shards with the item poking out.
local function crackedTop(model: Model, shell: Color3, itemId: string)
	local y = 0.56 -- where the crack runs round (fraction of half-height above the middle)
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		local tall = if k % 2 == 0 then 0.55 else 0.32
		part(model, {
			Name = "Shard",
			Size = Vector3.new(0.5, tall, 0.14),
			CFrame = onShell(y, a) * CFrame.Angles(math.rad(-20), 0, math.rad(45)) * CFrame.new(0, 0, 0.02),
			Color = shell:Lerp(Color3.new(1, 1, 1), 0.25),
		})
	end
	-- The item itself, small, sitting in the top of the egg.
	local item = ItemModel.buildNormal(itemId)
	local _, size = item:GetBoundingBox()
	local fit = 1.9 / math.max(size.X, size.Y * 0.8, size.Z, 0.1)
	Items.scaleModel(item, fit)
	item:PivotTo(CFrame.new(0, H * 0.72, 0))
	for _, p in item:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.Parent = model
		elseif p:IsA("Sparkles") or p:IsA("ParticleEmitter") or p:IsA("PointLight") then
			p:Destroy()
		end
	end
	item:Destroy()
	return H * 0.72 + size.Y * fit
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

	pattern(model, info and info.kind, second, Random.new(if itemId then #itemId * 131 + zoneIndex else zoneIndex * 97))

	local rank = Rarities.rank[if info then info.rarity else "Common"] or 1
	if (info and rank >= Rarities.rank.Legendary) or (not info and zoneIndex >= 5) then
		-- A band round the middle: gold, or glowing in the rarity's colour for Mystic and up.
		local glowing = info and rank >= Rarities.rank.Mystic
		local band = part(model, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.35, W * 1.03, W * 1.03),
			CFrame = CFrame.new(0, H * 0.46, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Color = if glowing then Rarities.info[info.rarity].color else GOLD,
			Material = if glowing then Enum.Material.Neon else Enum.Material.Foil,
		})
		band.Name = "Band"
	end

	local top = H
	if info then
		top = math.max(top, crackedTop(model, main, itemId))
	end
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
