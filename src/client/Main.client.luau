-- The player's client: the screen UI (HUD, side menu and windows, built from UI.luau and
-- Hud.luau; being rebuilt window by window), the world effects (guardians, attacks, pets,
-- treadmill running, ambience, events, flashing secret eggs) and the bits of gameplay
-- that live on the client. The server is the source of truth; this shows state and sends
-- requests.

local CollectionService = game:GetService("CollectionService")
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
local EggModel = require(Shared.EggModel)
local Format = require(Shared.Format)
local GamePasses = require(Shared.GamePasses)
local Items = require(Shared.Items)
local Remotes = require(Shared.Remotes)
local Ambient = require(script.Parent.Ambient)
local EventFX = require(script.Parent.EventFX)
local GuardianAttackFX = require(script.Parent.GuardianAttackFX)
local GuardianFX = require(script.Parent.GuardianFX)
local Hud = require(script.Parent.Hud)
local ItemPictures = require(script.Parent.ItemPictures)
local PetFX = require(script.Parent.PetFX)
local TreadmillRun = require(script.Parent.TreadmillRun)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

EventFX.start()

--------------------------------------------------------------------------------
-- Screen UI (UI.luau style): the HUD, the side menu and the windows
--------------------------------------------------------------------------------

local colors = UI.colors
local actionRemote = Remotes.get("Action")
local function send(action: string, ...)
	actionRemote:FireServer(action, ...)
end

local state = nil

