-- Brings Freek models to life: idle animations for Freeks standing in barns and on the
-- reveal stage, and walk cycles for Freeks roaming the map.
--
-- Idle, a Freek breathes, blinks, looks around (turning and tilting its head), wags its
-- tail, twitches its ears, flutters its wings, waves now and then, and every so often does
-- a happy hop. Walking, it steps with its own gait (see WALKS): legs and arms swing, the
-- body bobs, rocks and squashes on each footfall, the head nods, ears bounce and the tail
-- sways. Everything is worked out from the time alone, so the same Freek at the same
-- moment always strikes the same pose, and a renderer can draw any frame.
--
-- FreekModel tags the parts that move: SwingHinge (legs, arms, tails, wings), OnHead,
-- Eye/EyeWhite, and Rig = "ear" | "arm".
--
-- Usage:
--   local rig = FreekAnimator.rig(model)          -- once per model
--   FreekAnimator.pose(rig, groundCFrame, t)       -- every frame, idle
--   FreekAnimator.pose(rig, groundCFrame, t, true) -- every frame, walking

local Workspace = game:GetService("Workspace")

local FreekAnimator = {}

-- How each kind of Freek walks: steps per second (speed, radians), how high it bobs, how
-- much it rocks side to side (roll) and turns from side to side (yaw), and how far its legs
-- swing (degrees); plus how much it leans forward, nods its head and squashes on each step.
-- Set per species with `walk` in Freeks.luau.
FreekAnimator.WALKS = {
	waddle = { speed = 9, bob = 0.25, roll = 7, yaw = 0, legs = 30, lean = 3, nod = 5, squash = 0.05 },
	trot = { speed = 12, bob = 0.35, roll = 3, yaw = 0, legs = 35, lean = 5, nod = 7, squash = 0.04 },
	prowl = { speed = 8, bob = 0.08, roll = 2, yaw = 4, legs = 28, lean = 2, nod = 3, squash = 0.02 },
	slither = { speed = 9, bob = 0, roll = 0, yaw = 10, legs = 40, lean = 0, nod = 2, squash = 0.02 },
	stomp = { speed = 6, bob = 0.35, roll = 4, yaw = 0, legs = 25, lean = 4, nod = 6, squash = 0.07 },
	flap = { speed = 9, bob = 0.5, roll = 8, yaw = 0, legs = 30, lean = 6, nod = 6, squash = 0.04 },
	bounce = { speed = 7, bob = 1, roll = 6, yaw = 0, legs = 30, lean = 0, nod = 4, squash = 0.12, hop = true },
	strut = { speed = 10, bob = 0.25, roll = 2, yaw = 5, legs = 35, lean = -2, nod = 6, squash = 0.03 },
	catwalk = { speed = 9, bob = 0.15, roll = 0, yaw = 9, legs = 30, lean = -3, nod = 3, squash = 0.02 },
	shamble = { speed = 5, bob = 0.15, roll = 9, yaw = 3, legs = 22, lean = 9, nod = 10, squash = 0.03 },
	float = { speed = 3, bob = 0.7, roll = 4, yaw = 0, legs = 30, lean = 4, nod = 3, squash = 0, float = true },
}

local TAU = math.pi * 2

local function axisRotation(axis: string, angle: number): CFrame
	if axis == "Y" then
		return CFrame.Angles(0, angle, 0)
	elseif axis == "Z" then
		return CFrame.Angles(0, 0, angle)
	end
	return CFrame.Angles(angle, 0, 0)
end

-- A repeatable pseudo-random number in [0, 1) for a whole number n and a Freek's seed.
local function hash(n: number, seed: number): number
	local x = math.sin(n * 127.1 + seed * 311.7) * 43758.5453
	return x - math.floor(x)
end

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- A short event that happens every `period` seconds (shifted by `shift`) and lasts
-- `length`: returns how far through it we are (0..1), or nil between events.
local function event(t: number, period: number, length: number, shift: number): number?
	local into = (t + shift) % period
	if into < length then
		return into / length
	end
	return nil
end

export type Rig = {
	model: Model,
	walk: any,
	seed: number,
	parts: { BasePart },
	rest: { CFrame },
	sizes: { Vector3 },
	moves: { any },
	neck: CFrame?,
	eyes: { any },
	body: BasePart?,
	bodyIndex: number,
	hasHead: boolean,
	blinking: boolean,
	squashed: boolean,
}

