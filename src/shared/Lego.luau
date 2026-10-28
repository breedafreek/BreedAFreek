-- The LEGO look: everything is shiny plastic with studs on every face (inlets underneath),
-- like the classic Roblox bricks. Glowing (Neon), see-through (Glass), gold (Foil) and the
-- gate's force field keep their look, like the special pieces in a real set. Flat things
-- you walk or drive on (roads, sidewalks, paths, the treadmill belt) stay smooth, like
-- LEGO tiles.
--
-- The server applies it to everything in the Workspace as it's built (Lego.watch), and the
-- client to models it builds itself (guardians, pictures). Set ENABLED = false to go back to
-- the smooth cartoon look.

local Lego = {}

Lego.ENABLED = true
Lego.SIDE_STUDS = true -- studs on every face of a brick, not just the top
local MIN_STUD_FACE = 2 -- a face needs to be at least this many studs each way to get studs
-- Round pieces at least this big (their smallest side, in studs) become square bricks, like
-- brick-built LEGO creatures and plants; smaller ones (eyes, noses, buttons) stay round, like
-- LEGO's round pieces. Parts (or models) with the attribute "Round" are left alone (eggs).
local BRICKIFY_MIN = 1.3
local BRICK_FIT = 0.86 -- a brick is this much of the round piece's size, so it doesn't bulge

-- Materials that stay as they are.
local KEEP = {
	[Enum.Material.Neon] = true,
	[Enum.Material.Glass] = true,
	[Enum.Material.Foil] = true,
	[Enum.Material.ForceField] = true,
}

-- The LEGO colours. Every brick is snapped to the nearest one (Lego.snap), so the whole game
-- uses one set of colours like a real LEGO set. Parts with the attribute "AnyColor" keep
-- theirs (the checkerboard floors, which need two close shades).
Lego.PALETTE = {
	Color3.fromRGB(242, 243, 242), -- white
	Color3.fromRGB(160, 165, 169), -- light bluish grey
	Color3.fromRGB(99, 95, 98), -- dark bluish grey
	Color3.fromRGB(33, 33, 38), -- black
	Color3.fromRGB(201, 26, 9), -- bright red
	Color3.fromRGB(120, 32, 30), -- dark red
	Color3.fromRGB(0, 85, 191), -- bright blue
	Color3.fromRGB(10, 52, 99), -- dark blue
	Color3.fromRGB(54, 174, 191), -- medium azure
	Color3.fromRGB(90, 147, 219), -- medium blue
	Color3.fromRGB(159, 195, 233), -- light royal blue
	Color3.fromRGB(242, 205, 55), -- bright yellow
	Color3.fromRGB(255, 240, 160), -- light yellow
	Color3.fromRGB(254, 138, 24), -- bright orange
	Color3.fromRGB(248, 187, 61), -- bright light orange
	Color3.fromRGB(35, 120, 65), -- green
	Color3.fromRGB(75, 159, 74), -- bright green
	Color3.fromRGB(187, 233, 11), -- lime
	Color3.fromRGB(24, 70, 50), -- dark green
	Color3.fromRGB(160, 188, 172), -- sand green
	Color3.fromRGB(228, 205, 158), -- tan
	Color3.fromRGB(149, 138, 115), -- dark tan
	Color3.fromRGB(88, 42, 18), -- reddish brown
	Color3.fromRGB(53, 33, 0), -- dark brown
	Color3.fromRGB(208, 145, 104), -- nougat
	Color3.fromRGB(246, 215, 179), -- light nougat
	Color3.fromRGB(170, 125, 85), -- medium nougat
	Color3.fromRGB(252, 151, 172), -- bright pink
	Color3.fromRGB(200, 112, 160), -- dark pink
	Color3.fromRGB(146, 57, 120), -- magenta
	Color3.fromRGB(205, 164, 222), -- lavender
	Color3.fromRGB(129, 0, 123), -- dark purple
	Color3.fromRGB(104, 92, 165), -- medium lilac
	Color3.fromRGB(255, 128, 110), -- coral
	Color3.fromRGB(169, 85, 0), -- dark orange
	Color3.fromRGB(155, 154, 90), -- olive green
}

local function distance(a: Color3, b: Color3): number
	-- Weighted so the eye's sense of "close" wins over raw numbers.
	local r, g, bl = a.R - b.R, a.G - b.G, a.B - b.B
	return 2 * r * r + 4 * g * g + 3 * bl * bl
end

