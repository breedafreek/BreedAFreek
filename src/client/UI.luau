-- The building blocks of the screen UI, in one style (the owner's references: a top
-- simulator's HUD and its "Daily Rewards" window):
-- - Chunky text: Luckiest Guy (UI.heavy) for buttons, titles and numbers; Fredoka One
--   (UI.text) for small labels. White or a bright colour, always with a dark outline.
-- - The HUD floats on the world with no panels behind it: wide bright buttons (UI.wideButton)
--   with a stud-dot texture, an icon and a chunky label; big outlined numbers with an icon.
-- - Windows (UI.window): a dark see-through body with a thin outline and nearly square
--   corners under a flat coloured header (icon, title, red square X).
-- - Slots (UI.cell): dark cells; the one that matters gets a gold outline.
-- - Buttons: bright, the top half lighter than the bottom, dark outline. Everything you can
--   press grows a little when hovered and dips when pressed.
-- Pictures are our own 3D models (ItemPictures) or emoji, never uploaded images.

local TweenService = game:GetService("TweenService")

local UI = {}

UI.FONT = Font.fromEnum(Enum.Font.FredokaOne)
UI.HEAVY = Font.fromEnum(Enum.Font.LuckiestGuy)
UI.OUTLINE = Color3.fromRGB(22, 20, 26)
UI.fonts = { regular = UI.FONT, bold = UI.FONT, heavy = UI.HEAVY }

UI.colors = {
	white = Color3.fromRGB(255, 255, 255),
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(190, 190, 200),
	money = Color3.fromRGB(110, 240, 70),
	speed = Color3.fromRGB(255, 205, 50),
	gold = Color3.fromRGB(255, 205, 45),
	green = Color3.fromRGB(110, 210, 30),
	lime = Color3.fromRGB(150, 225, 30),
	red = Color3.fromRGB(230, 50, 50),
	blue = Color3.fromRGB(40, 150, 245),
	orange = Color3.fromRGB(250, 160, 30),
	purple = Color3.fromRGB(160, 90, 240),
	pink = Color3.fromRGB(245, 90, 170),
	gray = Color3.fromRGB(120, 120, 128),
	card = Color3.fromRGB(70, 70, 80),
	body = Color3.fromRGB(28, 28, 32), -- window bodies (see-through)
	cell = Color3.fromRGB(52, 52, 58), -- slots
	fusion = Color3.fromRGB(170, 80, 255),
	fusion2 = Color3.fromRGB(255, 80, 190),
}

-- Bright colours, picked by name so a thing keeps its colour between refreshes.
local NAMED = {
	Color3.fromRGB(245, 90, 170),
	Color3.fromRGB(110, 210, 30),
	Color3.fromRGB(40, 150, 245),
	Color3.fromRGB(250, 160, 30),
	Color3.fromRGB(160, 90, 240),
	Color3.fromRGB(30, 195, 190),
}
function UI.cardColor(name: string): Color3
	local sum = 0
	for i = 1, #name do
		sum += string.byte(name, i) * i
	end
	return NAMED[sum % #NAMED + 1]
end

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
	return UI.new("UICorner", { CornerRadius = UDim.new(0, radius or 6) })
end

-- The dark outline round a frame.
function UI.stroke(thickness: number?, color: Color3?)
	return UI.new("UIStroke", {
		Color = color or UI.OUTLINE,
		Thickness = thickness or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	})
end

local function textStroke(size: number)
	return UI.new("UIStroke", {
		Color = UI.OUTLINE,
		Thickness = if size >= 36 then 3.5 elseif size >= 24 then 3 elseif size >= 16 then 2.2 else 1.6,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Round,
	})
end

-- An outline round text (for labels built by hand).
function UI.textStroke(thickness: number?)
	local stroke = textStroke(20)
	stroke.Thickness = thickness or 2
	return stroke
end

-- Text: Fredoka One, white (or `color`), dark outline, `size` px (it shrinks to fit its box,
-- never grows past `size`).
function UI.text(text: string, size: number, props)
	local label = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = UI.FONT,
		Text = text,
		TextColor3 = UI.colors.white,
		TextScaled = true,
		Size = UDim2.new(1, 0, 0, size + 4),
	}, {
		textStroke(size),
		UI.new("UITextSizeConstraint", { MaxTextSize = size }),
	})
	for key, value in props or {} do
		label[key] = value
	end
	return label
end

-- Chunky text: Luckiest Guy, for buttons, titles and big numbers.
function UI.heavy(text: string, size: number, props)
	local label = UI.text(text, size, { FontFace = UI.HEAVY })
	for key, value in props or {} do
		label[key] = value
	end
	return label
end

