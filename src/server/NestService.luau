-- Eggs growing at home, and hatching them.
--
-- An egg brought home goes into the first free nest (Items.NESTS, two more with the Extra
-- Nests pass) and grows for Items.HATCH_SECONDS of its rarity (half with Fast Hatching).
-- It keeps growing while the player is offline (the end time is saved as os.time()). Once
-- it's ready the owner holds Hatch on its nest: out comes a random item of the egg's kind
-- and rarity (Items.pool), keeping the egg's mutations, which goes straight out on the
-- house, into the pen, onto a yard spot or into a garden bed if it's an upgrade
-- (LifeUtil.placeIfBetter), or into the backpack.
--
-- Also hands out items from the Lucky Wheel and Mystery Boxes (NestService.reward).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local Items = require(ReplicatedStorage.Shared.Items)
local LifeUtil = require(ReplicatedStorage.Shared.LifeUtil)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)
local DiscoveryService = require(script.Parent.DiscoveryService)
local PlotService = require(script.Parent.PlotService)

local NestService = {}

local rng = Random.new()
local notifyRemote = Remotes.get("Notify")
local resultRemote = Remotes.get("LuckResult")

local function notify(player: Player, message: string, kind: string?)
	if player.Parent then
		notifyRemote:FireClient(player, message, kind)
	end
end

-- The first free nest the player can use ("1".."5"), or nil if they're all full.
function NestService.freeNest(player: Player, data): string?
	data.nests = data.nests or {}
	for n = 1, LifeUtil.nestCount(GamePasses.extraNests(player)) do
		if not data.nests[tostring(n)] then
			return tostring(n)
		end
	end
	return nil
end

-- Puts an egg ({ egg = zone, rarity, mutations }) into a free nest. Returns the nest, or
-- nil if there was no room.
function NestService.addEgg(player: Player, record): string?
	local data = DataService.get(player)
	local nest = data and NestService.freeNest(player, data)
	if not nest then
		return nil
	end
	local seconds = math.ceil(Items.HATCH_SECONDS[record.rarity] * GamePasses.hatchMultiplier(player))
	data.nests[nest] = {
		zone = record.egg,
		rarity = record.rarity,
		mutations = Mutations.pack(record.mutations),
		size = record.size,
		endsAt = os.time() + seconds,
	}
	DataService.changed(player)
	task.spawn(DataService.save, player)
	return nest
end

-- A random item of a kind and rarity (falling back to the next rarity down if there are
-- none of that rarity).
function NestService.rollItem(kind: string, rarity: string): string
	for rank = Rarities.rank[rarity], 1, -1 do
		local pool = Items.pool(kind, Rarities.order[rank])
		if #pool > 0 then
			return pool[rng:NextInteger(1, #pool)]
		end
	end
	return Items.pool(kind, "Common")[1]
end

-- Adds an item to a player's save and puts it out if it beats what's there. Whatever it
-- replaces goes in the backpack; if the backpack is then over full, the worst extra item is
-- sold. Returns where it went ("house", "pen", "yard", "garden" or "backpack") and the money
-- made selling, if any.
function NestService.give(player: Player, data, record): (string, number)
	local uid = DataService.newUid(data)
	data.parts[uid] = { id = record.id, mutations = Mutations.pack(record.mutations), size = record.size }
	data.discovered[record.id] = true
	task.spawn(DiscoveryService.claim, player, record.id)
	local where = LifeUtil.placeIfBetter(data, uid)
	local sold = 0
	local backpack = LifeUtil.backpack(data)
	while #backpack > GamePasses.backpackSize(player) do
		local worst = table.remove(backpack)
		sold += LifeUtil.sellPrice(data.parts[worst])
		data.parts[worst] = nil
	end
	data.money += sold
	return where, sold
end

-- Gives an item and shows the reveal on the player's screen. reveal = { kind, ... } (what
-- it came from: "egg", "wheel", "crate"); size = its size (Items.SIZES, nil = Normal).
function NestService.reward(player: Player, data, itemId: string, mutations, reveal, size: string?)
	local record = { id = itemId, mutations = Mutations.pack(mutations), size = size }
	reveal.isNew = not data.discovered[itemId]
	local where, sold = NestService.give(player, data, record)
	reveal.where = where
	reveal.part = record
	reveal.rarity = Items.byId[itemId].rarity
	resultRemote:FireClient(player, reveal)
	if sold > 0 then
		notify(
			player,
			"🎒 Your backpack is full, so the worst item was sold for " .. Format.money(sold) .. ".",
			"money"
		)
	end
	if Rarities.rank[reveal.rarity] >= Rarities.rank.Mystic or Items.size(size).rank >= Items.sizeById.Giant.rank then
		for _, other in Players:GetPlayers() do
			notify(
				other,
				"🐣 "
					.. player.DisplayName
					.. " got a "
					.. reveal.rarity
					.. " "
					.. LifeUtil.displayName(record)
					.. "!",
				"discovery"
			)
		end
	end
	DataService.changed(player)
	task.spawn(DataService.save, player)
end

-- Hatches the egg in nest n if it's ready. Returns an error message or nil.
function NestService.hatch(player: Player, n: number): string?
	local data = DataService.get(player)
	local key = tostring(n)
	local egg = data and data.nests and data.nests[key]
	if not egg then
		return "That nest is empty."
	end
	if os.time() < egg.endsAt then
		return "It isn't ready yet! " .. Format.time(egg.endsAt - os.time()) .. " to go."
	end
	data.nests[key] = nil
	local zone = Items.ZONES[egg.zone] or Items.ZONES[1]
	local itemId = NestService.rollItem(zone.kind, egg.rarity)
	NestService.reward(
		player,
		data,
		itemId,
		egg.mutations,
		{ kind = "egg", egg = egg.zone, nest = n, eggSize = egg.size },
		egg.size
	)
	return nil
end

function NestService.init()
	-- So clients can count down nest timers (Items.now).
	ReplicatedStorage:SetAttribute("OsTimeOffset", os.time() - game:GetService("Workspace"):GetServerTimeNow())
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if prompt.Name ~= "HatchPrompt" then
			return
		end
		local plot = PlotService.getPlot(player)
		if not plot or plot.index ~= prompt:GetAttribute("PlotIndex") then
			return notify(player, "That's not your nest!", "error")
		end
		local problem = NestService.hatch(player, prompt:GetAttribute("Nest"))
		if problem then
			notify(player, problem, "error")
		end
	end)
end

return NestService
