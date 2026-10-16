-- Runs the scheduled events (see shared/Events.luau) and the ones the admin starts.
--
-- Every second it works out what should be running and publishes it as ReplicatedStorage
-- attributes (Event/EventEnds, Weather/WeatherEnds, NextEvent/NextEventAt,
-- NextWeather/NextWeatherAt), announcing each start and end. While weather runs, Freeks
-- standing in barns can catch its mutation.
--
-- Admin events reach every server at once through MessagingService, and are also saved in
-- a DataStore so servers that start up later still join in.

local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Events = require(ReplicatedStorage.Shared.Events)
local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local Luck = require(ReplicatedStorage.Shared.Luck)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)

local EventService = {}

local TOPIC = "FuseAFreekAdmin"
local STORE_KEY = "AdminEvents"

local notifyRemote = Remotes.get("Notify")
local rng = Random.new()
local store -- the DataStore, if this server can use one

-- What the admin has started: { big = { id, ends }, weather = { id, ends } }.
local overrides = { big = nil, weather = nil }

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function announce(message: string)
	for _, player in Players:GetPlayers() do
		notifyRemote:FireClient(player, message, "discovery")
	end
end

-- Applies an admin message (from this server or another one).
local function apply(message)
	if type(message) ~= "table" then
		return
	end
	if message.type == "event" then
		local kind = if Events.BIG[message.id]
			then "big"
			elseif Events.WEATHER[message.id] then "weather"
			elseif Luck.EVENTS[message.id] then "lucky"
			else nil
		if kind == "lucky" then
			ReplicatedStorage:SetAttribute("LuckyEvent", message.id)
			ReplicatedStorage:SetAttribute("LuckyEventEnds", message.ends)
			local event = Luck.EVENTS[message.id]
			announce(event.icon .. " " .. event.name .. "! " .. event.description)
		elseif kind then
			overrides[kind] = { id = message.id, ends = message.ends }
		end
	elseif message.type == "end" then
		-- End everything the admin started, and anything scheduled running right now.
		overrides.big = { id = nil, ends = message.ends or now() + 60 }
		overrides.weather = { id = nil, ends = message.ends or now() + 60 }
		ReplicatedStorage:SetAttribute("LuckyEvent", nil)
	elseif message.type == "announce" and type(message.text) == "string" then
		announce("📣 " .. message.text)
	end
end

-- Sends an admin message to this server and, if `everywhere`, every other server too.
function EventService.send(message, everywhere: boolean)
	apply(message)
	if not everywhere then
		return
	end
	task.spawn(function()
		local ok, err = pcall(function()
			MessagingService:PublishAsync(TOPIC, message)
		end)
		if not ok then
			warn("[EventService] Couldn't reach other servers: " .. tostring(err))
		end
		if store and message.type ~= "announce" then
			pcall(function()
				store:SetAsync(STORE_KEY, message)
			end)
		end
	end)
end

-- What's running (or nil): an admin override beats the timetable while it lasts.
local function pick(kind: string, scheduled)
	local override = overrides[kind]
	if override and now() < override.ends then
		if override.id then
			return { id = override.id, ends = override.ends }
		end
		return nil -- the admin ended it
	end
	return scheduled
end

-- Weather mutations: every Freek standing on a pad has a chance to catch it.
local function weatherTick(weather)
	for _, player in Players:GetPlayers() do
		local data = DataService.get(player)
		if data then
			local changed = false
			for _, freek in data.freeks do
				local mutations = Mutations.normalize(freek.mutations)
				if freek.slot and not table.find(mutations, weather.mutation) and rng:NextNumber() < weather.chance then
					table.insert(mutations, weather.mutation)
					freek.mutations = Mutations.pack(mutations)
					changed = true
					notifyRemote:FireClient(
						player,
						weather.icon
							.. " Your "
							.. FreekUtil.displayName(freek)
							.. " caught the "
							.. weather.name
							.. "!",
						"discovery"
					)
				end
			end
			if changed then
				DataService.changed(player)
			end
		end
	end
end

function EventService.init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("FuseAFreekEvents")
	end)
	store = ok and result or nil

	pcall(function()
		MessagingService:SubscribeAsync(TOPIC, function(packet)
			apply(packet.Data)
		end)
	end)

	-- Pick up an admin event another server started before this one existed.
	task.spawn(function()
		if store then
			local loaded, message = pcall(function()
				return store:GetAsync(STORE_KEY)
			end)
			if loaded and type(message) == "table" and (message.ends or 0) > now() then
				apply(message)
			end
		end
	end)

	local running = { big = nil, weather = nil }
	local nextTick = 0
	task.spawn(function()
		while true do
			local t = now()
			local unix = os.time()
			local offset = t - unix -- server time vs. the UTC clock the timetable uses
			local scheduledBig = Events.scheduledAt(unix)
			local scheduledWeather = Events.scheduledWeatherAt(unix)
			local big = pick("big", scheduledBig and { id = scheduledBig.id, ends = scheduledBig.ends + offset })
			local weather = pick(
				"weather",
				scheduledWeather and { id = scheduledWeather.id, ends = scheduledWeather.ends + offset }
			)

			for kind, state in { big = big, weather = weather } do
				local before = running[kind]
				local id = state and state.id
				local list = if kind == "big" then Events.BIG else Events.WEATHER
				if id ~= (before and before.id) then
					if before and before.id then
						announce(list[before.id].name .. " is over!")
					end
					if id then
						local event = list[id]
						announce(event.icon .. " " .. string.upper(event.name) .. "! " .. event.description)
					end
				end
				running[kind] = state
			end
			ReplicatedStorage:SetAttribute("Event", big and big.id)
			ReplicatedStorage:SetAttribute("EventEnds", big and big.ends or 0)
			ReplicatedStorage:SetAttribute("Weather", weather and weather.id)
			ReplicatedStorage:SetAttribute("WeatherEnds", weather and weather.ends or 0)

			-- What's coming next, for the countdowns.
			local upcoming = Events.upcoming(unix)
			local nextBig
			for _, slot in upcoming do
				if slot.starts > unix then
					nextBig = slot
					break
				end
			end
			ReplicatedStorage:SetAttribute("NextEvent", nextBig and nextBig.id)
			ReplicatedStorage:SetAttribute("NextEventAt", nextBig and nextBig.starts + offset or 0)
			local nextWeather = Events.nextWeather(unix)
			if nextWeather and nextWeather.starts <= unix then
				nextWeather = Events.nextWeather(nextWeather.ends + 1)
			end
			ReplicatedStorage:SetAttribute("NextWeather", nextWeather and nextWeather.id)
			ReplicatedStorage:SetAttribute("NextWeatherAt", nextWeather and nextWeather.starts + offset or 0)

			if weather and Events.WEATHER[weather.id] and t >= nextTick then
				nextTick = t + Events.WEATHER_TICK
				weatherTick(Events.WEATHER[weather.id])
			end
			task.wait(1)
		end
	end)
end

return EventService
