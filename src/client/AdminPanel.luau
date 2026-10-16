-- The admin panel (only for admins: the server sets IsAdmin and checks every command).
-- Start or end events in this server or all of them, fire any Freek from a cannon,
-- announce something to everyone, see the coming timetable, and get test coins.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Events = require(ReplicatedStorage.Shared.Events)
local Freeks = require(ReplicatedStorage.Shared.Freeks)
local Luck = require(ReplicatedStorage.Shared.Luck)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local UI = require(script.Parent.UI)

local AdminPanel = {}

local player = Players.LocalPlayer
local colors = UI.colors

-- Every event the panel can start, in the order its buttons appear.
local EVENT_BUTTONS = {
	{ id = "MonsterStorm", def = Events.BIG.MonsterStorm },
	{ id = "BloodMoon", def = Events.WEATHER.BloodMoon },
	{ id = "GoldRush", def = Events.WEATHER.GoldRush },
	{ id = "RainbowRain", def = Events.WEATHER.RainbowRain },
	{ id = "Rainbow", def = Luck.EVENTS.Rainbow },
	{ id = "LuckySkies", def = Luck.EVENTS.LuckySkies },
	{ id = "RapidFire", def = Luck.EVENTS.RapidFire },
	{ id = "CrateLuck", def = Luck.EVENTS.CrateLuck },
}
local DURATIONS = { 5, 15, 30, 60 }

local function heading(text: string, parent: Instance, order: number)
	return UI.label(text, {
		Size = UDim2.new(1, 0, 0, 24),
		FontFace = UI.fonts.heavy,
		TextColor3 = colors.gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order,
		Parent = parent,
	})
end

