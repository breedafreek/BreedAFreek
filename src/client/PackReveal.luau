-- Mystery Box opening, done like a card-pack reveal in the big sports games, in 3D.
-- The camera cuts to a dark arena (built on this client only, high above the map): the
-- box drops onto a glowing pedestal under sweeping spotlights, shakes, and bursts into a
-- face-down card. Then the clues slam onto the screen one at a time (first which SLOT of
-- the house the part is for, then its RARITY, with every light in the arena turning that
-- colour) before the card flips over in 3D and the part pops out in front of it with its
-- name. The rarer the part, the longer the suspense and the wilder the lights.
-- Tapping the screen speeds it up.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BoxModel = require(ReplicatedStorage.Shared.BoxModel)
local HouseModel = require(ReplicatedStorage.Shared.HouseModel)
local HouseUtil = require(ReplicatedStorage.Shared.HouseUtil)
local Luck = require(ReplicatedStorage.Shared.Luck)
local Parts = require(ReplicatedStorage.Shared.Parts)
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local UI = require(script.Parent.UI)

local PackReveal = {}

local STAGE = CFrame.new(0, 3000, 0) -- far above the map, out of everyone's way
local CARD_SIZE = Vector3.new(6, 8.4, 0.35)
local CARD_HOME = Vector3.new(0, 7.2, 0) -- where the card floats, above the pedestal
local PEDESTAL_TOP = 1.6
local DARK = Color3.fromRGB(14, 12, 28)
local GOLD = Color3.fromRGB(255, 205, 70)

local RARITY_WORDS = {
	Common = "COMMON",
	Uncommon = "UNCOMMON",
	Rare = "RARE!",
	Legendary = "LEGENDARY!",
	Mystic = "MYSTIC!!",
	Ultra = "ULTRA!!!",
	Secret = "SECRET!!!",
}

local function easeOut(a: number): number
	return 1 - (1 - a) ^ 3
end

local function easeInOut(a: number): number
	return a * a * (3 - 2 * a)
end

local function rainbow(t: number, offset: number?): Color3
	return Color3.fromHSV((t * 0.5 + (offset or 0)) % 1, 0.75, 1)
end

local function at(x: number, y: number, z: number): CFrame
	return STAGE * CFrame.new(x, y, z)
end

