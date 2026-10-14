-- Everything a player can ask the server to do. Every argument from the client is
-- untrusted, so each handler re-checks ownership, money and limits itself.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Freeks = require(ReplicatedStorage.Shared.Freeks)
local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)
local DiscoveryService = require(script.Parent.DiscoveryService)
local Recipes = require(script.Parent.Recipes)

local ActionService = {}

local notifyRemote = Remotes.get("Notify")
local stateRemote = Remotes.get("State")
local rng = Random.new()
local lastAction = {} -- [Player] = os.clock()

local function notify(player: Player, message: string, kind: string?)
	notifyRemote:FireClient(player, message, kind)
end

-- What the client is allowed to see of its own save.
local function snapshot(data)
	return {
		money = data.money,
		slots = data.slots,
		freeks = data.freeks,
		breeding = data.breeding,
		discovered = data.discovered,
	}
end

local function freeSlot(data): number?
	local used = {}
	for _, freek in data.freeks do
		if freek.slot then
			used[freek.slot] = true
		end
	end
	for i = 1, data.slots do
		if not used[i] then
			return i
		end
	end
	return nil
end

-- Adds a Freek, puts it in the yard if there's room, and records the discovery.
local function giveFreek(player: Player, data, species: string, mutation: string?)
	local uid = HttpService:GenerateGUID(false)
	data.freeks[uid] = { species = species, mutation = mutation, slot = freeSlot(data) }
	local isNew = not data.discovered[species]
	data.discovered[species] = true
	task.spawn(DiscoveryService.claim, player, species)
	return uid, isNew
end

local function ownedFreek(data, uid: any)
	if typeof(uid) ~= "string" then
		return nil
	end
	return data.freeks[uid]
end

local handlers = {}

function handlers.BuyFreek(player: Player, data, speciesId: any)
	local species = typeof(speciesId) == "string" and Freeks.byId[speciesId]
	if not species or not species.price then
		return
	end
	if FreekUtil.count(data) >= Config.MAX_FREEKS then
		return notify(player, "You have too many Freeks! Sell some first.", "error")
	end
	if data.money < species.price then
		return notify(player, "Not enough money!", "error")
	end
	data.money -= species.price
	giveFreek(player, data, species.id, nil)
	notify(player, "You got a " .. species.name .. "!", "success")
end

function handlers.BuySlot(player: Player, data)
	if data.slots >= Config.MAX_SLOTS then
		return notify(player, "Your yard is as big as it gets!", "error")
	end
	local price = Config.slotPrice(data.slots)
	if data.money < price then
		return notify(player, "Not enough money! A new slot costs " .. Format.money(price), "error")
	end
	data.money -= price
	data.slots += 1
	notify(player, "Your yard grew! You now have " .. data.slots .. " slots.", "success")
end

function handlers.Place(player: Player, data, uid: any)
	local freek = ownedFreek(data, uid)
	if not freek or freek.breeding or freek.slot then
		return
	end
	local slot = freeSlot(data)
	if not slot then
		return notify(player, "Your yard is full! Buy more slots or remove a Freek.", "error")
	end
	freek.slot = slot
end

function handlers.Unplace(_player: Player, data, uid: any)
	local freek = ownedFreek(data, uid)
	if freek then
		freek.slot = nil
	end
end

function handlers.Sell(player: Player, data, uid: any)
	local freek = ownedFreek(data, uid)
	if not freek or freek.breeding then
		return
	end
	local value = FreekUtil.sellValue(freek)
	data.freeks[uid] = nil
	data.money += value
	notify(player, "Sold " .. FreekUtil.displayName(freek) .. " for " .. Format.money(value), "money")
end

function handlers.StartBreed(player: Player, data, uidA: any, uidB: any)
	if data.breeding then
		return notify(player, "Your pen is already busy!", "error")
	end
	local a, b = ownedFreek(data, uidA), ownedFreek(data, uidB)
	if not a or not b or uidA == uidB or a.breeding or b.breeding then
		return
	end
	if FreekUtil.count(data) >= Config.MAX_FREEKS then
		return notify(player, "No room for a baby! Sell a Freek first.", "error")
	end
	a.slot, b.slot = nil, nil
	a.breeding, b.breeding = true, true
	local duration = FreekUtil.breedTime(a, b)
	data.breeding = { a = uidA, b = uidB, endsAt = os.time() + duration }
	notify(player, "Breeding started! Back in " .. Format.time(duration) .. ".", "success")
end

function handlers.ClaimBreed(player: Player, data)
	local breeding = data.breeding
	if not breeding or os.time() < breeding.endsAt then
		return
	end
	local a, b = data.freeks[breeding.a], data.freeks[breeding.b]
	data.breeding = nil
	if not a or not b then
		return
	end
	a.breeding, b.breeding = nil, nil

	local species, mutation = Recipes.roll(a, b, rng)
	-- Parents go back into the yard first so they keep earning.
	a.slot = freeSlot(data)
	b.slot = freeSlot(data)
	local _, isNew = giveFreek(player, data, species, mutation)

	local name = FreekUtil.displayName({ species = species, mutation = mutation })
	if isNew then
		notify(player, "NEW FREEK! You bred a " .. name .. "!", "discovery")
	else
		notify(player, "You bred a " .. name .. "!", "success")
	end
end

function ActionService.init()
	Remotes.get("GetState").OnServerInvoke = function(player)
		local data = DataService.waitFor(player)
		return data and snapshot(data)
	end

	DataService.onChanged(function(player, data)
		stateRemote:FireClient(player, snapshot(data))
	end)

	Remotes.get("Action").OnServerEvent:Connect(function(player, action, ...)
		local handler = typeof(action) == "string" and handlers[action]
		local data = DataService.get(player)
		if not handler or not data then
			return
		end
		local now = os.clock()
		if lastAction[player] and now - lastAction[player] < 0.15 then
			return
		end
		lastAction[player] = now

		local ok, err = pcall(handler, player, data, ...)
		if not ok then
			warn("Action", action, "failed for", player.Name, err)
		end
		DataService.changed(player)
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastAction[player] = nil
	end)
end

return ActionService
