-- Builds the placeholder 3D model for a Freek out of plain parts.
-- The model's pivot sits at its feet and its face points along -Z (the model's front),
-- so model:PivotTo(groundCFrame) stands it on the ground facing groundCFrame.LookVector.
--
-- When real models exist, put them in ReplicatedStorage.FreekModels named by species id
-- and they will be used instead.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Freeks = require(script.Parent.Freeks)

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

-- Returns the model and roughly how tall it is (for placing name tags).
function FreekModel.build(speciesId: string, mutationId: string?): (Model, number)
	local species = Freeks.byId[speciesId] or Freeks.list[1]
	local look = species.look
	local s = look.size

	local custom = ReplicatedStorage:FindFirstChild("FreekModels")
	custom = custom and custom:FindFirstChild(species.id)
	if custom and custom:IsA("Model") then
		local model = custom:Clone()
		local _, extents = model:GetBoundingBox()
		return model, extents.Y
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

return FreekModel
