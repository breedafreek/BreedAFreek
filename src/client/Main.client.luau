-- The player's screen: money display, menu buttons, and the Shop / Freeks / Breed / Book
-- windows. The server is the source of truth; this only shows state and sends requests.

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

print("[Fuse a Freek] Client starting")

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
local Drops = require(Shared.Drops)
local Breeding = require(Shared.Breeding)
local Config = require(Shared.Config)
local GateTiers = require(Shared.GateTiers)
local Format = require(Shared.Format)
local FreekModel = require(Shared.FreekModel)
local FreekUtil = require(Shared.FreekUtil)
local Freeks = require(Shared.Freeks)
local GamePasses = require(Shared.GamePasses)
local Luck = require(Shared.Luck)
local Mutations = require(Shared.Mutations)
local Rarities = require(Shared.Rarities)
local Remotes = require(Shared.Remotes)
local Seasons = require(Shared.Seasons)
local Weapons = require(Shared.Weapons)
local Ambient = require(script.Parent.Ambient)
local Hud = require(script.Parent.Hud)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer
local colors = UI.colors

local actionRemote = Remotes.get("Action")
local function send(action: string, ...)
	actionRemote:FireServer(action, ...)
end

local state = nil
local discoveries = {}

--------------------------------------------------------------------------------
-- Screen layout
--------------------------------------------------------------------------------

local screen = UI.new("ScreenGui", {
	Name = "FuseAFreekUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

local setRebirthBoost = Hud.money(screen)
Hud.eventChip(screen)
Hud.luckChip(screen)
Hud.leaderboard(screen)
Hud.vipChatTag()
local toast = Hud.toasts(screen)

local window = UI.glass({
	Name = "Window",
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.53, 0.52),
	Size = UDim2.fromScale(0.66, 0.74),
	BackgroundTransparency = 0.05,
	ZIndex = 5, -- above the leaderboard and other HUD pieces
	Parent = screen,
}, {
	UI.corner(22),
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(860, 600) }),
})
local windowTitle = UI.label("", {
	Size = UDim2.new(1, -70, 0, 34),
	Position = UDim2.fromOffset(20, 12),
	TextXAlignment = Enum.TextXAlignment.Left,
	FontFace = UI.fonts.heavy,
	Parent = window,
})
local body = UI.new("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(12, 56),
	Size = UDim2.new(1, -24, 1, -68),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 8,
	Parent = window,
}, {
	UI.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	UI.new("UIPadding", { PaddingBottom = UDim.new(0, 10), PaddingRight = UDim.new(0, 8) }),
})

--------------------------------------------------------------------------------
-- Windows
--------------------------------------------------------------------------------

local currentWindow = nil
local renderers = {}
local breedSelection = {}
local penCountdowns = {} -- { { label, button, endsAt } } for the Fuse window
local trade = nil -- the server's view of my current trade, or nil
local tradeStatusLabel = nil

local function clearBody()
	for _, child in body:GetChildren() do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
	table.clear(penCountdowns)
	tradeStatusLabel = nil
end

local function render()
	if not currentWindow or not state then
		return
	end
	clearBody()
	renderers[currentWindow]()
end

local setActiveTab = function(_name: string?) end
local TAB_ICONS = {}

local function open(name: string)
	if currentWindow == name then
		currentWindow = nil
		window.Visible = false
		setActiveTab(nil)
		return
	end
	currentWindow = name
	setActiveTab(name)
	windowTitle.Text = (TAB_ICONS[name] or "") .. "  " .. name
	window.Visible = true
	body.CanvasPosition = Vector2.zero
	render()
end

UI.button("✕", colors.gray, function()
	open(currentWindow)
end, {
	Size = UDim2.fromOffset(36, 36),
	Position = UDim2.new(1, -50, 0, 12),
	Parent = window,
})
	:FindFirstChildOfClass("UICorner").CornerRadius =
	UDim.new(0, 18)

