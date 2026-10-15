-- 3D models of the Monster Eggs (Halloween style), used for the egg stands in the world,
-- the Luck window and the hatch animation. Built from parts like the Freeks: the egg is a
-- ball stretched tall with a SpecialMesh, and the decorations sit on its surface.
--
-- EggModel.build(eggId) returns the model (pivot at the bottom of the egg, facing -Z)
-- and its height.

local EggModel = {}

local A, B = 1.5, 1.9 -- the egg's radius across and its half-height
local CENTER_Y = B

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function newPart(model: Model, props)
	local part = Instance.new(props.ClassName or "Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CastShadow = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		if key ~= "ClassName" and key ~= "Mesh" then
			part[key] = value
		end
	end
	if props.Mesh then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = props.Mesh
		mesh.Parent = part
	end
	part.Parent = model
	return part
end

-- A spot on the egg's surface: angle round from the front (radians, 0 = facing -Z), height
-- from the egg's middle, pushed out by `out`. Faces outward.
local function onEgg(angle: number, y: number, out: number?): CFrame
	local ring = A * math.sqrt(math.max(1 - (y * y) / (B * B), 0.02))
	local direction = Vector3.new(math.sin(angle), 0, -math.cos(angle))
	local position = direction * (ring + (out or 0)) + Vector3.new(0, CENTER_Y + y, 0)
	local normal = (direction / A + Vector3.new(0, y / (B * B), 0)).Unit
	return CFrame.lookAt(position, position + normal)
end

-- A diamond (a square turned 45°) flat on the surface.
local function diamond(model, cframe: CFrame, size: number, color: Color3, material)
	return newPart(model, {
		Size = Vector3.new(size, size, 0.12),
		CFrame = cframe * CFrame.Angles(0, 0, math.rad(45)),
		Color = color,
		Material = material or Enum.Material.Neon,
	})
end

local function body(model: Model, color: Color3, material)
	local egg = newPart(model, {
		Name = "Egg",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * (A * 2),
		CFrame = CFrame.new(0, CENTER_Y, 0),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		Mesh = Vector3.new(1, B / A, 1),
	})
	egg.PivotOffset = CFrame.new(0, -CENTER_Y, 0)
	model.PrimaryPart = egg
	return egg
end

local function effect(part: BasePart, kind: string, color: Color3)
	local instance
	if kind == "Glow" then
		instance = Instance.new("PointLight")
		instance.Color = color
		instance.Range = 10
		instance.Brightness = 2
	else
		instance = Instance.new("Sparkles")
		instance.SparkleColor = color
	end
	instance.Parent = part
end

local BUILDERS = {}

-- A pumpkin egg: orange with ribs, a stem, and a glowing jack-o'-lantern face.
function BUILDERS.Monster(model: Model)
	local egg = body(model, rgb(255, 140, 30))
	for i = 0, 3 do
		newPart(model, {
			Name = "Rib",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * (A * 2),
			CFrame = CFrame.new(0, CENTER_Y, 0) * CFrame.Angles(0, math.rad(i * 45), 0),
			Color = rgb(205, 90, 10),
			Mesh = Vector3.new(0.1, B / A * 1.006, 1.02),
		})
	end
	newPart(model, {
		Name = "Stem",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.8, 0.45, 0.45),
		CFrame = CFrame.new(0.05, CENTER_Y + B + 0.25, 0) * CFrame.Angles(0, 0, math.rad(80)),
		Color = rgb(95, 120, 45),
	})
	newPart(model, {
		Name = "Leaf",
		Size = Vector3.new(0.7, 0.08, 0.4),
		CFrame = CFrame.new(0.4, CENTER_Y + B + 0.05, -0.1) * CFrame.Angles(0, 0, math.rad(-20)),
		Color = rgb(110, 190, 60),
	})
	local glow = rgb(255, 215, 70)
	for _, side in { -1, 1 } do
		diamond(model, onEgg(side * 0.38, 0.45, 0.02), 0.45, glow)
	end
	diamond(model, onEgg(0, 0.05, 0.02), 0.25, glow)
	for i = -2, 2 do
		local y = -0.5 + math.abs(i) * 0.1
		diamond(model, onEgg(i * 0.17, y, 0.02), if i % 2 == 0 then 0.3 else 0.22, glow)
	end
	effect(egg, "Glow", rgb(255, 160, 50))
end

