-- Everything a player can ask the server to do. Every argument from the client is
-- untrusted, so each handler re-checks ownership, money and limits itself.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local Items = require(ReplicatedStorage.Shared.Items)
local LifeUtil = require(ReplicatedStorage.Shared.LifeUtil)
local Parts = require(ReplicatedStorage.Shared.Parts)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)
local NestService = require(script.Parent.NestService)
local PlotService = require(script.Parent.PlotService)
local StealService = require(script.Parent.StealService)

local ActionService = {}

local notifyRemote = Remotes.get("Notify")
local stateRemote = Remotes.get("State")
local lastAction = {} -- [Player] = os.clock()

local function notify(player: Player, message: string, kind: string?)
	notifyRemote:FireClient(player, message, kind)
end

-- What the client is allowed to see of its own save.
local function snapshot(data)
	return {
		money = data.money,
		speed = data.speed,
		treadmill = data.treadmill,
		plotLevel = data.plotLevel,
		houseLevel = data.houseLevel,
		parts = data.parts,
		house = data.house,
		pen = data.pen,
		yard = data.yard,
		garden = data.garden,
		nests = data.nests,
		discovered = data.discovered,
		crates = data.crates,
		lastSpin = data.lastSpin,
	}
end
ActionService.snapshot = snapshot

local function ownedItem(data, uid: any)
	if typeof(uid) ~= "string" then
		return nil
	end
	return data.parts[uid]
end

local handlers = {}

-- Puts an item from the backpack out: a house part onto its slot, a pet into the yard, a
-- yard item or plant onto `spot` ("1".."6"; the first free one if not given). Whatever was
-- there goes to the backpack.
function handlers.Place(player: Player, data, uid: any, spot: any)
	local record = ownedItem(data, uid)
	local item = record and Items.byId[record.id]
	if not item or LifeUtil.placed(data)[uid] then
		return
	end
	local spaces = LifeUtil.spaces(data)
	if item.kind == "House" then
		if not LifeUtil.slotOpen(data, item.slot) then
			return notify(
				player,
				"Upgrade your house to level " .. Config.HOUSE_SLOT_LEVEL[item.slot] .. " to add a " .. item.slot .. "!",
				"error"
			)
		end
		data.house[item.slot] = uid
	elseif item.kind == "Pet" then
		local pets = LifeUtil.pets(data)
		if #pets >= spaces.pets then
			-- Swap out the worst pet.
			table.sort(pets, function(a, b)
				return LifeUtil.itemIncome(data.parts[a]) < LifeUtil.itemIncome(data.parts[b])
			end)
			data.pen[pets[1]] = nil
		end
		data.pen[uid] = true
	else
		local where = if item.kind == "Yard" then data.yard else data.garden
		local count = if item.kind == "Yard" then spaces.yard else spaces.garden
		local key = typeof(spot) == "string" and tonumber(spot) and spot or nil
		if key and (tonumber(key) < 1 or tonumber(key) > count or key ~= tostring(tonumber(key))) then
			key = nil
		end
		if not key then
			for n = 1, count do
				if not where[tostring(n)] then
					key = tostring(n)
					break
				end
			end
		end
		if not key then
			return notify(player, "All your spots are full! Pick one to swap.", "error")
		end
		where[key] = uid
	end
	notify(player, "✨ " .. LifeUtil.displayName(record) .. " is out!", "success")
end

-- Takes an item that's out back into the backpack.
function handlers.TakeOff(player: Player, data, uid: any)
	local record = ownedItem(data, uid)
	if not record or not LifeUtil.placed(data)[uid] then
		return
	end
	if LifeUtil.backpackCount(data) >= GamePasses.backpackSize(player) then
		return notify(player, "Your backpack is full!", "error")
	end
	LifeUtil.takeOff(data, uid)
end

-- Takes a part off the house by slot (the slot goes back to Basic).
function handlers.Uninstall(player: Player, data, slotId: any)
	if typeof(slotId) ~= "string" or not Parts.slotById[slotId] then
		return
	end
	local _, uid = LifeUtil.installedRecord(data, slotId)
	if uid then
		handlers.TakeOff(player, data, uid)
	end
end

local function sell(data, uid: string): number
	local record = data.parts[uid]
	if not record or LifeUtil.placed(data)[uid] then
		return 0
	end
	local price = LifeUtil.sellPrice(record)
	data.parts[uid] = nil
	data.money += price
	return price
end

