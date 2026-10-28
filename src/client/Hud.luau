-- The always-on screen pieces, laid out like the owner's reference (a top simulator's
-- HUD). Nothing has a panel behind it; everything floats on the world:
-- - top centre: wide travel buttons (HOME, ZONES, SPIN)
-- - left: wide menu buttons (SHOP, MY HOME, BAG, INDEX) with red badges, and the event
--   timer under them
-- - right: square tiles (STORE, LUCK, and ADMIN for admins)
-- - bottom left: Speed and money as big chunky numbers with 3D icons, what you earn under
--   them, and "+$" popping up when money comes in
-- - bottom right: a dark bar with the next egg's hatch timer
-- - a dark pill under the top buttons (the zone you walked into, or the egg you carry) and
--   short messages under it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Events = require(ReplicatedStorage.Shared.Events)
local Format = require(ReplicatedStorage.Shared.Format)
local Items = require(ReplicatedStorage.Shared.Items)
local ZoneLayout = require(ReplicatedStorage.Shared.ZoneLayout)
local ItemPictures = require(script.Parent.ItemPictures)
local UI = require(script.Parent.UI)

local colors = UI.colors
local player = Players.LocalPlayer

local Hud = {}

-- A 3D icon (an ItemPictures key), or the emoji if there's no model for it.
function Hud.icon(key: string, emoji: string): GuiObject | string
	if ItemPictures.has(key) then
		local view = ItemPictures.icon(key)
		return view
	end
	return emoji
end

-- Shrinks a group on short screens (phones) so nothing runs off the edge.
local function fit(frame: GuiObject, designHeight: number)
	local scale = UI.new("UIScale", { Parent = frame })
	local function update()
		local camera = Workspace.CurrentCamera
		scale.Scale = math.clamp(camera.ViewportSize.Y / designHeight, 0.55, 1)
	end
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	update()
end

local function column(screen: ScreenGui, props, gap: number, horizontal: boolean?)
	local frame = UI.new("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(),
		Parent = screen,
	}, {
		UI.new("UIListLayout", {
			FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, gap),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for key, value in props do
		frame[key] = value
	end
	return frame
end

--------------------------------------------------------------------------------
-- Buttons
--------------------------------------------------------------------------------

-- A row (top centre) or column (left) of wide buttons. entries = { { name, text, colour,
-- icon } }. Returns setBadge(name, text or nil) and the buttons by name.
function Hud.buttons(screen: ScreenGui, where: string, entries, onSelect: (string) -> ())
	local row = where == "top"
	local holder = column(
		screen,
		if row
			then { Name = "TopButtons", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10) }
			else { Name = "MenuButtons", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.42, 0) },
		if row then 22 else 12,
		row
	)
	fit(holder, if row then 600 else 760)
	local badges, buttons = {}, {}
	for i, entry in entries do
		local button, setBadge = UI.wideButton({
			name = entry[1],
			text = entry[2],
			color = entry[3],
			icon = entry[4],
			size = if row then Vector2.new(196, 54) else Vector2.new(200, 60),
			onClick = function()
				onSelect(entry[1])
			end,
		})
		button.LayoutOrder = i
		button.Parent = holder
		badges[entry[1]], buttons[entry[1]] = setBadge, button
	end
	return function(name: string, text: string?)
		if badges[name] then
			badges[name](text)
		end
	end,
		buttons,
		holder
end

-- Square tiles on the right. entries = { { name, colour, icon } }. Returns setBadge and the
-- tiles by name.
function Hud.tiles(screen: ScreenGui, entries, onSelect: (string) -> ())
	local holder = column(screen, {
		Name = "Tiles",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.55, 0),
	}, 14)
	fit(holder, 760)
	local badges, tiles = {}, {}
	for i, entry in entries do
		local tile, setBadge = UI.tile({
			name = entry[1],
			color = entry[2],
			icon = entry[3],
			size = 80,
			onClick = function()
				onSelect(entry[1])
			end,
		})
		tile.LayoutOrder = i
		tile.Parent = holder
		badges[entry[1]], tiles[entry[1]] = setBadge, tile
	end
	return function(name: string, text: string?)
		if badges[name] then
			badges[name](text)
		end
	end, tiles
end

--------------------------------------------------------------------------------
-- Speed and money
--------------------------------------------------------------------------------

-- A number that glides to its new value instead of jumping.
local function glide(label: TextLabel, read: () -> number, show: (number) -> string)
	local shown = read()
	label.Text = show(shown)
	RunService.RenderStepped:Connect(function(dt)
		local target = read()
		shown += (target - shown) * math.min(1, dt * 8)
		if math.abs(target - shown) < 1 then
			shown = target
		end
		label.Text = show(shown)
	end)
end