-- A bat egg: purple with spots, bat wings, glowing green eyes and little fangs.
function BUILDERS.MegaMonster(model: Model)
	local egg = body(model, rgb(130, 70, 200))
	for _, spot in { { 0.9, 0.9 }, { 2.4, -0.6 }, { -2.2, 0.5 }, { 3.4, 1.0 }, { -1.0, -1.2 } } do
		newPart(model, {
			Name = "Spot",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.6,
			CFrame = onEgg(spot[1], spot[2], -0.2),
			Color = rgb(95, 45, 160),
		})
	end
	for _, side in { -1, 1 } do
		-- Wings: a black flap with a scalloped edge.
		local base = CFrame.new(side * 2.1, CENTER_Y + 0.5, 0.2) * CFrame.Angles(0, 0, math.rad(side * -25))
		newPart(model, {
			Name = "Wing",
			Size = Vector3.new(1.6, 0.9, 0.12),
			CFrame = base,
			Color = rgb(30, 25, 40),
		})
		for k = -1, 1 do
			newPart(model, {
				Name = "Wing",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * 0.55,
				CFrame = base * CFrame.new(k * 0.5, -0.45, 0),
				Color = rgb(30, 25, 40),
			})
		end
		-- Pointy ears on top.
		newPart(model, {
			ClassName = "WedgePart",
			Name = "Ear",
			Size = Vector3.new(0.15, 0.6, 0.45),
			CFrame = CFrame.new(side * 0.55, CENTER_Y + B - 0.05, -0.1) * CFrame.Angles(0, math.rad(side * 90), 0),
			Color = rgb(30, 25, 40),
		})
		local eye = onEgg(side * 0.36, 0.4, 0.05)
		newPart(model, {
			Name = "Eye",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.48,
			CFrame = eye,
			Color = rgb(120, 255, 120),
			Material = Enum.Material.Neon,
		})
		newPart(model, {
			Name = "Pupil",
			Size = Vector3.new(0.08, 0.3, 0.05),
			CFrame = eye * CFrame.new(0, 0, -0.22),
			Color = rgb(10, 10, 15),
		})
		newPart(model, {
			ClassName = "WedgePart",
			Name = "Fang",
			Size = Vector3.new(0.08, 0.25, 0.16),
			CFrame = onEgg(side * 0.13, -0.25, 0.02) * CFrame.Angles(math.rad(180), 0, 0),
			Color = rgb(255, 255, 255),
		})
	end
	effect(egg, "Glow", rgb(170, 110, 255))
end

-- A haunted golden egg: black with glowing golden cracks, a gold crown and purple eyes
-- peeking out of the dark.
function BUILDERS.LegendaryMonster(model: Model)
	local egg = body(model, rgb(35, 28, 48))
	local gold = rgb(255, 200, 60)
	-- Zig-zag cracks running down the egg, front and sides.
	for _, crack in { { 0.0, 1 }, { 1.6, -1 }, { -1.7, 1 }, { 3.1, -1 } } do
		local angle = crack[1]
		for k = 0, 4 do
			local y = 1.2 - k * 0.55
			local tilt = (if k % 2 == 0 then 1 else -1) * crack[2] * 35
			newPart(model, {
				Name = "Crack",
				Size = Vector3.new(0.12, 0.65, 0.1),
				CFrame = onEgg(angle + (if k % 2 == 0 then 0.06 else -0.06), y, 0.01)
					* CFrame.Angles(0, 0, math.rad(tilt)),
				Color = gold,
				Material = Enum.Material.Neon,
			})
		end
	end
	for _, side in { -1, 1 } do
		newPart(model, {
			Name = "Eye",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.32,
			CFrame = onEgg(side * 0.3, 0.55, 0.02),
			Color = rgb(200, 120, 255),
			Material = Enum.Material.Neon,
		})
	end
	-- A golden crown with a red gem.
	local crownY = CENTER_Y + B - 0.15
	newPart(model, {
		Name = "Crown",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.35, 1.4, 1.4),
		CFrame = CFrame.new(0, crownY, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = gold,
		Material = Enum.Material.Foil,
	})
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		newPart(model, {
			Name = "Crown",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.3,
			CFrame = CFrame.new(math.sin(a) * 0.62, crownY + 0.35, -math.cos(a) * 0.62),
			Color = gold,
			Material = Enum.Material.Foil,
		})
	end
	local gem = newPart(model, {
		Name = "Gem",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 0.35,
		CFrame = CFrame.new(0, crownY, -0.7),
		Color = rgb(255, 50, 80),
		Material = Enum.Material.Neon,
	})
	effect(egg, "Glow", gold)
	effect(gem, "Sparkles", rgb(255, 230, 140))
end

function EggModel.build(eggId: string): (Model, number)
	local model = Instance.new("Model")
	model.Name = eggId .. "Egg"
	local builder = BUILDERS[eggId] or BUILDERS.Monster
	builder(model)
	return model, B * 2 + 0.6
end

return EggModel
