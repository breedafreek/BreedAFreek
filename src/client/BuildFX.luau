-- Plays the build animation (BuildAnim.luau) on this client whenever someone's house or yard
-- is upgraded: the server rebuilds the home and bumps the plot's "BuildAnim" attribute (with
-- "BuildKind" = "House" or "Yard"); every client then hides the new pieces and drops them in
-- piece by piece, with dust puffs, a flash, a shockwave ring and sparkles. Only this client's
-- view moves: the server's parts stay where they belong.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BuildAnim = require(ReplicatedStorage.Shared.BuildAnim)

local BuildFX = {}

local YARD_PARTS = { Pad = true, PadRim = true, Soil = true, BedRim = true }

local running = {} -- [plot folder] = stop()

-- The parts to build and the middle of the build on the ground.
local function gather(folder: Instance, kind: string): ({ BasePart }, Vector3, Instance?)
	local parts = {}
	local house = folder:FindFirstChild("House")
	local function add(root: Instance?)
		for _, d in (if root then root:GetDescendants() else {}) do
			if d:IsA("BasePart") then
				table.insert(parts, d)
			end
		end
	end
	if kind == "House" then
		for _, child in (if house then house:GetChildren() else {}) do
			if child.Name ~= "Fence" then
				add(child)
			end
		end
	else
		add(house and house:FindFirstChild("Fence"))
		add(folder:FindFirstChild("Items"))
		for _, d in folder:GetDescendants() do
			if d:IsA("BasePart") and YARD_PARTS[d.Name] then
				table.insert(parts, d)
			end
		end
	end
	local min, max = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, p in parts do
		min = min:Min(p.CFrame.Position)
		max = max:Max(p.CFrame.Position)
	end
	local center = if #parts > 0 then Vector3.new((min.X + max.X) / 2, 0.5, (min.Z + max.Z) / 2) else Vector3.zero
	return parts, center, house
end

local function play(folder: Instance)
	local kind = folder:GetAttribute("BuildKind") or "House"
	if running[folder] then
		running[folder]()
	end
	local parts, center, house = gather(folder, kind)
	if #parts == 0 then
		return
	end
	local plan = BuildAnim.plan(parts, center, kind, house)
	local effectsFolder = Instance.new("Folder")
	effectsFolder.Name = "BuildFX"
	effectsFolder.Parent = Workspace
	local pool = {}
	local function effectPart(i: number, shape: string): Part
		local p = pool[i]
		if not p or p:GetAttribute("Shape") ~= shape then
			if p then
				p:Destroy()
			end
			p = Instance.new("Part")
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Material = Enum.Material.Neon
			p.Shape = if shape == "Ball" then Enum.PartType.Ball else Enum.PartType.Block
			p:SetAttribute("Shape", shape)
			p.Parent = effectsFolder
			pool[i] = p
		end
		return p
	end
	-- Split pieces of long parts are drawn by temporary copies; the real part stays hidden
	-- until the end.
	local hidden = {}
	for _, entry in plan.entries do
		if entry.split then
			local copy = entry.part:Clone()
			copy:ClearAllChildren()
			copy.Size = entry.size
			copy.Anchored = true
			copy.CanCollide = false
			copy.CanQuery = false
			copy.Parent = effectsFolder
			entry.instance = copy
			hidden[entry.part] = true
		else
			entry.instance = entry.part
		end
	end
	for part in hidden do
		part.LocalTransparencyModifier = 1
	end
	local started = os.clock()
	local connection
	local function finish()
		connection:Disconnect()
		running[folder] = nil
		for _, entry in plan.entries do
			if not entry.split and entry.part.Parent then
				entry.part.CFrame = entry.target
			end
			if entry.part.Parent then
				entry.part.LocalTransparencyModifier = 0
			end
		end
		effectsFolder:Destroy()
	end
	running[folder] = finish
	local function step()
		local t = os.clock() - started
		if t >= plan.duration then
			finish()
			return
		end
		for _, entry in plan.entries do
			if entry.part.Parent then
				local cf, shown = BuildAnim.pose(plan, entry, t)
				entry.instance.CFrame = cf
				entry.instance.LocalTransparencyModifier = if shown then 0 else 1
			end
		end
		local effects = BuildAnim.effects(plan, t)
		for i, e in effects do
			local p = effectPart(i, e.shape)
			p.Size = e.size
			p.CFrame = e.cframe
			p.Color = e.color
			p.Transparency = e.transparency
		end
		for i = #effects + 1, #pool do
			pool[i].Transparency = 1
		end
	end
	connection = RunService.RenderStepped:Connect(step)
	step()
end

local function watch(folder: Instance)
	folder:GetAttributeChangedSignal("BuildAnim"):Connect(function()
		play(folder)
	end)
end

function BuildFX.start()
	local plots = Workspace:WaitForChild("Plots")
	for _, folder in plots:GetChildren() do
		watch(folder)
	end
	plots.ChildAdded:Connect(watch)
end

return BuildFX
