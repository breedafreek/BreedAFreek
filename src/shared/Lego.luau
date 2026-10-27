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

-- Materials that stay as they are.
local KEEP = {
	[Enum.Material.Neon] = true,
	[Enum.Material.Glass] = true,
	[Enum.Material.Foil] = true,
	[Enum.Material.ForceField] = true,
}

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

function Lego.part(part: BasePart)
	if not Lego.ENABLED or part.Transparency >= 1 or part:IsA("Terrain") then
		return
	end
	if KEEP[part.Material] then
		return
	end
	local clear = TRANSLUCENT[part.Material]
	part.Material = Enum.Material.Plastic
	if clear then
		part.Transparency = math.max(part.Transparency, clear)
	end
	local isBlock = part:IsA("Part") and part.Shape == Enum.PartType.Block or part:IsA("SpawnLocation")
	if isBlock and not SMOOTH[part.Name] and not part:FindFirstChildOfClass("SpecialMesh") then
		part.TopSurface = Enum.SurfaceType.Studs
		part.BottomSurface = Enum.SurfaceType.Inlet
		if Lego.SIDE_STUDS then
			-- The classic Roblox look: the stud texture on the sides as well.
			part.FrontSurface = Enum.SurfaceType.Studs
			part.BackSurface = Enum.SurfaceType.Studs
			part.LeftSurface = Enum.SurfaceType.Studs
			part.RightSurface = Enum.SurfaceType.Studs
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
