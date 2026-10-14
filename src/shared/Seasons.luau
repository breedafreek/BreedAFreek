-- Limited events for Seasonal Freeks. A Freek with `season = "Halloween"` can only be bred
-- (or bought, if it has a price) while that event is running. Once owned it's kept forever
-- and still earns, trades and breeds year-round.
--
-- Each event's `window(year)` returns its first and last day (inclusive, UTC) as day
-- numbers (days since 1970-01-01). Windows may run past New Year.

local Seasons = {}

-- Days since 1970-01-01 for a calendar date (proleptic Gregorian).
local function dayNumber(year: number, month: number, day: number): number
	if month <= 2 then
		year -= 1
	end
	local era = year // 400
	local yearOfEra = year - era * 400
	local monthIndex = (month + 9) % 12
	local dayOfYear = (153 * monthIndex + 2) // 5 + day - 1
	local dayOfEra = yearOfEra * 365 + yearOfEra // 4 - yearOfEra // 100 + dayOfYear
	return era * 146097 + dayOfEra - 719468
end

local function weekday(days: number): number
	return (days + 4) % 7 -- 0 = Sunday; 1970-01-01 was a Thursday
end

local function easter(year: number): (number, number)
	local a = year % 19
	local b = year // 100
	local c = year % 100
	local d = b // 4
	local e = b % 4
	local f = (b + 8) // 25
	local g = (b - f + 1) // 3
	local h = (19 * a + b - d - g + 15) % 30
	local i = c // 4
	local k = c % 4
	local l = (32 + 2 * e + 2 * i - h - k) % 7
	local m = (a + 11 * h + 22 * l) // 451
	local month = (h + l - 7 * m + 114) // 31
	local day = (h + l - 7 * m + 114) % 31 + 1
	return month, day
end

local function fixed(fromMonth: number, fromDay: number, toMonth: number, toDay: number)
	return function(year: number)
		local first = dayNumber(year, fromMonth, fromDay)
		local toYear = if toMonth < fromMonth then year + 1 else year
		return first, dayNumber(toYear, toMonth, toDay)
	end
end

Seasons.list = {
	Halloween = {
		name = "Halloween",
		color = Color3.fromRGB(255, 130, 20),
		window = fixed(10, 1, 10, 31),
	},
	Thanksgiving = {
		name = "Thanksgiving",
		color = Color3.fromRGB(200, 120, 50),
		-- Nov 1 through the Sunday after Thanksgiving (4th Thursday of November).
		window = function(year)
			local nov1 = dayNumber(year, 11, 1)
			local firstThursday = nov1 + (4 - weekday(nov1)) % 7
			return nov1, firstThursday + 21 + 3
		end,
	},
	Christmas = {
		name = "Christmas",
		color = Color3.fromRGB(230, 50, 60),
		window = fixed(12, 1, 12, 26),
	},
	NewYears = {
		name = "New Years",
		color = Color3.fromRGB(255, 215, 90),
		window = fixed(12, 27, 1, 7),
	},
	Easter = {
		name = "Easter",
		color = Color3.fromRGB(255, 170, 220),
		-- Two weeks before Easter Sunday through Easter Monday.
		window = function(year)
			local month, day = easter(year)
			local sunday = dayNumber(year, month, day)
			return sunday - 14, sunday + 1
		end,
	},
	America = {
		name = "America",
		color = Color3.fromRGB(70, 120, 255),
		-- The week around July 4th.
		window = fixed(6, 28, 7, 7),
	},
}

function Seasons.isActive(seasonId: string?, now: number?): boolean
	local season = seasonId and Seasons.list[seasonId]
	if not season then
		return false
	end
	local today = (now or os.time()) // 86400
	local year = os.date("!*t", now or os.time()).year
	-- Check last year's window too, for events that run past New Year.
	for _, y in { year - 1, year } do
		local first, last = season.window(y)
		if today >= first and today <= last then
			return true
		end
	end
	return false
end

-- True if this species can be obtained right now (always true for non-seasonal Freeks).
function Seasons.available(species, now: number?): boolean
	return species.season == nil or Seasons.isActive(species.season, now)
end

-- The events running right now, e.g. { "Halloween" }.
function Seasons.active(now: number?): { string }
	local list = {}
	for id in Seasons.list do
		if Seasons.isActive(id, now) then
			table.insert(list, id)
		end
	end
	table.sort(list)
	return list
end

return Seasons
