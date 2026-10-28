-- Small helpers for building the UI in code (so there's nothing to set up in Studio).
-- Style: the juicy pixel-arcade shop look of the top Roblox simulators: dark slate windows
-- with a rainbow header full of halftone dots and falling sparkles, a big bouncing pixel
-- title, bright gradient cards with a halftone pattern and a spinning sunburst behind a
-- big 3D picture, tilted price tags, a gleam sweeping across titles, and chunky glossy
-- buttons that grow when hovered and squish when pressed. Every bit of text is white or
-- bright with a thick black outline.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local BoxModel = require(ReplicatedStorage.Shared.BoxModel)
local Lego = require(ReplicatedStorage.Shared.Lego)
local Items = require(ReplicatedStorage.Shared.Items)
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local ItemPictures = require(script.Parent.ItemPictures)

local UI = {}

local PIXEL = Font.fromEnum(Enum.Font.Arcade) -- Press Start 2P

UI.fonts = {
	regular = Font.fromEnum(Enum.Font.FredokaOne),
	bold = Font.fromEnum(Enum.Font.FredokaOne), -- longer text
	heavy = PIXEL, -- titles, buttons, tags and numbers
	pixel = PIXEL,
}

-- The dark outline around panels, buttons and text.
UI.OUTLINE = Color3.fromRGB(14, 14, 22)

UI.colors = {
	panel = Color3.fromRGB(62, 128, 245), -- HUD panels
	card = Color3.fromRGB(110, 170, 255),
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(180, 190, 220), -- hints
	dark = Color3.fromRGB(245, 246, 255), -- text on the dark window body
	green = Color3.fromRGB(70, 210, 90),
	blue = Color3.fromRGB(70, 140, 255),
	pink = Color3.fromRGB(255, 95, 170),
	orange = Color3.fromRGB(255, 160, 50),
	red = Color3.fromRGB(235, 60, 70),
	gray = Color3.fromRGB(105, 110, 130),
	money = Color3.fromRGB(110, 235, 140),
	gold = Color3.fromRGB(255, 205, 60),
	purple = Color3.fromRGB(160, 110, 240),
	sheet = Color3.fromRGB(50, 55, 72), -- window bodies
	sheetDark = Color3.fromRGB(36, 40, 54), -- section bands inside windows
	tab = Color3.fromRGB(36, 40, 54),
	ink = Color3.fromRGB(28, 26, 48),
	fusion = Color3.fromRGB(170, 80, 255),
	fusion2 = Color3.fromRGB(255, 80, 190),
}

-- The rainbow across window headers.
UI.RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 120, 255)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(40, 200, 220)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 225, 70)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 215, 40)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 130, 30)),
})

-- Bright card colours, picked by name so a card keeps its colour between refreshes.
local CARD_COLORS = {
	Color3.fromRGB(255, 70, 90),
	Color3.fromRGB(80, 215, 80),
	Color3.fromRGB(60, 150, 255),
	Color3.fromRGB(255, 150, 30),
	Color3.fromRGB(165, 90, 250),
	Color3.fromRGB(30, 200, 200),
	Color3.fromRGB(255, 90, 180),
	Color3.fromRGB(250, 200, 40),
}
function UI.cardColor(name: string): Color3
	local sum = 0
	for i = 1, #name do
		sum += string.byte(name, i) * i
	end
	return CARD_COLORS[sum % #CARD_COLORS + 1]
end

UI.GLASS_TRANSPARENCY = 0

--------------------------------------------------------------------------------
-- Animation: one RenderStepped loop runs every little effect (spinning sunbursts, title
-- gleams, bouncing letters, falling sparkles) while its frame is on screen.
--------------------------------------------------------------------------------

local animated = {} -- { { gui, step(gui, t, dt) } }
local animating = false

function UI.animate(gui: GuiObject, step: (any, number, number) -> ())
	table.insert(animated, { gui, step })
	if animating then
		return
	end
	animating = true
	RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()
		for i = #animated, 1, -1 do
			local entry = animated[i]
			local target = entry[1]
			if not target.Parent then
				table.remove(animated, i)
			elseif target.Visible then
				entry[2](target, t, dt)
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- Basics
--------------------------------------------------------------------------------

-- UI.new("Frame", { Size = ... }, { children... })
function UI.new(className: string, props, children)
	local instance = Instance.new(className)
	for key, value in props or {} do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	if props and props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

function UI.corner(radius: number?)
	return UI.new("UICorner", { CornerRadius = UDim.new(0, radius or 10) })
end

-- An outline around a frame; defaults to the thick dark cartoon outline.
function UI.stroke(color: Color3?, thickness: number?, transparency: number?)
	return UI.new("UIStroke", {
		Color = color or UI.OUTLINE,
		Thickness = thickness or 3,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	})
end

-- An outline around text (the chunky cartoon text look).
function UI.textStroke(thickness: number?)
	return UI.new("UIStroke", {
		Color = UI.OUTLINE,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Miter,
	})
end

-- Glossy shading: bright at the top, deeper at the bottom. It multiplies whatever colour
-- the frame is, so it works on any button or panel. (color/amount kept for old callers.)
function UI.gradient(_color: Color3?, amount: number?)
	local bottom = 1 - (amount or 0.3)
	return UI.new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.5, Color3.new(0.94, 0.94, 0.94)),
			ColorSequenceKeypoint.new(1, Color3.new(bottom, bottom, bottom)),
		}),
		Rotation = 90,
	})
