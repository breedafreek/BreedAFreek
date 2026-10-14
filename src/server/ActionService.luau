-- Everything a player can ask the server to do. Every argument from the client is
-- untrusted, so each handler re-checks ownership, money and limits itself.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Carried = require(script.Parent.Carried)
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
		rebirths = data.rebirths,
		money = data.money,
		slots = FreekUtil.totalSlots(data),
		boughtSlots = data.slots,
		passSlots = data.passSlots or 0,
		freeks = data.freeks,
		breeding = data.breeding,
		breeding2 = data.breeding2,
		discovered = data.discovered,
	}
end

-- Adds a Freek, puts it in the yard if there's room, and records the discovery.
local function giveFreek(player: Player, data, species: string, mutation: string?)
	local uid = HttpService:GenerateGUID(false)
	data.freeks[uid] = { species = species, mutation = mutation, slot = FreekUtil.freeSlot(data) }
	local isNew = not data.discovered[species]
	data.discovered[species] = true
	task.spawn(DiscoveryService.claim, player, species)
	return uid, isNew
end

ActionService.giveFreek = giveFreek

local function ownedFreek(data, uid: any)
	if typeof(uid) ~= "string" then
		return nil
	end
	return data.freeks[uid]
end

local handlers = {}

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
	if not freek or freek.breeding or freek.slot or Carried.is(player, uid) then
		return
	end
	local slot = FreekUtil.freeSlot(data)
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
	if Carried.is(player, uid) then
		return notify(player, "Someone is stealing that Freek! Catch them!", "error")
	end
	local value = FreekUtil.sellValue(freek)
	data.freeks[uid] = nil
	data.money += value
	notify(player, "Sold " .. FreekUtil.displayName(freek) .. " for " .. Format.money(value), "money")
end

-- penIndex is optional: with no pen given, the first free pen is used.
function handlers.StartBreed(player: Player, data, uidA: any, uidB: any, penIndex: any)
	local pens = GamePasses.penCount(player)
	local index = nil
	if typeof(penIndex) == "number" and penIndex >= 1 and penIndex <= pens and not FreekUtil.pen(data, penIndex) then
		index = penIndex
	else
		for i = 1, pens do
			if not FreekUtil.pen(data, i) then
				index = i
				break
			end
		end
	end
	if not index then
		return notify(player, if pens > 1 then "Both your pens are busy!" else "Your pen is already busy!", "error")
	end
	local a, b = ownedFreek(data, uidA), ownedFreek(data, uidB)
	if not a or not b or uidA == uidB or a.breeding or b.breeding then
		return
	end
	if Carried.is(player, uidA) or Carried.is(player, uidB) then
		return notify(player, "Someone is stealing that Freek! Catch them!", "error")
	end
	if FreekUtil.count(data) >= GamePasses.maxFreeks(player) then
		return notify(player, "No room for a baby! Sell a Freek first.", "error")
	end
	a.slot, b.slot = nil, nil
	a.breeding, b.breeding = true, true
	local duration = math.ceil(FreekUtil.breedTime(a, b) * GamePasses.breedTimeMultiplier(player))
	data[FreekUtil.PEN_KEYS[index]] = { a = uidA, b = uidB, endsAt = os.time() + duration }
	notify(player, "Breeding started! Back in " .. Format.time(duration) .. ".", "success")
end

-- penIndex is optional: with no pen given, the first ready pen is collected.
function handlers.ClaimBreed(player: Player, data, penIndex: any)
	local index = nil
	for i in FreekUtil.PEN_KEYS do
		local pen = FreekUtil.pen(data, i)
		if pen and os.time() >= pen.endsAt and (penIndex == nil or penIndex == i) then
			index = i
			break
		end
	end
	if not index then
		return
	end
	local key = FreekUtil.PEN_KEYS[index]
	local breeding = data[key]
	local a, b = data.freeks[breeding.a], data.freeks[breeding.b]
	data[key] = nil
	if not a or not b then
		return
	end
	a.breeding, b.breeding = nil, nil

	local species, mutation = Recipes.roll(a, b, rng)
	-- Parents go back into the yard first so they keep earning.
	a.slot = FreekUtil.freeSlot(data)
	b.slot = FreekUtil.freeSlot(data)
	local _, isNew = giveFreek(player, data, species, mutation)

	local name = FreekUtil.displayName({ species = species, mutation = mutation })
	if isNew then
		notify(player, "NEW FREEK! You bred a " .. name .. "!", "discovery")
	else
		notify(player, "You bred a " .. name .. "!", "success")
	end
end

local quiet = {} -- actions that don't change saved data, so skip the refresh

-- Lets other services add actions (they get the same rate limit and refresh).
-- Pass isQuiet = true for actions that never change the player's data.
function ActionService.register(name: string, handler, isQuiet: boolean?)
	handlers[name] = handler
	quiet[name] = isQuiet == true
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
		if not quiet[action] then
			DataService.changed(player)
		end
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastAction[player] = nil
	end)
end

return ActionService
