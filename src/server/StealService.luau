-- Carrying eggs home from the zones.
--
-- Hold the Grab prompt on an egg in a zone (you need a free nest at home). The egg rides
-- over your head and you run a little slower (GamePasses.carrySlowdown) until you get it
-- inside your own yard, where it goes into a free nest to grow (NestService). If the zone's
-- guardian catches you, or you die or leave, you drop it and it's gone (the zone grows a new
-- one).
--
-- Also gives players items (StealService.give), from hatching eggs, the Lucky Wheel and
-- Mystery Boxes.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EggModel = require(ReplicatedStorage.Shared.EggModel)
local Format = require(ReplicatedStorage.Shared.Format)
local ItemModel = require(ReplicatedStorage.Shared.ItemModel)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)
local NestService = require(script.Parent.NestService)
local PlotService = require(script.Parent.PlotService)
local ZoneService = require(script.Parent.ZoneService)

local StealService = {}

local notifyRemote = Remotes.get("Notify")
-- [carrier Player] = { record = { egg, rarity, mutations }, name, zone, pedestal, model, shoulders }
local carries = {}

local function notify(player: Player, message: string, kind: string?)
	if player.Parent then
		notifyRemote:FireClient(player, message, kind)
	end
end

local function rootPart(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- How far the arms swing up to hold an egg over the head (R15 characters).
local HOLD_ANGLE = math.rad(165)

-- Puts the egg over the carrier's head. Returns false if the carrier has no character.
local function pickUp(carrier: Player, carry): boolean
	local character = carrier.Character
	local root = rootPart(carrier)
	if not character or not root then
		return false
	end
	local model = EggModel.build(carry.record.egg, carry.record.item)
	Items.scaleModel(model, Items.weightScale(Items.weightFactor(carry.record)))
	ItemModel.addMutationEffect(model, carry.record.mutations)
	model:PivotTo(root.CFrame * CFrame.new(0, 3.2, 0))
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = descendant
			weld.Parent = descendant
		end
	end

	-- Arms up to hold it. Changing the shoulder joints' C0 (not Transform) keeps the pose
	-- under the walk animation, and putDown puts them back.
	carry.shoulders = {}
	for _, name in { "RightUpperArm.RightShoulder", "LeftUpperArm.LeftShoulder" } do
		local armName, jointName = string.match(name, "^(.-)%.(.*)$")
		local arm = character:FindFirstChild(armName)
		local joint = arm and arm:FindFirstChild(jointName)
		if joint and joint:IsA("Motor6D") then
			table.insert(carry.shoulders, { joint = joint, c0 = joint.C0 })
			joint.C0 = joint.C0 * CFrame.Angles(HOLD_ANGLE, 0, 0)
		end
	end

	model.Name = "CarriedPart"
	model.Parent = character
	carry.model = model
	carries[carrier] = carry
	carrier:SetAttribute(
		"Carrying",
		Format.weight(carry.record.weight or 1) .. " " .. carry.record.rarity .. " " .. carry.name
	)
	return true
end

-- Takes the egg off the carrier.
local function putDown(carrier: Player, carry)
	carries[carrier] = nil
	carrier:SetAttribute("Carrying", nil)
	if carry.model then
		carry.model:Destroy()
		carry.model = nil
	end
	for _, shoulder in carry.shoulders or {} do
		if shoulder.joint.Parent then
			shoulder.joint.C0 = shoulder.c0
		end
	end
	carry.shoulders = nil
end

-- The carrier dropped it: it's gone and its pedestal grows a new one.
local function drop(carrier: Player, carry, message: string?)
	putDown(carrier, carry)
	ZoneService.release(carry.zone, carry.pedestal)
	if message then
		notify(carrier, message, "error")
	end
end

-- Adds an item to a player's save (see NestService.give).
StealService.give = NestService.give

local function deliver(carrier: Player, carry)
	putDown(carrier, carry)
	ZoneService.release(carry.zone, carry.pedestal)
	local nest = NestService.addEgg(carrier, carry.record)
	if nest then
		notify(carrier, "🥚 " .. carry.name .. " is in nest " .. nest .. "! Wait for it to hatch.", "success")
	else
		notify(carrier, "Your nests are full, so the egg rolled away!", "error")
	end
end

-- Checks a player could carry an egg home right now. Returns an error message or nil.
local function cannotCarry(player: Player): string?
	if carries[player] then
		return "You can only carry one egg at a time!"
	end
	local data = DataService.get(player)
	if not data or not PlotService.getPlot(player) or not rootPart(player) then
		return ""
	end
	if not NestService.freeNest(player, data) then
		return "Your nests are full! Hatch your eggs first."
	end
	return nil
end

local function grab(prompt: ProximityPrompt, player: Player)
	local zone, pedestal = prompt:GetAttribute("Zone"), prompt:GetAttribute("Pedestal")
	local problem = cannotCarry(player)
	if problem then
		return if problem ~= "" then notify(player, problem, "error") else nil
	end
	local record = ZoneService.take(zone, pedestal)
	if not record then
		return
	end
	local carry = {
		record = record,
		name = ZoneService.eggName(record),
		zone = zone,
		pedestal = pedestal,
	}
	if not pickUp(player, carry) then
		return ZoneService.release(zone, pedestal)
	end
	notify(
		player,
		"You grabbed a "
			.. record.rarity
			.. " "
			.. carry.name
			.. "! Run home before "
			.. Items.ZONES[zone].title
			.. " catches you!",
		"success"
	)
	ZoneService.alert(zone, player)
end

function StealService.isCarrying(player: Player): boolean
	return carries[player] ~= nil
end

-- What a player is carrying (the egg's record), if anything.
function StealService.carrying(player: Player)
	local carry = carries[player]
	return carry and carry.record
end

-- Makes the player drop whatever they're carrying. Returns true if they were carrying.
function StealService.drop(player: Player, message: string?): boolean
	local carry = carries[player]
	if not carry then
		return false
	end
	drop(player, carry, message)
	return true
end

local function checkCarries()
	for carrier, carry in carries do
		local root = rootPart(carrier)
		if not root or not carry.model or not carry.model.Parent then
			drop(carrier, carry, "You dropped the " .. carry.name .. "!")
			continue
		end
		local home = PlotService.getPlot(carrier)
		if home and PlotService.isInside(home, root.Position) then
			deliver(carrier, carry)
		end
	end
end

function StealService.init()
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if prompt.Name == "GrabPrompt" then
			grab(prompt, player)
		end
	end)
	ZoneService.setCarrierHooks({
		carrying = StealService.carrying,
		drop = StealService.drop,
	})

	Players.PlayerRemoving:Connect(function(player)
		local carry = carries[player]
		if carry then
			drop(player, carry)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.1)
			-- One bad tick must never stop deliveries for the rest of the server.
			local ok, err = pcall(checkCarries)
			if not ok then
				warn("[StealService] " .. tostring(err))
			end
		end
	end)
end

return StealService
