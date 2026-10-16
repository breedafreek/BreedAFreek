-- The always-on-screen parts of the UI: money, event chip, menu tabs, leaderboard,
-- gate button and pop-up notifications. Windows (Shop, Freeks, ...) live in Main.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Events = require(ReplicatedStorage.Shared.Events)
local Format = require(ReplicatedStorage.Shared.Format)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local Luck = require(ReplicatedStorage.Shared.Luck)
local Seasons = require(ReplicatedStorage.Shared.Seasons)
local ItemPictures = require(script.Parent.ItemPictures)
local UI = require(script.Parent.UI)

local colors = UI.colors
local player = Players.LocalPlayer

local Hud = {}

local function text(value: string, size: number, props)
	local label = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = UI.fonts.bold,
		Text = value,
		TextSize = size,
		TextColor3 = colors.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, { UI.textStroke(if size >= 22 then 2.5 else 1.8) })
	for key, v in props or {} do
		label[key] = v
	end
	return label
end

-- Scales a frame down on short screens (phones) so it never runs off the edge.
local function fitHeight(frame: GuiObject, designHeight: number, reserved: number)
	local scale = UI.new("UIScale", { Parent = frame })
	local function update()
		local camera = Workspace.CurrentCamera
		local available = camera.ViewportSize.Y - reserved
		scale.Scale = math.clamp(available / designHeight, 0.55, 1)
	end
	update()
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
end

local function hoverGrow(button: GuiButton)
	local scale = UI.new("UIScale", { Parent = button })
	local info = TweenInfo.new(0.12, Enum.EasingStyle.Quad)
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, info, { Scale = 1.06 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, info, { Scale = 1 }):Play()
	end)
end

--------------------------------------------------------------------------------
-- Money
--------------------------------------------------------------------------------

function Hud.money(screen: ScreenGui)
	local pill = UI.glass({
		Name = "Money",
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromOffset(250, 62),
		BackgroundColor3 = Color3.fromRGB(40, 165, 75),
		Parent = screen,
	}, { UI.corner(20) })

	UI.new("Frame", {
		Name = "Coin",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = colors.gold,
		Parent = pill,
	}, {
		UI.corner(20),
		UI.new("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(255, 226, 120), Color3.fromRGB(235, 150, 30)),
			Rotation = 90,
		}),
		UI.stroke(nil, 3),
		text("$", 24, {
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			FontFace = UI.fonts.heavy,
			TextColor3 = Color3.fromRGB(120, 70, 10),
		}),
	})

	local amount = text("$0", 30, {
		Position = UDim2.fromOffset(60, 4),
		Size = UDim2.new(1, -116, 0, 32),
		FontFace = UI.fonts.heavy,
		TextColor3 = colors.money,
		Parent = pill,
	})
	local income = text("+$0/s", 15, {
		Position = UDim2.fromOffset(60, 35),
		Size = UDim2.new(1, -116, 0, 18),
		TextColor3 = Color3.fromRGB(255, 240, 150),
		Parent = pill,
	})
	local boost = UI.new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(46, 22),
		BackgroundColor3 = colors.gold,
		BackgroundTransparency = 0.75,
		FontFace = UI.fonts.heavy,
		TextSize = 14,
		TextColor3 = colors.gold,
		Visible = false,
		Parent = pill,
	}, { UI.corner(11) })

	-- The number glides to its new value instead of jumping.
	local shown = player:GetAttribute("Money") or 0
	RunService.RenderStepped:Connect(function(dt)
		local target = player:GetAttribute("Money") or 0
		shown += (target - shown) * math.min(1, dt * 8)
		if math.abs(target - shown) < 1 then
			shown = target
		end
		amount.Text = Format.money(shown)
	end)
	local function updateIncome()
		income.Text = "+" .. Format.money(player:GetAttribute("Income") or 0) .. "/s"
	end
	player:GetAttributeChangedSignal("Income"):Connect(updateIncome)
	updateIncome()

	return function(rebirths: number)
		boost.Visible = rebirths > 0
		boost.Text = "x" .. tostring(Config.incomeMultiplier(rebirths))
	end
