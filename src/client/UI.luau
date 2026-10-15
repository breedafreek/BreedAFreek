-- Small helpers for building the UI in code (so there's nothing to set up in Studio).
-- Style: the look of today's big Roblox simulators: windows are chunky wooden frames
-- around a cream parchment page, with a big outlined title and a 3D icon breaking out of
-- the corner; cards are bright and saturated with a darker border of the same hue;
-- buttons are glossy with a thick dark outline and squish when pressed; Luckiest Guy for
-- titles and buttons, Fredoka One for the rest, and text outlined in dark navy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local Freeks = require(ReplicatedStorage.Shared.Freeks)

local FreekModel = require(ReplicatedStorage.Shared.FreekModel)
local EggModel = require(ReplicatedStorage.Shared.EggModel)

local UI = {}

UI.fonts = {
	regular = Font.fromEnum(Enum.Font.FredokaOne),
	bold = Font.fromEnum(Enum.Font.FredokaOne),
	heavy = Font.fromEnum(Enum.Font.LuckiestGuy),
}

-- The dark outline around panels, buttons and text.
UI.OUTLINE = Color3.fromRGB(20, 22, 48)

UI.colors = {
	panel = Color3.fromRGB(176, 108, 52), -- small HUD panels (wood)
	card = Color3.fromRGB(60, 140, 245), -- default card (bright blue)
	wood = Color3.fromRGB(176, 108, 52),
	woodDark = Color3.fromRGB(120, 68, 30),
	woodOutline = Color3.fromRGB(58, 30, 12),
	parchment = Color3.fromRGB(255, 241, 208),
	parchmentEdge = Color3.fromRGB(205, 160, 100),
	caption = Color3.fromRGB(125, 76, 34), -- brown captions on parchment
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

-- Glossy two-tone shading for buttons: bright top half, a darker lip along the bottom.
function UI.glossy()
	return UI.new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.5, Color3.new(0.95, 0.95, 0.95)),
			ColorSequenceKeypoint.new(0.56, Color3.new(0.84, 0.84, 0.84)),
			ColorSequenceKeypoint.new(1, Color3.new(0.72, 0.72, 0.72)),
		}),
		Rotation = 90,
	})
end

-- A darker shade of a colour, for card borders and the like.
function UI.darker(color: Color3, amount: number?): Color3
	return color:Lerp(Color3.new(0, 0, 0), amount or 0.45)
end

-- A small panel: wood by default, thick dark outline, shaded top to bottom.
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
		UI.glossy(),
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
	-- Cards are bright: a Freek's card takes its rarity colour, others the given colour.
	local color = opts.background or opts.color
	if not color and opts.species then
		local species = Freeks.byId[opts.species]
		local info = species and Rarities.info[species.rarity]
		color = info and info.color:Lerp(Color3.new(0, 0, 0), 0.12)
	end
	color = color or UI.colors.card
	local card = UI.new(if opts.onClick then "TextButton" else "Frame", {
		BackgroundColor3 = color,
	}, {
		UI.corner(14),
		if opts.border then UI.stroke(opts.border, 4) else UI.stroke(UI.darker(color, 0.55), 3.5),
		UI.gradient(),
	})
	-- The content sits in its own frame so tags (ribbons) can hang off the card's edge.
	local content = UI.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = card,
	}, {
		UI.new("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, if opts.ribbon then 12 else 8),
			PaddingBottom = UDim.new(0, 8),
		}),
		UI.new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 3),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	})
	if opts.ribbon then
		UI.ribbon(card, opts.ribbon[1], opts.ribbon[2])
	end

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

	if opts.egg then
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

-- A section header like "— WEAPONS —": big outlined text between two rounded bars.
function UI.section(text: string, color: Color3?)
	local tint = color or UI.colors.green
	local row = UI.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
	}, {
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local function bar(order: number)
		UI.new("Frame", {
			BackgroundColor3 = tint,
			Size = UDim2.fromOffset(46, 10),
			LayoutOrder = order,
			Parent = row,
		}, { UI.corner(5), UI.stroke(nil, 2.5) })
	end
	bar(1)
	UI.label(string.upper(text), {
		FontFace = UI.fonts.heavy,
		TextColor3 = tint,
		TextScaled = false,
		TextSize = 34,
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Parent = row,
	})
		:FindFirstChildOfClass("UIStroke").Thickness =
		3
	bar(3)
	return row
end

-- A little tag on the top edge of a card or panel ("POPULAR", "BEST VALUE", "NEW!").
function UI.ribbon(parent: GuiObject, text: string, color: Color3?)
	local tag = UI.label(text, {
		Name = "Ribbon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		TextScaled = false,
		TextSize = 15,
		FontFace = UI.fonts.heavy,
		BackgroundTransparency = 0,
		BackgroundColor3 = color or UI.colors.red,
		ZIndex = parent.ZIndex + 3,
		Parent = parent,
	})
	UI.corner(8).Parent = tag
	UI.stroke(nil, 2.5).Parent = tag
	UI.glossy().Parent = tag
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }).Parent = tag
	return tag
