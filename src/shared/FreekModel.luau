-- Builds the 3D model for a Freek out of plain parts.
-- The model's pivot sits at its feet and its face points along -Z (the model's front),
-- so model:PivotTo(groundCFrame) stands it on the ground facing groundCFrame.LookVector.
--
-- A Freek's look is either:
--   * a part list (look.parts, look.effects), for designed Freeks; see buildFromParts, or
--   * the simple generator (look.shape/size/eyes/antennae), for placeholders.
-- A Model in ReplicatedStorage.FreekModels named after the species id overrides both.
--
-- Part list format, in studs, with y = 0 at the ground and the face toward -Z:
--   { shape = "Ball" | "Block" | "Cylinder" | "Wedge", size = { x, y, z } (or one number),
--     pos = { x, y, z }, rot = { x, y, z } (degrees, optional), color = Color3,
--     material = "Neon" etc. (optional), transparency = 0-1 (optional),
--     detail = true (optional: keeps its color when mutated, e.g. eyes) }
-- The first part is the main body. Effects:
--   { type = "Sparkles" | "Fire" | "Smoke" | "Glow", part = index (default 1), color = Color3,
--     size = number (optional) }

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Freeks = require(script.Parent.Freeks)
local Mutations = require(script.Parent.Mutations)

local FreekModel = {}

FreekModel.RAINBOW_TAG = "RainbowFreek"

local function newPart(props): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		part[key] = value
	end
	return part
end

local function ball(size: number, color: Color3, position: Vector3): Part
	return newPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * size,
		Color = color,
		CFrame = CFrame.new(position),
	})
end

local EYE_LAYOUTS = {
	[1] = { size = 0.42, xs = { 0 } },
	[2] = { size = 0.28, xs = { -0.2, 0.2 } },
	[3] = { size = 0.22, xs = { -0.27, 0, 0.27 } },
}

local SHAPES = {
	Ball = Enum.PartType.Ball,
	Block = Enum.PartType.Block,
	Cylinder = Enum.PartType.Cylinder,
}

local function vector(value): Vector3
	if type(value) == "number" then
		return Vector3.one * value
	end
	return Vector3.new(value[1], value[2], value[3])
end

local function addEffect(part: BasePart, effect)
	local kind = effect.type
	local color = effect.color or Color3.fromRGB(255, 230, 120)
	local instance
	if kind == "Sparkles" then
		instance = Instance.new("Sparkles")
		instance.SparkleColor = color
	elseif kind == "Fire" then
		instance = Instance.new("Fire")
		instance.Color = color
		instance.SecondaryColor = effect.color2 or Color3.fromRGB(255, 220, 80)
		instance.Size = effect.size or 5
		instance.Heat = effect.heat or 9
	elseif kind == "Smoke" then
		instance = Instance.new("Smoke")
		instance.Color = color
		instance.Size = effect.size or 2
		instance.Opacity = 0.3
		instance.RiseVelocity = 2
	elseif kind == "Glow" then
		instance = Instance.new("PointLight")
		instance.Color = color
		instance.Range = effect.size or 10
		instance.Brightness = 2
	else
		warn("Unknown Freek effect " .. tostring(kind))
		return
	end
	instance.Parent = part
end

