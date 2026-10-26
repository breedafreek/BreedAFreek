-- Everything a player can ask the server to do. Every argument from the client is
-- untrusted, so each handler re-checks ownership, money and limits itself.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local HouseUtil = require(ReplicatedStorage.Shared.HouseUtil)
local Parts = require(ReplicatedStorage.Shared.Parts)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Carried = require(script.Parent.Carried)
local DataService = require(script.Parent.DataService)
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
		rebirths = data.rebirths,
		money = data.money,
		speed = data.speed,
		treadmill = data.treadmill,
		parts = data.parts,
		house = data.house,
		discovered = data.discovered,
		crates = data.crates,
		lastSpin = data.lastSpin,
	}
end
ActionService.snapshot = snapshot

local function ownedPart(data, uid: any)
	if typeof(uid) ~= "string" then
		return nil
	end
	return data.parts[uid]
end

local handlers = {}

-- Puts a backpack part onto the house; whatever was in that slot goes to the backpack.
function handlers.Install(player: Player, data, uid: any)
	local record = ownedPart(data, uid)
	if not record or Carried.is(player, uid) then
		return
	end
	local slotId = Parts.byId[record.id].slot
	local current, currentUid = HouseUtil.installedRecord(data, slotId)
	if currentUid == uid then
		return
	end
	if current and Carried.is(player, currentUid) then
		return notify(player, "Someone is running off with that part! Snatch it back first.", "error")
	end
	data.house[slotId] = uid
	notify(player, "🏠 Installed " .. HouseUtil.displayName(record) .. "!", "success")
end

-- Takes a part off the house and puts it in the backpack (the slot goes back to Basic).
function handlers.Uninstall(player: Player, data, slotId: any)
	if typeof(slotId) ~= "string" or not Parts.slotById[slotId] then
		return
	end
	local current, currentUid = HouseUtil.installedRecord(data, slotId)
	if not current or Carried.is(player, currentUid) then
		return
	end
	if HouseUtil.backpackCount(data) >= GamePasses.backpackSize(player) then
		return notify(player, "Your backpack is full!", "error")
	end
	data.house[slotId] = nil
end

local function sell(player: Player, data, uid: string): number
	local record = data.parts[uid]
	if not record or HouseUtil.installedSlots(data)[uid] or Carried.is(player, uid) then
		return 0
	end
	local price = HouseUtil.sellPrice(record)
	data.parts[uid] = nil
	data.money += price
	return price
end

-- Sells one part from the backpack.
function handlers.Sell(player: Player, data, uid: any)
	if typeof(uid) ~= "string" then
		return
	end
	local name = data.parts[uid] and HouseUtil.displayName(data.parts[uid])
	local price = sell(player, data, uid)
	if price > 0 then
		notify(player, "Sold " .. name .. " for " .. Format.money(price) .. "!", "money")
	end
end

-- Sells everything in the backpack.
function handlers.SellBackpack(player: Player, data)
	local total, count = 0, 0
	for _, uid in HouseUtil.backpack(data) do
		local price = sell(player, data, uid)
		if price > 0 then
			total += price
			count += 1
		end
	end
	if count > 0 then
		notify(player, "Sold " .. count .. " parts for " .. Format.money(total) .. "!", "money")
	end
end

-- Puts the best part for every slot onto the house.
function handlers.InstallBest(player: Player, data)
	local changed = 0
	for _, slot in Parts.SLOTS do
		local current, currentUid = HouseUtil.installedRecord(data, slot.id)
		if current and Carried.is(player, currentUid) then
			continue
		end
		local bestUid, bestIncome = currentUid, HouseUtil.partIncome(current or { id = Parts.basic(slot.id) })
		for uid, record in data.parts do
			if Parts.byId[record.id].slot == slot.id and HouseUtil.partIncome(record) > bestIncome then
				bestUid, bestIncome = uid, HouseUtil.partIncome(record)
			end
		end
		if bestUid ~= currentUid then
			data.house[slot.id] = bestUid
			changed += 1
		end
	end
	if changed > 0 then
		notify(
			player,
			"🏠 Upgraded " .. changed .. " part" .. (if changed == 1 then "" else "s") .. " on your house!",
			"success"
		)
	else
		notify(player, "Your house already has your best parts!", "info")
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

-- Teleports the player home (not while carrying a part: that would skip the run).
local lastHome = {}
function handlers.GoHome(player: Player, _data)
	if StealService.isCarrying(player) then
		return notify(player, "No teleporting with a part! Run it home!", "error")
	end
	if lastHome[player] and os.clock() - lastHome[player] < 3 then
		return
	end
	lastHome[player] = os.clock()
	PlotService.sendHome(player)
end

local quiet = { GoHome = true } -- actions that don't change saved data, so skip the refresh

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