local function heading(text: string, order: number)
	return UI.label(text, {
		Size = UDim2.new(1, 0, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = colors.muted,
		LayoutOrder = order,
		Parent = body,
	})
end

local function rarityColor(speciesId: string): Color3
	return Rarities.info[Freeks.byId[speciesId].rarity].color
end

local function nameColor(freek): Color3
	local top = Mutations.top(freek.mutations)
	if top then
		return Mutations.byId[top].color
	end
	return rarityColor(freek.species)
end

-- My Freeks, best earners first.
local function sortedFreeks()
	local list = {}
	for uid, freek in state.freeks do
		table.insert(list, { uid = uid, freek = freek })
	end
	table.sort(list, function(x, y)
		local ix, iy = FreekUtil.income(x.freek), FreekUtil.income(y.freek)
		if ix ~= iy then
			return ix > iy
		end
		return x.uid < y.uid
	end)
	return list
end

-- Button that needs a second tap within 3 seconds.
local function confirmButton(text: string, color: Color3, onConfirm: () -> ())
	local armed = false
	local button
	button = UI.button(text, color, function()
		if armed then
			onConfirm()
			return
		end
		armed = true
		button.Text = "Tap again!"
		task.delay(3, function()
			if button.Parent then
				armed = false
				button.Text = text
			end
		end)
	end)
	return button
end

function renderers.Shop()
	heading("New Freeks come out of the Freek Machine onto the conveyor belt. Walk up and hold Buy!", 1)
	heading("Barn", 3)
	local yard = UI.grid(220, 120)
	yard.LayoutOrder = 4
	yard.Parent = body
	local bought = state.boughtSlots or state.slots
	local maxed = bought >= Config.MAX_SLOTS
	local price = Config.slotPrice(bought)
	UI.card({
		lines = {
			{ "Barn Slots", colors.text, 26 },
			{
				bought .. " / " .. Config.MAX_SLOTS .. " bought" .. (if (state.passSlots or 0) > 0
					then "  ·  +" .. state.passSlots .. " from passes"
					else ""),
				colors.muted,
			},
		},
		buttons = {
			UI.button(
				if maxed then "Maxed out!" else "Buy slot " .. Format.money(price),
				if maxed or state.money < price then colors.gray else colors.blue,
				function()
					send("BuySlot")
				end
			),
		},
	}).Parent =
		yard

	heading("Weapons", 5)
	local weapons = UI.grid(220, 150)
	weapons.LayoutOrder = 6
	weapons.Parent = body
	for i, weaponId in Weapons.order do
		local weapon = Weapons.list[weaponId]
		local owned = weaponId == Weapons.STARTER or (state.rebirths or 0) >= (weapon.rebirth or math.huge)
		local card = UI.card({
			lines = {
				{ weapon.name, weapon.color:Lerp(Color3.new(1, 1, 1), 0.3), 24 },
				{ weapon.description, colors.muted, 44 },
			},
			buttons = {
				UI.button(
					if owned then "Unlocked" else "Unlocks at Rebirth " .. weapon.rebirth,
					if owned then colors.green else colors.gray,
					function()
						if not owned then
							open("Rebirth")
						end
					end
				),
			},
		})
		card.LayoutOrder = i
		card.Parent = weapons
	end
end

function renderers.Freeks()
	local list = sortedFreeks()
	local placed = 0
	for _, item in list do
		if item.freek.slot then
			placed += 1
		end
	end
	heading(
		string.format(
			"%d Freeks (max %d)  ·  %d / %d in barn",
			#list,
			GamePasses.maxFreeks(player),
			placed,
			state.slots
		),
		1
	)
	if #list == 0 then
		heading("No Freeks yet! Buy one in the Shop.", 2)
		return
	end

	local grid = UI.grid(150, 270)
	grid.LayoutOrder = 3
	grid.Parent = body
	for i, item in list do
		local uid, freek = item.uid, item.freek
		local status, statusColor
		if freek.breeding then
			status, statusColor = "Fusing", colors.pink
		elseif freek.slot then
			status, statusColor = "In barn", colors.money
		else
			status, statusColor = "In backpack (not earning)", colors.muted
		end

		local buttons = {}
		if not freek.breeding then
			if freek.slot then
				table.insert(
					buttons,
					UI.button("Take out", colors.orange, function()
						send("Unplace", uid)
					end)
				)
			else
				table.insert(
					buttons,
					UI.button("Put in barn", colors.green, function()
						send("Place", uid)
					end)
				)
			end
			table.insert(
				buttons,
				confirmButton("Sell " .. Format.money(FreekUtil.sellValue(freek)), colors.red, function()
					send("Sell", uid)
				end)
			)
		end

		local card = UI.card({
			species = freek.species,
			mutations = freek.mutations,
			lines = {
				{ FreekUtil.displayName(freek), nameColor(freek), 20 },
				{ FreekUtil.rarityText(freek.species), rarityColor(freek.species), 16 },
				{ Format.money(FreekUtil.income(freek)) .. "/s", colors.money },
				{ status, statusColor, 14 },
			},
			buttons = buttons,
		})
		card.LayoutOrder = i
		card.Parent = grid
	end
end

function renderers.Fuse()
	-- Pens: what's cooking in each, and a locked card for the Extra Breeding Pen.
	local pens = GamePasses.penCount(player)
	local freePen = false
	local penGrid = UI.grid(300, 250)
	penGrid.LayoutOrder = 0
	penGrid.Parent = body
	for index = 1, #FreekUtil.PEN_KEYS do
		local breeding = FreekUtil.pen(state, index)
		local card
		if breeding then
			local a, b = state.freeks[breeding.a], state.freeks[breeding.b]
			local pair = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 100) }, {
				UI.new("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),
			})
			for _, freek in { a, b } do
				if freek then
					local view = UI.viewport(freek.species, freek.mutations)
					view.Size = UDim2.new(0.5, 0, 1, 0)
					view.Parent = pair
				end
			end
			local countdown = UI.label("", { Size = UDim2.new(1, 0, 0, 22) })
			local claim = UI.button("Collect!", colors.pink, function()
				send("ClaimBreed", index)
			end, { Size = UDim2.new(1, 0, 0, 38) })
			card = UI.card({
				lines = { { "Den " .. index, colors.pink, 22 } },
				buttons = { pair, countdown, claim },
			})
			table.insert(penCountdowns, { label = countdown, button = claim, endsAt = breeding.endsAt })
		elseif index <= pens then
			freePen = true
			card = UI.card({
				lines = {
					{ "Den " .. index, colors.pink, 22 },
					{ "Empty. Pick two Freeks below!", colors.muted, 18 },
				},
			})
		else
			card = UI.card({
				lines = {
					{ "🐣", colors.text, 40 },
					{ "Extra Fusion Den", colors.pink, 22 },
					{ "Fuse two pairs at once.", colors.muted, 18 },
				},
				buttons = {
					UI.button("Get it in the Store", colors.gray, function()
						open("Store")
					end, { Size = UDim2.new(1, 0, 0, 36) }),
				},
			})
		end
		card.LayoutOrder = index
		card.Parent = penGrid
	end
	if not freePen then
		heading(if pens > 1 then "Both Fusion Dens are busy!" else "Your Fusion Den is busy!", 1)
		return
	end

	-- Drop selections that are no longer valid.
	for i = #breedSelection, 1, -1 do
		local freek = state.freeks[breedSelection[i]]
		if not freek or freek.breeding then
			table.remove(breedSelection, i)
		end
	end

	heading("Both Freeks fuse into one hybrid that earns more than both. Some Ultra pairs make a Secret!", 1)

	local selected = {}
	for _, uid in breedSelection do
		selected[uid] = true
	end

	local ready = #breedSelection == 2
	local label = "Pick 2 Freeks (" .. #breedSelection .. "/2)"
	if ready then
		local a, b = state.freeks[breedSelection[1]], state.freeks[breedSelection[2]]
		label = "Fuse "
			.. FreekUtil.displayName(a)
			.. " + "
			.. FreekUtil.displayName(b)
			.. " ("
			.. Format.time(FreekUtil.breedTime(a, b))
			.. ")"

		-- What this pair will make: its name once you've made it before, otherwise ???.
		-- Which Ultra pairs make a Secret stays a surprise.
		local rarity, bothUltra = Breeding.babyRarity(a, b)
		local resultId = Breeding.babySpecies(a, b)
		local result = Freeks.byId[resultId]
		local resultName = if state.discovered[resultId] and result then result.name else "???"
		local parts = {
			"Makes: " .. resultName .. " (" .. rarity .. (if bothUltra then ", or a Secret?!" else "") .. ")",
			Format.money(Breeding.babyIncome(a, b)) .. "/s",
		}
		local odds = Breeding.mutationOdds(a, b)
		for _, option in odds do
			table.insert(parts, math.round(option.chance * 100) .. "% " .. option.id)
		end
		if #odds == 0 then
			table.insert(parts, "no mutations")
		end
		local prediction = heading(table.concat(parts, "  •  "), 2)
		prediction.TextColor3 = Rarities.info[rarity].color
	end
	UI.button(label, if ready then colors.pink else colors.gray, function()
		if #breedSelection == 2 then
			send("StartBreed", breedSelection[1], breedSelection[2])
			table.clear(breedSelection)
		end
	end, { Size = UDim2.new(1, 0, 0, 46), LayoutOrder = 3, Parent = body })

	local grid = UI.grid(140, 190)
	grid.LayoutOrder = 4
	grid.Parent = body
	for i, item in sortedFreeks() do
		local uid, freek = item.uid, item.freek
		local isSelected = selected[uid]
		local card = UI.card({
			species = freek.species,
			mutations = freek.mutations,
			background = if isSelected then Color3.fromRGB(90, 40, 80) else nil,
			border = if isSelected then colors.pink else nil,
			lines = {
				{ FreekUtil.displayName(freek), nameColor(freek), 20 },
				{ FreekUtil.rarityText(freek.species), rarityColor(freek.species), 16 },
				{ if isSelected then "Selected!" else "Tap to pick", colors.muted, 14 },
			},
			onClick = function()
				local index = table.find(breedSelection, uid)
				if index then
					table.remove(breedSelection, index)
				elseif #breedSelection < 2 then
					table.insert(breedSelection, uid)
				else
					breedSelection[2] = uid
				end
				render()
			end,
		})
		card.LayoutOrder = i
		card.Parent = grid
	end
