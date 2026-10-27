-- The Catalog: the first player in the whole game to get each rare item (Legendary and up:
-- house parts, pets, yard items and plants) has their name saved forever. Claims go through UpdateAsync so two servers can't
-- both win, and MessagingService tells every other server right away.

local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Items = require(ReplicatedStorage.Shared.Items)
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local STORE_NAME = "StealALife_Discoveries_v1"
local TOPIC = "PartDiscovered"

-- Only parts this rare or rarer can be claimed.
local MIN_RANK = Rarities.rank.Legendary

local function claimable(partId: string): boolean
	local part = Items.byId[partId]
	return part ~= nil and Rarities.rank[part.rarity] >= MIN_RANK
end

local DiscoveryService = {}

local cache = {} -- [partId] = { name, userId, time }
local claiming = {}
local store = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

local discoveryUpdate = Remotes.get("DiscoveryUpdate")
local notify = Remotes.get("Notify")

-- DataStore keys can be at most 50 characters; longer ids are hashed to fit.
local function storeKey(partId: string): string
	if #partId <= 50 then
		return partId
	end
	local hash = 5381
	for i = 1, #partId do
		hash = (hash * 33 + string.byte(partId, i)) % 4294967296
	end
	return string.format("H%08x%d", hash, #partId)
end

local function announce(partId: string, discovery)
	local isNew = cache[partId] == nil
	cache[partId] = discovery
	discoveryUpdate:FireAllClients(partId, discovery)
	if isNew then
		notify:FireAllClients(
			string.format("%s found the first %s ever!", discovery.name, Items.byId[partId].name),
			"discovery"
		)
	end
end

local function loadAll()
	if not store then
		return
	end
	for _, part in Items.list do
		if claimable(part.id) and not cache[part.id] then
			local ok, value = pcall(store.GetAsync, store, part.id)
			if ok and value then
				cache[part.id] = value
			end
		end
	end
end

-- Call whenever a player gets a part.
function DiscoveryService.claim(player: Player, partId: string)
	if not claimable(partId) or cache[partId] or claiming[partId] then
		return
	end
	claiming[partId] = true

	local mine = { name = player.DisplayName, userId = player.UserId, time = os.time() }
	local winner = mine
	if store then
		local ok, result = pcall(function()
			local existing = nil
			store:UpdateAsync(storeKey(partId), function(old)
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
			claiming[partId] = nil
			return
		end
	end

	announce(partId, winner)
	if winner == mine then
		pcall(MessagingService.PublishAsync, MessagingService, TOPIC, { part = partId, discovery = mine })
	end
	claiming[partId] = nil
end

-- True once someone, anywhere, has found this part.
function DiscoveryService.isDiscovered(partId: string): boolean
	return cache[partId] ~= nil
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
			if typeof(data) == "table" and typeof(data.part) == "string" and claimable(data.part) then
				announce(data.part, data.discovery)
			end
		end)
	end)

	task.spawn(function()
		while true do
			loadAll()
			task.wait(300)
		end
	end)

	-- Re-check parts a player already owns, in case an earlier claim failed.
	local DataService = require(script.Parent.DataService)
	DataService.onLoaded(function(player, data)
		for partId in data.discovered do
			DiscoveryService.claim(player, partId)
		end
	end)
end

return DiscoveryService
