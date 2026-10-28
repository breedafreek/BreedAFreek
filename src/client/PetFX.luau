-- Pets roaming their owner's front lawn, drawn on this client. The server lists each
-- home's pets on its plot (attribute "Pets" = "Pet_Oinkle:Golden:4.21:1.62,..." with each
-- pet's mutation, weight in kg and how big to draw it); this
-- builds a Freek for each and wanders it round the lawn (plot attributes PetMin / PetMax,
-- in plot space), animated with FreekAnimator: walk somewhere, stop, look about, walk on.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local FreekAnimator = require(ReplicatedStorage.Shared.FreekAnimator)
local ItemModel = require(ReplicatedStorage.Shared.ItemModel)
local Items = require(ReplicatedStorage.Shared.Items)
local Lego = require(ReplicatedStorage.Shared.Lego)

local PetFX = {}

local SCALE = 1.5
local WALK_SPEED = 6
local GROUND_Y = 0.4 -- the lawn's top
local OUTLINE = Color3.fromRGB(20, 22, 48)

local rng = Random.new()
local homes = {} -- [plot Model] = { key, pets = { { model, rig, position, goal, yaw, restUntil } } }

local function nameTag(model: Model, text: string, color: Color3, height: number)
	local anchor = model.PrimaryPart
	if not anchor then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(5, 1.1)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height + 1.2, 0)
	gui.MaxDistance = 24
	gui.LightInfluence = 0
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = color
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE
	stroke.Thickness = 2.5
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
end

-- A Freek, scaled up round its feet (more for heavier pets).
local function build(itemId: string, mutation: string?, weightScale: number): (Model, number)
	local model = ItemModel.buildNormal(itemId, if mutation ~= "" then mutation else nil)
	Items.scaleModel(model, SCALE * weightScale) -- (keeps the pivot at its feet)
	local pivot = model:GetPivot()
	local top = 0
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			top = math.max(top, pivot:PointToObjectSpace(p.Position).Y + p.Size.Y / 2)
		end
	end
	Lego.apply(model)
	return model, top
end

local function randomSpot(plot: Model): Vector3
	local origin = plot:GetAttribute("Origin")
	local lo, hi = plot:GetAttribute("PetMin"), plot:GetAttribute("PetMax")
	if typeof(origin) ~= "CFrame" or typeof(lo) ~= "Vector3" or typeof(hi) ~= "Vector3" then
		return Vector3.zero
	end
	local x = rng:NextNumber(lo.X, hi.X)
	local z = rng:NextNumber(lo.Z, hi.Z)
	local world = origin:PointToWorldSpace(Vector3.new(x, 0, z))
	return Vector3.new(world.X, GROUND_Y, world.Z)
end

local function clear(home)
	for _, pet in home.pets do
		pet.model:Destroy()
	end
	table.clear(home.pets)
end

local function refresh(plot: Model)
	local list = plot:GetAttribute("Pets")
	local home = homes[plot]
	if not home then
		home = { key = nil, pets = {} }
		homes[plot] = home
	end
	if home.key == list then
		return
	end
	home.key = list
	clear(home)
	if typeof(list) ~= "string" or list == "" then
		return
	end
	for i, entry in string.split(list, ",") do
		local parts = string.split(entry, ":")
		local itemId, mutation = parts[1], parts[2] or ""
		local weight, weightScale = tonumber(parts[3] or ""), tonumber(parts[4] or "") or 1
		local info = itemId and Items.byId[itemId]
		if info and info.kind == "Pet" then
			local model, height = build(itemId, mutation, weightScale)
			local position = randomSpot(plot)
			local yaw = rng:NextNumber(0, math.pi * 2)
			local ground = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
			model:PivotTo(ground)
			model.Name = "Pet_" .. info.species
			model.Parent = plot
			local title = (if mutation ~= "" then mutation .. " " else "")
				.. info.name
				.. (if weight then " · " .. Format.weight(weight) else "")
			nameTag(model, title, Items.color(itemId), height)
			table.insert(home.pets, {
				model = model,
				rig = FreekAnimator.rig(model, i * 13 + #list, ground),
				position = position,
				goal = position,
				yaw = yaw,
				restUntil = os.clock() + rng:NextNumber(0, 3),
			})
		end
	end
end

local function step(dt: number)
	local t = os.clock()
	for plot, home in homes do
		if not plot.Parent then
			clear(home)
			homes[plot] = nil
			continue
		end
		for _, pet in home.pets do
			local offset = pet.goal - pet.position
			local distance = offset.Magnitude
			local walking = distance > 0.3 and t >= pet.restUntil
			if walking then
				pet.position += offset.Unit * math.min(distance, WALK_SPEED * dt)
				local goalYaw = math.atan2(-offset.X, -offset.Z)
				local diff = (goalYaw - pet.yaw + math.pi) % (2 * math.pi) - math.pi
				pet.yaw += diff * math.min(1, dt * 8)
			elseif t >= pet.restUntil then
				-- Arrived: rest a moment, then pick somewhere new.
				pet.restUntil = t + rng:NextNumber(1.5, 5)
				pet.goal = randomSpot(plot)
			end
			local ground = CFrame.new(pet.position) * CFrame.Angles(0, pet.yaw, 0)
			if pet.rig then
				FreekAnimator.pose(pet.rig, ground, t, walking)
			else
				pet.model:PivotTo(ground)
			end
		end
	end
end

local function watch(plot: Instance)
	if not plot:IsA("Model") then
		return
	end
	plot:GetAttributeChangedSignal("Pets"):Connect(function()
		refresh(plot)
	end)
	refresh(plot)
end

function PetFX.start()
	local plots = Workspace:WaitForChild("Plots", 30)
	if not plots then
		return
	end
	for _, plot in plots:GetChildren() do
		watch(plot)
	end
	plots.ChildAdded:Connect(watch)
	RunService.RenderStepped:Connect(step)
end

return PetFX