local function newPart(parent: Instance, props)
	local p = Instance.new(props.ClassName or "Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		if key ~= "ClassName" then
			p[key] = value
		end
	end
	p.Parent = parent
	return p
end

-- Text on one face of a part.
local function faceText(
	part: BasePart,
	face: Enum.NormalId,
	text: string,
	color: Color3,
	position: UDim2,
	size: UDim2,
	heavy: boolean?
)
	local gui = part:FindFirstChild("Face" .. face.Name)
	if not gui then
		gui = Instance.new("SurfaceGui")
		gui.Name = "Face" .. face.Name
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 50
		gui.LightInfluence = 0
		gui.Parent = part
	end
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.TextScaled = true
	label.Font = if heavy then Enum.Font.LuckiestGuy else Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = color
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = UI.OUTLINE
	stroke.Thickness = 4
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	return label
end

-- The back of the card: a monster card that feels alive. Dark chrome with scanlines, a
-- silver-and-gold frame with curved horns out of the top corners, violet energy cracks
-- flickering out from a big glowing dragon eye that looks around and blinks, a ring of
-- runes turning round it, a chrome nameplate, and a holographic glint sweeping across.
-- Built round the card's centre (the back faces -Z). Returns animate(t), which moves the
-- living parts; call it every frame after the card is placed.
local function buildCardBack(card: Model, body: BasePart): (number) -> ()
	local half = Vector2.new(CARD_SIZE.X / 2, CARD_SIZE.Y / 2)
	local z0 = -CARD_SIZE.Z / 2
	local eye = Vector2.new(0, 0.55)
	local violet = Color3.fromRGB(175, 90, 255)
	local cyan = Color3.fromRGB(90, 235, 255)
	local chrome = Color3.fromRGB(200, 205, 220)
	local random = Random.new(7)
	local function flat(
		name: string,
		size: Vector3,
		x: number,
		y: number,
		z: number,
		color: Color3,
		material,
		angle: number?
	)
		return newPart(card, {
			Name = name,
			Size = size,
			CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, 0, angle or 0),
			Color = color,
			Material = material or Enum.Material.SmoothPlastic,
		})
	end
	local function ellipsoid(name: string, size: Vector3, x: number, y: number, z: number, color: Color3, material)
		local part = flat(name, size, x, y, z, color, material)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
		return part
	end
	local function disc(name: string, diameter: number, depth: number, z: number, color: Color3, material)
		return newPart(card, {
			Name = name,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(depth, diameter, diameter),
			CFrame = CFrame.new(eye.X, eye.Y, z) * CFrame.Angles(0, math.pi / 2, 0),
			Color = color,
			Material = material or Enum.Material.SmoothPlastic,
		})
	end

	-- Dark chrome with faint scanlines.
	body.Color = Color3.fromRGB(16, 12, 30)
	body.Material = Enum.Material.Metal
	for k = 0, 15 do
		flat(
			"Scanline",
			Vector3.new(CARD_SIZE.X - 1, 0.07, 0.02),
			0,
			-half.Y + 0.6 + k * 0.48,
			z0 - 0.01,
			Color3.fromRGB(34, 24, 62)
		)
	end

	-- Energy cracks: jagged violet lines from the eye out towards the edges.
	local cracks = {}
	for k = 0, 7 do
		local angle = k / 8 * math.pi * 2 + 0.3
		local point = eye + Vector2.new(math.cos(angle), math.sin(angle)) * 2.3
		for _ = 1, 3 do
			local turn = angle + random:NextNumber(-0.6, 0.6)
			local step = random:NextNumber(0.6, 1.1)
			local nextPoint = point + Vector2.new(math.cos(turn), math.sin(turn)) * step
			if math.abs(nextPoint.X) > half.X - 0.7 or math.abs(nextPoint.Y) > half.Y - 0.7 then
				break
			end
			local mid = (point + nextPoint) / 2
			local dir = nextPoint - point
			table.insert(
				cracks,
				flat(
					"Crack",
					Vector3.new(dir.Magnitude + 0.12, 0.15, 0.03),
					mid.X,
					mid.Y,
					z0 - 0.03,
					violet,
					Enum.Material.Neon,
					math.atan2(dir.Y, dir.X)
				)
			)
			point = nextPoint
		end
	end

	-- Frame: chrome bevel with a thin gold line inside it.
	for _, inset in { { 0.32, 0.22, chrome, Enum.Material.Foil, 0.08 }, { 0.6, 0.08, GOLD, Enum.Material.Neon, 0.06 } } do
		local d, w = inset[1], inset[2]
		for _, bar in
			{
				{ Vector3.new(CARD_SIZE.X - d * 2, w, inset[5]), Vector3.new(0, half.Y - d, 0) },
				{ Vector3.new(CARD_SIZE.X - d * 2, w, inset[5]), Vector3.new(0, -half.Y + d, 0) },
				{ Vector3.new(w, CARD_SIZE.Y - d * 2, inset[5]), Vector3.new(half.X - d, 0, 0) },
				{ Vector3.new(w, CARD_SIZE.Y - d * 2, inset[5]), Vector3.new(-half.X + d, 0, 0) },
			}
		do
			flat("Frame", bar[1], bar[2].X, bar[2].Y, z0 - 0.05, inset[3], inset[4])
		end
	end
	-- Horns curling up and out of the top corners: thick dark purple at the root, tapering
	-- to a glowing gold tip. Each is a chain of tapered cylinders with balls at the joints.
	for _, side in { -1, 1 } do
		local points = {}
		for k = 0, 8 do
			local f = k / 8
			local angle = math.rad(25 + 70 * f) -- sweeps from out-and-up to straight up
			table.insert(
				points,
				Vector2.new(
					side * (half.X - 0.55 + math.cos(angle) * 1.6 * f),
					half.Y - 0.35 + math.sin(angle) * 2.1 * f
				)
			)
		end
		for k = 1, #points - 1 do
			local f = (k - 1) / (#points - 1)
			local a0, a1 = points[k], points[k + 1]
			local width = 0.95 - 0.8 * f
			local color = Color3.fromRGB(55, 22, 90):Lerp(Color3.fromRGB(170, 100, 230), f)
			local dir = a1 - a0
			newPart(card, {
				Name = "Horn",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(dir.Magnitude + width * 0.3, width, width),
				CFrame = CFrame.new((a0.X + a1.X) / 2, (a0.Y + a1.Y) / 2, z0 + 0.05)
					* CFrame.Angles(0, 0, math.atan2(dir.Y, dir.X)),
				Color = color,
			})
			newPart(card, {
				Name = "Horn",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * width,
				CFrame = CFrame.new(a0.X, a0.Y, z0 + 0.05),
				Color = color,
			})
		end
		local tip = points[#points]
		newPart(card, {
			Name = "HornTip",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.3,
			CFrame = CFrame.new(tip.X, tip.Y, z0 + 0.05),
			Color = GOLD,
			Material = Enum.Material.Neon,
		})
	end

	-- The eye: a glowing socket, an amber eyeball, a green iris with a slit pupil, and lids.
	disc("SocketGlow", 4.3, 0.06, z0 - 0.04, violet, Enum.Material.Neon).Transparency = 0.35
	disc("SocketRing", 3.9, 0.2, z0 - 0.12, chrome, Enum.Material.Foil)
	disc("Socket", 3.5, 0.24, z0 - 0.16, Color3.fromRGB(10, 6, 20))
	local eyeball = ellipsoid(
		"Eyeball",
		Vector3.new(3.0, 2.1, 0.9),
		eye.X,
		eye.Y,
		z0 - 0.3,
		Color3.fromRGB(255, 160, 40),
		Enum.Material.Neon
	)
	local iris = ellipsoid("Iris", Vector3.new(1.55, 1.55, 0.35), eye.X, eye.Y, z0 - 0.82, Color3.fromRGB(110, 240, 90))
	local irisRing =
		ellipsoid("IrisRing", Vector3.new(1.75, 1.75, 0.3), eye.X, eye.Y, z0 - 0.8, Color3.fromRGB(30, 90, 30))
	local pupil = flat("Pupil", Vector3.new(0.3, 1.3, 0.1), eye.X, eye.Y, z0 - 1.0, Color3.fromRGB(8, 6, 14))
	local glint = newPart(card, {
		Name = "Glint",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 0.3,
		CFrame = CFrame.new(eye.X - 0.35, eye.Y + 0.4, z0 - 1.05),
		Color = Color3.new(1, 1, 1),
		Material = Enum.Material.Neon,
	})
	-- An angry brow over the eye.
	for _, side in { -1, 1 } do
		flat(
			"Brow",
			Vector3.new(1.7, 0.32, 0.25),
			eye.X + side * 0.85,
			eye.Y + 1.45,
			z0 - 0.35,
			Color3.fromRGB(60, 24, 100),
			nil,
			math.rad(side * -14)
		)
	end

	-- Runes circling the eye.
	local runes = {}
	for k = 1, 12 do
		table.insert(
			runes,
			newPart(card, {
				Name = "Rune",
				Size = if k % 3 == 0 then Vector3.new(0.34, 0.34, 0.05) else Vector3.new(0.12, 0.34, 0.05),
				Color = cyan,
				Material = Enum.Material.Neon,
			})
		)
	end

	-- Title and nameplate.
	local title = flat("BackTitle", Vector3.new(4.2, 0.5, 0.02), 0, half.Y - 1.05, z0 - 0.05, Color3.new(), nil)
	title.Transparency = 1
	faceText(title, Enum.NormalId.Front, "✦ FREEK CARD ✦", cyan, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), true)
	local plate = flat("Nameplate", Vector3.new(4.6, 1, 0.16), 0, -half.Y + 1.3, z0 - 0.1, chrome, Enum.Material.Foil)
	flat("NameplateInset", Vector3.new(4.3, 0.75, 0.04), 0, -half.Y + 1.3, z0 - 0.19, Color3.fromRGB(24, 14, 44))
	local plateText = flat("NameplateText", Vector3.new(4.2, 0.7, 0.02), 0, -half.Y + 1.3, z0 - 0.22, Color3.new(), nil)
	plateText.Transparency = 1
	faceText(
		plateText,
		Enum.NormalId.Front,
		"STEAL A HOME",
		GOLD,
		UDim2.fromScale(0.03, 0.05),
		UDim2.fromScale(0.94, 0.9),
		true
	)
	for _, side in { -1, 1 } do
		newPart(card, {
			Name = "PlateBolt",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.22,
			CFrame = CFrame.new(side * 2.1, plate.Position.Y, z0 - 0.2),
			Color = violet,
			Material = Enum.Material.Neon,
		})
	end

	-- The holographic glint.
	local shine = newPart(card, {
		Name = "Shine",
		Size = Vector3.new(0.3, CARD_SIZE.Y - 1.4, 0.02),
		CFrame = CFrame.new(0, 0, z0 - 1.2),
		Color = Color3.new(1, 1, 1),
		Material = Enum.Material.Neon,
		Transparency = 1,
		CastShadow = false,
	})

	local flicker = Random.new()
	return function(t: number)
		local base = body.CFrame
		local function put(part: BasePart, x: number, y: number, z: number, angle: number?)
			part.CFrame = base * CFrame.new(x, y, z) * CFrame.Angles(0, 0, angle or 0)
		end
		-- The eye looks around, darting now and then.
		local look = Vector2.new(math.sin(t * 0.8) * 0.45 + math.sin(t * 3.1) * 0.08, math.sin(t * 1.3) * 0.2)
		-- A blink every few seconds: the eye squints shut and opens again.
		local phase = (t % 3.4) / 0.28
		local open = 1 - (if phase < 1 then math.sin(phase * math.pi) else 0) * 0.92
		eyeball.Size = Vector3.new(3.0, 2.1 * open, 0.9)
		iris.Size = Vector3.new(1.55, 1.55 * open, 0.35)
		irisRing.Size = Vector3.new(1.75, 1.75 * open, 0.3)
		pupil.Size = Vector3.new(0.3, 1.3 * open, 0.1)
		glint.Transparency = if open < 0.5 then 1 else 0
		local lookY = look.Y * open
		put(eyeball, eye.X, eye.Y, z0 - 0.3)
		put(irisRing, eye.X + look.X, eye.Y + lookY, z0 - 0.62)
		put(iris, eye.X + look.X, eye.Y + lookY, z0 - 0.66)
		put(pupil, eye.X + look.X, eye.Y + lookY, z0 - 0.84)
		put(glint, eye.X + look.X - 0.35, eye.Y + lookY + 0.4, z0 - 0.9)
		-- The runes turn round the eye.
		for k, rune in runes do
			local angle = k / #runes * math.pi * 2 + t * 0.6
			put(rune, eye.X + math.cos(angle) * 2.3, eye.Y + math.sin(angle) * 2.3, z0 - 0.09, angle)
		end
		-- The cracks crackle.
		for _, crack in cracks do
			crack.Transparency = if flicker:NextNumber() < 0.15 then 0.6 else 0
		end
		-- The glint sweeps across every couple of seconds.
		local x = ((t * 0.9) % 2.2 - 1.1) * CARD_SIZE.X
		local inside = math.abs(x) < half.X - 1.6
		put(shine, x, 0, z0 - 1.2, math.rad(20))
		shine.Transparency = if inside then 0.78 + 0.2 * (math.abs(x) / (half.X - 1.6)) ^ 2 else 1
	end
end

-- Hides the rest of the HUD while the reveal plays; returns a function that brings it back.
local function hideHud(playerGui: Instance, keep: Instance): () -> ()
	local hidden = {}
	for _, gui in playerGui:GetChildren() do
		if gui:IsA("ScreenGui") and gui ~= keep and gui.Enabled then
			gui.Enabled = false
			table.insert(hidden, gui)
		end
	end
	return function()
		for _, gui in hidden do
			gui.Enabled = true
		end
	end
end

-- result = { crate, rarity, isNew, where = "installed"|"backpack", part = { id, mutations } }
function PackReveal.play(result, done: () -> ())
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local partInfo = Parts.byId[result.part.id]
	local rarity = result.rarity
	local tier = Rarities.rank[rarity] or 1
	local rarityColor = Rarities.info[rarity] and Rarities.info[rarity].color or Color3.new(1, 1, 1)
	-- The first clue is which slot of the house it's for.
	local slot = Parts.slotById[partInfo.slot]
	local series = { icon = slot.icon, name = slot.name, color = UI.cardColor(slot.name) }
	local random = Random.new()

	----------------------------------------------------------------------------
	-- The arena
	----------------------------------------------------------------------------
	local stage = Instance.new("Folder")
	stage.Name = "PackStage"
	stage.Parent = Workspace

	-- A dark room so nothing else shows: floor, walls and ceiling.
	newPart(stage, {
		Name = "Floor",
		Size = Vector3.new(110, 1, 110),
		CFrame = at(0, -0.5, 0),
		Color = Color3.fromRGB(22, 20, 40),
		Reflectance = 0.15,
	})
	for _, wall in
		{
			{ Vector3.new(110, 60, 1), Vector3.new(0, 30, 55) },
			{ Vector3.new(110, 60, 1), Vector3.new(0, 30, -55) },
			{ Vector3.new(1, 60, 110), Vector3.new(55, 30, 0) },
			{ Vector3.new(1, 60, 110), Vector3.new(-55, 30, 0) },
			{ Vector3.new(110, 1, 110), Vector3.new(0, 60, 0) },
		}
	do
		newPart(stage, { Name = "Wall", Size = wall[1], CFrame = at(wall[2].X, wall[2].Y, wall[2].Z), Color = DARK })
	end

	-- Everything that changes colour with the clues.
	local lit = {} -- { part = BasePart, offset = number }
	local function litPart(props, offset: number?)
		local p = newPart(stage, props)
		table.insert(lit, { part = p, offset = offset or 0 })
		return p
	end

	-- Rings of light on the floor.
	for r, radius in { 9, 15, 22 } do
		local count = 20 + r * 8
		for k = 1, count do
			local angle = k / count * math.pi * 2
			local p0 = Vector3.new(math.cos(angle) * radius, 0.05, math.sin(angle) * radius)
			local p1 = Vector3.new(
				math.cos(angle + math.pi * 2 / count) * radius,
				0.05,
				math.sin(angle + math.pi * 2 / count) * radius
			)
			litPart({
				Name = "FloorRing",
				Size = Vector3.new(0.45, 0.1, (p1 - p0).Magnitude * 0.7),
				CFrame = STAGE * CFrame.lookAt((p0 + p1) / 2, p1),
				Material = Enum.Material.Neon,
				Transparency = 0.15 * r,
			}, k / count)
		end
	end

	-- The pedestal.
	newPart(stage, {
		Name = "Pedestal",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(PEDESTAL_TOP, 8, 8),
		CFrame = at(0, PEDESTAL_TOP / 2, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(40, 38, 60),
		Material = Enum.Material.Metal,
	})
	local rim = litPart({
		Name = "PedestalRim",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.25, 8.5, 8.5),
		CFrame = at(0, PEDESTAL_TOP - 0.1, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Material = Enum.Material.Neon,
	})
	local light = Instance.new("PointLight")
	light.Range = 34
	light.Brightness = 2
	light.Shadows = false
	light.Parent = rim

	-- Stage spotlights: lamps on a ring above the stage, each throwing a soft cone of light
	-- (a bright core inside a wide glow, fading towards the floor) that sweeps round the
	-- pedestal, with a real spotlight and a glowing pool where it lands.
	local RIG_HEIGHT, RIG_RADIUS = 30, 19
	newPart(stage, {
		Name = "LightRig",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, RIG_RADIUS * 2 + 2, RIG_RADIUS * 2 + 2),
		CFrame = at(0, RIG_HEIGHT + 1.2, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(30, 30, 40),
		Material = Enum.Material.Metal,
		Transparency = 0,
	})
	local function coneBeam(a0: Attachment, a1: Attachment, width0: number, width1: number, near: number, far: number)
		local beam = Instance.new("Beam")
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Width0 = width0
		beam.Width1 = width1
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Segments = 12
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, near),
			NumberSequenceKeypoint.new(0.7, (near + far) / 2 + 0.05),
			NumberSequenceKeypoint.new(1, far),
		})
		beam.Parent = a0.Parent
		return beam
	end
	local beams = {}
	for k = 1, 8 do
		local angle = k / 8 * math.pi * 2
		local lampAt = Vector3.new(math.cos(angle) * RIG_RADIUS, RIG_HEIGHT, math.sin(angle) * RIG_RADIUS)
		newPart(stage, {
			Name = "Lamp",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.2, 1.8, 1.8),
			CFrame = at(lampAt.X, lampAt.Y, lampAt.Z),
			Color = Color3.fromRGB(35, 35, 45),
			Material = Enum.Material.Metal,
		})
		local lens = litPart({
			Name = "LampLens",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 1.3,
			CFrame = at(lampAt.X, lampAt.Y - 0.9, lampAt.Z),
			Material = Enum.Material.Neon,
		}, k / 8)
		local pool = litPart({
			Name = "LightPool",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.05, 5, 5),
			Material = Enum.Material.Neon,
			Transparency = 0.8,
			CastShadow = false,
		}, k / 8)
		local from = Instance.new("Attachment")
		from.Parent = lens
		local to = Instance.new("Attachment")
		to.Parent = pool
		local core = coneBeam(from, to, 0.8, 3.2, 0.45, 0.85)
		local halo = coneBeam(from, to, 2.2, 9, 0.82, 0.97)
		local spot = Instance.new("SpotLight")
		spot.Angle = 30
		spot.Range = 45
		spot.Brightness = 3
		spot.Shadows = false
		spot.Face = Enum.NormalId.Front
		spot.Parent = lens
		table.insert(
			beams,
			{ lens = lens, pool = pool, spot = spot, core = core, halo = halo, top = lampAt, angle = angle }
		)
	end

	----------------------------------------------------------------------------
	-- The 2D overlay: clue words, flashes, the name and the button
	----------------------------------------------------------------------------
	local gui = UI.new("ScreenGui", {
		Name = "PackReveal",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 50,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})
	local showHud = hideHud(playerGui, gui)
	local overlay = UI.new("TextButton", {
		Name = "Overlay",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = gui,
	})
	local speed = 1
	overlay.Activated:Connect(function()
		speed = 4 -- tap to hurry it along
	end)

	local function flash(color: Color3, duration: number)
		local frame = UI.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = color,
			BackgroundTransparency = 0,
			ZIndex = 40,
			Parent = gui,
		})
		task.spawn(function()
			local began = os.clock()
			while os.clock() - began < duration do
				frame.BackgroundTransparency = (os.clock() - began) / duration
				task.wait()
			end
			frame:Destroy()
		end)
	end

	local captionLabel = UI.label("", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.09),
		Size = UDim2.fromOffset(500, 34),
		FontFace = UI.fonts.heavy,
		TextColor3 = Color3.fromRGB(230, 230, 255),
		TextTransparency = 1,
		ZIndex = 20,
		Parent = overlay,
	})
	captionLabel:FindFirstChildOfClass("UIStroke").Transparency = 1
	local clueLabel = UI.label("", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.18),
		Size = UDim2.fromOffset(900, 100),
		FontFace = UI.fonts.heavy,
		TextTransparency = 1,
		ZIndex = 20,
		Parent = overlay,
	})
	local clueStroke = clueLabel:FindFirstChildOfClass("UIStroke")
	clueStroke.Thickness = 5
	clueStroke.Transparency = 1
	local clueScale = UI.new("UIScale", { Parent = clueLabel })
	local clueGradient = UI.new("UIGradient", { Enabled = false, Parent = clueLabel })

	----------------------------------------------------------------------------
	-- Animation state, updated every frame
	----------------------------------------------------------------------------
	local camera = Workspace.CurrentCamera
	local oldCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	local oldFov = camera.FieldOfView
	camera.FieldOfView = 55
	local controls: any = nil
	pcall(function()
		local module = require(player.PlayerScripts:WaitForChild("PlayerModule", 1) :: any)
		controls = module:GetControls()
		controls:Disable()
	end)

	local state = {
		color = Color3.fromRGB(200, 200, 230),
		brightness = 0.4, -- 0..1, how strongly the arena lights glow
		sweep = 0.3, -- how fast the beams sweep (radians per second)
		rainbow = false,
		shake = 0,
		camFrom = at(0, 16, -46),
		camTo = at(0, 16, -46),
		camBlend = 1,
		lookAt = at(0, 4, 0).Position,
	}
	local function moveCamera(position: Vector3, look: Vector3)
		state.camFrom = camera.CFrame
		state.camTo = CFrame.lookAt((STAGE * CFrame.new(position)).Position, (STAGE * CFrame.new(look)).Position)
		state.camBlend = 0
	end

	local clock = os.clock()
	local sweepAngle = 0
	local camTime = 0.8
	local function tick(dt: number)
		local now = os.clock()
		sweepAngle += state.sweep * dt
		for i, beam in beams do
			-- Each lamp swings its beam round the pedestal.
			local swing = beam.angle + sweepAngle + math.sin(sweepAngle * 2 + i) * 0.4
			local target = Vector3.new(math.cos(swing) * 8, 0.05, math.sin(swing) * 8)
			beam.lens.CFrame = STAGE * CFrame.lookAt(beam.top - Vector3.new(0, 0.9, 0), target)
			beam.pool.CFrame = STAGE * CFrame.new(target) * CFrame.Angles(0, 0, math.pi / 2)
			local color = if state.rainbow then rainbow(now, i / #beams) else state.color
			beam.core.Color = ColorSequence.new(color)
			beam.halo.Color = ColorSequence.new(color)
			beam.spot.Color = color
			beam.spot.Brightness = 1 + 4 * state.brightness
			beam.core.Brightness = 0.6 + 1.4 * state.brightness
			beam.halo.Brightness = beam.core.Brightness
			beam.pool.Transparency = 0.95 - 0.07 * state.brightness
		end
		for _, entry in lit do
			entry.part.Color = if state.rainbow then rainbow(now, entry.offset) else state.color
		end
		light.Color = if state.rainbow then rainbow(now) else state.color
		light.Brightness = 1 + 4 * state.brightness
		-- Camera: glide towards its target, then shake on impacts.
		state.camBlend = math.min(state.camBlend + dt / camTime, 1)
		local cf = state.camFrom:Lerp(state.camTo, easeInOut(state.camBlend))
		if state.shake > 0.01 then
			cf *= CFrame.new(random:NextNumber(-1, 1) * state.shake, random:NextNumber(-1, 1) * state.shake, 0)
			state.shake *= math.exp(-dt * 7)
		end
		camera.CFrame = cf
	end

	-- Runs fn(alpha, t) every frame for `duration` seconds (shorter when sped up).
	local function animate(duration: number, fn: ((number, number) -> ())?)
		local elapsed = 0
		while true do
			local now = os.clock()
			local dt = math.min(now - clock, 0.1)
			clock = now
			elapsed += dt * speed
			local alpha = math.min(elapsed / duration, 1)
			if fn then
				fn(alpha, elapsed)
			end
			tick(dt * speed)
			if alpha >= 1 then
				break
			end
			task.wait()
		end
	end

	-- Bits that fly out and fall: egg shell, sparks, confetti.
	local function burst(center: Vector3, count: number, colors: { Color3 }, confetti: boolean?)
		local bits = {}
		for k = 1, count do
			local direction = random:NextUnitVector() * Vector3.new(1, 0.6, 1) + Vector3.new(0, 0.6, 0)
			local bit = newPart(stage, {
				ClassName = if confetti then "Part" else "WedgePart",
				Name = "Bit",
				Size = if confetti then Vector3.new(0.4, 0.06, 0.25) else Vector3.new(0.15, 0.6, 0.6),
				CFrame = STAGE
					* CFrame.new(center + direction)
					* CFrame.Angles(random:NextNumber(0, 6), random:NextNumber(0, 6), 0),
				Color = colors[k % #colors + 1],
				Material = if confetti then Enum.Material.Neon else Enum.Material.SmoothPlastic,
			})
			table.insert(bits, { part = bit, velocity = direction.Unit * random:NextNumber(10, 22) })
		end
		task.spawn(function()
			local began, last = os.clock(), os.clock()
			while os.clock() - began < 2 do
				local now = os.clock()
				local dt = now - last
				last = now
				for _, b in bits do
					b.velocity -= Vector3.new(0, (if confetti then 14 else 35) * dt, 0)
					b.part.CFrame = (b.part.CFrame + b.velocity * dt) * CFrame.Angles(6 * dt, 4 * dt, 0)
					b.part.Transparency = ((now - began) / 2) ^ 2
				end
				task.wait()
			end
			for _, b in bits do
				b.part:Destroy()
			end
		end)
	end

	local function slam(caption: string, text: string, color: Color3)
		captionLabel.Text = caption
		clueLabel.Text = text
		clueLabel.TextColor3 = color
		captionLabel.TextTransparency = 0
		captionLabel:FindFirstChildOfClass("UIStroke").Transparency = 0
		animate(0.2, function(a)
			clueScale.Scale = 2.6 - 1.6 * easeOut(a)
			clueLabel.TextTransparency = 1 - a
			clueStroke.Transparency = 1 - a
		end)
		state.shake = 0.5 + tier * 0.06
	end

	local function hideClue()
		animate(0.15, function(a)
			clueLabel.TextTransparency = a
			clueStroke.Transparency = a
			captionLabel.TextTransparency = a
			captionLabel:FindFirstChildOfClass("UIStroke").Transparency = a
		end)
		clueGradient.Enabled = false
	end

	----------------------------------------------------------------------------
	-- 1. Into the arena: the camera swoops in and the egg drops onto the pedestal.
	----------------------------------------------------------------------------
	camera.CFrame = state.camFrom
	flash(Color3.new(0, 0, 0), 0.5)
	moveCamera(Vector3.new(0, 7, -24), Vector3.new(0, 4, 0))
	local egg = BoxModel.build(result.crate)
	egg.Parent = stage
	local eggRest = at(0, PEDESTAL_TOP, 0) * CFrame.Angles(0, math.pi, 0)
	animate(0.8, function(a)
		state.brightness = 0.25 + 0.2 * a
		local drop = if a < 0.75 then 22 * (1 - (a / 0.75) ^ 2) else math.sin((a - 0.75) / 0.25 * math.pi) * 0.8
		egg:PivotTo(eggRest + Vector3.new(0, drop, 0))
	end)
	state.shake = 0.6

	----------------------------------------------------------------------------
	-- 2. The egg shakes harder and harder while the camera creeps in.
	----------------------------------------------------------------------------
	camTime = 1 + tier * 0.15
	moveCamera(Vector3.new(0, 5, -14), Vector3.new(0, 3.2, 0))
	animate(1 + tier * 0.15, function(a, t)
		local wobble = math.sin(t * (14 + a * 24)) * math.rad(4 + 18 * a * a)
		egg:PivotTo(eggRest * CFrame.Angles(0, 0, wobble) + Vector3.new(0, math.abs(math.sin(t * 9)) * 0.3 * a, 0))
		state.brightness = 0.45 + 0.4 * a
		state.sweep = 0.3 + 2.5 * a
	end)

	----------------------------------------------------------------------------
	-- 3. Burst! A face-down card spins up out of the light.
	----------------------------------------------------------------------------
	flash(Color3.new(1, 1, 1), 0.45)
	burst(
		Vector3.new(0, PEDESTAL_TOP + 2, 0),
		18,
		{ (Luck.crateById[result.crate] and Luck.crateById[result.crate].color) or GOLD, Color3.new(1, 1, 1) }
	)
	egg:Destroy()
	state.shake = 1
	state.sweep = 0.6

	local card = Instance.new("Model")
	card.Name = "Card"
	card.Parent = stage
	local body = newPart(card, {
		Name = "CardBody",
		Size = CARD_SIZE,
		CFrame = CFrame.new(),
		Color = Color3.fromRGB(34, 16, 72),
	})
	card.PrimaryPart = body
	local rimParts = {}
	for _, bar in
		{
			{ Vector3.new(CARD_SIZE.X + 0.3, 0.3, 0.5), Vector3.new(0, CARD_SIZE.Y / 2, 0) },
			{ Vector3.new(CARD_SIZE.X + 0.3, 0.3, 0.5), Vector3.new(0, -CARD_SIZE.Y / 2, 0) },
			{ Vector3.new(0.3, CARD_SIZE.Y + 0.3, 0.5), Vector3.new(CARD_SIZE.X / 2, 0, 0) },
			{ Vector3.new(0.3, CARD_SIZE.Y + 0.3, 0.5), Vector3.new(-CARD_SIZE.X / 2, 0, 0) },
		}
	do
		table.insert(
			rimParts,
			newPart(card, {
				Name = "CardRim",
				Size = bar[1],
				CFrame = CFrame.new(bar[2]),
				Color = GOLD,
				Material = Enum.Material.Neon,
			})
		)
	end
	-- The back (facing the camera to start with): see buildCardBack.
	local animateBack = buildCardBack(card, body)
	-- The front starts blank (the card spins round as it appears, so nothing on it may give
	-- the pull away); paintFront() puts the rarity colours and words on just before the flip.
	local face = newPart(card, {
		Name = "CardFace",
		Size = Vector3.new(CARD_SIZE.X - 0.3, CARD_SIZE.Y - 0.3, 0.1),
		CFrame = CFrame.new(0, 0, CARD_SIZE.Z / 2 + 0.05),
		Color = Color3.fromRGB(16, 12, 30),
		Material = Enum.Material.Metal,
	})
	local function paintFront()
		face.Color = rarityColor:Lerp(Color3.new(0, 0, 0), 0.15)
		face.Material = Enum.Material.SmoothPlastic
		faceText(
			face,
			Enum.NormalId.Back,
			series.icon .. " " .. string.upper(series.name),
			series.color:Lerp(Color3.new(1, 1, 1), 0.4),
			UDim2.fromScale(0.06, 0.05),
			UDim2.fromScale(0.88, 0.09),
			true
		)
		faceText(
			face,
			Enum.NormalId.Back,
			string.upper(rarity),
			Color3.new(1, 1, 1),
			UDim2.fromScale(0.05, 0.4),
			UDim2.fromScale(0.9, 0.2),
			true
		)
		faceText(
			face,
			Enum.NormalId.Back,
			"★ ★ ★",
			GOLD,
			UDim2.fromScale(0.2, 0.66),
			UDim2.fromScale(0.6, 0.1),
			true
		)
	end

	local cardSpin = 0 -- extra turn on top of the float
	local cardRise = 0
	local function placeCard(t: number, extra: CFrame?)
		local float = math.sin(t * 2.2) * 0.25
		card:PivotTo(
			STAGE
				* CFrame.new(CARD_HOME + Vector3.new(0, float + cardRise, 0))
				* CFrame.Angles(0, cardSpin + math.sin(t * 0.9) * 0.12, 0)
				* (extra or CFrame.new())
		)
		animateBack(t)
	end
	moveCamera(Vector3.new(0, 7.5, -20), CARD_HOME)
	camTime = 0.6
	animate(0.6, function(a, t)
		local e = easeOut(a)
		cardSpin = (1 - e) * math.pi * 4
		cardRise = -5 * (1 - e)
		placeCard(t)
	end)
	cardSpin = 0
	cardRise = 0

	local function setRim(color: Color3)
		for _, p in rimParts do
			p.Color = color
		end
	end

	----------------------------------------------------------------------------
	-- 4. Clue one: the slot. The arena lights turn its colour.
	----------------------------------------------------------------------------
	state.color = series.color
	state.brightness = 0.7
	slam("SLOT", series.icon .. " " .. string.upper(series.name), series.color)
	setRim(series.color)
	camTime = 2
	moveCamera(Vector3.new(-5, 8, -18), CARD_HOME)
	animate(1.3 + tier * 0.1, function(_, t)
		placeCard(t)
	end)
	hideClue()

	----------------------------------------------------------------------------
	-- 5. Clue two: the rarity, climbing the ladder. COMMON slams in, then UNCOMMON,
	-- RARE... one rung at a time, each lighting the next pip on the meter and turning the
	-- whole arena its colour, with the pauses getting longer and the beams faster as it
	-- climbs. Before a big final rung the arena blacks out and the card's edge pulses like a
	-- heartbeat; then the real rarity lands with everything it's got.
	----------------------------------------------------------------------------
	local rungs = math.max(tier, 1)
	local shown = math.max(math.min(#Rarities.order, math.max(tier, 6)), 1) -- Common..Ultra (Secret if pulled)
	local meter = UI.new("Frame", {
		Name = "RarityMeter",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.92),
		Size = UDim2.fromOffset(shown * 126, 40),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = overlay,
	}, {
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local pips = {}
	for k = 1, shown do
		local name = Rarities.order[k]
		local pip = UI.new("Frame", {
			Name = name,
			Size = UDim2.fromOffset(118, 34),
			BackgroundColor3 = Color3.fromRGB(30, 30, 52),
			BackgroundTransparency = 0.25,
			LayoutOrder = k,
			ZIndex = 20,
			Parent = meter,
		}, { UI.corner(17) })
		local stroke = UI.stroke(nil, 2.5)
		stroke.Parent = pip
		local label = UI.label(string.upper(name), {
			Size = UDim2.fromScale(1, 1),
			FontFace = UI.fonts.heavy,
			TextColor3 = Color3.fromRGB(120, 120, 150),
			ZIndex = 21,
			Parent = pip,
		})
		label.Size = UDim2.new(1, -10, 1, -8)
		label.Position = UDim2.fromOffset(5, 4)
		local scale = UI.new("UIScale", { Parent = pip })
		pips[k] = { frame = pip, stroke = stroke, label = label, scale = scale }
	end
	animate(0.25, function(a, t)
		placeCard(t)
		meter.Position = UDim2.new(0.5, 0, 0.92, 60 * (1 - easeOut(a)))
	end)

	local function lightPip(k: number, current: boolean)
		local pip = pips[k]
		if not pip then
			return
		end
		local color = Rarities.info[Rarities.order[k]].color
		pip.frame.BackgroundColor3 = color:Lerp(Color3.new(0, 0, 0), 0.25)
		pip.frame.BackgroundTransparency = 0
		pip.label.TextColor3 = Color3.new(1, 1, 1)
		pip.stroke.Color = if current then Color3.new(1, 1, 1) else UI.OUTLINE
		pip.stroke.Thickness = if current then 3.5 else 2.5
		pip.scale.Scale = if current then 1.15 else 1
	end

	-- Camera stations for the climb: each rung pushes in a little closer.
	local function climbCamera(k: number)
		local f = (k - 1) / math.max(rungs - 1, 1)
		camTime = 0.35
		moveCamera(Vector3.new(math.sin(k * 1.7) * 3, 7.5 - f * 0.8, -19 + f * 5), CARD_HOME)
	end

	-- Fake-outs: on the way up, the card sometimes settles as if this is it and starts to
	-- turn over... then jolts back ("WAIT...!") and the climb carries on. Legendary and
	-- better always get one (Ultra and Secret two); Uncommon and Rare get one half the time.
	local fakeRungs = {}
	local fakeRandom = Random.new()
	if rungs >= 2 and (tier >= 4 or fakeRandom:NextNumber() < 0.5) then
		fakeRungs[fakeRandom:NextInteger(math.max(1, rungs - 2), rungs - 1)] = true
	end
	if tier >= 6 then
		fakeRungs[fakeRandom:NextInteger(1, math.max(1, rungs - 3))] = true
	end
	local function fakeOut(k: number)
		-- It all goes calm, like the climb is over...
		state.sweep = 0.25
		camTime = 0.9
		moveCamera(Vector3.new(0, 7.3, -14), CARD_HOME)
		animate(0.45, function(_, t)
			placeCard(t)
			pips[k].scale.Scale = 1.15
		end)
		-- ...the card starts to turn over...
		animate(0.65, function(a, t)
			cardSpin = math.pi * 0.42 * easeInOut(a)
			placeCard(t)
		end)
		-- ...then jolts back, and the climb is on again.
		flash(Color3.new(1, 1, 1), 0.3)
		state.shake = 1.3
		captionLabel.Text = ""
		clueLabel.Text = "WAIT...!"
		clueLabel.TextColor3 = Color3.new(1, 1, 1)
		animate(0.22, function(a, t)
			cardSpin = math.pi * 0.42 * (1 - easeOut(a))
			placeCard(t)
			clueScale.Scale = 2.4 - 1.4 * easeOut(a)
			clueLabel.TextTransparency = 1 - a
			clueStroke.Transparency = 1 - a
		end)
		cardSpin = 0
		state.sweep = 2.5
		animate(0.55, function(_, t)
			placeCard(t)
		end)
		animate(0.1, function(a, t)
			placeCard(t)
			clueLabel.TextTransparency = a
			clueStroke.Transparency = a
		end)
	end

	for k = 1, rungs do
		local name = Rarities.order[k]
		local color = Rarities.info[name].color
		local final = k == rungs
		if final and tier >= 3 then
			-- Blackout and heartbeat before the big one.
			hideClue()
			state.color = Color3.fromRGB(60, 50, 90)
			state.sweep = 0.2
			camTime = 1.1
			moveCamera(Vector3.new(0, 7.2, -12.5), CARD_HOME)
			animate(0.5 + tier * 0.12, function(a, t)
				placeCard(t)
				state.brightness = 0.9 * (1 - a) + 0.08
				local beat = math.max(math.sin(t * 9), 0) ^ 6
				setRim(Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(40, 30, 60), 1 - beat))
				if beat > 0.95 then
					state.shake = math.max(state.shake, 0.25)
				end
			end)
		end
		lightPip(k, true)
		if pips[k - 1] then
			lightPip(k - 1, false)
		end
		state.color = color
		setRim(color)
		if not final then
			-- A quick rung: the word punches in, the arena turns its colour, then on.
			clueLabel.Text = string.upper(name)
			clueLabel.TextColor3 = color
			captionLabel.Text = "RARITY"
			captionLabel.TextTransparency = 0
			captionLabel:FindFirstChildOfClass("UIStroke").Transparency = 0
			state.brightness = 0.55 + 0.1 * k
			state.sweep = 0.6 + k * 0.5
			climbCamera(k)
			animate(0.14, function(a, t)
				placeCard(t)
				clueScale.Scale = 1.8 - 0.8 * easeOut(a)
				clueLabel.TextTransparency = 1 - a
				clueStroke.Transparency = 1 - a
			end)
			flash(color:Lerp(Color3.new(1, 1, 1), 0.6), 0.15)
			state.shake = 0.3 + k * 0.06
			-- Each rung holds a little longer than the last: the suspense builds.
			animate(0.3 + k * 0.14, function(a, t)
				placeCard(t)
				pips[k].scale.Scale = 1.15 + math.sin(a * math.pi) * 0.08
			end)
			if fakeRungs[k] then
				fakeOut(k)
			else
				animate(0.1, function(a, t)
					placeCard(t)
					clueLabel.TextTransparency = a * 0.7
				end)
			end
		else
			-- The real rarity lands.
			state.brightness = 1
			state.sweep = 1 + tier * 0.4
			state.rainbow = tier >= 6
			if tier >= 3 then
				flash(color:Lerp(Color3.new(1, 1, 1), 0.5), 0.4)
			end
			if state.rainbow then
				local keys = {}
				for c = 0, 6 do
					table.insert(keys, ColorSequenceKeypoint.new(c / 6, Color3.fromHSV(c / 6, 0.75, 1)))
				end
				clueGradient.Color = ColorSequence.new(keys)
				clueGradient.Enabled = true
			end
			slam(
				"RARITY",
				RARITY_WORDS[rarity] or string.upper(rarity),
				if state.rainbow then Color3.new(1, 1, 1) else color
			)
			state.shake = 0.8 + tier * 0.1
			if tier >= 4 then
				local colors = {}
				for c = 1, 6 do
					table.insert(colors, Color3.fromHSV(c / 6, 0.7, 1))
				end
				burst(CARD_HOME + Vector3.new(0, 4, 0), 30 + tier * 8, colors, true)
			end
		end
	end

	local nextStrike = 0.3
	camTime = 1.5 + tier * 0.25
	moveCamera(Vector3.new(5, 6.5, -17), CARD_HOME)
	animate(1.2 + tier * 0.25, function(_, t)
		placeCard(t)
		pips[rungs].scale.Scale = 1.15 + math.sin(t * 6) * 0.06
		if state.rainbow then
			setRim(rainbow(os.clock()))
			clueGradient.Offset = Vector2.new(math.sin(t * 2) * 0.5, 0)
			for k = 1, rungs do
				pips[k].frame.BackgroundColor3 = rainbow(os.clock(), k / rungs)
			end
		end
		if tier >= 5 and t >= nextStrike then
			nextStrike += 0.55
			flash(Color3.fromRGB(220, 200, 255), 0.18)
			state.shake = 0.7
		end
	end)
	hideClue()
	meter:Destroy()

	paintFront()

	----------------------------------------------------------------------------
	-- 6. The flip: the card turns over in 3D, then the part pops out in front of it.
	----------------------------------------------------------------------------
	camTime = 0.5
	moveCamera(Vector3.new(0, 7.5, -16), CARD_HOME)
	animate(0.55, function(a, t)
		cardSpin = math.pi * easeInOut(a)
		placeCard(t)
	end)
	cardSpin = math.pi
	flash(Color3.new(1, 1, 1), 0.35)
	state.shake = 0.8
	burst(CARD_HOME, 24, { rarityColor, Color3.new(1, 1, 1) })
	animate(0.5, function(_, t)
		placeCard(t)
	end)

	-- The card lifts up and back; the part pops out onto the pedestal.
	local freek = HouseModel.item(result.part.id)
	pcall(freek.ScaleTo, freek, 1.3)
	for _, p in freek:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
		end
	end
	freek.Parent = stage
	local freekRest = at(0, PEDESTAL_TOP, -0.5)
	camTime = 0.9
	moveCamera(Vector3.new(0, 5.5, -15), Vector3.new(0, 6.2, 1))
	animate(0.6, function(a, t)
		local e = easeOut(a)
		cardRise = 5 * e
		card:PivotTo(
			STAGE
				* CFrame.new(CARD_HOME + Vector3.new(0, cardRise, 6 * e))
				* CFrame.Angles(0, math.pi + math.sin(t * 0.9) * 0.12, 0)
		)
		local hop = math.sin(a * math.pi) * 3
		freek:PivotTo(freekRest * CFrame.new(0, hop - 2 * (1 - e), 0) * CFrame.Angles(0, (1 - e) * math.pi * 2, 0))
	end)
	flash(rarityColor:Lerp(Color3.new(1, 1, 1), 0.6), 0.3)
	burst(Vector3.new(0, PEDESTAL_TOP + 1, -0.5), 20, { rarityColor, GOLD })
	state.shake = 0.6

	-- 7. The name slams in, with NEW! if it's new to them.
	local nameLabel = UI.label(string.upper(HouseUtil.displayName(result.part)), {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.86),
		Size = UDim2.fromOffset(800, 70),
		FontFace = UI.fonts.heavy,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 20,
		Parent = overlay,
	})
	nameLabel:FindFirstChildOfClass("UIStroke").Thickness = 4
	local nameScale = UI.new("UIScale", { Parent = nameLabel })
	animate(0.2, function(a)
		nameScale.Scale = 2.2 - 1.2 * easeOut(a)
	end)
	UI.label(string.upper(rarity) .. "  ·  " .. string.upper(series.name), {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.86, -50),
		Size = UDim2.fromOffset(500, 28),
		FontFace = UI.fonts.heavy,
		TextColor3 = rarityColor,
		ZIndex = 20,
		Parent = overlay,
	})
	if result.isNew then
		local stamp = UI.label("NEW!", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.64, 0.36),
			Size = UDim2.fromOffset(120, 50),
			FontFace = UI.fonts.heavy,
			TextColor3 = Color3.new(1, 1, 1),
			BackgroundColor3 = UI.colors.red,
			BackgroundTransparency = 0,
			Rotation = 12,
			ZIndex = 22,
			Parent = overlay,
		})
		UI.corner(12).Parent = stamp
		UI.stroke(nil, 3).Parent = stamp
		local stampScale = UI.new("UIScale", { Parent = stamp })
		animate(0.18, function(a)
			stampScale.Scale = 2 - easeOut(a)
		end)
	end
	UI.label(if result.where == "installed" then "It's on your house!" else "It's in your backpack!", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.86, 48),
		Size = UDim2.fromOffset(400, 26),
		TextColor3 = Color3.fromRGB(220, 232, 255),
		ZIndex = 20,
		Parent = overlay,
	})

	-- 8. Show it off until they tap Awesome!
	local closed = false
	UI.button("AWESOME!", UI.colors.green, function()
		closed = true
	end, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -60, 1, -50),
		Size = UDim2.fromOffset(220, 60),
		ZIndex = 25,
		Parent = overlay,
	})
	speed = 1
	camTime = 6
	moveCamera(Vector3.new(-4, 5.5, -14.5), Vector3.new(0, 6.2, 1))
	local showTime = 0
	freek:PivotTo(freekRest)
	while not closed do
		animate(0.2, function(_, t)
			local time = showTime + t
			card:PivotTo(
				STAGE
					* CFrame.new(CARD_HOME + Vector3.new(0, 5 + math.sin(time * 2.2) * 0.25, 6))
					* CFrame.Angles(0, math.pi + math.sin(time * 0.9) * 0.12, 0)
			)
			-- It turns slowly on the pedestal to show off.
			freek:PivotTo(freekRest * CFrame.new(0, math.sin(time * 2) * 0.25, 0) * CFrame.Angles(0, time * 0.7, 0))
			if state.rainbow then
				setRim(rainbow(os.clock()))
			end
		end)
		showTime += 0.2
	end

	-- Back to the game.
	stage:Destroy()
	gui:Destroy()
	showHud()
	camera.CameraType = if oldCameraType == Enum.CameraType.Scriptable then Enum.CameraType.Custom else oldCameraType
	camera.FieldOfView = oldFov
	if controls then
		controls:Enable()
	end
	done()
end

return PackReveal
