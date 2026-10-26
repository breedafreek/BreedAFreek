-- Carrying house parts home: from the zone piles, or pried off other players' houses.
--
-- Hold the Grab prompt on a part in a zone pile, or (while a home's gate is open) the Steal
-- prompt on a part of someone's house. The part rides over your head and you run a little
-- slower (GamePasses.carrySlowdown) until you get it inside your own yard, where it snaps
-- onto your house if it's better than what's there (the old part goes in your backpack), or
-- into your backpack if not.
--
-- While it's being carried:
--   * a zone's guardian that catches you flings you and you drop it (ZoneService);
--   * anyone can hit you with a weapon (WeaponService) and you drop it;
--   * the house's owner can Snatch it back; any other player can Snatch it for themselves;
--   * if you die or leave, you drop it.
-- A dropped zone part is gone (the pile grows a new one); a dropped house part goes straight
-- back onto its owner's house. A house part stays in its owner's save until the moment it's
-- delivered, so a crash mid-steal can never lose or duplicate it.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local HouseModel = require(ReplicatedStorage.Shared.HouseModel)
local HouseUtil = require(ReplicatedStorage.Shared.HouseUtil)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Parts = require(ReplicatedStorage.Shared.Parts)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Config = require(ReplicatedStorage.Shared.Config)

local Carried = require(script.Parent.Carried)
local DataService = require(script.Parent.DataService)
local DiscoveryService = require(script.Parent.DiscoveryService)
local PlotService = require(script.Parent.PlotService)
local ZoneService = require(script.Parent.ZoneService)

local StealService = {}

local notifyRemote = Remotes.get("Notify")
-- [carrier Player] = { record, name, source = "zone"|"house", zone?, pedestal?, owner?,
--                      uid?, slot?, model, shoulders }
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

-- A sparkle on mutated parts, in the mutation's colour.
local function addMutationEffect(model: Model, record)
	local top = Mutations.top(record.mutations)
	local base = model:FindFirstChildWhichIsA("BasePart")
	if top and base then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Mutations.byId[top].color
		sparkles.Parent = base
	end
end
StealService.addMutationEffect = addMutationEffect

-- How far the arms swing up to hold a part over the head (R15 characters).
local HOLD_ANGLE = math.rad(165)

-- Puts the part over the carrier's head and adds a Snatch prompt for everyone else.
-- Returns false if the carrier has no character to carry it.
local function pickUp(carrier: Player, carry): boolean
	local character = carrier.Character
	local root = rootPart(carrier)
	if not character or not root then
		return false
	end
	local model = HouseModel.item(carry.record.id)
	addMutationEffect(model, carry.record)
	-- Held up over the head, facing the same way as the carrier.
	local _, size = model:GetBoundingBox()
	model:PivotTo(root.CFrame * CFrame.new(0, 3.4 + math.max(0, 5 - size.Y) * 0.2, 0))
	local first
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
			first = first or descendant
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

	if first then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "SnatchPrompt"
		prompt.ActionText = "Snatch"
		prompt.ObjectText = carry.name
		prompt.HoldDuration = Config.SNATCH_HOLD_SECONDS
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("CarrierUserId", carrier.UserId)
		prompt.Parent = first
	end

	model.Name = "CarriedPart"
	model.Parent = character
	carry.model = model
	carries[carrier] = carry
	carrier:SetAttribute("Carrying", carry.record.id)
	if carry.source == "house" then
		Carried.set(carry.owner, carry.uid, carrier)
		PlotService.render(carry.owner)
	end
	return true
end

-- Takes the part off the carrier.
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

-- The carrier dropped it: a house part goes back on its owner's house, a zone part is gone
-- (its pile grows a new one).
local function drop(carrier: Player, carry, ownerMessage: string?, carrierMessage: string?)
	putDown(carrier, carry)
	if carry.source == "house" then
		Carried.set(carry.owner, carry.uid, nil)
		PlotService.render(carry.owner)
		if ownerMessage then
			notify(carry.owner, ownerMessage, "success")
		end
	else
		ZoneService.release(carry.zone, carry.pedestal)
	end
	if carrierMessage then
		notify(carrier, carrierMessage, "error")
	end
end

-- Adds a part to a player's save: onto the house if it beats what's in its slot (the old
-- one goes in the backpack, or is sold if the backpack is full), otherwise in the backpack.
-- Returns "installed" or "backpack".
function StealService.give(player: Player, data, record): string
	local uid = DataService.newUid(data)
	data.parts[uid] = { id = record.id, mutations = Mutations.pack(record.mutations) }
	data.discovered[record.id] = true
	task.spawn(DiscoveryService.claim, player, record.id)
	local slotId = Parts.byId[record.id].slot
	local current, currentUid = HouseUtil.installedRecord(data, slotId)
	local currentIncome = HouseUtil.partIncome(current or { id = Parts.basic(slotId) })
	if HouseUtil.partIncome(data.parts[uid]) > currentIncome then
		data.house[slotId] = uid
		if current and HouseUtil.backpackCount(data) > GamePasses.backpackSize(player) then
			-- No room for the old part: sell it.
			local price = HouseUtil.sellPrice(current)
			data.parts[currentUid] = nil
			data.money += price
		end
		return "installed"
	end
	return "backpack"
end

local function deliver(carrier: Player, carry)
	local carrierData = DataService.get(carrier)
	if not carrierData then
		return drop(carrier, carry)
	end
	if carry.source == "house" then
		local ownerData = DataService.get(carry.owner)
		local owned = ownerData and ownerData.parts[carry.uid]
		if not owned then
			return drop(carrier, carry)
		end
		putDown(carrier, carry)
		Carried.set(carry.owner, carry.uid, nil)
		ownerData.parts[carry.uid] = nil
		for slotId, uid in ownerData.house do
			if uid == carry.uid then
				ownerData.house[slotId] = nil
			end
		end
		DataService.changed(carry.owner)
		task.spawn(DataService.save, carry.owner)
		notify(carry.owner, carrier.DisplayName .. " stole your " .. carry.name .. "! Lock your gate!", "error")
	else
		putDown(carrier, carry)
		ZoneService.release(carry.zone, carry.pedestal)
	end
	local where = StealService.give(carrier, carrierData, carry.record)
	DataService.changed(carrier)
	task.spawn(DataService.save, carrier)
	if where == "installed" then
		notify(carrier, "🏠 " .. carry.name .. " added to your house!", "success")
	else
		notify(
			carrier,
			"🎒 " .. carry.name .. " went in your backpack (your house already has a better one).",
			"money"
		)
	end
	-- Tell the client so it can play the build effect on the right slot.
	carrier:SetAttribute("LastBuilt", carry.record.id .. "@" .. os.clock())
end

-- Checks a player could carry a part home right now. Returns an error message or nil.
local function cannotCarry(player: Player): string?
	if carries[player] then
		return "You can only carry one part at a time!"
	end
	local data = DataService.get(player)
	if not data or not PlotService.getPlot(player) or not rootPart(player) then
		return ""
	end
	if HouseUtil.backpackCount(data) >= GamePasses.backpackSize(player) then
		return "Your backpack is full! Sell some parts first."
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
		name = HouseUtil.displayName(record),
		source = "zone",
		zone = zone,
		pedestal = pedestal,
	}
	if not pickUp(player, carry) then
		return ZoneService.release(zone, pedestal)
	end
	notify(
		player,
		"You grabbed a " .. carry.name .. "! Run home before " .. Parts.ZONES[zone].title .. " catches you!",
		"success"
	)
	ZoneService.alert(zone, player)