end

--------------------------------------------------------------------------------
-- Event chip
--------------------------------------------------------------------------------

function Hud.eventChip(screen: ScreenGui)
	local chip = UI.glass({
		Name = "Event",
		Position = UDim2.fromOffset(12, 80),
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = false,
		Parent = screen,
	}, {
		UI.corner(14),
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12) }),
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 7),
		}),
	})
	local dot = UI.new("Frame", { Size = UDim2.fromOffset(9, 9), Parent = chip }, { UI.corner(5) })
	local label = text("", 14, { Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, Parent = chip })

	local function update()
		local active = Seasons.active()
		local season = active[1] and Seasons.list[active[1]]
		chip.Visible = season ~= nil
		if season then
			dot.BackgroundColor3 = season.color
			label.Text = season.name .. " Event · Live"
			label.TextColor3 = season.color:Lerp(Color3.new(1, 1, 1), 0.35)
		end
	end
	update()
	task.spawn(function()
		while true do
			task.wait(60)
			update()
		end
	end)
end

-- Shows the Lucky Hour event that's running (see Luck.luau) with a countdown.
function Hud.luckChip(screen: ScreenGui)
	local chip = UI.glass({
		Name = "LuckyEvent",
		Position = UDim2.fromOffset(12, 114),
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = false,
		Parent = screen,
	}, {
		UI.corner(15),
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12) }),
	})
	local stroke = UI.stroke(Color3.new(1, 1, 1), 2)
	stroke.Parent = chip
	local label = text("", 15, {
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		FontFace = UI.fonts.heavy,
		Parent = chip,
	})
	task.spawn(function()
		while true do
			local event, ends = Luck.current()
			chip.Visible = event ~= nil
			if event then
				local left = ends - Workspace:GetServerTimeNow()
				label.Text = event.icon .. "  " .. event.name .. " · " .. Format.time(left)
				label.TextColor3 = event.color:Lerp(Color3.new(1, 1, 1), 0.3)
				-- Pulse the outline so it catches the eye.
				stroke.Color = event.color
				stroke.Transparency = (math.sin(os.clock() * 4) + 1) * 0.3
			end
			task.wait(0.1)
		end
	end)
end

--------------------------------------------------------------------------------
-- Big events and weather (see Events.luau)
--------------------------------------------------------------------------------