end

function renderers.Book()
	local total, found = 0, 0
	for _, species in Freeks.list do
		total += 1
		if state.discovered[species.id] then
			found += 1
		end
	end
	heading(string.format("You've found %d / %d Freeks", found, total), 1)

	local grid = UI.grid(150, 220)
	grid.LayoutOrder = 2
	grid.Parent = body
	for _, species in Freeks.list do
		local discovery = discoveries[species.id]
		local known = species.price ~= nil or discovery ~= nil
		local credit
		if species.price then
			credit = "Starter Freek"
		elseif discovery then
			credit = "First found by\n" .. discovery.name
		elseif not Seasons.available(species) then
			credit = "Limited: only during the " .. Seasons.list[species.season].name .. " Event"
		else
			credit = "Nobody has found this yet!"
		end
		local card = UI.card({
			species = species.id,
			silhouette = not known,
			border = if state.discovered[species.id] then colors.green else nil,
			lines = {
				{ if known then species.name else "???", if known then colors.text else colors.muted, 22 },
				{ FreekUtil.rarityText(species.id), Rarities.info[species.rarity].color, 16 },
				{ credit, if discovery then colors.orange else colors.muted, 34 },
				{ if state.discovered[species.id] then "You have found this" else "", colors.green, 14 },
			},
		})
		card.LayoutOrder = species.order
		card.Parent = grid
	end

	-- Hybrids this player has made, with whoever made each one first.
	local hybrids = {}
	for id in state.discovered do
		local species = Freeks.byId[id]
		if species and species.hybrid then
			table.insert(hybrids, species)
		end
	end
	table.sort(hybrids, function(a, b)
		return a.name < b.name
	end)
	heading(string.format("Hybrids you've made: %d (every pair makes its own!)", #hybrids), 3)
	local hybridGrid = UI.grid(150, 220)
	hybridGrid.LayoutOrder = 4
	hybridGrid.Parent = body
	for i, species in hybrids do
		local discovery = discoveries[species.id]
		local card = UI.card({
			species = species.id,
			border = colors.green,
			lines = {
				{ species.name, colors.text, 22 },
				{ species.rarity .. " hybrid", Rarities.info[species.rarity].color, 16 },
				{
					if discovery then "First made by\n" .. discovery.name else "",
					colors.orange,
					34,
				},
			},
		})
		card.LayoutOrder = i
		card.Parent = hybridGrid
	end
end

local function tradeStatus(): string
	if not trade then
		return ""
	end
	if trade.countdownEndsAt then
		local left = math.max(0, math.ceil(trade.countdownEndsAt - Workspace:GetServerTimeNow()))
		return "Trading in " .. left .. "..."
	elseif trade.myReady then
		return "Waiting for " .. trade.partner .. " to press Ready..."
	elseif trade.theirReady then
		return trade.partner .. " is ready! Press Ready to accept."
	end
	return "Add Freeks, then both press Ready."
end

local function tradeCard(item, footer: string, onClick)
	return UI.card({
		species = item.species,
		mutations = item.mutations,
		lines = {
			{ FreekUtil.displayName(item), nameColor(item), 18 },
			{ Format.money(FreekUtil.income(item)) .. "/s", colors.money, 14 },
			{ footer, colors.muted, 14 },
		},
		onClick = onClick,
	})
end

function renderers.Trade()
	if not trade then
		heading("Trade Freeks with other players in this server.", 1)
		local grid = UI.grid(200, 100)
		grid.LayoutOrder = 2
		grid.Parent = body
		local anyone = false
		for _, other in Players:GetPlayers() do
			if other ~= player then
				anyone = true
				UI.card({
					lines = { { other.DisplayName, colors.text, 24 } },
					buttons = {
						UI.button("Send trade request", colors.blue, function()
							send("TradeRequest", other.UserId)
						end, { Size = UDim2.new(1, 0, 0, 36) }),
					},
				}).Parent =
					grid
			end
		end
		if not anyone then
			heading("Nobody else is here yet!", 3)
		end
		return
	end

	heading("Trading with " .. trade.partner, 1)

	local offered = {}
	for _, item in trade.mine do
		offered[item.uid] = true
	end

	local columns = UI.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = body,
	}, {
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local function column(title: string, color: Color3, ready: boolean, order: number)
		local frame = UI.new("Frame", {
			BackgroundColor3 = Color3.fromRGB(30, 26, 46),
			Size = UDim2.new(0.5, -5, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = order,
			Parent = columns,
		}, {
			UI.corner(12),
			if ready then UI.stroke(colors.green, 2.5) else UI.stroke(),
			UI.new("UIPadding", {
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
			}),
			UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		UI.label(title .. (if ready then "  READY" else ""), {
			TextColor3 = color,
			Size = UDim2.new(1, 0, 0, 24),
			LayoutOrder = 1,
			Parent = frame,
		})
		local grid = UI.grid(120, 165)
		grid.LayoutOrder = 2
		grid.Parent = frame
		return grid
	end

	local giveGrid = column("You give", colors.orange, trade.myReady, 1)
	for i, item in trade.mine do
		local card = tradeCard(item, "Tap to remove", function()
			send("TradeOffer", item.uid, false)
		end)
		card.LayoutOrder = i
		card.Parent = giveGrid
	end
	local getGrid = column("You get", colors.money, trade.theirReady, 2)
	for i, item in trade.theirs do
		local card = tradeCard(item, "", nil)
		card.LayoutOrder = i
		card.Parent = getGrid
	end

	tradeStatusLabel = UI.label(tradeStatus(), { Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 3, Parent = body })

	local buttons = UI.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 46),
		LayoutOrder = 4,
		Parent = body,
	}, {
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	UI.button(
		if trade.myReady then "Not ready" else "Ready",
		if trade.myReady then colors.gray else colors.green,
		function()
			if trade then
				send("TradeReady", not trade.myReady)
			end
		end,
		{ Size = UDim2.new(0.5, -5, 1, 0), LayoutOrder = 1, Parent = buttons }
	)
	UI.button("Cancel trade", colors.red, function()
		send("TradeCancel")
	end, { Size = UDim2.new(0.5, -5, 1, 0), LayoutOrder = 2, Parent = buttons })

	heading("Tap your Freeks to offer them", 5)
	local mine = UI.grid(120, 165)
	mine.LayoutOrder = 6
	mine.Parent = body
	for i, item in sortedFreeks() do
		if not offered[item.uid] and not item.freek.breeding then
			local card = tradeCard(item.freek, "Tap to offer", function()
				send("TradeOffer", item.uid, true)
			end)
			card.LayoutOrder = i
			card.Parent = mine
		end
	end
end

-- Incoming trade request popup.
local requestPopup = UI.new("Frame", {
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 90),
	Size = UDim2.fromOffset(320, 110),
	BackgroundColor3 = colors.panel,
	ZIndex = 10,
	Parent = screen,
}, {
	UI.corner(18),
	UI.stroke(colors.blue, 2),
})
local requestLabel = UI.label("", {
	Size = UDim2.new(1, -20, 0, 40),
	Position = UDim2.fromOffset(10, 8),
	ZIndex = 10,
	Parent = requestPopup,
})
local pendingRequest = nil
local function answerRequest(accept: boolean)
	if pendingRequest then
		send("TradeRespond", pendingRequest.userId, accept)
	end
	pendingRequest = nil
	requestPopup.Visible = false
end
UI.button("Accept", colors.green, function()
	answerRequest(true)
end, {
	Size = UDim2.new(0.5, -15, 0, 42),
	Position = UDim2.new(0, 10, 1, -52),
	ZIndex = 10,
	Parent = requestPopup,
})
UI.button("Decline", colors.red, function()
	answerRequest(false)
end, {
	Size = UDim2.new(0.5, -15, 0, 42),
	Position = UDim2.new(0.5, 5, 1, -52),
	ZIndex = 10,
	Parent = requestPopup,
})

function renderers.Rebirth()
	local rebirths = state.rebirths or 0
	local cost = Config.rebirthCost(rebirths)
	local nextMult = Config.incomeMultiplier(rebirths + 1)
	heading(
		string.format("Rebirth %d  ·  Your Freeks earn x%s", rebirths, tostring(Config.incomeMultiplier(rebirths))),
		1
	)

	local unlocks = {}
	for _, weaponId in Weapons.order do
		if Weapons.list[weaponId].rebirth == rebirths + 1 then
			table.insert(unlocks, Weapons.list[weaponId].name)
		end
	end

	local gateNow = GateTiers.list[GateTiers.forRebirths(rebirths)]
	local gateNext = GateTiers.list[GateTiers.forRebirths(rebirths + 1)]
	local gateLine = if gateNext ~= gateNow
		then "Gate upgrade: " .. gateNow.name .. " → " .. gateNext.name
		else "Your gate: " .. gateNow.name .. " (max)"

	local grid = UI.grid(440, 290)
	grid.LayoutOrder = 2
	grid.Parent = body
	local ready = state.money >= cost
	UI.card({
		lines = {
			{ "Rebirth " .. (rebirths + 1), Color3.fromRGB(255, 210, 80), 30 },
			{ "Your Freeks earn x" .. tostring(nextMult) .. " forever", colors.money, 22 },
			{ if #unlocks > 0 then "Unlocks: " .. table.concat(unlocks, ", ") else "", colors.orange, 20 },
			{ gateLine, colors.gold, 18 },
			{ "Resets: coins, Freeks, barn slots", colors.red:Lerp(Color3.new(1, 1, 1), 0.3), 18 },
			{ "Keeps: Discovery Book, Limited Freeks, weapons", colors.muted, 18 },
			{
				Format.money(state.money) .. " / " .. Format.money(cost),
				if ready then colors.money else colors.text,
				22,
			},
		},
		buttons = {
			if ready
				then confirmButton("Rebirth for " .. Format.money(cost), Color3.fromRGB(230, 180, 40), function()
					send("Rebirth")
				end)
				else UI.button("Need " .. Format.money(cost), colors.gray, function() end),
		},
	}).Parent =
		grid

	heading("Weapon unlocks", 3)
	local milestones = UI.grid(200, 80)
	milestones.LayoutOrder = 4
	milestones.Parent = body
	for i, weaponId in Weapons.order do
		local weapon = Weapons.list[weaponId]
		local at = weapon.rebirth or 0
		local card = UI.card({
			lines = {
				{ weapon.name, weapon.color:Lerp(Color3.new(1, 1, 1), 0.3), 22 },
				{
					if at == 0 then "Free" elseif rebirths >= at then "Unlocked" else "Rebirth " .. at,
					if rebirths >= at then colors.money else colors.muted,
					18,
				},
			},
		})
		card.LayoutOrder = i
		card.Parent = milestones
	end
end

function renderers.Store()
	heading("Game passes are one-time purchases. Their perks last forever.", 1)
	local grid = UI.grid(250, 230)
	grid.LayoutOrder = 2
	grid.Parent = body
	for i, key in GamePasses.order do
		local pass = GamePasses.list[key]
		local owned = GamePasses.has(player, key)
		local label, color
		if owned then
			label, color = "Owned ✓", colors.green
		elseif pass.id == 0 then
			label, color = "Coming soon", colors.gray
		else
			label, color = "R$ " .. pass.price, Color3.fromRGB(40, 180, 90)
		end
		local card = UI.card({
			border = if owned then colors.green else nil,
			lines = {
				{ pass.icon, colors.text, 40 },
				{ pass.name, pass.color, 24 },
				{ pass.description, colors.muted, 50 },
			},
			buttons = {
				UI.button(label, color, function()
					if not owned and pass.id ~= 0 then
						MarketplaceService:PromptGamePassPurchase(player, pass.id)
					end
				end, { Size = UDim2.new(1, 0, 0, 36) }),
			},
		})
		card.LayoutOrder = i
		card.Parent = grid
	end
end

-- Refresh the Store as soon as a purchase goes through.
player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 5) == "Pass_" and currentWindow == "Store" then
		render()
	end
end)

--------------------------------------------------------------------------------
-- Luck: the reveal overlay (crates and the wheel) and the Luck window
--------------------------------------------------------------------------------

local revealing = false

-- A full-screen dimmed overlay with a box in the middle; returns overlay, box, close().
local function overlay()
	local shade = UI.new("TextButton", {
		Name = "Reveal",
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		ZIndex = 50,
		Parent = screen,
	})
	local box = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(360, 420),
		BackgroundTransparency = 1,
		ZIndex = 51,
		Parent = shade,
	})
	return shade, box
