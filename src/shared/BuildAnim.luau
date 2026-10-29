-- The build animation when someone upgrades their house or yard: the new pieces drop out of
-- the sky one cluster at a time, working their way up and around, each landing with a little
-- bounce and a puff of dust; then a white flash, a glowing shockwave ring across the yard and
-- a burst of sparkles.
--
-- Everything is worked out from the time alone, so the client (BuildFX) and the offline video
-- renderer draw exactly the same frames:
--   local plan = BuildAnim.plan(parts, center, kind)   -- once ("House" or "Yard")
--   plan.entries = { { part, target, size, split, cluster } }: one per piece. Long blocks
--     (fence rails, beams) are split into short segments (split = true) that drop in one
--     after another; the client draws those as temporary copies of the part (at `size`)
--     and keeps the real part hidden until the end.
--   BuildAnim.pose(plan, entry, t)  -> the piece's CFrame and whether it's shown yet
--   BuildAnim.effects(plan, t)      -> the effect pieces to draw at time t
--   plan.duration                    -- when it's all over

local BuildAnim = {}

local DROP_TIME = 0.5 -- seconds from the sky to the ground (and the bounce)
local DROP_HEIGHT = 16 -- studs above its spot a piece starts

-- Which house pieces go first (the rest come after, in any order).
local SLOT_ORDER = { Walls = 1, Door = 2, Windows = 2, Porch = 3, Roof = 4, Chimney = 5, Tower = 5 }

-- The slot a part belongs to: the name of its top model under the house (or nil).
local function slotOf(part: BasePart, root: Instance?): string?
	local node = part
	while node and node.Parent and node.Parent ~= root do
		node = node.Parent
	end
	return node and node.Name
end

local function hash(n: number): number
	return (math.sin(n * 12.9898) * 43758.5453) % 1
end

local SEGMENT = 6 -- long blocks are split into segments about this long

-- The pieces to drop: every part, with long plain blocks cut into segments.
local function pieces(parts: { BasePart })
	local list = {}
	for _, part in parts do
		local size = part.Size
		local long = math.max(size.X, size.Y, size.Z)
		local plain = part.ClassName == "Part" and part.Shape == Enum.PartType.Block
		if plain and long > SEGMENT * 1.6 then
			local n = math.ceil(long / SEGMENT)
			local axis = if long == size.X then Vector3.xAxis elseif long == size.Z then Vector3.zAxis else Vector3.yAxis
			local piece = size - axis * long + axis * (long / n)
			for k = 0, n - 1 do
				local along = (k + 0.5) / n * long - long / 2
				table.insert(
					list,
					{ part = part, cframe = part.CFrame * CFrame.new(axis * along), size = piece, split = true }
				)
			end
		else
			table.insert(list, { part = part, cframe = part.CFrame, size = size, split = false })
		end
	end
	return list
end

