-- Mystery Boxes, the daily Lucky Wheel and Lucky Hour events (rules and odds in
-- shared/Luck.luau). All rolls happen here; the client only shows the result (the
-- LuckResult remote) with a reveal animation.
--
-- Mystery Boxes are Developer Products. ProcessReceipt grants a crate only once per
-- purchase (receipts are remembered in the player's save) and only tells Roblox the
-- purchase went through after the save succeeds, so nobody pays without getting it.

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BoxModel = require(ReplicatedStorage.Shared.BoxModel)
local FloatText = require(ReplicatedStorage.Shared.FloatText)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local Items = require(ReplicatedStorage.Shared.Items)
local LifeUtil = require(ReplicatedStorage.Shared.LifeUtil)
local Luck = require(ReplicatedStorage.Shared.Luck)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ActionService = require(script.Parent.ActionService)
local DataService = require(script.Parent.DataService)
local NestService = require(script.Parent.NestService)

local LuckService = {}

local rng = Random.new()
local notifyRemote = Remotes.get("Notify")
local resultRemote = Remotes.get("LuckResult")
local RECEIPTS_KEPT = 50 -- how many recent purchase IDs each save remembers

local function notify(player: Player, message: string, kind: string?)
	notifyRemote:FireClient(player, message, kind)
end

local function announce(message: string)
	for _, player in Players:GetPlayers() do
		notify(player, message, "discovery")
	end
end

-- Picks a key from a { [key] = weight } table.
local function rollWeighted(weights: { [string]: number }): string
	local keys = {}
	local total = 0
	for key, weight in weights do
		table.insert(keys, key)
		total += weight
	end
	table.sort(keys)
	local roll = rng:NextNumber() * total
	for _, key in keys do
		roll -= weights[key]
		if roll <= 0 then
			return key
		end
	end
	return keys[#keys]
end

-- A random item of this rarity, of any kind.
local function pickItem(rarity: string): string
	local kind = Items.KIND_ORDER[rng:NextInteger(1, #Items.KIND_ORDER)]
	return NestService.rollItem(kind, rarity)
end

local function rollMutations(boost: number): { string }?
	for _, mutation in Mutations.list do
		if rng:NextNumber() < mutation.chance * boost then
			return { mutation.id }
		end
	end
	return nil
end

local function hasRoom(player: Player, data): boolean
	return LifeUtil.backpackCount(data) < GamePasses.backpackSize(player)
end

local function openCrate(player: Player, data, crate)
	NestService.reward(
		player,
		data,
		pickItem(rollWeighted(Luck.crateOdds(crate))),
		rollMutations(crate.mutation),
		{ kind = "crate", crate = crate.id },
		Items.rollWeightFactor(rng, crate.mutation),
		1
	)
end

-- Whether paid random items are allowed for this player (some countries ban them).
local function cratesAllowed(player: Player): boolean
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if not ok then
		return RunService:IsStudio() -- can't check: only allow while testing in Studio
	end
	return not info.ArePaidRandomItemsRestricted
end

-- The player asked to buy a crate: check, then show Roblox's purchase prompt.
local function buyCrate(player: Player, data, crateId: any)
	local crate = typeof(crateId) == "string" and Luck.crateById[crateId]
	if not crate then
		return
	end
	if player:GetAttribute("CratesRestricted") then
		return notify(player, "Mystery Boxes aren't available where you live.", "error")
	end
	if not hasRoom(player, data) then
		return notify(player, "Your backpack is full! Sell some items first.", "error")
	end
	if crate.productId == 0 then
		if RunService:IsStudio() and Luck.STUDIO_FREE_CRATES then
			notify(player, "Studio test: opening a " .. crate.name .. " for free.", "success")
			return openCrate(player, data, crate)
		end
		return notify(player, "Mystery Boxes are coming soon!", "error")
	end
	MarketplaceService:PromptProductPurchase(player, crate.productId)
end

-- Opens a crate the player already owns (won on the wheel, or bought while full).
local function openOwnedCrate(player: Player, data, crateId: any)
	local crate = typeof(crateId) == "string" and Luck.crateById[crateId]
	if not crate or (data.crates[crate.id] or 0) < 1 then
		return
	end
	if not hasRoom(player, data) then
		return notify(player, "Your backpack is full! Sell some items first.", "error")
	end
	data.crates[crate.id] -= 1
	openCrate(player, data, crate)
end

-- Shows the Starter Pack countdown on the player (StarterEnds; nil once bought).
local function markStarter(player: Player, data)
	local ends = (data.firstJoin or os.time()) + Luck.STARTER.hours * 3600
	local offerOpen = not data.starterBought and os.time() < ends
	-- Server time, so the client's countdown lines up with GetServerTimeNow.
	local offset = Workspace:GetServerTimeNow() - os.time()
	player:SetAttribute("StarterEnds", if offerOpen then ends + offset else nil)
end

local function buyStarter(player: Player, data)
	if player:GetAttribute("CratesRestricted") then
		return notify(player, "The Starter Pack isn't available where you live.", "error")
	end
	if data.starterBought or not player:GetAttribute("StarterEnds") then
		return notify(player, "The Starter Pack offer is over.", "error")
	end
	if Luck.STARTER.passId == 0 then
		return notify(player, "The Starter Pack is coming soon!", "error")
	end
	MarketplaceService:PromptGamePassPurchase(player, Luck.STARTER.passId)
end

local function buyBundle(player: Player, _data, bundleId: any)
	local bundle = typeof(bundleId) == "string" and Luck.bundleById[bundleId]
	if not bundle then
		return
	end
	if player:GetAttribute("CratesRestricted") then
		return notify(player, "Mystery Boxes aren't available where you live.", "error")
	end
	if bundle.productId == 0 then
		return notify(player, "This bundle is coming soon!", "error")
	end
	MarketplaceService:PromptProductPurchase(player, bundle.productId)
end

-- Gives the Starter Pack's contents, once ever (the boxes wait in the Luck tab).
local function grantStarter(player: Player, data)
	if data.starterBought then
		return
	end
	local starter = Luck.STARTER
	data.money += starter.coins
	for crateId, count in starter.crates do
		data.crates[crateId] = (data.crates[crateId] or 0) + count
	end
	data.starterBought = true
	markStarter(player, data)
	notify(player, "🎁 Starter Pack unlocked! Your Mystery Boxes are waiting in the 🍀 Luck tab.", "discovery")
	DataService.changed(player)
	task.spawn(DataService.save, player)
end

-- Owns the Starter Pack pass (bought here or on the website) but hasn't had it yet: give it.
local function checkStarterPass(player: Player, data)
	if data.starterBought or Luck.STARTER.passId == 0 then
		return
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Luck.STARTER.passId)
	end)
	if ok and owns then
		grantStarter(player, data)
	end
end

-- Gives what a bundle contains (boxes are saved to open from Luck).
local function grantPack(player: Player, data, productId: number): boolean
	local bundle = Luck.bundleByProduct[productId]
	if bundle then
		data.crates[bundle.crate] = (data.crates[bundle.crate] or 0) + bundle.count
		notify(player, "📦 " .. bundle.name .. " added! Open them from the 🍀 Luck tab.", "discovery")
		return true
	end
	return false
end

local function isOurs(productId: number): boolean
	return Luck.crateByProduct[productId] ~= nil or Luck.bundleByProduct[productId] ~= nil
end

local function processReceipt(receipt)
	local crate = Luck.crateByProduct[receipt.ProductId]
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local data = player and DataService.get(player)
	if not isOurs(receipt.ProductId) or not data then
		-- Not ours, or the player isn't here: Roblox will try again later.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	data.receipts = data.receipts or {}
	if not table.find(data.receipts, receipt.PurchaseId) then
		if not crate then
			grantPack(player, data, receipt.ProductId)
		elseif hasRoom(player, data) then
			openCrate(player, data, crate)
		else
			data.crates[crate.id] = (data.crates[crate.id] or 0) + 1
			notify(
				player,
				"Your backpack is full, so your " .. crate.name .. " was saved. Open it from the 🍀 Luck tab!",
				"success"
			)
		end
		table.insert(data.receipts, receipt.PurchaseId)
		while #data.receipts > RECEIPTS_KEPT do
			table.remove(data.receipts, 1)
		end
		DataService.changed(player)
	end
	if not DataService.save(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function spinCooldown(player: Player): number
	return if GamePasses.has(player, "VIP") then Luck.VIP_SPIN_COOLDOWN else Luck.SPIN_COOLDOWN
end

local function coinPrize(data, minutes: number): number
	return math.max(Luck.MIN_COIN_PRIZE, math.floor(LifeUtil.totalIncome(data) * 60 * minutes))
end

local function spin(player: Player, data)
	local now = os.time()
	if now - (data.lastSpin or 0) < spinCooldown(player) then
		return notify(player, "Your next free spin isn't ready yet!", "error")
	end
	data.lastSpin = now

	local weights = {}
	for i, slice in Luck.WHEEL do
		weights[tostring(i)] = slice.weight
	end
	local index = tonumber(rollWeighted(weights)) :: number
	local slice = Luck.WHEEL[index]
	local reveal = { kind = "wheel", slice = index }

	if slice.golden or slice.rainbow then
		-- An egg from the best zone the player's Speed reaches, hatched on the spot.
		local zone = Items.zoneFor(data.speed)
		local itemId = NestService.rollItem(Items.ZONES[zone].kind, Items.rollRarity(zone, rng))
		reveal.egg = zone
		return NestService.reward(
			player,
			data,
			itemId,
			{ if slice.rainbow then "Rainbow" else "Golden" },
			reveal,
			Items.eggBaseWeight(zone) * Items.rollWeightFactor(rng),
			Items.eggBaseWeight(zone)
		)
	end
	if slice.crate then
		data.crates[slice.crate] = (data.crates[slice.crate] or 0) + 1
		reveal.crate = slice.crate
		if slice.crate == "LegendaryMonster" then
			announce(player.DisplayName .. " hit the JACKPOT on the Lucky Wheel!")
		end
	else
		-- Coins (also the fallback for a part prize when the backpack is full).
		local amount = coinPrize(data, slice.minutes or 10)
		data.money += amount
		reveal.coins = amount
	end
	resultRemote:FireClient(player, reveal)
end

-- Runs Lucky Hour events forever: a random one every so often, announced to everyone.
local function runEvents()
	task.wait(Luck.FIRST_EVENT_AFTER)
	local ids = {}
	for id in Luck.EVENTS do
		table.insert(ids, id)
	end
	table.sort(ids)
	while true do
		local id = ids[rng:NextInteger(1, #ids)]
		local event = Luck.EVENTS[id]
		ReplicatedStorage:SetAttribute("LuckyEvent", id)
		ReplicatedStorage:SetAttribute("LuckyEventEnds", Workspace:GetServerTimeNow() + Luck.EVENT_DURATION)
		announce(event.icon .. " " .. event.name .. "! " .. event.description)
		task.wait(Luck.EVENT_DURATION)
		ReplicatedStorage:SetAttribute("LuckyEvent", nil)
		announce(event.name .. " is over. Another one will come soon!")
		task.wait(rng:NextInteger(Luck.EVENT_GAP[1], Luck.EVENT_GAP[2]))
	end
end

-- Marks players who can't buy crates so their client hides the buy buttons.
local function checkPolicy(player: Player)
	player:SetAttribute("CratesRestricted", not cratesAllowed(player))
end

-- The Mystery Box stand by the spawn: the three boxes on glowing pedestals, each with its
-- name and price floating above it. Hold E on one to see its odds and buy it in the Luck
-- window (the client opens it), so the odds are always shown before buying.
local STAND_X = 190
local function buildBoxStand()
	local folder = Instance.new("Folder")
	folder.Name = "BoxStand"
	folder.Parent = Workspace
	for i, crate in Luck.CRATES do
		local z = (i - 2) * 13
		local base = CFrame.lookAt(Vector3.new(STAND_X, 0, z), Vector3.new(STAND_X + 10, 0, z)) -- faces the spawn
		local pedestal = Instance.new("Part")
		pedestal.Name = "EggPedestal"
		pedestal.Anchored = true
		pedestal.Shape = Enum.PartType.Cylinder
		pedestal.Size = Vector3.new(1.2, 7, 7)
		pedestal.CFrame = base * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90))
		pedestal.Color = Color3.fromRGB(45, 35, 65)
		pedestal.Material = Enum.Material.Slate
		pedestal.Parent = folder
		local rim = pedestal:Clone()
		rim.Name = "EggRim"
		rim.Size = Vector3.new(0.3, 7.6, 7.6)
		rim.CFrame = base * CFrame.new(0, 0.85, 0) * CFrame.Angles(0, 0, math.rad(90))
		rim.Color = crate.color
		rim.Material = Enum.Material.Neon
		rim.Parent = folder

		local egg, height = BoxModel.build(crate.id)
		local rest = base * CFrame.new(0, 1.2, 0)
		egg:PivotTo(rest)
		egg:SetAttribute("Rest", rest) -- clients spin and bob it around here
		CollectionService:AddTag(egg, "DisplayEgg")
		egg.Parent = folder

		-- Its name and price float above it.
		local _, lines = FloatText.new(egg.PrimaryPart, { { size = 22, heavy = true }, { size = 18, heavy = true } }, {
			offset = Vector3.new(0, height + 2.5, 0),
			maxDistance = 40,
		})
		lines[1].Text = string.upper(crate.name)
		lines[1].TextColor3 = crate.color
		lines[2].Text = "R$ " .. crate.robux
		lines[2].TextColor3 = Color3.fromRGB(110, 240, 70)

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "EggPrompt"
		prompt.ActionText = "See odds"
		prompt.ObjectText = crate.name
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("EggId", crate.id)
		prompt.Parent = egg.PrimaryPart
	end

	-- A big sign over the stand.
	local signPart = Instance.new("Part")
	signPart.Name = "EggSign"
	signPart.Anchored = true
	signPart.Transparency = 1
	signPart.CanCollide = false
	signPart.Size = Vector3.one
	signPart.CFrame = CFrame.new(STAND_X, 17, 0)
	signPart.Parent = folder
	local _, lines = FloatText.new(signPart, { { size = 40, heavy = true } }, { maxDistance = 160, width = 520 })
	lines[1].Text = "MYSTERY BOXES"
	lines[1].TextColor3 = Color3.fromRGB(255, 170, 40)
end

function LuckService.init()
	buildBoxStand()
	ActionService.register("BuyCrate", buyCrate)
	ActionService.register("OpenCrate", openOwnedCrate)
	ActionService.register("SpinWheel", spin)
	ActionService.register("BuyStarter", buyStarter)
	ActionService.register("BuyBundle", buyBundle)
	DataService.onLoaded(function(player, data)
		markStarter(player, data)
		checkStarterPass(player, data)
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local data = DataService.get(player)
		if purchased and data and passId == Luck.STARTER.passId then
			grantStarter(player, data)
		end
	end)
	-- The offer ends while they're playing: take the countdown down.
	task.spawn(function()
		while true do
			task.wait(30)
			for _, player in Players:GetPlayers() do
				local data = DataService.get(player)
				if data and player:GetAttribute("StarterEnds") then
					markStarter(player, data)
				end
			end
		end
	end)
	MarketplaceService.ProcessReceipt = processReceipt
	LuckService.processReceipt = processReceipt -- also called directly by tests
	Players.PlayerAdded:Connect(checkPolicy)
	for _, player in Players:GetPlayers() do
		task.spawn(checkPolicy, player)
	end
	task.spawn(runEvents)
end

return LuckService