end

-- A halftone of soft dots over a panel (the printed-comic texture on cards, banners and
-- headers). `w`/`h` are about how big the panel is, so there are enough dots to cover it.
function UI.pattern(parent: GuiObject, w: number?, h: number?, transparency: number?)
	local SPACING, DOT = 16, 6
	local holder = UI.new("Frame", {
		Name = "Pattern",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.new(1, -8, 1, -8),
		ClipsDescendants = true,
		ZIndex = parent.ZIndex,
		Parent = parent,
	}, {
		UI.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(DOT, DOT),
			CellPadding = UDim2.fromOffset(SPACING - DOT, SPACING - DOT),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingTop = UDim.new(0, 4) }),
	})
	local columns = math.ceil((w or 220) / SPACING)
	local rows = math.ceil((h or 280) / SPACING)
	for k = 1, columns * rows do
		local row = (k - 1) // columns
		UI.new("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			-- Fades out toward the bottom, like a printed halftone.
			BackgroundTransparency = (transparency or 0.7) + 0.2 * row / rows,
			BorderSizePixel = 0,
			ZIndex = parent.ZIndex,
			Parent = holder,
		}, { UI.corner(DOT) })
	end
	return holder
end

-- A slowly spinning sunburst of soft rays (behind pictures). Returns the frame, centred in
-- its parent; give it a square Size in pixels.
function UI.sunburst(parent: GuiObject, color: Color3?, transparency: number?)
	local burst = UI.new("Frame", {
		Name = "Sunburst",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = parent.ZIndex,
		Parent = parent,
	})
	for k = 0, 5 do
		UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.16, 1),
			Rotation = k * 30,
			BackgroundColor3 = color or Color3.new(1, 1, 1),
			BackgroundTransparency = transparency or 0.55,
			BorderSizePixel = 0,
			ZIndex = parent.ZIndex,
			Parent = burst,
		}, {
			UI.new("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		})
	end
	-- A soft glow in the middle.
	UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.55, 0.55),
		BackgroundColor3 = color or Color3.new(1, 1, 1),
		BackgroundTransparency = 0.6,
		ZIndex = parent.ZIndex,
		Parent = burst,
	}, { UI.corner(999) })
	UI.animate(burst, function(gui, _t, dt)
		gui.Rotation = (gui.Rotation + dt * 25) % 360
	end)
	return burst
end

-- A shine that sweeps across a text label every few seconds. `color` is the text's colour
-- (near-white by default); the shine is a brighter band moving over it.
function UI.gleam(label: TextLabel, color: Color3?, period: number?)
	local base = color or Color3.fromRGB(232, 236, 255)
	label.TextColor3 = Color3.new(1, 1, 1)
	local gradient = UI.new("UIGradient", {
		Rotation = 20,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, base),
			ColorSequenceKeypoint.new(0.4, base),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.6, base),
			ColorSequenceKeypoint.new(1, base),
		}),
		Offset = Vector2.new(-1, 0),
		Parent = label,
	})
	local every = period or 3
	local phase = math.random() * every
	UI.animate(label, function(_gui, t)
		local f = ((t + phase) % every) / every -- 0..1
		gradient.Offset = Vector2.new(-1 + f * 2.4, 0)
	end)
	return gradient
