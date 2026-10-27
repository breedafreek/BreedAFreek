-- The player's screen: money and Speed, the side menu, and the Shop / Luck / My Life / Bag /
-- Catalog / Rebirth / Store windows. The server is the source of truth; this only shows
-- state and sends requests.

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
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local GamePasses = require(Shared.GamePasses)
local LifeUtil = require(Shared.LifeUtil)
local Luck = require(Shared.Luck)
local Mutations = require(Shared.Mutations)
local Items = require(Shared.Items)
local Parts = require(Shared.Parts)
local Rarities = require(Shared.Rarities)
local Remotes = require(Shared.Remotes)
local AdminPanel = require(script.Parent.AdminPanel)
local Ambient = require(script.Parent.Ambient)
local EventFX = require(script.Parent.EventFX)
local GuardianFX = require(script.Parent.GuardianFX)
local Hud = require(script.Parent.Hud)
local ItemPictures = require(script.Parent.ItemPictures)
local LuckyWheel = require(script.Parent.LuckyWheel)
local PackReveal = require(script.Parent.PackReveal)
local PetFX = require(script.Parent.PetFX)
local TreadmillRun = require(script.Parent.TreadmillRun)
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
	Name = "StealALifeUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

local setRebirthBoost = Hud.money(screen)
Hud.speed(screen)
Hud.eventChip(screen)
Hud.luckChip(screen)
Hud.eventBanner(screen)
AdminPanel.start(screen)
EventFX.start()
Hud.leaderboard(screen)
Hud.vipChatTag()
Hud.zoneBanner(screen)
Hud.carrying(screen)
local toast = Hud.toasts(screen)

-- Which build is running (and anything the server found covering the yards), small in
-- the bottom-left corner.
do
	local label = UI.label("", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 8, 1, -4),
		Size = UDim2.new(0.6, 0, 0, 18),
		TextScaled = false,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(220, 225, 255),
		Parent = screen,
	})
	local function update()
		local problems = ReplicatedStorage:GetAttribute("GroundProblems")
		label.Text = "build " .. Config.BUILD .. (if problems then "  ·  ⚠ " .. problems else "")
	end
	ReplicatedStorage:GetAttributeChangedSignal("GroundProblems"):Connect(update)
	update()
end

-- Windows: a light body under a header bar in the window's own colour, with a slanted
-- title tab in the game's purple-to-pink sticking out over the top-left corner and a red
-- square X (the clean simulator style of Pet Simulator and PLS DONATE).
local window = UI.new("Frame", {
	Name = "Window",
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.53, 0.53),
	Size = UDim2.fromScale(0.66, 0.74),
	BackgroundColor3 = colors.sheet,
	ZIndex = 5, -- above the leaderboard and other HUD pieces
	Parent = screen,
}, {
	UI.corner(22),
	UI.stroke(nil, 4),
	UI.new("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(220, 215, 235)),
		Rotation = 90,
	}),
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(860, 600) }),
})
local header = UI.new("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 58),
	BackgroundColor3 = colors.green,
	ZIndex = 5,
	Parent = window,
}, {
	UI.corner(20),
	UI.new("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 200)),
		Rotation = 90,
	}),
})
-- Square off the header's bottom corners, with a dark line under it.
local headerFill = UI.new("Frame", {
	Position = UDim2.new(0, 0, 1, -20),
	Size = UDim2.new(1, 0, 0, 20),
	BackgroundColor3 = colors.green,
	BorderSizePixel = 0,
	ZIndex = 5,
	Parent = header,
}, {
	UI.new("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(215, 215, 222), Color3.fromRGB(190, 190, 200)),
		Rotation = 90,
	}),
})
UI.new("Frame", {
	Position = UDim2.new(0, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 4),
	BackgroundColor3 = UI.OUTLINE,
	BorderSizePixel = 0,
	ZIndex = 5,
	Parent = header,
})
local titleRibbon = UI.new("Frame", {
	Name = "TitleTab",
	Position = UDim2.fromOffset(18, -22),
	Size = UDim2.fromOffset(0, 58),
	AutomaticSize = Enum.AutomaticSize.X,
	Rotation = -4,
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 6,
	Parent = window,
}, {
	UI.corner(14),
	UI.stroke(nil, 4),
	UI.new("UIGradient", {
		Color = ColorSequence.new(colors.fusion, colors.fusion2),
		Rotation = 0,
	}),
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 22) }),
	UI.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}),
})
local windowTitle = UI.new("TextLabel", {
	Size = UDim2.fromOffset(0, 46),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1,
	FontFace = UI.fonts.heavy,
	TextSize = 36,
	TextColor3 = Color3.new(1, 1, 1),
	ZIndex = 7,
	Parent = titleRibbon,
}, { UI.textStroke(3) })
local function paintHeader(color: Color3)
	header.BackgroundColor3 = color
	headerFill.BackgroundColor3 = color
end
local body = UI.new("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(14, 70),
	Size = UDim2.new(1, -28, 1, -82),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 8,
	Parent = window,
}, {
	UI.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	UI.new("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 8),
	}),
})

--------------------------------------------------------------------------------
-- Windows
--------------------------------------------------------------------------------

local currentWindow = nil
local renderers = {}
local liveTimers = {} -- { { label, endsAt } } counting down on the Nests tab

local function clearBody()
	table.clear(liveTimers)
	for _, child in body:GetChildren() do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
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
local TAB_COLORS = {}

