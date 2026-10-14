-- Player-to-player Freek trades within one server.
--
-- Flow: request -> accept -> both sides add Freeks -> both press Ready -> 3 second
-- countdown -> swap. Any change to either offer clears both Ready buttons and stops the
-- countdown, so nobody can swap something out at the last second. Ownership is checked
-- again at the moment of the swap, and both players are saved right after.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ActionService = require(script.Parent.ActionService)
local DataService = require(script.Parent.DataService)

local MAX_OFFER = 8
local REQUEST_SECONDS = 30
local COUNTDOWN_SECONDS = 3

local TradeService = {}

local tradeRemote = Remotes.get("Trade")
local notifyRemote = Remotes.get("Notify")

local trades = {} -- [Player] = trade (both players point at the same table)
local requests = {} -- [target Player] = { from = Player, expires = os.clock() }

local function notify(player: Player, message: string, kind: string?)
	notifyRemote:FireClient(player, message, kind)
end

local function otherSide(trade, player: Player): Player
	return if trade.a == player then trade.b else trade.a
end

local function offerView(player: Player, uids)
	local data = DataService.get(player)
	local list = {}
	for _, uid in uids do
		local freek = data and data.freeks[uid]
		if freek then
			table.insert(list, { uid = uid, species = freek.species, mutation = freek.mutation })
		end
	end
	return list
end

local function push(trade)
	for _, player in { trade.a, trade.b } do
		local other = otherSide(trade, player)
		tradeRemote:FireClient(player, "State", {
			partner = other.DisplayName,
			mine = offerView(player, trade.offers[player]),
			theirs = offerView(other, trade.offers[other]),
			myReady = trade.ready[player] == true,
			theirReady = trade.ready[other] == true,
			countdownEndsAt = trade.countdownEndsAt,
		})
	end
end

local function close(trade, reason: string)
	for _, player in { trade.a, trade.b } do
		if trades[player] == trade then
			trades[player] = nil
		end
		tradeRemote:FireClient(player, "Closed", reason)
	end
	trade.closed = true
end

local function unready(trade)
	trade.ready = {}
	trade.countdownEndsAt = nil
	trade.token += 1
end

-- Checks a side's offer is still theirs and tradeable. Returns nil if fine, else why not.
local function offerProblem(player: Player, uids): string?
	local data = DataService.get(player)
	if not data then
		return player.DisplayName .. " isn't loaded"
	end
	for _, uid in uids do
		local freek = data.freeks[uid]
		if not freek then
			return player.DisplayName .. " no longer has one of their Freeks"
		elseif freek.breeding then
			return player.DisplayName .. " put an offered Freek in the breeding pen"
		end
	end
	return nil
end

local function execute(trade)
	local a, b = trade.a, trade.b
	local offerA, offerB = trade.offers[a], trade.offers[b]
	if #offerA == 0 and #offerB == 0 then
		return close(trade, "Trade cancelled: nothing was offered.")
	end
	local problem = offerProblem(a, offerA) or offerProblem(b, offerB)
	if problem then
		return close(trade, "Trade cancelled: " .. problem .. ".")
	end

	local dataA, dataB = DataService.get(a), DataService.get(b)
	if FreekUtil.count(dataA) - #offerA + #offerB > Config.MAX_FREEKS then
		return close(trade, "Trade cancelled: " .. a.DisplayName .. " has too many Freeks.")
	end
	if FreekUtil.count(dataB) - #offerB + #offerA > Config.MAX_FREEKS then
		return close(trade, "Trade cancelled: " .. b.DisplayName .. " has too many Freeks.")
	end

	-- Take everything out first, then hand it over, so neither side can end up with both.
	local fromA, fromB = {}, {}
	for _, uid in offerA do
		fromA[uid] = dataA.freeks[uid]
		dataA.freeks[uid] = nil
	end
	for _, uid in offerB do
		fromB[uid] = dataB.freeks[uid]
		dataB.freeks[uid] = nil
	end
	local function receive(data, freeks)
		for uid, freek in freeks do
			freek.slot = nil
			freek.breeding = nil
			data.freeks[uid] = freek
			data.discovered[freek.species] = true
		end
	end
	receive(dataA, fromB)
	receive(dataB, fromA)

	close(trade, "Trade complete! New Freeks are in your backpack.")
	for _, player in { a, b } do
		DataService.changed(player)
		task.spawn(DataService.save, player)
	end
