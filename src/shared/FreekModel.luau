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
--   { shape = "Ball" | "Ellipsoid" | "Block" | "Cylinder" | "Wedge", size = { x, y, z } (or one number),
--     pos = { x, y, z }, rot = { x, y, z } (degrees, optional), color = Color3,
--     material = "Neon" etc. (optional), transparency = 0-1 (optional),
--     detail = true (optional: keeps its color when mutated, e.g. eyes),
--     shine = false (optional: no sparkle highlights on a dark detail ball),
--     swing = { hinge = {x, y, z}, phase = 0..1, axis = "X" | "Y" | "Z", amount = 1 }
--       (optional: the part swings around the hinge while the Freek walks, e.g. legs;
--       axis "Y" swings are tails and wag when idle, axis "Z" swings are wings or flippers),
--     rig = "ear" | "arm" (optional: an ear that twitches, or an arm that waves, when idle),
--     side = -1 | 1, pivot = { x, y, z } (for rig parts: which side, and where it bends),
--     onHead = false (optional: stays put when the head turns, e.g. a collar) }
-- A part named "Head" turns to look around, with everything on it; eyes (white detail
-- balls with an iris and pupil in front) blink. See FreekAnimator.
-- A species' walk = "waddle" | "trot" | ... picks how it moves (see the client).
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

local polish
local tagRig

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

-- The finishing touches every designed Freek gets, in the style of today's popular Roblox
-- pets: two sparkle highlights on every pupil and nose (small dark balls marked detail),
-- and a soft glossy sheen on round bodies and heads, like a vinyl toy.
local function luminance(c: Color3): number
	return c.R * 0.3 + c.G * 0.59 + c.B * 0.11
end

function polish(model: Model, specs, parts)
	for i, spec in specs do
		local part = parts[i]
		local shape = spec.shape or "Block"
		local size = part.Size
		if
			spec.detail
			and shape == "Ball"
			and spec.shine ~= false
			and size.X <= 0.9
			and luminance(part.Color) < 0.16
		then
			-- Catchlights sit on the front of the pupil, up and to the side, like light from above.
			local r = size.X / 2
			for k, light in { { 0.42, -0.38, 0.42 }, { 0.2, 0.32, -0.25 } } do
				local dot = newPart({
					Name = "Sparkle",
					Shape = Enum.PartType.Ball,
					Size = Vector3.one * size.X * light[1],
					Color = Color3.new(1, 1, 1),
					CFrame = part.CFrame * CFrame.new(light[2] * r, light[3] * r, -r * 0.82),
					CanQuery = false,
				})
				if k == 2 then
					dot.Transparency = 0.15
				end
				dot:SetAttribute("Rig", part:GetAttribute("Rig"))
				local swing = part:GetAttribute("SwingHinge")
				if swing then
					dot:SetAttribute("SwingHinge", swing)
					dot:SetAttribute("SwingPhase", part:GetAttribute("SwingPhase"))
					dot:SetAttribute("SwingAxis", part:GetAttribute("SwingAxis"))
					dot:SetAttribute("SwingAmount", part:GetAttribute("SwingAmount"))
				end
				dot.Parent = model
			end
		elseif
			(spec.name == "Body" or spec.name == "Head" or i == 1)
			and (shape == "Ball" or shape == "Ellipsoid")
			and spec.gloss ~= false
		then
			-- A soft sheen high on the front, like light catching a shiny toy.
			local half = if shape == "Ball" then Vector3.one * math.min(size.X, size.Y, size.Z) / 2 else size / 2
			local sheen = newPart({
				Name = "Sheen",
				Shape = Enum.PartType.Block,
				Size = Vector3.new(half.X * 0.7, half.Y * 0.38, half.Z * 0.2),
				Color = Color3.new(1, 1, 1),
				Transparency = 0.72,
				CFrame = part.CFrame
					* CFrame.new(-half.X * 0.32, half.Y * 0.6, -half.Z * 0.62)
					* CFrame.Angles(math.rad(-35), math.rad(-25), 0),
				CanQuery = false,
				CastShadow = false,
			})
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = sheen
			sheen.Parent = model
		end
	end
end