-- Old-style label (fills its box), kept for the reveal animations.
function UI.label(text: string, props)
	local label = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = UI.FONT,
		Text = text,
		TextColor3 = UI.colors.white,
		TextScaled = true,
		Size = UDim2.new(1, 0, 0, 24),
	}, { textStroke(20) })
	for key, value in props or {} do
		label[key] = value
	end
	return label
end

-- Grows a little when hovered and dips when pressed.
function UI.hover(button: GuiButton, grow: number?)
	local scale = UI.new("UIScale", { Parent = button })
	local info = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local over = false
	local function to(value: number)
		TweenService:Create(scale, info, { Scale = value }):Play()
	end
	button.MouseEnter:Connect(function()
		over = true
		to(grow or 1.06)
	end)
	button.MouseLeave:Connect(function()
		over = false
		to(1)
	end)
	button.MouseButton1Down:Connect(function()
		to(0.94)
	end)
	button.MouseButton1Up:Connect(function()
		to(if over then grow or 1.06 else 1)
	end)
	return scale
end

-- The two-tone shine on buttons and tiles: the top half lighter than the bottom.
function UI.twoTone(dark: number?)
	local d = dark or 0.84
	return UI.new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.501, Color3.new(d, d, d)),
			ColorSequenceKeypoint.new(1, Color3.new(d, d, d)),
		}),
	})
end

-- A texture of little stud dots over a button or tile (like LEGO studs). `w`/`h` are about
-- how big it is, so there are enough dots.
function UI.dots(parent: GuiObject, w: number, h: number)
	local GAP, DOT = 11, 5
	local holder = UI.new("Frame", {
		Name = "Dots",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
		ZIndex = parent.ZIndex,
		Parent = parent,
	}, {
		UI.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(DOT, DOT),
			CellPadding = UDim2.fromOffset(GAP - DOT, GAP - DOT),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingTop = UDim.new(0, 3) }),
	})
	for _ = 1, math.ceil(w / GAP) * math.ceil(h / GAP) do
		UI.new("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
			ZIndex = parent.ZIndex,
			Parent = holder,
		}, { UI.corner(2) })
	end
	return holder
end

-- A red count badge on a button's top-right corner. Returns set(text or nil).
function UI.badge(parent: GuiObject)
	local badge = UI.heavy("", 18, {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -4, 0, 4),
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = UI.colors.red,
		BackgroundTransparency = 0,
		Visible = false,
		ZIndex = parent.ZIndex + 3,
		Parent = parent,
	})
	UI.corner(15).Parent = badge
	UI.stroke(2.5, Color3.new(1, 1, 1)).Parent = badge
	return function(text: string?)
		badge.Visible = text ~= nil
		badge.Text = text or ""
	end
end

-- A button: bright `color` (top half lighter), dark outline, chunky white outlined text.
function UI.button(text: string, color: Color3, onClick: () -> (), props)
	local button = UI.new("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = color,
		Text = "",
		Size = UDim2.fromOffset(160, 50),
	}, { UI.corner(6), UI.stroke(3), UI.twoTone() })
	UI.heavy(text, 26, {
		Name = "Label",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 2),
		Size = UDim2.new(1, -14, 1, -12),
		Parent = button,
	})
	for key, value in props or {} do
		button[key] = value
	end
	UI.hover(button)
	button.Activated:Connect(onClick)
	return button
end

-- A wide HUD button like the reference's PLOT / SHOP: a bright colour with stud dots, an
-- icon on the left (an emoji, or a picture GuiObject) and a chunky label. opts = { text,
-- color, icon, size = Vector2 (default 210 x 58), onClick }. Returns the button and
-- setBadge(text or nil).
function UI.wideButton(opts)
	local size = opts.size or Vector2.new(210, 58)
	local button = UI.new("TextButton", {
		Name = opts.name or opts.text,
		AutoButtonColor = false,
		BackgroundColor3 = opts.color,
		Text = "",
		Size = UDim2.fromOffset(size.X, size.Y),
	}, { UI.corner(4), UI.stroke(3), UI.twoTone(0.86) })
	UI.dots(button, size.X, size.Y)
	local iconSize = size.Y - 8
	if typeof(opts.icon) == "Instance" then
		opts.icon.AnchorPoint = Vector2.new(0, 0.5)
		opts.icon.Position = UDim2.new(0, 6, 0.5, 0)
		opts.icon.Size = UDim2.fromOffset(iconSize, iconSize)
		opts.icon.ZIndex = button.ZIndex + 1
		opts.icon.Parent = button
	elseif opts.icon then
		UI.text(opts.icon, math.floor(iconSize * 0.75), {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 6, 0.5, 0),
			Size = UDim2.fromOffset(iconSize, iconSize),
			ZIndex = button.ZIndex + 1,
			Parent = button,
		})
	end
	local hasIcon = opts.icon ~= nil
	UI.heavy(opts.text, math.floor(size.Y * 0.55), {
		Name = "Label",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, if hasIcon then iconSize + 10 else 8, 0.5, 3),
		Size = UDim2.new(1, if hasIcon then -iconSize - 18 else -16, 1, -10),
		ZIndex = button.ZIndex + 1,
		Parent = button,
	})
	UI.hover(button, 1.05)
	if opts.onClick then
		button.Activated:Connect(opts.onClick)
	end
	return button, UI.badge(button)
