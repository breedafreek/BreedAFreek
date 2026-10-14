-- Loads and saves each player's data with a session lock, so the same player in two
-- servers at once (e.g. a fast rejoin) can't duplicate or lose Freeks.
--
-- In Studio without "Enable Studio Access to API Services", saving is skipped and a
-- fresh save is used so the game is still testable.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local STORE_NAME = "BreedAFreek_Players_v1"

local DataService = {}

local profiles = {} -- [Player] = data
local noSave = {} -- [Player] = true when running without DataStores
local loadedCallbacks = {}
local changedCallbacks = {}

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

local function defaultData()
	return {
		version = 1,
		money = Config.START_MONEY,
		slots = Config.START_SLOTS,
		freeks = {}, -- [uid] = { species, mutation?, slot?, breeding? }
		breeding = nil, -- { a = uid, b = uid, endsAt = unix seconds }
		discovered = {}, -- [speciesId] = true for every species this player has owned
		weapons = {}, -- [weaponId] = true for weapons bought in the shop
		lastSeen = os.time(),
	}
end

local function reconcile(data)
	for key, value in defaultData() do
		if data[key] == nil then
			data[key] = value
		end
	end
	return data
end

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

-- Returns data, or nil + reason. reason is "locked" when another server holds the save.
local function tryLoad(player: Player)
	local locked = false
	local ok, result = pcall(function()
		return store:UpdateAsync(keyFor(player), function(old)
			locked = false
			old = old or defaultData()
			local lock = old.lock
			if lock and lock.job ~= game.JobId and os.time() - lock.time < Config.SESSION_LOCK_TIMEOUT then
				locked = true
				return nil
			end
			old.lock = { job = game.JobId, time = os.time() }
			return old
		end)
	end)
	if not ok then
		return nil, result
	end
	if locked then
		return nil, "locked"
	end
	return result, nil
end

local function load(player: Player)
	if not store then
		return nil, "DataStores unavailable"
	end
	local reason
	for attempt = 1, 6 do
		local data
		data, reason = tryLoad(player)
		if data then
			return reconcile(data)
		end
		if not player.Parent then
			return nil, "left"
		end
		if RunService:IsStudio() and reason ~= "locked" then
			return nil, reason -- don't make testers wait through retries
		end
		task.wait(if reason == "locked" then 10 else 2 * attempt)
	end
	return nil, reason
end

function DataService.save(player: Player, release: boolean?)
	local data = profiles[player]
	if not data or noSave[player] then
		return
	end
	data.lastSeen = os.time()
	data.lock = if release then nil else { job = game.JobId, time = os.time() }
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			store:UpdateAsync(keyFor(player), function(old)
				if old and old.lock and old.lock.job ~= game.JobId then
					return nil -- another server took over; never overwrite its save
				end
				return data
			end)
		end)
		if ok then
			return
		end
		warn("Save failed for", player.Name, err)
		task.wait(attempt)
	end
end

function DataService.get(player: Player)
	return profiles[player]
end

-- Yields until the player's data is loaded; returns nil if they leave first.
function DataService.waitFor(player: Player)
	while player.Parent and not profiles[player] do
		task.wait(0.1)
	end
	return profiles[player]
end

function DataService.all()
	return profiles
end

function DataService.onLoaded(callback)
	table.insert(loadedCallbacks, callback)
end

function DataService.onChanged(callback)
	table.insert(changedCallbacks, callback)
end

-- Call after changing a player's data so their yard and UI refresh.
function DataService.changed(player: Player)
	local data = profiles[player]
	if not data then
		return
	end
	for _, callback in changedCallbacks do
		task.spawn(callback, player, data)
	end
end

local function onPlayerAdded(player: Player)
	local data, reason = load(player)
	if not player.Parent then
		return
	end
	if not data then
		if RunService:IsStudio() then
			warn("Using a temporary save (not saved). Reason:", reason)
			data = defaultData()
			noSave[player] = true
		elseif reason == "locked" then
			player:Kick("Your Freeks are still saving from your last server. Please rejoin in a minute!")
			return
		else
			player:Kick("Couldn't load your Freeks right now. Please rejoin!")
			return
		end
	end
	profiles[player] = data
	for _, callback in loadedCallbacks do
		task.spawn(callback, player, data)
	end
	DataService.changed(player)
end

local function onPlayerRemoving(player: Player)
	if profiles[player] then
		DataService.save(player, true)
	end
	profiles[player] = nil
	noSave[player] = nil
end

function DataService.init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(Config.AUTOSAVE_INTERVAL)
			for player in profiles do
				task.spawn(DataService.save, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				DataService.save(player, true)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.1)
		end
	end)
end

return DataService
