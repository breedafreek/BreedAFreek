-- Speed: trained on your treadmill, it decides how fast you run (Items.walkSpeed), which
-- decides which zones' guardians you can outrun.
--
-- Step onto your own treadmill and you run on it by yourself (client TreadmillRun) and your
-- Speed goes up every second by the treadmill's gain (Config.treadmillGain), times pass
-- bonuses. The belt runs as fast as you do, so you stay on it. Carrying an egg
-- slows you down, the more the heavier it is (Items.carrySpeed).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local Items = require(ReplicatedStorage.Shared.Items)

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local StealService = require(script.Parent.StealService)

local SpeedService = {}

local TICK = 0.2

-- Speed a second this player gets from running on their treadmill.
function SpeedService.gain(player: Player, data): number
	return Config.treadmillGain(data.treadmill) * GamePasses.speedMultiplier(player)
end

local function update(player: Player, data)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end
	local plot = PlotService.getPlot(player)
	local training = false
	if plot and PlotService.onTreadmill(plot, root.Position) then
		training = true
		data.speed += SpeedService.gain(player, data) * TICK
	end
	player:SetAttribute("Training", training)
	player:SetAttribute("Speed", math.floor(data.speed))

	local walk = Items.walkSpeed(data.speed)
	local carrying = StealService.carrying(player)
	if carrying then
		walk *= Items.carrySpeed(carrying)
	end
	if math.abs(humanoid.WalkSpeed - walk) > 0.05 then
		humanoid.WalkSpeed = walk
	end
	-- The belt runs as fast as its owner, pushing back toward the house.
	if plot then
		local belt = plot.treadmill.belt
		belt.AssemblyLinearVelocity = belt.CFrame:VectorToWorldSpace(Vector3.new(0, 0, Items.walkSpeed(data.speed)))
	end
end

function SpeedService.init()
	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, player in Players:GetPlayers() do
				local data = DataService.get(player)
				if data then
					local ok, err = pcall(update, player, data)
					if not ok then
						warn("[SpeedService] " .. tostring(err))
					end
				end
			end
		end
	end)
end

return SpeedService
