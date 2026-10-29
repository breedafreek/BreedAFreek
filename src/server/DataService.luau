-- Loads and saves each player's data with a session lock, so the same player in two
-- servers at once (e.g. a fast rejoin) can't duplicate or lose house parts.
--
-- In Studio without "Enable Studio Access to API Services", saving is skipped and a
-- fresh save is used so the game is still testable.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Items = require(ReplicatedStorage.Shared.Items)

local STORE_NAME = "StealALife_Players_v1"

local DataService = {}

local profiles = {} -- [Player] = data
local noSave = {} -- [Player] = true when running without DataStores
local loadedCallbacks = {}
local changedCallbacks = {}

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

-- Which item catalogue the save's items are from. Version 2 is the 80 items in ten zones
-- (the owner's reference sheet); everything from before (house parts, Freeks, the old yard
-- items and plants) was wiped when it came in.
local ITEMS_VERSION = 2

local function defaultData()
	return {
		version = 1,
		itemsVersion = ITEMS_VERSION,
		money = Config.START_MONEY,
		speed = 0, -- trained on the treadmill; decides how fast you run
		treadmill = 1, -- treadmill level
		plotLevel = 1, -- how many yard spots, garden beds and pets (Config.plotSpaces)
		houseLevel = 1, -- the house's size, style and bonus (Config.HOUSE_*)
		parts = {}, -- [uid] = { id = itemId, mutations? }: everything owned (see LifeUtil)
		pen = {}, -- [uid] = true for pets out in the yard
		yard = {}, -- ["1".."6"] = uid of the yard item on that spot
		garden = {}, -- ["1".."6"] = uid of the plant in that bed
		nests = {}, -- ["1".."5"] = { zone, rarity, endsAt, mutations? }: eggs growing
		nextUid = 1,
		discovered = {}, -- [itemId] = true for every item this player has owned
		crates = {}, -- [crateId] = how many unopened Mystery Boxes (won on the wheel)
		receipts = {}, -- recent Robux purchase IDs, so a purchase is never granted twice
		lastSpin = 0, -- os.time() of the last Lucky Wheel spin
		lastSeen = os.time(),
		firstJoin = os.time(), -- when they first played (starts the Starter Pack countdown)
		starterBought = false,
	}
end

-- Saves from before plot and house levels: start them at the levels that fit everything
-- they already have out, so nothing gets put away.
local function fitLevels(data)
	if data.plotLevel == nil then
		local need = 1
		for key in data.yard or {} do
			need = math.max(need, (tonumber(key) or 1) - 1)
		end
		for key in data.garden or {} do
			need = math.max(need, (tonumber(key) or 1) - 1)
		end
		local pets = 0
		for _ in data.pen or {} do
			pets += 1
		end
		need = math.max(need, pets - 3)
		data.plotLevel = math.clamp(need, 1, Config.PLOT_MAX)
	end
	if data.houseLevel == nil then
		local need = 1
		for slotId in data.house or {} do
			need = math.max(need, Config.HOUSE_SLOT_LEVEL[slotId] or 1)
		end
		data.houseLevel = need
	end
end

-- Saves from an older item catalogue lose every item (and the eggs in their nests, which
-- would hatch old items); money, Speed, levels and boxes stay.
local function wipeOldItems(data)
	if (data.itemsVersion or 1) >= ITEMS_VERSION then
		return
	end
	data.parts = {}
	data.pen = {}
	data.yard = {}
	data.garden = {}
	data.nests = {}
	data.discovered = {}
	data.house = nil -- house parts are gone: the house comes from the house level
	data.itemsVersion = ITEMS_VERSION
end

local function reconcile(data)
	fitLevels(data)
	wipeOldItems(data)
	for key, value in defaultData() do
		if data[key] == nil then
			data[key] = value
		end
	end
	data.rebirths = nil -- rebirths were taken out of the game
	if Config.TEST_MONEY and data.money < Config.TEST_MONEY then
		data.money = Config.TEST_MONEY
	end
	-- Items that no longer exist are dropped, and places pointing at missing items emptied.
	for uid, record in data.parts do
		if not Items.byId[record.id] then
			data.parts[uid] = nil
		else
			record.mutations = Mutations.pack(record.mutations)
			record.size = nil -- the old size tiers, replaced by weights
			local function valid(n)
				return type(n) == "number" and n > 0 and n < math.huge
			end
			if not valid(record.weight) or not valid(record.baseWeight) then
				record.weight, record.baseWeight = nil, nil
			end
		end
	end
	for uid in data.pen do
		local record = data.parts[uid]
		if not record or Items.byId[record.id].kind ~= "Pet" then
			data.pen[uid] = nil
		end
	end
	data.plotLevel = math.clamp(math.floor(tonumber(data.plotLevel) or 1), 1, Config.PLOT_MAX)
	data.houseLevel = math.clamp(math.floor(tonumber(data.houseLevel) or 1), 1, Config.HOUSE_MAX)
	local spaces = Config.plotSpaces(data.plotLevel)
	for kind, where in { Yard = data.yard, Plant = data.garden } do
		local count = if kind == "Yard" then spaces.yard else spaces.garden
		for spot, uid in where do
			local record = data.parts[uid]
			if not record or Items.byId[record.id].kind ~= kind or (tonumber(spot) or 0) > count then
				where[spot] = nil
			end
		end
	end
	return data
end

-- A fresh uid for a new item.
function DataService.newUid(data): string
	local uid = "p" .. data.nextUid
	data.nextUid += 1
	return uid
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

-- Saves the player's data. Returns true once it's safely stored (or if this is a
-- temporary Studio save that's never stored).
function DataService.save(player: Player, release: boolean?): boolean
	local data = profiles[player]
	if not data then
		return false
	end
	if noSave[player] then
		return true
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
			return true
		end
		warn("Save failed for", player.Name, err)
		task.wait(attempt)
	end
	return false
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

-- Call after changing a player's data so their house and UI refresh.
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
			data = reconcile(defaultData())
			noSave[player] = true
		elseif reason == "locked" then
			player:Kick("Your house is still saving from your last server. Please rejoin in a minute!")
			return
		else
			player:Kick("Couldn't load your house right now. Please rejoin!")
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
