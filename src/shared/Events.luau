-- Scheduled events, like the "admin abuse" events of the big Roblox games.
--
--   * Big events (Guardian Nap) run on a weekly timetable, the same moment in every server:
--     the guardians get sleepy and slow, parts regrow faster and rarer parts turn up.
--   * Weather rolls in for a few minutes at half past most hours. While it lasts, parts on
--     houses can catch its mutation (Blood Moon -> Shadow, and so on), and new parts in the
--     zone piles often grow with it.
--
-- The timetable is worked out from the clock alone, so every server agrees without talking.
-- The admin panel can also start any event early, in one server or all of them (see
-- server/EventService). The server publishes what's running as ReplicatedStorage
-- attributes; Events.current() and Events.weather() read them on either side.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Luck = require(script.Parent.Luck)

local Events = {}

-- Big events.
Events.BIG = {
	GuardianNap = {
		name = "Guardian Nap",
		icon = "😴",
		description = "The guardians are sleepy! They run slower, parts regrow fast and rare parts turn up!",
		color = Color3.fromRGB(170, 110, 255),
		respawnBoost = 3, -- parts regrow this many times faster
		rareBoost = 4, -- rarer parts (the next zone's style) turn up this many times more often
		mutationBoost = 2,
		guardianSpeed = 0.75, -- guardians run at this fraction of their speed
	},
}

-- Weather: each one can give parts on houses (and new parts in the piles) its mutation.
Events.WEATHER = {
	BloodMoon = {
		name = "Blood Moon",
		icon = "🌕",
		description = "Parts can turn Shadow!",
		color = Color3.fromRGB(255, 70, 80),
		mutation = "Shadow",
		chance = 0.02, -- per part on a house, every WEATHER_TICK seconds
	},
	GoldRush = {
		name = "Gold Rush",
		icon = "✨",
		description = "Parts can turn Golden!",
		color = Color3.fromRGB(255, 205, 60),
		mutation = "Golden",
		chance = 0.012,
	},
	RainbowRain = {
		name = "Rainbow Rain",
		icon = "🌈",
		description = "Parts can turn Rainbow!",
		color = Color3.fromRGB(255, 120, 230),
		mutation = "Rainbow",
		chance = 0.004,
	},
}
Events.WEATHER_TICK = 20

-- The weekly timetable, in UTC (weekday 1 = Sunday). 19:00 UTC on Saturday is 3pm US
-- Eastern in summer time (2pm in winter).
Events.SCHEDULE = {
	{ id = "GuardianNap", weekday = 7, hour = 19, minute = 0, minutes = 30 }, -- Saturday
	{ id = "GuardianNap", weekday = 3, hour = 22, minute = 0, minutes = 30 }, -- Tuesday
}

-- Weather comes at WEATHER_MINUTE past the hour for WEATHER_MINUTES, picked from this
-- list (weights; "" = clear skies that hour).
Events.WEATHER_MINUTE = 30
Events.WEATHER_MINUTES = 10
Events.WEATHER_ODDS = {
	{ id = "BloodMoon", weight = 4 },
	{ id = "GoldRush", weight = 3 },
	{ id = "RainbowRain", weight = 1 },
	{ id = "", weight = 4 },
}

local DAY = 24 * 60 * 60

-- Every scheduled big event in the next week from time t (and any running now), soonest
-- first: { id, starts, ends }.
function Events.upcoming(t: number)
	local list = {}
	local midnight = t - t % DAY
	for day = -1, 7 do
		local dayStart = midnight + day * DAY
		local weekday = (os.date("!*t", dayStart) :: any).wday
		for _, slot in Events.SCHEDULE do
			if slot.weekday == weekday then
				local starts = dayStart + slot.hour * 3600 + slot.minute * 60
				local ends = starts + slot.minutes * 60
				if ends > t then
					table.insert(list, { id = slot.id, starts = starts, ends = ends })
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return a.starts < b.starts
	end)
	return list
end

-- The scheduled big event running at time t, if any.
function Events.scheduledAt(t: number)
	local first = Events.upcoming(t)[1]
	if first and first.starts <= t then
		return first
	end
	return nil
end

-- The weather the timetable gives the hour containing t: { id, starts, ends } or nil.
function Events.weatherFor(hourIndex: number)
	local x = math.sin(hourIndex * 12.9898 + 78.233) * 43758.5453
	local roll = x - math.floor(x)
	local total = 0
	for _, entry in Events.WEATHER_ODDS do
		total += entry.weight
	end
	roll *= total
	for _, entry in Events.WEATHER_ODDS do
		roll -= entry.weight
		if roll <= 0 then
			if entry.id == "" then
				return nil
			end
			local starts = hourIndex * 3600 + Events.WEATHER_MINUTE * 60
			return { id = entry.id, starts = starts, ends = starts + Events.WEATHER_MINUTES * 60 }
		end
	end
	return nil
end

function Events.scheduledWeatherAt(t: number)
	local weather = Events.weatherFor(math.floor(t / 3600))
	if weather and weather.starts <= t and t < weather.ends then
		return weather
	end
	return nil
end

-- The next scheduled weather after t (looks a day ahead).
function Events.nextWeather(t: number)
	local hour = math.floor(t / 3600)
	for k = 0, 24 do
		local weather = Events.weatherFor(hour + k)
		if weather and weather.ends > t then
			return weather
		end
	end
	return nil
end

-- What's running now, from the attributes the server publishes.
function Events.current()
	local id = ReplicatedStorage:GetAttribute("Event")
	local ends = ReplicatedStorage:GetAttribute("EventEnds") or 0
	if id and Events.BIG[id] and Workspace:GetServerTimeNow() < ends then
		return Events.BIG[id], ends, id
	end
	return nil, 0, nil
end

function Events.weather()
	local id = ReplicatedStorage:GetAttribute("Weather")
	local ends = ReplicatedStorage:GetAttribute("WeatherEnds") or 0
	if id and Events.WEATHER[id] and Workspace:GetServerTimeNow() < ends then
		return Events.WEATHER[id], ends, id
	end
	return nil, 0, nil
end

-- A boost from everything running now (a Lucky Hour and a big event multiply together):
-- "respawnBoost", "rareBoost", "mutationBoost", "guardianSpeed" or "crateLuck".
function Events.boost(key: string): number
	local total = 1
	local lucky = Luck.current()
	if lucky and lucky[key] then
		total *= lucky[key]
	end
	local big = Events.current()
	if big and big[key] then
		total *= big[key]
	end
	return total
end

return Events
