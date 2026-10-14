-- Weapons: giving them out, buying them, and what happens when they hit.
--
-- The client sends "UseWeapon" with where the player is aiming; the server checks the
-- weapon is owned and equipped, applies the cooldown, and does the hit (melee) or flies a
-- ball (projectile). Weapons only affect players carrying one of the attacker's Freeks; the
-- Glue Gun also works on anyone standing inside the attacker's yard.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Weapons = require(ReplicatedStorage.Shared.Weapons)

local ActionService = require(script.Parent.ActionService)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local StealService = require(script.Parent.StealService)

local WeaponService = {}

local notifyRemote = Remotes.get("Notify")
local lastUse = {} -- [Player] = { [weaponId] = os.clock() }
local glued = {} -- [Player] = true while stuck

local function notify(player: Player, message: string, kind: string?)
	if player.Parent then
		notifyRemote:FireClient(player, message, kind)
	end
end

local function owns(player: Player, weaponId: string): boolean
	if weaponId == Weapons.STARTER then
		return true
	end
	local data = DataService.get(player)
	return data ~= nil and data.weapons[weaponId] == true
end

local function buildTool(weaponId: string): Tool
	local weapon = Weapons.list[weaponId]
	local tool = Instance.new("Tool")
	tool.Name = weapon.name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = weapon.description
	if weapon.kind == "melee" then
		-- Same grip as Roblox's classic sword: held at one end, pointing up and forward.
		tool.GripForward = Vector3.new(-1, 0, 0)
		tool.GripRight = Vector3.new(0, 1, 0)
		tool.GripUp = Vector3.new(0, 0, 1)
		tool.GripPos = Vector3.new(0, 0, -1.5)
	end
	tool:SetAttribute("WeaponId", weaponId)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = weapon.handle.size
	handle.Color = weapon.handle.color
	handle.Material = Enum.Material[weapon.handle.material]
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	return tool
end

-- Makes sure the player's backpack has every weapon they own.
local function giveWeapons(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	local have = {}
	for _, container in { backpack, player.Character } do
		if container then
			for _, child in container:GetChildren() do
				local id = child:IsA("Tool") and child:GetAttribute("WeaponId")
				if id then
					have[id] = true
				end
			end
		end
	end
	for _, weaponId in Weapons.order do
		if owns(player, weaponId) and not have[weaponId] then
			buildTool(weaponId).Parent = backpack
		end
	end
end

local function playSound(parent: Instance, soundId: string)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.6
	sound.Parent = parent
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

-- Finds the player a hit part belongs to (including parts of a Freek they're carrying).
local function playerFromPart(part: Instance): Player?
	local node = part.Parent
	while node and node ~= Workspace do
		local player = Players:GetPlayerFromCharacter(node)
		if player then
			return player
		end
		node = node.Parent
	end
	return nil
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Sticks a player to the nearest wall (or where they stand, if none is close).
local function glue(attacker: Player, target: Player, seconds: number)
	local root = rootOf(target)
	if not root or glued[target] then
		return
	end
	glued[target] = true

	local exclude = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(exclude, player.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclude

	local best = nil
	for i = 0, 7 do
		local angle = i / 8 * math.pi * 2
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle)) * 30
		local result = Workspace:Raycast(root.Position, direction, params)
		if result and (not best or result.Distance < best.Distance) then
			best = result
		end
	end

	local blob = Instance.new("Part")
	blob.Name = "Glue"
	blob.Anchored = true
	blob.CanCollide = false
	blob.CanQuery = false
	blob.Material = Enum.Material.Glass
	blob.Transparency = 0.25
	blob.Color = Weapons.list.GlueGun.ball.color
	blob.Size = Vector3.new(4, 6, 1)

	if best then
		local spot = best.Position + best.Normal * 1.6
		spot = Vector3.new(spot.X, root.Position.Y, spot.Z)
		root.Parent:PivotTo(CFrame.lookAt(spot, spot + best.Normal))
		blob.CFrame = CFrame.lookAt(best.Position + best.Normal * 0.5, best.Position + best.Normal * 2)
	else
		blob.CFrame = root.CFrame * CFrame.new(0, 0, 1)
	end
	blob.Parent = Workspace
	root.Anchored = true

	notify(target, attacker.DisplayName .. " glued you to the wall!", "error")
	notify(attacker, "You glued " .. target.DisplayName .. "!", "success")

	task.delay(seconds, function()
		blob:Destroy()
		glued[target] = nil
		if root.Parent then
			root.Anchored = false
		end
	end)
end

local function applyHit(attacker: Player, target: Player, weapon)
	if target == attacker then
		return
	end
	if weapon.effect == "drop" then
		StealService.knockLoose(attacker, target, weapon.name)
	elseif weapon.effect == "glue" then
		local root = rootOf(target)
		local plot = PlotService.getPlot(attacker)
		local intruding = root ~= nil and plot ~= nil and PlotService.isInside(plot, root.Position)
		if StealService.isCarryingFrom(target, attacker) or intruding then
			glue(attacker, target, weapon.glueSeconds)
		end
	end
end

local function melee(player: Player, weapon, tool: Tool)
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash" -- plays the default character's sword-slash animation
	anim.Parent = tool
	playSound(tool.Handle, "rbxasset://sounds/swordslash.wav")

	local root = rootOf(player)
	if not root then
		return
	end
	for _, other in Players:GetPlayers() do
		local otherRoot = other ~= player and rootOf(other)
		if otherRoot then
			local offset = otherRoot.Position - root.Position
			if offset.Magnitude <= weapon.range and offset.Unit:Dot(root.CFrame.LookVector) > 0.3 then
				applyHit(player, other, weapon)
			end
		end
	end
end

local function shoot(player: Player, weapon, tool: Tool, aim: Vector3?)
	local root = rootOf(player)
	if not root then
		return
	end
	local origin = tool.Handle.Position
	local direction = if aim and (aim - origin).Magnitude > 1 then (aim - origin).Unit else root.CFrame.LookVector

	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one * weapon.ball.size
	ball.Color = weapon.ball.color
	ball.Material = Enum.Material.Neon
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.CFrame = CFrame.new(origin)
	ball.Parent = Workspace
	playSound(tool.Handle, "rbxasset://sounds/swordlunge.wav")

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character, ball }

	local position = origin
	local traveled = 0
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		local step = math.min(weapon.speed * dt, weapon.range - traveled)
		local result = Workspace:Spherecast(position, weapon.ball.size / 2, direction * step, params)
		if result then
			connection:Disconnect()
			ball:Destroy()
			local target = playerFromPart(result.Instance)
			if target then
				applyHit(player, target, weapon)
			end
			return
		end
		position += direction * step
		traveled += step
		ball.CFrame = CFrame.new(position)
		if traveled >= weapon.range then
			connection:Disconnect()
			ball:Destroy()
		end
	end)
