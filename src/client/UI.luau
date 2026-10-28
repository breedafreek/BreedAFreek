-- The building blocks of the screen UI, in one style (the owner's reference: a clean
-- simulator look like the "Daily Rewards" window):
-- - One font, Fredoka One, white or a bright colour with a black outline.
-- - Windows: a dark see-through body with a thin black outline and nearly square corners,
--   a flat coloured header bar (icon, white title, red square X) and a black line under it.
-- - Slots: dark cells with a thin black outline: a white label on top, a big picture in the
--   middle and a coloured value at the bottom; the one that matters gets a gold outline.
-- - Buttons: bright, the top half lighter than the bottom, black outline, white text.
-- - Everything you can press grows a little when hovered and dips when pressed.
-- Pictures are our own 3D models (ItemPictures) or emoji, never uploaded images.

local TweenService = game:GetService("TweenService")

local UI = {}

UI.FONT = Font.fromEnum(Enum.Font.FredokaOne)
UI.OUTLINE = Color3.fromRGB(20, 20, 22)

UI.colors = {
	white = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(190, 190, 200),
	money = Color3.fromRGB(110, 235, 80),
	speed = Color3.fromRGB(90, 185, 255),
	gold = Color3.fromRGB(255, 205, 45),
	green = Color3.fromRGB(80, 215, 60),
	red = Color3.fromRGB(230, 55, 55),
	blue = Color3.fromRGB(60, 140, 240),
	orange = Color3.fromRGB(245, 140, 45),
	gray = Color3.fromRGB(120, 120, 128),
	body = Color3.fromRGB(28, 28, 32), -- window bodies (see-through)
	cell = Color3.fromRGB(52, 52, 58), -- slots
}

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

-- The black outline round a frame.
function UI.stroke(thickness: number?, color: Color3?)
	return UI.new("UIStroke", {
		Color = color or UI.OUTLINE,
		Thickness = thickness or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	})
end

-- Text: Fredoka One, white (or `color`), black outline, `size` px (it shrinks to fit its
-- box, never grows past `size`).
function UI.text(text: string, size: number, props)
	local label = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = UI.FONT,
		Text = text,
		TextColor3 = UI.colors.white,
		TextScaled = true,
		Size = UDim2.new(1, 0, 0, size + 4),
	}, {
		UI.new("UIStroke", {
			Color = UI.OUTLINE,
			Thickness = if size >= 28 then 3 elseif size >= 18 then 2.5 else 2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			LineJoinMode = Enum.LineJoinMode.Round,
		}),
		UI.new("UITextSizeConstraint", { MaxTextSize = size }),
	})
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
end

-- The two-tone shine on buttons and tiles: the top half lighter than the bottom.
local function twoTone(dark: number)
	return UI.new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.501, Color3.new(dark, dark, dark)),
			ColorSequenceKeypoint.new(1, Color3.new(dark, dark, dark)),
		}),
	})
end

-- A button: bright `color` (top half lighter), black outline, white outlined text.
function UI.button(text: string, color: Color3, onClick: () -> (), props)
	local button = UI.new("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = color,
		Text = "",
		Size = UDim2.fromOffset(160, 50),
	}, { UI.corner(5), UI.stroke(3), twoTone(0.86) })
	UI.text(text, 26, {
		Name = "Label",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
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

-- A slot: a dark cell with a thin black outline. `gold` gives it the gold outline.
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
	local HEADER = 52
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
		UI.new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.86, 0.86, 0.86)),
		}),
	})
	-- Square off the header's bottom corners, with a black line under it.
	local fill = UI.new("Frame", {
		Position = UDim2.new(0, 0, 1, -8),
		Size = UDim2.new(1, 0, 0, 8),
		BackgroundColor3 = UI.colors.orange,
		BorderSizePixel = 0,
		ZIndex = z,
		Parent = header,
	}, {
		UI.new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(0.88, 0.88, 0.88), Color3.new(0.86, 0.86, 0.86)),
		}),
	})
	UI.new("Frame", {
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = UI.OUTLINE,
		BorderSizePixel = 0,
		ZIndex = z,
		Parent = header,
	})
	local icon = UI.text("", 30, {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.fromOffset(40, HEADER),
		ZIndex = z + 1,
		Parent = header,
	})
	local title = UI.text("", 28, {
		Position = UDim2.fromOffset(56, 0),
		Size = UDim2.new(1, -120, 0, HEADER),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = z + 1,
		Parent = header,
	})
	local close = UI.button("X", UI.colors.red, onClose, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
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
