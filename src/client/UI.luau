-- Small helpers for building the UI in code (so there's nothing to set up in Studio).
-- Style: bright cartoon look like the big Roblox simulators: saturated panels with a thick
-- dark outline, chunky shaded buttons that squish when pressed, Luckiest Guy titles,
-- Fredoka One text, and every bit of text outlined in dark navy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FreekModel = require(ReplicatedStorage.Shared.FreekModel)
local EggModel = require(ReplicatedStorage.Shared.EggModel)
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
}

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

-- A little 3D picture of a Freek. silhouette = true draws it solid black ("???").
function UI.viewport(speciesId: string, mutations: { string }?, silhouette: boolean?)
	local frame = UI.new("ViewportFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 100),
		Ambient = Color3.fromRGB(170, 170, 170),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(-1, -1, -1),
		ImageColor3 = if silhouette then Color3.new(0, 0, 0) else Color3.new(1, 1, 1),
	})
	local model, height = FreekModel.build(speciesId, mutations)
	model:PivotTo(CFrame.new())
	model.Parent = frame
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	local distance = height * 2.1
	camera.CFrame =
		CFrame.lookAt(Vector3.new(distance * 0.35, height * 0.75, -distance), Vector3.new(0, height * 0.42, 0))
	camera.Parent = frame
	frame.CurrentCamera = camera
	return frame
end

-- A little 3D picture of a Monster Egg.
function UI.eggViewport(eggId: string, size: number?)
	local frame = UI.new("ViewportFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, size or 100),
		Ambient = Color3.fromRGB(180, 170, 190),
		LightColor = Color3.fromRGB(255, 240, 220),
		LightDirection = Vector3.new(-1, -1, 1),
	})
	local model, height = EggModel.build(eggId)
	model:PivotTo(CFrame.new())
	model.Parent = frame
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	local distance = height * 1.9
	camera.CFrame =
		CFrame.lookAt(Vector3.new(distance * 0.2, height * 0.6, -distance), Vector3.new(0, height * 0.45, 0))
	camera.Parent = frame
	frame.CurrentCamera = camera
	return frame
end

-- A card for grids: picture, lines of text, and buttons.
-- opts = { species, mutations?, silhouette?, lines = { {text, color?} }, buttons = { button instances } }
function UI.card(opts)
	-- Clickable cards are buttons; buttons inside them still get their own clicks.
	local card = UI.new(if opts.onClick then "TextButton" else "Frame", {
		BackgroundColor3 = opts.background or UI.colors.card,
	}, {
		UI.corner(14),
		if opts.border then UI.stroke(opts.border, 3.5) else UI.stroke(nil, 3),
		UI.gradient(),
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
	end

	local order = 0
	local function add(child)
		order += 1
		child.LayoutOrder = order
		child.Parent = card
	end

	if opts.picture then
		add(ItemPictures.view(opts.picture, opts.pictureHeight))
	elseif opts.egg then
		add(UI.eggViewport(opts.egg))
	elseif opts.species then
		add(UI.viewport(opts.species, opts.mutations, opts.silhouette))
	end
	for _, line in opts.lines or {} do
		add(UI.label(line[1], {
			TextColor3 = line[2] or UI.colors.text,
			Size = UDim2.new(1, 0, 0, line[3] or 18),
		}))
	end
	for _, button in opts.buttons or {} do
		add(button)
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
