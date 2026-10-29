-- The player's client: the screen UI (HUD, side menu and windows, built from UI.luau and
-- Hud.luau), the reveals, the world effects (guardians, attacks, pets,
-- treadmill running, ambience, events, flashing secret eggs) and the bits of gameplay
-- that live on the client. The server is the source of truth; this shows state and sends
-- requests.

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
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
local BoxModel = require(Shared.BoxModel)
local Config = require(Shared.Config)
local EggModel = require(Shared.EggModel)
local Events = require(Shared.Events)
local Format = require(Shared.Format)
local GamePasses = require(Shared.GamePasses)
local Items = require(Shared.Items)
local Lego = require(Shared.Lego)
local LifeUtil = require(Shared.LifeUtil)
local Luck = require(Shared.Luck)
local Mutations = require(Shared.Mutations)
local Parts = require(Shared.Parts)
local Rarities = require(Shared.Rarities)
local Remotes = require(Shared.Remotes)
local Ambient = require(script.Parent.Ambient)
local DayNightFX = require(script.Parent.DayNightFX)
local EventFX = require(script.Parent.EventFX)
local GuardianAttackFX = require(script.Parent.GuardianAttackFX)
local GuardianFX = require(script.Parent.GuardianFX)
local Hud = require(script.Parent.Hud)
local ItemPictures = require(script.Parent.ItemPictures)
local LuckyWheel = require(script.Parent.LuckyWheel)
local PackReveal = require(script.Parent.PackReveal)
local PetFX = require(script.Parent.PetFX)
local TreadmillRun = require(script.Parent.TreadmillRun)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

EventFX.start()

--------------------------------------------------------------------------------
-- Screen UI (UI.luau style): the HUD, the menu buttons and the windows
--------------------------------------------------------------------------------

local colors = UI.colors
local actionRemote = Remotes.get("Action")
local function send(action: string, ...)
	actionRemote:FireServer(action, ...)
end

local state = nil
local discoveries = {}

local screen = UI.new("ScreenGui", {
	Name = "StealALifeUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})
Hud.stats(screen)
Hud.topPill(screen)
local message = Hud.messages(screen)
local setBar = Hud.bar(screen)
Remotes.get("Notify").OnClientEvent:Connect(function(text: string, kind: string?)
	message(text, kind)
end)

-- Every window: name, title, header colour, header icon.
local WINDOWS = {
	Shop = { "SHOP", Color3.fromRGB(80, 200, 40), "🛒" },
	Life = { "MY HOME", colors.blue, "🏡" },
	Bag = { "BAG", colors.orange, "🎒" },
	Index = { "INDEX", Color3.fromRGB(165, 90, 240), "📖" },
	Store = { "STORE", Color3.fromRGB(240, 70, 170), "💎" },
	Luck = { "LUCK", Color3.fromRGB(40, 190, 170), "🍀" },
	Admin = { "ADMIN", colors.red, "🛠️" },
}

-- The one window, reused by every menu button.
local currentWindow = nil
local openWindow
local window, content, setHeader = UI.window({
	Name = "Window",
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.53),
	Size = UDim2.fromScale(0.6, 0.72),
	ZIndex = 5,
	Parent = screen,
}, function()
	openWindow(nil)
end)
UI.new("UISizeConstraint", { MaxSize = Vector2.new(860, 600), Parent = window })
local windowScale = UI.new("UIScale", { Parent = window })
local body = UI.new("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = Color3.new(1, 1, 1),
	ZIndex = 5,
	Parent = content,
}, {
	UI.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	UI.new("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
	}),
})

local renderers = {}
local liveTimers = {} -- { { label, egg } } nest countdowns in the open window
local function render()
	if not currentWindow or not state then
		return
	end
	for _, child in body:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	table.clear(liveTimers)
	renderers[currentWindow]()
end

-- A section title in the window (optionally coloured).
local function section(text: string, order: number, color: Color3?)
	return UI.text(text, 22, {
		Size = UDim2.new(1, 0, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = color or colors.white,
		LayoutOrder = order,
		ZIndex = 6,
		Parent = body,
	})
end

-- A horizontal row of buttons (tabs, actions) in the window.
local function row(order: number, height: number?)
	return UI.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height or 44),
		LayoutOrder = order,
		ZIndex = 6,
		Parent = body,
	}, {
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})
end

local function addButton(parent, order: number, text: string, color: Color3, width: number, onClick)
	local button = UI.button(text, color, onClick, {
		Size = UDim2.fromOffset(width, 40),
		LayoutOrder = order,
		ZIndex = 7,
		Parent = parent,
	})
	button.Label.ZIndex = 8
	return button
end

-- Tabs: the picked one in its colour, the rest gray. tabs = { { id, label, colour } }.
local function tabRow(order: number, tabs, current: string, onPick: (string) -> ())
	local holder = row(order)
	for i, tab in tabs do
		addButton(holder, i, tab[2], if tab[1] == current then tab[3] else colors.gray, tab[4] or 130, function()
			onPick(tab[1])
		end)
	end
	return holder
end

