-- What big events and weather look like (see Events.luau), on each player's own screen:
-- a colour tint over everything, falling rain or sparkles around the camera, and lightning
-- flashes during a Monster Storm.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Events = require(ReplicatedStorage.Shared.Events)

local EventFX = {}

local LOOKS = {
	-- Guardian Nap: a dreamy purple dusk with soft sparkles drifting down.
	GuardianNap = {
		tint = Color3.fromRGB(210, 195, 255),
		brightness = -0.04,
		rain = Color3.fromRGB(205, 185, 255),
	},
	BloodMoon = { tint = Color3.fromRGB(255, 165, 170), brightness = -0.04, rain = Color3.fromRGB(255, 80, 90) },
	GoldRush = { tint = Color3.fromRGB(255, 238, 180), brightness = 0.03, rain = Color3.fromRGB(255, 215, 80) },
	RainbowRain = { tint = Color3.fromRGB(255, 225, 255), brightness = 0.02, rain = "rainbow" },
}

function EventFX.start()
	local tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "EventTint"
	tint.Parent = Lighting

	-- A big invisible sheet over the camera that rain (or sparkles) falls from.
	local sky = Instance.new("Part")
	sky.Name = "EventSky"
	sky.Anchored = true
	sky.CanCollide = false
	sky.CanQuery = false
	sky.CanTouch = false
	sky.Transparency = 1
	sky.Size = Vector3.new(120, 1, 120)
	local rain = Instance.new("ParticleEmitter")
	rain.Rate = 0
	rain.Lifetime = NumberRange.new(1.6, 2.2)
	rain.Speed = NumberRange.new(30, 40)
	rain.EmissionDirection = Enum.NormalId.Bottom
	rain.Size = NumberSequence.new(0.35)
	rain.LightEmission = 0.6
	rain.Parent = sky
	sky.Parent = Workspace

	local nextFlash = 0
	task.spawn(function()
		while true do
			local big, _, bigId = Events.current()
			local weather, _, weatherId = Events.weather()
			-- A big event's look wins over the weather's.
			local look = (big and LOOKS[bigId]) or (weather and LOOKS[weatherId])
			local camera = Workspace.CurrentCamera
			if camera then
				sky.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 40, 0))
			end
			local target = if look then look.tint else Color3.new(1, 1, 1)
			local brightness = if look then look.brightness else 0
			if look and look.rain == "rainbow" then
				target = Color3.fromHSV((os.clock() * 0.1) % 1, 0.12, 1)
			end
			tint.TintColor = tint.TintColor:Lerp(target, 0.05)
			if look and look.lightning and os.clock() >= nextFlash then
				nextFlash = os.clock() + 3 + math.random() * 5
				tint.Brightness = 0.45 -- the flash, which fades below
			end
			tint.Brightness += (brightness - tint.Brightness) * 0.12
			if look then
				rain.Rate = if look.lightning then 300 else 120
				if look.rain == "rainbow" then
					rain.Color = ColorSequence.new(Color3.fromHSV((os.clock() * 0.3) % 1, 0.6, 1))
				else
					rain.Color = ColorSequence.new(look.rain)
				end
			else
				rain.Rate = 0
			end
			task.wait(1 / 30)
		end
	end)
end

return EventFX
