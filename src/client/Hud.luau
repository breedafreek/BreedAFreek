-- The always-on screen pieces, in the UI.luau style: money and Speed as big outlined
-- numbers with an icon (no panel behind them), the side menu of square coloured tiles,
-- a dark pill at the top centre (the zone you walked into, or the egg you're carrying),
-- and short messages from the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Format = require(ReplicatedStorage.Shared.Format)
local Items = require(ReplicatedStorage.Shared.Items)
local ZoneLayout = require(ReplicatedStorage.Shared.ZoneLayout)
local ItemPictures = require(script.Parent.ItemPictures)
local UI = require(script.Parent.UI)

local colors = UI.colors
local player = Players.LocalPlayer

local Hud = {}

-- A 3D icon (an ItemPictures key) in a square.
local function icon(key: string, size: number, props)
	local view = ItemPictures.icon(key)
	view.Size = UDim2.fromOffset(size, size)
	for k, v in props or {} do
		view[k] = v
	end
	return view
end

-- A number that glides to its new value instead of jumping.
local function glide(label: TextLabel, read: () -> number, show: (number) -> string)
	local shown = read()
	RunService.RenderStepped:Connect(function(dt)
		local target = read()
		shown += (target - shown) * math.min(1, dt * 8)
		if math.abs(target - shown) < 1 then
			shown = target
		end
		label.Text = show(shown)
	end)
end

--------------------------------------------------------------------------------
-- Money and Speed (bottom left, above nothing: just icons and outlined numbers)
--------------------------------------------------------------------------------

function Hud.stats(screen: ScreenGui)
	local holder = UI.new("Frame", {
		Name = "Stats",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 14, 1, -18),
		Size = UDim2.fromOffset(300, 140),
		BackgroundTransparency = 1,
		Parent = screen,
	})

	-- Speed: a lightning bolt and the number in blue.
	icon("Bolt", 40, { Position = UDim2.fromOffset(0, 0), Parent = holder })
	local speed = UI.text("0", 30, {
		Position = UDim2.fromOffset(46, 4),
		Size = UDim2.fromOffset(240, 34),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = colors.speed,
		Parent = holder,
	})
	glide(speed, function()
		return player:GetAttribute("Speed") or 0
	end, function(n)
		local training = player:GetAttribute("Training") == true
		return Format.number(n) .. (if training then "  TRAINING!" else "")
	end)

	-- Money: a stack of cash and the number in green, what you earn under it.
	icon("Cash", 54, { Position = UDim2.fromOffset(-4, 46), Parent = holder })
	local money = UI.text("$0", 42, {
		Position = UDim2.fromOffset(56, 48),
		Size = UDim2.fromOffset(240, 46),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = colors.money,
		Parent = holder,
	})
	glide(money, function()
		return player:GetAttribute("Money") or 0
	end, Format.money)
	local income = UI.text("Earning: $0/s", 18, {
		Position = UDim2.fromOffset(4, 104),
		Size = UDim2.fromOffset(290, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})
	local function updateIncome()
		income.Text = "Earning: " .. Format.money(player:GetAttribute("Income") or 0) .. "/s"
	end
	player:GetAttributeChangedSignal("Income"):Connect(updateIncome)
	updateIncome()
end

--------------------------------------------------------------------------------
-- Side menu
--------------------------------------------------------------------------------

-- Two columns of square tiles: a bright colour (top half lighter), a big 3D icon, the name
-- overlapping the bottom edge, and a red "!" badge when something is waiting there.
-- entries = { { name, label, colour, iconKey } }. Returns setBadge(name, on).
function Hud.menu(screen: ScreenGui, entries, onSelect: (string) -> ())
	local TILE, GAP = 70, 12
	local rows = math.ceil(#entries / 2)
	local rail = UI.new("Frame", {
		Name = "Menu",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.45, 0),
		Size = UDim2.fromOffset(TILE * 2 + GAP, rows * (TILE + GAP)),
		BackgroundTransparency = 1,
		Parent = screen,
	}, {
		UI.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(TILE, TILE),
			CellPadding = UDim2.fromOffset(GAP, GAP),
			FillDirectionMaxCells = 2,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	-- Shrinks on short screens so it never runs off the edge.
	local fit = UI.new("UIScale", { Parent = rail })
	local function refit()
		local available = Workspace.CurrentCamera.ViewportSize.Y * 0.62
		fit.Scale = math.clamp(available / rail.Size.Y.Offset, 0.6, 1)
	end
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
	refit()

	local badges = {}
	for i, entry in entries do
		local name, label, color, iconKey = entry[1], entry[2], entry[3], entry[4]
		local tile = UI.new("TextButton", {
			Name = name,
			AutoButtonColor = false,
			Text = "",
			BackgroundColor3 = color,
			LayoutOrder = i,
			Parent = rail,
		}, {
			UI.corner(6),
			UI.stroke(3),
			UI.new("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(0.501, Color3.new(0.85, 0.85, 0.85)),
					ColorSequenceKeypoint.new(1, Color3.new(0.85, 0.85, 0.85)),
				}),
			}),
		})
		if ItemPictures.has(iconKey) then
			icon(iconKey, TILE - 12, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.42, 0),
				Parent = tile,
			})
		end
		UI.text(label, 18, {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 4),
			Size = UDim2.new(1, 10, 0, 22),
			ZIndex = 2,
			Parent = tile,
		})
		badges[name] = UI.text("!", 20, {
			Name = "Badge",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -4, 0, 4),
			Size = UDim2.fromOffset(24, 24),
			BackgroundColor3 = colors.red,
			BackgroundTransparency = 0,
			Visible = false,
			ZIndex = 3,
			Parent = tile,
		})
		UI.corner(12).Parent = badges[name]
		UI.stroke(2.5).Parent = badges[name]
		UI.hover(tile, 1.08)
		tile.Activated:Connect(function()
			onSelect(name)
		end)
	end
	return function(name: string, on: boolean)
		if badges[name] then
			badges[name].Visible = on
		end
	end
end

--------------------------------------------------------------------------------
-- Top pill: the zone you just walked into, or the egg you're carrying
--------------------------------------------------------------------------------

function Hud.topPill(screen: ScreenGui)
	local pill = UI.new("Frame", {
		Name = "TopPill",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Visible = false,
		Parent = screen,
	}, {
		UI.corner(8),
		UI.stroke(2.5),
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
	})
	local label = UI.text("", 22, {
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		TextScaled = false,
		TextSize = 22,
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
			show("🥚 " .. carrying .. " · Run home!", colors.gold)
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
							.. info.name
							.. (if fast then " · Grab an egg!" else " · Needs ⚡" .. Format.number(info.speed)),
						if fast then colors.white else Color3.fromRGB(255, 120, 120)
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
	error = Color3.fromRGB(255, 110, 110),
	discovery = UI.colors.gold,
}

-- Short messages under the top pill, fading out after a few seconds. Returns show(text,
-- kind).
function Hud.messages(screen: ScreenGui)
	local holder = UI.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 60),
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
		local label = UI.text(message, 24, {
			Size = UDim2.new(1, 0, 0, 30),
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
