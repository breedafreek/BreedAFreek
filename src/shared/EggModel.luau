-- The eggs you steal from the zones. Each zone's egg has its own colours (Items.ZONES:
-- eggColor with spotColor spots); deeper zones' eggs get fancier: a gold band from zone 5, a
-- crown from zone 9. EggModel.build(zoneIndex) returns the model (standing on its pivot,
-- PrimaryPart = the shell) and its height.

local Items = require(script.Parent.Items)

local EggModel = {}

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

function EggModel.build(zoneIndex: number): (Model, number)
	local zone = Items.ZONES[zoneIndex] or Items.ZONES[1]
	local model = Instance.new("Model")
	model.Name = "Egg"
	model:SetAttribute("Zone", zoneIndex)
	local w, h = 2.6, 3.4
	local shell = egg(model, Vector3.new(w, h, w), CFrame.new(0, h / 2, 0), zone.eggColor)
	shell.Name = "Shell"
	-- The model's pivot is the bottom of the egg, so it stands on whatever it's put on.
	shell.PivotOffset = CFrame.new(0, -h / 2, 0)
	model.PrimaryPart = shell
	-- Spots all over, squashed onto the shell.
	local rng = Random.new(zoneIndex * 97)
	for _ = 1, 11 do
		local a = rng:NextNumber() * math.pi * 2
		local y = rng:NextNumber(-0.75, 0.75)
		local r = math.sqrt(1 - y * y)
		local normal = Vector3.new(math.cos(a) * r, y * 1.25, math.sin(a) * r).Unit
		local spot = Vector3.new(math.cos(a) * r * w / 2, h / 2 + y * h / 2, math.sin(a) * r * w / 2)
		local size = rng:NextNumber(0.55, 0.9)
		egg(
			model,
			Vector3.new(size, size, 0.25),
			CFrame.lookAt(spot, spot + normal) * CFrame.new(0, 0, -0.02),
			zone.spotColor
		)
	end
	if zoneIndex >= 5 then
		-- A shiny band round the middle.
		local band = part(model, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.35, w * 1.02, w * 1.02),
			CFrame = CFrame.new(0, h * 0.48, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Color = Color3.fromRGB(255, 205, 60),
			Material = Enum.Material.Foil,
		})
		band.Name = "Band"
	end
	local top = h
	if zoneIndex >= 9 then
		-- A little gold crown with gems.
		local crownY = h - 0.15
		part(model, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.5, 1.3, 1.3),
			CFrame = CFrame.new(0, crownY + 0.25, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Color = Color3.fromRGB(255, 205, 60),
			Material = Enum.Material.Foil,
		})
		for k = 0, 4 do
			local a = k / 5 * math.pi * 2
			part(model, {
				Size = Vector3.new(0.3, 0.6, 0.3),
				CFrame = CFrame.new(math.sin(a) * 0.55, crownY + 0.75, math.cos(a) * 0.55),
				Color = Color3.fromRGB(255, 205, 60),
				Material = Enum.Material.Foil,
			})
		end
		part(model, {
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.35,
			CFrame = CFrame.new(0, crownY + 0.3, -0.62),
			Color = Color3.fromRGB(255, 60, 100),
			Material = Enum.Material.Neon,
		})
		top = crownY + 1.1
	end
	return model, top
end

return EggModel
