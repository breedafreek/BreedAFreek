-- Draws the guardians' attacks (GuardianAttacks.luau) on this client, from the server's
-- GuardianAttack events: a dust burst for a dash, the thing thrown for a projectile (a pie,
-- a bandage, a magic orb, a bat swarm), a poof at both ends of a teleport, a warning line
-- then a laser for a beam, and a warning circle then a lightning bolt for a strike. The
-- server decides what hits; this is only the show.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GuardianAttacks = require(ReplicatedStorage.Shared.GuardianAttacks)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local GuardianAttackFX = {}

local folder
local moving = {} -- { { model, velocity, target, homing, speed, endsAt, spin } }
local beams = {} -- [zone] = { line, target, endsAt }

local function part(props): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		p[key] = value
	end
	p.Parent = props.Parent or folder
	return p
end

local function guardianPosition(zone: number): Vector3?
	local guardians = ReplicatedStorage:FindFirstChild("Guardians")
	local data = guardians and guardians:FindFirstChild("Guardian" .. zone)
	if not data then
		return nil
	end
	return Vector3.new(data:GetAttribute("X") or 0, 5, data:GetAttribute("Z") or 0)
end

local function rootOf(userId: number?): BasePart?
	local player = userId and Players:GetPlayerByUserId(userId)
	local character = player and player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- A burst of little bricks flying out from a point and fading (dust, poofs, sparks).
local function burst(at: Vector3, color: Color3, count: number, speed: number, material: Enum.Material?)
	for _ = 1, count do
		local direction = Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5).Unit
		local bit = part({
			Size = Vector3.one * (0.5 + math.random() * 0.6),
			CFrame = CFrame.new(at),
			Color = color,
			Material = material or Enum.Material.SmoothPlastic,
		})
		table.insert(moving, {
			model = bit,
			velocity = direction * speed,
			endsAt = os.clock() + 0.6,
			fade = true,
			gravity = true,
		})
	end
end

-- The thing a projectile attack throws.
local function projectileModel(attackId: string, color: Color3): Model
	local model = Instance.new("Model")
	model.Name = "Projectile"
	if attackId == "pie" then
		part({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, 2.4, 2.4),
			Color = color,
			Parent = model,
		})
		part({
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 1.6,
			CFrame = CFrame.new(0.5, 0, 0),
			Color = Color3.fromRGB(255, 250, 245),
			Parent = model,
		})
	elseif attackId == "bandage" then
		part({ Size = Vector3.new(0.5, 0.2, 5), Color = color, Parent = model })
	elseif attackId == "bats" then
		for k = 0, 3 do
			local offset = Vector3.new(math.cos(k * 1.7) * 1.4, math.sin(k * 2.3) * 0.8, math.sin(k * 1.7) * 1.4)
			part({ Size = Vector3.new(1.6, 0.2, 0.7), CFrame = CFrame.new(offset), Color = color, Parent = model })
			part({
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * 0.6,
				CFrame = CFrame.new(offset),
				Color = color,
				Parent = model,
			})
		end
	else -- magic orb
		local orb = part({
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 2,
			Color = color,
			Material = Enum.Material.Neon,
			Parent = model,
		})
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 10
		light.Brightness = 3
		light.Parent = orb
	end
	model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart")
	model.Parent = folder
	return model
end

