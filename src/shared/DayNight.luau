-- The day and night cycle, the same in every server and on every client: DAY seconds of
-- day, then NIGHT seconds of night. At nightfall every zone's eggs are swapped for new
-- random ones, and while it's night the eggs in everyone's nests grow NIGHT_SPEED times
-- as fast. Time is the server clock (Workspace:GetServerTimeNow()), so clients agree.

local Workspace = game:GetService("Workspace")

local DayNight = {}

DayNight.DAY = 5 * 60
DayNight.NIGHT = 15
DayNight.CYCLE = DayNight.DAY + DayNight.NIGHT
DayNight.NIGHT_SPEED = 30

-- Seconds into the current cycle (0 = sunrise; DAY = nightfall).
function DayNight.phase(now: number?): number
	return (now or Workspace:GetServerTimeNow()) % DayNight.CYCLE
end

function DayNight.isNight(now: number?): boolean
	return DayNight.phase(now) >= DayNight.DAY
end

-- Seconds until the next change (nightfall during the day, sunrise at night).
function DayNight.timeLeft(now: number?): number
	local phase = DayNight.phase(now)
	return if phase >= DayNight.DAY then DayNight.CYCLE - phase else DayNight.DAY - phase
end

-- How dark it is, 0 (day) to 1 (night): it gets dark over the last few seconds of the day
-- and light again over the last few seconds of the night.
function DayNight.darkness(now: number?): number
	local phase = DayNight.phase(now)
	if phase < DayNight.DAY then
		return math.clamp((phase - (DayNight.DAY - 4)) / 4, 0, 1)
	end
	return math.clamp((DayNight.CYCLE - phase) / 3, 0, 1)
end

return DayNight