end

-- The prize card: the Freek, its name and rarity, and a button to close.
local function prizeCard(box: Frame, title: string, freek, color: Color3, subtitle: string, close: () -> ())
	local card = UI.glass({
		Size = UDim2.fromScale(1, 1),
		ZIndex = 52,
		Parent = box,
	}, {
		UI.corner(18),
		UI.stroke(color, 3),
		UI.new("UIPadding", {
			PaddingTop = UDim.new(0, 14),
			PaddingBottom = UDim.new(0, 14),
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
		}),
		UI.new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),
	})
	local lines = { { title, colors.gold, 26 } }
	local order = 0
	local function add(child)
		order += 1
		child.LayoutOrder = order
		child.ZIndex = 53
		child.Parent = card
	end
	for _, line in lines do
		add(UI.label(line[1], { TextColor3 = line[2], Size = UDim2.new(1, 0, 0, line[3]) }))
	end
	if freek then
		local view = UI.viewport(freek.species, freek.mutations)
		view.Size = UDim2.new(1, 0, 0, 200)
		add(view)
		add(UI.label(FreekUtil.displayName(freek), { TextColor3 = color, Size = UDim2.new(1, 0, 0, 30) }))
	end
	add(UI.label(subtitle, { TextColor3 = colors.muted, Size = UDim2.new(1, 0, 0, 40), TextWrapped = true }))
	add(UI.button("Awesome!", colors.green, close, { Size = UDim2.new(1, 0, 0, 44) }))
	-- Pop in.
	local scale = UI.new("UIScale", { Scale = 0.3, Parent = card })
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
end

