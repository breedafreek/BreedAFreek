-- Gives every player a weapon and handles swings. A hit only matters when the target is
-- carrying a Freek stolen from the attacker (see StealService.onHit), so weapons can't be
-- used to bully players who aren't stealing from you.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")

local Weapons = require(ReplicatedStorage.Shared.Weapons)

local StealService = require(script.Parent.StealService)

local WeaponService = {}

local lastSwing = {} -- [Player] = os.clock()
local hooked = setmetatable({}, { __mode = "k" }) -- tools already connected

local function buildTool(weaponId: string): Tool
	local weapon = Weapons.list[weaponId]
	local tool = Instance.new("Tool")
	tool.Name = weapon.name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	-- Same grip as Roblox's classic sword: held at one end, pointing forward.
	tool.GripForward = Vector3.new(-1, 0, 0)
	tool.GripRight = Vector3.new(0, 1, 0)
	tool.GripUp = Vector3.new(0, 0, 1)
	tool.GripPos = Vector3.new(0, 0, -1.5)
	tool:SetAttribute("WeaponId", weaponId)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = weapon.size
	handle.Color = weapon.color
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	return tool
end

local function swing(player: Player, tool: Tool)
	local weapon = Weapons.list[tool:GetAttribute("WeaponId")]
	local now = os.clock()
	if not weapon or (lastSwing[player] and now - lastSwing[player] < weapon.cooldown) then
		return
	end
	lastSwing[player] = now

	-- Plays the default character's sword-slash animation.
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool
	local handle = tool:FindFirstChild("Handle")
	if handle then
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/swordslash.wav"
		sound.Volume = 0.6
		sound.Parent = handle
		sound:Play()
		sound.Ended:Once(function()
			sound:Destroy()
		end)
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	for _, other in Players:GetPlayers() do
		local otherCharacter = other.Character
		local otherRoot = otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart")
		local humanoid = otherCharacter and otherCharacter:FindFirstChildOfClass("Humanoid")
		if other ~= player and otherRoot and humanoid and humanoid.Health > 0 then
			local offset = otherRoot.Position - root.Position
			if offset.Magnitude <= weapon.range and offset.Unit:Dot(root.CFrame.LookVector) > 0.3 then
				StealService.onHit(player, other)
			end
		end
	end
end

local function hook(player: Player, instance: Instance)
	if instance:IsA("Tool") and instance:GetAttribute("WeaponId") and not hooked[instance] then
		hooked[instance] = true
		instance.Activated:Connect(function()
			swing(player, instance)
		end)
	end
end

local function onPlayerAdded(player: Player)
	local function watch(container: Instance)
		for _, child in container:GetChildren() do
			hook(player, child)
		end
		container.ChildAdded:Connect(function(child)
			hook(player, child)
		end)
	end
	player.CharacterAdded:Connect(watch)
	if player.Character then
		watch(player.Character)
	end
	local backpack = player:WaitForChild("Backpack")
	watch(backpack)
	player.ChildAdded:Connect(function(child)
		if child:IsA("Backpack") then
			watch(child)
		end
	end)
end

function WeaponService.init()
	buildTool(Weapons.STARTER).Parent = StarterPack

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
	end)
end

return WeaponService