-- A grid of slots in the window.
local function grid(order: number, cellSize: UDim2)
	return UI.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		ZIndex = 6,
		Parent = body,
	}, {
		UI.new("UIGridLayout", {
			CellSize = cellSize,
			CellPadding = UDim2.fromOffset(10, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

-- A button that asks "SURE?" before it does something you can't undo.
local function confirmButton(text: string, color: Color3, onConfirm: () -> ())
	local armed = false
	local button
	button = UI.button(text, color, function()
		if armed then
			onConfirm()
			return
		end
		armed = true
		button.Label.Text = "SURE?"
		task.delay(2.5, function()
			armed = false
			if button.Parent then
				button.Label.Text = text
			end
		end)
	end)
	return button
end

-- A slot: label on top, picture in the middle, coloured lines at the bottom and buttons
-- under them. opts = { label, picture (a ViewportFrame), lines = { { text, colour } },
-- buttons = { GuiButton }, gold, tag = { text, colour } }.
local function slot(parent, order: number, opts)
	local cell = UI.cell({ LayoutOrder = order, ZIndex = 6, Parent = parent }, opts.gold)
	local buttons = opts.buttons or {}
	local lines = opts.lines or {}
	local bottom = 6
	for i = #buttons, 1, -1 do
		local button = buttons[i]
		button.AnchorPoint = Vector2.new(0.5, 1)
		button.Position = UDim2.new(0.5, 0, 1, -bottom - 2)
		button.Size = UDim2.new(1, -16, 0, 38)
		button.ZIndex = 7
		button.Label.ZIndex = 8
		button.Parent = cell
		bottom += 44
	end
	for i = #lines, 1, -1 do
		local line = lines[i]
		UI.text(line[1], line[3] or 18, {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 6, 1, -bottom - 2),
			Size = UDim2.new(1, -12, 0, line[3] or 20),
			TextColor3 = line[2] or colors.white,
			ZIndex = 7,
			Parent = cell,
		})
		bottom += (line[3] or 20) + 2
	end
	UI.text(opts.label, 20, {
		Position = UDim2.fromOffset(6, 8),
		Size = UDim2.new(1, -12, 0, 22),
		ZIndex = 7,
		Parent = cell,
	})
	local picture = opts.picture
	if picture then
		picture.AnchorPoint = Vector2.new(0.5, 0)
		picture.Position = UDim2.new(0.5, 0, 0, 32)
		picture.Size = UDim2.new(1, -16, 1, -32 - bottom - 4)
		picture.ZIndex = 7
		picture.Parent = cell
	end
	if opts.tag then
		local tag = UI.heavy(opts.tag[1], 16, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 4, 0, -6),
			Size = UDim2.fromOffset(58, 24),
			Rotation = 8,
			BackgroundTransparency = 0,
			BackgroundColor3 = opts.tag[2],
			ZIndex = 9,
			Parent = cell,
		}, nil)
		UI.corner(4).Parent = tag
		UI.stroke(2).Parent = tag
	end
	return cell
end

-- A little 3D picture of a Mystery Box.
local function boxPicture(crateId: string): ViewportFrame
	local frame = UI.new("ViewportFrame", {
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(190, 185, 200),
		LightColor = Color3.fromRGB(255, 245, 230),
		LightDirection = Vector3.new(-1, -1, 1),
	})
	local model, height = BoxModel.build(crateId)
	Lego.apply(model)
	model:PivotTo(CFrame.new())
	model.Parent = frame
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	local distance = height * 2
	camera.CFrame =
		CFrame.lookAt(Vector3.new(distance * 0.35, height * 0.8, -distance), Vector3.new(0, height * 0.42, 0))
	camera.Parent = frame
	frame.CurrentCamera = camera
	return frame
end

-- An item's name colour: its mutation, or its rarity.
local function partColor(record): Color3
	local top = Mutations.top(record.mutations)
	if top then
		return Mutations.byId[top].color
	end
	return Items.color(record.id)
end

local function percentText(percent: number): string
	return if percent < 1 then string.format("%.1f%%", percent) else string.format("%.0f%%", percent)
end

local function speedGain(level: number): number
	return Config.treadmillGain(level) * GamePasses.speedMultiplier(player)
end

local function spinCooldown(): number
	return if GamePasses.has(player, "VIP") then Luck.VIP_SPIN_COOLDOWN else Luck.SPIN_COOLDOWN
end

local function spinLeft(): number
	return (state and state.lastSpin or 0) + spinCooldown() - Workspace:GetServerTimeNow()
end

--------------------------------------------------------------------------------
-- Shop: the treadmill, plot and house upgrades, and the zones
--------------------------------------------------------------------------------

-- An upgrade slot: name and level, picture, what you get, and the price to buy.
local function upgradeSlot(parent, order, name, level, maxLevel, pictureKey, value, cost, action)
	local maxed = level >= maxLevel
	local canAfford = not maxed and (state.money or 0) >= cost
	local button = if maxed
		then UI.button("MAX", colors.gray, function() end)
		else UI.button(Format.money(cost), if canAfford then colors.green else colors.gray, function()
			send(action)
		end)
	return slot(parent, order, {
		label = name .. "  Lv " .. level,
		picture = ItemPictures.view(pictureKey),
		lines = { { value, colors.speed, 20 } },
		buttons = { button },
		gold = canAfford,
	})
end

function renderers.Shop()
	section("Upgrades", 1)
	local upgrades = grid(2, UDim2.new(1 / 3, -7, 0, 250))
	local level = state.treadmill or 1
	upgradeSlot(
		upgrades,
		1,
		"Treadmill",
		level,
		Config.TREADMILL_MAX,
		"Treadmill",
		"+" .. Format.number(speedGain(level)) .. " ⚡/s",
		Config.treadmillCost(level),
		"UpgradeTreadmill"
	)
	local plotLevel = state.plotLevel or 1
	local spaces = Config.plotSpaces(plotLevel)
	upgradeSlot(
		upgrades,
		2,
		"Plot",
		plotLevel,
		Config.PLOT_MAX,
		"MenuLife",
		spaces.yard + spaces.garden + spaces.pets .. " spots",
		Config.plotCost(plotLevel),
		"UpgradePlot"
	)
	local houseLevel = state.houseLevel or 1
	upgradeSlot(
		upgrades,
		3,
		"House",
		houseLevel,
		Config.HOUSE_MAX,
		"MenuHouse",
		"Size " .. houseLevel,
		Config.houseCost(houseLevel),
		"UpgradeHouse"
	)

	-- The zones: their egg and the Speed each needs. The deepest one you can do is gold;
	-- GO takes you to its entrance.
	section("Zones", 3)
	local speed = player:GetAttribute("Speed") or state.speed or 0
	local best = 1
	for i, zone in Items.ZONES do
		if speed >= zone.speed then
			best = i
		end
	end
	local zones = grid(4, UDim2.new(1 / 4, -8, 0, 210))
	for i, zone in Items.ZONES do
		local fast = speed >= zone.speed
		slot(zones, i, {
			label = zone.name,
			picture = ItemPictures.egg(i),
			lines = {
				{
					"⚡ " .. (if zone.speed > 0 then Format.number(zone.speed) else "Any"),
					if fast then colors.money else Color3.fromRGB(255, 110, 110),
					20,
				},
			},
			buttons = {
				UI.button(if fast then "GO!" else "🔒", if fast then colors.green else colors.gray, function()
					if fast then
						send("GoZone", i)
						openWindow(nil)
					end
				end),
			},
			gold = i == best,
		})
	end
end

--------------------------------------------------------------------------------
-- My Home: the nests, the house, the pets, the yard and the garden
--------------------------------------------------------------------------------

local lifeTab = "Nests"
local LIFE_TABS = {
	{ "Nests", "🥚 NESTS", Color3.fromRGB(255, 170, 40), 120 },
	{ "House", "🏠 HOUSE", Items.KINDS.House.color, 120 },
	{ "Pets", "🐾 PETS", Items.KINDS.Pet.color, 110 },
	{ "Yard", "🛝 YARD", Items.KINDS.Yard.color, 110 },
	{ "Garden", "🌷 GARDEN", Items.KINDS.Plant.color, 130 },
}

-- An item that's out, with a TAKE OFF button.
local function placedSlot(parent, order: number, uid: string, title: string)
	local record = state.parts[uid]
	local info = Items.byId[record.id]
	return slot(parent, order, {
		label = title,
		picture = ItemPictures.part(record.id, nil, false, record.mutations),
		lines = {
			{ LifeUtil.displayName(record), partColor(record):Lerp(Color3.new(1, 1, 1), 0.2), 18 },
			{ Format.money(LifeUtil.itemIncome(record)) .. "/s", colors.money, 20 },
		},
		buttons = {
			UI.button("TAKE OFF", colors.blue, function()
				send("TakeOff", uid)
			end),
		},
		tag = { info.rarity:upper():sub(1, 6), Items.color(record.id) },
	})
end

-- A locked spot: upgrade in the Shop to open it.
local function lockedSlot(parent, order: number, title: string, hint: string)
	return slot(parent, order, {
		label = title,
		lines = { { "🔒", colors.muted, 40 }, { hint, colors.muted, 18 } },
		buttons = {
			UI.button("UPGRADE", colors.green, function()
				openWindow("Shop")
			end),
		},
	})
end

-- An empty spot.
local function emptySlot(parent, order: number, title: string, hint: string)
	return slot(parent, order, {
		label = title,
		lines = { { "Empty", colors.muted, 26 }, { hint, colors.muted, 18 } },
		buttons = {
			UI.button("FIND EGGS", colors.gray, function()
				openWindow("Shop")
			end),
		},
	})
end

local function nestSlots(parent)
	local count = LifeUtil.nestCount(GamePasses.extraNests(player))
	local now = Items.now()
	for n = 1, Items.NESTS + 2 do
		local egg = state.nests and state.nests[tostring(n)]
		if n > count then
			slot(parent, n, {
				label = "Nest " .. n,
				picture = ItemPictures.view("ExtraPen"),
				lines = { { "🔒 Extra Nests", colors.muted, 18 } },
				buttons = {
					UI.button("STORE", Color3.fromRGB(240, 70, 170), function()
						openWindow("Store")
					end),
				},
			})
		elseif not egg then
			emptySlot(parent, n, "Nest " .. n, "Bring an egg home!")
		else
			local ready = egg.endsAt <= now
			local weight = Items.eggWeightAt(egg, now)
			local cell = slot(parent, n, {
				label = "Nest " .. n,
				picture = ItemPictures.egg(egg.zone, nil, egg.item),
				lines = {
					{ egg.rarity, Rarities.info[egg.rarity].color, 18 },
					{
						if ready then "READY!" else "⏱ " .. Format.time(egg.endsAt - now),
						if ready then colors.money else colors.white,
						20,
					},
					{ Format.weight(weight), Items.weightColor(weight / (egg.baseWeight or weight)), 16 },
				},
				buttons = {
					UI.button("HATCH!", if ready then colors.green else colors.gray, function()
						send("Hatch", n)
					end),
				},
				gold = ready,
			})
			if not ready then
				for _, label in cell:GetChildren() do
					if label:IsA("TextLabel") and string.sub(label.Text, 1, 3) == "⏱" then
						table.insert(liveTimers, { label = label, egg = egg })
					end
				end
			end
		end
	end
end

function renderers.Life()
	local income = LifeUtil.totalIncome(state) * GamePasses.coinMultiplier(player)
	section("Your home earns " .. Format.money(income) .. "/s", 1, colors.money)
	tabRow(2, LIFE_TABS, lifeTab, function(name)
		lifeTab = name
		render()
	end)
	local actions = row(3)
	addButton(actions, 1, "⬆ PUT OUT BEST", colors.green, 220, function()
		send("PlaceBest")
	end)
	local cells = grid(4, UDim2.new(1 / 4, -8, 0, 250))
	if lifeTab == "Nests" then
		nestSlots(cells)
	elseif lifeTab == "House" then
		for i, houseSlot in Parts.SLOTS do
			local record, uid = LifeUtil.installedRecord(state, houseSlot.id)
			local title = houseSlot.icon .. " " .. houseSlot.name
			if not LifeUtil.slotOpen(state, houseSlot.id) then
				lockedSlot(cells, i, title, "House Lv " .. Config.HOUSE_SLOT_LEVEL[houseSlot.id])
			elseif record then
				placedSlot(cells, i, uid, title)
			else
				local basic = { id = Parts.basic(houseSlot.id) }
				slot(cells, i, {
					label = title,
					picture = ItemPictures.part(basic.id),
					lines = {
						{ "Basic", colors.muted, 18 },
						{ Format.money(LifeUtil.itemIncome(basic)) .. "/s", colors.money, 20 },
					},
				})
			end
		end
	elseif lifeTab == "Pets" then
		local pets = LifeUtil.pets(state)
		local room = LifeUtil.spaces(state).pets
		for n = 1, Config.plotSpaces(Config.PLOT_MAX).pets do
			if n > room then
				lockedSlot(cells, n, "🐾 Pet " .. n, "Plot Lv " .. (n - 3))
			elseif pets[n] then
				placedSlot(cells, n, pets[n], "🐾 Pet " .. n)
			else
				emptySlot(cells, n, "🐾 Pet " .. n, "Wilds eggs")
			end
		end
	else
		local yard = lifeTab == "Yard"
		local where = if yard then state.yard else state.garden
		local spaces = LifeUtil.spaces(state)
		local room = if yard then spaces.yard else spaces.garden
		local count = if yard then Items.YARD_SPOTS else Items.GARDEN_BEDS
		local icon = if yard then "🛝 Spot " else "🌷 Bed "
		for n = 1, count do
			local uid = where and where[tostring(n)]
			if n > room then
				lockedSlot(cells, n, icon .. n, "Plot Lv " .. (n - 1))
			elseif uid and state.parts[uid] then
				placedSlot(cells, n, uid, icon .. n)
			else
				emptySlot(cells, n, icon .. n, if yard then "Yard Sale eggs" else "Garden eggs")
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Bag: items that aren't out
--------------------------------------------------------------------------------

function renderers.Bag()
	local list = LifeUtil.backpack(state)
	section("🎒 " .. #list .. " / " .. GamePasses.backpackSize(player), 1)
	if #list == 0 then
		section("Empty! Extra items you hatch go here.", 2, colors.muted)
		return
	end
	local total = 0
	for _, uid in list do
		total += LifeUtil.sellPrice(state.parts[uid])
	end
	local actions = row(2)
	addButton(actions, 1, "⬆ PUT OUT BEST", colors.green, 220, function()
		send("PlaceBest")
	end)
	local sellAll = confirmButton("SELL ALL " .. Format.money(total), colors.red, function()
		send("SellBackpack")
	end)
	sellAll.Size = UDim2.fromOffset(260, 40)
	sellAll.LayoutOrder = 2
	sellAll.ZIndex = 7
	sellAll.Label.ZIndex = 8
	sellAll.Parent = actions
	local cells = grid(3, UDim2.new(1 / 4, -8, 0, 300))
	for i, uid in list do
		local record = state.parts[uid]
		local info = Items.byId[record.id]
		local upgrade = LifeUtil.isUpgrade(state, uid)
		slot(cells, i, {
			label = LifeUtil.displayName(record),
			picture = ItemPictures.part(record.id, nil, false, record.mutations),
			lines = {
				{ info.rarity, partColor(record):Lerp(Color3.new(1, 1, 1), 0.2), 18 },
				{ Format.money(LifeUtil.itemIncome(record)) .. "/s", colors.money, 20 },
			},
			buttons = {
				UI.button("PUT OUT", colors.green, function()
					send("Place", uid)
				end),
				confirmButton("SELL " .. Format.money(LifeUtil.sellPrice(record)), colors.red, function()
					send("Sell", uid)
				end),
			},
			gold = upgrade,
			tag = if upgrade then { "UP!", colors.green } else nil,
		})
	end
end

--------------------------------------------------------------------------------
-- Index: every item, kind by kind (house parts style by style)
--------------------------------------------------------------------------------

local indexKind = "House"
local indexStyle = "Scrap"
local INDEX_TABS = {
	{ "House", "🏠 HOUSE", Items.KINDS.House.color, 120 },
	{ "Pet", "🐾 PETS", Items.KINDS.Pet.color, 110 },
	{ "Yard", "🛝 YARD", Items.KINDS.Yard.color, 110 },
	{ "Plant", "🌷 PLANTS", Items.KINDS.Plant.color, 130 },
}

local function indexSlot(parent, order: number, id: string, title: string)
	local info = Items.byId[id]
	local owned = state.discovered[id] == true
	local first = discoveries[id]
	local lines = {
		{ info.rarity, Rarities.info[info.rarity].color:Lerp(Color3.new(1, 1, 1), 0.3), 16 },
		{ Format.money(info.income) .. "/s", colors.money, 18 },
	}
	if first then
		table.insert(lines, { "1st: " .. first.name, colors.gold, 14 })
	end
	slot(parent, order, {
		label = if owned then title else "???",
		picture = ItemPictures.part(id, nil, not owned),
		lines = lines,
		gold = owned,
	})
end

function renderers.Index()
	local found, total = 0, 0
	for _, item in Items.list do
		if not item.basic then
			total += 1
			if state.discovered[item.id] then
				found += 1
			end
		end
	end
	section("Found " .. found .. " / " .. total, 1, colors.gold)
	tabRow(2, INDEX_TABS, indexKind, function(name)
		indexKind = name
		render()
	end)
	if indexKind == "House" then
		local styles = UI.new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 3,
			ZIndex = 6,
			Parent = body,
		}, {
			UI.new("UIGridLayout", {
				CellSize = UDim2.fromOffset(124, 36),
				CellPadding = UDim2.fromOffset(6, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})
		for i, style in Parts.STYLES do
			if style.id ~= "Basic" then
				local color = Rarities.info[style.rarity].color
				local button = UI.button(style.name, if style.id == indexStyle then color else colors.gray, function()
					indexStyle = style.id
					render()
				end, { LayoutOrder = i, ZIndex = 7, Parent = styles })
				button.Label.ZIndex = 8
			end
		end
		local style = Parts.styleById[indexStyle]
		section(style.name .. " · " .. style.rarity, 4, Rarities.info[style.rarity].color)
		local cells = grid(5, UDim2.new(1 / 5, -8, 0, 200))
		for i, houseSlot in Parts.SLOTS do
			indexSlot(cells, i, style.id .. "_" .. houseSlot.id, houseSlot.name)
		end
		return
	end
	local cells = grid(5, UDim2.new(1 / 5, -8, 0, 200))
	local order = 0
	for _, item in Items.list do
		if item.kind == indexKind then
			order += 1
			indexSlot(cells, order, item.id, item.name)
		end
	end
end

--------------------------------------------------------------------------------
-- Store: game passes, the Starter Pack and Mystery Box bundles
--------------------------------------------------------------------------------

local PASS_BADGES = {
	DoubleCoins = "x2",
	FastBreeding = "x2",
	LongerLock = "x2",
	ExtraPen = "+2",
	ExtraSlot1 = "+20",
	ExtraSlot2 = "+20",
	ExtraSlot3 = "+20",
}

local function passButton(key: string)
	local pass = GamePasses.list[key]
	local owned = GamePasses.has(player, key)
	if owned then
		return UI.button("OWNED", colors.gray, function() end)
	elseif pass.id == 0 then
		return UI.button("SOON", colors.gray, function() end)
	end
	return UI.button("R$ " .. pass.price, colors.green, function()
		MarketplaceService:PromptGamePassPurchase(player, pass.id)
	end)
end

-- A wide offer slot: picture on the left, title and lines, a button on the right.
local function offer(order: number, picture, title: string, titleColor: Color3, lines, button, tag)
	local cell = UI.cell({ Size = UDim2.new(1, 0, 0, 150), LayoutOrder = order, ZIndex = 6, Parent = body }, true)
	if picture then
		picture.Position = UDim2.fromOffset(10, 10)
		picture.Size = UDim2.fromOffset(150, 130)
		picture.ZIndex = 7
		picture.Parent = cell
	end
	UI.heavy(title, 36, {
		Position = UDim2.fromOffset(176, 12),
		Size = UDim2.new(1, -400, 0, 42),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = titleColor,
		ZIndex = 7,
		Parent = cell,
	})
	for i, line in lines do
		UI.text(line, 18, {
			Position = UDim2.fromOffset(178, 34 + i * 24),
			Size = UDim2.new(1, -400, 0, 22),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 7,
			Parent = cell,
		})
	end
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -16, 0.5, 0)
	button.Size = UDim2.fromOffset(200, 54)
	button.ZIndex = 7
	button.Label.ZIndex = 8
	button.Parent = cell
	if tag then
		local label = UI.heavy(tag, 16, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 4, 0, -6),
			Size = UDim2.fromOffset(70, 24),
			Rotation = 8,
			BackgroundTransparency = 0,
			BackgroundColor3 = colors.red,
			ZIndex = 9,
			Parent = cell,
		})
		UI.corner(4).Parent = label
		UI.stroke(2).Parent = label
	end
	return cell
