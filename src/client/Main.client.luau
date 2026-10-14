-- The player's screen: money display, menu buttons, and the Shop / Freeks / Breed / Book
-- windows. The server is the source of truth; this only shows state and sends requests.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local FreekModel = require(Shared.FreekModel)
local FreekUtil = require(Shared.FreekUtil)
local Freeks = require(Shared.Freeks)
local Mutations = require(Shared.Mutations)
local Rarities = require(Shared.Rarities)
local Remotes = require(Shared.Remotes)
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
	Name = "BreedAFreekUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

local moneyLabel = UI.label("$0", {
	Size = UDim2.new(1, 0, 0.62, 0),
	TextColor3 = colors.money,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local incomeLabel = UI.label("+$0/s", {
	Size = UDim2.new(1, 0, 0.38, 0),
	Position = UDim2.fromScale(0, 0.62),
	TextColor3 = colors.muted,
	TextXAlignment = Enum.TextXAlignment.Left,
})
UI.new("Frame", {
	Name = "Money",
	BackgroundColor3 = colors.panel,
	BackgroundTransparency = 0.15,
	Position = UDim2.new(0, 12, 0, 12),
	Size = UDim2.fromOffset(190, 64),
	Parent = screen,
}, {
	UI.corner(12),
	UI.stroke(Color3.fromRGB(20, 10, 35), 3),
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }),
	moneyLabel,
	incomeLabel,
})

