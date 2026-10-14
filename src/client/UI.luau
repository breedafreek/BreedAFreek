-- Small helpers for building the UI in code (so there's nothing to set up in Studio).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FreekModel = require(ReplicatedStorage.Shared.FreekModel)

local UI = {}

UI.FONT = Enum.Font.FredokaOne
UI.colors = {
	panel = Color3.fromRGB(45, 30, 70),
	card = Color3.fromRGB(70, 50, 105),
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(190, 180, 210),
	green = Color3.fromRGB(70, 200, 90),
	blue = Color3.fromRGB(70, 140, 255),
	pink = Color3.fromRGB(255, 100, 170),
	orange = Color3.fromRGB(255, 160, 50),
	red = Color3.fromRGB(230, 70, 70),
	gray = Color3.fromRGB(110, 105, 120),
	money = Color3.fromRGB(140, 255, 140),
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
	return UI.new("UICorner", { CornerRadius = UDim.new(0, radius or 10) })
end

function UI.stroke(color: Color3?, thickness: number?)
	return UI.new("UIStroke", {
		Color = color or Color3.new(0, 0, 0),
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function UI.label(text: string, props)
	local label = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Font = UI.FONT,
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
		Font = UI.FONT,
		Text = text,
		TextColor3 = UI.colors.text,
		TextScaled = true,
		AutoButtonColor = true,
		Size = UDim2.new(1, 0, 0, 30),
	}, {
		UI.corner(8),
		UI.stroke(color:Lerp(Color3.new(0, 0, 0), 0.5), 2),
		UI.new("UIPadding", {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
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
		UI.stroke(opts.border or Color3.fromRGB(25, 15, 40), if opts.border then 3 else 2),
		UI.new("UIPadding", {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
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
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	})
end

return UI