local function freekPrize(box: Frame, freek, rarity: string, isNew: boolean, close)
	local color = Rarities.info[rarity].color
	local subtitle = rarity .. (if isNew then "  ·  NEW FREEK!" else "") .. "\nIt's in your barn."
	prizeCard(box, if isNew then "NEW FREEK!" else "You got...", freek, color, subtitle, close)
end

-- A crate that shakes harder and harder, flashes, then shows what was inside.
local function revealCrate(result, done)
	local crate = Luck.crateById[result.crate]
	local shade, box = overlay()
	local function close()
		shade:Destroy()
		done()
	end
	local crateBox = UI.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(170, 170),
		BackgroundColor3 = crate.color,
		Text = "?",
		TextSize = 90,
		FontFace = UI.fonts.heavy,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 52,
		Parent = box,
	}, { UI.corner(22), UI.stroke(Color3.new(1, 1, 1), 4) })
	local insideColor = Rarities.info[result.rarity].color
	task.spawn(function()
		for i = 1, 14 do
			local strength = 4 + i * 1.6
			crateBox.Rotation = if i % 2 == 0 then strength else -strength
			crateBox.Size = UDim2.fromOffset(170 + i * 4, 170 + i * 4)
			-- Glow in the colour of what's inside for the last few shakes.
			if i > 9 then
				crateBox.BackgroundColor3 = crate.color:Lerp(insideColor, (i - 9) / 5)
			end
			task.wait(0.11)
		end
		local flash = UI.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 60,
			Parent = shade,
		})
		TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		task.delay(0.5, flash.Destroy, flash)
		crateBox:Destroy()
		freekPrize(box, result.freek, result.rarity, result.isNew, close)
	end)
end

-- The Lucky Wheel spins and lands on the prize the server rolled.
local function buildWheel(parent: Instance, radius: number)
	local wheel = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(radius * 2, radius * 2),
		BackgroundColor3 = Color3.fromRGB(30, 25, 45),
		ZIndex = 52,
		Parent = parent,
	}, { UI.corner(radius), UI.stroke(colors.gold, 5) })
	local count = #Luck.WHEEL
	for i, slice in Luck.WHEEL do
		local angle = math.rad((i - 1) * 360 / count)
		local petal = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(
				radius + math.sin(angle) * radius * 0.5,
				radius - math.cos(angle) * radius * 0.5
			),
			Size = UDim2.fromOffset(radius * 0.62, radius * 0.92),
			Rotation = math.deg(angle),
			BackgroundColor3 = slice.color,
			ZIndex = 53,
			Parent = wheel,
		}, { UI.corner(math.floor(radius * 0.2)) })
		UI.label(slice.label .. "\n" .. string.format("%.0f%%", Luck.wheelPercent(i)), {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 8),
			Size = UDim2.new(1, -6, 0, 40),
			TextColor3 = Color3.fromRGB(25, 20, 35),
			TextSize = 13,
			TextWrapped = true,
			ZIndex = 54,
			Parent = petal,
		})
	end
	UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(radius * 0.4, radius * 0.4),
		BackgroundColor3 = colors.gold,
		ZIndex = 55,
		Parent = wheel,
	}, { UI.corner(radius), UI.stroke(Color3.new(1, 1, 1), 3) })
	return wheel
end

