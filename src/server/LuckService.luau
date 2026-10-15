-- Monster Crates, the daily Lucky Wheel and Lucky Hour events (rules and odds in
-- shared/Luck.luau). All rolls happen here; the client only shows the result (the
-- LuckResult remote) with a reveal animation.
--
-- Monster Crates are Developer Products. ProcessReceipt grants a crate only once per
-- purchase (receipts are remembered in the player's save) and only tells Roblox the
-- purchase went through after the save succeeds, so nobody pays without getting it.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local Freeks = require(ReplicatedStorage.Shared.Freeks)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local Luck = require(ReplicatedStorage.Shared.Luck)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Seasons = require(ReplicatedStorage.Shared.Seasons)

local ActionService = require(script.Parent.ActionService)
local DataService = require(script.Parent.DataService)

local LuckService = {}

local rng = Random.new()
local notifyRemote = Remotes.get("Notify")
local resultRemote = Remotes.get("LuckResult")
local RECEIPTS_KEPT = 50 -- how many recent purchase IDs each save remembers

-- Odds for the wheel's Golden/Rainbow Freek (by rarity, never Monsters).
local WHEEL_FREEK_ODDS = { Common = 35, Uncommon = 45, Rare = 17, Legendary = 3 }

local function notify(player: Player, message: string, kind: string?)
	notifyRemote:FireClient(player, message, kind)
end

local function announce(message: string)
	for _, player in Players:GetPlayers() do
		notify(player, message, "discovery")
	end
end

-- Picks a key from a { [key] = weight } table.
local function rollWeighted(weights: { [string]: number }): string
	local keys = {}
	local total = 0
	for key, weight in weights do
		table.insert(keys, key)
		total += weight
	end
	table.sort(keys)
	local roll = rng:NextNumber() * total
	for _, key in keys do
		roll -= weights[key]
		if roll <= 0 then
			return key
		end
	end
	return keys[#keys]
end

-- A random non-Monster species of that rarity (or the next rarity down that has any).
local function pickSpecies(rarity: string)
	local rank = Rarities.rank[rarity]
	while rank >= 1 do
		local pool = {}
		for _, species in Freeks.list do
			if
				species.rarity == Rarities.order[rank]
				and not species.exclusive
				and species.rarity ~= "Secret"
				and Seasons.available(species)
			then
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
	local species = Freeks.byId[rollWeighted(Luck.crateOdds(crate))]
	giveFreek(player, data, species, rollMutations(crate.mutation), { kind = "crate", crate = crate.id })
end

-- Whether paid random items are allowed for this player (some countries ban them).
local function cratesAllowed(player: Player): boolean
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if not ok then
		return RunService:IsStudio() -- can't check: only allow while testing in Studio
	end
	return not info.ArePaidRandomItemsRestricted
end

-- The player asked to buy a crate: check, then show Roblox's purchase prompt.
local function buyCrate(player: Player, data, crateId: any)
	local crate = typeof(crateId) == "string" and Luck.crateById[crateId]
	if not crate then
		return
	end
	if player:GetAttribute("CratesRestricted") then
		return notify(player, "Monster Crates aren't available where you live.", "error")
	end
	if not hasRoom(player, data) then
		return notify(player, "You have too many Freeks! Sell or fuse some first.", "error")
	end
	if crate.productId == 0 then
		if RunService:IsStudio() and Luck.STUDIO_FREE_CRATES then
			notify(player, "Studio test: opening " .. crate.name .. " for free.", "success")
			return openCrate(player, data, crate)
		end
		return notify(player, "Monster Crates are coming soon!", "error")
	end
	MarketplaceService:PromptProductPurchase(player, crate.productId)
end

-- Opens a crate the player already owns (won on the wheel, or bought while full).
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

local function processReceipt(receipt)
	local crate = Luck.crateByProduct[receipt.ProductId]
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local data = player and DataService.get(player)
	if not crate or not data then
		-- Not ours, or the player isn't here: Roblox will try again later.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	data.receipts = data.receipts or {}
	if not table.find(data.receipts, receipt.PurchaseId) then
		if hasRoom(player, data) then
			openCrate(player, data, crate)
		else
			data.crates[crate.id] = (data.crates[crate.id] or 0) + 1
			notify(
				player,
				"Your barn is full, so your " .. crate.name .. " was saved. Open it from the 🍀 Luck tab!",
				"success"
			)
		end
		table.insert(data.receipts, receipt.PurchaseId)
		while #data.receipts > RECEIPTS_KEPT do
			table.remove(data.receipts, 1)
		end
		DataService.changed(player)
	end
	if not DataService.save(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
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

	local weights = {}
	for i, slice in Luck.WHEEL do
		weights[tostring(i)] = slice.weight
	end
	local index = tonumber(rollWeighted(weights)) :: number
	local slice = Luck.WHEEL[index]
	local reveal = { kind = "wheel", slice = index }

	if (slice.golden or slice.rainbow) and hasRoom(player, data) then
		local species = pickSpecies(rollWeighted(WHEEL_FREEK_ODDS))
		return giveFreek(player, data, species, { if slice.rainbow then "Rainbow" else "Golden" }, reveal)
	end
	if slice.crate then
		data.crates[slice.crate] = (data.crates[slice.crate] or 0) + 1
		reveal.crate = slice.crate
		if slice.crate == "LegendaryMonster" then
			announce(player.DisplayName .. " hit the JACKPOT on the Lucky Wheel!")
		end
	else
		-- Coins (also the fallback for a Freek prize when the barn is full).
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

-- Marks players who can't buy crates so their client hides the buy buttons.
local function checkPolicy(player: Player)
	player:SetAttribute("CratesRestricted", not cratesAllowed(player))
end

function LuckService.init()
	ActionService.register("BuyCrate", buyCrate)
	ActionService.register("OpenCrate", openOwnedCrate)
	ActionService.register("SpinWheel", spin)
	MarketplaceService.ProcessReceipt = processReceipt
	Players.PlayerAdded:Connect(checkPolicy)
	for _, player in Players:GetPlayers() do
		task.spawn(checkPolicy, player)
	end
	task.spawn(runEvents)
end

return LuckService