-- Marks what moves when the Freek is idle (see FreekAnimator): everything on its head gets
-- OnHead, and each eye (a white detail ball or ellipsoid with the parts in front of it)
-- gets an Eye number, with EyeWhite on the white. Round eye parts become sphere-meshed
-- blocks, which look the same but can squash shut to blink.
local function sphereBlock(part: BasePart)
	if part:IsA("Part") and part.Shape == Enum.PartType.Ball then
		part.Shape = Enum.PartType.Block
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
	end
end

function tagRig(model: Model, specs, parts)
	local body = parts[1]
	local head = model:FindFirstChild("Head")
	local headCenter, headRadius
	if head and head:IsA("BasePart") then
		headCenter = head.CFrame.Position
		headRadius = math.max(head.Size.X, head.Size.Y, head.Size.Z) / 2
		for _, part in model:GetChildren() do
			if part:IsA("BasePart") and part ~= body and not part:GetAttribute("SwingHinge") then
				local offset = part.CFrame.Position - headCenter
				if
					offset.Magnitude <= headRadius * 1.55
					and offset.Y >= -headRadius * 0.92
					and offset.Z <= headRadius
					and part:GetAttribute("Rig") ~= "arm"
					and part:GetAttribute("NotOnHead") ~= true
				then
					part:SetAttribute("OnHead", true)
				end
			end
		end
	end

	-- A Freek with no separate head wears its face on its body: mark the face (the front
	-- details and anything small on the front of the upper body) so a hybrid can swap it.
	if not headCenter then
		local center = body.CFrame.Position
		local half = body.Size / 2
		for i, spec in specs do
			local part = parts[i]
			local offset = part.CFrame.Position - center
			if
				i > 1
				and not spec.swing
				and offset.Z < -half.Z * 0.4
				and offset.Y > -half.Y * 0.6
				and math.max(part.Size.X, part.Size.Y) < math.max(half.X, half.Y) * 1.3
			then
				part:SetAttribute("Face", true)
			end
		end
		for _, part in model:GetChildren() do
			if part.Name == "Sparkle" then
				local offset = part.CFrame.Position - center
				if offset.Z < -half.Z * 0.4 then
					part:SetAttribute("Face", true)
				end
			end
		end
	end

	-- Eyes: big white detail balls on the head (or on the upper body of a head-less Freek).
	local all = model:GetChildren()
	local eyes = 0
	for i, spec in specs do
		local part = parts[i]
		local shape = spec.shape or "Block"
		local size = part.Size
		local color = part.Color
		local whiteish = math.min(color.R, color.G, color.B) > 0.9
		local placed = if headCenter
			then part:GetAttribute("OnHead") == true
			else part.CFrame.Position.Y > body.CFrame.Position.Y
		if
			spec.detail
			and whiteish
			and (shape == "Ball" or shape == "Ellipsoid")
			and math.min(size.X, size.Y) >= 0.25
			and math.max(size.X, size.Y) <= 2.4
			and (spec.transparency or 0) < 0.5
			and placed
			and not part:GetAttribute("Eye")
		then
			eyes += 1
			local center = part.CFrame.Position
			local half = size / 2
			part:SetAttribute("Eye", eyes)
			part:SetAttribute("EyeWhite", true)
			sphereBlock(part)
			for _, other in all do
				if other:IsA("BasePart") and other ~= part and other ~= body and other ~= head then
					local offset = other.CFrame.Position - center
					local big = math.max(other.Size.X, other.Size.Y)
					if
						math.abs(offset.X) <= half.X
						and math.abs(offset.Y) <= half.Y
						and offset.Z <= 0.05
						and offset.Z >= -half.Z - 0.5
						and big <= math.max(size.X, size.Y) * 1.02
						and not other:GetAttribute("Eye")
					then
						other:SetAttribute("Eye", eyes)
						sphereBlock(other)
					end
				end
			end
		end
	end
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
		elseif shape == "Ellipsoid" then
			-- A smooth stretched ball: a block drawn as a sphere filling its size.
			part = newPart({ Shape = Enum.PartType.Block })
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = part
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
		if spec.swing then
			part:SetAttribute("SwingHinge", vector(spec.swing.hinge))
			part:SetAttribute("SwingPhase", spec.swing.phase or 0)
			part:SetAttribute("SwingAxis", spec.swing.axis or "X")
			part:SetAttribute("SwingAmount", spec.swing.amount or 1)
		end
		if spec.onHead == false then
			part:SetAttribute("NotOnHead", true)
		end
		if spec.detail then
			part:SetAttribute("Detail", true)
		end
		if spec.rig then
			part:SetAttribute("Rig", spec.rig)
			part:SetAttribute("RigSide", spec.side or (if spec.pos[1] < 0 then -1 else 1))
			if spec.pivot then
				part:SetAttribute("RigPivot", vector(spec.pivot))
			end
		end

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
	polish(model, look.parts, parts)
	tagRig(model, look.parts, parts)

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