end

local function bundleOffer(order: number, bundle)
	local crate = Luck.crateById[bundle.crate]
	local button
	if player:GetAttribute("CratesRestricted") then
		button = UI.button("NOT AVAILABLE", colors.gray, function() end)
	elseif bundle.productId ~= 0 then
		button = UI.button("R$ " .. bundle.robux, colors.green, function()
			send("BuyBundle", bundle.id)
		end)
	else
		button = UI.button("SOON", colors.gray, function() end)
	end
	offer(
		order,
		boxPicture(crate.id),
		string.upper(bundle.name),
		crate.color,
		{ "Save " .. Luck.bundleSaving(bundle) .. "% on " .. crate.name .. "es", "Odds in the 🍀 Luck window" },
		button,
		"-" .. Luck.bundleSaving(bundle) .. "%"
	)
end

function renderers.Store()
	-- The Starter Pack, while its offer is open.
	local ends = player:GetAttribute("StarterEnds")
	if ends and ends > Workspace:GetServerTimeNow() and not player:GetAttribute("CratesRestricted") then
		local starter = Luck.STARTER
		local boxes = {}
		local firstCrate
		for crateId, count in starter.crates do
			firstCrate = firstCrate or crateId
			table.insert(boxes, count .. " " .. Luck.crateById[crateId].name .. if count > 1 then "es" else "")
		end
		local cell = offer(
			0,
			if firstCrate then boxPicture(firstCrate) else nil,
			"STARTER PACK",
			colors.gold,
			{ "💰 " .. Format.money(starter.coins), "📦 " .. table.concat(boxes, " + "), "" },
			UI.button(if starter.passId ~= 0 then "R$ " .. starter.robux else "SOON", colors.green, function()
				send("BuyStarter")
			end),
			"LIMITED"
		)
		-- Count down live while the window is open.
		local clock
		for _, child in cell:GetChildren() do
			if child:IsA("TextLabel") and child.Text == "" then
				clock = child
			end
		end
		task.spawn(function()
			while clock and clock.Parent do
				local left = math.max(0, ends - Workspace:GetServerTimeNow())
				clock.Text = "⏰ " .. Format.time(left) .. " left!"
				clock.TextColor3 = colors.gold
				task.wait(1)
			end
		end)
	end

	offer(
		1,
		ItemPictures.view("VIP"),
		"VIP",
		colors.gold,
		{ "👑 Gold VIP tag in chat", "💰 +10% coins forever", "🎡 Spin twice as often" },
		passButton("VIP"),
		if GamePasses.has(player, "VIP") then "YOURS!" else "BEST!"
	)

	section("Game Passes", 2)
	local cells = grid(3, UDim2.new(1 / 4, -8, 0, 260))
	local i = 0
	for _, key in GamePasses.order do
		if key ~= "VIP" then
			i += 1
			local pass = GamePasses.list[key]
			slot(cells, i, {
				label = pass.name,
				picture = ItemPictures.view(key),
				lines = { { pass.description, colors.muted, 16 } },
				buttons = { passButton(key) },
				gold = GamePasses.has(player, key),
				tag = PASS_BADGES[key] and { PASS_BADGES[key], pass.color },
			})
		end
	end

	section("Mystery Box Bundles", 4)
	for k, bundle in Luck.BUNDLES do
		bundleOffer(10 + k, bundle)
	end