local menu = UI.new("Frame", {
	Name = "Menu",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 12, 0.5, 0),
	Size = UDim2.fromOffset(96, 4 * 58),
	Parent = screen,
}, {
	UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local window = UI.new("Frame", {
	Name = "Window",
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.55, 0.5),
	Size = UDim2.fromScale(0.72, 0.8),
	BackgroundColor3 = colors.panel,
	Parent = screen,
}, {
	UI.corner(16),
	UI.stroke(Color3.fromRGB(20, 10, 35), 4),
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(880, 620) }),
})
local windowTitle = UI.label("", {
	Size = UDim2.new(1, -60, 0, 40),
	Position = UDim2.fromOffset(16, 8),
	TextXAlignment = Enum.TextXAlignment.Left,
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

local toasts = UI.new("Frame", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
	Size = UDim2.new(0.6, 0, 0, 200),
	Parent = screen,
}, {
	UI.new("UIListLayout", {
		Padding = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local TOAST_COLORS = {
	error = colors.red,
	success = colors.green,
	money = Color3.fromRGB(40, 150, 70),
	discovery = colors.orange,
}

local function toast(message: string, kind: string?)
	local frame = UI.new("Frame", {
		BackgroundColor3 = TOAST_COLORS[kind or ""] or colors.panel,
		Size = UDim2.new(1, 0, 0, if kind == "discovery" then 44 else 34),
		Parent = toasts,
	}, {
		UI.corner(10),
		UI.stroke(Color3.fromRGB(20, 10, 35), 2),
		UI.label(message, { Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4) }),
	})
	task.delay(if kind == "discovery" then 7 else 3.5, function()
		local fade = TweenService:Create(frame, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		frame:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- Windows
--------------------------------------------------------------------------------

local currentWindow = nil
local renderers = {}
local breedSelection = {}
local countdownLabel = nil
local claimButton = nil

local function clearBody()
	for _, child in body:GetChildren() do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
	countdownLabel = nil
	claimButton = nil
end

local function render()
	if not currentWindow or not state then
		return
	end
	clearBody()
	renderers[currentWindow]()
end

local function open(name: string)
	if currentWindow == name then
		currentWindow = nil
		window.Visible = false
		return
	end
	currentWindow = name
	windowTitle.Text = name
	window.Visible = true
	body.CanvasPosition = Vector2.zero
	render()
end

UI.button("X", colors.red, function()
	currentWindow = nil
	window.Visible = false
end, {
	Size = UDim2.fromOffset(40, 40),
	Position = UDim2.new(1, -50, 0, 10),
	Parent = window,
})

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
	if freek.mutation and Mutations.byId[freek.mutation] then
		return Mutations.byId[freek.mutation].color
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
	heading("Starter Freeks", 1)
	local grid = UI.grid(150, 230)
	grid.LayoutOrder = 2
	grid.Parent = body

	for _, species in Freeks.list do
		if species.price then
			local canAfford = state.money >= species.price
			local card = UI.card({
				species = species.id,
				lines = {
					{ species.name, rarityColor(species.id), 22 },
					{ Format.money(species.income) .. "/s", colors.money },
				},
				buttons = {
					UI.button(
						"Buy " .. Format.money(species.price),
						if canAfford then colors.green else colors.gray,
						function()
							send("BuyFreek", species.id)
						end
					),
				},
			})
			card.LayoutOrder = species.order
			card.Parent = grid
		end
	end

	heading("Yard", 3)
	local yard = UI.grid(220, 120)
	yard.LayoutOrder = 4
	yard.Parent = body
	local maxed = state.slots >= Config.MAX_SLOTS
	local price = Config.slotPrice(state.slots)
	UI.card({
		lines = {
			{ "Yard Slots", colors.text, 26 },
			{ state.slots .. " / " .. Config.MAX_SLOTS .. " unlocked", colors.muted },
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
end

function renderers.Freeks()
	local list = sortedFreeks()
	local placed = 0
	for _, item in list do
		if item.freek.slot then
			placed += 1
		end
	end
	heading(string.format("%d Freeks (max %d)  ·  %d / %d in yard", #list, Config.MAX_FREEKS, placed, state.slots), 1)
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
			status, statusColor = "Breeding", colors.pink
		elseif freek.slot then
			status, statusColor = "In yard", colors.money
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
					UI.button("Put in yard", colors.green, function()
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
			mutation = freek.mutation,
			lines = {
				{ FreekUtil.displayName(freek), nameColor(freek), 20 },
				{ Freeks.byId[freek.species].rarity, rarityColor(freek.species), 16 },
				{ Format.money(FreekUtil.income(freek)) .. "/s", colors.money },
				{ status, statusColor, 14 },
			},
			buttons = buttons,
		})
		card.LayoutOrder = i
		card.Parent = grid
	end
end

function renderers.Breed()
	local breeding = state.breeding
	if breeding then
		local a, b = state.freeks[breeding.a], state.freeks[breeding.b]
		heading("Your pen is busy!", 1)
		local pair = UI.grid(150, 160)
		pair.LayoutOrder = 2
		pair.Parent = body
		for _, freek in { a, b } do
			if freek then
				UI.card({
					species = freek.species,
					mutation = freek.mutation,
					lines = { { FreekUtil.displayName(freek), nameColor(freek), 20 } },
				}).Parent =
					pair
			end
		end
		countdownLabel = UI.label("", { Size = UDim2.new(1, 0, 0, 36), LayoutOrder = 3, Parent = body })
		claimButton = UI.button("Collect baby!", colors.pink, function()
			send("ClaimBreed")
		end, { Size = UDim2.new(1, 0, 0, 50), LayoutOrder = 4, Parent = body })
		return
	end

	-- Drop selections that are no longer valid.
	for i = #breedSelection, 1, -1 do
		local freek = state.freeks[breedSelection[i]]
		if not freek or freek.breeding then
			table.remove(breedSelection, i)
		end
	end

	heading("Pick two Freeks to breed. Some pairs make brand new Freeks!", 1)

	local selected = {}
	for _, uid in breedSelection do
		selected[uid] = true
	end

	local ready = #breedSelection == 2
	local label = "Pick 2 Freeks (" .. #breedSelection .. "/2)"
	if ready then
		local a, b = state.freeks[breedSelection[1]], state.freeks[breedSelection[2]]
		label = "Breed "
			.. FreekUtil.displayName(a)
			.. " + "
			.. FreekUtil.displayName(b)
			.. " ("
			.. Format.time(FreekUtil.breedTime(a, b))
			.. ")"
	end
	UI.button(label, if ready then colors.pink else colors.gray, function()
		if #breedSelection == 2 then
			send("StartBreed", breedSelection[1], breedSelection[2])
			table.clear(breedSelection)
		end
	end, { Size = UDim2.new(1, 0, 0, 46), LayoutOrder = 2, Parent = body })

	local grid = UI.grid(140, 190)
	grid.LayoutOrder = 3
	grid.Parent = body
	for i, item in sortedFreeks() do
		local uid, freek = item.uid, item.freek
		local isSelected = selected[uid]
		local card = UI.card({
			species = freek.species,
			mutation = freek.mutation,
			background = if isSelected then Color3.fromRGB(150, 60, 120) else nil,
			border = if isSelected then colors.pink else nil,
			lines = {
				{ FreekUtil.displayName(freek), nameColor(freek), 20 },
				{ Freeks.byId[freek.species].rarity, rarityColor(freek.species), 16 },
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
		else
			credit = "Nobody has found this yet!"
		end
		local card = UI.card({
			species = species.id,
			silhouette = not known,
			border = if state.discovered[species.id] then colors.green else nil,
			lines = {
				{ if known then species.name else "???", if known then colors.text else colors.muted, 22 },
				{ species.rarity, Rarities.info[species.rarity].color, 16 },
				{ credit, if discovery then colors.orange else colors.muted, 34 },
				{ if state.discovered[species.id] then "You have found this" else "", colors.green, 14 },
			},
		})
		card.LayoutOrder = species.order
		card.Parent = grid
	end
end

local MENU = {
	{ "Shop", colors.green },
	{ "Freeks", colors.blue },
	{ "Breed", colors.pink },
	{ "Book", colors.orange },
}
for i, entry in MENU do
	UI.button(entry[1], entry[2], function()
		open(entry[1])
	end, { Size = UDim2.new(1, 0, 0, 50), LayoutOrder = i, Parent = menu })
end

--------------------------------------------------------------------------------
-- Live updates
--------------------------------------------------------------------------------

local function updateMoney()
	moneyLabel.Text = Format.money(player:GetAttribute("Money") or 0)
	incomeLabel.Text = "+" .. Format.money(player:GetAttribute("Income") or 0) .. "/s"
	if state then
		state.money = player:GetAttribute("Money") or state.money
	end
end
player:GetAttributeChangedSignal("Money"):Connect(updateMoney)
player:GetAttributeChangedSignal("Income"):Connect(updateMoney)
updateMoney()

Remotes.get("Notify").OnClientEvent:Connect(toast)

Remotes.get("State").OnClientEvent:Connect(function(newState)
	state = newState
	render()
end)

Remotes.get("DiscoveryUpdate").OnClientEvent:Connect(function(speciesId, discovery)
	discoveries[speciesId] = discovery
	if currentWindow == "Book" then
		render()
	end
end)

-- Breed countdown.
task.spawn(function()
	while true do
		task.wait(0.5)
		if countdownLabel and state and state.breeding then
			local left = state.breeding.endsAt - Workspace:GetServerTimeNow()
			if left > 0 then
				countdownLabel.Text = "Baby arrives in " .. Format.time(left)
				claimButton.BackgroundColor3 = colors.gray
				claimButton.Text = "Not ready yet"
			else
				countdownLabel.Text = "Your baby is ready!"
				claimButton.BackgroundColor3 = colors.pink
				claimButton.Text = "Collect baby!"
			end
		end
	end
end)

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
state = Remotes.get("GetState"):InvokeServer()
render()