-- Collects what moves on a model. Returns nil for a model with no parts.
function FreekAnimator.rig(model: Model, seed: number?): Rig?
	if not model.PrimaryPart then
		return nil
	end
	local pivot = model:GetPivot()
	local rig = {
		model = model,
		walk = FreekAnimator.WALKS[model:GetAttribute("Walk")] or FreekAnimator.WALKS.waddle,
		seed = 0,
		parts = {},
		rest = {},
		sizes = {},
		moves = {},
		eyes = {},
		body = model.PrimaryPart,
		bodyIndex = 1,
		hasHead = false,
		blinking = false,
		squashed = false,
	}
	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		-- The head turns about the bottom of the neck, a little behind its centre.
		local radius = math.max(head.Size.X, head.Size.Y, head.Size.Z) / 2
		local center = pivot:PointToObjectSpace(head.CFrame.Position)
		rig.neck = CFrame.new(center + Vector3.new(0, -radius * 0.8, radius * 0.25))
		rig.hasHead = true
	end
	local eyeIndex = {}
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		table.insert(rig.parts, part)
		local i = #rig.parts
		rig.rest[i] = pivot:ToObjectSpace(part.CFrame)
		rig.sizes[i] = part.Size
		if part == rig.body then
			rig.bodyIndex = i
		end
		local move = {}
		local hinge = part:GetAttribute("SwingHinge")
		if typeof(hinge) == "Vector3" then
			local axis = part:GetAttribute("SwingAxis") or "X"
			move.hinge = CFrame.new(hinge)
			move.phase = (part:GetAttribute("SwingPhase") or 0) * TAU
			move.axis = axis
			move.amount = part:GetAttribute("SwingAmount") or 1
			move.kind = if axis == "Y" then "tail" elseif axis == "Z" then "wing" else "leg"
		end
		local role = part:GetAttribute("Rig")
		if role == "arm" then
			move.kind = "arm"
			move.side = part:GetAttribute("RigSide") or 1
		elseif role == "ear" then
			local point = part:GetAttribute("RigPivot")
			move.ear = CFrame.new(if typeof(point) == "Vector3" then point else rig.rest[i].Position)
			move.side = part:GetAttribute("RigSide") or 1
		end
		move.onHead = rig.hasHead and part:GetAttribute("OnHead") == true
		local eye = part:GetAttribute("Eye")
		if eye then
			local group = eyeIndex[eye]
			if not group then
				group = { members = {} }
				eyeIndex[eye] = group
				table.insert(rig.eyes, group)
			end
			table.insert(group.members, i)
			if part:GetAttribute("EyeWhite") then
				group.white = i
			end
		end
		rig.moves[i] = move
	end
	for _, group in rig.eyes do
		local white = group.white or group.members[1]
		local rest, size = rig.rest[white], rig.sizes[white]
		-- Eyes close toward a line a little below their middle, like lids coming down.
		group.center = rest.Position - Vector3.new(0, size.Y * 0.12, 0)
	end
	rig.seed = seed or (model:GetAttribute("Seed") or (pivot.Position.X * 0.37 + pivot.Position.Z * 0.61))
	rig.seed = (rig.seed % 97) / 97
	return rig :: any
end

-- How open the eyes are (1 open, 0 shut) at time t.
local function eyesOpen(t: number, seed: number): number
	local period = 2.6 + seed * 2.4
	local cycle = math.floor((t + seed * 10) / period)
	local into = (t + seed * 10) % period
	local open = 1
	local blink = 0.16
	if into < blink then
		open = 1 - math.sin(into / blink * math.pi)
	elseif hash(cycle, seed) < 0.3 and into > 0.24 and into < 0.24 + blink then
		-- Sometimes a quick double blink.
		open = 1 - math.sin((into - 0.24) / blink * math.pi)
	end
	return open
end

