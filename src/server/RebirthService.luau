-- Rebirth: pay Config.rebirthCost to start over with a permanent income bonus.
--
-- Resets: money (back to START_MONEY), Speed, and the treadmill level.
-- Keeps: everything you own (house, pets, yard, garden, backpack, eggs in nests) and the
-- Catalog. Each rebirth adds REBIRTH_INCOME_BONUS income and REBIRTH_SPEED_BONUS treadmill
-- speed, forever.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ActionService = require(script.Parent.ActionService)
local DataService = require(script.Parent.DataService)
local StealService = require(script.Parent.StealService)

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
	if StealService.isCarrying(player) then
		return notify(player, "You can't rebirth while carrying an egg!", "error")
	end

	data.money = Config.TEST_MONEY or Config.START_MONEY
	data.speed = 0
	data.treadmill = 1
	data.rebirths += 1

	task.spawn(DataService.save, player)

	local message = string.format(
		"Rebirth %d! Your life now earns x%s and your treadmill trains x%s Speed, forever.",
		data.rebirths,
		tostring(Config.incomeMultiplier(data.rebirths)),
		tostring(Config.speedMultiplier(data.rebirths))
	)
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
