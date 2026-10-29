-- Floating text over things in the world (eggs, nests, pets, guardians), all in one clean
-- style like the big simulators: a short stack of lines in a fixed size on screen (it
-- doesn't balloon when you walk up to it), chunky white or coloured text with a thin black
-- outline, no backgrounds. Only shows up close (maxDistance).
--
-- FloatText.new(parent, lines, opts) where lines = { { size = px, heavy = bool } } and
-- opts = { offset = Vector3 (world space, above the parent), maxDistance, width }. Returns
-- the BillboardGui and its TextLabels (in order) to fill in.

local FloatText = {}

FloatText.OUTLINE = Color3.fromRGB(22, 20, 26)
FloatText.HEAVY = Enum.Font.LuckiestGuy
FloatText.BOLD = Enum.Font.FredokaOne

function FloatText.new(parent: Instance, lines, opts): (BillboardGui, { TextLabel })
	opts = opts or {}
	local total = 0
	for _, line in lines do
		total += line.size
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = opts.name or "FloatText"
	gui.Size = UDim2.fromOffset(opts.width or 220, total)
	gui.StudsOffsetWorldSpace = opts.offset or Vector3.new(0, 3, 0)
	gui.MaxDistance = opts.maxDistance or 30
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.ClipsDescendants = false
	local labels = {}
	local y = 0
	for i, line in lines do
		local label = Instance.new("TextLabel")
		label.Name = "Line" .. i
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromScale(0, y / total)
		label.Size = UDim2.fromScale(1, line.size / total)
		label.Font = if line.heavy then FloatText.HEAVY else FloatText.BOLD
		label.TextSize = line.size
		label.TextScaled = false
		label.TextWrapped = false
		label.TextColor3 = line.color or Color3.new(1, 1, 1)
		label.Text = line.text or ""
		label.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Color = FloatText.OUTLINE
		stroke.Thickness = if line.size >= 20 then 2.5 else 2
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Parent = label
		labels[i] = label
		y += line.size
	end
	gui.Parent = parent
	return gui, labels
end

return FloatText
