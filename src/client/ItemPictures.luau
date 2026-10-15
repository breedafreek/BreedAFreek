-- 3D pictures for shop items (barn slots, weapons, game passes), built from parts like
-- everything else in the game and shown in ViewportFrames on the item cards.
-- ItemPictures.view(key, height) returns a ViewportFrame; keys are "BarnSlot", a weapon
-- id from Weapons.luau, or a game pass key from GamePasses.luau.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FreekModel = require(ReplicatedStorage.Shared.FreekModel)
local WeaponModel = require(ReplicatedStorage.Shared.WeaponModel)
local Weapons = require(ReplicatedStorage.Shared.Weapons)

local ItemPictures = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local GOLD = rgb(255, 200, 55)

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

-- A ball, or a squashed ball (a sphere mesh) when the size isn't the same every way.
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

local function cylinder(model, cframe: CFrame, height: number, diameter: number, color: Color3, material)
	return part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = cframe * CFrame.Angles(0, 0, math.pi / 2), -- upright
		Color = color,
		Material = material,
	})
end

-- A thick arc of blocks (handles, shackles).
local function arc(model, center: CFrame, radius: number, from: number, to: number, thickness: number, color: Color3)
	local last
	for i = 0, 10 do
		local a = from + (to - from) * i / 10
		local point = (center * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0)).Position
		if last then
			part(model, {
				Size = Vector3.new(thickness, thickness, (point - last).Magnitude + thickness * 0.6),
				CFrame = CFrame.lookAt((point + last) / 2, point),
				Color = color,
				Material = Enum.Material.Metal,
			})
		end
		last = point
	end
end

-- A big green "+" sign.
local function plus(model, position: Vector3, size: number)
	local green = rgb(80, 220, 100)
	part(model, { Size = Vector3.new(size, size * 0.32, size * 0.32), CFrame = CFrame.new(position), Color = green })
	part(model, { Size = Vector3.new(size * 0.32, size, size * 0.32), CFrame = CFrame.new(position), Color = green })
end

-- A glowing pad like the ones in the barn, with a Freek standing on it.
local function padWithFreek(model, species: string)
	cylinder(model, CFrame.new(0, 0.3, 0), 0.6, 5, rgb(70, 70, 85))
	cylinder(model, CFrame.new(0, 0.62, 0), 0.06, 4.4, rgb(90, 230, 255), Enum.Material.Neon)
	local freek, height = FreekModel.build(species)
	freek:PivotTo(CFrame.new(0, 0.65, 0))
	for _, p in freek:GetDescendants() do
		if p:IsA("BasePart") then
			p.Parent = model
		end
	end
	freek:Destroy()
	return height
end

local BUILDERS = {}

-- An extra barn slot: a pad with a Freek on it and a big plus.
function BUILDERS.BarnSlot(model)
	local height = padWithFreek(model, "Oinkle")
	plus(model, Vector3.new(-2.6, height + 0.8, 0), 1.8)
end
BUILDERS.ExtraSlot1 = BUILDERS.BarnSlot
BUILDERS.ExtraSlot2 = BUILDERS.BarnSlot
BUILDERS.ExtraSlot3 = BUILDERS.BarnSlot

-- 2x Coins: a pile of gold coins and a green cash stack.
function BUILDERS.DoubleCoins(model)
	for i = 0, 2 do
		part(model, {
			Size = Vector3.new(3.4, 0.6, 1.8),
			CFrame = CFrame.new(0.4, 0.3 + i * 0.62, 0.6) * CFrame.Angles(0, math.rad(i * 7), 0),
			Color = rgb(90, 200, 90),
		})
		part(model, {
			Size = Vector3.new(0.6, 0.66, 1.86),
			CFrame = CFrame.new(0.4, 0.3 + i * 0.62, 0.6) * CFrame.Angles(0, math.rad(i * 7), 0),
			Color = rgb(255, 240, 200),
		})
	end
	for i, spot in
		{
			Vector3.new(-1.4, 0.2, -0.6),
			Vector3.new(-1.4, 0.55, -0.6),
			Vector3.new(-1.4, 0.9, -0.6),
			Vector3.new(-0.3, 0.2, -1.2),
		}
	do
		cylinder(model, CFrame.new(spot) * CFrame.Angles(0, i, 0), 0.32, 1.7, GOLD, Enum.Material.Foil)
	end
	-- One big coin standing up in front.
	part(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 2.4, 2.4),
		CFrame = CFrame.new(-0.6, 1.6, -1.6) * CFrame.Angles(0, math.rad(80), 0),
		Color = GOLD,
		Material = Enum.Material.Foil,
	})
end

-- Fast Fusing: a pink potion with a lightning bolt.
function BUILDERS.FastBreeding(model)
	ball(model, Vector3.new(0, 1.8, 0), 3.4, rgb(200, 235, 255), Enum.Material.Glass).Transparency = 0.6
	ball(model, Vector3.new(0, 1.55, 0), Vector3.new(2.9, 2.4, 2.9), rgb(255, 60, 170), Enum.Material.Neon)
	cylinder(model, CFrame.new(0, 3.8, 0), 1.4, 1.1, rgb(200, 235, 255), Enum.Material.Glass).Transparency = 0.4
	cylinder(model, CFrame.new(0, 4.6, 0), 0.7, 1.3, rgb(150, 95, 50))
	-- A zig-zag bolt beside it.
	local yellow = rgb(255, 220, 40)
	for _, bit in { { 2.3, 3.6, -30 }, { 2.0, 2.4, 35 }, { 2.4, 1.2, -30 } } do
		part(model, {
			Size = Vector3.new(0.7, 1.6, 0.5),
			CFrame = CFrame.new(bit[1], bit[2], -0.6) * CFrame.Angles(0, 0, math.rad(bit[3])),
			Color = yellow,
			Material = Enum.Material.Neon,
		})
	end