-- "2d 4h", "3h 12m", "12:05": how long until something, short.
local function countdown(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local d, h, m, s = seconds // 86400, (seconds % 86400) // 3600, (seconds % 3600) // 60, seconds % 60
	if d > 0 then
		return string.format("%dd %dh", d, h)
	elseif h > 0 then
		return string.format("%dh %dm", h, m)
	end
	return string.format("%d:%02d", m, s)
end

-- A banner at the top of the screen: the big event when it's live (big, glowing, with time
-- left) or a countdown to the next one, and under it the weather or when it's next due.
function Hud.eventBanner(screen: ScreenGui)
	local holder = UI.new("Frame", {
		Name = "EventBanner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Parent = screen,
	}, {
		UI.new("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 5),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local function pill(order: number, height: number)
		local frame = UI.glass({
			Size = UDim2.fromOffset(0, height),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = order,
			Parent = holder,
		}, {
			UI.corner(height / 2),
			UI.new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
			UI.new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		})
		local label = text("", height * 0.55, {
			Size = UDim2.fromOffset(0, height),
			AutomaticSize = Enum.AutomaticSize.X,
			FontFace = UI.fonts.heavy,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = frame,
		})
		return frame, label, frame:FindFirstChildOfClass("UIStroke")
	end
	local eventPill, eventLabel, eventStroke = pill(1, 40)
	local weatherPill, weatherLabel = pill(2, 28)
	local eventScale = UI.new("UIScale", { Parent = eventPill })

	task.spawn(function()
		while true do
			local t = Workspace:GetServerTimeNow()
			local big, ends = Events.current()
			if big then
				-- Live: the event's colour, pulsing, with time left.
				local pulse = (math.sin(os.clock() * 5) + 1) / 2
				eventPill.BackgroundColor3 = big.color:Lerp(Color3.fromRGB(60, 20, 110), 0.35 + pulse * 0.2)
				eventLabel.Text = big.icon .. "  " .. string.upper(big.name) .. " LIVE · " .. countdown(ends - t)
				eventLabel.TextColor3 = Color3.new(1, 1, 1)
				if eventStroke then
					eventStroke.Color = big.color:Lerp(Color3.new(1, 1, 1), pulse * 0.6)
				end
				eventScale.Scale = 1 + pulse * 0.04
			else
				local id = ReplicatedStorage:GetAttribute("NextEvent")
				local at = ReplicatedStorage:GetAttribute("NextEventAt") or 0
				local nextEvent = id and Events.BIG[id]
				eventPill.Visible = nextEvent ~= nil
				if nextEvent then
					eventPill.BackgroundColor3 = colors.panel
					eventLabel.Text = nextEvent.icon .. "  " .. nextEvent.name .. " in " .. countdown(at - t)
					eventLabel.TextColor3 = nextEvent.color:Lerp(Color3.new(1, 1, 1), 0.55)
					if eventStroke then
						eventStroke.Color = UI.OUTLINE
					end
					eventScale.Scale = 0.85
				end
			end
			if big then
				eventPill.Visible = true
			end

			local weather, weatherEnds = Events.weather()
			if weather then
				weatherPill.BackgroundColor3 = weather.color:Lerp(Color3.new(0, 0, 0), 0.25)
				weatherLabel.Text = weather.icon .. "  " .. weather.name .. " · " .. countdown(weatherEnds - t)
				weatherLabel.TextColor3 = Color3.new(1, 1, 1)
				weatherPill.Visible = true
			else
				local id = ReplicatedStorage:GetAttribute("NextWeather")
				local at = ReplicatedStorage:GetAttribute("NextWeatherAt") or 0
				local nextWeather = id and Events.WEATHER[id]
				weatherPill.Visible = nextWeather ~= nil
				if nextWeather then
					weatherPill.BackgroundColor3 = colors.panel
					weatherLabel.Text = nextWeather.icon .. "  " .. nextWeather.name .. " in " .. countdown(at - t)
					weatherLabel.TextColor3 = nextWeather.color:Lerp(Color3.new(1, 1, 1), 0.5)
				end
			end
			task.wait(0.1)
		end
	end)
end

-- The Starter Pack offer button with its countdown (only during a player's first hours,
-- until they buy it). Tapping it opens the Store.
function Hud.starterOffer(screen: ScreenGui, onOpen: () -> ())
	local button = UI.button("", colors.green, onOpen, {
		Name = "StarterOffer",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, -70),
		Size = UDim2.fromOffset(170, 74),
		Visible = false,
		ZIndex = 10,
		Parent = screen,
	})
	button:FindFirstChildOfClass("UIPadding"):Destroy()
	local gradient = button:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new(Color3.fromRGB(80, 230, 120), Color3.fromRGB(30, 170, 150))
	end
	text("🎁 STARTER PACK", 18, {
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.new(1, 0, 0, 24),
		FontFace = UI.fonts.heavy,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 11,
		Parent = button,
	})
	local timer = text("", 22, {
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 0, 28),
		FontFace = UI.fonts.heavy,
		TextColor3 = colors.gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 11,
		Parent = button,
	})
	UI.tag(button, "LIMITED", colors.red).Size = UDim2.fromOffset(84, 24)
	local scale = UI.new("UIScale", { Parent = button })
	task.spawn(function()
		while true do
			local ends = player:GetAttribute("StarterEnds")
			local left = if ends then ends - Workspace:GetServerTimeNow() else 0
			button.Visible = left > 0 and not player:GetAttribute("CratesRestricted")
			if button.Visible then
				local h, m, sec = left // 3600, (left % 3600) // 60, math.floor(left % 60)
				timer.Text = string.format("⏰ %d:%02d:%02d", h, m, sec)
				scale.Scale = 1 + (math.sin(os.clock() * 4) + 1) * 0.02
			end
			task.wait(0.1)
		end
	end)
end

--------------------------------------------------------------------------------
-- Menu buttons
--------------------------------------------------------------------------------

-- The side buttons, like the big simulators': a two-column grid of chunky 3D buttons (a
-- bright face on a darker base, so they look pressable), each with a glossy shine, a big
-- wobbling emoji, its name across the bottom edge and a red alert badge when something is
-- waiting there.
--
-- entries = { { name, icon, color } }. Returns setActive(name or nil) and
-- setBadge(name, text or nil, color?).
function Hud.menu(screen: ScreenGui, entries, onSelect: (string) -> ())
	local TILE = 72
	local DEPTH = 5 -- how far the base shows under the face
	local GAP_X, GAP_Y = 12, 16
	local COLUMNS = 2
	local rows = math.ceil(#entries / COLUMNS)
	local width = COLUMNS * TILE + (COLUMNS - 1) * GAP_X + 16
	local height = rows * (TILE + DEPTH) + (rows - 1) * GAP_Y + 24
	-- Starts below the money pill and event chip, and shrinks to fit on short screens.
	local rail = UI.new("Frame", {
		Name = "Menu",
		Position = UDim2.fromOffset(6, 112),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 1,
		Parent = screen,
	}, {
		UI.new("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 8),
		}),
		UI.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(TILE, TILE + DEPTH),
			CellPadding = UDim2.fromOffset(GAP_X, GAP_Y),
			FillDirection = Enum.FillDirection.Horizontal,
			FillDirectionMaxCells = COLUMNS,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	fitHeight(rail, height, 112 + 24)

	local tiles = {}
	local icons = {}
	local pressInfo = TweenInfo.new(0.08, Enum.EasingStyle.Quad)
	for i, entry in entries do
		local name, icon, color = entry[1], entry[2], entry[3]
		local holder = UI.new("Frame", {
			Name = name,
			BackgroundTransparency = 1,
			LayoutOrder = i,
			Parent = rail,
		})
		-- The darker base underneath.
		UI.new("Frame", {
			Name = "Base",
			Position = UDim2.fromOffset(0, DEPTH),
			Size = UDim2.fromOffset(TILE, TILE),
			BackgroundColor3 = color:Lerp(Color3.new(0, 0, 0), 0.45),
			Parent = holder,
		}, { UI.corner(20), UI.stroke(nil, 3.5) })

		local face = UI.new("TextButton", {
			Name = "Face",
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = color,
			Size = UDim2.fromOffset(TILE, TILE),
			ZIndex = 2,
			Parent = holder,
		}, {
			UI.corner(20),
			UI.new("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(0.55, Color3.fromRGB(235, 235, 235)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(175, 175, 185)),
				}),
				Rotation = 90,
			}),
		})
		local ring = UI.stroke(nil, 3.5)
		ring.Parent = face
		-- Glossy shine across the top.
		UI.new("Frame", {
			Name = "Shine",
			Position = UDim2.fromOffset(7, 5),
			Size = UDim2.new(1, -14, 0.38, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.55,
			ZIndex = 2,
			Parent = face,
		}, {
			UI.corner(14),
			UI.new("UIGradient", {
				Transparency = NumberSequence.new(0, 1),
				Rotation = 90,
			}),
		})
		-- The big picture: a 3D model if there is one, otherwise the emoji.
		local pictureKey = "Menu" .. name
		local picture, sway
		if ItemPictures.has(pictureKey) then
			picture, sway = ItemPictures.icon(pictureKey)
		else
			picture = text(icon, 40, { TextXAlignment = Enum.TextXAlignment.Center })
		end
		picture.Name = "Icon"
		picture.AnchorPoint = Vector2.new(0.5, 0.5)
		picture.Position = UDim2.new(0.5, 0, 0.44, 0)
		picture.Size = UDim2.fromOffset(TILE - 6, TILE - 14)
		picture.ZIndex = 3
		picture.Parent = face
		local iconScale = UI.new("UIScale", { Parent = picture })
		table.insert(icons, { picture = picture, sway = sway, phase = i * 0.9 })
		-- The name, straddling the bottom edge.
		local caption = text(string.upper(name), 17, {
			Name = "Caption",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 1, -6),
			Size = UDim2.new(1, 12, 0, 20),
			TextXAlignment = Enum.TextXAlignment.Center,
			FontFace = UI.fonts.heavy,
			ZIndex = 4,
			Parent = face,
		})
		caption:FindFirstChildOfClass("UIStroke").Thickness = 2.6

		-- The alert badge in the top-right corner (hidden until setBadge).
		local badge = UI.new("TextLabel", {
			Name = "Badge",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -6, 0, 4),
			Size = UDim2.fromOffset(0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = colors.red,
			FontFace = UI.fonts.heavy,
			Text = "!",
			TextSize = 18,
			TextColor3 = colors.text,
			Visible = false,
			ZIndex = 6,
			Parent = face,
		}, {
			UI.corner(13),
			UI.stroke(nil, 3),
			UI.textStroke(2),
			UI.new("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 3),
			}),
		})
		local badgeScale = UI.new("UIScale", { Parent = badge })

		-- Pressing pushes the face down onto its base.
		local function press(down: boolean)
			TweenService:Create(face, pressInfo, {
				Position = UDim2.fromOffset(0, if down then DEPTH - 1 else 0),
			}):Play()
		end
		face.MouseButton1Down:Connect(function()
			press(true)
		end)
		face.MouseButton1Up:Connect(function()
			press(false)
		end)
		face.MouseLeave:Connect(function()
			press(false)
		end)
		hoverGrow(face)
		face.Activated:Connect(function()
			onSelect(name)
		end)
		tiles[name] = { ring = ring, badge = badge, badgeScale = badgeScale, icon = iconScale }
	end

	-- Pictures sway gently in a wave; badges throb so they catch the eye.
	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		for _, entry in icons do
			if entry.sway then
				entry.sway(t * 1.4 + entry.phase)
			else
				entry.picture.Rotation = math.sin(t * 1.8 + entry.phase) * 6
			end
		end
		local throb = 1 + math.max(0, math.sin(t * 5)) * 0.15
		for _, tile in tiles do
			if tile.badge.Visible then
				tile.badgeScale.Scale = throb
			end
		end
	end)

	local function setActive(active: string?)
		for name, tile in tiles do
			local on = name == active
			tile.ring.Color = if on then Color3.new(1, 1, 1) else UI.OUTLINE
			tile.ring.Thickness = if on then 4.5 else 3.5
			tile.icon.Scale = if on then 1.15 else 1
		end
	end

	local function setBadge(name: string, value: string?, color: Color3?)
		local tile = tiles[name]
		if tile then
			tile.badge.Visible = value ~= nil
			tile.badge.Text = value or ""
			tile.badge.BackgroundColor3 = color or colors.red
		end
	end

	return setActive, setBadge