local screen = UI.new("ScreenGui", {
	Name = "StealALifeUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})
Hud.stats(screen)
Hud.topPill(screen)
local message = Hud.messages(screen)
Remotes.get("Notify").OnClientEvent:Connect(function(text: string, kind: string?)
	message(text, kind)
end)

-- The one window, reused by every menu button.
local currentWindow = nil
local openWindow
local window, content, setHeader = UI.window({
	Name = "Window",
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.56, 0.7),
	ZIndex = 5,
	Parent = screen,
}, function()
	openWindow(currentWindow)
end)
UI.new("UISizeConstraint", { MaxSize = Vector2.new(780, 560), Parent = window })
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
local function render()
	if not currentWindow or not state then
		return
	end
	for _, child in body:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	renderers[currentWindow]()
end

-- A section title in the window.
local function section(text: string, order: number)
	return UI.text(text, 22, {
		Size = UDim2.new(1, 0, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order,
		ZIndex = 6,
		Parent = body,
	})
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

-- A slot: label on top, picture in the middle, value at the bottom, and a button under
-- that if there is one. `picture` is a ViewportFrame (or nil).
local function slot(parent, order, label, picture, value, valueColor, gold, button)
	local cell = UI.cell({ LayoutOrder = order, ZIndex = 6, Parent = parent }, gold)
	local bottom = if button then 58 else 6
	UI.text(label, 20, {
		Position = UDim2.fromOffset(6, 8),
		Size = UDim2.new(1, -12, 0, 22),
		ZIndex = 7,
		Parent = cell,
	})
	if picture then
		picture.AnchorPoint = Vector2.new(0.5, 0)
		picture.Position = UDim2.new(0.5, 0, 0, 34)
		picture.Size = UDim2.new(1, -16, 1, -34 - 30 - bottom)
		picture.ZIndex = 7
		picture.Parent = cell
	end
	UI.text(value, 20, {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 6, 1, -bottom - 4),
		Size = UDim2.new(1, -12, 0, 24),
		TextColor3 = valueColor or colors.white,
		ZIndex = 7,
		Parent = cell,
	})
	if button then
		button.AnchorPoint = Vector2.new(0.5, 1)
		button.Position = UDim2.new(0.5, 0, 1, -8)
		button.Size = UDim2.new(1, -16, 0, 44)
		button.ZIndex = 7
		button.Label.ZIndex = 8
		button.Parent = cell
	end
	return cell
end

--------------------------------------------------------------------------------
-- Shop: the treadmill, plot and house upgrades, and the zones
--------------------------------------------------------------------------------

local function speedGain(level: number): number
	return Config.treadmillGain(level) * GamePasses.speedMultiplier(player)
end

-- An upgrade slot: name and level, picture, what you get, and the price to buy.
local function upgradeSlot(parent, order, name, level, maxLevel, pictureKey, value, cost, action)
	local maxed = level >= maxLevel
	local canAfford = not maxed and (state.money or 0) >= cost
	local button = if maxed
		then UI.button("MAX", colors.gray, function() end)
		else UI.button(Format.money(cost), if canAfford then colors.green else colors.gray, function()
			send(action)
		end)
	return slot(
		parent,
		order,
		name .. "  Lv " .. level,
		ItemPictures.view(pictureKey),
		value,
		colors.speed,
		canAfford,
		button
	)
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

	-- The zones: their egg and the Speed each needs. The deepest one you can do is gold.
	section("Zones", 3)
	local speed = player:GetAttribute("Speed") or state.speed or 0
	local best = 1
	for i, zone in Items.ZONES do
		if speed >= zone.speed then
			best = i
		end
	end
	local zones = grid(4, UDim2.new(1 / 5, -8, 0, 168))
	for i, zone in Items.ZONES do
		local fast = speed >= zone.speed
		slot(
			zones,
			i,
			zone.name,
			ItemPictures.egg(i),
			"⚡ " .. (if zone.speed > 0 then Format.number(zone.speed) else "Any"),
			if fast then colors.money else Color3.fromRGB(255, 110, 110),
			i == best
		)
	end
end

-- Windows that haven't been rebuilt yet.
local function comingSoon()
	UI.text("Coming soon!", 30, {
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = 1,
		ZIndex = 6,
		Parent = body,
	})
end
for _, name in { "Luck", "Life", "Bag", "Index", "Store" } do
	renderers[name] = comingSoon
end

-- The side menu: name, label, colour, icon.
local MENU = {
	{ "Shop", "SHOP", Color3.fromRGB(235, 60, 70), "MenuShop", "🛒" },
	{ "Luck", "LUCK", Color3.fromRGB(110, 205, 50), "MenuLuck", "🍀" },
	{ "Life", "HOME", Color3.fromRGB(60, 140, 240), "MenuLife", "🏡" },
	{ "Bag", "BAG", Color3.fromRGB(245, 150, 40), "MenuBag", "🎒" },
	{ "Index", "INDEX", Color3.fromRGB(40, 185, 200), "MenuCatalog", "📖" },
	{ "Store", "STORE", Color3.fromRGB(165, 90, 240), "MenuStore", "💎" },
	{ "Home", "TP", Color3.fromRGB(250, 200, 40), "MenuHome", "🚪" },
}
local MENU_BY_NAME = {}
for _, entry in MENU do
	MENU_BY_NAME[entry[1]] = entry
end

openWindow = function(name: string?)
	if not name or currentWindow == name then
		currentWindow = nil
		window.Visible = false
		return
	end
	currentWindow = name
	local entry = MENU_BY_NAME[name]
	setHeader(entry[5], name, entry[3])
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

local setBadge = Hud.menu(screen, MENU, function(name: string)
	if name == "Home" then
		send("GoHome") -- not a window: takes you back to your house
	else
		openWindow(name)
	end
end)

-- The Shop's "!" when you can afford an upgrade.
local function updateBadges()
	if not state then
		return
	end
	local money = state.money or 0
	local level, plotLevel, houseLevel = state.treadmill or 1, state.plotLevel or 1, state.houseLevel or 1
	setBadge(
		"Shop",
		(level < Config.TREADMILL_MAX and money >= Config.treadmillCost(level))
			or (plotLevel < Config.PLOT_MAX and money >= Config.plotCost(plotLevel))
			or (houseLevel < Config.HOUSE_MAX and money >= Config.houseCost(houseLevel))
	)
end

Remotes.get("State").OnClientEvent:Connect(function(newState)
	state = newState
	updateBadges()
	render()
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
GuardianAttackFX.start()
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
			glow.Transparency = 0.25 + 0.5 * (1 - flash)
		end
		if light and light:IsA("PointLight") then
			light.Color = color
			light.Brightness = 1.5 + 4 * flash
		end
	end
end)

state = Remotes.get("GetState"):InvokeServer()
updateBadges()
print("[Steal a Life] Client ready")
clientReady = true