end

-- A wooden window: a chunky plank frame (with wood grain) around a cream parchment page.
-- Returns the frame and the page; put content in the page.
function UI.wood(props, children)
	local frame = UI.new("Frame", {
		BackgroundColor3 = UI.colors.wood,
	}, {
		UI.corner(20),
		UI.stroke(UI.colors.woodOutline, 4),
		UI.gradient(),
	})
	-- Wood grain: thin darker streaks (only the frame's edges show round the page).
	local streaks = { { 0.02, 0.5, 0.45 }, { 0.6, 0.1, 0.35 }, { 0.97, 0.15, 0.6 }, { 0.985, 0.55, 0.3 } }
	for _, streak in streaks do
		UI.new("Frame", {
			Name = "Grain",
			BackgroundColor3 = UI.colors.woodDark,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			Position = UDim2.new(streak[2], 0, streak[1], -1),
			Size = UDim2.new(streak[3], 0, 0, 3),
			Parent = frame,
		}, { UI.corner(2) })
	end
	local page = UI.new("Frame", {
		Name = "Page",
		BackgroundColor3 = UI.colors.parchment,
		Position = UDim2.fromOffset(18, 64),
		Size = UDim2.new(1, -36, 1, -82),
		ZIndex = 2,
		Parent = frame,
	}, {
		UI.corner(12),
		UI.stroke(UI.colors.parchmentEdge, 3),
		UI.new("UIGradient", {
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.93, 0.9, 0.84)),
			Rotation = 90,
		}),
	})
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
	return frame, page
end

-- The box round everything you can see in a model, in world space. Unlike
-- Model:GetBoundingBox it counts stretched SpecialMeshes (like the eggs).
local function visibleBounds(model: Model): (Vector3, Vector3)
	local lo, hi
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			local size = p.Size
			local mesh = p:FindFirstChildOfClass("SpecialMesh")
			if mesh then
				size *= mesh.Scale
			end
			local half = size / 2
			for _, corner in
				{
					Vector3.new(1, 1, 1),
					Vector3.new(1, 1, -1),
					Vector3.new(1, -1, 1),
					Vector3.new(1, -1, -1),
					Vector3.new(-1, 1, 1),
					Vector3.new(-1, 1, -1),
					Vector3.new(-1, -1, 1),
					Vector3.new(-1, -1, -1),
				}
			do
				local point = p.CFrame:PointToWorldSpace(half * corner)
				lo = if lo then lo:Min(point) else point
				hi = if hi then hi:Max(point) else point
			end
		end
	end
	return lo or Vector3.zero, hi or Vector3.zero
end

-- A 3D icon: a model in a ViewportFrame, framed to fit, seen a little from the side.
function UI.modelIcon(model: Model, size: UDim2?, turn: number?)
	local frame = UI.new("ViewportFrame", {
		BackgroundTransparency = 1,
		Size = size or UDim2.fromOffset(72, 72),
		Ambient = Color3.fromRGB(200, 200, 200),
		LightColor = Color3.fromRGB(255, 250, 240),
		LightDirection = Vector3.new(-1, -1.4, 1),
	})
	local pivot = model:GetPivot()
	model:PivotTo(CFrame.Angles(0, turn or 0, 0) * pivot.Rotation)
	local lo, hi = visibleBounds(model)
	local center = (lo + hi) / 2
	model.Parent = frame
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	-- Back off until the box fits (the camera looks along +Z at the model's front).
	local extent = hi - lo
	local fit = math.max(extent.X, extent.Y) / 2
	local distance = fit / math.tan(math.rad(15)) + extent.Z / 2
	camera.CFrame = CFrame.lookAt(center + Vector3.new(0, fit * 0.2, -distance), center)
	camera.Parent = frame
	frame.CurrentCamera = camera
	return frame
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