-- parts = the BaseParts to build (their CFrames now are where they belong); center = the
-- middle of the house or yard on the ground; root = the model the slots hang off (the house).
function BuildAnim.plan(parts: { BasePart }, center: Vector3, kind: string, root: Instance?)
	-- Group parts into clusters ("pieces"): same slot, same layer, same slice round the
	-- centre. Clusters drop one after another.
	local clusters = {}
	local byKey = {}
	local sectors = if kind == "Yard" then 48 else 14
	for _, piece in pieces(parts) do
		local part = piece.part
		local position = piece.cframe.Position
		local offset = position - center
		local angle = math.atan2(offset.X, -offset.Z) -- 0 straight ahead, going clockwise
		local sector = math.floor(((angle / (2 * math.pi)) % 1) * sectors)
		local layer = if kind == "Yard" then 0 else math.floor(position.Y / 1.6)
		local slot = if kind == "Yard" then "Yard" else (slotOf(part, root) or "Walls")
		local key = slot .. ":" .. layer .. ":" .. sector
		local cluster = byKey[key]
		if not cluster then
			cluster = {
				slot = slot,
				order = SLOT_ORDER[slot] or 6,
				layer = layer,
				sector = sector,
				pieces = {},
				low = math.huge,
				sum = Vector3.zero,
			}
			byKey[key] = cluster
			table.insert(clusters, cluster)
		end
		table.insert(cluster.pieces, piece)
		cluster.low = math.min(cluster.low, position.Y - piece.size.Y / 2)
		cluster.sum += position
		cluster.long = math.max(cluster.long or 0, piece.size.X, piece.size.Y, piece.size.Z)
	end
	table.sort(clusters, function(a, b)
		if a.order ~= b.order then
			return a.order < b.order
		elseif a.layer ~= b.layer then
			return a.layer < b.layer
		end
		return a.sector < b.sector
	end)
	-- Spread them over a few seconds: quick enough to stay exciting, slow enough to see
	-- every piece land.
	local span = math.clamp(#clusters * 0.06, 1.6, if kind == "Yard" then 4.2 else 4.6)
	local plan = { entries = {}, clusters = clusters, center = center, kind = kind }
	for i, cluster in clusters do
		cluster.start = (i - 1) / math.max(#clusters - 1, 1) * span
		cluster.land = cluster.start + DROP_TIME * 0.7
		cluster.middle = cluster.sum / #cluster.pieces
		-- A little tumble on the way down; long pieces (fence rails, roof planks) barely
		-- tilt, so they come down level instead of swinging round.
		local seed = i * 7.31
		local amount = math.clamp(5 / cluster.long, 0.12, 1)
		cluster.tilt = CFrame.Angles(
			(hash(seed) - 0.5) * 0.9 * amount,
			(hash(seed + 1) - 0.5) * 1.2 * amount,
			(hash(seed + 2) - 0.5) * 0.9 * amount
		)
		for _, piece in cluster.pieces do
			table.insert(plan.entries, {
				part = piece.part,
				target = piece.cframe,
				size = piece.size,
				split = piece.split,
				cluster = cluster,
			})
		end
	end
	plan.finale = span + DROP_TIME + 0.1
	plan.duration = plan.finale + 1.6
	return plan
end

-- Where a part is at time t, and whether it's visible yet.
function BuildAnim.pose(_plan, entry, t: number): (CFrame, boolean)
	local cluster = entry.cluster
	local p = (t - cluster.start) / DROP_TIME
	if p <= 0 then
		return entry.target * CFrame.new(0, DROP_HEIGHT, 0), false
	elseif p >= 1 then
		return entry.target, true
	end
	-- Falling (speeding up) for the first 70%, then a little bounce that settles.
	local lift, spin
	if p < 0.7 then
		local f = p / 0.7
		lift = DROP_HEIGHT * (1 - f * f)
		spin = 1 - f
	else
		local f = (p - 0.7) / 0.3
		lift = math.sin(f * math.pi) * 0.9 * (1 - f * 0.5)
		spin = 0
	end
	-- Turn round the cluster's middle, so a piece tumbles in as one.
	local pivot = CFrame.new(cluster.middle)
	local tilt = CFrame.new():Lerp(cluster.tilt, spin)
	local placed = pivot * tilt * pivot:Inverse() * entry.target
	return CFrame.new(0, lift, 0) * placed, true
end

-- The effect pieces at time t: { { shape, size, cframe, color, transparency } }.
local WHITE = Color3.fromRGB(255, 255, 255)
local GLOW = Color3.fromRGB(150, 235, 255)
local GOLD = Color3.fromRGB(255, 215, 90)
function BuildAnim.effects(plan, t: number)
	local out = {}
	-- A puff of dust where each piece lands: little white cubes rushing out and fading.
	for i, cluster in plan.clusters do
		local age = t - cluster.land
		if age >= 0 and age < 0.4 then
			local f = age / 0.4
			for k = 0, 5 do
				local a = k / 6 * math.pi * 2 + i
				local r = 0.6 + f * 2.6
				local s = 0.7 * (1 - f) + 0.15
				table.insert(out, {
					shape = "Block",
					size = Vector3.one * s,
					cframe = CFrame.new(
						cluster.middle.X + math.cos(a) * r,
						cluster.low + 0.3 + f * 0.8,
						cluster.middle.Z + math.sin(a) * r
					) * CFrame.Angles(a, a, 0),
					color = WHITE,
					transparency = 0.2 + f * 0.8,
				})
			end
		end
	end
	-- The finale: a white flash, a glowing shockwave ring and sparkles flying up.
	local age = t - plan.finale
	if age >= 0 then
		local center = plan.center
		if age < 0.5 then
			local f = age / 0.5
			table.insert(out, {
				shape = "Ball",
				size = Vector3.one * (8 + f * (if plan.kind == "Yard" then 70 else 50)),
				cframe = CFrame.new(center + Vector3.new(0, 4, 0)),
				color = WHITE,
				transparency = 0.35 + f * 0.65,
			})
		end
		if age < 1.0 then
			local f = age / 1.0
			local ease = 1 - (1 - f) ^ 3
			local r = 4 + ease * (if plan.kind == "Yard" then 62 else 48)
			local n = 36
			for k = 0, n - 1 do
				local a = k / n * math.pi * 2
				table.insert(out, {
					shape = "Block",
					size = Vector3.new(2 * math.pi * r / n + 0.3, 2.2 * (1 - f) + 0.4, 2.4 * (1 - f) + 0.8),
					cframe = CFrame.new(center + Vector3.new(math.cos(a) * r, 0.9, math.sin(a) * r))
						* CFrame.Angles(0, -a + math.pi / 2, 0),
					color = GLOW,
					transparency = f * f,
				})
			end
		end
		if age < 1.5 then
			local f = age / 1.5
			for k = 0, 23 do
				local a = k * 2.399
				local speed = 12 + hash(k) * 10
				local up = 22 + hash(k + 50) * 14
				local x = math.cos(a) * speed * age
				local z = math.sin(a) * speed * age
				local y = 6 + up * age - 30 * age * age
				local s = 0.9 * (1 - f) + 0.2
				table.insert(out, {
					shape = "Block",
					size = Vector3.one * s,
					cframe = CFrame.new(center + Vector3.new(x, math.max(y, 0.5), z))
						* CFrame.Angles(age * 6, age * 4 + k, 0),
					color = if k % 3 == 0 then GOLD else if k % 3 == 1 then WHITE else GLOW,
					transparency = f,
				})
			end
		end
	end
	return out
end

return BuildAnim