-- Where the head is looking at time t: yaw, pitch, roll (radians). It glances somewhere,
-- holds it, then glances somewhere else; now and then it tilts its head, curious.
local function headLook(t: number, seed: number): (number, number, number)
	local hold = 2.2 + seed * 1.3
	local shifted = t + seed * 7
	local index = math.floor(shifted / hold)
	local into = shifted % hold
	local function target(n: number)
		local yaw = (hash(n, seed) - 0.5) * math.rad(46)
		local pitch = (hash(n + 0.5, seed) - 0.4) * math.rad(18)
		local roll = if hash(n + 0.25, seed) < 0.3 then (hash(n + 0.75, seed) - 0.5) * math.rad(36) else 0
		if hash(n + 0.9, seed) < 0.25 then
			yaw, pitch = 0, -math.rad(4) -- looking straight at you
		end
		return yaw, pitch, roll
	end
	local y0, p0, r0 = target(index - 1)
	local y1, p1, r1 = target(index)
	local a = smooth(into / 0.45)
	return y0 + (y1 - y0) * a, p0 + (p1 - p0) * a, r0 + (r1 - r0) * a
end

-- Works out the pose for time t and moves the model there, standing at `ground`.
function FreekAnimator.pose(rig: Rig, ground: CFrame, t: number, walking: boolean?)
	local walk = rig.walk
	local seed = rig.seed
	t += seed * 31

	-- The whole body: bob, rock, lean, hop, and squash (sy up, sx out to the sides).
	local root = CFrame.identity
	local sy = 0
	local stepAngle = 0
	local yaw, pitch, roll = 0, 0, 0 -- the head
	local earAngle = 0
	local tailAngle, tailSpeed = 0, 0
	local wingAngle = 0
	local armWave = 0 -- 0..1, how far the waving arm is raised
	local hopping = false

	if walking then
		stepAngle = t * walk.speed
		local step = math.sin(stepAngle)
		local footfall = math.abs(math.cos(stepAngle)) -- 1 as a foot lands
		local lift = math.abs(step) * walk.bob
		root = CFrame.new(0, lift, 0)
			* CFrame.Angles(math.rad(-walk.lean), math.rad(step * walk.yaw), math.rad(step * walk.roll))
		if walk.float then
			root = CFrame.new(0, 0.6 + math.sin(t * 2) * 0.35, 0)
				* CFrame.Angles(math.rad(-walk.lean), 0, math.rad(math.sin(t * 1.5) * walk.roll))
		end
		sy = -footfall ^ 6 * walk.squash + (if walk.hop then math.abs(step) * walk.squash * 0.6 else 0)
		pitch = math.sin(stepAngle * 2) * math.rad(walk.nod)
		yaw = math.sin(t * 0.7 + seed * 5) * math.rad(10)
		earAngle = math.sin(stepAngle * 2 + 0.6) * math.rad(10)
		tailAngle, tailSpeed = math.rad(18), walk.speed
	else
		-- Breathing: a slow swell of the chest.
		local breath = math.sin(t * 2.2)
		sy = breath * 0.022
		-- A gentle sway from foot to foot.
		root = CFrame.Angles(0, math.sin(t * 0.5) * math.rad(4), math.sin(t * 1.1) * math.rad(1.5))
		if walk.float then
			root = CFrame.new(0, 0.6 + math.sin(t * 1.6) * 0.35, 0) * root
		end

		yaw, pitch, roll = headLook(t, seed)

		-- A happy hop every so often: crouch, spring up with a little spin, land and squash.
		local hop = event(t, 9 + seed * 5, 1.1, seed * 13)
		if hop then
			hopping = true
			if hop < 0.2 then
				sy = -smooth(hop / 0.2) * 0.12
			elseif hop < 0.75 then
				local air = (hop - 0.2) / 0.55
				root = CFrame.new(0, math.sin(air * math.pi) * 1.4, 0) * root
				sy = 0.1 * math.sin(air * math.pi)
				pitch -= math.rad(10)
			else
				local land = (hop - 0.75) / 0.25
				sy = -math.sin(land * math.pi) * 0.1
			end
		end

		-- Tail: always wagging a little, sometimes really going for it.
		local excited = event(t, 6 + seed * 4, 2.2, seed * 3)
		tailAngle = math.rad(10 + (if excited then math.sin(excited * math.pi) * 22 else 0))
		tailSpeed = if excited then 11 else 3

		-- Ears: a quick double flick now and then.
		local twitch = event(t, 4.5 + seed * 3, 0.45, seed * 17)
		if twitch then
			earAngle = math.sin(twitch * TAU * 2) * math.rad(18) * (1 - twitch)
		else
			earAngle = math.sin(t * 1.3) * math.rad(2)
		end

		-- Wings and flippers: a flutter now and then (and on every hop).
		local flutter = event(t, 7 + seed * 3, 0.9, seed * 23)
		if flutter or hopping then
			wingAngle = math.abs(math.sin(t * 22)) * math.rad(30)
		else
			wingAngle = (math.sin(t * 2.2) + 1) * math.rad(2)
		end

		-- A wave hello.
		local wave = event(t, 11 + seed * 6, 2.4, seed * 41)
		if wave then
			armWave = smooth(wave / 0.2) * smooth((1 - wave) / 0.2)
		end
		if hopping then
			armWave = math.max(armWave, 0.95) -- arms up: yay!
		end
	end

	local headTurn = rig.neck and (rig.neck * CFrame.fromOrientation(pitch, yaw, roll) * rig.neck:Inverse())
	local legSwing = math.rad(walk.legs)
	local base = ground * root
	local sx = -sy * 0.5
	local waveSide = if seed < 0.5 then 1 else -1

	local cframes = table.create(#rig.parts)
	for i = 1, #rig.parts do
		local local_ = rig.rest[i]
		local move = rig.moves[i]
		if move.hinge then
			local angle = 0
			if move.kind == "tail" then
				angle = math.sin(t * tailSpeed + move.phase) * tailAngle * move.amount
				if walking then
					angle += math.sin(stepAngle + move.phase) * legSwing * move.amount
				end
			elseif move.kind == "wing" then
				if walking then
					angle = math.sin(stepAngle + move.phase) * legSwing * move.amount
				else
					angle = wingAngle * move.amount
				end
			elseif walking then
				angle = math.sin(stepAngle + move.phase) * legSwing * move.amount
			elseif move.kind == "arm" then
				angle = math.sin(t * 1.2 + move.side) * math.rad(3)
			end
			local swing = move.hinge * axisRotation(move.axis, angle) * move.hinge:Inverse()
			local_ = swing * local_
			if move.kind == "arm" and armWave > 0 and (move.side == waveSide or hopping) then
				-- Raise the arm out to the side and wave the hand back and forth.
				local raise = armWave * math.rad(150) + math.sin(t * 12) * math.rad(18) * armWave
				local shoulder = move.hinge
				local_ = shoulder * CFrame.Angles(0, 0, move.side * raise) * shoulder:Inverse() * local_
			end
		end
		if move.ear then
			local_ = move.ear * CFrame.Angles(0, 0, -move.side * earAngle) * move.ear:Inverse() * local_
		end
		if move.onHead and headTurn then
			local_ = headTurn * local_
		end
		if sy ~= 0 then
			-- Squash and stretch about the feet: everything moves with the body's swell.
			local p = local_.Position
			local_ = local_ + Vector3.new(p.X * sx, p.Y * sy, p.Z * sx * 0.5)
		end
		cframes[i] = base * local_
	end

	-- Eyes squash shut to blink.
	local open = if walking then eyesOpen(t * 1.2, seed) else eyesOpen(t, seed)
	if open < 0.999 or rig.blinking then
		rig.blinking = open < 0.999
		local k = math.max(open, 0.08)
		for _, group in rig.eyes do
			for _, i in group.members do
				local part = rig.parts[i]
				local size = rig.sizes[i]
				part.Size = Vector3.new(size.X, size.Y * k, size.Z)
				-- Move it toward the closing line, in the head's frame.
				local rest = rig.rest[i]
				local offset = rest.Position - group.center
				local shut = CFrame.new(group.center + Vector3.new(offset.X, offset.Y * k, offset.Z)) * rest.Rotation
				local swung = shut
				if rig.moves[i].onHead and headTurn then
					swung = headTurn * swung
				end
				if sy ~= 0 then
					local p = swung.Position
					swung = swung + Vector3.new(p.X * sx, p.Y * sy, p.Z * sx * 0.5)
				end
				cframes[i] = base * swung
			end
		end
	end

	-- The body swells as it breathes.
	if rig.body and sy ~= 0 then
		local size = rig.sizes[rig.bodyIndex]
		rig.body.Size = Vector3.new(size.X * (1 + sx), size.Y * (1 + sy), size.Z * (1 + sx * 0.5))
		rig.squashed = true
	elseif rig.body and rig.squashed then
		rig.body.Size = rig.sizes[rig.bodyIndex]
		rig.squashed = false
	end

	local ok = pcall(function()
		Workspace:BulkMoveTo(rig.parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end)
	if not ok then
		for i, part in rig.parts do
			part.CFrame = cframes[i]
		end
	end
end

return FreekAnimator