local function revealWheel(result, done)
	local shade, box = overlay()
	local function close()
		shade:Destroy()
		done()
	end
	box.Size = UDim2.fromOffset(380, 420)
	local wheel = buildWheel(box, 165)
	UI.label("▼", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, -205),
		Size = UDim2.fromOffset(60, 50),
		TextSize = 46,
		TextColor3 = colors.gold,
		ZIndex = 60,
		Parent = box,
	})
	local count = #Luck.WHEEL
	local target = -((result.slice - 1) * 360 / count) - 360 * 6 + (math.random() - 0.5) * (300 / count)
	local spinTween = TweenService:Create(
		wheel,
		TweenInfo.new(4.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Rotation = target }
	)
	spinTween:Play()
	spinTween.Completed:Connect(function()
		task.wait(0.6)
		wheel.Parent = nil
		local slice = Luck.WHEEL[result.slice]
		if result.freek then
			freekPrize(box, result.freek, result.rarity, result.isNew, close)
		elseif result.crate then
			prizeCard(
				box,
				if slice.crate == "Diamond" then "JACKPOT!" else "You won!",
				nil,
				slice.color,
				"A " .. Luck.crateById[result.crate].name .. "!\nOpen it from the 🍀 Luck tab.",
				close
			)
		else
			prizeCard(box, "You won!", nil, colors.money, "+" .. Format.money(result.coins or 0) .. " coins!", close)
		end
	end)
end

-- Reveals queue up so two never overlap.
local revealQueue = {}
local function nextReveal()
	if revealing or #revealQueue == 0 then
		return
	end
	revealing = true
	local result = table.remove(revealQueue, 1)
	local function done()
		revealing = false
		nextReveal()
	end
	if result.kind == "wheel" then
		revealWheel(result, done)
	else
		revealCrate(result, done)
	end
end
Remotes.get("LuckResult").OnClientEvent:Connect(function(result)
	table.insert(revealQueue, result)
	nextReveal()
end)

local function spinCooldown(): number
	return if GamePasses.has(player, "VIP") then Luck.VIP_SPIN_COOLDOWN else Luck.SPIN_COOLDOWN
end

function renderers.Luck()
	heading("Crates always give a Freek, and every chance is shown. Spin the wheel free every day!", 1)

	-- The Lucky Wheel.
	local left = (state.lastSpin or 0) + spinCooldown() - Workspace:GetServerTimeNow()
	local ready = left <= 0
	local prizes = {}
	for i, slice in Luck.WHEEL do
		table.insert(prizes, string.format("%s %.0f%%", slice.label, Luck.wheelPercent(i)))
	end
	local wheelCard = UI.card({
		lines = {
			{ "🎡 Lucky Wheel", colors.gold, 28 },
			{ table.concat(prizes, "  ·  "), colors.muted, 40 },
		},
		buttons = {
			UI.button(
				if ready then "SPIN! (free)" else "Next spin in " .. Format.time(left),
				if ready then colors.green else colors.gray,
				function()
					if ready then
						send("SpinWheel")
					end
				end,
				{ Size = UDim2.new(1, 0, 0, 44) }
			),
		},
	})
	wheelCard.Size = UDim2.new(1, 0, 0, 150)
	wheelCard.LayoutOrder = 2
	wheelCard.Parent = body

	-- Lucky Crates.
	local event = Luck.current()
	local grid = UI.grid(230, 330)
	grid.LayoutOrder = 3
	grid.Parent = body
	for i, crate in Luck.CRATES do
		local lines = {
			{ "📦", colors.text, 40 },
			{ crate.name, crate.color, 24 },
		}
		for _, odds in Luck.oddsList(crate) do
			table.insert(lines, {
				string.format(
					"%s  %s%%",
					odds.rarity,
					if odds.percent < 1
						then string.format("%.1f", odds.percent)
						else string.format("%.0f", odds.percent)
				),
				Rarities.info[odds.rarity].color,
				16,
			})
		end
		local price = Luck.cratePrice(crate)
		local buttons = {
			UI.button(
				"Buy & Open " .. Format.money(price) .. (if event and event.crateDiscount then " (sale!)" else ""),
				if state.money >= price then crate.color:Lerp(colors.green, 0.6) else colors.gray,
				function()
					send("BuyCrate", crate.id)
				end,
				{ Size = UDim2.new(1, 0, 0, 36) }
			),
		}
		local owned = state.crates and state.crates[crate.id] or 0
		if owned > 0 then
			table.insert(
				buttons,
				UI.button("Open yours (" .. owned .. ")", colors.pink, function()
					send("OpenCrate", crate.id)
				end, { Size = UDim2.new(1, 0, 0, 36) })
			)
		end
		local card = UI.card({ lines = lines, buttons = buttons, border = crate.color })
		card.LayoutOrder = i
		card.Parent = grid
	end
end

local MENU = {
	{ "Shop", "🛒", colors.green },
	{ "Luck", "🍀", Color3.fromRGB(90, 220, 120) },
	{ "Freeks", "🐷", colors.blue },
	{ "Fuse", "🧪", colors.pink },
	{ "Book", "📖", colors.orange },
	{ "Trade", "🤝", colors.purple },
	{ "Rebirth", "⭐", Color3.fromRGB(230, 170, 30) },
	{ "Store", "💎", Color3.fromRGB(40, 180, 160) },
}
for _, entry in MENU do
	TAB_ICONS[entry[1]] = entry[2]
end
setActiveTab = Hud.menu(screen, MENU, open)

--------------------------------------------------------------------------------
-- Live updates
--------------------------------------------------------------------------------

player:GetAttributeChangedSignal("Money"):Connect(function()
	if state then
		state.money = player:GetAttribute("Money") or state.money
	end
end)

Remotes.get("Notify").OnClientEvent:Connect(toast)

Remotes.get("State").OnClientEvent:Connect(function(newState)
	state = newState
	setRebirthBoost(state.rebirths or 0)
	render()
end)

Remotes.get("DiscoveryUpdate").OnClientEvent:Connect(function(speciesId, discovery)
	discoveries[speciesId] = discovery
	if currentWindow == "Book" then
		render()
	end
end)

Remotes.get("Trade").OnClientEvent:Connect(function(kind, payload)
	if kind == "Request" then
		pendingRequest = payload
		requestLabel.Text = payload.name .. " wants to trade!"
		requestPopup.Visible = true
		task.delay(30, function()
			if pendingRequest == payload then
				pendingRequest = nil
				requestPopup.Visible = false
			end
		end)
	elseif kind == "State" then
		local isNew = trade == nil
		trade = payload
		if isNew and currentWindow ~= "Trade" then
			open("Trade")
		elseif currentWindow == "Trade" then
			render()
		end
	elseif kind == "Closed" then
		trade = nil
		toast(payload, if string.find(payload, "complete") then "success" else "error")
		if currentWindow == "Trade" then
			render()
		end
	end
end)

