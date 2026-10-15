-- Chunky 3D icons for the menu buttons and window titles, built from parts and shown in
-- ViewportFrames (like the rendered icons in the big simulators). Icons.build(name)
-- returns a Model; UI.modelIcon frames it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EggModel = require(ReplicatedStorage.Shared.EggModel)
local FreekModel = require(ReplicatedStorage.Shared.FreekModel)

local Icons = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function part(model: Model, props)
	local p = Instance.new(props.ClassName or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		if key ~= "ClassName" then
			p[key] = value
		end
	end
	p.Parent = model
	return p
end

-- A ball, or a squashed ball (an ellipsoid, made with a sphere mesh) when the size isn't
-- the same every way.
local function ball(model, position: Vector3, size: Vector3 | number, color: Color3, material: Enum.Material?)
	local vector = if typeof(size) == "number" then Vector3.one * size else size
	local round = vector.X == vector.Y and vector.Y == vector.Z
	local p = part(model, {
		Shape = if round then Enum.PartType.Ball else Enum.PartType.Block,
		Size = vector,
		CFrame = CFrame.new(position),
		Color = color,
		Material = material,
	})
	if not round then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	return p
end

-- A thick arc of blocks around the Z axis (for handles and swirls).
local function arc(
	model,
	center: CFrame,
	radius: number,
	from: number,
	to: number,
	thickness: number,
	color: Color3,
	steps: number?
)
	local n = steps or 10
	local last
	for i = 0, n do
		local a = from + (to - from) * i / n
		local point = (center * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0)).Position
		if last then
			part(model, {
				Size = Vector3.new(thickness, thickness, (point - last).Magnitude + thickness * 0.6),
				CFrame = CFrame.lookAt((point + last) / 2, point),
				Color = color,
			})
		end
		last = point
	end
	return last
end

local BUILDERS = {}

-- A red shopping basket with a handle.
function BUILDERS.Shop(model)
	local red, dark = rgb(235, 55, 55), rgb(170, 30, 35)
	part(model, { Size = Vector3.new(4.4, 2.6, 3), CFrame = CFrame.new(0, 0, 0), Color = red })
	part(model, { Size = Vector3.new(4.9, 0.6, 3.4), CFrame = CFrame.new(0, 1.4, 0), Color = rgb(255, 120, 110) })
	for _, x in { -1.4, 0, 1.4 } do
		part(model, { Size = Vector3.new(0.35, 1.8, 0.2), CFrame = CFrame.new(x, -0.1, -1.55), Color = dark })
	end
	arc(model, CFrame.new(0, 1.6, 0), 1.9, 0, math.pi, 0.45, rgb(90, 90, 100), 10)
end

-- A pumpkin Monster Egg.
function BUILDERS.Eggs(model)
	local egg = EggModel.build("Monster")
	for _, p in egg:GetChildren() do
		p.Parent = model
	end
	egg:Destroy()
end

-- Oinkle, the first Freek.
function BUILDERS.Freeks(model)
	local freek = FreekModel.build("Oinkle")
	for _, p in freek:GetDescendants() do
		if p:IsA("BasePart") then
			p.Parent = model
		end
	end
	freek:Destroy()
end

-- A round potion flask with bubbling pink liquid.
function BUILDERS.Fuse(model)
	ball(model, Vector3.new(0, 0, 0), 3.6, rgb(200, 235, 255), Enum.Material.Glass).Transparency = 0.65
	ball(model, Vector3.new(0, -0.25, 0), Vector3.new(3.1, 2.6, 3.1), rgb(255, 40, 160), Enum.Material.Neon)
	part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.6, 1.2, 1.2),
		CFrame = CFrame.new(0, 2.1, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = rgb(200, 235, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.35,
	})
	part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.8, 1.35, 1.35),
		CFrame = CFrame.new(0, 3.05, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = rgb(150, 95, 50),
	})
	for _, b in { { -0.6, 1.4, 0.5 }, { 0.5, 1.9, 0.4 }, { 0.1, 2.7, 0.3 } } do
		ball(model, Vector3.new(b[1], b[2], -0.6), b[3], rgb(255, 170, 230), Enum.Material.Neon)
	end
end

-- The Freek Book: a chunky blue book with gold corners and a star.
function BUILDERS.Book(model)
	local tilt = CFrame.Angles(0, math.rad(-20), math.rad(8))
	local function piece(size, offset, color, material)
		part(model, { Size = size, CFrame = tilt * CFrame.new(offset), Color = color, Material = material })
	end
	piece(Vector3.new(3.4, 4.2, 1.1), Vector3.new(0, 0, 0), rgb(60, 120, 235))
	piece(Vector3.new(3.1, 3.9, 0.9), Vector3.new(0.25, 0, 0), rgb(255, 245, 220))
	piece(Vector3.new(0.5, 4.3, 1.2), Vector3.new(-1.6, 0, 0), rgb(40, 85, 190))
	for _, y in { -1.9, 1.9 } do
		piece(Vector3.new(0.7, 0.6, 1.25), Vector3.new(1.5, y, 0), rgb(255, 200, 60), Enum.Material.Foil)
	end
	part(model, {
		Size = Vector3.new(1.3, 1.3, 0.3),
		CFrame = tilt * CFrame.new(0.1, 0.2, -0.6) * CFrame.Angles(0, 0, math.rad(45)),
		Color = rgb(255, 210, 60),
		Material = Enum.Material.Neon,
	})
