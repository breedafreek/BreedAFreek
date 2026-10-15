-- Halloween props: ghosts, bats, cobwebs, tombstones, dead trees, a witch's cauldron,
-- witch hats, string lights and creeping fog.
--
-- Ghosts and bats are tagged; each client flies them around (see client/Ambient) using
-- the attributes set here, so they move smoothly without network traffic.

local CollectionService = game:GetService("CollectionService")

local Decor = require(script.Parent.Decor)

local part = Decor.part

local HalloweenDecor = {}

HalloweenDecor.GHOST_TAG = "SpookyGhost"
HalloweenDecor.BAT_TAG = "SpookyBat"

-- Shared flight settings read by the client: circle `center` at `radius`, `height` up.
local function flightPath(model: Model, center: Vector3, radius: number, height: number, speed: number, phase: number)
	model:SetAttribute("Center", center)
	model:SetAttribute("Radius", radius)
	model:SetAttribute("Height", height)
	model:SetAttribute("Speed", speed)
	model:SetAttribute("Phase", phase)
end

function HalloweenDecor.ghost(
	parent: Instance,
	center: Vector3,
	radius: number,
	height: number,
	speed: number,
	phase: number
)
	local model = Instance.new("Model")
	model.Name = "Ghost"
	local white = Color3.fromRGB(240, 245, 255)
	local origin = CFrame.new(center + Vector3.new(radius, height, 0))
	local head = part({
		Name = "Head",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 3.2,
		CFrame = origin,
		Color = white,
		Transparency = 0.15,
		CanCollide = false,
		CastShadow = false,
		Parent = model,
	})
	part({
		Name = "Body",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.6, 3.1, 3.1),
		CFrame = origin * CFrame.new(0, -1.3, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = white,
		Transparency = 0.15,
		CanCollide = false,
		CastShadow = false,
		Parent = model,
	})
	-- Wavy hem.
	for i = 0, 5 do
		local angle = i / 6 * math.pi * 2
		part({
			Name = "Hem",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 1.2,
			CFrame = origin * CFrame.new(math.cos(angle) * 1.2, -2.7, math.sin(angle) * 1.2),
			Color = white,
			Transparency = 0.15,
			CanCollide = false,
			CastShadow = false,
			Parent = model,
		})
	end
	for _, x in { -1.6, 1.6 } do
		part({
			Name = "Arm",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1, 1, 1),
			CFrame = origin * CFrame.new(x, -0.9, -0.3),
			Color = white,
			Transparency = 0.15,
			CanCollide = false,
			CastShadow = false,
			Parent = model,
		})
	end
	for _, x in { -0.55, 0.55 } do
		part({
			Name = "Eye",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.6,
			CFrame = origin * CFrame.new(x, 0.3, -1.4),
			Color = Color3.fromRGB(20, 20, 30),
			CanCollide = false,
			Parent = model,
		})
	end
	part({
		Name = "Mouth",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.7, 0.7, 0.7),
		CFrame = origin * CFrame.new(0, -0.5, -1.4),
		Color = Color3.fromRGB(20, 20, 30),
		CanCollide = false,
		Parent = model,
	})
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(190, 220, 255)
	glow.Range = 12
	glow.Brightness = 0.8
	glow.Parent = head
	model.PrimaryPart = head
	flightPath(model, center, radius, height, speed, phase)
	model.Parent = parent
	CollectionService:AddTag(model, HalloweenDecor.GHOST_TAG)
	return model
end

function HalloweenDecor.bat(
	parent: Instance,
	center: Vector3,
	radius: number,
	height: number,
	speed: number,
	phase: number
)
	local model = Instance.new("Model")
	model.Name = "Bat"
	local black = Color3.fromRGB(28, 22, 36)
	local origin = CFrame.new(center + Vector3.new(radius, height, 0))
	local body = part({
		Name = "Body",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.1, 1.1, 1.1),
		CFrame = origin,
		Color = black,
		CanCollide = false,
		Parent = model,
	})
	part({
		Name = "Head",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 0.75,
		CFrame = origin * CFrame.new(0, 0.35, -0.55),
		Color = black,
		CanCollide = false,
		Parent = model,
	})
	for _, x in { -0.18, 0.18 } do
		part({
			Name = "Eye",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.16,
			CFrame = origin * CFrame.new(x, 0.42, -0.88),
			Color = Color3.fromRGB(255, 60, 40),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = model,
		})
	end
	for _, side in { -1, 1 } do
		part({
			Name = if side < 0 then "WingL" else "WingR",
			Size = Vector3.new(2.2, 0.1, 1.3),
			CFrame = origin * CFrame.new(side * 1.5, 0, 0),
			Color = Color3.fromRGB(45, 30, 55),
			CanCollide = false,
			Parent = model,
		})
	end
	model.PrimaryPart = body
	flightPath(model, center, radius, height, speed, phase)
	model.Parent = parent
	CollectionService:AddTag(model, HalloweenDecor.BAT_TAG)
	return model