end

-- Refresh the Store as soon as a purchase goes through.
player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 5) == "Pass_" and currentWindow == "Store" then
		render()
	end
end)

--------------------------------------------------------------------------------
-- Luck: the Lucky Wheel and the Mystery Boxes (odds shown before buying)
--------------------------------------------------------------------------------

function renderers.Luck()
	local left = spinLeft()
	local ready = left <= 0
	local function spin()
		if ready then
			send("SpinWheel")
		end
	end
	local wheelCell = UI.cell({ Size = UDim2.new(1, 0, 0, 300), LayoutOrder = 1, ZIndex = 6, Parent = body }, ready)
	local holder = UI.new("Frame", {
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(280, 280),
		BackgroundTransparency = 1,
		ZIndex = 7,
		Parent = wheelCell,
	})
	LuckyWheel.build(holder, 280, { hubText = if ready then "SPIN!" else "⏳", onHub = spin, zIndex = 7 })
	UI.heavy("LUCKY WHEEL", 44, {
		Position = UDim2.fromOffset(310, 24),
		Size = UDim2.new(1, -330, 0, 50),
		TextColor3 = colors.gold,
		ZIndex = 7,
		Parent = wheelCell,
	})
	UI.text(if ready then "Your free spin is ready!" else "A free spin every day!", 22, {
		Position = UDim2.fromOffset(310, 84),
		Size = UDim2.new(1, -330, 0, 28),
		ZIndex = 7,
		Parent = wheelCell,
	})
	UI.text("Coins · Golden parts · Boxes · JACKPOT", 18, {
		Position = UDim2.fromOffset(310, 118),
		Size = UDim2.new(1, -330, 0, 24),
		TextColor3 = colors.muted,
		ZIndex = 7,
		Parent = wheelCell,
	})
	local spinButton =
		UI.button(if ready then "SPIN!" else Format.time(left), if ready then colors.green else colors.gray, spin, {
			Position = UDim2.fromOffset(330, 190),
			Size = UDim2.new(1, -370, 0, 64),
			ZIndex = 7,
			Parent = wheelCell,
		})
	spinButton.Label.ZIndex = 8

	-- Mystery Boxes (Robux): every chance is shown before buying.
	section("📦 Mystery Boxes · odds", 2)
	local restricted = player:GetAttribute("CratesRestricted")
	local cells = grid(3, UDim2.new(1 / 3, -7, 0, 420))
	for i, crate in Luck.CRATES do
		local lines = {}
		for _, entry in Luck.oddsList(crate) do
			table.insert(lines, {
				entry.rarity .. "  " .. percentText(entry.percent),
				Rarities.info[entry.rarity].color:Lerp(Color3.new(1, 1, 1), 0.35),
				18,
			})
		end
		local button
		if restricted then
			button = UI.button("NOT AVAILABLE", colors.gray, function() end)
		elseif crate.productId ~= 0 or (RunService:IsStudio() and Luck.STUDIO_FREE_CRATES) then
			button = UI.button("R$ " .. crate.robux, colors.green, function()
				send("BuyCrate", crate.id)
			end)
		else
			button = UI.button("SOON", colors.gray, function() end)
		end
		local buttons = { button }
		local owned = state.crates and state.crates[crate.id] or 0
		if owned > 0 then
			table.insert(
				buttons,
				UI.button("OPEN (" .. owned .. ")", colors.orange, function()
					send("OpenCrate", crate.id)
				end)
			)
		end
		slot(cells, i, {
			label = crate.name,
			picture = boxPicture(crate.id),
			lines = lines,
			buttons = buttons,
			gold = owned > 0,
			tag = if i == #Luck.CRATES then { "BEST", colors.red } else nil,
		})
	end
	for k, bundle in Luck.BUNDLES do
		bundleOffer(10 + k, bundle)
	end