end

-- A flat triangular arrowhead: its base centred on `base`, pointing along `direction`,
-- `width` across (along `across`) and `length` long, `thickness` deep.
local function arrowHead(
	model,
	base: Vector3,
	direction: Vector3,
	across: Vector3,
	length: number,
	width: number,
	thickness: number,
	color: Color3
)
	for _, side in { 1, -1 } do
		local w = across * side
		-- A wedge's right angle sits at its bottom back edge: put that on the base centre,
		-- run its height along the arrow and its depth out to the side.
		local right = direction:Cross(-w)
		local center = base + direction * (length / 2) + w * (width / 4)
		part(model, {
			ClassName = "WedgePart",
			Size = Vector3.new(thickness, length, width / 2),
			CFrame = CFrame.fromMatrix(center, right, direction),
			Color = color,
		})
	end
end

-- Two fat arrows passing each other.
function BUILDERS.Trade(model)
	local function arrow(y: number, direction: number, color: Color3)
		part(model, {
			Size = Vector3.new(2.6, 1, 0.9),
			CFrame = CFrame.new(-direction * 0.7, y, 0),
			Color = color,
		})
		arrowHead(
			model,
			Vector3.new(direction * 0.55, y, 0),
			Vector3.new(direction, 0, 0),
			Vector3.yAxis,
			1.6,
			2.4,
			0.9,
			color
		)
	end
	arrow(0.85, 1, rgb(80, 210, 100))
	arrow(-0.85, -1, rgb(255, 160, 50))
end

-- Two curved arrows chasing each other round a circle (pink and blue).
function BUILDERS.Rebirth(model)
	for k, color in { rgb(255, 90, 170), rgb(80, 170, 255) } do
		local start = (k - 1) * math.pi + 0.5
		local stop = start + math.pi - 1.1
		local tip = arc(model, CFrame.new(), 1.9, start, stop, 0.85, color, 8)
		local direction = Vector3.new(-math.sin(stop), math.cos(stop), 0)
		local outward = Vector3.new(math.cos(stop), math.sin(stop), 0)
		arrowHead(model, tip, direction, outward, 1.3, 2.2, 0.85, color)
	end
	ball(model, Vector3.zero, 1.1, rgb(255, 220, 80), Enum.Material.Neon)
end

-- A lucky four-leaf clover (game passes).
function BUILDERS.Store(model)
	local green, dark = rgb(90, 210, 80), rgb(50, 150, 55)
	for k = 0, 3 do
		local angle = k * math.pi / 2 + math.pi / 4
		local out = Vector3.new(math.cos(angle), math.sin(angle), 0)
		local side = Vector3.new(-out.Y, out.X, 0)
		-- Each leaf is a heart: two round lobes and a point toward the middle.
		for _, s in { 1, -1 } do
			ball(model, out * 1.45 + side * s * 0.55, Vector3.new(1.55, 1.55, 0.7), green)
		end
		ball(model, out * 0.75, Vector3.new(1.2, 1.2, 0.7), green)
		part(model, {
			Size = Vector3.new(0.15, 1.7, 0.75),
			CFrame = CFrame.lookAt(out * 1.05, out * 1.05 + Vector3.new(0, 0, -1), out),
			Color = dark,
		})
	end
	ball(model, Vector3.zero, Vector3.new(0.9, 0.9, 0.8), dark)
	part(model, {
		Size = Vector3.new(0.4, 2.2, 0.4),
		CFrame = CFrame.new(0.5, -1.6, 0) * CFrame.Angles(0, 0, math.rad(-20)),
		Color = dark,
	})
end

-- A stack of cash with gold coins.
function BUILDERS.Money(model)
	for i = 0, 2 do
		part(model, {
			Size = Vector3.new(3.4, 0.6, 1.8),
			CFrame = CFrame.new(-0.2 + i * 0.15, i * 0.62, 0) * CFrame.Angles(0, math.rad(i * 6), 0),
			Color = rgb(90, 200, 90),
		})
		part(model, {
			Size = Vector3.new(0.6, 0.66, 1.86),
			CFrame = CFrame.new(-0.2 + i * 0.15, i * 0.62, 0) * CFrame.Angles(0, math.rad(i * 6), 0),
			Color = rgb(255, 240, 200),
		})
	end
	for i, offset in { Vector3.new(1.7, -0.1, -0.9), Vector3.new(2.1, 0.35, -0.5) } do
		part(model, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.35, 1.5, 1.5),
			CFrame = CFrame.new(offset) * CFrame.Angles(math.rad(70), 0, math.rad(90 + i * 10)),
			Color = rgb(255, 205, 50),
			Material = Enum.Material.Foil,
		})
	end
end

BUILDERS.Luck = BUILDERS.Eggs

function Icons.build(name: string): Model
	local model = Instance.new("Model")
	model.Name = name .. "Icon"
	local builder = BUILDERS[name]
	if builder then
		builder(model)
	end
	local first = model:FindFirstChildWhichIsA("BasePart")
	if first then
		model.PrimaryPart = first
	end
	return model
end

return Icons