local function buildFromParts(species, mutationId: string?): (Model, number)
	local look = species.look
	local model = Instance.new("Model")
	model.Name = species.name

	local parts = {}
	local top = 0
	for i, spec in look.parts do
		local shape = spec.shape or "Block"
		local size = vector(spec.size)
		local rot = spec.rot or { 0, 0, 0 }
		local cframe = CFrame.new(vector(spec.pos))
			* CFrame.Angles(math.rad(rot[1]), math.rad(rot[2]), math.rad(rot[3]))
		local part
		if shape == "Wedge" then
			part = Instance.new("WedgePart")
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.Material = Enum.Material.SmoothPlastic
		else
			part = newPart({ Shape = SHAPES[shape] or Enum.PartType.Block })
		end
		part.Name = spec.name or (if i == 1 then "Body" else "Part" .. i)
		part.Size = size
		part.CFrame = cframe
		part.Color = spec.color or Color3.new(1, 1, 1)
		if spec.material then
			part.Material = Enum.Material[spec.material]
		end
		part.Transparency = spec.transparency or 0

		if not spec.detail then
			if mutationId == "Golden" then
				part.Color = Color3.fromRGB(255, 196, 40):Lerp(part.Color, 0.15)
				part.Material = Enum.Material.Foil
			elseif mutationId == "Shadow" then
				part.Color = Color3.fromRGB(35, 25, 50):Lerp(part.Color, 0.1)
			elseif mutationId == "Rainbow" then
				part.Material = Enum.Material.Neon
				CollectionService:AddTag(part, FreekModel.RAINBOW_TAG)
			end
		end

		part.Parent = model
		parts[i] = part
		top = math.max(top, spec.pos[2] + size.Y / 2)
	end

	local body = parts[1]
	body.PivotOffset = body.CFrame:Inverse()
	model.PrimaryPart = body

	for _, effect in look.effects or {} do
		addEffect(parts[effect.part or 1], effect)
	end
	if mutationId == "Golden" or mutationId == "Rainbow" then
		addEffect(body, {
			type = "Sparkles",
			color = if mutationId == "Golden" then Color3.fromRGB(255, 220, 80) else Color3.new(1, 1, 1),
		})
	elseif mutationId == "Shadow" then
		addEffect(body, { type = "Smoke", color = Color3.fromRGB(60, 30, 90), size = 1.5 })
	end

	return model, top
end

-- Effects that show a mutation, for Freeks that carry more than one (the rarest sets the
-- colours, the rest add their effect on top).
local MUTATION_EFFECTS = {
	Rainbow = { type = "Sparkles", color = Color3.new(1, 1, 1) },
	Golden = { type = "Sparkles", color = Color3.fromRGB(255, 220, 80) },
	Shadow = { type = "Smoke", color = Color3.fromRGB(60, 30, 90), size = 1.5 },
}

local buildHybrid

local function buildSingle(speciesId: string, mutationId: string?): (Model, number)
	local species = Freeks.byId[speciesId] or Freeks.list[1]
	local look = species.look
	local s = look.size or 3

	if look.hybrid then
		return buildHybrid(species, mutationId)
	end

	local custom = ReplicatedStorage:FindFirstChild("FreekModels")
	custom = custom and custom:FindFirstChild(species.id)
	if custom and custom:IsA("Model") then
		local model = custom:Clone()
		local _, extents = model:GetBoundingBox()
		return model, extents.Y
	end

	if look.parts then
		return buildFromParts(species, mutationId)
	end

	local bodyColor = look.color
	local bodyMaterial = Enum.Material.SmoothPlastic
	local pupilColor = Color3.new(0, 0, 0)
	local pupilMaterial = Enum.Material.SmoothPlastic
	if mutationId == "Golden" then
		bodyColor = Color3.fromRGB(255, 196, 40)
		bodyMaterial = Enum.Material.Foil
	elseif mutationId == "Shadow" then
		bodyColor = Color3.fromRGB(35, 25, 50)
		pupilColor = Color3.fromRGB(180, 70, 255)
		pupilMaterial = Enum.Material.Neon
	elseif mutationId == "Rainbow" then
		bodyMaterial = Enum.Material.Neon
	end

	local model = Instance.new("Model")
	model.Name = species.name

	local isBall = look.shape ~= "Block"
	local bodyY = s * 0.6
	local body = newPart({
		Name = "Body",
		Shape = if isBall then Enum.PartType.Ball else Enum.PartType.Block,
		Size = Vector3.one * s,
		Color = bodyColor,
		Material = bodyMaterial,
		CFrame = CFrame.new(0, bodyY, 0),
	})
	body.PivotOffset = CFrame.new(0, -bodyY, 0)
	body.Parent = model
	model.PrimaryPart = body

	if mutationId == "Rainbow" then
		CollectionService:AddTag(body, FreekModel.RAINBOW_TAG)
	end
	if mutationId == "Golden" or mutationId == "Rainbow" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = if mutationId == "Golden"
			then Color3.fromRGB(255, 220, 80)
			else Color3.fromRGB(255, 255, 255)
		sparkles.Parent = body
	end

	-- Where the front surface of the body is at a given offset (in multiples of s) from its center.
	local function frontZ(x: number, y: number): number
		if isBall then
			return -math.sqrt(math.max(0.25 - x * x - y * y, 0.04)) * s
		end
		return -0.5 * s
	end

	-- Feet
	for _, x in { -0.25, 0.25 } do
		local foot = ball(s * 0.3, bodyColor:Lerp(Color3.new(0, 0, 0), 0.25), Vector3.new(x * s, s * 0.15, -0.05 * s))
		foot.Material = bodyMaterial
		foot.Parent = model
	end

	-- Eyes
	local layout = EYE_LAYOUTS[math.clamp(look.eyes or 2, 1, 3)]
	local eyeY = 0.12
	for _, x in layout.xs do
		local z = frontZ(x, eyeY) + 0.04 * s
		local white = ball(s * layout.size, Color3.new(1, 1, 1), Vector3.new(x * s, bodyY + eyeY * s, z))
		white.Parent = model
		local pupil =
			ball(s * layout.size * 0.5, pupilColor, Vector3.new(x * s, bodyY + eyeY * s, z - s * layout.size * 0.36))
		pupil.Material = pupilMaterial
		pupil.Parent = model
	end

	-- Mouth
	local mouthY = -0.17
	local mouth = newPart({
		Size = Vector3.new(0.3 * s, 0.06 * s, 0.06 * s),
		Color = Color3.fromRGB(60, 20, 30),
		CFrame = CFrame.new(0, bodyY + mouthY * s, frontZ(0, mouthY) + 0.01 * s),
	})
	mouth.Parent = model

	-- Antennae
	local count = math.clamp(look.antennae or 0, 0, 3)
	for i = 1, count do
		local x = if count == 1 then 0 else (i - (count + 1) / 2) * 0.25
		local topY = bodyY + (if isBall then 0.45 else 0.5) * s
		local stalk = newPart({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4 * s, 0.06 * s, 0.06 * s),
			Color = bodyColor:Lerp(Color3.new(0, 0, 0), 0.35),
			CFrame = CFrame.new(x * s, topY + 0.2 * s, 0) * CFrame.Angles(0, 0, math.pi / 2),
		})
		stalk.Parent = model
		local tip = ball(0.15 * s, Color3.fromRGB(255, 240, 120), Vector3.new(x * s, topY + 0.42 * s, 0))
		tip.Material = Enum.Material.Neon
		tip.Parent = model
	end

	return model, s * 1.6
