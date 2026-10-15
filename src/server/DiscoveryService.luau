-- The Discovery Book: the first player in the whole game to get each species has their
-- name saved forever. Claims go through UpdateAsync so two servers can't both win, and
-- MessagingService tells every other server right away.

local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Freeks = require(ReplicatedStorage.Shared.Freeks)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local STORE_NAME = "FuseAFreek_Discoveries_v1"
local TOPIC = "FreekDiscovered"

local DiscoveryService = {}

local cache = {} -- [speciesId] = { name, userId, time }
local claiming = {}
local store = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

local discoveryUpdate = Remotes.get("DiscoveryUpdate")
local notify = Remotes.get("Notify")

-- DataStore keys can be at most 50 characters; long hybrid ids are hashed to fit.
local function storeKey(speciesId: string): string
	if #speciesId <= 50 then
		return speciesId
	end
	local hash = 5381
	for i = 1, #speciesId do
		hash = (hash * 33 + string.byte(speciesId, i)) % 4294967296
	end
	return string.format("H%08x%d", hash, #speciesId)
end

local function announce(speciesId: string, discovery)
	local isNew = cache[speciesId] == nil
	cache[speciesId] = discovery
	discoveryUpdate:FireAllClients(speciesId, discovery)
	if isNew then
		local species = Freeks.byId[speciesId]
		notify:FireAllClients(
			string.format("%s discovered %s for the first time ever!", discovery.name, species.name),
			"discovery"
		)
	end
end

local function loadAll()
	if not store then
		return
	end
	for _, species in Freeks.list do
		if not species.price and not cache[species.id] then
			local ok, value = pcall(store.GetAsync, store, species.id)
			if ok and value then
				cache[species.id] = value
			end
		end
	end
end

-- Call whenever a player gets a species. Shop (starter) Freeks aren't claimable.
function DiscoveryService.claim(player: Player, speciesId: string)
	local species = Freeks.byId[speciesId]
	if not species or species.price or cache[speciesId] or claiming[speciesId] then
		return
	end
	claiming[speciesId] = true

	local mine = { name = player.DisplayName, userId = player.UserId, time = os.time() }
	local winner = mine
	if store then
		local ok, result = pcall(function()
			local existing = nil
			store:UpdateAsync(storeKey(speciesId), function(old)
				existing = old
				if old then
					return nil
				end
				return mine
			end)
			return existing
		end)
		if ok then
			winner = result or mine
		elseif not RunService:IsStudio() then
			warn("Discovery claim failed:", result)
			claiming[speciesId] = nil
			return
		end
	end

	announce(speciesId, winner)
	if winner == mine then
		pcall(MessagingService.PublishAsync, MessagingService, TOPIC, { species = speciesId, discovery = mine })
	end
	claiming[speciesId] = nil
end

-- True once someone, anywhere, has found this species.
function DiscoveryService.isDiscovered(speciesId: string): boolean
	return cache[speciesId] ~= nil
end

function DiscoveryService.init()
	Remotes.get("GetDiscoveries").OnServerInvoke = function()
		return cache
	end

	-- In the background: SubscribeAsync can hang for a long time in Studio, and nothing
	-- else should wait on it.
	task.spawn(pcall, function()
		MessagingService:SubscribeAsync(TOPIC, function(message)
			local data = message.Data
			if typeof(data) == "table" and Freeks.byId[data.species] then
				announce(data.species, data.discovery)
			end
		end)
	end)

	task.spawn(function()
		while true do
			loadAll()
			task.wait(300)
		end
	end)

	-- Re-check species a player already owns, in case an earlier claim failed.
	local DataService = require(script.Parent.DataService)
	DataService.onLoaded(function(player, data)
		for speciesId in data.discovered do
			DiscoveryService.claim(player, speciesId)
		end
	end)
end

return DiscoveryService
