-- Monster Crates, the daily Lucky Wheel and Lucky Hour events (rules and odds in
-- shared/Luck.luau). All rolls happen here; the client only shows the result (the
-- LuckResult remote) with a reveal animation.
--
-- Monster Crates are Developer Products. ProcessReceipt grants a crate only once per
-- purchase (receipts are remembered in the player's save) and only tells Roblox the
-- purchase went through after the save succeeds, so nobody pays without getting it.

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local EggModel = require(ReplicatedStorage.Shared.EggModel)
local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local Freeks = require(ReplicatedStorage.Shared.Freeks)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local Luck = require(ReplicatedStorage.Shared.Luck)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Seasons = require(ReplicatedStorage.Shared.Seasons)

local ActionService = require(script.Parent.ActionService)
local DataService = require(script.Parent.DataService)

local LuckService = {}

local rng = Random.new()
local notifyRemote = Remotes.get("Notify")
local resultRemote = Remotes.get("LuckResult")
local RECEIPTS_KEPT = 50 -- how many recent purchase IDs each save remembers

-- Odds for the wheel's Golden/Rainbow Freek (by rarity, never Monsters).
local WHEEL_FREEK_ODDS = { Common = 35, Uncommon = 45, Rare = 17, Legendary = 3 }

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

-- A random non-Monster species of that rarity (or the next rarity down that has any).
local function pickSpecies(rarity: string)
	local rank = Rarities.rank[rarity]
	while rank >= 1 do
		local pool = {}
		for _, species in Freeks.list do
			if
				species.rarity == Rarities.order[rank]
				and not species.exclusive
				and not species.event
				and species.rarity ~= "Secret"
				and Seasons.available(species)
			then
				table.insert(pool, species)
			end
		end
		if #pool > 0 then
			return pool[rng:NextInteger(1, #pool)]
		end
		rank -= 1
	end
	return Freeks.list[1]
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
	return FreekUtil.count(data) < GamePasses.maxFreeks(player)
end

-- Gives the player a Freek and tells their client to show the reveal.
local function giveFreek(player: Player, data, species, mutations, reveal)
	local _, isNew = ActionService.giveFreek(player, data, species.id, mutations)
	local freek = { species = species.id, mutations = mutations }
	reveal.freek = freek
	reveal.isNew = isNew
	reveal.rarity = species.rarity
	resultRemote:FireClient(player, reveal)
	if Rarities.rank[species.rarity] >= Rarities.rank.Legendary then
		announce(player.DisplayName .. " got a " .. species.rarity .. " " .. FreekUtil.displayName(freek) .. "!")
	end
end

local function openCrate(player: Player, data, crate)
	local species = Freeks.byId[rollWeighted(Luck.crateOdds(crate))]
	giveFreek(player, data, species, rollMutations(crate.mutation), { kind = "crate", crate = crate.id })
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
		return notify(player, "Monster Eggs aren't available where you live.", "error")
	end
	if not hasRoom(player, data) then
		return notify(player, "You have too many Freeks! Sell or fuse some first.", "error")
	end
	if crate.productId == 0 then
		if RunService:IsStudio() and Luck.STUDIO_FREE_CRATES then
			notify(player, "Studio test: hatching a " .. crate.name .. " for free.", "success")
			return openCrate(player, data, crate)
		end
		return notify(player, "Monster Eggs are coming soon!", "error")
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
		return notify(player, "You have too many Freeks! Sell or fuse some first.", "error")
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
		return notify(player, "Monster Eggs aren't available where you live.", "error")
	end
	if bundle.productId == 0 then
		return notify(player, "This bundle is coming soon!", "error")
	end
	MarketplaceService:PromptProductPurchase(player, bundle.productId)
end

-- Gives the Starter Pack's contents, once ever (the eggs wait in the Luck tab).
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
	notify(player, "🎁 Starter Pack unlocked! Your eggs are waiting in the 🍀 Luck tab.", "discovery")
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

-- Gives what a bundle contains (eggs are saved to hatch from Luck).
local function grantPack(player: Player, data, productId: number): boolean
	local bundle = Luck.bundleByProduct[productId]
	if bundle then
		data.crates[bundle.crate] = (data.crates[bundle.crate] or 0) + bundle.count
		notify(player, "🥚 " .. bundle.name .. " added! Hatch them from the 🍀 Luck tab.", "discovery")
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
				"Your barn is full, so your " .. crate.name .. " was saved. Hatch it from the 🍀 Luck tab!",
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
	return math.max(Luck.MIN_COIN_PRIZE, math.floor(FreekUtil.yardIncome(data) * 60 * minutes))
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

	if (slice.golden or slice.rainbow) and hasRoom(player, data) then
		local species = pickSpecies(rollWeighted(WHEEL_FREEK_ODDS))
		return giveFreek(player, data, species, { if slice.rainbow then "Rainbow" else "Golden" }, reveal)
	end
	if slice.crate then
		data.crates[slice.crate] = (data.crates[slice.crate] or 0) + 1
		reveal.crate = slice.crate
		if slice.crate == "LegendaryMonster" then
			announce(player.DisplayName .. " hit the JACKPOT on the Lucky Wheel!")
		end
	else
		-- Coins (also the fallback for a Freek prize when the barn is full).
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

-- The Egg Stand by the spawn: the three Monster Eggs on glowing pedestals, each with its
-- odds floating above it (like the egg stands in pet games). Hold E to hatch one.
local STAND_X = 128
local OUTLINE = Color3.fromRGB(20, 22, 48)

local function outlinedLabel(parent: Instance, text: string, color: Color3, top: number, height: number, font)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0, top)
	label.Size = UDim2.fromScale(1, height)
	label.TextScaled = true
	label.Font = font
	label.Text = text
	label.TextColor3 = color
	label.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE
	stroke.Thickness = 2.5
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	return label
end

local function buildEggStand()
	local folder = Instance.new("Folder")
	folder.Name = "EggStand"
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

		local egg, height = EggModel.build(crate.id)
		local rest = base * CFrame.new(0, 1.2, 0)
		egg:PivotTo(rest)
		egg:SetAttribute("Rest", rest) -- clients spin and bob it around here
		CollectionService:AddTag(egg, "DisplayEgg")
		egg.Parent = folder

		-- The odds float above the egg.
		local odds = Luck.oddsList(crate)
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(230, 46 + #odds * 20)
		gui.StudsOffsetWorldSpace = Vector3.new(0, height + 3.2, 0)
		gui.MaxDistance = 80
		gui.LightInfluence = 0
		local total = 46 + #odds * 20
		outlinedLabel(gui, string.upper(crate.name), crate.color, 0, 26 / total, Enum.Font.LuckiestGuy)
		outlinedLabel(
			gui,
			"R$ " .. crate.robux,
			Color3.fromRGB(110, 240, 120),
			26 / total,
			20 / total,
			Enum.Font.LuckiestGuy
		)
		for k, entry in odds do
			local species = Freeks.byId[entry.species]
			local percent = if entry.percent < 1
				then string.format("%.1f", entry.percent)
				else string.format("%.0f", entry.percent)
			outlinedLabel(
				gui,
				species.name .. "  " .. percent .. "%",
				Rarities.info[species.rarity].color,
				(46 + (k - 1) * 20) / total,
				19 / total,
				Enum.Font.FredokaOne
			)
		end
		gui.Parent = egg.PrimaryPart

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "EggPrompt"
		prompt.ActionText = "Hatch (R$ " .. crate.robux .. ")"
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
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(26, 5)
	gui.MaxDistance = 300
	gui.LightInfluence = 0
	local label =
		outlinedLabel(gui, "🥚 MONSTER EGGS 🥚", Color3.fromRGB(255, 160, 40), 0, 1, Enum.Font.LuckiestGuy)
	label:FindFirstChildOfClass("UIStroke").Thickness = 4
	gui.Parent = signPart
end

function LuckService.init()
	buildEggStand()
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		local eggId = prompt.Name == "EggPrompt" and prompt:GetAttribute("EggId")
		local data = DataService.get(player)
		if eggId and data then
			buyCrate(player, data, eggId)
			DataService.changed(player)
		end
	end)
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