end

local function useWeapon(player: Player, _data, weaponId: any, aim: any)
	local weapon = typeof(weaponId) == "string" and Weapons.list[weaponId]
	if not weapon or not owns(player, weaponId) or glued[player] then
		return
	end
	-- Must actually be holding it.
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	if not tool or tool:GetAttribute("WeaponId") ~= weaponId or not tool:FindFirstChild("Handle") then
		return
	end
	local now = os.clock()
	lastUse[player] = lastUse[player] or {}
	if lastUse[player][weaponId] and now - lastUse[player][weaponId] < weapon.cooldown then
		return
	end
	lastUse[player][weaponId] = now

	if weapon.kind == "melee" then
		melee(player, weapon, tool)
	else
		shoot(player, weapon, tool, if typeof(aim) == "Vector3" then aim else nil)
	end
end

local function buyWeapon(player: Player, data, weaponId: any)
	local weapon = typeof(weaponId) == "string" and Weapons.list[weaponId]
	if not weapon or not weapon.price or data.weapons[weaponId] then
		return
	end
	if data.money < weapon.price then
		return notify(
			player,
			"Not enough money! The " .. weapon.name .. " costs " .. Format.money(weapon.price),
			"error"
		)
	end
	data.money -= weapon.price
	data.weapons[weaponId] = true
	giveWeapons(player)
	notify(player, "You bought the " .. weapon.name .. "! It's in your toolbar.", "success")
end

function WeaponService.init()
	ActionService.register("UseWeapon", useWeapon, true)
	ActionService.register("BuyWeapon", buyWeapon)

	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function()
			player:WaitForChild("Backpack")
			task.wait() -- let Roblox finish refilling the backpack first
			giveWeapons(player)
		end)
		if player.Character then
			giveWeapons(player)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	DataService.onLoaded(function(player)
		giveWeapons(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastUse[player] = nil
		glued[player] = nil
	end)
end

return WeaponService
