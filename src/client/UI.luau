-- Small helpers for building the UI in code (so there's nothing to set up in Studio).
-- Style: dark frosted-glass panels, rounded corners, Builder Sans, soft gradient buttons.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FreekModel = require(ReplicatedStorage.Shared.FreekModel)

local UI = {}

local FAMILY = "rbxasset://fonts/families/BuilderSans.json"
UI.fonts = {
	regular = Font.new(FAMILY, Enum.FontWeight.Medium),
	bold = Font.new(FAMILY, Enum.FontWeight.Bold),
	heavy = Font.new(FAMILY, Enum.FontWeight.ExtraBold),
}

UI.colors = {
	panel = Color3.fromRGB(22, 19, 34), -- glass panels
	card = Color3.fromRGB(40, 34, 60),
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(170, 164, 192),
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

UI.GLASS_TRANSPARENCY = 0.12

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

-- A thin outline; defaults to the faint white edge used on glass panels.
function UI.stroke(color: Color3?, thickness: number?, transparency: number?)
	return UI.new("UIStroke", {
		Color = color or Color3.new(1, 1, 1),
		Thickness = thickness or 1.5,
		Transparency = transparency or (if color then 0 else 0.86),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

-- Vertical gradient from a lighter version of color at the top to color at the bottom.
function UI.gradient(color: Color3, lighten: number?)
	return UI.new("UIGradient", {
		Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), lighten or 0.18), color),
		Rotation = 90,
	})
end

-- A frosted-glass panel.
function UI.glass(props, children)
	local frame = UI.new("Frame", {
		BackgroundColor3 = UI.colors.panel,
		BackgroundTransparency = UI.GLASS_TRANSPARENCY,
	}, { UI.corner(14), UI.stroke() })
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
	})
	for key, value in props or {} do
		label[key] = value
	end
	return label
end

function UI.button(text: string, color: Color3, onClick: () -> (), props)
	local button = UI.new("TextButton", {
		BackgroundColor3 = color,
		FontFace = UI.fonts.heavy,
		Text = text,
		TextColor3 = UI.colors.text,
		TextScaled = true,
		AutoButtonColor = true,
		Size = UDim2.new(1, 0, 0, 30),
	}, {
		UI.corner(10),
		UI.gradient(color),
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
	button.Activated:Connect(onClick)
	return button
end

-- A little 3D picture of a Freek. silhouette = true draws it solid black ("???").
function UI.viewport(speciesId: string, mutation: string?, silhouette: boolean?)
	local frame = UI.new("ViewportFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 100),
		Ambient = Color3.fromRGB(170, 170, 170),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(-1, -1, -1),
		ImageColor3 = if silhouette then Color3.new(0, 0, 0) else Color3.new(1, 1, 1),
	})
	local model, height = FreekModel.build(speciesId, mutation)
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

-- A card for grids: picture, lines of text, and buttons.
-- opts = { species, mutation?, silhouette?, lines = { {text, color?} }, buttons = { button instances } }
function UI.card(opts)
	-- Clickable cards are buttons; buttons inside them still get their own clicks.
	local card = UI.new(if opts.onClick then "TextButton" else "Frame", {
		BackgroundColor3 = opts.background or UI.colors.card,
	}, {
		UI.corner(12),
		if opts.border then UI.stroke(opts.border, 2.5) else UI.stroke(),
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

	if opts.species then
		add(UI.viewport(opts.species, opts.mutation, opts.silhouette))
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