end

-- A square HUD tile (the reference's egg and crate buttons): a bright colour with stud
-- dots and a big icon. Returns the button and setBadge.
function UI.tile(opts)
	local s = opts.size or 76
	local button = UI.new("TextButton", {
		Name = opts.name,
		AutoButtonColor = false,
		BackgroundColor3 = opts.color,
		Text = "",
		Size = UDim2.fromOffset(s, s),
	}, { UI.corner(4), UI.stroke(3), UI.twoTone(0.86) })
	UI.dots(button, s, s)
	if typeof(opts.icon) == "Instance" then
		opts.icon.AnchorPoint = Vector2.new(0.5, 0.5)
		opts.icon.Position = UDim2.fromScale(0.5, 0.5)
		opts.icon.Size = UDim2.fromOffset(s - 10, s - 10)
		opts.icon.ZIndex = button.ZIndex + 1
		opts.icon.Parent = button
	else
		UI.text(opts.icon or "", math.floor(s * 0.6), {
			Size = UDim2.fromScale(1, 1),
			ZIndex = button.ZIndex + 1,
			Parent = button,
		})
	end
	UI.hover(button, 1.08)
	if opts.onClick then
		button.Activated:Connect(opts.onClick)
	end
	return button, UI.badge(button)
end

-- A slot: a dark cell with a thin dark outline. `gold` gives it the gold outline.
function UI.cell(props, gold: boolean?)
	local cell = UI.new("Frame", {
		BackgroundColor3 = UI.colors.cell,
		BackgroundTransparency = 0.05,
	}, {
		UI.corner(6),
		UI.stroke(if gold then 3.5 else 2.5, if gold then UI.colors.gold else nil),
	})
	for key, value in props or {} do
		cell[key] = value
	end
	return cell
end

-- A window: the dark see-through body with a flat coloured header (icon, title, red X).
-- Returns the frame, the content area under the header, setHeader(icon, title, colour)
-- and the X button.
function UI.window(props, onClose: () -> ())
	local HEADER = 54
	local frame = UI.new("Frame", {
		BackgroundColor3 = UI.colors.body,
		BackgroundTransparency = 0.2,
	}, { UI.corner(6), UI.stroke(3) })
	for key, value in props or {} do
		if key ~= "Parent" then
			frame[key] = value
		end
	end
	local z = frame.ZIndex
	local header = UI.new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, HEADER),
		BackgroundColor3 = UI.colors.orange,
		BorderSizePixel = 0,
		ZIndex = z,
		Parent = frame,
	}, {
		UI.corner(6),
		UI.twoTone(0.88),
	})
	-- Square off the header's bottom corners, with a dark line under it.
	local fill = UI.new("Frame", {
		Position = UDim2.new(0, 0, 1, -8),
		Size = UDim2.new(1, 0, 0, 8),
		BackgroundColor3 = UI.colors.orange,
		BorderSizePixel = 0,
		ZIndex = z,
		Parent = header,
	}, {
		UI.new("UIGradient", { Color = ColorSequence.new(Color3.new(0.88, 0.88, 0.88)) }),
	})
	UI.new("Frame", {
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = UI.OUTLINE,
		BorderSizePixel = 0,
		ZIndex = z,
		Parent = header,
	})
	local icon = UI.text("", 32, {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.fromOffset(42, HEADER),
		ZIndex = z + 1,
		Parent = header,
	})
	local title = UI.heavy("", 32, {
		Position = UDim2.fromOffset(58, 3),
		Size = UDim2.new(1, -124, 0, HEADER),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = z + 1,
		Parent = header,
	})
	local close = UI.button("X", UI.colors.red, onClose, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(42, 42),
		ZIndex = z + 1,
		Parent = header,
	})
	close.Label.ZIndex = z + 2
	local content = UI.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, HEADER + 3),
		Size = UDim2.new(1, 0, 1, -HEADER - 3),
		ZIndex = z,
		Parent = frame,
	})
	local function setHeader(iconText: string, titleText: string, color: Color3?)
		icon.Text = iconText
		title.Text = titleText
		header.BackgroundColor3 = color or UI.colors.orange
		fill.BackgroundColor3 = header.BackgroundColor3
	end
	if props and props.Parent then
		frame.Parent = props.Parent
	end
	return frame, content, setHeader, close
end

return UI
