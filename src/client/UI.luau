-- Small helpers for building the UI in code (so there's nothing to set up in Studio).
-- Style: the clean cartoon look of the big Roblox simulators (Pet Simulator, PLS DONATE,
-- Grow a Garden) in Steal a Home colours: light windows with a coloured header and a
-- slanted title tab, bright glossy gradient cards with a big 3D picture, black price
-- pills, chunky shaded buttons that squish when pressed, Luckiest Guy titles, Fredoka One
-- text, and every bit of text outlined in dark navy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BoxModel = require(ReplicatedStorage.Shared.BoxModel)
local Lego = require(ReplicatedStorage.Shared.Lego)
local Parts = require(ReplicatedStorage.Shared.Parts)
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local ItemPictures = require(script.Parent.ItemPictures)

local UI = {}

UI.fonts = {
	regular = Font.fromEnum(Enum.Font.FredokaOne),
	bold = Font.fromEnum(Enum.Font.FredokaOne),
	heavy = Font.fromEnum(Enum.Font.LuckiestGuy),
}

-- The dark outline around panels, buttons and text.
UI.OUTLINE = Color3.fromRGB(20, 22, 48)

UI.colors = {
	panel = Color3.fromRGB(62, 128, 245), -- windows and HUD panels
	card = Color3.fromRGB(110, 170, 255),
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(220, 232, 255),
	green = Color3.fromRGB(60, 200, 110),
	blue = Color3.fromRGB(70, 140, 255),
	pink = Color3.fromRGB(255, 95, 170),
	orange = Color3.fromRGB(255, 160, 50),
	red = Color3.fromRGB(235, 70, 80),
	gray = Color3.fromRGB(95, 90, 115),
	money = Color3.fromRGB(110, 235, 140),
	gold = Color3.fromRGB(255, 200, 60),
	purple = Color3.fromRGB(160, 110, 240),
	sheet = Color3.fromRGB(236, 230, 255), -- window bodies
	ink = Color3.fromRGB(28, 26, 48), -- price pills
	fusion = Color3.fromRGB(170, 80, 255), -- the game's own purple-to-pink
	fusion2 = Color3.fromRGB(255, 80, 190),
}

-- Bright card colours, picked by name so a card keeps its colour between refreshes.
local CARD_COLORS = {
	Color3.fromRGB(255, 95, 170),
	Color3.fromRGB(70, 200, 110),
	Color3.fromRGB(70, 150, 255),
	Color3.fromRGB(255, 160, 50),
	Color3.fromRGB(165, 95, 245),
	Color3.fromRGB(40, 195, 190),
	Color3.fromRGB(240, 80, 80),
	Color3.fromRGB(250, 200, 50),
}
function UI.cardColor(name: string): Color3
	local sum = 0
	for i = 1, #name do
		sum += string.byte(name, i) * i
	end
	return CARD_COLORS[sum % #CARD_COLORS + 1]
end

UI.GLASS_TRANSPARENCY = 0

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
		LineJoinMode = Enum.LineJoinMode.Round,
	})
end

-- Shading from light at the top to darker at the bottom. It multiplies whatever colour the
-- frame is, so it works on any button or panel. (color/lighten are kept for old callers.)
function UI.gradient(_color: Color3?, lighten: number?)
	local top = 1
	local bottom = 0.78 - (lighten or 0) * 0.3
	return UI.new("UIGradient", {
		Color = ColorSequence.new(Color3.new(top, top, top), Color3.new(bottom, bottom, bottom)),
		Rotation = 90,
	})
end

-- A bright cartoon panel with a thick outline (the name is from the old glass style).
function UI.glass(props, children)
	local frame = UI.new("Frame", {
		BackgroundColor3 = UI.colors.panel,
		BackgroundTransparency = UI.GLASS_TRANSPARENCY,
	}, { UI.corner(16), UI.stroke(nil, 3.5), UI.gradient() })
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
	}, { UI.textStroke(1.6) })
	for key, value in props or {} do
		label[key] = value
	end
	return label
end

-- A chunky cartoon button: bright shaded fill, thick dark outline, outlined text, and a
-- squish when pressed.
function UI.button(text: string, color: Color3, onClick: () -> (), props)
	local scale = UI.new("UIScale")
	local button = UI.new("TextButton", {
		BackgroundColor3 = color,
		FontFace = UI.fonts.heavy,
		Text = text,
		TextColor3 = UI.colors.text,
		TextStrokeColor3 = UI.OUTLINE,
		TextStrokeTransparency = 0,
		TextScaled = true,
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 30),
	}, {
		UI.corner(12),
		UI.gradient(),
		UI.stroke(nil, 3),
		scale,
		UI.new("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 5),
			PaddingBottom = UDim.new(0, 5),
		}),
	})
	for key, value in props or {} do
		button[key] = value
	end
	button.MouseButton1Down:Connect(function()
		scale.Scale = 0.92
	end)
	button.MouseButton1Up:Connect(function()
		scale.Scale = 1
	end)
	button.MouseLeave:Connect(function()
		scale.Scale = 1
	end)
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