end

--------------------------------------------------------------------------------
-- Leaderboard (replaces Roblox's default player list)
--------------------------------------------------------------------------------

function Hud.leaderboard(screen: ScreenGui)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	end)

	local ROW = 40
	local board = UI.glass({
		Name = "Leaderboard",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(250, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = screen,
	}, {
		UI.corner(16),
		UI.new("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
		UI.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	local header = UI.new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 0,
		Parent = board,
	}, {
		text("🏆  Leaderboard", 15, {
			Position = UDim2.fromOffset(4, 0),
			Size = UDim2.new(1, -40, 1, 0),
			FontFace = UI.fonts.heavy,
		}),
	})
	local count = text("", 13, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -4, 0, 0),
		Size = UDim2.fromOffset(40, 26),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = colors.muted,
		Parent = header,
	})

	local list = UI.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Parent = board,
	}, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	header.Activated:Connect(function()
		list.Visible = not list.Visible
	end)

	local rows = {} -- [Player] = { frame, rank, name, money, badge }
	local thumbnails = {}

	local function makeRow(other: Player)
		local isMe = other == player
		local frame = UI.new("Frame", {
			BackgroundColor3 = if isMe then colors.blue else Color3.new(1, 1, 1),
			BackgroundTransparency = if isMe then 0.72 else 0.95,
			Size = UDim2.new(1, 0, 0, ROW),
			Parent = list,
		}, { UI.corner(10) })
		local rank = text("1", 13, {
			Position = UDim2.fromOffset(6, 0),
			Size = UDim2.fromOffset(16, ROW),
			TextColor3 = colors.muted,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = frame,
		})
		local avatar = UI.new("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 26, 0.5, 0),
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = colors.card,
			Parent = frame,
		}, { UI.corner(14) })
		task.spawn(function()
			if not thumbnails[other.UserId] then
				local ok, image = pcall(function()
					return Players:GetUserThumbnailAsync(
						other.UserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size48x48
					)
				end)
				thumbnails[other.UserId] = if ok then image else ""
			end
			avatar.Image = thumbnails[other.UserId]
		end)
		local name = text(other.DisplayName, 14, {
			Position = UDim2.fromOffset(62, 0),
			Size = UDim2.new(1, -150, 1, 0),
			Parent = frame,
		})
		local vip = UI.new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 46, 0, 9),
			Size = UDim2.fromOffset(14, 14),
			BackgroundTransparency = 1,
			Text = "👑",
			TextSize = 12,
			Visible = false,
			ZIndex = 2,
			Parent = frame,
		})
		local badge = UI.new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -66, 0.5, 0),
			Size = UDim2.fromOffset(28, 18),
			BackgroundColor3 = colors.gold,
			BackgroundTransparency = 0.75,
			FontFace = UI.fonts.heavy,
			TextSize = 11,
			TextColor3 = colors.gold,
			Visible = false,
			Parent = frame,
		}, { UI.corner(9) })
		local money = text("$0", 14, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 0),
			Size = UDim2.fromOffset(56, ROW),
			TextXAlignment = Enum.TextXAlignment.Right,
			FontFace = UI.fonts.heavy,
			TextColor3 = colors.money,
			Parent = frame,
		})
		rows[other] = { frame = frame, rank = rank, name = name, money = money, badge = badge, vip = vip }
	end

	local function stat(other: Player, key: string): number
		local stats = other:FindFirstChild("leaderstats")
		local value = stats and stats:FindFirstChild(key)
		return if value then value.Value else 0
	end

	local function refresh()
		local everyone = Players:GetPlayers()
		for _, other in everyone do
			if not rows[other] then
				makeRow(other)
			end
		end
		for other, row in rows do
			if not other.Parent then
				row.frame:Destroy()
				rows[other] = nil
			end
		end
		table.sort(everyone, function(a, b)
			return stat(a, "Money") > stat(b, "Money")
		end)
		for i, other in everyone do
			local row = rows[other]
			row.frame.LayoutOrder = i
			row.rank.Text = tostring(i)
			row.money.Text = Format.money(stat(other, "Money"))
			local rebirths = stat(other, "Rebirths")
			row.badge.Visible = rebirths > 0
			row.badge.Text = "R" .. rebirths
			local isVip = GamePasses.has(other, "VIP")
			row.vip.Visible = isVip
			row.name.TextColor3 = if isVip then colors.gold else colors.text
		end
		count.Text = #everyone .. "/" .. Config.PLOT_COUNT
	end

	refresh()
	Players.PlayerAdded:Connect(refresh)
	Players.PlayerRemoving:Connect(function()
		task.defer(refresh)
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			refresh()
		end
	end)