-- The nearest LEGO colour (and, with skip, the nearest that isn't `skip`).
function Lego.snap(color: Color3, skip: Color3?): Color3
	local best, bestDistance = color, math.huge
	for _, option in Lego.PALETTE do
		local d = distance(color, option)
		if d < bestDistance and option ~= skip then
			best, bestDistance = option, d
		end
	end
	return best
end

-- Ice becomes clear "trans" plastic.
local TRANSLUCENT = {
	[Enum.Material.Ice] = 0.25,
}

-- Parts with these names stay smooth on top (tiles).
local SMOOTH = {
	Road = true,
	RoadLine = true,
	Sidewalk = true,
	Curb = true,
	PathStone = true,
	Belt = true,
	Screen = true,
	NameBoard = true, -- signs with writing on them
	TroughWater = true,
	Seam = true,
}

local function isAvatar(part: BasePart): boolean
	-- Players' own bodies are left alone (but what they carry isn't).
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model.Name == "CarriedPart" then
			return false
		end
		if model:FindFirstChildOfClass("Humanoid") then
			return true
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return false
end

-- True if this part (or a model it's in) is marked to stay round.
local function keepRound(part: BasePart): boolean
	if part:GetAttribute("Round") then
		return true
	end
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:GetAttribute("Round") then
			return true
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return false
end

-- True if this part (or a model it's in) is a "Crafted" model: the detailed low-poly look
-- (eggs, creatures) that keeps its own smooth materials and colours, with no studs.
local function crafted(part: BasePart): boolean
	if part:GetAttribute("Crafted") then
		return true
	end
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:GetAttribute("Crafted") then
			return true
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return false
end

-- Turns a big ball or sphere-meshed part into a square brick of about the same size.
local function brickify(part: BasePart)
	local isBall = part:IsA("Part") and part.Shape == Enum.PartType.Ball
	local mesh = part:FindFirstChildOfClass("SpecialMesh")
	local isSphere = mesh and mesh.MeshType == Enum.MeshType.Sphere
	if not isBall and not isSphere then
		return
	end
	local size = part.Size * (if isSphere then mesh.Scale else Vector3.one)
	if math.min(size.X, size.Y, size.Z) < BRICKIFY_MIN or keepRound(part) then
		return
	end
	local cframe = part.CFrame
	if mesh then
		mesh:Destroy()
	end
	if isBall then
		part.Shape = Enum.PartType.Block
	end
	part.Size = size * BRICK_FIT
	part.CFrame = cframe
end

function Lego.part(part: BasePart)
	if not Lego.ENABLED or part.Transparency >= 1 or part:IsA("Terrain") then
		return
	end
	if KEEP[part.Material] or crafted(part) then
		return
	end
	brickify(part)
	if not part:GetAttribute("AnyColor") then
		part.Color = Lego.snap(part.Color)
	end
	local clear = TRANSLUCENT[part.Material]
	part.Material = Enum.Material.Plastic
	if clear then
		part.Transparency = math.max(part.Transparency, clear)
	end
	local isBlock = part:IsA("Part") and part.Shape == Enum.PartType.Block or part:IsA("SpawnLocation")
	if isBlock and not SMOOTH[part.Name] and not part:FindFirstChildOfClass("SpecialMesh") then
		-- Studs only on faces big enough to hold whole rows of them: on small trims, caps and
		-- panes they'd be cut off at the edges, so those stay smooth like the round pieces.
		local size = part.Size
		local function face(a: number, b: number, kind: Enum.SurfaceType): Enum.SurfaceType
			return if a >= MIN_STUD_FACE and b >= MIN_STUD_FACE then kind else Enum.SurfaceType.Smooth
		end
		part.TopSurface = face(size.X, size.Z, Enum.SurfaceType.Studs)
		part.BottomSurface = face(size.X, size.Z, Enum.SurfaceType.Inlet)
		if Lego.SIDE_STUDS then
			-- The classic Roblox look: the stud texture on the sides as well.
			part.FrontSurface = face(size.X, size.Y, Enum.SurfaceType.Studs)
			part.BackSurface = face(size.X, size.Y, Enum.SurfaceType.Studs)
			part.LeftSurface = face(size.Z, size.Y, Enum.SurfaceType.Studs)
			part.RightSurface = face(size.Z, size.Y, Enum.SurfaceType.Studs)
		end
	end
end

-- Applies the look to everything under `root`.
function Lego.apply(root: Instance)
	if not Lego.ENABLED then
		return
	end
	if root:IsA("BasePart") then
		Lego.part(root)
	end
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") and not isAvatar(descendant) then
			Lego.part(descendant)
		end
	end
end

-- Applies the look to everything under `root` now and to anything added later.
function Lego.watch(root: Instance)
	if not Lego.ENABLED then
		return
	end
	Lego.apply(root)
	root.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			-- Next frame: let whoever built it finish setting its material first.
			task.defer(function()
				if descendant.Parent and not isAvatar(descendant) then
					Lego.part(descendant)
				end
			end)
		end
	end)
end

return Lego