end

local function startTrade(a: Player, b: Player)
	local trade = {
		a = a,
		b = b,
		offers = { [a] = {}, [b] = {} },
		ready = {},
		countdownEndsAt = nil,
		token = 0,
	}
	trades[a] = trade
	trades[b] = trade
	push(trade)
end

function TradeService.init()
	ActionService.register("TradeRequest", function(player: Player, _data, targetUserId: any)
		local target = typeof(targetUserId) == "number" and Players:GetPlayerByUserId(targetUserId)
		if not target or target == player or not DataService.get(target) then
			return
		end
		if trades[player] then
			return notify(player, "Finish your current trade first!", "error")
		end
		if trades[target] then
			return notify(player, target.DisplayName .. " is already trading.", "error")
		end
		local pending = requests[target]
		if pending and pending.from == player and os.clock() < pending.expires then
			return notify(player, "Request already sent!", "error")
		end
		requests[target] = { from = player, expires = os.clock() + REQUEST_SECONDS }
		tradeRemote:FireClient(target, "Request", { name = player.DisplayName, userId = player.UserId })
		notify(player, "Trade request sent to " .. target.DisplayName .. ".", "success")
	end)

	ActionService.register("TradeRespond", function(player: Player, _data, fromUserId: any, accept: any)
		local request = requests[player]
		if not request or request.from.UserId ~= fromUserId then
			return
		end
		requests[player] = nil
		local from = request.from
		if os.clock() > request.expires or not from.Parent then
			return notify(player, "That trade request expired.", "error")
		end
		if accept ~= true then
			return notify(from, player.DisplayName .. " declined your trade.", "error")
		end
		if trades[player] or trades[from] then
			return notify(player, "One of you is already trading.", "error")
		end
		startTrade(from, player)
	end)

	ActionService.register("TradeOffer", function(player: Player, data, uid: any, add: any)
		local trade = trades[player]
		if not trade or typeof(uid) ~= "string" then
			return
		end
		local offer = trade.offers[player]
		local index = table.find(offer, uid)
		if add == true then
			local freek = data.freeks[uid]
			if index or not freek or freek.breeding then
				return
			end
			if #offer >= MAX_OFFER then
				return notify(player, "You can offer up to " .. MAX_OFFER .. " Freeks.", "error")
			end
			table.insert(offer, uid)
		elseif index then
			table.remove(offer, index)
		else
			return
		end
		unready(trade)
		push(trade)
	end)

	ActionService.register("TradeReady", function(player: Player, _data, ready: any)
		local trade = trades[player]
		if not trade then
			return
		end
		if ready == true then
			trade.ready[player] = true
		else
			unready(trade)
		end

		if trade.ready[trade.a] and trade.ready[trade.b] and not trade.countdownEndsAt then
			trade.countdownEndsAt = Workspace:GetServerTimeNow() + COUNTDOWN_SECONDS
			local token = trade.token
			task.delay(COUNTDOWN_SECONDS, function()
				if not trade.closed and trade.token == token then
					execute(trade)
				end
			end)
		end
		push(trade)
	end)

	ActionService.register("TradeCancel", function(player: Player)
		local trade = trades[player]
		if trade then
			close(trade, player.DisplayName .. " cancelled the trade.")
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local trade = trades[player]
		if trade then
			close(trade, player.DisplayName .. " left the game.")
		end
		requests[player] = nil
		for target, request in requests do
			if request.from == player then
				requests[target] = nil
			end
		end
	end)
end

return TradeService