end

--------------------------------------------------------------------------------
-- VIP chat tag
--------------------------------------------------------------------------------

function Hud.vipChatTag()
	local TextChatService = game:GetService("TextChatService")
	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local properties = Instance.new("TextChatMessageProperties")
		local source = message.TextSource
		local sender = source and Players:GetPlayerByUserId(source.UserId)
		if sender and GamePasses.has(sender, "VIP") then
			properties.PrefixText = '<font color="#FFC83C">[VIP]</font> ' .. message.PrefixText
		end
		return properties
	end
end

--------------------------------------------------------------------------------
-- Gate status (locking happens at the padlock inside your yard)
--------------------------------------------------------------------------------

function Hud.gateStatus(screen: ScreenGui)
	local button = UI.new("Frame", {
		Name = "Gate",
		AnchorPoint = Vector2.new(0.5, 1),
		-- Sits above Roblox's tool hotbar, which takes the bottom-centre of the screen.
		Position = UDim2.new(0.5, 0, 1, -96),
		Size = UDim2.fromOffset(300, 52),
		BackgroundColor3 = colors.panel,
		BackgroundTransparency = UI.GLASS_TRANSPARENCY,
		Parent = screen,
	}, { UI.corner(26) })
	local ring = UI.stroke(colors.green, 2, 0.1)
	ring.Parent = button
	local label = text("", 18, {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = UI.fonts.heavy,
		Parent = button,
	})
	task.spawn(function()
		while true do
			local left = (player:GetAttribute("GateLockedUntil") or 0) - Workspace:GetServerTimeNow()
			if left > 0 and left < 1e9 then
				label.Text = "🔒  Locked · " .. Format.time(left)
				label.TextColor3 = colors.money
				ring.Color = colors.green
				button.BackgroundColor3 = colors.panel
			else
				-- Pulses red while open so the owner notices.
				local pulse = (math.sin(os.clock() * 6) + 1) / 2
				label.Text = "🔓  Barn open · Lock it at your door!"
				label.TextColor3 = colors.text
				ring.Color = colors.red
				button.BackgroundColor3 = colors.red:Lerp(Color3.fromRGB(120, 25, 35), pulse)
			end
			task.wait(0.05)
		end
	end)
