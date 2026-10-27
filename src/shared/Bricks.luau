-- Small helpers for building models out of parts (blocks, balls, cylinders, cones, wedges),
-- shared by the yard item and plant models. Every function takes the model to add to, the
-- size, where it goes and its colour (and optionally a material), and returns the part.

local Bricks = {}

function Bricks.rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

function Bricks.block(model: Instance, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if p.Material == Enum.Material.Glass then
		p.Transparency = 0.3
	end
	p.Parent = model
	return p
end

function Bricks.ball(model: Instance, size: Vector3 | number, cframe: CFrame, color: Color3, material: Enum.Material?)
	local vector = if typeof(size) == "number" then Vector3.one * size else size
	local p = Bricks.block(model, vector, cframe, color, material)
	if vector.X == vector.Y and vector.Y == vector.Z then
		p.Shape = Enum.PartType.Ball
	else
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	return p
end

-- A cylinder standing up with its base on `cframe`.
function Bricks.post(model: Instance, height: number, diameter: number, cframe: CFrame, color: Color3, material)
	local p = Bricks.block(
		model,
		Vector3.new(height, diameter, diameter),
		cframe * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.pi / 2),
		color,
		material
	)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- A cylinder lying along the cframe's X axis, centred on it.
function Bricks.rod(model: Instance, length: number, diameter: number, cframe: CFrame, color: Color3, material)
	local p = Bricks.block(model, Vector3.new(length, diameter, diameter), cframe, color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- A cone of stacked discs standing on `cframe`.
function Bricks.cone(
	model: Instance,
	height: number,
	diameter: number,
	cframe: CFrame,
	color: Color3,
	material,
	steps: number?
)
	local n = steps or 5
	for i = 0, n - 1 do
		Bricks.post(
			model,
			height / n + 0.02,
			diameter * (1 - i / n),
			cframe * CFrame.new(0, i * height / n, 0),
			color,
			material
		)
	end
end

function Bricks.wedge(model: Instance, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?)
	local p = Instance.new("WedgePart")
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = model
	return p
end

Bricks.RAINBOW = {
	Color3.fromRGB(255, 70, 90),
	Color3.fromRGB(255, 150, 40),
	Color3.fromRGB(255, 225, 50),
	Color3.fromRGB(80, 220, 100),
	Color3.fromRGB(60, 170, 255),
	Color3.fromRGB(150, 90, 255),
}

return Bricks