end

-- Grows a little when hovered and squishes when pressed (buttons and clickable cards).
function UI.juicy(button: GuiButton)
	local scale = button:FindFirstChildOfClass("UIScale") or UI.new("UIScale", { Parent = button })
	local info = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local hovered = false
	local function to(value: number)
		TweenService:Create(scale, info, { Scale = value }):Play()
	end
	button.MouseEnter:Connect(function()
		hovered = true
		to(1.08)
	end)
	button.MouseLeave:Connect(function()
		hovered = false
		to(1)
	end)
	button.MouseButton1Down:Connect(function()
		to(0.9)
	end)
	button.MouseButton1Up:Connect(function()
		to(if hovered then 1.08 else 1)
	end)
	return scale
end

-- A bright cartoon panel with a thick outline (the name is from the old glass style).
function UI.glass(props, children)
	local frame = UI.new("Frame", {
		BackgroundColor3 = UI.colors.panel,
		BackgroundTransparency = UI.GLASS_TRANSPARENCY,
	}, { UI.corner(12), UI.stroke(nil, 3.5), UI.gradient() })
	for key, value in props or {} do
		if key ~= "Parent" then
			frame[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = frame
	end
	if props and props.Parent then
		frame.Parent = props.Parent
	end
	return frame
end

function UI.label(text: string, props)
	local label = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = UI.fonts.bold,
		Text = text,
		TextColor3 = UI.colors.text,
		TextScaled = true,
		Size = UDim2.new(1, 0, 0, 24),
	}, { UI.textStroke(1.8) })
	for key, value in props or {} do
		label[key] = value
	end
	return label
end

-- Text on a window body (white, outlined).
function UI.text(text: string, props)
	local label = UI.label(text, { TextColor3 = UI.colors.dark })
	for key, value in props or {} do
		label[key] = value
	end
	return label
end

-- Big pixel text (titles, numbers).
function UI.pixel(text: string, props)
	local label = UI.label(text, { FontFace = UI.fonts.pixel })
	label.UIStroke.Thickness = 2.5
	for key, value in props or {} do
		label[key] = value
	end
	return label
end

-- A chunky glossy button: bright fill shaded top to bottom, thick black outline, white
-- outlined pixel text; grows when hovered and squishes when pressed.
function UI.button(text: string, color: Color3, onClick: () -> (), props)
	local button = UI.new("TextButton", {
		BackgroundColor3 = color,
		FontFace = UI.fonts.pixel,
		Text = text,
		TextColor3 = UI.colors.text,
		TextScaled = true,
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 30),
	}, {
		UI.corner(10),
		UI.gradient(nil, 0.32),
		UI.stroke(nil, 3),
		UI.textStroke(2.2),
		UI.new("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
	})
	for key, value in props or {} do
		button[key] = value
	end
	UI.juicy(button)
	button.Activated:Connect(onClick)
	return button
end

-- A little 3D picture of a Mystery Box.
function UI.boxViewport(crateId: string, size: number?)
	local frame = UI.new("ViewportFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, size or 100),
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

-- A price button: green and glossy, the price in white pixel text.
function UI.pricePill(text: string, onClick: () -> (), props)
	return UI.button(text, UI.colors.green, onClick, props)
end

-- A tilted tag on a card's corner: "NEW", "BEST", "x2"...
function UI.tag(parent: GuiObject, text: string, color: Color3?)
	local tag = UI.new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 6, 0, 30), -- beside the picture, clear of the title
		Size = UDim2.fromOffset(64, 26),
		Rotation = 12,
		BackgroundColor3 = color or UI.colors.red,
		FontFace = UI.fonts.pixel,
		Text = text,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = (parent.ZIndex or 1) + 5,
		Parent = parent,
	}, {
		UI.corner(6),
		UI.gradient(),
		UI.stroke(nil, 2.5),
		UI.textStroke(1.8),
		UI.new("UIPadding", {
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5),
			PaddingTop = UDim.new(0, 5),
			PaddingBottom = UDim.new(0, 5),
		}),
	})
	return tag
end