end

-- A cobweb in a corner. `corner` sits in the corner with -X/-Y pointing into the opening,
-- so place it rotated to suit each corner.
function HalloweenDecor.cobweb(parent: Instance, corner: CFrame, size: number)
	local white = Color3.fromRGB(235, 235, 240)
	local strand = function(a: Vector3, b: Vector3)
		local length = (b - a).Magnitude
		part({
			Name = "Web",
			Size = Vector3.new(0.07, 0.07, length),
			CFrame = CFrame.lookAt(a, b) * CFrame.new(0, 0, -length / 2),
			Color = white,
			Transparency = 0.3,
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
	end
	local spokes = {}
	for i = 0, 4 do
		local angle = math.rad(180 + i * 22.5)
		local tip = corner * CFrame.new(math.cos(angle) * size * -1, math.sin(angle) * size, 0)
		spokes[i] = tip.Position
		strand(corner.Position, tip.Position)
	end
	for _, ring in { 0.35, 0.65, 0.95 } do
		for i = 0, 3 do
			local a = corner.Position:Lerp(spokes[i], ring)
			local b = corner.Position:Lerp(spokes[i + 1], ring)
			strand(a, b)
		end
	end
end

function HalloweenDecor.tombstone(parent: Instance, ground: CFrame, seed: number)
	local rng = Random.new(seed)
	local stone = Color3.fromRGB(130, 130, 140):Lerp(Color3.fromRGB(95, 100, 105), rng:NextNumber())
	local lean = ground * CFrame.Angles(math.rad(rng:NextNumber(-8, 8)), 0, math.rad(rng:NextNumber(-10, 10)))
	local slab = part({
		Name = "Tombstone",
		Size = Vector3.new(3, 3.4, 0.8),
		CFrame = lean * CFrame.new(0, 1.7, 0),
		Color = stone,
		Material = Enum.Material.Slate,
		Parent = parent,
	})
	part({
		Name = "TombstoneTop",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.8, 3, 3),
		CFrame = lean * CFrame.new(0, 3.4, 0) * CFrame.Angles(0, math.pi / 2, 0),
		Color = stone,
		Material = Enum.Material.Slate,
		Parent = parent,
	})
	part({
		Name = "Dirt",
		Size = Vector3.new(2.6, 0.4, 4),
		CFrame = ground * CFrame.new(0, 0.2, -2.6),
		Color = Color3.fromRGB(85, 60, 45),
		Material = Enum.Material.Ground,
		CanCollide = false,
		Parent = parent,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 0.6)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.Fondamento
	label.Text = "R.I.P."
	label.TextColor3 = Color3.fromRGB(60, 60, 70)
	label.Parent = gui
	gui.Parent = slab
end

-- A bare, twisted tree.
function HalloweenDecor.deadTree(parent: Instance, ground: CFrame, scale: number, seed: number)
	local rng = Random.new(seed)
	local bark = Color3.fromRGB(60, 45, 40)
	local function branch(from: CFrame, length: number, thickness: number, depth: number)
		local tip = from * CFrame.new(0, length, 0)
		part({
			Name = "Branch",
			Size = Vector3.new(thickness, length, thickness),
			CFrame = from * CFrame.new(0, length / 2, 0),
			Color = bark,
			Material = Enum.Material.Wood,
			Parent = parent,
		})
		if depth > 0 then
			for _ = 1, 2 do
				local turn = CFrame.Angles(math.rad(rng:NextNumber(-55, 55)), math.rad(rng:NextNumber(0, 360)), 0)
				branch(tip * turn, length * 0.65, thickness * 0.6, depth - 1)
			end
		end
	end
	branch(ground, 7 * scale, 1.3 * scale, 3)
end

function HalloweenDecor.cauldron(parent: Instance, ground: CFrame)
	local iron = Color3.fromRGB(35, 35, 40)
	part({
		Name = "Cauldron",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 6,
		CFrame = ground * CFrame.new(0, 3, 0),
		Color = iron,
		Material = Enum.Material.Metal,
		Parent = parent,
	})
	part({
		Name = "Rim",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 5.4, 5.4),
		CFrame = ground * CFrame.new(0, 5.5, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = iron,
		Material = Enum.Material.Metal,
		Parent = parent,
	})
	local brew = part({
		Name = "Brew",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 4.8, 4.8),
		CFrame = ground * CFrame.new(0, 5.65, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(110, 255, 90),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = parent,
	})
	for i = 0, 2 do
		local angle = i / 3 * math.pi * 2
		part({
			Name = "Leg",
			Size = Vector3.new(0.6, 1.6, 0.6),
			CFrame = ground * CFrame.new(math.cos(angle) * 2, 0.8, math.sin(angle) * 2),
			Color = iron,
			Material = Enum.Material.Metal,
			Parent = parent,
		})
	end
	-- Firewood and flames underneath.
	for i = 0, 3 do
		part({
			Name = "Log",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(4, 0.7, 0.7),
			CFrame = ground * CFrame.new(0, 0.35, 0) * CFrame.Angles(0, i * math.pi / 4, 0),
			Color = Color3.fromRGB(100, 65, 40),
			Material = Enum.Material.Wood,
			Parent = parent,
		})
	end
	local embers = part({
		Name = "Embers",
		Size = Vector3.new(1, 1, 1),
		CFrame = ground * CFrame.new(0, 0.7, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = parent,
	})
	local fire = Instance.new("Fire")
	fire.Size = 4
	fire.Heat = 4
	fire.Parent = embers

	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(120, 255, 110)
	smoke.Opacity = 0.18
	smoke.RiseVelocity = 3
	smoke.Size = 2.5
	smoke.Parent = brew
	local bubbles = Instance.new("Sparkles")
	bubbles.SparkleColor = Color3.fromRGB(150, 255, 120)
	bubbles.Parent = brew
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(110, 255, 90)
	light.Range = 22
	light.Brightness = 2
	light.Parent = brew
end

-- A pointy witch hat; ground is the bottom of the brim.
function HalloweenDecor.witchHat(parent: Instance, ground: CFrame, scale: number, color: Color3)
	local s = scale
	part({
		Name = "Brim",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.35 * s, 7 * s, 7 * s),
		CFrame = ground * CFrame.new(0, 0.18 * s, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = color,
		Parent = parent,
	})
	part({
		Name = "Band",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6 * s, 4.7 * s, 4.7 * s),
		CFrame = ground * CFrame.new(0, 0.6 * s, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(255, 150, 40),
		Parent = parent,
	})
	-- Stacked, shrinking, slightly bent tiers make the cone.
	local tier = ground * CFrame.new(0, 0.9 * s, 0)
	for i, d in { 4.5, 3.6, 2.7, 1.8, 1 } do
		local h = 1.3 * s
		part({
			Name = "Cone",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(h, d * s, d * s),
			CFrame = tier * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Color = color,
			Parent = parent,
		})
		tier = tier * CFrame.new(0, h * 0.9, 0) * CFrame.Angles(0, 0, math.rad(if i >= 3 then 9 else 2))
	end
end

-- A strand of glowing bulbs from a to b, sagging in the middle.
function HalloweenDecor.stringLights(parent: Instance, a: Vector3, b: Vector3, count: number, sag: number)
	local colors = { Color3.fromRGB(255, 140, 30), Color3.fromRGB(170, 80, 255) }
	local previous = a
	for i = 0, count do
		local t = i / count
		local point = a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * sag, 0)
		if i > 0 then
			local length = (point - previous).Magnitude
			part({
				Name = "Wire",
				Size = Vector3.new(0.06, 0.06, length),
				CFrame = CFrame.lookAt(previous, point) * CFrame.new(0, 0, -length / 2),
				Color = Color3.fromRGB(20, 20, 20),
				CanCollide = false,
				CastShadow = false,
				Parent = parent,
			})
		end
		if i > 0 and i < count then
			part({
				Name = "Bulb",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * 0.45,
				CFrame = CFrame.new(point - Vector3.new(0, 0.25, 0)),
				Color = colors[i % 2 + 1],
				Material = Enum.Material.Neon,
				CanCollide = false,
				CastShadow = false,
				Parent = parent,
			})
		end
		previous = point
	end
end

-- Low, slow-drifting ground fog.
function HalloweenDecor.fog(parent: Instance, position: Vector3)
	local holder = part({
		Name = "Fog",
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(position),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Parent = parent,
	})
	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(185, 175, 210)
	smoke.Opacity = 0.07
	smoke.RiseVelocity = 0.2
	smoke.Size = 12
	smoke.Parent = holder
end

return HalloweenDecor
