-- Pays every player once a second for the parts on their house, plus offline earnings
-- when they come back. Money also shows on the leaderboard so players can show off.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local LifeUtil = require(ReplicatedStorage.Shared.LifeUtil)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)

local EconomyService = {}

-- House income including rebirths and game passes.
local function incomeFor(player: Player, data): number
	return LifeUtil.totalIncome(data) * GamePasses.coinMultiplier(player)
end

local function publish(player: Player, data, income: number)
	player:SetAttribute("Money", data.money)
	player:SetAttribute("Income", income)
	local stats = player:FindFirstChild("leaderstats")
	local money = stats and stats:FindFirstChild("Money")
	if money then
		money.Value = math.floor(data.money)
	end
	local rebirths = stats and stats:FindFirstChild("Rebirths")
	if rebirths then
		rebirths.Value = data.rebirths
	end
	local speed = stats and stats:FindFirstChild("Speed")
	if speed then
		speed.Value = math.floor(data.speed)
	end
end

local function onLoaded(player: Player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local money = Instance.new("NumberValue")
	money.Name = "Money"
	money.Parent = stats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = stats
	local speed = Instance.new("NumberValue")
	speed.Name = "Speed"
	speed.Parent = stats
	stats.Parent = player

	local income = incomeFor(player, data)
	local away = math.clamp(os.time() - (data.lastSeen or os.time()), 0, Config.OFFLINE_MAX_SECONDS)
	local earned = math.floor(away * income * Config.OFFLINE_RATE)
	if earned > 0 then
		data.money += earned
		Remotes.get("Notify")
			:FireClient(player, "While you were away your house earned " .. Format.money(earned) .. "!", "money")
	end
	publish(player, data, income)
end

function EconomyService.init()
	DataService.onLoaded(onLoaded)
	DataService.onChanged(function(player, data)
		publish(player, data, incomeFor(player, data))
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			for player, data in DataService.all() do
				local income = incomeFor(player, data)
				data.money += income
				publish(player, data, income)
			end
		end
	end)
end

return EconomyService