end

--------------------------------------------------------------------------------
-- Notifications
--------------------------------------------------------------------------------

local TOAST_COLORS = {
	error = colors.red,
	success = colors.green,
	money = Color3.fromRGB(40, 165, 75),
	discovery = Color3.fromRGB(255, 160, 30),
}

-- Returns toast(message, kind?).
function Hud.toasts(screen: ScreenGui)
	local holder = UI.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 92), -- under the event banner
		Size = UDim2.new(0.5, 0, 0, 220),
		Parent = screen,
	}, {
		UI.new("UIListLayout", {
			Padding = UDim.new(0, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	return function(message: string, kind: string?)
		local accent = TOAST_COLORS[kind or ""] or colors.blue
		local big = kind == "discovery"
		local frame = UI.glass({
			Size = UDim2.fromOffset(0, if big then 48 else 38),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = accent,
			Parent = holder,
		}, {
			UI.corner(20),
			UI.new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 16) }),
			UI.new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 10),
			}),
		})
		local label = text(message, if big then 22 else 17, {
			Size = UDim2.fromOffset(0, 28),
			AutomaticSize = Enum.AutomaticSize.X,
			FontFace = if big then UI.fonts.heavy else UI.fonts.bold,
			TextColor3 = colors.text,
			Parent = frame,
		})
		label.TextTruncate = Enum.TextTruncate.None

		task.delay(if big then 7 else 3.5, function()
			local info = TweenInfo.new(0.35)
			TweenService:Create(frame, info, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(label, info, { TextTransparency = 1 }):Play()
			task.wait(0.35)
			frame:Destroy()
		end)
	end
end

return Hud