end

--------------------------------------------------------------------------------
-- Admin (only for admins: the server sets IsAdmin and checks every command)
--------------------------------------------------------------------------------

local ADMIN_EVENTS = {
	{ id = "GuardianNap", def = Events.BIG.GuardianNap },
	{ id = "BloodMoon", def = Events.WEATHER.BloodMoon },
	{ id = "GoldRush", def = Events.WEATHER.GoldRush },
	{ id = "RainbowRain", def = Events.WEATHER.RainbowRain },
	{ id = "Rainbow", def = Luck.EVENTS.Rainbow },
	{ id = "LuckySkies", def = Luck.EVENTS.LuckySkies },
	{ id = "RapidFire", def = Luck.EVENTS.RapidFire },
	{ id = "CrateLuck", def = Luck.EVENTS.CrateLuck },
}
local admin = {
	event = ADMIN_EVENTS[1].id,
	minutes = 15,
	everywhere = true,
	zone = 1,
	rarity = 0, -- 0 = fill with every rarity
	mutation = 0, -- 0 = none
	status = "Pick an event, or spawn some eggs!",
}

local function adminRun(command: string, args)
	admin.status = "..."
	task.spawn(function()
		local ok, result = pcall(function()
			return Remotes.get("Admin"):InvokeServer(command, args)
		end)
		admin.status = if ok then tostring(result or "Done!") else "Failed: " .. tostring(result)
		if currentWindow == "Admin" then
			render()
		end
	end)
	if currentWindow == "Admin" then
		render()
	end