end

-- A hybrid: one body with the colours of both parents blended, the first parent's lower
-- half (legs, feet, snout, mouth) and the second parent's upper half (eyes, ears, antennae).
function buildHybrid(species, mutationId: string?): (Model, number)
	local model, height = buildSingle(species.look.hybrid.a, mutationId)
	local other, otherHeight = buildSingle(species.look.hybrid.b, mutationId)
	model.Name = species.name
	local body, otherBody = model.PrimaryPart, other.PrimaryPart
	if not body or not otherBody then
		other:Destroy()
		return model, height
	end

	-- Scale the second parent so the bodies match, and centre it on the first one's body.
	local scale = body.Size.Magnitude / otherBody.Size.Magnitude
	local otherCenter = otherBody.Position
	for _, part in other:GetDescendants() do
		if part:IsA("BasePart") then
			local offset = (part.Position - otherCenter) * scale
			part.Size *= scale
			part.CFrame = CFrame.new(body.Position + offset) * part.CFrame.Rotation
		end
	end

	local center = body.Position
	local function fromSecond(part: BasePart): boolean
		return part.Position.Y > center.Y
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= body and fromSecond(part) then
			part:Destroy()
		end
	end
	for _, part in other:GetDescendants() do
		if part:IsA("BasePart") and part ~= otherBody and fromSecond(part) then
			part.Parent = model
		end
	end
	if not mutationId then
		body.Color = body.Color:Lerp(otherBody.Color, 0.5)
	end
	other:Destroy()
	return model, math.max(height, otherHeight * scale)
end

-- Returns the model and roughly how tall it is (for placing name tags). mutations is a
-- list of mutation ids (a single id also works).
function FreekModel.build(speciesId: string, mutations): (Model, number)
	local list = Mutations.normalize(mutations)
	local model, height = buildSingle(speciesId, list[1])
	local body = model.PrimaryPart
	for i = 2, #list do
		local effect = MUTATION_EFFECTS[list[i]]
		-- Rainbow and Golden already sparkle; don't stack a second set.
		local sparkling = body and body:FindFirstChildOfClass("Sparkles")
		if body and effect and not (effect.type == "Sparkles" and sparkling) then
			addEffect(body, effect)
		end
	end
	return model, height
end

return FreekModel
