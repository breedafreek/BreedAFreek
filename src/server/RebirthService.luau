-- Rebirth: pay Config.rebirthCost to start over with a permanent income bonus.
--
-- Resets: money (back to START_MONEY), Freeks, yard slots, the breeding pen.
-- Keeps: the Discovery Book, Limited (seasonal) Freeks (moved to the backpack, then back into
-- the yard), and weapons, which unlock at rebirth milestones (see Weapons.luau).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Weapons = require(ReplicatedStorage.Shared.Weapons)

local ActionService = require(script.Parent.ActionService)
local Carried = require(script.Parent.Carried)
local DataService = require(script.Parent.DataService)
local StealService = require(script.Parent.StealService)
local TradeService = require(script.Parent.TradeService)
local WeaponService = require(script.Parent.WeaponService)

local RebirthService = {}

local notifyRemote = Remotes.get("Notify")

local function notify(player: Player, message: string, kind: string?)
	notifyRemote:FireClient(player, message, kind)
end

local function rebirth(player: Player, data)
	local cost = Config.rebirthCost(data.rebirths)
	if data.money < cost then
		return notify(player, "You need " .. Format.money(cost) .. " to rebirth!", "error")
	end
	if TradeService.isTrading(player) then
		return notify(player, "Finish your trade before rebirthing!", "error")
	end
	if StealService.isCarrying(player) or Carried.any(player) then
		return notify(player, "You can't rebirth in the middle of a steal!", "error")
	end

	-- Limited Freeks survive; everything else is cleared.
	local kept = {}
	for uid, freek in data.freeks do
		local species = FreekUtil.species(freek)
		if species and species.season then
			kept[uid] = { species = freek.species, mutation = freek.mutation }
		end
	end
	data.freeks = kept
	data.breeding = nil
	data.money = Config.START_MONEY
	data.slots = Config.START_SLOTS
	data.rebirths += 1
	for _, freek in data.freeks do
		freek.slot = FreekUtil.freeSlot(data)
	end

	WeaponService.giveWeapons(player)
	task.spawn(DataService.save, player)

	local unlocked = {}
	for _, weaponId in Weapons.order do
		if Weapons.list[weaponId].rebirth == data.rebirths then
			table.insert(unlocked, Weapons.list[weaponId].name)
		end
	end
	local message = string.format(
		"Rebirth %d! Your Freeks now earn x%s forever.",
		data.rebirths,
		tostring(Config.incomeMultiplier(data.rebirths))
	)
	if #unlocked > 0 then
		message ..= " Unlocked: " .. table.concat(unlocked, ", ") .. "!"
	end
	notify(player, message, "discovery")
	for _, other in Players:GetPlayers() do
		if other ~= player then
			notify(other, player.DisplayName .. " just reached Rebirth " .. data.rebirths .. "!", "discovery")
		end
	end
end

function RebirthService.init()
	ActionService.register("Rebirth", rebirth)
end

return RebirthService
