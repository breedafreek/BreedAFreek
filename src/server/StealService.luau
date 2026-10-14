-- Stealing Freeks from other players' yards.
--
-- While a yard's gate is open, anyone else can walk in and hold the Steal prompt on a Freek
-- standing on a pad. The Freek floats over the thief's head and they walk slower: barely
-- for a Common, a lot for a Secret (see carrySpeed in Rarities). If the
-- owner gets within CATCH_DISTANCE before the thief is back inside their own fence, or the
-- thief dies or leaves, the Freek goes home. If the thief makes it home, it's theirs.
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
local carries = {} -- [thief Player] = { owner, uid, slot, name, model, normalSpeed }

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

local function attachToHead(player: Player, freek): (Model?, number?)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not head or not humanoid then
		return nil, nil
	end
	local model = FreekModel.build(freek.species, freek.mutation)
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
	model.Name = "CarriedFreek"
	model.Parent = character

	local normalSpeed = humanoid.WalkSpeed
	-- Rarer Freeks are heavier: the thief slows down more.
	local rarity = FreekUtil.species(freek).rarity
	humanoid.WalkSpeed = math.min(normalSpeed, Rarities.info[rarity].carrySpeed)
	return model, normalSpeed
end

local function cleanup(thief: Player, carry)
	carries[thief] = nil
	Carried.set(carry.owner, carry.uid, nil)
	if carry.model then
		carry.model:Destroy()
	end
	local character = thief.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and carry.normalSpeed then
		humanoid.WalkSpeed = carry.normalSpeed
	end
end

-- The Freek goes back to its owner's yard (or backpack, if its pad was filled meanwhile).
local function sendBack(thief: Player, carry, ownerMessage: string?, thiefMessage: string?)
	cleanup(thief, carry)
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
	if thiefMessage then
		notify(thief, thiefMessage, "error")
	end
end

local function deliver(thief: Player, carry)
	local ownerData = DataService.get(carry.owner)
	local thiefData = DataService.get(thief)
	local freek = ownerData and ownerData.freeks[carry.uid]
	if not freek or not thiefData then
		return sendBack(thief, carry)
	end
	if FreekUtil.count(thiefData) >= Config.MAX_FREEKS then
		return sendBack(thief, carry, nil, "You have too many Freeks! It ran back home.")
	end

	cleanup(thief, carry)
	ownerData.freeks[carry.uid] = nil
	thiefData.freeks[carry.uid] = {
		species = freek.species,
		mutation = freek.mutation,
		slot = FreekUtil.freeSlot(thiefData),
	}
	thiefData.discovered[freek.species] = true
	task.spawn(DiscoveryService.claim, thief, freek.species)

	for _, player in { carry.owner, thief } do
		DataService.changed(player)
		task.spawn(DataService.save, player)
	end
	notify(carry.owner, thief.DisplayName .. " stole your " .. carry.name .. "! Lock your gate!", "error")
	notify(thief, "You stole " .. carry.name .. "!", "success")
end

local function onPromptTriggered(prompt: ProximityPrompt, thief: Player)
	if prompt.Name ~= "StealPrompt" then
		return
	end
	local uid = prompt:GetAttribute("Uid")
	local owner = Players:GetPlayerByUserId(prompt:GetAttribute("OwnerUserId") or 0)
	if not owner or owner == thief or typeof(uid) ~= "string" then
		return
	end
	if carries[thief] then
		return notify(thief, "You can only carry one Freek at a time!", "error")
	end

	local ownerData, thiefData = DataService.get(owner), DataService.get(thief)
	local ownerPlot, thiefPlot = PlotService.getPlot(owner), PlotService.getPlot(thief)
	local freek = ownerData and ownerData.freeks[uid]
	local root = rootPart(thief)
	if not freek or not freek.slot or freek.breeding or Carried.is(owner, uid) then
		return
	end
	if not thiefData or not ownerPlot or not thiefPlot or not root then
		return
	end
	if PlotService.isGateLocked(ownerPlot) or not PlotService.isInside(ownerPlot, root.Position) then
		return
	end
	if FreekUtil.count(thiefData) >= Config.MAX_FREEKS then
		return notify(thief, "You have too many Freeks to steal another!", "error")
	end

	local model, normalSpeed = attachToHead(thief, freek)
	if not model then
		return
	end
	local name = FreekUtil.displayName(freek)
	carries[thief] = {
		owner = owner,
		uid = uid,
		slot = freek.slot,
		name = name,
		model = model,
		normalSpeed = normalSpeed,
	}
	Carried.set(owner, uid, thief)
	freek.slot = nil
	DataService.changed(owner)

	notify(
		thief,
		"You grabbed " .. name .. "! Get back to your yard before " .. owner.DisplayName .. " catches you!",
		"success"
	)
	notify(owner, thief.DisplayName .. " is stealing your " .. name .. "! Catch them!", "error")
end

local function checkCarries()
	for thief, carry in carries do
		local root = rootPart(thief)
		if not root or not carry.model.Parent then
			sendBack(
				thief,
				carry,
				"Your " .. carry.name .. " escaped and ran home!",
				"You dropped " .. carry.name .. "!"
			)
			continue
		end
		local ownerRoot = rootPart(carry.owner)
		if ownerRoot and (ownerRoot.Position - root.Position).Magnitude <= Config.CATCH_DISTANCE then
			sendBack(
				thief,
				carry,
				"You caught " .. thief.DisplayName .. "! " .. carry.name .. " is back home.",
				carry.owner.DisplayName .. " caught you!"
			)
			continue
		end
		local home = PlotService.getPlot(thief)
		if home and PlotService.isInside(home, root.Position) then
			deliver(thief, carry)
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
		for thief, other in carries do
			if other.owner == player then
				cleanup(thief, other)
				notify(thief, other.name .. "'s owner left, so it vanished!", "error")
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