end

-- A < value > picker.
local function cycler(parent, order: number, width: number, text: string, onStep: (number) -> ())
	addButton(parent, order, "<", colors.blue, 36, function()
		onStep(-1)
		render()
	end)
	local label = UI.text(text, 18, {
		Size = UDim2.fromOffset(width, 40),
		BackgroundTransparency = 0,
		BackgroundColor3 = colors.cell,
		LayoutOrder = order + 1,
		ZIndex = 7,
		Parent = parent,
	})
	UI.corner(6).Parent = label
	UI.stroke(2.5).Parent = label
	addButton(parent, order + 2, ">", colors.blue, 36, function()
		onStep(1)
		render()
	end)
end

function renderers.Admin()
	section(admin.status, 0, colors.gold)

	section("⚡ Start an event", 1)
	local events = grid(2, UDim2.new(0.25, -8, 0, 44))
	for i, entry in ADMIN_EVENTS do
		local picked = entry.id == admin.event
		local button = UI.button(
			entry.def.icon .. " " .. entry.def.name,
			if picked then entry.def.color else colors.gray,
			function()
				admin.event = entry.id
				render()
			end,
			{ LayoutOrder = i, ZIndex = 7, Parent = events }
		)
		button.Label.ZIndex = 8
		if picked then
			button.UIStroke.Color = Color3.new(1, 1, 1)
		end
	end
	local times = row(3)
	for i, value in { 5, 15, 30, 60 } do
		addButton(
			times,
			i,
			value .. " MIN",
			if value == admin.minutes then colors.orange else colors.gray,
			100,
			function()
				admin.minutes = value
				render()
			end
		)
	end
	addButton(
		times,
		10,
		if admin.everywhere then "ALL SERVERS" else "THIS SERVER",
		if admin.everywhere then colors.purple else colors.blue,
		190,
		function()
			admin.everywhere = not admin.everywhere
			render()
		end
	)
	local go = row(4)
	addButton(go, 1, "▶ START", colors.green, 200, function()
		adminRun("event", { id = admin.event, minutes = admin.minutes, everywhere = admin.everywhere })
	end)
	addButton(go, 2, "■ END EVENTS", colors.red, 220, function()
		adminRun("stop", { everywhere = admin.everywhere })
	end)

	section("🥚 Spawn eggs (this server)", 5)
	local spawnRow = row(6)
	local zoneCount = #Items.ZONES
	cycler(spawnRow, 1, 130, Items.ZONES[admin.zone].name, function(step)
		admin.zone = (admin.zone - 1 + step) % zoneCount + 1
	end)
	local rarities = Rarities.order
	cycler(spawnRow, 4, 80, if admin.rarity == 0 then "All" else rarities[admin.rarity], function(step)
		admin.rarity = (admin.rarity + step) % (#rarities + 1)
	end)
	local mutations = Mutations.list
	cycler(spawnRow, 7, 110, if admin.mutation == 0 then "No mutation" else mutations[admin.mutation].id, function(step)
		admin.mutation = (admin.mutation + step) % (#mutations + 1)
	end)
	addButton(spawnRow, 10, "GO!", colors.orange, 70, function()
		adminRun("spawn", {
			zone = admin.zone,
			rarity = if admin.rarity == 0 then nil else rarities[admin.rarity],
			mutation = if admin.mutation == 0 then nil else mutations[admin.mutation].id,
		})
	end)

	section("📣 Announce", 7)
	local announce = row(8)
	local box = UI.new("TextBox", {
		Size = UDim2.new(1, -120, 0, 40),
		BackgroundColor3 = Color3.new(1, 1, 1),
		FontFace = UI.FONT,
		PlaceholderText = "Guardian Nap in 5 minutes!",
		PlaceholderColor3 = Color3.fromRGB(140, 140, 150),
		Text = "",
		TextColor3 = UI.OUTLINE,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		LayoutOrder = 1,
		ZIndex = 7,
		Parent = announce,
	}, { UI.corner(6), UI.stroke(2.5), UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10) }) })
	addButton(announce, 2, "SEND", colors.green, 100, function()
		if box.Text ~= "" then
			adminRun("announce", { text = box.Text, everywhere = admin.everywhere })
		end
	end)

	section("🗓️ Coming up", 9)
	local t = os.time()
	local lines = {}
	for i, upcoming in Events.upcoming(t) do
		if i > 3 then
			break
		end
		local def = Events.BIG[upcoming.id]
		local live = if upcoming.starts <= t then "  LIVE" else ""
		table.insert(lines, def.icon .. " " .. def.name .. "  " .. os.date("%a %I:%M %p", upcoming.starts) .. live)
	end
	local weather = Events.nextWeather(t)
	if weather then
		local def = Events.WEATHER[weather.id]
		table.insert(lines, def.icon .. " " .. def.name .. "  " .. os.date("%I:%M %p", weather.starts))
	end
	UI.text(table.concat(lines, "\n"), 18, {
		Size = UDim2.new(1, 0, 0, 22 * math.max(1, #lines)),
		TextScaled = false,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = colors.muted,
		LayoutOrder = 10,
		ZIndex = 6,
		Parent = body,
	})

	section("💰 Test coins", 11)
	local coins = row(12)
	addButton(coins, 1, "+1M", colors.gold, 140, function()
		adminRun("money", { amount = 1e6 })
	end)
	addButton(coins, 2, "+1B", colors.gold, 140, function()
		adminRun("money", { amount = 1e9 })
	end)
end

--------------------------------------------------------------------------------
-- Opening windows, and the HUD buttons
--------------------------------------------------------------------------------

openWindow = function(name: string?)
	if not name or currentWindow == name then
		currentWindow = nil
		window.Visible = false
		return
	end
	if name == "Admin" and player:GetAttribute("IsAdmin") ~= true then
		return
	end
	currentWindow = name
	local info = WINDOWS[name]
	setHeader(info[3], info[1], info[2])
	if not window.Visible then
		window.Visible = true
		windowScale.Scale = 0.85
		TweenService:Create(windowScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()
	end
	body.CanvasPosition = Vector2.zero
	render()
end

-- Top centre: travel.
local setTopBadge = Hud.buttons(screen, "top", {
	{ "Home", "HOME", colors.orange, Hud.icon("MenuHome", "🏠") },
	{ "Zones", "ZONES", colors.blue, Hud.icon("Egg", "🥚") },
	{ "Spin", "SPIN", Color3.fromRGB(160, 215, 45), Hud.icon("MenuLuck", "🎡") },
}, function(name)
	if name == "Home" then
		send("GoHome")
	elseif name == "Zones" then
		send("GoZone")
	elseif spinLeft() <= 0 then
		send("SpinWheel")
	else
		openWindow("Luck")
	end
end)

-- Left: the menus, and the event timer under them.
local setMenuBadge, _, menuHolder = Hud.buttons(screen, "left", {
	{ "Shop", "SHOP", Color3.fromRGB(80, 200, 40), Hud.icon("MenuShop", "🛒") },
	{ "Life", "MY HOME", colors.blue, Hud.icon("MenuLife", "🏡") },
	{ "Bag", "BAG", colors.orange, Hud.icon("MenuBag", "🎒") },
	{ "Index", "INDEX", Color3.fromRGB(165, 90, 240), Hud.icon("MenuCatalog", "📖") },
}, openWindow)
Hud.eventTimer(menuHolder)
Hud.dayClock(screen)

-- Right: square tiles.
local setTileBadge, tiles = Hud.tiles(screen, {
	{ "Store", Color3.fromRGB(240, 70, 170), Hud.icon("MenuStore", "💎") },
	{ "Luck", Color3.fromRGB(40, 190, 170), Hud.icon("MenuLuck", "🍀") },
	{ "Admin", colors.red, "🛠️" },
}, openWindow)
local function updateAdmin()
	tiles.Admin.Visible = player:GetAttribute("IsAdmin") == true
	if not tiles.Admin.Visible and currentWindow == "Admin" then
		openWindow(nil)
	end
end
player:GetAttributeChangedSignal("IsAdmin"):Connect(updateAdmin)
updateAdmin()

-- Badges, the hatch bar and the nest countdowns, twice a second.
task.spawn(function()
	while true do
		if state then
			local money = state.money or 0
			local level, plotLevel, houseLevel = state.treadmill or 1, state.plotLevel or 1, state.houseLevel or 1
			local canUpgrade = (level < Config.TREADMILL_MAX and money >= Config.treadmillCost(level))
				or (plotLevel < Config.PLOT_MAX and money >= Config.plotCost(plotLevel))
				or (houseLevel < Config.HOUSE_MAX and money >= Config.houseCost(houseLevel))
			setMenuBadge("Shop", if canUpgrade then "!" else nil)

			local eggNow = Items.now()
			local ready, soonest = 0, nil
			for _, egg in state.nests or {} do
				if egg.endsAt <= eggNow then
					ready += 1
				elseif not soonest or egg.endsAt < soonest then
					soonest = egg.endsAt
				end
			end
			setMenuBadge("Life", if ready > 0 then tostring(ready) else nil)
			if ready > 0 then
				setBar("🐣 EGG READY!", colors.money)
			elseif soonest then
				setBar("🐣 " .. Format.time(soonest - eggNow), colors.white)
			else
				setBar(nil)
			end

			local upgrades = 0
			for _, uid in LifeUtil.backpack(state) do
				if LifeUtil.isUpgrade(state, uid) then
					upgrades += 1
				end
			end
			setMenuBadge("Bag", if upgrades > 0 then "UP" else nil)

			local boxes = 0
			for _, count in state.crates or {} do
				boxes += count
			end
			local spinReady = spinLeft() <= 0
			setTopBadge("Spin", if spinReady then "!" else nil)
			setTileBadge("Luck", if boxes > 0 then tostring(boxes) elseif spinReady then "!" else nil)

			for _, timer in liveTimers do
				if timer.label.Parent then
					local left = timer.egg.endsAt - eggNow
					timer.label.Text = if left > 0 then "⏱ " .. Format.time(left) else "READY!"
				end
			end
		end
		task.wait(0.5)
	end
end)

--------------------------------------------------------------------------------
-- Reveals: hatching and boxes play the card-pack reveal; the wheel spins
--------------------------------------------------------------------------------

local WHERE_TEXT = {
	house = "It's on your house!",
	pen = "It's roaming your yard!",
	yard = "It's in your yard!",
	garden = "It's in your garden!",
	backpack = "It's in your bag.",
}

-- A full-screen shade with a window in the middle; returns shade, frame, content, setHeader.
local function prizeWindow(onClose: () -> ())
	local shade = UI.new("TextButton", {
		Name = "Reveal",
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.4,
		ZIndex = 50,
		Parent = screen,
	})
	local frame, inside, header = UI.window({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(380, 440),
		ZIndex = 51,
		Parent = shade,
	}, onClose)
	return shade, frame, inside, header
end

local function prize(title: string, color: Color3, picture, name: string?, subtitle: string, done: () -> ())
	local shade, frame, inside, header
	local function close()
		shade:Destroy()
		done()
	end
	shade, frame, inside, header = prizeWindow(close)
	header("🎉", title, color)
	if picture then
		picture.Position = UDim2.fromOffset(20, 12)
		picture.Size = UDim2.new(1, -40, 0, 210)
		picture.ZIndex = 52
		picture.Parent = inside
	end
	if name then
		UI.heavy(name, 30, {
			Position = UDim2.new(0, 14, 0, 226),
			Size = UDim2.new(1, -28, 0, 34),
			TextColor3 = color,
			ZIndex = 52,
			Parent = inside,
		})
	end
	UI.text(subtitle, 20, {
		Position = UDim2.new(0, 14, 0, 262),
		Size = UDim2.new(1, -28, 0, 48),
		TextWrapped = true,
		ZIndex = 52,
		Parent = inside,
	})
	local button = UI.button("AWESOME!", colors.green, close, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.new(1, -40, 0, 52),
		ZIndex = 52,
		Parent = inside,
	})
	button.Label.ZIndex = 53
	local scale = UI.new("UIScale", { Scale = 0.3, Parent = frame })
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
end

-- The Lucky Wheel spins and lands on the slice the server rolled, then shows the prize.
local function revealWheel(result, done)
	local shade = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.4,
		ZIndex = 50,
		Parent = screen,
	})
	local holder = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(420, 420),
		BackgroundTransparency = 1,
		ZIndex = 51,
		Parent = shade,
	})
	local wheel = LuckyWheel.build(holder, 420, { hubText = "🎡", zIndex = 52 })
	wheel.spinTo(result.slice, function()
		task.wait(0.7)
		shade:Destroy()
		local slice = Luck.WHEEL[result.slice]
		if result.part then
			local color = Rarities.info[result.rarity].color
			prize(
				if result.isNew then "NEW ITEM!" else "YOU WON!",
				color,
				ItemPictures.part(result.part.id, nil, false, result.part.mutations),
				LifeUtil.displayName(result.part),
				result.rarity .. " · " .. (WHERE_TEXT[result.where] or WHERE_TEXT.backpack),
				done
			)
		elseif result.crate then
			prize(
				if slice.crate == "LegendaryMonster" then "JACKPOT!" else "YOU WON!",
				slice.color,
				boxPicture(result.crate),
				Luck.crateById[result.crate].name,
				"Open it in the 🍀 Luck window!",
				done
			)
		else
			prize(
				"YOU WON!",
				colors.money,
				ItemPictures.view("Cash"),
				"+" .. Format.money(result.coins or 0),
				"Coins!",
				done
			)
		end
	end)
