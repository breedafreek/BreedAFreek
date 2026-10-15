-- Lucky Crates, the daily Lucky Wheel and Lucky Hour events (rules and odds in
-- shared/Luck.luau). All rolls happen here; the client only shows the result
-- (the LuckResult remote) with a reveal animation.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Format = require(ReplicatedStorage.Shared.Format)
local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local Freeks = require(ReplicatedStorage.Shared.Freeks)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local Luck = require(ReplicatedStorage.Shared.Luck)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Seasons = require(ReplicatedStorage.Shared.Seasons)

local ActionService = require(script.Parent.ActionService)

local LuckService = {}

local rng = Random.new()
local notifyRemote = Remotes.get("Notify")
local resultRemote = Remotes.get("LuckResult")

local function notify(player: Player, message: string, kind: string?)
	notifyRemote:FireClient(player, message, kind)
end

local function announce(message: string)
	for _, player in Players:GetPlayers() do
		notify(player, message, "discovery")
	end
end

local function rollWeighted(weights: { [string]: number }): string
	local total = 0
	for _, weight in weights do
		total += weight
	end
	local roll = rng:NextNumber() * total
	for _, rarity in Rarities.order do
		local weight = weights[rarity]
		if weight then
			roll -= weight
			if roll <= 0 then
				return rarity
			end
		end
	end
	return Rarities.order[1]
end

-- A random species of that rarity (or the next rarity down that has any).
local function pickSpecies(rarity: string)
	local rank = Rarities.rank[rarity]
	while rank >= 1 do
		local pool = {}
		for _, species in Freeks.list do
			if species.rarity == Rarities.order[rank] and species.rarity ~= "Secret" and Seasons.available(species) then
				table.insert(pool, species)
			end
		end
		if #pool > 0 then
			return pool[rng:NextInteger(1, #pool)]
		end
		rank -= 1
	end
	return Freeks.list[1]
end

local function rollMutations(boost: number): { string }?
	for _, mutation in Mutations.list do
		if rng:NextNumber() < mutation.chance * boost then
			return { mutation.id }
		end
	end
	return nil
end

local function hasRoom(player: Player, data): boolean
	return FreekUtil.count(data) < GamePasses.maxFreeks(player)
end

-- Gives the player a Freek and tells their client to show the reveal.
local function giveFreek(player: Player, data, species, mutations, reveal)
	local _, isNew = ActionService.giveFreek(player, data, species.id, mutations)
	local freek = { species = species.id, mutations = mutations }
	reveal.freek = freek
	reveal.isNew = isNew
	reveal.rarity = species.rarity
	resultRemote:FireClient(player, reveal)
	if Rarities.rank[species.rarity] >= Rarities.rank.Legendary then
		announce(player.DisplayName .. " got a " .. species.rarity .. " " .. FreekUtil.displayName(freek) .. "!")
	end
end

local function openCrate(player: Player, data, crate)
	local species = pickSpecies(rollWeighted(crate.odds))
	giveFreek(player, data, species, rollMutations(crate.mutation), { kind = "crate", crate = crate.id })
end

local function buyCrate(player: Player, data, crateId: any)
	local crate = typeof(crateId) == "string" and Luck.crateById[crateId]
	if not crate then
		return
	end
	if not hasRoom(player, data) then
		return notify(player, "You have too many Freeks! Sell or fuse some first.", "error")
	end
	local price = Luck.cratePrice(crate)
	if data.money < price then
		return notify(player, "Not enough money! It costs " .. Format.money(price) .. ".", "error")
	end
	data.money -= price
	openCrate(player, data, crate)
end

-- Opens a crate the player already owns (won on the wheel).
local function openOwnedCrate(player: Player, data, crateId: any)
	local crate = typeof(crateId) == "string" and Luck.crateById[crateId]
	if not crate or (data.crates[crate.id] or 0) < 1 then
		return
	end
	if not hasRoom(player, data) then
		return notify(player, "You have too many Freeks! Sell or fuse some first.", "error")
	end
	data.crates[crate.id] -= 1
	openCrate(player, data, crate)
end

local function spinCooldown(player: Player): number
	return if GamePasses.has(player, "VIP") then Luck.VIP_SPIN_COOLDOWN else Luck.SPIN_COOLDOWN
end

local function coinPrize(data, minutes: number): number
	return math.max(Luck.MIN_COIN_PRIZE, math.floor(FreekUtil.yardIncome(data) * 60 * minutes))
end

local function spin(player: Player, data)
	local now = os.time()
	if now - (data.lastSpin or 0) < spinCooldown(player) then
		return notify(player, "Your next free spin isn't ready yet!", "error")
	end
	data.lastSpin = now

	local total = 0
	for _, slice in Luck.WHEEL do
		total += slice.weight
	end
	local roll = rng:NextNumber() * total
	local index = #Luck.WHEEL
	for i, slice in Luck.WHEEL do
		roll -= slice.weight
		if roll <= 0 then
			index = i
			break
		end
	end
	local slice = Luck.WHEEL[index]
	local reveal = { kind = "wheel", slice = index }

	if slice.golden and hasRoom(player, data) then
		local species = pickSpecies(rollWeighted(Luck.crateById.Silver.odds))
		return giveFreek(player, data, species, { "Golden" }, reveal)
	end
	if slice.crate then
		data.crates[slice.crate] = (data.crates[slice.crate] or 0) + 1
		reveal.crate = slice.crate
		if slice.crate == "Diamond" then
			announce(player.DisplayName .. " hit the JACKPOT on the Lucky Wheel!")
		end
	else
		-- Coins (also the fallback for a Golden Freek when the barn is full).
		local amount = coinPrize(data, slice.minutes or 10)
		data.money += amount
		reveal.coins = amount
	end
	resultRemote:FireClient(player, reveal)
end

-- Runs Lucky Hour events forever: a random one every so often, announced to everyone.
local function runEvents()
	task.wait(Luck.FIRST_EVENT_AFTER)
	local ids = {}
	for id in Luck.EVENTS do
		table.insert(ids, id)
	end
	table.sort(ids)
	while true do
		local id = ids[rng:NextInteger(1, #ids)]
		local event = Luck.EVENTS[id]
		ReplicatedStorage:SetAttribute("LuckyEvent", id)
		ReplicatedStorage:SetAttribute("LuckyEventEnds", Workspace:GetServerTimeNow() + Luck.EVENT_DURATION)
		announce(event.icon .. " " .. event.name .. "! " .. event.description)
		task.wait(Luck.EVENT_DURATION)
		ReplicatedStorage:SetAttribute("LuckyEvent", nil)
		announce(event.name .. " is over. Another one will come soon!")
		task.wait(rng:NextInteger(Luck.EVENT_GAP[1], Luck.EVENT_GAP[2]))
	end
end

function LuckService.init()
	ActionService.register("BuyCrate", buyCrate)
	ActionService.register("OpenCrate", openOwnedCrate)
	ActionService.register("SpinWheel", spin)
	task.spawn(runEvents)
end

return LuckService