-- A card for grids: picture, lines of text, and buttons.
-- opts = { species, mutations?, silhouette?, lines = { {text, color?} }, buttons = { button instances } }
-- A black price pill (like PLS DONATE): coin or Robux icon and the price in white.
function UI.pricePill(text: string, onClick: () -> (), props)
	local pill = UI.button(text, UI.colors.ink, onClick, props)
	pill.TextColor3 = Color3.new(1, 1, 1)
	local corner = pill:FindFirstChildOfClass("UICorner")
	if corner then
		corner.CornerRadius = UDim.new(1, 0)
	end
	local shade = pill:FindFirstChildOfClass("UIGradient")
	if shade then
		shade:Destroy() -- flat and glossy black
	end
	return pill
end

-- A little slanted tag on a card's corner: "NEW", "BEST", "x2"...
function UI.tag(parent: GuiObject, text: string, color: Color3?)
	local tag = UI.new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 6, 0, -8),
		Size = UDim2.fromOffset(64, 26),
		Rotation = 10,
		BackgroundColor3 = color or UI.colors.red,
		FontFace = UI.fonts.heavy,
		Text = text,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = (parent.ZIndex or 1) + 5,
		Parent = parent,
	}, {
		UI.corner(8),
		UI.stroke(nil, 2.5),
		UI.textStroke(1.6),
		UI.new("UIPadding", {
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingTop = UDim.new(0, 3),
			PaddingBottom = UDim.new(0, 3),
		}),
	})
	return tag
end

-- A bright glossy card (like Pet Simulator's shop): a gradient in the card's colour with a
-- shine across the top, the title in white, a big picture on a glowing disc, then text
-- lines and buttons. opts: accent (colour), border (a highlight outline, e.g. owned),
-- picture (an ItemPictures key) / part (+ mutations, silhouette) / box, lines = { { text,
-- colour?, height? } }, buttons, tag = { text, colour? }, onClick.
function UI.card(opts)
	local title = opts.lines and opts.lines[1] and opts.lines[1][1] or ""
	local accent = opts.accent
	if not accent and opts.part then
		local part = Parts.byId[opts.part]
		local rarity = part and part.rarity
		if rarity and rarity ~= "Common" then
			accent = Rarities.info[rarity].color
		end
	end
	accent = accent or (if opts.part then Color3.fromRGB(110, 165, 255) else UI.cardColor(title))
	if opts.background then
		accent = opts.background
	end

	-- Clickable cards are buttons; buttons inside them still get their own clicks.
	local card = UI.new(if opts.onClick then "TextButton" else "Frame", {
		BackgroundColor3 = accent,
	}, {
		UI.corner(16),
		if opts.border then UI.stroke(opts.border, 4.5) else UI.stroke(nil, 3.5),
		UI.new("UIGradient", {
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(165, 165, 175)),
			Rotation = 90,
		}),
	})
	-- The glossy shine across the top.
	UI.new("Frame", {
		Name = "Shine",
		Position = UDim2.fromOffset(5, 4),
		Size = UDim2.new(1, -10, 0.38, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.8,
		Parent = card,
	}, { UI.corner(12) })
	local content = UI.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = card,
	}, {
		UI.new("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 6),
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
	end

	local order = 0
	local function add(child)
		order += 1
		child.LayoutOrder = order
		child.Parent = content
	end

	-- The title on top, big and white.
	local lines = opts.lines or {}
	if lines[1] then
		add(UI.label(lines[1][1], {
			FontFace = UI.fonts.heavy,
			TextColor3 = Color3.new(1, 1, 1),
			Size = UDim2.new(1, 0, 0, math.max(lines[1][3] or 22, 22)),
		}))
	end

	-- The picture, on a soft glowing disc.
	local picture
	if opts.picture then
		picture = ItemPictures.view(opts.picture, opts.pictureHeight)
	elseif opts.box then
		picture = UI.boxViewport(opts.box)
	elseif opts.part then
		picture = ItemPictures.part(opts.part, opts.pictureHeight, opts.silhouette)
	end
	if picture then
		local holder = UI.new("Frame", {
			BackgroundTransparency = 1,
			Size = picture.Size,
		})
		UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.52),
			Size = UDim2.fromScale(0.62, 0.95),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.72,
			Parent = holder,
		}, { UI.corner(999), UI.new("UIAspectRatioConstraint", { AspectRatio = 1 }) })
		picture.Size = UDim2.fromScale(1, 1)
		picture.Parent = holder
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
			CellPadding = UDim2.fromOffset(10, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	})
end

return UI
