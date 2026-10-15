-- The egg hatch show. The egg pops out of the player and lands on the ground in front of
-- them, wobbles harder and harder, cracks and bursts, and the Freek inside jumps out.
-- The rarer the Freek, the bigger the show:
--   Common/Uncommon  a poof and a shockwave
--   Rare             + the egg glows in the rarity colour, more shockwaves
--   Legendary        + light beams, confetti, camera shake, the camera circles the Freek
--   Mystic           + the sky goes dark, the egg floats up, lightning strikes
--   Ultra/Secret     + rainbow everything, orbiting stars, more lightning
-- Only the hatching player sees it (it's all built on the client).

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EggModel = require(Shared.EggModel)
local FreekModel = require(Shared.FreekModel)
local FreekUtil = require(Shared.FreekUtil)
local Rarities = require(Shared.Rarities)
local UI = require(script.Parent.UI)

local Hatch = {}

local BANNERS = {
	Common = "COMMON",
	Uncommon = "UNCOMMON!",
	Rare = "RARE!",
	Legendary = "LEGENDARY!!",
	Mystic = "MYSTIC!!!",
	Ultra = "ULTRA!!!",
	Secret = "SECRET!!!!",
}

local function rainbow(t: number, offset: number?): Color3
	return Color3.fromHSV((t * 0.6 + (offset or 0)) % 1, 0.8, 1)
end

local function easeOut(a: number): number
	return 1 - (1 - a) * (1 - a)
end

local function newPart(parent: Instance, props)
	local part = Instance.new(props.ClassName or "Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		if key ~= "ClassName" then
			part[key] = value
		end
	end
	part.Parent = parent
	return part
end

-- Where the show happens: the ground about 10 studs in front of the player, facing them.
local function findStage(origin: CFrame, exclude: { Instance }): (CFrame, number)
	local flat = Vector3.new(origin.LookVector.X, 0, origin.LookVector.Z)
	flat = if flat.Magnitude > 0.01 then flat.Unit else Vector3.new(0, 0, -1)
	local spot = origin.Position + flat * 10
	local groundY = origin.Position.Y
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclude
	local ok, hit = pcall(function()
		return Workspace:Raycast(spot + Vector3.new(0, 8, 0), Vector3.new(0, -40, 0), params)
	end)
	if ok and hit then
		groundY = hit.Position.Y
	end
	local position = Vector3.new(spot.X, groundY, spot.Z)
	local facing = Vector3.new(origin.Position.X, groundY, origin.Position.Z)
	return CFrame.lookAt(position, facing), groundY
end

-- result = { crate, rarity, freek = { species, mutations }, isNew }
-- showPrize(cleanup) is called once the Freek is out; call cleanup() when the prize card
-- closes. origin is where the player stands (defaults to their character).
-- Returns false if there's nowhere to put on the show (no character).
function Hatch.play(result, gui: ScreenGui, showPrize: (cleanup: () -> ()) -> (), origin: CFrame?): boolean
	local player = Players.LocalPlayer
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not origin then
		if not (root and root:IsA("BasePart")) then
			return false
		end
		origin = root.CFrame * CFrame.new(0, -3, 0)
	end
	local start = origin :: CFrame

	local rarity = result.rarity
	local tier = Rarities.rank[rarity] or 1
	local color = Rarities.info[rarity] and Rarities.info[rarity].color or Color3.new(1, 1, 1)
	local eggColor = EggModel.COLORS[result.crate] or Color3.fromRGB(255, 140, 30)

	local folder = Instance.new("Folder")
	folder.Name = "HatchShow"
	folder.Parent = Workspace
	local stage, groundY = findStage(start, { folder, character :: Instance })
	local ground = stage.Position

	-- Everything that moves on its own (particles, beams, camera shake) runs in `updaters`,
	-- called every frame with (now, dt). An updater returns false to stop.
	local updaters = {}
	local clock = os.clock()
	local function step(): number
		local now = os.clock()
		local dt = math.min(now - clock, 0.1)
		clock = now
		for i = #updaters, 1, -1 do
			if updaters[i](now, dt) == false then
				table.remove(updaters, i)
			end
		end
		return dt
	end
	-- Runs fn(alpha, t) every frame for `duration` seconds.
	local function animate(duration: number, fn: (number, number) -> ())
		local began = os.clock()
		while true do
			local t = os.clock() - began
			local alpha = math.min(t / duration, 1)
			fn(alpha, t)
			step()
			if alpha >= 1 then
				break
			end
			task.wait()
		end
	end

	-- Camera: behind and above the player, looking at the landing spot. Shakes on demand.
	local camera = Workspace.CurrentCamera
	local oldCameraType = camera.CameraType
	local fromCamera = camera.CFrame
	local toward = (start.Position - ground) * Vector3.new(1, 0, 1)
	toward = if toward.Magnitude > 0.01 then toward.Unit else Vector3.new(0, 0, 1)
	local side = toward:Cross(Vector3.yAxis)
	local function cameraAt(angle: number, distance: number, height: number, focusHeight: number?): CFrame
		local direction = CFrame.fromAxisAngle(Vector3.yAxis, angle):VectorToWorldSpace(toward)
		local position = ground + direction * distance + side * (distance * 0.15) + Vector3.new(0, height, 0)
		return CFrame.lookAt(position, ground + Vector3.new(0, focusHeight or 2.5, 0))
	end
	local cameraBase = cameraAt(0, 16, 6.5)
	local cameraFrom = fromCamera
	local cameraBlend = 0
	local shake = 0
	camera.CameraType = Enum.CameraType.Scriptable
	table.insert(updaters, function(_, dt)
		cameraBlend = math.min(cameraBlend + dt / 0.5, 1)
		local cf = cameraFrom:Lerp(cameraBase, easeOut(cameraBlend))
		if shake > 0.01 then
			local r = Random.new()
			cf *= CFrame.new(r:NextNumber(-1, 1) * shake, r:NextNumber(-1, 1) * shake, 0) * CFrame.Angles(
				0,
				0,
				r:NextNumber(-1, 1) * shake * 0.03
			)
			shake *= math.exp(-dt * 5)
		end
		camera.CFrame = cf
		return true
	end)

	-- Stop the player walking off mid-show.
	local controls: any = nil
	pcall(function()
		local module = require(player.PlayerScripts:WaitForChild("PlayerModule", 1) :: any)
		controls = module:GetControls()
		controls:Disable()
	end)

	-- Particles: parts that fly, spin, fall, grow and fade, then vanish.
	local particles = {}
	local function particle(part: BasePart, velocity: Vector3, life: number, opts)
		table.insert(particles, {
			part = part,
			velocity = velocity,
			life = life,
			age = 0,
			gravity = opts.gravity or 0,
			spin = opts.spin or Vector3.zero,
			grow = opts.grow,
			fade = opts.fade,
			size = part.Size,
		})
	end
	table.insert(updaters, function(_, dt)
		for i = #particles, 1, -1 do
			local p = particles[i]
			p.age += dt
			if p.age >= p.life then
				p.part:Destroy()
				table.remove(particles, i)
			else
				local a = p.age / p.life
				p.velocity -= Vector3.new(0, p.gravity * dt, 0)
				local cf = p.part.CFrame + p.velocity * dt
				p.part.CFrame = cf * CFrame.Angles(p.spin.X * dt, p.spin.Y * dt, p.spin.Z * dt)
				if p.grow then
					p.part.Size = p.size * (1 + p.grow * easeOut(a))
				end
				if p.fade then
					p.part.Transparency = math.max(p.part.Transparency, a * a)
				end
			end
		end
		return true
	end)

	local random = Random.new()
	local function puff(position: Vector3, count: number, size: number, tint: Color3?)
		for _ = 1, count do
			local direction = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(0, 0.6), random:NextNumber(-1, 1))
			local ball = newPart(folder, {
				Name = "Puff",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * size * random:NextNumber(0.7, 1.2),
				CFrame = CFrame.new(position + direction),
				Color = tint or Color3.new(1, 1, 1),
				Transparency = 0.15,
			})
			particle(ball, direction * random:NextNumber(4, 8), 0.6, { grow = 1.2, fade = true })
		end
	end
	local function ring(delay: number, ringColor: Color3, radius: number)
		task.delay(delay, function()
			local count = 28
			for k = 1, count do
				local angle = k / count * math.pi * 2
				local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
				local part = newPart(folder, {
					Name = "Shockwave",
					Size = Vector3.new(0.35, 0.45, 0.5),
					CFrame = CFrame.lookAt(
						ground + Vector3.new(0, 0.3, 0) + direction,
						ground + Vector3.new(0, 0.3, 0) + direction * 2
					) * CFrame.Angles(0, math.rad(90), 0),
					Color = ringColor,
					Material = Enum.Material.Neon,
				})
				particle(part, direction * radius / 0.7, 0.7, { grow = radius * 0.22, fade = true })
			end
		end)
	end
	local function confetti(position: Vector3, count: number)
		for i = 1, count do
			local piece = newPart(folder, {
				Name = "Confetti",
				Size = Vector3.new(0.5, 0.08, 0.3),
				CFrame = CFrame.new(position) * CFrame.Angles(random:NextNumber(0, 6), random:NextNumber(0, 6), 0),
				Color = if tier >= 6 then rainbow(0, i / count) else Color3.fromHSV(random:NextNumber(), 0.75, 1),
				Material = Enum.Material.Neon,
			})
			local velocity =
				Vector3.new(random:NextNumber(-1, 1) * 14, random:NextNumber(14, 26), random:NextNumber(-1, 1) * 14)
			particle(piece, velocity, 2.4, { gravity = 30, spin = Vector3.new(8, 5, 3), fade = true })
		end
	end
	local function flash(flashColor: Color3, duration: number)
		local frame = UI.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = flashColor,
			BackgroundTransparency = 0.1,
			ZIndex = 70,
			Parent = gui,
		})
		TweenService:Create(frame, TweenInfo.new(duration), { BackgroundTransparency = 1 }):Play()
		task.delay(duration, frame.Destroy, frame)
	end
	local function lightning(target: Vector3)
		local from = target + Vector3.new(random:NextNumber(-8, 8), 45, random:NextNumber(-8, 8))
		local boltColor = if tier >= 6 then rainbow(os.clock()) else Color3.fromRGB(220, 200, 255)
		local points = { from }
		for k = 1, 6 do
			local p = from:Lerp(target, k / 7)
			table.insert(points, p + Vector3.new(random:NextNumber(-2, 2), 0, random:NextNumber(-2, 2)))
		end
		table.insert(points, target)
		for k = 1, #points - 1 do
			local a, b = points[k], points[k + 1]
			local bolt = newPart(folder, {
				Name = "Lightning",
				Size = Vector3.new(0.45, 0.45, (b - a).Magnitude + 0.3),
				CFrame = CFrame.lookAt((a + b) / 2, b),
				Color = boltColor,
				Material = Enum.Material.Neon,
			})
			particle(bolt, Vector3.zero, 0.25, { fade = true })
		end
		flash(Color3.fromRGB(235, 225, 255), 0.25)
		shake = math.max(shake, 0.6)
	end

	-- 1. The egg pops out of the player and arcs onto the ground, then bounces.
	local egg = EggModel.build(result.crate)
	for _, part in egg:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanQuery = false
		end
	end
	egg.Parent = folder
	local throwFrom = start.Position + Vector3.new(0, 4, 0)
	local spinTurns = 1
	animate(0.8, function(a)
		local position = throwFrom:Lerp(ground, a) + Vector3.new(0, math.sin(a * math.pi) * 7, 0)
		egg:PivotTo(stage.Rotation + position)
		egg:PivotTo(egg:GetPivot() * CFrame.Angles(-(1 - a) * math.pi * 2 * spinTurns, 0, 0))
	end)
	puff(ground, 8, 1.2)
	shake = 0.35
	animate(0.45, function(a)
		local hop = math.abs(math.sin(a * math.pi * 2)) * (1 - a) * 1.2
		egg:PivotTo(stage + Vector3.new(0, hop, 0))
	end)

	-- 2. Suspense: the egg wobbles harder and harder and starts to crack. Rarer Freeks
	-- make it glow, call down light beams, darken the sky and bring lightning.
	local suspense = 1 + tier * 0.5
	local glow = nil
	if tier >= 3 then
		glow = Instance.new("PointLight")
		glow.Color = color
		glow.Range = 16
		glow.Brightness = 0
		glow.Parent = egg.PrimaryPart
	end
	local beams = {}
	if tier >= 4 then
		local count = tier * 2 - 4
		for i = 1, count do
			local beam = newPart(folder, {
				Name = "Beam",
				Size = Vector3.new(0.7, 0.1, 0.7),
				Color = color,
				Material = Enum.Material.Neon,
				Transparency = 0.35,
			})
			table.insert(beams, { part = beam, angle = i / count * math.pi * 2 })
		end
	end
	local beamHeight = 0
	local beamFade = 0
	if #beams > 0 then
		table.insert(updaters, function(now)
			for i, beam in beams do
				if beam.part.Parent then
					local angle = beam.angle + now * 1.6
					local radius = 4 + math.sin(now * 3 + i) * 0.6
					local tilt = CFrame.Angles(math.rad(12), 0, 0)
					beam.part.Size = Vector3.new(0.7, beamHeight, 0.7)
					beam.part.Transparency = 0.35 + 0.65 * beamFade
					beam.part.CFrame = CFrame.new(
						ground + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
					) * CFrame.Angles(0, -angle, 0) * tilt * CFrame.new(0, beamHeight / 2, 0)
					if tier >= 6 then
						beam.part.Color = rainbow(now, i / #beams)
					end
				end
			end
			return true
		end)
	end
	local darkness = nil
	if tier >= 5 then
		darkness = Instance.new("ColorCorrectionEffect")
		darkness.Name = "HatchDark"
		darkness.Parent = Lighting
		TweenService:Create(darkness, TweenInfo.new(suspense * 0.5), {
			Brightness = -0.25,
			Contrast = 0.15,
			TintColor = color:Lerp(Color3.new(1, 1, 1), 0.55),
		}):Play()
	end
	local stars = {}
	if tier >= 6 then
		for i = 1, 6 do
			table.insert(
				stars,
				newPart(folder, {
					Name = "Star",
					Shape = Enum.PartType.Ball,
					Size = Vector3.one * 0.6,
					Material = Enum.Material.Neon,
					Color = rainbow(0, i / 6),
				})
			)
		end
	end
	local cracks = 0
	local function addCracks(count: number)
		local pivot = egg:GetPivot()
		for _ = 1, count do
			cracks += 1
			local angle = (cracks * 2.4) % (math.pi * 2) - math.pi
			local y = random:NextNumber(-1, 1.1)
			for k = 0, 2 do
				newPart(egg, {
					Name = "Crack",
					Size = Vector3.new(0.12, 0.55, 0.1),
					CFrame = pivot
						* EggModel.surface(angle + (if k % 2 == 0 then 0.05 else -0.05), y - k * 0.45, 0.03)
						* CFrame.Angles(0, 0, math.rad(if k % 2 == 0 then 35 else -35)),
					Color = if tier >= 3 then color else Color3.fromRGB(255, 245, 210),
					Material = Enum.Material.Neon,
				})
			end
		end
	end
	local strikes = if tier >= 6 then { 0.3, 0.5, 0.68, 0.84 } elseif tier >= 5 then { 0.4, 0.65, 0.88 } else {}
	local crackAt = { 0.45, 0.65, 0.82 }
	local phase = 0
	local lift = if tier >= 5 then 3 else 0
	animate(suspense, function(a, t)
		local strength = a * a
		phase += (6 + 16 * a) * (1 / 60)
		local rock = math.sin(phase * math.pi) * (0.06 + 0.3 * strength)
		local height = lift * easeOut(math.min(a / 0.4, 1))
		local spin = if lift > 0 then t * (1 + a * 6) else 0
		local hop = if tier >= 4 and a > 0.5 then math.max(math.sin(phase * math.pi * 0.5), 0) * 0.4 * a else 0
		egg:PivotTo(stage * CFrame.new(0, height + hop, 0) * CFrame.Angles(0, spin, rock))
		cameraBase = cameraAt(0, 16 - 5 * easeOut(a), 6.5 - 2 * easeOut(a) + height * 0.5, 2.5 + height)
		if glow then
			glow.Brightness = 1 + 4 * strength * (tier - 2)
		end
		beamHeight = 60 * easeOut(math.min(a / 0.3, 1))
		for i, star in stars do
			local angle = t * 4 + i / #stars * math.pi * 2
			star.CFrame = CFrame.new(
				ground + Vector3.new(math.cos(angle) * 3.2, 2 + height + math.sin(t * 5 + i), math.sin(angle) * 3.2)
			)
			star.Color = rainbow(t, i / #stars)
		end
		if crackAt[1] and a >= crackAt[1] then
			table.remove(crackAt, 1)
			addCracks(if tier >= 4 then 2 else 1)
			shake = math.max(shake, 0.1 + tier * 0.03)
		end
		if strikes[1] and a >= strikes[1] then
			table.remove(strikes, 1)
			lightning(egg:GetPivot().Position + Vector3.new(0, 2, 0))
		end
	end)

	-- 3. Burst! Shell pieces fly, shockwaves roll out, confetti for the good stuff.
	local burstAt = egg:GetPivot().Position + Vector3.new(0, 2, 0)
	egg:Destroy()
	for _, star in stars do
		star:Destroy()
	end
	flash(color:Lerp(Color3.new(1, 1, 1), 0.6), 0.5 + tier * 0.08)
	shake = 0.3 + tier * 0.15
	for i = 1, 14 do
		local direction = CFrame.fromAxisAngle(Vector3.yAxis, i / 14 * math.pi * 2):VectorToWorldSpace(Vector3.xAxis)
		local shard = newPart(folder, {
			ClassName = "WedgePart",
			Name = "Shell",
			Size = Vector3.new(0.15, random:NextNumber(0.6, 1.1), random:NextNumber(0.6, 1)),
			CFrame = CFrame.new(burstAt + direction)
				* CFrame.Angles(random:NextNumber(0, 6), random:NextNumber(0, 6), 0),
			Color = eggColor,
		})
		particle(shard, direction * random:NextNumber(10, 16) + Vector3.new(0, random:NextNumber(10, 18), 0), 1.4, {
			gravity = 40,
			spin = Vector3.new(9, 6, 4),
			fade = true,
		})
	end
	puff(burstAt, 10 + tier * 2, 1.4, if tier >= 3 then color:Lerp(Color3.new(1, 1, 1), 0.5) else nil)
	for k = 1, math.clamp(tier - 1, 1, 4) do
		ring((k - 1) * 0.15, if tier >= 6 then rainbow(os.clock(), k / 4) else color, 10 + tier * 3)
	end
	if tier >= 4 then
		confetti(burstAt, 20 * (tier - 3))
	end

	-- The rarity banner on screen.
	local banner = UI.label(BANNERS[rarity] or rarity, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.15),
		Size = UDim2.fromOffset(620, 70 + tier * 8),
		FontFace = UI.fonts.heavy,
		TextColor3 = if tier >= 6 then Color3.new(1, 1, 1) else color,
		ZIndex = 72,
		Parent = gui,
	})
	local bannerStroke = banner:FindFirstChildOfClass("UIStroke")
	if bannerStroke then
		bannerStroke.Thickness = 4
	end
	local bannerScale = UI.new("UIScale", { Scale = 0.2, Parent = banner })
	TweenService
		:Create(bannerScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
	local bannerGradient = nil
	if tier >= 6 then
		local keys = {}
		for k = 0, 6 do
			table.insert(keys, ColorSequenceKeypoint.new(k / 6, Color3.fromHSV(k / 6, 0.8, 1)))
		end
		bannerGradient = UI.new("UIGradient", { Color = ColorSequence.new(keys), Parent = banner })
	end
	if tier >= 5 then
		table.insert(updaters, function(now)
			if not banner.Parent then
				return false
			end
			banner.Rotation = math.sin(now * 6) * 4
			if bannerGradient then
				bannerGradient.Offset = Vector2.new(math.sin(now * 2) * 0.5, 0)
			end
			return true
		end)
	end
	local newLabel = nil
	if result.isNew then
		newLabel = UI.label("NEW FREEK!", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.15, 60 + tier * 4),
			Size = UDim2.fromOffset(300, 36),
			FontFace = UI.fonts.heavy,
			TextColor3 = Color3.fromRGB(255, 215, 60),
			ZIndex = 72,
			Parent = gui,
		})
	end

	-- 4. The Freek jumps out and lands where the egg was, facing the camera.
	local freek, freekHeight = FreekModel.build(result.freek.species, result.freek.mutations)
	for _, part in freek:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
		end
	end
	freek.Parent = folder
	cameraBase = cameraAt(0, 11, 4.5)
	local face = CFrame.lookAt(ground, Vector3.new(cameraBase.Position.X, groundY, cameraBase.Position.Z))
	local function setScale(scale: number)
		pcall(function()
			freek:ScaleTo(scale)
		end)
	end
	local airY = burstAt.Y - 2 - groundY
	animate(0.55, function(a)
		local y = airY * (1 - a) + math.sin(a * math.pi) * 3
		setScale(0.2 + 0.8 * math.min(a / 0.6, 1))
		freek:PivotTo(face * CFrame.new(0, y, 0) * CFrame.Angles(0, (1 - a) * math.pi * 2, 0))
	end)
	setScale(1)
	puff(ground, 6, 0.9)

	local tag = UI.new("BillboardGui", {
		Size = UDim2.fromOffset(260, 60),
		StudsOffsetWorldSpace = Vector3.new(0, 1, 0),
		AlwaysOnTop = true,
		LightInfluence = 0,
		Parent = freek.PrimaryPart,
	})
	if freek.PrimaryPart then
		tag.StudsOffsetWorldSpace = Vector3.new(0, groundY + freekHeight + 1.2 - freek.PrimaryPart.Position.Y, 0)
	end
	UI.label(rarity, {
		Size = UDim2.new(1, 0, 0.4, 0),
		FontFace = UI.fonts.heavy,
		TextColor3 = color,
		Parent = tag,
	})
	UI.label(FreekUtil.displayName(result.freek), {
		Position = UDim2.fromScale(0, 0.4),
		Size = UDim2.new(1, 0, 0.6, 0),
		FontFace = UI.fonts.heavy,
		TextColor3 = Color3.new(1, 1, 1),
		Parent = tag,
	})

	-- 5. Show it off: happy hops, and for Legendary+ the camera circles round.
	local showcase = 1.4 + tier * 0.3
	local orbit = if tier >= 4 then math.rad(25 + tier * 8) else 0
	local closeDistance = math.max(8, freekHeight * 1.9)
	local closeHeight = freekHeight * 0.5 + 1.5
	local closeFocus = freekHeight * 0.6 + 0.5
	animate(showcase, function(a, t)
		local e = easeOut(math.min(a * 1.6, 1))
		beamFade = math.min(a * 2.5, 1)
		cameraBase = cameraAt(
			orbit * math.sin(a * math.pi * 0.5),
			11 + (closeDistance - 11) * e,
			4.5 + (closeHeight - 4.5) * e,
			2.5 + (closeFocus - 2.5) * e
		)
		-- Keep facing the camera as it circles round.
		local look = Vector3.new(cameraBase.Position.X, groundY, cameraBase.Position.Z)
		local hop = math.abs(math.sin(t * math.pi * 2.2)) * 0.8 * (1 - a)
		freek:PivotTo(CFrame.lookAt(ground, look) * CFrame.new(0, hop, 0))
	end)

	local cleaned = false
	local function cleanup()
		if cleaned then
			return
		end
		cleaned = true
		table.clear(updaters)
		folder:Destroy()
		banner:Destroy()
		if newLabel then
			newLabel:Destroy()
		end
		if darkness then
			local fade = TweenService:Create(darkness, TweenInfo.new(0.6), {
				Brightness = 0,
				Contrast = 0,
				TintColor = Color3.new(1, 1, 1),
			})
			fade:Play()
			task.delay(0.6, darkness.Destroy, darkness)
		end
		camera.CameraType = if oldCameraType == Enum.CameraType.Scriptable
			then Enum.CameraType.Custom
			else oldCameraType
		if controls then
			controls:Enable()
		end
	end
	-- Keep beams and particles going behind the prize card.
	task.spawn(function()
		while not cleaned do
			step()
			task.wait()
		end
	end)
	showPrize(cleanup)
	return true
end

return Hatch