local function onAttack(zone: number, attackId: string, info)
	local attack = GuardianAttacks.list[attackId]
	if not attack or typeof(info) ~= "table" then
		return
	end
	local at = guardianPosition(zone)
	if attack.kind == "dash" then
		if at then
			burst(at - Vector3.new(0, 4, 0), Color3.fromRGB(200, 185, 160), 10, 18)
		end
	elseif attack.kind == "projectile" then
		local model = projectileModel(attackId, attack.color or Color3.new(1, 1, 1))
		model:PivotTo(CFrame.new(info.from))
		table.insert(moving, {
			model = model,
			velocity = info.velocity,
			target = info.target,
			homing = attack.homing,
			speed = attack.speed,
			radius = attack.radius,
			endsAt = os.clock() + (info.duration or 2),
			spin = attackId ~= "bandage",
		})
	elseif attack.kind == "teleport" then
		local ghost = Color3.fromRGB(180, 200, 255)
		burst(info.from + Vector3.new(0, 3, 0), ghost, 14, 14, Enum.Material.Neon)
		burst(info.to + Vector3.new(0, 3, 0), ghost, 14, 14, Enum.Material.Neon)
	elseif attack.kind == "beam" then
		if info.phase == "aim" then
			local line = part({
				Name = "LaserAim",
				Size = Vector3.new(0.25, 0.25, 1),
				Color = Color3.fromRGB(255, 60, 60),
				Material = Enum.Material.Neon,
				Transparency = 0.3,
			})
			beams[zone] = { line = line, target = info.target, endsAt = os.clock() + (info.windup or 1) }
			Debris:AddItem(line, (info.windup or 1) + 0.2)
		elseif info.phase == "fire" then
			if beams[zone] then
				beams[zone].line:Destroy()
				beams[zone] = nil
			end
			local length = info.range or 60
			local laser = part({
				Name = "Laser",
				Size = Vector3.new(attack.width * 0.8, attack.width * 0.8, length),
				CFrame = CFrame.lookAt(info.from, info.from + info.direction) * CFrame.new(0, 0, -length / 2),
				Color = Color3.fromRGB(255, 40, 40),
				Material = Enum.Material.Neon,
				Transparency = 0.15,
			})
			Debris:AddItem(laser, 0.35)
		end
	elseif attack.kind == "strike" then
		local radius = info.radius or 7
		if info.phase == "mark" then
			local mark = part({
				Name = "StrikeMark",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.2, radius * 2, radius * 2),
				CFrame = CFrame.new(info.spot + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2),
				Color = Color3.fromRGB(255, 60, 60),
				Material = Enum.Material.Neon,
				Transparency = 0.6,
			})
			Debris:AddItem(mark, (info.windup or 1) + 0.1)
		elseif info.phase == "fire" then
			local bolt = part({
				Name = "Lightning",
				Size = Vector3.new(1.6, 70, 1.6),
				CFrame = CFrame.new(info.spot + Vector3.new(0, 35, 0)),
				Color = Color3.fromRGB(255, 240, 120),
				Material = Enum.Material.Neon,
			})
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 240, 160)
			light.Range = 30
			light.Brightness = 8
			light.Parent = bolt
			Debris:AddItem(bolt, 0.3)
			burst(info.spot + Vector3.new(0, 1, 0), Color3.fromRGB(255, 230, 90), 12, 20, Enum.Material.Neon)
		end
	end
end

local function step(dt: number)
	local now = os.clock()
	for i = #moving, 1, -1 do
		local m = moving[i]
		local model = m.model
		if not model.Parent or now > m.endsAt then
			model:Destroy()
			table.remove(moving, i)
			continue
		end
		local root = rootOf(m.target)
		if m.homing and root then
			local position = model:GetPivot().Position
			m.velocity = m.velocity:Lerp((root.Position - position).Unit * m.speed, math.min(1, m.homing * dt))
		end
		if m.gravity then
			m.velocity += Vector3.new(0, -60 * dt, 0)
		end
		local position = model:GetPivot().Position + m.velocity * dt
		local facing = if m.velocity.Magnitude > 0.1
			then CFrame.lookAt(position, position + m.velocity)
			else CFrame.new(position)
		if m.spin then
			facing *= CFrame.Angles(0, 0, now * 8)
		end
		model:PivotTo(facing)
		if m.fade and model:IsA("BasePart") then
			model.Transparency = math.clamp(1 - (m.endsAt - now) / 0.6, 0, 1)
		end
		-- Gone once it reaches its target (the server decides whether it hit).
		if root and m.radius and (root.Position - position).Magnitude < m.radius then
			model:Destroy()
			table.remove(moving, i)
		end
	end
	-- Laser warning lines follow their target until the shot.
	for zone, beam in beams do
		local from = guardianPosition(zone)
		local root = rootOf(beam.target)
		if not beam.line.Parent or now > beam.endsAt or not from or not root then
			beams[zone] = nil
		else
			local length = (root.Position - from).Magnitude
			beam.line.Size = Vector3.new(0.25, 0.25, length)
			beam.line.CFrame = CFrame.lookAt(from, root.Position) * CFrame.new(0, 0, -length / 2)
		end
	end
end

function GuardianAttackFX.start()
	folder = Instance.new("Folder")
	folder.Name = "GuardianAttackFX"
	folder.Parent = Workspace
	Remotes.get("GuardianAttack").OnClientEvent:Connect(onAttack)
	RunService.RenderStepped:Connect(step)
end

return GuardianAttackFX
