-- The Lucky Wheel, drawn like the prize wheels in the big simulators: bright pie slices
-- (each with a big icon, its prize and its chance) inside a chunky gold rim ringed with
-- blinking bulbs, a red pointer at the top, and a hub in the middle that can be the SPIN
-- button. LuckyWheel.build returns the wheel and spinTo(slice, onDone), which spins it
-- round a few times and stops with that slice under the pointer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Luck = require(ReplicatedStorage.Shared.Luck)
local UI = require(script.Parent.UI)

local LuckyWheel = {}

-- Slice colours go round the wheel in a rainbow, so neighbours always differ.
local SLICE_COLORS = {
	Color3.fromRGB(255, 90, 160),
	Color3.fromRGB(70, 160, 255),
	Color3.fromRGB(255, 205, 50),
	Color3.fromRGB(80, 210, 110),
	Color3.fromRGB(165, 100, 250),
	Color3.fromRGB(255, 140, 50),
	Color3.fromRGB(40, 205, 200),
	Color3.fromRGB(245, 75, 85),
}
local ICONS = {
	Coins = "💰",
	["Big Coins"] = "💵",
	["Golden Freek"] = "⭐",
	["Monster Egg"] = "🥚",
	["Huge Coins"] = "🤑",
	["Rainbow Freek"] = "🌈",
	["Mega Egg"] = "🔮",
	JACKPOT = "👑",
}

-- Short names that fit on a slice.
local SHORT = {
	Coins = "COINS",
	["Big Coins"] = "BIG $",
	["Golden Freek"] = "GOLDEN",
	["Monster Egg"] = "EGG",
	["Huge Coins"] = "HUGE $",
	["Rainbow Freek"] = "RAINBOW",
	["Mega Egg"] = "MEGA EGG",
	JACKPOT = "JACKPOT",
}

local function circle(props, children)
	local frame = UI.new("Frame", props, children)
	UI.corner(999).Parent = frame
	return frame
end