end

local function steal(prompt: ProximityPrompt, thief: Player)
	local slotId = prompt:GetAttribute("Slot")
	local owner = Players:GetPlayerByUserId(prompt:GetAttribute("OwnerUserId") or 0)
	if not owner or owner == thief or typeof(slotId) ~= "string" then
		return
	end
	local problem = cannotCarry(thief)
	if problem then
		return if problem ~= "" then notify(thief, problem, "error") else nil
	end
	local ownerData = DataService.get(owner)
	local ownerPlot = PlotService.getPlot(owner)
	local record, uid = nil, nil
	if ownerData then
		record, uid = HouseUtil.installedRecord(ownerData, slotId)
	end
	if not record or not ownerPlot or Carried.is(owner, uid) then
		return
	end
	if PlotService.isGateLocked(ownerPlot) or not PlotService.isInside(ownerPlot, rootPart(thief).Position) then
		return notify(thief, "Their gate is locked!", "error")
	end
	local carry = {
		record = { id = record.id, mutations = record.mutations },
		name = HouseUtil.displayName(record),
		source = "house",
		owner = owner,
		uid = uid,
		slot = slotId,
	}
	if not pickUp(thief, carry) then
		return
	end
	notify(thief, "You pried off their " .. carry.name .. "! Get it back to your house!", "success")
	notify(owner, thief.DisplayName .. " is stealing your " .. carry.name .. "! Snatch it back!", "error")
