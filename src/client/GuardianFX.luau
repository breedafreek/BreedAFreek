-- The zone guardians, drawn on this client: a giant Freek per zone that walks after its
-- target. The server keeps each guardian as plain data on ReplicatedStorage.Guardians
-- (X, Z, Yaw, Moving, Chasing, Speed); this builds the model once, glides it toward the
-- latest position every frame (so it moves smoothly between the server's updates) and
-- animates it walking or idling with FreekAnimator. A name tag shows over its head: 💤 and
-- drifting z's while it sleeps (it dozes, leaning forward and breathing slowly), red and
-- angry while it's chasing someone.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local FreekAnimator = require(ReplicatedStorage.Shared.FreekAnimator)
local FreekModel = require(ReplicatedStorage.Shared.FreekModel)
local Lego = require(ReplicatedStorage.Shared.Lego)

local GuardianFX = {}

local SCALE = 3.4
local OUTLINE = Color3.fromRGB(20, 22, 48)

-- Builds a Freek scaled up round its pivot.
local function giant(species: string): (Model, number)
	local model, height = FreekModel.build(species)
	local pivot = model:GetPivot()
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			local rel = pivot:ToObjectSpace(p.CFrame)
			p.Size *= SCALE
			p.CFrame = pivot * (rel.Rotation + rel.Position * SCALE)
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
		end
	end
	Lego.apply(model)
	return model, height * SCALE
end

local function nameTag(parent: BasePart, title: string, height: number)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(12, 2.4)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height - (parent.Position.Y - 0) + 2, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.LuckiestGuy
	label.Text = string.upper(title)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE
	stroke.Thickness = 3
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	return label
end

local guardians = {} -- [Configuration] = { model, rig, position, yaw, label }

local function add(data: Instance)
	if guardians[data] or not data:IsA("Configuration") then
		return
	end
	local species = data:GetAttribute("Species")
	if typeof(species) ~= "string" then
		return
	end
	local model, height = giant(species)
	local position = Vector3.new(data:GetAttribute("X") or 0, 0, data:GetAttribute("Z") or 0)
	local yaw = data:GetAttribute("Yaw") or 0
	local home = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
	model:PivotTo(home)
	model.Name = "Guardian_" .. species
	model.Parent = Workspace
	local anchor = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	local label = anchor and nameTag(anchor, data:GetAttribute("Title") or species, height)
	guardians[data] = {
		model = model,
		rig = FreekAnimator.rig(model, (data:GetAttribute("Zone") or 1) * 17, home),
		position = position,
		yaw = yaw,
		label = label,
	}
end

local function step(dt: number)
	local t = os.clock()
	for data, g in guardians do
		if not data.Parent then
			g.model:Destroy()
			guardians[data] = nil
			continue
		end
		local target = Vector3.new(data:GetAttribute("X") or 0, 0, data:GetAttribute("Z") or 0)
		local speed = (data:GetAttribute("Speed") or 16) * 1.25
		local offset = target - g.position
		local distance = offset.Magnitude
		if distance > 30 then
			g.position = target -- too far behind (e.g. just streamed in): jump there
		elseif distance > 0.01 then
			g.position += offset.Unit * math.min(distance, speed * dt)
		end
		-- Turn smoothly toward the server's heading.
		local goalYaw = data:GetAttribute("Yaw") or g.yaw
		local diff = (goalYaw - g.yaw + math.pi) % (2 * math.pi) - math.pi
		g.yaw += diff * math.min(1, dt * 10)
		local ground = CFrame.new(g.position) * CFrame.Angles(0, g.yaw, 0)
		local walking = data:GetAttribute("Moving") == true
		local sleeping = data:GetAttribute("Sleeping") == true and not walking
		if sleeping then
			-- Dozing: leaning forward a little, breathing slowly.
			ground *= CFrame.Angles(math.rad(-10 + math.sin(t * 1.2) * 2), 0, 0)
		end
		if g.rig then
			local pace = if data:GetAttribute("Chasing") then 1.6 elseif sleeping then 0.3 else 1
			FreekAnimator.pose(g.rig, ground, t * pace, walking)
		else
			g.model:PivotTo(ground)
		end
		if g.label then
			local chasing = data:GetAttribute("Chasing") == true
			local title = string.upper(data:GetAttribute("Title") or "")
			if sleeping then
				-- Drifting z's.
				local zs = ({ "z", "zZ", "zZz" })[math.floor(t * 1.5) % 3 + 1]
				g.label.TextColor3 = Color3.fromRGB(170, 200, 255)
				g.label.Text = "💤 " .. title .. " " .. zs
			else
				g.label.TextColor3 = if chasing then Color3.fromRGB(255, 80, 80) else Color3.new(1, 1, 1)
				g.label.Text = if chasing then "😡 " .. title else title
			end
		end
	end
end

function GuardianFX.start()
	local folder = ReplicatedStorage:WaitForChild("Guardians", 30)
	if not folder then
		return
	end
	for _, data in folder:GetChildren() do
		task.spawn(add, data)
	end
	folder.ChildAdded:Connect(add)
	RunService.RenderStepped:Connect(step)
end

return GuardianFX