local function open(name: string)
	if currentWindow == name then
		currentWindow = nil
		window.Visible = false
		setActiveTab(nil)
		return
	end
	currentWindow = name
	setActiveTab(name)
	windowTitle.Text = (TAB_ICONS[name] or "") .. " " .. (if name == "Life" then "MY LIFE" else string.upper(name))
	paintHeader(TAB_COLORS[name] or colors.blue)
	window.Visible = true
	body.CanvasPosition = Vector2.zero
	render()
end

UI.button("X", colors.red, function()
	open(currentWindow)
end, {
	AnchorPoint = Vector2.new(1, 0.5),
	Size = UDim2.fromOffset(50, 50),
	Position = UDim2.new(1, 12, 0, 6),
	ZIndex = 7,
	Parent = window,
})

-- A line of text over the cards: short ones are bold section titles, long ones are hints.
local function heading(text: string, order: number, color: Color3?)
	local title = #text <= 28
	return UI.label(text, {
		Size = UDim2.new(1, 0, 0, if title then 32 else 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = if title then UI.fonts.heavy else UI.fonts.bold,
		TextColor3 = color or (if title then Color3.new(1, 1, 1) else colors.muted),
		LayoutOrder = order,
		Parent = body,
	})
end

-- A row of buttons across the window.
local function buttonRow(order: number, buttons: { GuiButton })
	local row = UI.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 48),
		LayoutOrder = order,
		Parent = body,
	}, {
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for i, button in buttons do
		button.Size = UDim2.fromOffset(220, 46)
		button.LayoutOrder = i
		button.Parent = row
	end
	return row
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

-- An item's name, coloured by its mutation (or rarity).
local function partColor(record): Color3
	local top = Mutations.top(record.mutations)
	if top then
		return Mutations.byId[top].color
	end
	return Items.color(record.id)
end

-- A wide glossy banner card (treadmill, Starter Pack, box bundles, VIP): returns the frame.
local function banner(order: number, colorA: Color3, colorB: Color3, height: number)
	local frame = UI.new("Frame", {
		Size = UDim2.new(1, -8, 0, height),
		BackgroundColor3 = Color3.new(1, 1, 1),
		LayoutOrder = order,
		Parent = body,
	}, {
		UI.corner(18),
		UI.stroke(nil, 4),
		UI.new("UIGradient", { Color = ColorSequence.new(colorA, colorB), Rotation = 15 }),
	})
	UI.new("Frame", {
		Position = UDim2.fromOffset(6, 5),
		Size = UDim2.new(1, -12, 0.4, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.8,
		Parent = frame,
	}, { UI.corner(14) })
	return frame
end

local function bannerText(parent: Instance, title: string, lines: string, x: number, color: Color3)
	local titleLabel = UI.label(title, {
		Position = UDim2.fromOffset(x, 12),
		Size = UDim2.new(1, -x - 230, 0, 44),
		FontFace = UI.fonts.heavy,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
	titleLabel.UIStroke.Thickness = 3
	return UI.label(lines, {
		Position = UDim2.fromOffset(x + 2, 58),
		Size = UDim2.new(1, -x - 232, 0, 70),
		TextScaled = false,
		TextSize = 18,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = parent,
	})
end

local function bannerButton(parent: Instance, button: GuiButton)
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -20, 0.5, 6)
	button.Size = UDim2.fromOffset(190, 54)
	button.Parent = parent
	return button
end

-- A row of Mystery Box pictures inside a banner.
local function boxRow(parent: Instance, crateId: string, count: number, x: number, size: number)
	for k = 1, count do
		local view = UI.boxViewport(crateId, size)
		view.Position = UDim2.fromOffset(x + (k - 1) * size * 0.62, 18)
		view.Size = UDim2.fromOffset(size, size)
		view.ZIndex = 3
		view.Parent = parent
	end
end

--------------------------------------------------------------------------------
-- Shop: the treadmill and the zones
--------------------------------------------------------------------------------

local function speedGain(level: number): number
	return Config.treadmillGain(level) * Config.speedMultiplier(state.rebirths) * GamePasses.speedMultiplier(player)
end

-- "Common 70% · Uncommon 25% · Rare 5%"
local function percentText(percent: number): string
	return if percent < 1 then string.format("%.1f%%", percent) else string.format("%.0f%%", percent)
end

function renderers.Shop()
	-- The treadmill, big across the top.
	local level = state.treadmill or 1
	local frame = banner(1, Color3.fromRGB(70, 160, 255), Color3.fromRGB(120, 90, 255), 150)
	local picture = ItemPictures.view("Treadmill", 140)
	picture.Position = UDim2.fromOffset(10, 5)
	picture.Size = UDim2.fromOffset(150, 140)
	picture.Parent = frame
	local maxed = level >= Config.TREADMILL_MAX
	bannerText(
		frame,
		"TREADMILL  LV " .. level,
		"Run on the treadmill in your yard to train ⚡ Speed.\nNow: +"
			.. Format.number(speedGain(level))
			.. " ⚡/s"
			.. (
				if maxed
					then "  (max level!)"
					else "   ➜   Next: +" .. Format.number(speedGain(level + 1)) .. " ⚡/s"
			),
		170,
		Color3.fromRGB(150, 230, 255)
	)
	local cost = Config.treadmillCost(level)
	bannerButton(
		frame,
		if maxed
			then UI.button("MAXED!", colors.gray, function() end)
			else UI.pricePill("UPGRADE " .. Format.money(cost), function()
				send("UpgradeTreadmill")
			end)
	)

	-- The zones, their eggs and the Speed each one needs.
	local speed = player:GetAttribute("Speed") or state.speed or 0
	heading("Zones", 2)
	heading("Grab an egg and outrun the guardian! Train ⚡ Speed to reach the deeper zones.", 3)
	local grid = UI.grid(210, 300)
	grid.LayoutOrder = 4
	grid.Parent = body
	for i, zone in Items.ZONES do
		local kind = Items.KINDS[zone.kind]
		local ready = speed >= zone.speed
		local odds = Items.oddsList(i)
		local best = odds[#odds]
		local card = UI.card({
			egg = i,
			pictureHeight = 100,
			accent = zone.eggColor,
			border = if ready then colors.money else nil,
			lines = {
				{ zone.name, nil, 24 },
				{
					"⚡ " .. (if zone.speed > 0 then Format.number(zone.speed) else "Any") .. " Speed",
					Color3.fromRGB(150, 230, 255),
					20,
				},
				{ kind.icon .. " " .. Items.eggName(i) .. "s", colors.text, 18 },
				{
					"Up to " .. best.rarity .. " (" .. percentText(best.percent) .. ")",
					Rarities.info[best.rarity].color:Lerp(Color3.new(1, 1, 1), 0.3),
					17,
				},
				{
					if ready
						then "✅ You're fast enough!"
						else "🔒 Need " .. Format.number(zone.speed - speed) .. " more",
					if ready then colors.money else Color3.fromRGB(255, 200, 200),
					18,
				},
			},
		})
		card.LayoutOrder = i
		card.Parent = grid
	end
end

--------------------------------------------------------------------------------
-- My Life: the nests, the house, the pets, the yard and the garden
--------------------------------------------------------------------------------

local lifeTab = "Nests"
local LIFE_TABS = {
	{ "Nests", "🥚", Color3.fromRGB(255, 190, 60) },
	{ "House", "🏠", Items.KINDS.House.color },
	{ "Pets", "🐾", Items.KINDS.Pet.color },
	{ "Yard", "🛝", Items.KINDS.Yard.color },
	{ "Garden", "🌷", Items.KINDS.Plant.color },
}
local function tabRow(order: number, tabs, current: string, onPick: (string) -> ())
	local row = UI.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		Parent = body,
	}, {
		UI.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(132, 40),
			CellPadding = UDim2.fromOffset(6, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for i, tab in tabs do
		local button = UI.button(tab[2] .. " " .. tab[1], if tab[1] == current then tab[3] else colors.gray, function()
			onPick(tab[1])
		end)
		button.LayoutOrder = i
		button.Parent = row
	end
end

-- A card for an item that's out, with a TAKE OFF button.
local function placedCard(uid: string, title: string)
	local record = state.parts[uid]
	local info = Items.byId[record.id]
	return UI.card({
		part = record.id,
		mutations = record.mutations,
		pictureHeight = 110,
		lines = {
			{ title, nil, 22 },
			{ LifeUtil.displayName(record), partColor(record):Lerp(Color3.new(1, 1, 1), 0.2), 20 },
			{ Format.money(LifeUtil.itemIncome(record)) .. "/s", colors.money, 20 },
		},
		buttons = {
			UI.button("TAKE OFF", colors.blue, function()
				send("TakeOff", uid)
			end, { Size = UDim2.new(1, 0, 0, 36) }),
		},
		tag = { info.rarity:upper(), Items.color(record.id) },
	})
end

-- An empty spot: hatch more eggs!
local function emptyCard(title: string, hint: string)
	return UI.card({
		accent = Color3.fromRGB(150, 150, 170),
		lines = { { title, nil, 22 }, { hint, colors.muted, 36 } },
		buttons = {
			UI.button("Find eggs!", colors.gray, function()
				open("Shop")
			end, { Size = UDim2.new(1, 0, 0, 36) }),
		},
	})
end

local function nestCards(grid: Instance)
	local count = LifeUtil.nestCount(GamePasses.extraNests(player))
	local now = Items.now()
	for n = 1, Items.NESTS + 2 do
		local egg = state.nests and state.nests[tostring(n)]
		local card
		if n > count then
			card = UI.card({
				picture = "ExtraPen",
				pictureHeight = 100,
				accent = Color3.fromRGB(150, 150, 170),
				lines = { { "Nest " .. n, nil, 22 }, { "🔒 Extra Nests pass", colors.muted, 20 } },
				buttons = {
					UI.button("STORE", colors.pink, function()
						open("Store")
					end, { Size = UDim2.new(1, 0, 0, 36) }),
				},
			})
		elseif not egg then
			card = emptyCard("Nest " .. n, "Empty! Grab an egg in a zone and run it home.")
		else
			local ready = egg.endsAt <= now
			local zone = Items.ZONES[egg.zone]
			local timer = {
				if ready then "🐣 READY!" else "⏱ " .. Format.time(egg.endsAt - now),
				if ready then colors.money else colors.text,
				22,
			}
			card = UI.card({
				egg = egg.zone,
				pictureHeight = 100,
				accent = Rarities.info[egg.rarity].color,
				border = if ready then colors.money else nil,
				lines = {
					{ "Nest " .. n, nil, 22 },
					{
						Items.KINDS[zone.kind].icon
							.. " "
							.. (if egg.size then egg.size .. " " else "")
							.. Items.eggName(egg.zone),
						Items.size(egg.size).color,
						19,
					},
					timer,
				},
				buttons = {
					UI.button("HATCH!", if ready then colors.green else colors.gray, function()
						send("Hatch", n)
					end, { Size = UDim2.new(1, 0, 0, 36) }),
				},
				tag = { egg.rarity:upper(), Rarities.info[egg.rarity].color },
			})
			if not ready then
				-- The third text line is the timer: count it down without re-rendering.
				for _, label in card:GetDescendants() do
					if label:IsA("TextLabel") and string.sub(label.Text, 1, 3) == "⏱" then
						table.insert(liveTimers, { label = label, endsAt = egg.endsAt })
					end
				end
			end
		end
		card.LayoutOrder = n
		card.Parent = grid
	end
end

function renderers.Life()
	local income = LifeUtil.totalIncome(state) * GamePasses.coinMultiplier(player)
	heading("Your life earns " .. Format.money(income) .. "/s", 1, colors.money)
	tabRow(2, LIFE_TABS, lifeTab, function(name)
		lifeTab = name
		render()
	end)
	buttonRow(3, {
		UI.button("⬆ PUT OUT BEST", colors.green, function()
			send("PlaceBest")
		end),
	})
	local grid = UI.grid(200, 280)
	grid.LayoutOrder = 4
	grid.Parent = body
	if lifeTab == "Nests" then
		heading("Eggs grow in your nests. Rarer eggs take longer!", 5)
		nestCards(grid)
	elseif lifeTab == "House" then
		for i, slot in Parts.SLOTS do
			local record, uid = LifeUtil.installedRecord(state, slot.id)
			local card
			if record then
				card = placedCard(uid, slot.icon .. " " .. slot.name)
			else
				local basic = { id = Parts.basic(slot.id) }
				card = UI.card({
					part = basic.id,
					pictureHeight = 110,
					accent = Color3.fromRGB(150, 150, 170),
					lines = {
						{ slot.icon .. " " .. slot.name, nil, 22 },
						{ "Basic", colors.muted, 20 },
						{ Format.money(LifeUtil.itemIncome(basic)) .. "/s", colors.money, 20 },
					},
					buttons = {
						UI.button("Hatch a better one!", colors.gray, function()
							open("Shop")
						end, { Size = UDim2.new(1, 0, 0, 36) }),
					},
				})
			end
			card.LayoutOrder = i
			card.Parent = grid
		end
	elseif lifeTab == "Pets" then
		local pets = LifeUtil.pets(state)
		for n = 1, Items.PET_SLOTS do
			local card = if pets[n]
				then placedCard(pets[n], "🐾 Pet " .. n)
				else emptyCard("🐾 Pet " .. n, "Hatch Wilds Eggs to get pets that roam your yard!")
			card.LayoutOrder = n
			card.Parent = grid
		end
	else
		local where = if lifeTab == "Yard" then state.yard else state.garden
		local count = if lifeTab == "Yard" then Items.YARD_SPOTS else Items.GARDEN_BEDS
		local icon = if lifeTab == "Yard" then "🛝 Spot " else "🌷 Bed "
		for n = 1, count do
			local uid = where and where[tostring(n)]
			local card = if uid and state.parts[uid]
				then placedCard(uid, icon .. n)
				else emptyCard(
					icon .. n,
					if lifeTab == "Yard"
						then "Hatch Yard Sale Eggs for swings, pools and more!"
						else "Hatch Garden Eggs for flowers and trees!"
				)
			card.LayoutOrder = n
			card.Parent = grid
		end
	end
end

--------------------------------------------------------------------------------
-- Bag: items that aren't out
--------------------------------------------------------------------------------

function renderers.Bag()
	local list = LifeUtil.backpack(state)
	heading("🎒 Backpack  " .. #list .. " / " .. GamePasses.backpackSize(player), 1)
	if #list == 0 then
		heading("Empty! Hatched items that aren't better than yours go here.", 2)
		return
	end
	local total = 0
	for _, uid in list do
		total += LifeUtil.sellPrice(state.parts[uid])
	end
	buttonRow(2, {
		UI.button("⬆ PUT OUT BEST", colors.green, function()
			send("PlaceBest")
		end),
		confirmButton("SELL ALL " .. Format.money(total), colors.red, function()
			send("SellBackpack")
		end),
	})
	local grid = UI.grid(200, 300)
	grid.LayoutOrder = 3
	grid.Parent = body
	for i, uid in list do
		local record = state.parts[uid]
		local info = Items.byId[record.id]
		local upgrade = LifeUtil.isUpgrade(state, uid)
		local kind = Items.KINDS[info.kind]
		local card = UI.card({
			part = record.id,
			mutations = record.mutations,
			pictureHeight = 110,
			border = if upgrade then colors.money else nil,
			lines = {
				{ LifeUtil.displayName(record), nil, 22 },
				{
					kind.icon .. " " .. (info.slot or kind.name) .. " · " .. info.rarity,
					partColor(record):Lerp(Color3.new(1, 1, 1), 0.2),
					18,
				},
				{ Format.money(LifeUtil.itemIncome(record)) .. "/s", colors.money, 20 },
				{
					if upgrade then "▲ Upgrade!" else "▼ Yours are better",
					if upgrade then colors.money else Color3.fromRGB(255, 200, 200),
					18,
				},
			},
			buttons = {
				UI.button("PUT OUT", colors.green, function()
					send("Place", uid)
				end, { Size = UDim2.new(1, 0, 0, 34) }),
				confirmButton("SELL " .. Format.money(LifeUtil.sellPrice(record)), colors.red, function()
					send("Sell", uid)
				end),
			},
			tag = if upgrade then { "UP!", colors.green } else nil,
		})
		card.LayoutOrder = i
		card.Parent = grid
	end
end

--------------------------------------------------------------------------------
-- Catalog: every item, kind by kind (house parts style by style)
--------------------------------------------------------------------------------

local catalogKind = "House"
local catalogStyle = "Scrap" -- which house style the Catalog is showing
local CATALOG_TABS = {
	{ "House", "🏠", Items.KINDS.House.color },
	{ "Pet", "🐾", Items.KINDS.Pet.color },
	{ "Yard", "🛝", Items.KINDS.Yard.color },
	{ "Plant", "🌷", Items.KINDS.Plant.color },
}

local function catalogCard(id: string, title: string)
	local info = Items.byId[id]
	local owned = state.discovered[id] == true
	local first = discoveries[id]
	local lines = {
		{ if owned then title else "???", nil, 20 },
		{ info.rarity, Rarities.info[info.rarity].color:Lerp(Color3.new(1, 1, 1), 0.3), 16 },
		{ Format.money(info.income) .. "/s", colors.money, 18 },
	}
	if first then
		table.insert(lines, { "1st: " .. first.name, colors.gold, 16 })
	end
	return UI.card({
		part = id,
		pictureHeight = 90,
		silhouette = not owned,
		accent = if owned then nil else Color3.fromRGB(90, 90, 110),
		lines = lines,
	})
end

function renderers.Catalog()
	local found, total = 0, 0
	for _, item in Items.list do
		if not item.basic then
			total += 1
			if state.discovered[item.id] then
				found += 1
			end
		end
	end
	heading("Found " .. found .. " / " .. total .. " items", 1)
	tabRow(2, CATALOG_TABS, catalogKind, function(name)
		catalogKind = name
		render()
	end)
	if catalogKind == "House" then
		-- Style tabs.
		local tabs = UI.new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 3,
			Parent = body,
		}, {
			UI.new("UIGridLayout", {
				CellSize = UDim2.fromOffset(118, 36),
				CellPadding = UDim2.fromOffset(6, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})
		for i, style in Parts.STYLES do
			if style.id ~= "Basic" then
				local color = Rarities.info[style.rarity].color
				local button = UI.button(style.name, if style.id == catalogStyle then color else colors.gray, function()
					catalogStyle = style.id
					render()
				end)
				button.LayoutOrder = i
				button.Parent = tabs
			end
		end
		local style = Parts.styleById[catalogStyle]
		heading(style.name .. " · " .. style.rarity, 4, Rarities.info[style.rarity].color)
		local grid = UI.grid(150, 220)
		grid.LayoutOrder = 5
		grid.Parent = body
		for i, slot in Parts.SLOTS do
			local card = catalogCard(style.id .. "_" .. slot.id, slot.name)
			card.LayoutOrder = i
			card.Parent = grid
		end
		return
	end
	local grid = UI.grid(150, 220)
	grid.LayoutOrder = 5
	grid.Parent = body
	local order = 0
	for _, item in Items.list do
		if item.kind == catalogKind then
			order += 1
			local card = catalogCard(item.id, item.name)
			card.LayoutOrder = order
			card.Parent = grid
		end
	end
end

--------------------------------------------------------------------------------
-- Rebirth
--------------------------------------------------------------------------------

function renderers.Rebirth()
	local rebirths = state.rebirths or 0
	local cost = Config.rebirthCost(rebirths)
	heading(
		string.format(
			"Rebirth %d  ·  Income x%s  ·  Speed x%s",
			rebirths,
			tostring(Config.incomeMultiplier(rebirths)),
			tostring(Config.speedMultiplier(rebirths))
		),
		1
	)
	local grid = UI.grid(440, 270)
	grid.LayoutOrder = 2
	grid.Parent = body
	local ready = state.money >= cost
	UI.card({
		lines = {
			{ "Rebirth " .. (rebirths + 1), Color3.fromRGB(255, 210, 80), 30 },
			{
				"Everything you own earns x" .. tostring(Config.incomeMultiplier(rebirths + 1)) .. " forever",
				colors.money,
				22,
			},
			{
				"Your treadmill trains x" .. tostring(Config.speedMultiplier(rebirths + 1)) .. " Speed forever",
				Color3.fromRGB(150, 230, 255),
				20,
			},
			{ "Resets: coins, Speed, treadmill level", colors.red:Lerp(Color3.new(1, 1, 1), 0.3), 18 },
			{ "Keeps: your house, pets, yard, garden, eggs, backpack", colors.muted, 18 },
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
end

--------------------------------------------------------------------------------
-- Store
--------------------------------------------------------------------------------

-- What each pass gives, shown as a badge on its card.
local PASS_BADGES = {
	DoubleCoins = "x2",
	FastBreeding = "x2",
	LongerLock = "x2",
	ExtraPen = "+2",
	ExtraSlot1 = "+20",
	ExtraSlot2 = "+20",
	ExtraSlot3 = "+20",
}

-- The price pill (or Owned / Coming soon) for a game pass.
local function passButton(key: string, size: UDim2)
	local pass = GamePasses.list[key]
	local owned = GamePasses.has(player, key)
	local function buy()
		if not owned and pass.id ~= 0 then
			MarketplaceService:PromptGamePassPurchase(player, pass.id)
		end
	end
	if owned then
		return UI.button("OWNED ✓", colors.green, buy, { Size = size })
	elseif pass.id == 0 then
		return UI.button("Coming soon", colors.gray, buy, { Size = size })
	end
	return UI.pricePill("R$ " .. pass.price, buy, { Size = size })
end

-- The Starter Pack banner, with its countdown (only while the offer is open).
local function starterBanner(order: number)
	local ends = player:GetAttribute("StarterEnds")
	if not ends or ends <= Workspace:GetServerTimeNow() or player:GetAttribute("CratesRestricted") then
		return
	end
	local starter = Luck.STARTER
	local frame = banner(order, Color3.fromRGB(70, 225, 120), Color3.fromRGB(30, 160, 200), 150)
	local eggs = 0
	for crateId, count in starter.crates do
		boxRow(frame, crateId, count, 10 + eggs * 70, 110)
		eggs += count
	end
	local x = 10 + eggs * 70 + 60
	local eggWord = {}
	for crateId, count in starter.crates do
		table.insert(eggWord, count .. " " .. Luck.crateById[crateId].name .. if count > 1 then "s" else "")
	end
	local info = bannerText(
		frame,
		"STARTER PACK",
		"💰 " .. Format.money(starter.coins) .. " coins\n📦 " .. table.concat(eggWord, " + ") .. "\n⏰ ",
		x,
		colors.gold
	)
	local pill = UI.pricePill(if starter.passId ~= 0 then "R$ " .. starter.robux else "Coming soon", function()
		send("BuyStarter")
	end)
	bannerButton(frame, pill)
	UI.tag(frame, "LIMITED", colors.red).Position = UDim2.new(1, -16, 0, 8)
	-- Count down live while the window is open.
	local base = info.Text
	task.spawn(function()
		while info.Parent do
			local left = math.max(0, ends - Workspace:GetServerTimeNow())
			info.Text = base
				.. string.format("Only %d:%02d:%02d left!", left // 3600, (left % 3600) // 60, math.floor(left % 60))
			task.wait(1)
		end
	end)
end

-- A Mystery Box bundle banner.
local function bundleBanner(order: number, bundle)
	local crate = Luck.crateById[bundle.crate]
	local frame = banner(order, crate.color, Color3.fromRGB(255, 100, 60), 150)
	boxRow(frame, crate.id, 4, 10, 110)
	local restricted = player:GetAttribute("CratesRestricted")
	bannerText(
		frame,
		string.upper(bundle.name),
		"Save "
			.. Luck.bundleSaving(bundle)
			.. "% on "
			.. crate.name
			.. "es!\nThey wait in the Luck tab to open whenever you like.",
		350,
		Color3.new(1, 1, 1)
	)
	local button
	if restricted then
		button = UI.button("Not available in your region", colors.gray, function() end)
	elseif bundle.productId ~= 0 then
		button = UI.pricePill("R$ " .. bundle.robux, function()
			send("BuyBundle", bundle.id)
		end)
	else
		button = UI.button("Coming soon", colors.gray, function() end)
	end
	bannerButton(frame, button)
	UI.tag(frame, "-" .. Luck.bundleSaving(bundle) .. "%", colors.red).Position = UDim2.new(1, -16, 0, 8)
end

function renderers.Store()
	starterBanner(0)
	-- VIP, big and rainbow across the top (like the VIP banners in PLS DONATE).
	local vipBanner = UI.new("Frame", {
		Size = UDim2.new(1, -8, 0, 150),
		BackgroundColor3 = Color3.new(1, 1, 1),
		LayoutOrder = 1,
		Parent = body,
	}, {
		UI.corner(18),
		UI.stroke(nil, 4),
		UI.new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 120)),
				ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 170, 40)),
				ColorSequenceKeypoint.new(0.6, Color3.fromRGB(190, 90, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 160, 255)),
			}),
			Rotation = 15,
		}),
	})
	UI.new("Frame", {
		Position = UDim2.fromOffset(6, 5),
		Size = UDim2.new(1, -12, 0.4, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.8,
		Parent = vipBanner,
	}, { UI.corner(14) })
	local crown = ItemPictures.view("VIP", 140)
	crown.Position = UDim2.fromOffset(10, 5)
	crown.Size = UDim2.fromOffset(150, 140)
	crown.Parent = vipBanner
	UI.label("VIP", {
		Position = UDim2.fromOffset(170, 14),
		Size = UDim2.new(1, -400, 0, 48),
		FontFace = UI.fonts.heavy,
		TextColor3 = colors.gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = vipBanner,
	}).UIStroke.Thickness =
		3
	UI.label(
		"👑 Gold VIP badge on the leaderboard and in chat\n💰 +10% coins forever\n🎡 Spin the Lucky Wheel more often",
		{
			Position = UDim2.fromOffset(172, 64),
			Size = UDim2.new(1, -400, 0, 72),
			TextScaled = false,
			TextSize = 17,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Parent = vipBanner,
		}
	)
	local vipButton = passButton("VIP", UDim2.fromOffset(200, 52))
	vipButton.AnchorPoint = Vector2.new(1, 0.5)
	vipButton.Position = UDim2.new(1, -20, 0.5, 8)
	vipButton.Parent = vipBanner
	UI.tag(vipBanner, if GamePasses.has(player, "VIP") then "YOURS!" else "BEST!", colors.red).Position =
		UDim2.new(1, -16, 0, 8)

	-- The other passes as bright cards.
	local grid = UI.grid(220, 270)
	grid.LayoutOrder = 2
	grid.Parent = body
	local i = 0
	for _, key in GamePasses.order do
		if key ~= "VIP" then
			i += 1
			local pass = GamePasses.list[key]
			local owned = GamePasses.has(player, key)
			local card = UI.card({
				accent = pass.color,
				border = if owned then colors.money else nil,
				picture = key,
				lines = {
					{ pass.name, nil, 24 },
					{ pass.description, colors.text, 40 },
				},
				buttons = { passButton(key, UDim2.new(1, 0, 0, 40)) },
				tag = PASS_BADGES[key] and { PASS_BADGES[key], UI.OUTLINE },
			})
			card.LayoutOrder = i
			card.Parent = grid
		end
	end

	-- Mystery Box bundles.
	for k, bundle in Luck.BUNDLES do
		bundleBanner(10 + k, bundle)
	end
end

-- Refresh the Store as soon as a purchase goes through.
player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 5) == "Pass_" and currentWindow == "Store" then
		render()
	end
end)

--------------------------------------------------------------------------------
-- Luck: the reveal overlay (boxes and the wheel) and the Luck window
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

-- The prize card: the part, its name and rarity, and a button to close.
local function prizeCard(box: Frame, title: string, part, color: Color3, subtitle: string, close: () -> ())
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
	if part then
		local view = ItemPictures.part(part.id, 200, false, part.mutations)
		view.Size = UDim2.new(1, 0, 0, 200)
		add(view)
		add(UI.label(LifeUtil.displayName(part), { TextColor3 = color, Size = UDim2.new(1, 0, 0, 30) }))
	end
	add(UI.label(subtitle, { TextColor3 = colors.muted, Size = UDim2.new(1, 0, 0, 40), TextWrapped = true }))
	add(UI.button("Awesome!", colors.green, close, { Size = UDim2.new(1, 0, 0, 44) }))
	-- Pop in.
	local scale = UI.new("UIScale", { Scale = 0.3, Parent = card })
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
end

-- Where a new item went, in words.
local WHERE_TEXT = {
	house = "It's on your house!",
	pen = "It's roaming your yard!",
	yard = "It's in your yard!",
	garden = "It's in your garden!",
	backpack = "It's in your backpack.",
}

local function partPrize(box: Frame, part, rarity: string, isNew: boolean, where: string?, close)
	local color = Rarities.info[rarity].color
	local subtitle = rarity
		.. (if isNew then "  ·  NEW!" else "")
		.. "\n"
		.. (WHERE_TEXT[where] or WHERE_TEXT.backpack)
	prizeCard(box, if isNew then "NEW ITEM!" else "You got...", part, color, subtitle, close)
end

-- The Lucky Wheel spins and lands on the prize the server rolled.
local function revealWheel(result, done)
	local shade, box = overlay()
	local function close()
		shade:Destroy()
		done()
	end
	box.Size = UDim2.fromOffset(420, 460)
	local wheel = LuckyWheel.build(box, 400, { hubText = "🎡", zIndex = 52 })
	wheel.spinTo(result.slice, function()
		task.wait(0.7)
		wheel.frame:Destroy()
		box.Size = UDim2.fromOffset(360, 420)
		local slice = Luck.WHEEL[result.slice]
		if result.part then
			partPrize(box, result.part, result.rarity, result.isNew, result.where, close)
		elseif result.crate then
			prizeCard(
				box,
				if slice.crate == "LegendaryMonster" then "JACKPOT!" else "You won!",
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
		return
	end
	-- Boxes open with the full card-pack reveal.
	if currentWindow then
		open(currentWindow)
	end
	PackReveal.play(result, done)
end
Remotes.get("LuckResult").OnClientEvent:Connect(function(result)
	table.insert(revealQueue, result)
	nextReveal()
end)

local function spinCooldown(): number
	return if GamePasses.has(player, "VIP") then Luck.VIP_SPIN_COOLDOWN else Luck.SPIN_COOLDOWN
end

function renderers.Luck()
	-- The Lucky Wheel: a big purple-to-pink card with the wheel and a SPIN button.
	local left = (state.lastSpin or 0) + spinCooldown() - Workspace:GetServerTimeNow()
	local ready = left <= 0
	local function spin()
		if ready then
			send("SpinWheel")
		end
	end
	local wheelCard = UI.new("Frame", {
		Size = UDim2.new(1, -8, 0, 300),
		BackgroundColor3 = Color3.new(1, 1, 1),
		LayoutOrder = 1,
		Parent = body,
	}, {
		UI.corner(18),
		UI.stroke(nil, 4),
		UI.new("UIGradient", {
			Color = ColorSequence.new(colors.fusion, colors.fusion2),
			Rotation = 20,
		}),
	})
	UI.new("Frame", {
		Position = UDim2.fromOffset(6, 5),
		Size = UDim2.new(1, -12, 0.35, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.82,
		Parent = wheelCard,
	}, { UI.corner(14) })
	local wheelHolder = UI.new("Frame", {
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(280, 280),
		BackgroundTransparency = 1,
		Parent = wheelCard,
	})
	LuckyWheel.build(wheelHolder, 280, { hubText = if ready then "SPIN!" else "⏳", onHub = spin })
	UI.label("LUCKY WHEEL", {
		Position = UDim2.fromOffset(310, 22),
		Size = UDim2.new(1, -330, 0, 52),
		FontFace = UI.fonts.heavy,
		TextColor3 = colors.gold,
		Parent = wheelCard,
	}).UIStroke.Thickness =
		3
	UI.label(if ready then "Your free spin is ready!" else "Free spin every day!", {
		Position = UDim2.fromOffset(310, 80),
		Size = UDim2.new(1, -330, 0, 30),
		Parent = wheelCard,
	})
	UI.label("Win coins, Golden and Rainbow parts, Mystery Boxes and the JACKPOT!", {
		Position = UDim2.fromOffset(310, 114),
		Size = UDim2.new(1, -330, 0, 48),
		TextScaled = false,
		TextSize = 17,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(255, 235, 255),
		Parent = wheelCard,
	})
	local spinButton = UI.button(
		if ready then "SPIN!" else "Next spin in " .. Format.time(left),
		if ready then colors.green else colors.gray,
		spin,
		{
			Position = UDim2.fromOffset(330, 190),
			Size = UDim2.new(1, -370, 0, 64),
			Parent = wheelCard,
		}
	)
	if ready then
		UI.tag(spinButton, "FREE", colors.red)
	end

	-- Mystery Boxes (Robux): every chance is shown before buying.
	UI.label("📦 MYSTERY BOXES · a random item of any kind, odds below", {
		Size = UDim2.new(1, 0, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = UI.fonts.heavy,
		LayoutOrder = 2,
		Parent = body,
	})
	local restricted = player:GetAttribute("CratesRestricted")
	local grid = UI.grid(250, 480)
	grid.LayoutOrder = 3
	grid.Parent = body
	for i, crate in Luck.CRATES do
		local odds = Luck.oddsList(crate)
		local lines = { { crate.name, nil, 24 } }
		for _, entry in odds do
			table.insert(lines, {
				entry.rarity .. "  " .. percentText(entry.percent),
				Rarities.info[entry.rarity].color:Lerp(Color3.new(1, 1, 1), 0.35),
				18,
			})
		end
		local buy = function()
			if not restricted then
				send("BuyCrate", crate.id)
			end
		end
		local button
		if restricted then
			button = UI.button("Not available in your region", colors.gray, buy, { Size = UDim2.new(1, 0, 0, 40) })
		elseif crate.productId ~= 0 or (RunService:IsStudio() and Luck.STUDIO_FREE_CRATES) then
			button = UI.pricePill(
				"R$ " .. crate.robux .. (if crate.productId == 0 then " (free in Studio)" else ""),
				buy,
				{ Size = UDim2.new(1, 0, 0, 40) }
			)
		else
			button = UI.button("Coming soon", colors.gray, buy, { Size = UDim2.new(1, 0, 0, 40) })
		end
		local buttons = { button }
		local owned = state.crates and state.crates[crate.id] or 0
		if owned > 0 then
			table.insert(
				buttons,
				UI.button("OPEN YOURS (" .. owned .. ")", colors.green, function()
					send("OpenCrate", crate.id)
				end, { Size = UDim2.new(1, 0, 0, 38) })
			)
		end
		local card = UI.card({
			box = crate.id,
			accent = crate.color,
			lines = lines,
			buttons = buttons,
			tag = if i == #Luck.CRATES then { "BEST", colors.red } else nil,
		})
		card.LayoutOrder = i
		card.Parent = grid
	end
	for k, bundle in Luck.BUNDLES do
		bundleBanner(10 + k, bundle)
	end
end

local MENU = {
	{ "Shop", "🛒", colors.green },
	{ "Luck", "🍀", Color3.fromRGB(160, 215, 45) },
	{ "Life", "🏡", colors.blue },
	{ "Bag", "🎒", colors.orange },
	{ "Catalog", "📖", colors.pink },
	{ "Rebirth", "⭐", Color3.fromRGB(230, 170, 30) },
	{ "Store", "💎", Color3.fromRGB(40, 180, 160) },
	{ "Home", "🚪", colors.purple },
}
for _, entry in MENU do
	TAB_ICONS[entry[1]] = entry[2]
	TAB_COLORS[entry[1]] = entry[3]
end
local setBadge
setActiveTab, setBadge = Hud.menu(screen, MENU, function(name: string)
	if name == "Home" then
		-- Not a window: takes you back to your house.
		send("GoHome")
		return
	end
	open(name)
end)

-- Alert badges on the side buttons: a free spin or unopened boxes, upgrades waiting in the
-- backpack, a treadmill upgrade you can afford, enough coins to rebirth.
task.spawn(function()
	while true do
		if state then
			local now = Workspace:GetServerTimeNow()
			local boxes = 0
			for _, count in state.crates or {} do
				boxes += count
			end
			local spinReady = (state.lastSpin or 0) + spinCooldown() <= now
			setBadge("Luck", if spinReady then "SPIN!" elseif boxes > 0 then tostring(boxes) else nil)
			local upgrades = 0
			for _, uid in LifeUtil.backpack(state) do
				if LifeUtil.isUpgrade(state, uid) then
					upgrades += 1
				end
			end
			setBadge("Bag", if upgrades > 0 then "UP!" else nil, colors.green)
			local ready = 0
			local eggNow = Items.now()
			for _, egg in state.nests or {} do
				if egg.endsAt <= eggNow then
					ready += 1
				end
			end
			setBadge("Life", if ready > 0 then "🐣" .. ready else nil, colors.green)
			-- Nest timers in the open window.
			for _, timer in liveTimers do
				if timer.label.Parent then
					local left = timer.endsAt - eggNow
					timer.label.Text = if left > 0 then "⏱ " .. Format.time(left) else "🐣 READY!"
				end
			end
			local level = state.treadmill or 1
			local canUpgrade = level < Config.TREADMILL_MAX and (state.money or 0) >= Config.treadmillCost(level)
			setBadge("Shop", if canUpgrade then "⚡" else nil, colors.blue)
			local canRebirth = (state.money or 0) >= Config.rebirthCost(state.rebirths or 0)
			setBadge("Rebirth", if canRebirth then "!" else nil, colors.green)
		end
		task.wait(0.5)
	end
end)
Hud.starterOffer(screen, function()
	if currentWindow ~= "Store" then
		open("Store")
	end
end)

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

Remotes.get("DiscoveryUpdate").OnClientEvent:Connect(function(partId, discovery)
	discoveries[partId] = discovery
	if currentWindow == "Catalog" then
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
PetFX.start()
TreadmillRun.start()
Ambient.start()

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

task.spawn(function()
	discoveries = Remotes.get("GetDiscoveries"):InvokeServer() or {}
	render()
end)
print("[Steal a Life] Client UI built, loading your data...")
state = Remotes.get("GetState"):InvokeServer()
print("[Steal a Life] Client ready")
clientReady = true
if state then
	setRebirthBoost(state.rebirths or 0)
end
render()
