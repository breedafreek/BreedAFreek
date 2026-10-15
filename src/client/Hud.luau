-- The always-on-screen parts of the UI: money, event chip, menu tabs, leaderboard,
-- gate button and pop-up notifications. Windows (Shop, Freeks, ...) live in Main.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local Luck = require(ReplicatedStorage.Shared.Luck)
local Seasons = require(ReplicatedStorage.Shared.Seasons)
local Icons = require(script.Parent.Icons)
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
	-- Bottom left, like the big simulators: a 3D cash stack and a huge green number,
	-- with the income and any rebirth boost in a pill above it.
	local holder = UI.new("Frame", {
		Name = "Money",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, -10),
		Size = UDim2.fromOffset(330, 96),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	local icon = UI.modelIcon(Icons.build("Money"), UDim2.fromOffset(70, 70), math.rad(-25))
	icon.AnchorPoint = Vector2.new(0, 1)
	icon.Position = UDim2.new(0, 0, 1, 4)
	icon.Parent = holder
	local amount = text("$0", 44, {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 72, 1, -4),
		Size = UDim2.new(1, -72, 0, 50),
		FontFace = UI.fonts.heavy,
		TextColor3 = colors.money,
		Parent = holder,
	})
	amount:FindFirstChildOfClass("UIStroke").Thickness = 3.5
	local pill = UI.new("Frame", {
		Position = UDim2.fromOffset(4, 0),
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = UI.OUTLINE,
		BackgroundTransparency = 0.35,
		Parent = holder,
	}, {
		UI.corner(15),
		UI.stroke(nil, 2.5),
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local income = text("+$0/s", 18, {
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		FontFace = UI.fonts.heavy,
		TextColor3 = Color3.fromRGB(255, 240, 150),
		LayoutOrder = 1,
		Parent = pill,
	})
	local boost = text("", 18, {
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		FontFace = UI.fonts.heavy,
		TextColor3 = Color3.fromRGB(255, 120, 200),
		Visible = false,
		LayoutOrder = 2,
		Parent = pill,
	})

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
		boost.Text = "Rebirth Boost x" .. tostring(Config.incomeMultiplier(rebirths))
	end
end

--------------------------------------------------------------------------------
-- Event chip
--------------------------------------------------------------------------------

function Hud.eventChip(screen: ScreenGui)
	local chip = UI.glass({
		Name = "Event",
		Position = UDim2.fromOffset(12, 8),
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
		Position = UDim2.fromOffset(12, 42),
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
-- Menu tabs
--------------------------------------------------------------------------------

-- The menu: big 3D icons with outlined labels, down the left and right edges of the
-- screen (no tiles behind them). entries = { { name, label, side } } where side is
-- "left" or "right". Returns setActive(name or nil).
function Hud.menu(screen: ScreenGui, entries, onSelect: (string) -> ())
	local ICON = 74
	local ITEM = 96
	local function column(side: string)
		local count = 0
		for _, entry in entries do
			if entry[3] == side then
				count += 1
			end
		end
		local height = count * ITEM + (count - 1) * 4
		local frame = UI.new("Frame", {
			Name = "Menu" .. side,
			AnchorPoint = Vector2.new(if side == "left" then 0 else 1, 0.5),
			Position = if side == "left" then UDim2.new(0, 6, 0.5, -10) else UDim2.new(1, -6, 0.56, 0),
			Size = UDim2.fromOffset(ICON + 16, height),
			BackgroundTransparency = 1,
			Parent = screen,
		}, {
			UI.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		fitHeight(frame, height, 200)
		return frame
	end
	local columns = { left = column("left"), right = column("right") }

	local labels = {}
	for i, entry in entries do
		local name, title, side = entry[1], entry[2], entry[3]
		local button = UI.new("TextButton", {
			Name = name,
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(ICON + 16, ITEM),
			LayoutOrder = i,
			Parent = columns[side],
		})
		local icon = UI.modelIcon(Icons.build(name), UDim2.fromOffset(ICON, ICON), math.rad(-20))
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.new(0.5, 0, 0, 0)
		icon.Parent = button
		local label = text(title, 20, {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.new(1, 8, 0, 24),
			TextXAlignment = Enum.TextXAlignment.Center,
			FontFace = UI.fonts.heavy,
			Parent = button,
		})
		label:FindFirstChildOfClass("UIStroke").Thickness = 2.6
		labels[name] = label
		hoverGrow(button)
		button.Activated:Connect(function()
			onSelect(name)
		end)
	end

	return function(active: string?)
		for name, label in labels do
			label.TextColor3 = if name == active then colors.gold else colors.text
		end
	end
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
		Position = UDim2.new(0.5, 0, 0, 12),
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