-- Refresh the player list while the Trade window is open with no trade going.
local function refreshTradeList()
	if currentWindow == "Trade" and not trade then
		render()
	end
end
Players.PlayerAdded:Connect(refreshTradeList)
Players.PlayerRemoving:Connect(function()
	task.defer(refreshTradeList)
end)

-- Trade countdown.
task.spawn(function()
	while true do
		task.wait(0.25)
		if tradeStatusLabel then
			tradeStatusLabel.Text = tradeStatus()
		end
	end
end)

Hud.gateStatus(screen)

-- Nobody needs a Steal prompt on their own Freeks, a Snatch prompt on the Freek they're
-- carrying, or the padlock on someone else's gate.
local function hideOwnPrompt(instance: Instance)
	if not instance:IsA("ProximityPrompt") then
		return
	end
	if
		(instance.Name == "StealPrompt" and instance:GetAttribute("OwnerUserId") == player.UserId)
		or (instance.Name == "SnatchPrompt" and instance:GetAttribute("CarrierUserId") == player.UserId)
	then
		instance.Enabled = false
	elseif instance.Name == "LockPrompt" then
		instance.Enabled = instance:GetAttribute("PlotIndex") == player:GetAttribute("Plot")
	end
end
for _, descendant in Workspace:GetDescendants() do
	hideOwnPrompt(descendant)
end
Workspace.DescendantAdded:Connect(hideOwnPrompt)
player:GetAttributeChangedSignal("Plot"):Connect(function()
	for _, descendant in Workspace:GetDescendants() do
		hideOwnPrompt(descendant)
	end
end)

-- Cannon Freeks only move on clients, so the server can't use Roblox's own prompt range
-- check for them; grabbing goes through an action the server checks itself.
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name == "GrabPrompt" then
		send("GrabDrop", prompt:GetAttribute("ItemId"))
	end
end)

-- Weapons: when an equipped weapon is used, tell the server where we're aiming.
local mouse = player:GetMouse()
local function watchTool(child: Instance)
	if child:IsA("Tool") and child:GetAttribute("WeaponId") and not child:GetAttribute("Hooked") then
		child:SetAttribute("Hooked", true)
		child.Activated:Connect(function()
			send("UseWeapon", child:GetAttribute("WeaponId"), mouse.Hit.Position)
		end)
	end
end
local function watchCharacter(character: Model)
	for _, child in character:GetChildren() do
		watchTool(child)
	end
	character.ChildAdded:Connect(watchTool)
end
player.CharacterAdded:Connect(watchCharacter)
if player.Character then
	watchCharacter(player.Character)
end

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

-- Breed countdowns.
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, pen in penCountdowns do
			local left = pen.endsAt - Workspace:GetServerTimeNow()
			if left > 0 then
				pen.label.Text = "Fusing... " .. Format.time(left)
				pen.button.BackgroundColor3 = colors.gray
				pen.button.Text = "Not ready yet"
			else
				pen.label.Text = "Fusion complete!"
				pen.button.BackgroundColor3 = colors.pink
				pen.button.Text = "Collect!"
			end
		end
	end
end)

-- Cannon Freeks: fly each one out of its cannon, then let it wander the town square and
-- walk into the Freek House, all worked out locally from its seed and launch time (smooth,
-- and matches where the server thinks it is).
local dropFolder = Workspace:WaitForChild("DropFreeks")
local paths = {} -- [Model] = path; cleared when the model goes
dropFolder.ChildRemoved:Connect(function(model)
	paths[model] = nil
end)