end

-- Longer Gate Lock: a big gold padlock.
function BUILDERS.LongerLock(model)
	part(model, {
		Size = Vector3.new(3.2, 2.6, 1.2),
		CFrame = CFrame.new(0, 1.3, 0),
		Color = GOLD,
		Material = Enum.Material.Foil,
	})
	arc(model, CFrame.new(0, 2.6, 0), 1.1, 0, math.pi, 0.45, rgb(170, 170, 180))
	ball(model, Vector3.new(0, 1.5, -0.6), 0.6, rgb(60, 45, 30))
	part(model, { Size = Vector3.new(0.3, 0.8, 0.2), CFrame = CFrame.new(0, 1.05, -0.62), Color = rgb(60, 45, 30) })
end

-- VIP: a gold crown with gems.
function BUILDERS.VIP(model)
	cylinder(model, CFrame.new(0, 0.8, 0), 1.6, 3.6, GOLD, Enum.Material.Foil)
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		local spot = Vector3.new(math.sin(a) * 1.5, 2.2, -math.cos(a) * 1.5)
		part(model, {
			Size = Vector3.new(0.9, 1.6, 0.9),
			CFrame = CFrame.new(spot) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.rad(45)),
			Color = GOLD,
			Material = Enum.Material.Foil,
		})
		ball(model, spot + Vector3.new(0, 1.1, 0), 0.55, GOLD, Enum.Material.Foil)
	end
	for k, color in { rgb(255, 50, 80), rgb(80, 160, 255), rgb(90, 220, 110) } do
		local a = (k - 2) * 0.7
		ball(model, Vector3.new(math.sin(a) * 1.8, 0.8, -math.cos(a) * 1.8), 0.7, color, Enum.Material.Neon)
	end
end

-- Extra Fusion Den: two hay bales and a pink heart.
function BUILDERS.ExtraPen(model)
	for _, x in { -1.4, 1.4 } do
		part(model, {
			Size = Vector3.new(2.4, 1.5, 1.6),
			CFrame = CFrame.new(x, 0.75, 0),
			Color = rgb(225, 190, 95),
			Material = Enum.Material.Sand,
		})
		part(model, { Size = Vector3.new(0.2, 1.55, 1.65), CFrame = CFrame.new(x, 0.75, 0), Color = rgb(140, 100, 55) })
	end
	local pink = rgb(255, 90, 170)
	ball(model, Vector3.new(-0.45, 3, 0), 1.2, pink, Enum.Material.Neon)
	ball(model, Vector3.new(0.45, 3, 0), 1.2, pink, Enum.Material.Neon)
	part(model, {
		Size = Vector3.new(1.25, 1.25, 1),
		CFrame = CFrame.new(0, 2.5, 0) * CFrame.Angles(0, 0, math.rad(45)),
		Color = pink,
		Material = Enum.Material.Neon,
	})
end

-- A weapon, laid on its side so the whole thing shows.
local function weaponModel(model, weaponId: string)
	local tool = WeaponModel.build(weaponId)
	local melee = Weapons.list[weaponId].kind == "melee"
	for _, p in tool:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			-- Melee weapons extend along +Z, guns point along -Z: turn them to lie across.
			p.CFrame = CFrame.Angles(
				0,
				if melee then math.rad(90) else math.rad(-90),
				if melee then math.rad(35) else 0
			) * p.CFrame
			p.Parent = model
		end
	end
	tool:Destroy()
end

-- The box round everything you can see (counting stretched sphere meshes).
local function visibleBounds(model: Model): (Vector3, Vector3)
	local lo, hi
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			local size = p.Size
			local mesh = p:FindFirstChildOfClass("SpecialMesh")
			if mesh then
				size *= mesh.Scale
			end
			for _, x in { -0.5, 0.5 } do
				for _, y in { -0.5, 0.5 } do
					for _, z in { -0.5, 0.5 } do
						local point = p.CFrame:PointToWorldSpace(size * Vector3.new(x, y, z))
						lo = if lo then lo:Min(point) else point
						hi = if hi then hi:Max(point) else point
					end
				end
			end
		end
	end
	return lo or Vector3.zero, hi or Vector3.zero
end

function ItemPictures.has(key: string): boolean
	return BUILDERS[key] ~= nil or Weapons.list[key] ~= nil
end

-- A ViewportFrame showing the item, framed to fit, seen a little from above and the side.
function ItemPictures.view(key: string, height: number?): ViewportFrame
	local frame = Instance.new("ViewportFrame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, height or 90)
	frame.Ambient = Color3.fromRGB(190, 190, 190)
	frame.LightColor = Color3.fromRGB(255, 250, 240)
	frame.LightDirection = Vector3.new(-1, -1.4, 1)

	local model = Instance.new("Model")
	if Weapons.list[key] then
		weaponModel(model, key)
	elseif BUILDERS[key] then
		BUILDERS[key](model)
	end
	model.Parent = frame

	local lo, hi = visibleBounds(model)
	local center = (lo + hi) / 2
	local extent = hi - lo
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	-- The picture strip is about twice as wide as it is tall, so wide items can use the
	-- width (the field of view is vertical).
	local aspect = 2
	local wide = math.max(extent.X, extent.Z) * 0.85
	local fit = math.max(extent.Y, wide / aspect) / 2 * 1.08
	local distance = fit / math.tan(math.rad(15)) + extent.Z / 2
	local direction = Vector3.new(0.45, 0.4, -1).Unit
	camera.CFrame = CFrame.lookAt(center + direction * distance, center)
	camera.Parent = frame
	frame.CurrentCamera = camera
	return frame
end

return ItemPictures
