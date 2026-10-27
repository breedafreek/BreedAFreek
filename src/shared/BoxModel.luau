-- Mystery Box models: a chunky gift box in the box's colour with a ribbon, a big bow and
-- glowing question marks on its sides. BoxModel.build(crateId) returns the model (standing
-- on its pivot, PrimaryPart = the box) and its height.

local Luck = require(script.Parent.Luck)

local BoxModel = {}

local function part(model: Model, props)
	local p = Instance.new(props.ClassName or "Part")
	p.Anchored = true
	p.CanCollide = false
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

-- A chunky "?" made of blocks on a face, `cf` at the face's centre looking out of it.
local function questionMark(model: Model, cf: CFrame, s: number, color: Color3)
	local bits = {
		{ -0.35, 0.55, 0.3, 0.6 },
		{ 0, 0.8, 0.9, 0.3 },
		{ 0.35, 0.5, 0.3, 0.7 },
		{ 0.15, 0.15, 0.55, 0.3 },
		{ 0, -0.1, 0.3, 0.4 },
		{ 0, -0.7, 0.34, 0.34 },
	}
	for _, b in bits do
		part(model, {
			Size = Vector3.new(b[3] * s, b[4] * s, 0.15),
			CFrame = cf * CFrame.new(b[1] * s, b[2] * s, -0.05),
			Color = color,
			Material = Enum.Material.Neon,
		})
	end
end

function BoxModel.build(crateId: string): (Model, number)
	local crate = Luck.crateById[crateId] or Luck.CRATES[1]
	local tier = table.find(Luck.CRATES, crate) or 1
	local size = 3.2 + tier * 0.4
	local model = Instance.new("Model")
	model.Name = crate.id .. "Box"
	local color = crate.color
	local ribbon = if tier == 3 then Color3.fromRGB(230, 40, 70) else Color3.fromRGB(255, 255, 255)

	local box = part(model, {
		Name = "Box",
		Size = Vector3.new(size, size * 0.85, size),
		CFrame = CFrame.new(0, size * 0.425, 0),
		Color = color,
	})
	-- The model's pivot is the bottom of the box, so it stands on whatever it's put on.
	box.PivotOffset = CFrame.new(0, -size * 0.425, 0)
	model.PrimaryPart = box
	-- The lid, a bit wider.
	part(model, {
		Name = "Lid",
		Size = Vector3.new(size * 1.08, size * 0.22, size * 1.08),
		CFrame = CFrame.new(0, size * 0.85 + size * 0.1, 0),
		Color = color:Lerp(Color3.new(1, 1, 1), 0.12),
	})
	-- Ribbons round both ways.
	for _, rotation in { 0, math.pi / 2 } do
		part(model, {
			Size = Vector3.new(size * 0.22, size * 1.07, size * 1.1),
			CFrame = CFrame.new(0, size * 0.53, 0) * CFrame.Angles(0, rotation, 0),
			Color = ribbon,
		})
	end
	-- A bow: two loops and a knot.
	local top = size * 0.96 + size * 0.1
	for _, side in { -1, 1 } do
		local loop = part(model, {
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * size * 0.42,
			CFrame = CFrame.new(side * size * 0.22, top + size * 0.12, 0),
			Color = ribbon,
		})
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = Vector3.new(1.2, 0.8, 0.6)
		mesh.Parent = loop
	end
	part(model, {
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * size * 0.24,
		CFrame = CFrame.new(0, top + size * 0.1, 0),
		Color = ribbon:Lerp(Color3.new(0, 0, 0), 0.1),
	})
	-- Glowing "?" on the four sides, in the quarters beside the ribbon.
	local mark = Color3.fromRGB(255, 255, 220)
	for k = 0, 3 do
		local face = CFrame.Angles(0, k * math.pi / 2, 0) * CFrame.new(size * 0.28, size * 0.42, -size / 2)
		questionMark(model, face, size * 0.3, mark)
	end
	if tier == 3 then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.fromRGB(255, 230, 120)
		sparkles.Parent = box
	end
	return model, top + size * 0.35
end

return BoxModel