-- Sells one item from the backpack.
function handlers.Sell(player: Player, data, uid: any)
	if typeof(uid) ~= "string" then
		return
	end
	local name = data.parts[uid] and LifeUtil.displayName(data.parts[uid])
	local price = sell(data, uid)
	if price > 0 then
		notify(player, "Sold " .. name .. " for " .. Format.money(price) .. "!", "money")
	end
end

-- Sells everything in the backpack.
function handlers.SellBackpack(player: Player, data)
	local total, count = 0, 0
	for _, uid in LifeUtil.backpack(data) do
		local price = sell(data, uid)
		if price > 0 then
			total += price
			count += 1
		end
	end
	if count > 0 then
		notify(player, "Sold " .. count .. " items for " .. Format.money(total) .. "!", "money")
	end
end

-- Puts out the best of everything (best items first, so each spot ends up with the best).
local function putOutBest(data): number
	local changed = 0
	for _, uid in LifeUtil.backpack(data) do
		if LifeUtil.placeIfBetter(data, uid) ~= "backpack" then
			changed += 1
		end
	end
	return changed
end

function handlers.PlaceBest(player: Player, data)
	local changed = putOutBest(data)
	if changed > 0 then
		notify(
			player,
			"✨ Put out " .. changed .. " better item" .. (if changed == 1 then "" else "s") .. "!",
			"success"
		)
	else
		notify(player, "Your best items are already out!", "info")
	end
end
handlers.InstallBest = handlers.PlaceBest

-- Hatches the egg in a nest (from the UI; the nest's prompt does the same).
function handlers.Hatch(player: Player, _data, n: any)
	if typeof(n) ~= "number" or n ~= n // 1 or n < 1 or n > PlotService.NEST_MAX then
		return
	end
	local problem = NestService.hatch(player, n)
	if problem then
		notify(player, problem, "error")
	end
end

-- Upgrades the treadmill one level.
function handlers.UpgradeTreadmill(player: Player, data)
	if data.treadmill >= Config.TREADMILL_MAX then
		return notify(player, "Your treadmill is maxed out!", "error")
	end
	local cost = Config.treadmillCost(data.treadmill)
	if data.money < cost then
		return notify(player, "You need " .. Format.money(cost) .. " to upgrade your treadmill.", "error")
	end
	data.money -= cost
	data.treadmill += 1
	notify(player, "⚡ Treadmill upgraded to level " .. data.treadmill .. "!", "success")
end

-- Upgrades the plot one level: another yard spot, garden bed and pet place.
function handlers.UpgradePlot(player: Player, data)
	local level = data.plotLevel or 1
	if level >= Config.PLOT_MAX then
		return notify(player, "Your plot is as big as it gets!", "error")
	end
	local cost = Config.plotCost(level)
	if data.money < cost then
		return notify(player, "You need " .. Format.money(cost) .. " to upgrade your plot.", "error")
	end
	data.money -= cost
	data.plotLevel = level + 1
	notify(player, "🏡 Plot upgraded to level " .. data.plotLevel .. "! More room for your stuff.", "success")
	-- Fill the new room with the best of the backpack.
	putOutBest(data)
end

-- Upgrades the house one level: bigger, and some levels open up a new slot.
function handlers.UpgradeHouse(player: Player, data)
	local level = data.houseLevel or 1
	if level >= Config.HOUSE_MAX then
		return notify(player, "Your house is as big as it gets!", "error")
	end
	local cost = Config.houseCost(level)
	if data.money < cost then
		return notify(player, "You need " .. Format.money(cost) .. " to upgrade your house.", "error")
	end
	data.money -= cost
	data.houseLevel = level + 1
	local opened = nil
	for slotId, at in Config.HOUSE_SLOT_LEVEL do
		if at == data.houseLevel then
			opened = slotId
		end
	end
	notify(
		player,
		"🏠 House upgraded to level "
			.. data.houseLevel
			.. "!"
			.. (if opened then " New: " .. opened .. "!" else " It's bigger!"),
		"success"
	)
	if opened then
		putOutBest(data)
	end
end

-- Teleports the player home (not while carrying an egg: that would skip the run).
local lastHome = {}
function handlers.GoHome(player: Player, _data)
	if StealService.isCarrying(player) then
		return notify(player, "No teleporting with an egg! Run it home!", "error")
	end
	if lastHome[player] and os.clock() - lastHome[player] < 3 then
		return
	end
	lastHome[player] = os.clock()
	PlotService.sendHome(player)
end

local quiet = { GoHome = true, Hatch = true } -- actions that don't change saved data, so skip the refresh

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
		lastHome[player] = nil
	end)
end

return ActionService