-- A tilted price written straight on a card (like "119R" on the shop cards).
function UI.priceTag(parent: GuiObject, text: string, left: boolean, color: Color3?)
	return UI.pixel(text, {
		Name = "PriceTag",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(if left then 0.14 else 0.86, 0, 0.4, 0),
		Size = UDim2.fromOffset(56, 16),
		Rotation = if left then 30 else -30,
		TextColor3 = color or UI.colors.money,
		ZIndex = (parent.ZIndex or 1) + 3,
		Parent = parent,
	})
end

-- A bright patterned card (like the top simulators' shops): a gradient in the card's
-- colour under a halftone, the title in white pixel text, a big picture on a spinning
-- sunburst, then text lines and buttons. opts: accent (colour), border (a highlight
-- outline, e.g. owned), picture (an ItemPictures key) / part (any item id, + mutations,
-- silhouette) / egg (a zone index, + eggItem for what's inside) / box, lines = { { text,
-- colour?, height? } }, buttons, tag = { text, colour? }, price (tilted price text on both
-- sides of the picture), onClick, size = { w, h } (for the halftone).
function UI.card(opts)
	local title = opts.lines and opts.lines[1] and opts.lines[1][1] or ""
	local accent = opts.accent
	if not accent and opts.part then
		local part = Items.byId[opts.part]
		local rarity = part and part.rarity
		if rarity and rarity ~= "Common" then
			accent = Rarities.info[rarity].color
		end
	end
	accent = accent or (if opts.part then Color3.fromRGB(70, 150, 255) else UI.cardColor(title))
	if opts.background then
		accent = opts.background
	end

	-- Clickable cards are buttons; buttons inside them still get their own clicks.
	local card = UI.new(if opts.onClick then "TextButton" else "Frame", {
		BackgroundColor3 = accent,
	}, {
		UI.corner(12),
		if opts.border then UI.stroke(opts.border, 4.5) else UI.stroke(nil, 3.5),
		UI.new("UIGradient", {
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 160)),
			Rotation = 90,
		}),
	})
	UI.pattern(card, opts.size and opts.size[1], opts.size and opts.size[2])
	local content = UI.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = card,
	}, {
		UI.new("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
		UI.new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 3),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	})

	if opts.onClick then
		card.Text = ""
		card.AutoButtonColor = false
		UI.juicy(card)
	end

	local order = 0
	local function add(child)
		order += 1
		child.LayoutOrder = order
		child.Parent = content
	end

	-- The title on top, in white pixel letters.
	local lines = opts.lines or {}
	if lines[1] then
		add(UI.pixel(lines[1][1], {
			TextColor3 = lines[1][2] or Color3.new(1, 1, 1),
			Size = UDim2.new(1, 0, 0, math.max(lines[1][3] or 22, 20)),
		}))
	end

	-- The picture, on a spinning sunburst.
	local picture
	if opts.picture then
		picture = ItemPictures.view(opts.picture, opts.pictureHeight)
	elseif opts.box then
		picture = UI.boxViewport(opts.box)
	elseif opts.part then
		picture = ItemPictures.part(opts.part, opts.pictureHeight, opts.silhouette, opts.mutations)
	elseif opts.egg then
		picture = ItemPictures.egg(opts.egg, opts.pictureHeight, opts.eggItem)
	end
	if picture then
		local holder = UI.new("Frame", {
			BackgroundTransparency = 1,
			Size = picture.Size,
		})
		local side = picture.Size.Y.Offset * 1.15
		UI.sunburst(holder).Size = UDim2.fromOffset(side, side)
		picture.Size = UDim2.fromScale(1, 1)
		picture.Parent = holder
		if opts.price then
			UI.priceTag(holder, opts.price, true)
			UI.priceTag(holder, opts.price, false)
		end
		add(holder)
	end

	for i = 2, #lines do
		local line = lines[i]
		add(UI.label(line[1], {
			TextColor3 = line[2] or UI.colors.text,
			Size = UDim2.new(1, 0, 0, line[3] or 18),
		}))
	end
	for _, button in opts.buttons or {} do
		add(button)
	end
	if opts.tag then
		UI.tag(card, opts.tag[1], opts.tag[2])
	end

	if opts.onClick then
		card.Activated:Connect(opts.onClick)
	end

	return card
end

-- A grid that grows to fit its cards.
function UI.grid(cellWidth: number, cellHeight: number)
	return UI.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		UI.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(cellWidth, cellHeight),
			CellPadding = UDim2.fromOffset(12, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	})
end

return UI
