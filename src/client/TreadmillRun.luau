-- Running on your treadmill by yourself: while you stand on your own treadmill's belt and
-- aren't steering, your character runs forward (the belt pushes back just as fast, so you
-- stay on it and train ⚡ Speed). Press any direction to take over and walk off.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TreadmillRun = {}

local player = Players.LocalPlayer

-- The player's own treadmill belt, if their home has loaded.
local function myBelt(): BasePart?
	local index = player:GetAttribute("Plot")
	local plots = Workspace:FindFirstChild("Plots")
	local plot = index and plots and plots:FindFirstChild("Plot" .. index)
	local treadmill = plot and plot:FindFirstChild("Treadmill")
	local belt = treadmill and treadmill:FindFirstChild("Belt")
	return if belt and belt:IsA("BasePart") then belt else nil
end

-- Same area as the server's PlotService.onTreadmill.
local function onBelt(belt: BasePart, position: Vector3): boolean
	local localPos = belt.CFrame:PointToObjectSpace(position)
	return math.abs(localPos.X) < 3 and math.abs(localPos.Z) < 6.2 and localPos.Y > -1 and localPos.Y < 6
end

function TreadmillRun.start()
	-- The player's own steering, from Roblox's control scripts (nil if they're replaced).
	local controls = nil
	task.spawn(function()
		local ok, playerModule = pcall(function()
			return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 10))
		end)
		if ok and playerModule then
			controls = playerModule:GetControls()
		end
	end)
	-- Runs after Roblox's own movement each frame, so it wins while the player isn't steering.
	RunService:BindToRenderStep("TreadmillRun", Enum.RenderPriority.Character.Value + 1, function()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local belt = myBelt()
		if not humanoid or not root or not belt or humanoid.Health <= 0 then
			return
		end
		if not onBelt(belt, root.Position) then
			return
		end
		local steering = controls and controls:GetMoveVector().Magnitude > 0.1
		if not steering then
			-- Face the front of the treadmill and run.
			humanoid:Move(belt.CFrame.LookVector, false)
		end
	end)
end

return TreadmillRun
