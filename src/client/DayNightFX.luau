-- Night falls on this client's screen (DayNight.luau): the sun sets, the sky turns to
-- night and the picture tints blue, then morning comes back. Done locally every frame so
-- it's smooth; the server's lighting (and any seasonal theme's) is the daytime look.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DayNight = require(ReplicatedStorage.Shared.DayNight)

local DayNightFX = {}

local NIGHT_CLOCK = 22 -- the clock time at full night (the moon is up)
local NIGHT_TINT = Color3.fromRGB(140, 160, 255)

function DayNightFX.start()
	local tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "NightTint"
	tint.Parent = Lighting
	local dayClock = Lighting.ClockTime
	local dark = 0
	RunService.RenderStepped:Connect(function()
		local wanted = DayNight.darkness()
		if wanted == 0 and dark == 0 then
			-- Daytime: whatever the server sets is the day look.
			dayClock = Lighting.ClockTime
			return
		end
		dark = wanted
		Lighting.ClockTime = dayClock + (NIGHT_CLOCK - dayClock) * dark
		tint.TintColor = Color3.new(1, 1, 1):Lerp(NIGHT_TINT, dark)
		tint.Brightness = -0.12 * dark
		tint.Saturation = -0.15 * dark
	end)
end

return DayNightFX