end

local function snatch(prompt: ProximityPrompt, snatcher: Player)
	local carrier = Players:GetPlayerByUserId(prompt:GetAttribute("CarrierUserId") or 0)
	local carry = carrier and carries[carrier]
	if not carry or carrier == snatcher then
		return
	end
	-- The owner snatching it back puts it straight back on their house.
	if carry.source == "house" and snatcher == carry.owner then
		return drop(
			carrier,
			carry,
			"You got your " .. carry.name .. " back!",
			snatcher.DisplayName .. " snatched their part back!"
		)
	end
	local problem = cannotCarry(snatcher)
	if problem then
		return if problem ~= "" then notify(snatcher, problem, "error") else nil
	end
	putDown(carrier, carry)
	if carry.source == "house" then
		Carried.set(carry.owner, carry.uid, nil)
	end
	if not pickUp(snatcher, carry) then
		return drop(carrier, carry)
	end
	notify(carrier, snatcher.DisplayName .. " snatched " .. carry.name .. " from you!", "error")
	notify(snatcher, "You snatched " .. carry.name .. "! Get it back to your house!", "success")
end

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	if prompt.Name == "GrabPrompt" then
		grab(prompt, player)
	elseif prompt.Name == "StealPrompt" then
		steal(prompt, player)
	elseif prompt.Name == "SnatchPrompt" then
		snatch(prompt, player)
	elseif prompt.Name == "LockPrompt" then
		-- Gates can only be locked from the padlock inside the owner's own yard.
		local plot = PlotService.getPlot(player)
		if not plot or plot.index ~= prompt:GetAttribute("PlotIndex") then
			return notify(player, "That's not your gate!", "error")
		end
		local problem = PlotService.lockGate(player)
		if problem then
			notify(player, problem, "error")
		else
			notify(player, "Gate locked for " .. GamePasses.gateLockSeconds(player) .. " seconds!", "success")
		end
	end
end

function StealService.isCarrying(player: Player): boolean
	return carries[player] ~= nil
end

-- What a player is carrying (the part's record), if anything.
function StealService.carrying(player: Player)
	local carry = carries[player]
	return carry and carry.record
end

-- Makes the player drop whatever they're carrying. Returns true if they were carrying.
function StealService.drop(player: Player, carrierMessage: string?, ownerMessage: string?): boolean
	local carry = carries[player]
	if not carry then
		return false
	end
	drop(player, carry, ownerMessage, carrierMessage)
	return true
end

-- Called by WeaponService when a weapon hits someone carrying a part: they drop it.
-- Returns true if the target was carrying one.
function StealService.knockLoose(attacker: Player, target: Player, weaponName: string): boolean
	local carry = carries[target]
	if not carry then
		return false
	end
	local ownerMessage = if carry.source == "house"
		then (if attacker == carry.owner
			then "Hit with your " .. weaponName .. "! You got your " .. carry.name .. " back!"
			else attacker.DisplayName .. " knocked your " .. carry.name .. " loose! It's back on your house.")
		else nil
	drop(
		target,
		carry,
		ownerMessage,
		attacker.DisplayName .. " hit you with a " .. weaponName .. "! You dropped " .. carry.name .. "."
	)
	if attacker ~= carry.owner then
		notify(attacker, "You knocked " .. carry.name .. " loose!", "success")
	end
	return true
end

local function checkCarries()
	for carrier, carry in carries do
		local root = rootPart(carrier)
		if not root or not carry.model or not carry.model.Parent then
			drop(
				carrier,
				carry,
				"Your " .. carry.name .. " is back on your house!",
				"You dropped " .. carry.name .. "!"
			)
			continue
		end
		local home = PlotService.getPlot(carrier)
		if home and PlotService.isInside(home, root.Position) then
			deliver(carrier, carry)
		end
	end
end

function StealService.init()
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
	ZoneService.setCarrierHooks({
		carrying = StealService.carrying,
		drop = StealService.drop,
	})

	Players.PlayerRemoving:Connect(function(player)
		local carry = carries[player]
		if carry then
			drop(player, carry, "The thief left! Your " .. carry.name .. " is back on your house.")
		end
		for carrier, other in carries do
			if other.source == "house" and other.owner == player then
				putDown(carrier, other)
				Carried.set(other.owner, other.uid, nil)
				notify(carrier, other.name .. "'s owner left, so it vanished!", "error")
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.1)
			checkCarries()
		end
	end)
end

return StealService