-- A hybrid: the first parent's whole body (legs, arms, tail, anything it holds) wearing
-- the second parent's whole head (ears, eyes, hair, hats), resized to fit and set where
-- the first parent's head was, so every piece stays joined up. A round Freek with no
-- separate head (its face is on its body) gets the new head on top, and loses its old
-- face; given as the head, its whole round body becomes the head.

-- The parts that make up a Freek's head, where it is and how big.
local function headOf(model: Model): ({ BasePart }, Vector3, number, BasePart)
	local body = model.PrimaryPart :: BasePart
	local head = model:FindFirstChild("Head")
	local list = {}
	if head and head:IsA("BasePart") then
		-- Everything tagged OnHead, plus anything else on top of the head (a big afro, a
		-- hat), but never limbs, tails or things like a collar.
		local center = head.CFrame.Position
		local radius = math.max(head.Size.X, head.Size.Y, head.Size.Z) / 2
		for _, part in model:GetChildren() do
			if part:IsA("BasePart") and part ~= body then
				local offset = part.CFrame.Position - center
				local around = offset.Magnitude <= radius * 2.1
					and offset.Y >= radius * 0.2
					and offset.Z <= radius * 1.4
					and not part:GetAttribute("SwingHinge")
					and part:GetAttribute("Rig") ~= "arm"
					and not part:GetAttribute("NotOnHead")
				if part == head or part:GetAttribute("OnHead") or around then
					table.insert(list, part)
				end
			end
		end
		return list, center, radius, head
	end
	-- No head: the round body is the head, with its face and whatever sits on top (horns,
	-- hats), but not its arms, legs, wings or tail.
	local center = body.CFrame.Position
	for _, part in model:GetChildren() do
		if
			part:IsA("BasePart")
			and (
				part == body
				or part:GetAttribute("Face")
				or (
					part.CFrame.Position.Y > center.Y
					and not part:GetAttribute("SwingHinge")
					and part:GetAttribute("Rig") == nil
				)
			)
		then
			table.insert(list, part)
		end
	end
	return list, center, math.max(body.Size.X, body.Size.Y, body.Size.Z) / 2, body
end

