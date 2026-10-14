-- Stealing Freeks from other players' yards.
--
-- While a yard's gate is open, anyone else can walk in and hold the Steal prompt on a Freek
-- standing on a pad. The Freek floats over the thief's head and they walk slower: barely
-- for a Common, a lot for a Secret (see carrySpeed in Rarities).
--
-- While it's being carried:
--   * the owner can bonk the carrier with a weapon (WeaponService), or Snatch it back, and it
--     goes home;
--   * any other player can Snatch it and carry it to their own yard instead;
--   * if the carrier dies or leaves, it goes home.
-- Whoever gets it inside their own fence keeps it.
--
-- The Freek stays in the owner's save until the moment it's delivered, so a crash mid-steal
-- can never lose or duplicate it.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FreekModel = require(ReplicatedStorage.Shared.FreekModel)
local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ActionService = require(script.Parent.ActionService)
local Carried = require(script.Parent.Carried)
local DataService = require(script.Parent.DataService)
local DiscoveryService = require(script.Parent.DiscoveryService)
local PlotService = require(script.Parent.PlotService)

local StealService = {}

local notifyRemote = Remotes.get("Notify")
-- [carrier Player] = { owner, uid, slot, name, species, mutation, model, normalSpeed }
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

-- Puts the Freek on the carrier's head, slows them down, and adds a Snatch prompt for
-- everyone else. Returns false if the carrier has no character to carry it.
local function pickUp(carrier: Player, carry): boolean
	local character = carrier.Character
	local head = character and character:FindFirstChild("Head")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not head or not humanoid or humanoid.Health <= 0 then
		return false
	end
	local model = FreekModel.build(carry.species, carry.mutation)
	pcall(function()
		model:ScaleTo(0.6)
	end)
	model:PivotTo(head.CFrame * CFrame.new(0, 1, 0))
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = head
			weld.Part1 = descendant
			weld.Parent = descendant
		end
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SnatchPrompt"
	prompt.ActionText = "Snatch"
	prompt.ObjectText = carry.name
	prompt.HoldDuration = Config.SNATCH_HOLD_SECONDS
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("CarrierUserId", carrier.UserId)
	prompt.Parent = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")

	model.Name = "CarriedFreek"
	model.Parent = character

	carry.model = model
	carry.normalSpeed = humanoid.WalkSpeed
	-- Rarer Freeks are heavier: the carrier slows down more.
	local rarity = FreekUtil.species(carry).rarity
	humanoid.WalkSpeed = math.min(carry.normalSpeed, Rarities.info[rarity].carrySpeed)

	carries[carrier] = carry
	Carried.set(carry.owner, carry.uid, carrier)
	return true
end

-- Takes the Freek off the carrier and gives them their speed back.
local function putDown(carrier: Player, carry)
	carries[carrier] = nil
	if carry.model then
		carry.model:Destroy()
		carry.model = nil
	end
	local character = carrier.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and carry.normalSpeed then
		humanoid.WalkSpeed = carry.normalSpeed
	end
end

-- The Freek goes back to its owner's yard (or backpack, if its pad was filled meanwhile).
local function sendBack(carrier: Player, carry, ownerMessage: string?, carrierMessage: string?)
	putDown(carrier, carry)
	Carried.set(carry.owner, carry.uid, nil)
	local ownerData = DataService.get(carry.owner)
	local freek = ownerData and ownerData.freeks[carry.uid]
	if freek and not freek.slot then
		local taken = false
		for _, other in ownerData.freeks do
			if other.slot == carry.slot then
				taken = true
			end
		end
		freek.slot = if taken or carry.slot > ownerData.slots then FreekUtil.freeSlot(ownerData) else carry.slot
		DataService.changed(carry.owner)
	end
	if ownerMessage then
		notify(carry.owner, ownerMessage, "success")
	end
	if carrierMessage then
		notify(carrier, carrierMessage, "error")
	end
end

local function deliver(carrier: Player, carry)
	local ownerData = DataService.get(carry.owner)
	local carrierData = DataService.get(carrier)
	local freek = ownerData and ownerData.freeks[carry.uid]
	if not freek or not carrierData then
		return sendBack(carrier, carry)
	end
	if FreekUtil.count(carrierData) >= Config.MAX_FREEKS then
		return sendBack(carrier, carry, nil, "You have too many Freeks! It ran back home.")
	end

	putDown(carrier, carry)
	Carried.set(carry.owner, carry.uid, nil)
	ownerData.freeks[carry.uid] = nil
	carrierData.freeks[carry.uid] = {
		species = freek.species,
		mutation = freek.mutation,
		slot = FreekUtil.freeSlot(carrierData),
	}
	carrierData.discovered[freek.species] = true
	task.spawn(DiscoveryService.claim, carrier, freek.species)

	for _, player in { carry.owner, carrier } do
		DataService.changed(player)
		task.spawn(DataService.save, player)
	end
	notify(carry.owner, carrier.DisplayName .. " stole your " .. carry.name .. "! Lock your gate!", "error")
	notify(carrier, "You stole " .. carry.name .. "!", "success")