-- A puff of smoke that grows and fades (cannon shots and landings).
local function puff(position: Vector3, size: number, color: Color3)
	for i = 1, 5 do
		local ball = Instance.new("Part")
		ball.Shape = Enum.PartType.Ball
		ball.Anchored = true
		ball.CanCollide = false
		ball.CanQuery = false
		ball.CastShadow = false
		ball.Material = Enum.Material.SmoothPlastic
		ball.Color = color
		ball.Transparency = 0.2
		ball.Size = Vector3.one * size * 0.4
		ball.Position = position + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * size
		ball.Parent = Workspace
		local grow = TweenInfo.new(0.6 + i * 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(ball, grow, { Size = Vector3.one * size * 1.4, Transparency = 1 }):Play()
		task.delay(1.2, ball.Destroy, ball)
	end
end

-- How each kind of Freek walks: steps per second (speed, radians), how high it bobs, how
-- much it rocks side to side (roll) and turns from side to side (yaw), and how far its legs
-- swing (degrees). Set per species with `walk` in Freeks.luau.
local WALKS = {
	waddle = { speed = 9, bob = 0.25, roll = 7, yaw = 0, legs = 30 },
	trot = { speed = 12, bob = 0.35, roll = 3, yaw = 0, legs = 35 },
	prowl = { speed = 8, bob = 0.08, roll = 2, yaw = 4, legs = 28 },
	slither = { speed = 9, bob = 0, roll = 0, yaw = 10, legs = 40 },
	stomp = { speed = 6, bob = 0.35, roll = 4, yaw = 0, legs = 25 },
	flap = { speed = 9, bob = 0.5, roll = 8, yaw = 0, legs = 30 },
	bounce = { speed = 7, bob = 1, roll = 6, yaw = 0, legs = 30 },
	strut = { speed = 10, bob = 0.25, roll = 2, yaw = 5, legs = 35 },
	catwalk = { speed = 9, bob = 0.15, roll = 0, yaw = 9, legs = 30 },
}

-- What Freeks stand on: the ground itself (terrain, the town square floor and the
-- walkways), never lamps, trees, players or other Freeks.
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include
local groundList = { Workspace.Terrain }
local scenery = Workspace:WaitForChild("Scenery")
for _, part in scenery:GetDescendants() do
	if part:IsA("BasePart") and (part.Name == "TownSquare" or part.Name == "Walkway" or part.Name == "Curb") then
		table.insert(groundList, part)
	end
end
groundParams.FilterDescendantsInstances = groundList

-- Height of the ground at a spot (nil if there's nothing below).
local function groundAt(position: Vector3): number?
	local hit = Workspace:Raycast(position + Vector3.new(0, 12, 0), Vector3.new(0, -40, 0), groundParams)
	return hit and hit.Position.Y
end

-- The parts of a Freek that swing as it walks, with where they rest relative to the model.
local function swingParts(model: Model)
	local pivot = model:GetPivot()
	local list = {}
	for _, part in model:GetDescendants() do
		local hinge = part:IsA("BasePart") and part:GetAttribute("SwingHinge")
		if typeof(hinge) == "Vector3" then
			table.insert(list, {
				part = part,
				rest = pivot:ToObjectSpace(part.CFrame),
				hinge = hinge,
				phase = part:GetAttribute("SwingPhase") or 0,
				axis = part:GetAttribute("SwingAxis") or "X",
				amount = part:GetAttribute("SwingAmount") or 1,
			})
		end
	end
	return list
end

local function axisRotation(axis: string, angle: number): CFrame
	if axis == "Y" then
		return CFrame.Angles(0, angle, 0)
	elseif axis == "Z" then
		return CFrame.Angles(0, 0, angle)
	end
	return CFrame.Angles(angle, 0, 0)
end

RunService.RenderStepped:Connect(function()
	local now = Workspace:GetServerTimeNow()
	for _, model in dropFolder:GetChildren() do
		if not model:IsA("Model") or not model.PrimaryPart then
			continue -- not streamed in yet
		end
		local path = paths[model]
		if not path then
			local seed, cannon, launch =
				model:GetAttribute("Seed"), model:GetAttribute("Cannon"), model:GetAttribute("Launch")
			if not (seed and cannon and launch) then
				continue
			end
			path = Drops.plan(seed, cannon, launch)
			path.landed = now >= path.land
			path.swing = swingParts(model)
			path.walk = WALKS[model:GetAttribute("Walk")] or WALKS.waddle
			path.offset = (seed % 100) / 10
			paths[model] = path
		end
		local cframe, doing, moving = Drops.cframeAt(path, now)
		local stepAngle = 0
		if doing == "wandering" or doing == "leaving" then
			-- Stand on whatever the ground really is right there.
			local groundY = groundAt(cframe.Position)
			if groundY then
				cframe = cframe + Vector3.new(0, groundY - cframe.Position.Y, 0)
			end
			if not path.landed then
				path.landed = true
				puff(cframe.Position + Vector3.new(0, 1, 0), 3, Color3.fromRGB(225, 210, 180))
			end
			local walk = path.walk
			local t = now + path.offset
			if moving then
				stepAngle = t * walk.speed
				local step = math.sin(stepAngle)
				cframe *= CFrame.new(0, math.abs(step) * walk.bob, 0) * CFrame.Angles(
					0,
					math.rad(step * walk.yaw),
					math.rad(step * walk.roll)
				)
			else
				-- Standing still: just breathing.
				cframe *= CFrame.new(0, (math.sin(t * 2) + 1) * 0.04, 0)
			end
		end
		model:PivotTo(cframe)

		-- Legs, arms, wings and tails swing around their hinges while walking.
		local legs = math.rad(path.walk.legs)
		for _, swing in path.swing do
			local angle = if stepAngle ~= 0
				then math.sin(stepAngle + swing.phase * math.pi * 2) * legs * swing.amount
				else 0
			swing.part.CFrame = cframe
				* CFrame.new(swing.hinge)
				* axisRotation(swing.axis, angle)
				* CFrame.new(-swing.hinge)
				* swing.rest
		end

		local prompt = model:FindFirstChild("GrabPrompt", true)
		if prompt then
			prompt.Enabled = doing == "wandering" or doing == "leaving"
		end
	end
end)

-- Cannons go boom: smoke at the muzzle when the server fires one.
local cannonsFolder = Workspace:WaitForChild("Cannons")
for index = 1, Drops.CANNON_COUNT do
	local cannon = cannonsFolder:WaitForChild("Cannon" .. index)
	cannon:GetAttributeChangedSignal("FiredAt"):Connect(function()
		local wait = (cannon:GetAttribute("FiredAt") or 0) - Workspace:GetServerTimeNow()
		task.delay(math.max(wait, 0), function()
			local muzzle = Drops.muzzle(index)
			puff(muzzle, 6, Color3.fromRGB(200, 200, 205))
			local flash = Instance.new("PointLight")
			flash.Brightness = 6
			flash.Range = 40
			flash.Color = Color3.fromRGB(255, 200, 120)
			flash.Parent = cannon.PrimaryPart
			task.delay(0.15, flash.Destroy, flash)
		end)
	end)
end

-- Yard Freeks gently bob and sway so yards feel alive. Only nearby ones are animated.
-- They always move relative to the "Ground" the server set, so they can't drift upward.
local plotsFolder = Workspace:WaitForChild("Plots")
RunService.RenderStepped:Connect(function()
	local camera = Workspace.CurrentCamera
	local eye = camera and camera.CFrame.Position or Vector3.zero
	local t = os.clock()
	for _, plot in plotsFolder:GetChildren() do
		local freeks = plot:FindFirstChild("Freeks")
		if freeks then
			for _, model in freeks:GetChildren() do
				local ground = model:IsA("Model") and model.PrimaryPart and model:GetAttribute("Ground")
				if typeof(ground) == "CFrame" and (ground.Position - eye).Magnitude < 140 then
					local phase = ground.Position.X * 0.37 + ground.Position.Z * 0.61
					local bob = math.sin(t * 2.2 + phase) * 0.15 + 0.15
					local sway = math.sin(t * 1.3 + phase) * math.rad(5)
					model:PivotTo(ground * CFrame.new(0, bob, 0) * CFrame.Angles(0, sway, 0))
				end
			end
		end
	end
end)

Ambient.start()

-- Rainbow Freeks cycle through colors.
RunService.RenderStepped:Connect(function()
	local color = Color3.fromHSV((os.clock() * 0.25) % 1, 0.75, 1)
	for _, part in CollectionService:GetTagged(FreekModel.RAINBOW_TAG) do
		part.Color = color
	end
end)

task.spawn(function()
	discoveries = Remotes.get("GetDiscoveries"):InvokeServer() or {}
	render()
end)
print("[Fuse a Freek] Client UI built, loading your data...")
state = Remotes.get("GetState"):InvokeServer()
print("[Fuse a Freek] Client ready")
clientReady = true
if state then
	setRebirthBoost(state.rebirths or 0)
end
render()