-- size: the wheel's width in pixels. opts.hubText: text on the hub (e.g. "SPIN!"),
-- opts.onHub: makes the hub a button. opts.zIndex: base ZIndex.
function LuckyWheel.build(parent: Instance, size: number, opts)
	opts = opts or {}
	local z = opts.zIndex or 1
	local count = #Luck.WHEEL
	local sliceAngle = 360 / count

	local frame = UI.new("Frame", {
		Name = "LuckyWheel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		ZIndex = z,
		Parent = parent,
	})

	-- The gold rim with its outline.
	circle({
		Name = "Rim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 200, 60),
		ZIndex = z,
		Parent = frame,
	}, {
		UI.stroke(nil, 4),
		UI.new("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(255, 240, 160), Color3.fromRGB(230, 140, 20)),
			Rotation = 90,
		}),
	})

	-- Bulbs round the rim.
	local bulbs = {}
	local bulbCount = 16
	for k = 1, bulbCount do
		local a = math.rad((k - 1) / bulbCount * 360)
		local bulb = circle({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.sin(a) * size * 0.465, 0.5, -math.cos(a) * size * 0.465),
			Size = UDim2.fromOffset(size * 0.04, size * 0.04),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = z + 1,
			Parent = frame,
		}, { UI.stroke(nil, 1.5) })
		table.insert(bulbs, bulb)
	end

	-- The spinning part: the slices and their labels.
	local radius = size * 0.42
	local spinner = UI.new("Frame", {
		Name = "Spinner",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(radius * 2, radius * 2),
		BackgroundTransparency = 1,
		ZIndex = z + 1,
		Parent = frame,
	})
	circle({
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UI.OUTLINE,
		ZIndex = z + 1,
		Parent = spinner,
	})
	-- Each slice is filled with thin wedges fanned out from the middle.
	local wedges = 10
	local step = sliceAngle / wedges
	local wedgeWidth = radius * math.rad(step) * 1.25
	for i, slice in Luck.WHEEL do
		local color = SLICE_COLORS[(i - 1) % #SLICE_COLORS + 1]
		for k = 0, wedges - 1 do
			UI.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(wedgeWidth, radius - 3),
				Rotation = (i - 1) * sliceAngle + (k + 0.5) * step,
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				ZIndex = z + 2,
				Parent = spinner,
			}, {
				-- Lighter toward the rim.
				UI.new("UIGradient", {
					Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 210)),
					Rotation = 90,
				}),
			})
		end
		-- A dark line between slices.
		UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(3, radius),
			Rotation = (i - 1) * sliceAngle,
			BackgroundColor3 = UI.OUTLINE,
			BorderSizePixel = 0,
			ZIndex = z + 3,
			Parent = spinner,
		})
		-- The slice's label: big icon, prize, chance; turned to read outward.
		local arm = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(radius * 0.5, radius * 2),
			Rotation = (i - 0.5) * sliceAngle,
			BackgroundTransparency = 1,
			ZIndex = z + 4,
			Parent = spinner,
		})
		UI.label(ICONS[slice.label] or "🎁", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, radius * 0.08),
			Size = UDim2.fromOffset(radius * 0.36, radius * 0.3),
			ZIndex = z + 5,
			Parent = arm,
		})
		UI.label(SHORT[slice.label] or string.upper(slice.label), {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, radius * 0.38),
			Size = UDim2.fromOffset(radius * 0.5, radius * 0.13),
			FontFace = UI.fonts.heavy,
			ZIndex = z + 5,
			Parent = arm,
		})
		UI.label(string.format("%.0f%%", Luck.wheelPercent(i)), {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, radius * 0.52),
			Size = UDim2.fromOffset(radius * 0.4, radius * 0.11),
			TextColor3 = Color3.fromRGB(255, 250, 200),
			ZIndex = z + 5,
			Parent = arm,
		})
	end

	-- The hub in the middle (the SPIN button in the Luck window).
	local hub = UI.new(if opts.onHub then "TextButton" else "TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size * 0.26, size * 0.26),
		BackgroundColor3 = Color3.new(1, 1, 1),
		FontFace = UI.fonts.heavy,
		Text = opts.hubText or "🎡",
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = z + 6,
		Parent = frame,
	}, {
		UI.corner(999),
		UI.stroke(nil, 4),
		UI.textStroke(2.5),
		UI.new("UIGradient", {
			Color = ColorSequence.new(UI.colors.fusion, UI.colors.fusion2),
			Rotation = 45,
		}),
		UI.new("UIPadding", {
			PaddingLeft = UDim.new(0.14, 0),
			PaddingRight = UDim.new(0.14, 0),
			PaddingTop = UDim.new(0.22, 0),
			PaddingBottom = UDim.new(0.22, 0),
		}),
	})
	if opts.onHub then
		(hub :: TextButton).AutoButtonColor = false
		(hub :: TextButton).Activated:Connect(opts.onHub)
	end

	-- The pointer at the top: a red tip with a gold cap.
	UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, size * 0.06),
		Size = UDim2.fromOffset(size * 0.09, size * 0.09),
		Rotation = 45,
		BackgroundColor3 = UI.colors.red,
		ZIndex = z + 7,
		Parent = frame,
	}, { UI.corner(4), UI.stroke(nil, 3) })
	circle({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, size * 0.015),
		Size = UDim2.fromOffset(size * 0.07, size * 0.07),
		BackgroundColor3 = Color3.fromRGB(255, 205, 60),
		ZIndex = z + 8,
		Parent = frame,
	}, { UI.stroke(nil, 3) })

	-- Bulbs blink in turn (faster while spinning).
	local spinning = false
	task.spawn(function()
		local tick = 0
		while frame.Parent do
			tick += 1
			for k, bulb in bulbs do
				local on = (k + tick) % 2 == 0
				bulb.BackgroundColor3 = if on then Color3.fromRGB(255, 250, 200) else Color3.fromRGB(255, 120, 60)
			end
			task.wait(if spinning then 0.08 else 0.45)
		end
	end)

	local wheel = { frame = frame, hub = hub }
	-- Spins round several times and stops with `slice` under the pointer.
	function wheel.spinTo(slice: number, onDone: (() -> ())?)
		spinning = true
		local target = -((slice - 0.5) * sliceAngle) - 360 * 6 + (math.random() - 0.5) * sliceAngle * 0.6
		local tween = TweenService:Create(
			spinner,
			TweenInfo.new(4.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Rotation = target }
		)
		tween:Play()
		tween.Completed:Connect(function()
			spinning = false
			if onDone then
				onDone()
			end
		end)
	end
	return wheel
end

return LuckyWheel
