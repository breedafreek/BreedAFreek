-- Reusable scenery pieces built from parts: trees, bushes, flowers, lamp posts, picket
-- fences and signboards. Every builder takes a parent and a CFrame on the ground.

local Decor = {}

local function part(props, className: string?): BasePart
	local p = Instance.new(className or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		p[key] = value
	end
	return p
end
Decor.part = part

local LEAF_COLORS = {
	Color3.fromRGB(70, 160, 70),
	Color3.fromRGB(90, 180, 80),
	Color3.fromRGB(60, 140, 75),
}

-- A round cartoon tree. scale 1 is about 14 studs tall.
function Decor.tree(parent: Instance, ground: CFrame, scale: number?, seed: number?)
	local s = scale or 1
	local rng = Random.new(seed or 1)
	part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(7 * s, 1.6 * s, 1.6 * s),
		CFrame = ground * CFrame.new(0, 3.5 * s, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(120, 85, 55),
		Material = Enum.Material.Wood,
		Parent = parent,
	})
	for i = 1, 3 do
		local size = (5.5 + rng:NextNumber() * 2) * s
		local offset =
			Vector3.new((rng:NextNumber() - 0.5) * 3 * s, (7.5 + i * 1.6) * s, (rng:NextNumber() - 0.5) * 3 * s)
		part({
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * size,
			CFrame = ground * CFrame.new(offset),
			Color = LEAF_COLORS[rng:NextInteger(1, #LEAF_COLORS)],
			Material = Enum.Material.Grass,
			CanCollide = false,
			Parent = parent,
		})
	end
end

function Decor.bush(parent: Instance, ground: CFrame, scale: number?, seed: number?)
	local s = scale or 1
	local rng = Random.new(seed or 2)
	for _ = 1, 3 do
		local size = (2.2 + rng:NextNumber() * 1.2) * s
		part({
			Name = "Bush",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * size,
			CFrame = ground
				* CFrame.new((rng:NextNumber() - 0.5) * 2.5 * s, size * 0.35, (rng:NextNumber() - 0.5) * 1.5 * s),
			Color = LEAF_COLORS[rng:NextInteger(1, #LEAF_COLORS)],
			Material = Enum.Material.Grass,
			CanCollide = false,
			Parent = parent,
		})
	end
end

local FLOWER_COLORS = {
	Color3.fromRGB(255, 110, 150),
	Color3.fromRGB(255, 220, 80),
	Color3.fromRGB(170, 120, 255),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(255, 150, 60),
}

-- A rectangular flower bed (width along X, depth along Z).
function Decor.flowerBed(parent: Instance, ground: CFrame, width: number, depth: number, seed: number?)
	local rng = Random.new(seed or 3)
	part({
		Name = "FlowerBed",
		Size = Vector3.new(width, 0.4, depth),
		CFrame = ground * CFrame.new(0, 0.2, 0),
		Color = Color3.fromRGB(110, 75, 50),
		Material = Enum.Material.Ground,
		CanCollide = false,
		Parent = parent,
	})
	local count = math.floor(width * depth / 2.5)
	for _ = 1, count do
		local x = (rng:NextNumber() - 0.5) * (width - 0.8)
		local z = (rng:NextNumber() - 0.5) * (depth - 0.8)
		part({
			Name = "Stem",
			Size = Vector3.new(0.15, 0.8, 0.15),
			CFrame = ground * CFrame.new(x, 0.8, z),
			Color = Color3.fromRGB(70, 150, 60),
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
		part({
			Name = "Flower",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.55,
			CFrame = ground * CFrame.new(x, 1.25, z),
			Color = FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)],
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
	end
end

-- A lamp post with a warm light that glows at night and adds sparkle by day.
function Decor.lamp(parent: Instance, ground: CFrame, color: Color3?)
	part({
		Name = "LampPost",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(8, 0.5, 0.5),
		CFrame = ground * CFrame.new(0, 4, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(45, 45, 55),
		Material = Enum.Material.Metal,
		Parent = parent,
	})
	part({
		Name = "LampBase",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 1.4, 1.4),
		CFrame = ground * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(45, 45, 55),
		Material = Enum.Material.Metal,
		Parent = parent,
	})
	local bulb = part({
		Name = "Bulb",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 1.3,
		CFrame = ground * CFrame.new(0, 8.4, 0),
		Color = color or Color3.fromRGB(255, 225, 160),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = parent,
	})
	local light = Instance.new("PointLight")
	light.Color = color or Color3.fromRGB(255, 210, 150)
	light.Range = 18
	light.Brightness = 1.2
	light.Shadows = false
	light.Parent = bulb
end

-- A white picket fence from a to b (both on the ground). Pickets every `spacing` studs.
function Decor.picketFence(parent: Instance, a: Vector3, b: Vector3, height: number, color: Color3?)
	local white = color or Color3.fromRGB(245, 242, 235)
	local length = (b - a).Magnitude
	if length < 0.5 then
		return
	end
	local along = CFrame.lookAt(a, b) -- -Z points from a to b
	for _, y in { height * 0.35, height * 0.75 } do
		part({
			Name = "Rail",
			Size = Vector3.new(0.3, 0.35, length),
			CFrame = along * CFrame.new(0, y, -length / 2),
			Color = white,
			Material = Enum.Material.WoodPlanks,
			Parent = parent,
		})
	end
	local spacing = 1.6
	local count = math.max(1, math.floor(length / spacing))
	for i = 0, count do
		local z = -math.min(length, i * length / count)
		part({
			Name = "Picket",
			Size = Vector3.new(0.25, height, 0.7),
			CFrame = along * CFrame.new(0, height / 2, z),
			Color = white,
			Material = Enum.Material.WoodPlanks,
			Parent = parent,
		})
		-- A small block turned 45 degrees gives each picket a pointed top.
		local tip = part({
			Name = "PicketTip",
			Size = Vector3.new(0.25, 0.5, 0.5),
			CFrame = along * CFrame.new(0, height, z) * CFrame.Angles(math.rad(45), 0, 0),
			Color = white,
			Material = Enum.Material.WoodPlanks,
			Parent = parent,
		})
		tip.CanCollide = false
	end
end

-- A wooden signboard with text on both faces. Returns the front TextLabel (and back).
function Decor.signboard(parent: Instance, cframe: CFrame, size: Vector2, text: string, accent: Color3)
	local board = part({
		Name = "Signboard",
		Size = Vector3.new(size.X, size.Y, 0.5),
		CFrame = cframe,
		Color = Color3.fromRGB(140, 95, 60),
		Material = Enum.Material.WoodPlanks,
		Parent = parent,
	})
	part({
		Name = "SignTrim",
		Size = Vector3.new(size.X + 0.6, size.Y + 0.6, 0.35),
		CFrame = cframe,
		Color = accent,
		Parent = parent,
	})
	local labels = {}
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0.3
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.Text = text
		label.TextColor3 = Color3.fromRGB(255, 250, 235)
		label.TextStrokeTransparency = 0.4
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0.04, 0)
		padding.PaddingRight = UDim.new(0.04, 0)
		padding.PaddingTop = UDim.new(0.12, 0)
		padding.PaddingBottom = UDim.new(0.12, 0)
		padding.Parent = label
		label.Parent = gui
		gui.Parent = board
		table.insert(labels, label)
	end
	return labels
end

return Decor
