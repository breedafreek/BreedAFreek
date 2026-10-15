-- Moving bits of the rebirth barn upgrades (BarnUpgrades.luau on the server), animated
-- locally so they're smooth: weathervanes and spotlights sway, the gem halo spins, and
-- barns with fireworks set one off every so often. Only nearby barns animate.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BarnFX = {}

local SPINNER_TAG = "BarnSpinner"
local FIREWORKS_TAG = "BarnFireworks"
local RANGE = 400
local FIREWORK_COLORS = {
	Color3.fromRGB(255, 80, 120),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(80, 220, 255),
	Color3.fromRGB(170, 100, 255),
	Color3.fromRGB(120, 255, 110),
	Color3.fromRGB(255, 140, 50),
}

local function spark(parent: Instance, position: Vector3, size: number, color: Color3): BasePart
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.one * size
	p.CFrame = CFrame.new(position)
	p.Color = color
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

-- One firework: a rocket climbs from the roof, then bursts into a ball of sparks.
local function launch(folder: Instance, from: Vector3)
	local random = Random.new()
	local color = FIREWORK_COLORS[random:NextInteger(1, #FIREWORK_COLORS)]
	local second = FIREWORK_COLORS[random:NextInteger(1, #FIREWORK_COLORS)]
	local burstAt = from + Vector3.new(random:NextNumber(-8, 8), random:NextNumber(26, 38), random:NextNumber(-8, 8))
	local rocket = spark(folder, from, 0.8, Color3.fromRGB(255, 240, 200))
	local began = os.clock()
	while os.clock() - began < 0.9 do
		local a = (os.clock() - began) / 0.9
		local position = from:Lerp(burstAt, 1 - (1 - a) * (1 - a))
		rocket.CFrame = CFrame.new(position)
		task.wait()
	end
	rocket:Destroy()
	local flash = Instance.new("PointLight")
	local core = spark(folder, burstAt, 2.5, color)
	flash.Color = color
	flash.Range = 40
	flash.Brightness = 4
	flash.Parent = core
	local sparks = {}
	for k = 1, 36 do
		local direction = random:NextUnitVector()
		local p = spark(folder, burstAt, 0.7, if k % 3 == 0 then second else color)
		table.insert(sparks, { part = p, velocity = direction * random:NextNumber(14, 20) })
	end
	began = os.clock()
	local last = began
	while os.clock() - began < 1.6 do
		local now = os.clock()
		local dt = now - last
		last = now
		local a = (now - began) / 1.6
		for _, s in sparks do
			s.velocity = s.velocity * (1 - dt * 1.5) - Vector3.new(0, 9 * dt, 0)
			s.part.CFrame = s.part.CFrame + s.velocity * dt
			s.part.Transparency = a * a
		end
		core.Transparency = math.min(a * 4, 1)
		flash.Brightness = 4 * (1 - a)
		task.wait()
	end
	for _, s in sparks do
		s.part:Destroy()
	end
	core:Destroy()
end

function BarnFX.start()
	local folder = Instance.new("Folder")
	folder.Name = "BarnFX"
	folder.Parent = Workspace

	RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera
		local eye = if camera then camera.CFrame.Position else Vector3.zero
		local t = os.clock()
		for i, model in CollectionService:GetTagged(SPINNER_TAG) do
			local rest = model:GetAttribute("Rest")
			if model:IsA("Model") and model.PrimaryPart and typeof(rest) == "CFrame" then
				if (rest.Position - eye).Magnitude < RANGE then
					local speed = model:GetAttribute("Speed") or 0.5
					local angle = if model:GetAttribute("Mode") == "sway"
						then math.sin(t * speed + i) * (model:GetAttribute("Amount") or 0.5)
						else t * speed
					model:PivotTo(rest * CFrame.Angles(0, angle, 0))
				end
			end
		end
	end)

	-- Fireworks: each barn with a launcher fires every 40-80 seconds.
	local nextShot = {}
	task.spawn(function()
		while true do
			task.wait(1)
			local camera = Workspace.CurrentCamera
			local eye = if camera then camera.CFrame.Position else Vector3.zero
			local now = os.clock()
			for _, launcher in CollectionService:GetTagged(FIREWORKS_TAG) do
				if launcher:IsA("BasePart") then
					if not nextShot[launcher] then
						nextShot[launcher] = now + math.random(5, 30)
					elseif now >= nextShot[launcher] then
						nextShot[launcher] = now + math.random(40, 80)
						if (launcher.Position - eye).Magnitude < RANGE then
							for k = 1, math.random(2, 3) do
								task.delay(k * 0.35, launch, folder, launcher.Position)
							end
						end
					end
				end
			end
			for launcher in nextShot do
				if not launcher.Parent then
					nextShot[launcher] = nil
				end
			end
		end
	end)
end

return BarnFX