function buildHybrid(species, mutationId: string?): (Model, number)
	local model, height = buildSingle(species.look.hybrid.a, mutationId)
	local other = buildSingle(species.look.hybrid.b, mutationId)
	model.Name = species.name
	local body, otherBody = model.PrimaryPart, other.PrimaryPart
	if not body or not otherBody then
		other:Destroy()
		return model, height
	end

	-- Where the new head goes: in place of the first parent's head, or on top of its body.
	local target, targetRadius
	local oldHead = model:FindFirstChild("Head")
	-- The first parent keeps its ears: they go on the new head, so both parents show.
	local oldParts, oldCenter, oldRadius = headOf(model)
	local ears = {}
	for _, part in oldParts do
		if part:GetAttribute("Rig") == "ear" then
			table.insert(ears, part)
		end
	end
	local firstColor = if oldHead and oldHead:IsA("BasePart") then oldHead.Color else body.Color
	if oldHead and oldHead:IsA("BasePart") then
		target, targetRadius = oldCenter, oldRadius
		for _, part in oldParts do
			if part:GetAttribute("Rig") ~= "ear" then
				part:Destroy()
			end
		end
	else
		-- Its face and whatever sat on top (a hat) make way for the new head.
		for _, part in oldParts do
			if part ~= body and part:GetAttribute("Rig") ~= "ear" then
				part:Destroy()
			end
		end
		local size = body.Size
		targetRadius = math.max(size.X, size.Z) * 0.32
		target = body.CFrame.Position + Vector3.new(0, size.Y / 2 + targetRadius * 0.6, 0)
	end

	-- A big, chibi head (like the popular pet games), its bottom kept where it was.
	local grown = targetRadius * 1.15
	target += Vector3.new(0, grown - targetRadius, 0)
	targetRadius = grown

	-- Move the second parent's head over, resized to fit.
	local headParts, center, radius, anchor = headOf(other)
	local headColor = anchor.Color
	local scale = targetRadius / radius
	for _, part in headParts do
		local offset = (part.CFrame.Position - center) * scale
		part.Size *= scale
		part.CFrame = CFrame.new(target + offset) * part.CFrame.Rotation
		local eye = part:GetAttribute("Eye")
		if eye then
			part:SetAttribute("Eye", eye + 100) -- keep the parents' eye numbers apart
		end
		for _, name in { "SwingHinge", "RigPivot" } do
			local point = part:GetAttribute(name)
			if typeof(point) == "Vector3" then
				part:SetAttribute(name, target + (point - center) * scale)
			end
		end
		part:SetAttribute("OnHead", true)
		part.Parent = model
	end
	anchor.Name = "Head" -- so it turns and looks around like any head

	-- Swap the new head's ears for the first parent's, moved and resized to fit it.
	if #ears > 0 then
		for _, part in headParts do
			if part:GetAttribute("Rig") == "ear" then
				part:Destroy()
			end
		end
		local earScale = targetRadius / oldRadius
		for _, part in ears do
			part.Size *= earScale
			part.CFrame = CFrame.new(target + (part.CFrame.Position - oldCenter) * earScale) * part.CFrame.Rotation
			local pivot = part:GetAttribute("RigPivot")
			if typeof(pivot) == "Vector3" then
				part:SetAttribute("RigPivot", target + (pivot - oldCenter) * earScale)
			end
			part:SetAttribute("OnHead", true)
		end
	end

	-- The second parent's tail (if it has one) replaces the first parent's.
	local function tailOf(m: Model)
		local list, hinge = {}, nil
		for _, part in m:GetChildren() do
			if part:IsA("BasePart") and part:GetAttribute("SwingAxis") == "Y" and not part:GetAttribute("OnHead") then
				table.insert(list, part)
				hinge = hinge or part:GetAttribute("SwingHinge")
			end
		end
		return list, hinge
	end
	local newTail, newHinge = tailOf(other)
	if #newTail > 0 and typeof(newHinge) == "Vector3" then
		local oldTail, oldHinge = tailOf(model)
		local half = body.Size / 2
		local back = if typeof(oldHinge) == "Vector3"
			then oldHinge
			else body.CFrame.Position + Vector3.new(0, half.Y * 0.1, half.Z * 0.85)
		for _, part in oldTail do
			part:Destroy()
		end
		local tailScale = math.clamp(body.Size.Magnitude / otherBody.Size.Magnitude, 0.6, 1.4)
		for _, part in newTail do
			part.Size *= tailScale
			part.CFrame = CFrame.new(back + (part.CFrame.Position - newHinge) * tailScale) * part.CFrame.Rotation
			part:SetAttribute("SwingHinge", back)
			part.Parent = model
		end
	end

	-- Both parents' colours: the body takes a little of the head's colour, its legs and arms
	-- a touch more, and it gets patches of the head's colour, like markings.
	if not mutationId then
		body.Color = body.Color:Lerp(headColor, 0.25)
		for _, part in model:GetChildren() do
			if
				part:IsA("BasePart")
				and part:GetAttribute("SwingAxis") == "X"
				and not part:GetAttribute("Detail")
				and not part:GetAttribute("OnHead")
			then
				part.Color = part.Color:Lerp(headColor, 0.35)
			end
		end
		local half = body.Size / 2
		if body:IsA("Part") and body.Shape == Enum.PartType.Ball then
			half = Vector3.one * math.min(half.X, half.Y, half.Z)
		end
		local spot = math.min(half.X, half.Y, half.Z) * 0.75
		for _, direction in
			{
				Vector3.new(0.7, 0.35, -0.55),
				Vector3.new(-0.75, -0.2, -0.45),
				Vector3.new(0.9, -0.3, 0.3),
				Vector3.new(-0.85, 0.45, 0.25),
				Vector3.new(0.2, 0.75, 0.6),
				Vector3.new(-0.3, -0.2, 0.9),
			}
		do
			-- A point on the body's surface in that direction, and a flat spot lying on it.
			local d = direction.Unit
			local reach = 1 / math.sqrt((d.X / half.X) ^ 2 + (d.Y / half.Y) ^ 2 + (d.Z / half.Z) ^ 2)
			local point = body.CFrame.Position + d * reach
			local normal = Vector3.new(d.X / half.X ^ 2, d.Y / half.Y ^ 2, d.Z / half.Z ^ 2).Unit
			local patch = newPart({
				Name = "FusionSpot",
				Shape = Enum.PartType.Block,
				Size = Vector3.new(spot, spot * 0.8, spot * 0.3),
				CFrame = CFrame.lookAt(point, point + normal),
				Color = headColor,
				CanQuery = false,
			})
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = patch
			patch.Parent = model
		end
		-- And a patch of the first parent's colour round one eye, like a mixed-breed pup.
		local d = Vector3.new(-0.5, 0.35, -0.8).Unit
		local headR = targetRadius
		-- Thin and just under the surface, so the eye still sits on top of it.
		local point = target + d * headR * 0.94
		local eyePatch = newPart({
			Name = "FusionSpot",
			Shape = Enum.PartType.Block,
			Size = Vector3.new(headR * 0.95, headR * 0.85, headR * 0.14),
			CFrame = CFrame.lookAt(point, point + d),
			Color = firstColor,
			CanQuery = false,
		})
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = eyePatch
		eyePatch:SetAttribute("OnHead", true)
		eyePatch.Parent = model
	end

	-- The fusion collar where the head meets the body: a chunky two-tone ring with a glowing
	-- trim and a gem in front, so the join looks made that way.
	local bodyColor = body.Color
	local neck = target - Vector3.new(0, targetRadius * 1.0, 0)
	local ring = targetRadius * 1.45
	for k, layer in
		{
			{ 0.18, ring, bodyColor, Enum.Material.SmoothPlastic },
			{ -0.18, ring * 0.95, headColor, Enum.Material.SmoothPlastic },
			{ 0, ring * 1.08, Color3.fromRGB(255, 120, 230), Enum.Material.Neon },
		}
	do
		local collar = newPart({
			Name = "FusionCollar",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(if k == 3 then targetRadius * 0.12 else targetRadius * 0.3, layer[2], layer[2]),
			CFrame = CFrame.new(neck + Vector3.new(0, layer[1] * targetRadius * 0.6, 0))
				* CFrame.Angles(0, 0, math.pi / 2),
			Color = layer[3],
			Material = layer[4],
			CanQuery = false,
		})
		collar:SetAttribute("NotOnHead", true)
		collar.Parent = model
	end
	local gem = newPart({
		Name = "FusionGem",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * targetRadius * 0.45,
		CFrame = CFrame.new(neck + Vector3.new(0, 0, -ring / 2)),
		Color = Color3.fromRGB(255, 120, 230),
		Material = Enum.Material.Neon,
		CanQuery = false,
	})
	gem.Parent = model
	if not mutationId then
		-- A fusion shimmer in the two parents' colours.
		local shimmer = Instance.new("Sparkles")
		shimmer.SparkleColor = bodyColor:Lerp(headColor, 0.5)
		shimmer.Parent = gem
	end
	other:Destroy()

	local top = 0
	local ground = model:GetPivot().Position.Y
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			top = math.max(top, part.CFrame.Position.Y + part.Size.Y / 2 - ground)
		end
	end
	return model, top
end

-- Returns the model and roughly how tall it is (for placing name tags). mutations is a
-- list of mutation ids (a single id also works).
function FreekModel.build(speciesId: string, mutations): (Model, number)
	local list = Mutations.normalize(mutations)
	local model, height = buildSingle(speciesId, list[1])
	local species = Freeks.byId[speciesId]
	model:SetAttribute("Walk", species and species.walk or "waddle")
	-- Stream the whole Freek to clients at once. Otherwise a client can get the model
	-- before its body part, and then Roblox pivots it from its middle instead of its feet,
	-- leaving it half in the ground.
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
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