end

-- Checks a player could carry a Freek home right now. Returns an error message or nil.
local function cannotCarry(player: Player): string?
	if carries[player] then
		return "You can only carry one Freek at a time!"
	end
	local data = DataService.get(player)
	if not data or not PlotService.getPlot(player) or not rootPart(player) then
		return ""
	end
	if FreekUtil.count(data) >= Config.MAX_FREEKS then
		return "You have too many Freeks to steal another!"
	end
	return nil
end

local function steal(prompt: ProximityPrompt, thief: Player)
	local uid = prompt:GetAttribute("Uid")
	local owner = Players:GetPlayerByUserId(prompt:GetAttribute("OwnerUserId") or 0)
	if not owner or owner == thief or typeof(uid) ~= "string" then
		return
	end
	local problem = cannotCarry(thief)
	if problem then
		return if problem ~= "" then notify(thief, problem, "error") else nil
	end

	local ownerData = DataService.get(owner)
	local ownerPlot = PlotService.getPlot(owner)
	local freek = ownerData and ownerData.freeks[uid]
	if not freek or not freek.slot or freek.breeding or Carried.is(owner, uid) or not ownerPlot then
		return
	end
	if PlotService.isGateLocked(ownerPlot) or not PlotService.isInside(ownerPlot, rootPart(thief).Position) then
		return
	end

	local carry = {
		owner = owner,
		uid = uid,
		slot = freek.slot,
		name = FreekUtil.displayName(freek),
		species = freek.species,
		mutation = freek.mutation,
	}
	if not pickUp(thief, carry) then
		return
	end
	freek.slot = nil
	DataService.changed(owner)

	notify(thief, "You grabbed " .. carry.name .. "! Get it back to your yard!", "success")
	notify(owner, thief.DisplayName .. " is stealing your " .. carry.name .. "! Bonk them!", "error")
end

local function snatch(prompt: ProximityPrompt, snatcher: Player)
	local carrier = Players:GetPlayerByUserId(prompt:GetAttribute("CarrierUserId") or 0)
	local carry = carrier and carries[carrier]
	if not carry or carrier == snatcher then
		return
	end

	-- The owner snatching it back sends it straight home.
	if snatcher == carry.owner then
		return sendBack(
			carrier,
			carry,
			"You got your " .. carry.name .. " back!",
			snatcher.DisplayName .. " snatched their Freek back!"
		)
	end

	local problem = cannotCarry(snatcher)
	if problem then
		return if problem ~= "" then notify(snatcher, problem, "error") else nil
	end
	putDown(carrier, carry)
	if not pickUp(snatcher, carry) then
		return sendBack(carrier, carry)
	end
	notify(carrier, snatcher.DisplayName .. " snatched " .. carry.name .. " from you!", "error")
	notify(snatcher, "You snatched " .. carry.name .. "! Get it back to your yard!", "success")
	notify(
		carry.owner,
		snatcher.DisplayName .. " snatched your " .. carry.name .. " from " .. carrier.DisplayName .. "!",
		"error"
	)
end

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	if prompt.Name == "StealPrompt" then
		steal(prompt, player)
	elseif prompt.Name == "SnatchPrompt" then
		snatch(prompt, player)
	end
end

-- Called by WeaponService when one player hits another. Only the Freek's owner can knock
-- it loose; hitting anyone else does nothing.
function StealService.onHit(attacker: Player, target: Player)
	local carry = carries[target]
	if carry and carry.owner == attacker then
		sendBack(
			target,
			carry,
			"BONK! You got your " .. carry.name .. " back!",
			attacker.DisplayName .. " bonked you! You dropped " .. carry.name .. "."
		)
	end
end

local function checkCarries()
	for carrier, carry in carries do
		local root = rootPart(carrier)
		if not root or not carry.model or not carry.model.Parent then
			sendBack(
				carrier,
				carry,
				"Your " .. carry.name .. " escaped and ran home!",
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

	ActionService.register("LockGate", function(player: Player)
		local problem = PlotService.lockGate(player)
		if problem then
			notify(player, problem, "error")
		else
			notify(player, "Gate locked for " .. Config.GATE_LOCK_SECONDS .. " seconds!", "success")
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local carry = carries[player]
		if carry then
			sendBack(player, carry, "The thief left! Your " .. carry.name .. " is back home.")
		end
		for carrier, other in carries do
			if other.owner == player then
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