end

-- Reveals queue up so two never overlap.
local revealing = false
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
	openWindow(nil)
	if result.kind == "wheel" then
		revealWheel(result, done)
	else
		PackReveal.play(result, done)
	end
end
Remotes.get("LuckResult").OnClientEvent:Connect(function(result)
	table.insert(revealQueue, result)
	nextReveal()
end)

--------------------------------------------------------------------------------
-- Live updates
--------------------------------------------------------------------------------

player:GetAttributeChangedSignal("Money"):Connect(function()
	if state then
		state.money = player:GetAttribute("Money") or state.money
	end
end)

Remotes.get("State").OnClientEvent:Connect(function(newState)
	state = newState
	render()
end)

Remotes.get("DiscoveryUpdate").OnClientEvent:Connect(function(partId, discovery)
	discoveries[partId] = discovery
	if currentWindow == "Index" then
		render()
	end
end)

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

-- The Mystery Boxes on the stand: holding E on one opens the Luck window, where its odds
-- are shown before buying.
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt)
	if prompt.Name == "EggPrompt" and currentWindow ~= "Luck" then
		openWindow("Luck")
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
DayNightFX.start()

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
			glow.Transparency = 0.55 + 0.3 * (1 - flash)
		end
		if light and light:IsA("PointLight") then
			light.Color = color
			light.Brightness = 1.5 + 4 * flash
		end
	end
end)

task.spawn(function()
	discoveries = Remotes.get("GetDiscoveries"):InvokeServer() or {}
end)
state = Remotes.get("GetState"):InvokeServer()
print("[Steal a Life] Client ready")
clientReady = true
