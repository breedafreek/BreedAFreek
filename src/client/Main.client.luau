-- The player's client. The screen UI has been removed while it's rebuilt from scratch;
-- this runs the world effects (guardians, attacks, pets, treadmill running, ambience,
-- events, flashing secret eggs) and the bits of gameplay that live on the client.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

print("[Steal a Life] Client starting")

-- If the game hasn't loaded after a few seconds, show what the server is stuck on.
local clientReady = false
task.delay(8, function()
	if clientReady then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "LoadingProblem"
	gui.DisplayOrder = 100
	gui.ResetOnSpawn = false
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.8, 0, 0.6, 0)
	label.Position = UDim2.fromScale(0.1, 0.2)
	label.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
	label.BackgroundTransparency = 0.15
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextWrapped = true
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Font = Enum.Font.Code
	label.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	while not clientReady do
		label.Text = "The game didn't finish loading. Send this to the developer:\n\nServer: "
			.. tostring(ReplicatedStorage:GetAttribute("ServerStartup") or "no status (server script never ran)")
		task.wait(1)
	end
	gui:Destroy()
end)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EggModel = require(Shared.EggModel)
local Remotes = require(Shared.Remotes)
local Ambient = require(script.Parent.Ambient)
local EventFX = require(script.Parent.EventFX)
local GuardianAttackFX = require(script.Parent.GuardianAttackFX)
local GuardianFX = require(script.Parent.GuardianFX)
local PetFX = require(script.Parent.PetFX)
local TreadmillRun = require(script.Parent.TreadmillRun)

local player = Players.LocalPlayer

EventFX.start()

-- Only the owner sees the Hatch prompts on their own nests.
local function hideOtherPrompt(instance: Instance)
	if instance:IsA("ProximityPrompt") and instance.Name == "HatchPrompt" then
		local mine = instance:GetAttribute("PlotIndex") == player:GetAttribute("Plot")
		instance:SetAttribute("Mine", mine)
		if not mine then
			instance.Enabled = false
		end
		if not instance:GetAttribute("Hooked") then
			instance:SetAttribute("Hooked", true)
			instance:GetPropertyChangedSignal("Enabled"):Connect(function()
				if instance.Enabled and instance:GetAttribute("PlotIndex") ~= player:GetAttribute("Plot") then
					instance.Enabled = false
				end
			end)
		end
	end
end
for _, descendant in Workspace:GetDescendants() do
	hideOtherPrompt(descendant)
end
Workspace.DescendantAdded:Connect(hideOtherPrompt)
player:GetAttributeChangedSignal("Plot"):Connect(function()
	for _, descendant in Workspace:GetDescendants() do
		hideOtherPrompt(descendant)
	end
end)

-- Getting hit: pushed away and knocked over for a moment.
Remotes.get("Knockback").OnClientEvent:Connect(function(direction: Vector3, strength: number, seconds: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return
	end
	humanoid.PlatformStand = true
	root.AssemblyLinearVelocity = direction * strength + Vector3.new(0, strength * 0.5, 0)
	task.delay(seconds, function()
		if humanoid.Parent then
			humanoid.PlatformStand = false
		end
	end)
end)

GuardianFX.start()
GuardianAttackFX.start()
PetFX.start()
TreadmillRun.start()
Ambient.start()

-- The Mystery Boxes on the stand turn slowly and bob up and down.
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for i, box in CollectionService:GetTagged("DisplayEgg") do
		local rest = box:GetAttribute("Rest")
		if box:IsA("Model") and box.PrimaryPart and typeof(rest) == "CFrame" then
			local phase = i * 1.7
			box:PivotTo(
				rest * CFrame.new(0, 0.35 + math.sin(t * 2 + phase) * 0.35, 0) * CFrame.Angles(0, t * 0.8 + phase, 0)
			)
		end
	end
end)

-- Secret eggs flash and glow: their aura and light cycle through every colour and pulse.
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for i, egg in CollectionService:GetTagged(EggModel.SECRET_TAG) do
		local glow = egg:FindFirstChild("SecretGlow")
		local shell = egg:FindFirstChild("Shell")
		local light = shell and shell:FindFirstChild("SecretLight")
		local color = Color3.fromHSV((t * 0.5 + i * 0.13) % 1, 0.75, 1)
		local flash = (math.sin(t * 9 + i) + 1) / 2 -- 0..1, a few flashes a second
		if glow and glow:IsA("BasePart") then
			glow.Color = color
			glow.Transparency = 0.25 + 0.5 * (1 - flash)
		end
		if light and light:IsA("PointLight") then
			light.Color = color
			light.Brightness = 1.5 + 4 * flash
		end
	end
end)

Remotes.get("GetState"):InvokeServer()
print("[Steal a Life] Client ready")
clientReady = true