function Hud.stats(screen: ScreenGui)
	local holder = UI.new("Frame", {
		Name = "Stats",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 18, 1, -14),
		Size = UDim2.fromOffset(360, 170),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	fit(holder, 720)

	-- Speed: a lightning bolt and a big gold number.
	local bolt = ItemPictures.icon("Bolt")
	bolt.Position = UDim2.fromOffset(0, 0)
	bolt.Size = UDim2.fromOffset(56, 56)
	bolt.Parent = holder
	local speed = UI.heavy("0", 46, {
		Position = UDim2.fromOffset(64, 4),
		Size = UDim2.fromOffset(290, 52),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = colors.speed,
		Parent = holder,
	})
	glide(speed, function()
		return player:GetAttribute("Speed") or 0
	end, Format.number)
	local training = UI.heavy("TRAINING!", 18, {
		Position = UDim2.fromOffset(66, -16),
		Size = UDim2.fromOffset(160, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = colors.speed,
		Visible = false,
		Parent = holder,
	})
	player:GetAttributeChangedSignal("Training"):Connect(function()
		training.Visible = player:GetAttribute("Training") == true
	end)

	-- Money: a stack of cash and a big green number, what you earn under it.
	local cash = ItemPictures.icon("Cash")
	cash.Position = UDim2.fromOffset(-4, 62)
	cash.Size = UDim2.fromOffset(66, 66)
	cash.Parent = holder
	local money = UI.heavy("$0", 56, {
		Position = UDim2.fromOffset(64, 66),
		Size = UDim2.fromOffset(300, 62),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = colors.money,
		Parent = holder,
	})
	glide(money, function()
		return player:GetAttribute("Money") or 0
	end, Format.money)
	local income = UI.heavy("Earning $0/s", 22, {
		Position = UDim2.fromOffset(4, 134),
		Size = UDim2.fromOffset(340, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = colors.money,
		Parent = holder,
	})
	local function updateIncome()
		income.Text = "Earning " .. Format.money(player:GetAttribute("Income") or 0) .. "/s"
	end
	player:GetAttributeChangedSignal("Income"):Connect(updateIncome)
	updateIncome()

	-- "+$" popping up and floating away when money comes in.
	local last = player:GetAttribute("Money") or 0
	player:GetAttributeChangedSignal("Money"):Connect(function()
		local now = player:GetAttribute("Money") or 0
		local gain = now - last
		last = now
		if gain < 1 then
			return
		end
		local pop = UI.heavy("+" .. Format.money(gain), 30, {
			Position = UDim2.fromOffset(200 + math.random(-30, 40), 60),
			Size = UDim2.fromOffset(200, 34),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = colors.money,
			Parent = holder,
		})
		local info = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(pop, info, { Position = pop.Position - UDim2.fromOffset(0, 60), TextTransparency = 1 })
			:Play()
		TweenService:Create(pop:FindFirstChildOfClass("UIStroke"), info, { Transparency = 1 }):Play()
		task.delay(1.2, function()
			pop:Destroy()
		end)
	end)
end

--------------------------------------------------------------------------------
-- Timers
--------------------------------------------------------------------------------

-- The event timer under the menu buttons: what's on now (and how long it has left), or
-- the next big event and how long until it starts.
function Hud.eventTimer(menu: GuiObject)
	local holder = UI.new("Frame", {
		Name = "EventTimer",
		Size = UDim2.fromOffset(200, 70),
		BackgroundTransparency = 1,
		LayoutOrder = 99,
		Parent = menu,
	})
	local icon = UI.text("", 40, {
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.fromOffset(54, 54),
		Parent = holder,
	})
	local name = UI.heavy("", 18, {
		Position = UDim2.fromOffset(58, 6),
		Size = UDim2.fromOffset(142, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})
	local clock = UI.heavy("", 32, {
		Position = UDim2.fromOffset(58, 28),
		Size = UDim2.fromOffset(142, 36),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})
	local function hms(seconds: number): string
		seconds = math.max(0, math.floor(seconds))
		return string.format("%02d:%02d:%02d", seconds // 3600, seconds % 3600 // 60, seconds % 60)
	end
	task.spawn(function()
		while holder.Parent do
			local now = Workspace:GetServerTimeNow()
			local big, ends = Events.current()
			local weather, weatherEnds = Events.weather()
			if big or weather then
				local def = big or weather
				icon.Text = def.icon
				name.Text = def.name
				name.TextColor3 = def.color
				clock.Text = hms((if big then ends else weatherEnds) - now)
				clock.TextColor3 = colors.white
			else
				local next = Events.upcoming(os.time())[1]
				local def = next and Events.BIG[next.id]
				holder.Visible = def ~= nil
				if def then
					icon.Text = def.icon
					name.Text = def.name .. " in"
					name.TextColor3 = def.color
					clock.Text = hms(next.starts - os.time())
					clock.TextColor3 = colors.white
				end
			end
			task.wait(0.5)
		end
	end)
end

-- A small dark bar (bottom right, like the reference's restock timer). Returns
-- set(text, colour?) (nil text hides it).
function Hud.bar(screen: ScreenGui)
	local bar = UI.new("Frame", {
		Name = "Bar",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.fromOffset(280, 56),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		Visible = false,
		Parent = screen,
	}, {
		UI.corner(4),
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
	})
	fit(bar, 720)
	local label = UI.heavy("", 34, {
		Size = UDim2.fromScale(1, 1),
		Parent = bar,
	})
	return function(text: string?, color: Color3?)
		bar.Visible = text ~= nil
		label.Text = text or ""
		label.TextColor3 = color or colors.white
	end
end

--------------------------------------------------------------------------------
-- Top pill: the zone you just walked into, or the egg you're carrying
--------------------------------------------------------------------------------

function Hud.topPill(screen: ScreenGui)
	local pill = UI.new("Frame", {
		Name = "TopPill",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 80),
		Size = UDim2.fromOffset(0, 44),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		Visible = false,
		Parent = screen,
	}, {
		UI.corner(4),
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
	})
	local label = UI.heavy("", 26, {
		Size = UDim2.fromOffset(0, 44),
		AutomaticSize = Enum.AutomaticSize.X,
		TextScaled = false,
		TextSize = 26,
		Parent = pill,
	})

	-- The beam from you to your gate while you carry an egg, so you never get lost.
	local beam, from, target
	local function clearBeam()
		for _, thing in { beam, from, target } do
			if thing then
				thing:Destroy()
			end
		end
		beam, from, target = nil, nil, nil
	end
	local function beamHome()
		clearBeam()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local plotIndex = player:GetAttribute("Plot")
		local plots = Workspace:FindFirstChild("Plots")
		local plot = plotIndex and plots and plots:FindFirstChild("Plot" .. plotIndex)
		local origin = plot and plot:GetAttribute("Origin")
		if not root or typeof(origin) ~= "CFrame" then
			return
		end
		target = UI.new("Part", {
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			Transparency = 1,
			Size = Vector3.one,
			CFrame = origin * CFrame.new(0, 3, -40),
			Parent = Workspace,
		})
		local a1 = UI.new("Attachment", { Parent = target })
		from = UI.new("Attachment", { Position = Vector3.new(0, -2, 0), Parent = root })
		beam = UI.new("Beam", {
			Attachment0 = from,
			Attachment1 = a1,
			Width0 = 0.8,
			Width1 = 0.8,
			FaceCamera = true,
			LightEmission = 1,
			Color = ColorSequence.new(Color3.fromRGB(110, 255, 140)),
			Transparency = NumberSequence.new(0.2),
			Parent = target,
		})
	end

	local zoneUntil = 0
	local currentZone = nil
	local function show(text: string, color: Color3)
		label.Text = text
		label.TextColor3 = color
		pill.Visible = true
	end
	local function onCarrying()
		local carrying = player:GetAttribute("Carrying")
		if typeof(carrying) == "string" then
			show("🥚 " .. string.upper(carrying) .. " · RUN HOME!", colors.gold)
			beamHome()
		else
			clearBeam()
			pill.Visible = os.clock() < zoneUntil
		end
	end
	player:GetAttributeChangedSignal("Carrying"):Connect(onCarrying)
	onCarrying()

	task.spawn(function()
		while true do
			task.wait(0.2)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local zone = root and ZoneLayout.zoneAt(root.Position)
			local carrying = typeof(player:GetAttribute("Carrying")) == "string"
			if zone ~= currentZone then
				currentZone = zone
				if zone and not carrying then
					local info = Items.ZONES[zone]
					local fast = (player:GetAttribute("Speed") or 0) >= info.speed
					show(
						Items.KINDS[info.kind].icon
							.. " "
							.. string.upper(info.name)
							.. (if fast then " · GRAB AN EGG!" else " · NEEDS ⚡" .. Format.number(info.speed)),
						if fast then colors.white else Color3.fromRGB(255, 110, 110)
					)
					zoneUntil = os.clock() + 3.5
				end
			end
			if not carrying and pill.Visible and os.clock() >= zoneUntil then
				pill.Visible = false
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- Messages
--------------------------------------------------------------------------------

local MESSAGE_COLORS = {
	success = UI.colors.money,
	money = UI.colors.money,
	error = Color3.fromRGB(255, 110, 110),
	discovery = UI.colors.gold,
}

-- Short messages under the top pill, fading out after a few seconds. Returns show(text,
-- kind).
function Hud.messages(screen: ScreenGui)
	local holder = UI.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 132),
		Size = UDim2.new(0.6, 0, 0, 200),
		Parent = screen,
	}, {
		UI.new("UIListLayout", {
			Padding = UDim.new(0, 4),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	return function(message: string, kind: string?)
		local label = UI.heavy(message, 26, {
			Size = UDim2.new(1, 0, 0, 32),
			TextColor3 = MESSAGE_COLORS[kind or ""] or colors.white,
			Parent = holder,
		})
		task.delay(3.5, function()
			local info = TweenInfo.new(0.4)
			TweenService:Create(label, info, { TextTransparency = 1 }):Play()
			TweenService:Create(label.UIStroke, info, { Transparency = 1 }):Play()
			task.wait(0.4)
			label:Destroy()
		end)
	end
end

return Hud