local function row(parent: Instance, order: number, height: number)
	return UI.new("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = parent,
	}, {
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

function AdminPanel.start(screen: ScreenGui)
	local remote = Remotes.get("Admin")
	local window
	local status

	local function run(command: string, args)
		status.Text = "..."
		status.TextColor3 = colors.text
		task.spawn(function()
			local ok, result, message = pcall(function()
				return remote:InvokeServer(command, args)
			end)
			if not ok then
				status.Text = "Couldn't reach the server"
				status.TextColor3 = colors.red
				return
			end
			status.Text = tostring(message or (if result then "Done" else "Failed"))
			status.TextColor3 = if result then colors.money else Color3.fromRGB(255, 140, 140)
		end)
	end

	-- The window, in the game's style: blue panel, gold title ribbon, round red X.
	window = UI.glass({
		Name = "AdminPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(600, 520),
		Visible = false,
		ZIndex = 20,
		Parent = screen,
	}, { UI.corner(22) })
	local fit = UI.new("UIScale", { Parent = window })
	local function refit()
		local camera = Workspace.CurrentCamera
		if camera then
			fit.Scale = math.clamp(math.min(camera.ViewportSize.X / 640, camera.ViewportSize.Y / 600), 0.5, 1)
		end
	end
	refit()
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
	local ribbon = UI.glass({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 2),
		Size = UDim2.fromOffset(280, 48),
		BackgroundColor3 = Color3.fromRGB(255, 190, 40),
		ZIndex = 21,
		Parent = window,
	}, { UI.corner(24) })
	UI.label("ADMIN PANEL", {
		Size = UDim2.new(1, -20, 1, -8),
		Position = UDim2.fromOffset(10, 4),
		FontFace = UI.fonts.heavy,
		ZIndex = 22,
		Parent = ribbon,
	})
	local close = UI.button("X", colors.red, function()
		window.Visible = false
	end, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.fromOffset(44, 44),
		ZIndex = 22,
		Parent = window,
	})
	close:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(1, 0)

	local body = UI.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(16, 34),
		Size = UDim2.new(1, -32, 1, -78),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ZIndex = 21,
		Parent = window,
	}, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		UI.new("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6) }),
	})
	status = UI.label("Pick an event, or fire a Freek!", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(1, -32, 0, 26),
		ZIndex = 22,
		Parent = window,
	})

	-- Everywhere or just this server, used by events and announcements.
	local everywhere = true

	-- Events --------------------------------------------------------------------
	heading("⚡ START AN EVENT", body, 1)
	local chosenEvent = EVENT_BUTTONS[1].id
	local eventButtons = {}
	local grid = UI.new("Frame", {
		Size = UDim2.new(1, 0, 0, 82),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = body,
	}, {
		UI.new("UIGridLayout", {
			CellSize = UDim2.new(0.25, -6, 0, 38),
			CellPadding = UDim2.fromOffset(6, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local function paintEvents()
		for id, button in eventButtons do
			local entry
			for _, e in EVENT_BUTTONS do
				if e.id == id then
					entry = e
				end
			end
			local picked = id == chosenEvent
			button.BackgroundColor3 = if picked then entry.def.color else colors.card
			button:FindFirstChildOfClass("UIStroke").Color = if picked then Color3.new(1, 1, 1) else UI.OUTLINE
		end
	end
	for i, entry in EVENT_BUTTONS do
		eventButtons[entry.id] = UI.button(entry.def.icon .. " " .. entry.def.name, colors.card, function()
			chosenEvent = entry.id
			paintEvents()
		end, { LayoutOrder = i, ZIndex = 22, Parent = grid })
	end
	paintEvents()

	local minutes = 15
	local timeRow = row(body, 3, 36)
	UI.label("Length:", {
		Size = UDim2.fromOffset(70, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 22,
		Parent = timeRow,
	})
	local timeButtons = {}
	local function paintTimes()
		for value, button in timeButtons do
			button.BackgroundColor3 = if value == minutes then colors.orange else colors.card
		end
	end
	for i, value in DURATIONS do
		timeButtons[value] = UI.button(value .. " min", colors.card, function()
			minutes = value
			paintTimes()
		end, { Size = UDim2.fromOffset(78, 32), LayoutOrder = i, ZIndex = 22, Parent = timeRow })
	end
	paintTimes()
	local whereButton
	whereButton = UI.button("ALL SERVERS", colors.purple, function()
		everywhere = not everywhere
		whereButton.Text = if everywhere then "ALL SERVERS" else "THIS SERVER"
		whereButton.BackgroundColor3 = if everywhere then colors.purple else colors.blue
	end, { Size = UDim2.fromOffset(150, 32), LayoutOrder = 10, ZIndex = 22, Parent = timeRow })

	local goRow = row(body, 4, 44)
	UI.button("▶ START", colors.green, function()
		run("event", { id = chosenEvent, minutes = minutes, everywhere = everywhere })
	end, { Size = UDim2.new(0.5, -3, 0, 40), LayoutOrder = 1, ZIndex = 22, Parent = goRow })
	UI.button("■ END EVENTS", colors.red, function()
		run("stop", { everywhere = everywhere })
	end, { Size = UDim2.new(0.5, -3, 0, 40), LayoutOrder = 2, ZIndex = 22, Parent = goRow })

	-- Cannon --------------------------------------------------------------------
	heading("💥 FIRE A FREEK FROM A CANNON (THIS SERVER)", body, 5)
	local speciesIds = {}
	for _, species in Freeks.list do
		table.insert(speciesIds, species.id)
	end
	local mutationIds = { "" }
	for _, mutation in Mutations.list do
		table.insert(mutationIds, mutation.id)
	end
	local speciesIndex, mutationIndex = 1, 1
	local cannonRow = row(body, 6, 44)
	local function cycler(values, getIndex, setIndex, describe, order, width)
		local label
		local function show()
			label.Text = describe(values[getIndex()])
		end
		UI.button("<", colors.blue, function()
			setIndex((getIndex() - 2) % #values + 1)
			show()
		end, { Size = UDim2.fromOffset(34, 36), LayoutOrder = order, ZIndex = 22, Parent = cannonRow })
		label = UI.label("", {
			Size = UDim2.fromOffset(width, 36),
			BackgroundTransparency = 0,
			BackgroundColor3 = colors.card,
			LayoutOrder = order + 1,
			ZIndex = 22,
			Parent = cannonRow,
		})
		UI.corner(10).Parent = label
		UI.stroke(nil, 2.5).Parent = label
		UI.button(">", colors.blue, function()
			setIndex(getIndex() % #values + 1)
			show()
		end, { Size = UDim2.fromOffset(34, 36), LayoutOrder = order + 2, ZIndex = 22, Parent = cannonRow })
		show()
	end
	cycler(speciesIds, function()
		return speciesIndex
	end, function(v)
		speciesIndex = v
	end, function(id)
		local species = Freeks.byId[id]
		return species and species.name or id
	end, 1, 130)
	cycler(mutationIds, function()
		return mutationIndex
	end, function(v)
		mutationIndex = v
	end, function(id)
		return if id == "" then "No mutation" else id
	end, 4, 110)
	UI.button("FIRE!", colors.orange, function()
		local mutation = mutationIds[mutationIndex]
		run("spawn", { species = speciesIds[speciesIndex], mutation = if mutation == "" then nil else mutation })
	end, { Size = UDim2.fromOffset(84, 40), LayoutOrder = 10, ZIndex = 22, Parent = cannonRow })

	-- Announce ------------------------------------------------------------------
	heading("📣 ANNOUNCE (USES THE SERVER BUTTON ABOVE)", body, 7)
	local announceRow = row(body, 8, 44)
	local box = UI.new("TextBox", {
		Size = UDim2.new(1, -110, 0, 38),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		FontFace = UI.fonts.bold,
		PlaceholderText = "Monster Storm in 5 minutes!",
		PlaceholderColor3 = Color3.fromRGB(140, 150, 180),
		Text = "",
		TextColor3 = UI.OUTLINE,
		TextSize = 18,
		ClearTextOnFocus = false,
		LayoutOrder = 1,
		ZIndex = 22,
		Parent = announceRow,
	}, { UI.corner(10), UI.stroke(nil, 2.5), UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10) }) })
	UI.button("SEND", colors.green, function()
		run("announce", { text = box.Text, everywhere = everywhere })
		box.Text = ""
	end, { Size = UDim2.fromOffset(100, 40), LayoutOrder = 2, ZIndex = 22, Parent = announceRow })

	-- Timetable and test coins --------------------------------------------------
	heading("🗓️ COMING UP (YOUR LOCAL TIME)", body, 9)
	local schedule = UI.label("", {
		Size = UDim2.new(1, 0, 0, 66),
		TextScaled = false,
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 10,
		ZIndex = 22,
		Parent = body,
	})
	local function refreshSchedule()
		local lines = {}
		local t = os.time()
		for i, slot in Events.upcoming(t) do
			if i > 3 then
				break
			end
			local def = Events.BIG[slot.id]
			local when = os.date("%a %I:%M %p", slot.starts)
			table.insert(
				lines,
				def.icon .. " " .. def.name .. " · " .. when .. if slot.starts <= t then "  (LIVE)" else ""
			)
		end
		local weather = Events.nextWeather(t)
		if weather then
			local def = Events.WEATHER[weather.id]
			table.insert(lines, def.icon .. " " .. def.name .. " · " .. os.date("%I:%M %p", weather.starts))
		end
		schedule.Text = table.concat(lines, "\n")
	end

	local coinRow = row(body, 11, 44)
	for i, amount in { 1e6, 1e9 } do
		UI.button("+" .. (if amount >= 1e9 then "1B" else "1M") .. " COINS", colors.gold, function()
			run("money", { amount = amount })
		end, { Size = UDim2.fromOffset(150, 38), LayoutOrder = i, ZIndex = 22, Parent = coinRow })
	end

	-- The ADMIN button that opens it, only shown to admins.
	local toggle = UI.button("🛠️ ADMIN", colors.red, function()
		window.Visible = not window.Visible
		if window.Visible then
			refreshSchedule()
		end
	end, {
		Name = "AdminButton",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(120, 38),
		Visible = false,
		ZIndex = 10,
		Parent = screen,
	})
	local function update()
		toggle.Visible = player:GetAttribute("IsAdmin") == true
		if not toggle.Visible then
			window.Visible = false
		end
	end
	player:GetAttributeChangedSignal("IsAdmin"):Connect(update)
	update()
	return window
end

return AdminPanel
