-- Pays every player once a second for the Freeks in their yard, plus offline earnings
-- when they come back. Money also shows on the leaderboard so players can show off.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)

local EconomyService = {}

local function publish(player: Player, data, income: number)
	player:SetAttribute("Money", data.money)
	player:SetAttribute("Income", income)
	local stats = player:FindFirstChild("leaderstats")
	local money = stats and stats:FindFirstChild("Money")
	if money then
		money.Value = math.floor(data.money)
	end
end

local function onLoaded(player: Player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local money = Instance.new("NumberValue")
	money.Name = "Money"
	money.Parent = stats
	stats.Parent = player

	local income = FreekUtil.yardIncome(data)
	local away = math.clamp(os.time() - (data.lastSeen or os.time()), 0, Config.OFFLINE_MAX_SECONDS)
	local earned = math.floor(away * income * Config.OFFLINE_RATE)
	if earned > 0 then
		data.money += earned
		Remotes.get("Notify")
			:FireClient(player, "While you were away your Freeks earned " .. Format.money(earned) .. "!", "money")
	end
	publish(player, data, income)
end

function EconomyService.init()
	DataService.onLoaded(onLoaded)
	DataService.onChanged(function(player, data)
		publish(player, data, FreekUtil.yardIncome(data))
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			for player, data in DataService.all() do
				local income = FreekUtil.yardIncome(data)
				data.money += income
				publish(player, data, income)
			end
		end
	end)
end

return EconomyService
