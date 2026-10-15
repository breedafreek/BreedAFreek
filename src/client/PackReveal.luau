-- Monster Egg opening, done like a card-pack reveal in the big sports games: the screen
-- goes dark, the egg drops in and shakes, bursts into a face-down card, and then the
-- clues slam in one at a time (first the Freek's SERIES, then its RARITY, with the lights
-- turning that colour) before the card flips to show the Freek's picture and name.
-- The rarer the Freek, the longer the suspense and the bigger the lights.
-- Tapping the screen speeds it up.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Freeks = require(ReplicatedStorage.Shared.Freeks)
local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local Rarities = require(ReplicatedStorage.Shared.Rarities)
local UI = require(script.Parent.UI)

local PackReveal = {}

local RARITY_WORDS = {
	Common = "COMMON",
	Uncommon = "UNCOMMON",
	Rare = "RARE!",
	Legendary = "LEGENDARY!",
	Mystic = "MYSTIC!!",
	Ultra = "ULTRA!!!",
	Secret = "SECRET!!!",
}

local CARD_W, CARD_H = 290, 400

local function easeOut(a: number): number
	return 1 - (1 - a) ^ 3
end

local function rainbow(t: number, offset: number?): Color3
	return Color3.fromHSV((t * 0.5 + (offset or 0)) % 1, 0.75, 1)
end

-- result = { crate, rarity, isNew, freek = { species, mutations } }
function PackReveal.play(result, done: () -> ())
	local player = Players.LocalPlayer
	local species = Freeks.byId[result.freek.species]
	local rarity = result.rarity
	local tier = Rarities.rank[rarity] or 1
	local rarityColor = Rarities.info[rarity] and Rarities.info[rarity].color or Color3.new(1, 1, 1)
	local series = Freeks.SERIES[species and species.series or "Animal"] or Freeks.SERIES.Animal
	local random = Random.new()

	local gui = UI.new("ScreenGui", {
		Name = "PackReveal",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 50,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	-- Everything sits in `stage` so the whole picture can shake.
	local stage = UI.new("TextButton", {
		Name = "Stage",
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1.06, 1.06),
		BackgroundColor3 = Color3.fromRGB(10, 8, 26),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	local backdrop = UI.new("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(70, 60, 120), Color3.fromRGB(10, 8, 26)),
		Rotation = 90,
		Parent = stage,
	})

	-- Tapping speeds everything up (for people who've seen it before).
	local speed = 1
	stage.Activated:Connect(function()
		speed = 4
	end)

	-- Light rays spinning round the middle of the screen.
	local rays = {}
	for i = 1, 8 do
		local ray = UI.new("Frame", {
			Name = "Ray",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.48),
			Size = UDim2.new(0, 70, 2, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Rotation = i * 22.5,
			ZIndex = 2,
			Parent = stage,
		}, {
			UI.new("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.42, 0.55),
					NumberSequenceKeypoint.new(0.5, 0.35),
					NumberSequenceKeypoint.new(0.58, 0.55),
					NumberSequenceKeypoint.new(1, 1),
				}),
				Rotation = 90,
			}),
		})
		table.insert(rays, ray)
	end
	-- A glow behind the egg/card and a spotlight pool on the floor.
	local glow = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(460, 460),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = stage,
	}, {
		UI.corner(230),
		UI.new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.3),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})
	local pool = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.86),
		Size = UDim2.fromOffset(520, 90),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = stage,
	}, { UI.corner(45) })

	local state = {
		rayColor = Color3.new(1, 1, 1),
		rayAlpha = 0, -- 0 = invisible, 1 = full
		raySpeed = 8, -- degrees per second
		rainbow = false,
		shake = 0,
	}

	-- Runs fn(alpha, t) every frame for `duration` seconds (shorter when sped up), and
	-- keeps the rays spinning and the stage shaking.
	local clock = os.clock()
	local spin = 0
	local function animate(duration: number, fn: ((number, number) -> ())?)
		local elapsed = 0
		while true do
			local now = os.clock()
			local dt = math.min(now - clock, 0.1)
			clock = now
			elapsed += dt * speed
			local alpha = math.min(elapsed / duration, 1)
			if fn then
				fn(alpha, elapsed)
			end
			spin += state.raySpeed * dt
			for i, ray in rays do
				ray.Rotation = i * 22.5 + spin
				ray.BackgroundColor3 = if state.rainbow then rainbow(now, i / #rays) else state.rayColor
				ray.BackgroundTransparency = 1 - state.rayAlpha
			end
			glow.BackgroundColor3 = if state.rainbow then rainbow(now) else state.rayColor
			glow.BackgroundTransparency = 1 - state.rayAlpha * 0.9
			pool.BackgroundColor3 = glow.BackgroundColor3
			pool.BackgroundTransparency = 1 - state.rayAlpha * 0.35
			if state.shake > 0.5 then
				stage.Position =
					UDim2.new(0.5, random:NextNumber(-1, 1) * state.shake, 0.5, random:NextNumber(-1, 1) * state.shake)
				state.shake *= math.exp(-dt * 9)
			else
				stage.Position = UDim2.fromScale(0.5, 0.5)
			end
			if alpha >= 1 then
				break
			end
			task.wait()
		end
	end

	local function flash(color: Color3, duration: number)
		local frame = UI.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = color,
			BackgroundTransparency = 0,
			ZIndex = 40,
			Parent = gui,
		})
		task.spawn(function()
			local began = os.clock()
			while os.clock() - began < duration do
				frame.BackgroundTransparency = (os.clock() - began) / duration
				task.wait()
			end
			frame:Destroy()
		end)
	end

	-- Sparks flying out from the middle of the screen.
	local function burst(color: Color3, count: number, confetti: boolean?)
		local sparks = {}
		for k = 1, count do
			local angle = random:NextNumber(0, math.pi * 2)
			local spark = UI.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.48),
				Size = if confetti then UDim2.fromOffset(12, 7) else UDim2.fromOffset(10, 10),
				BackgroundColor3 = if confetti
					then Color3.fromHSV(random:NextNumber(), 0.7, 1)
					elseif k % 3 == 0 then Color3.new(1, 1, 1)
					else color,
				Rotation = random:NextNumber(0, 360),
				ZIndex = 30,
				Parent = stage,
			}, if confetti then {} else { UI.corner(5) })
			table.insert(sparks, {
				frame = spark,
				velocity = Vector2.new(math.cos(angle), math.sin(angle)) * random:NextNumber(300, 750),
			})
		end
		task.spawn(function()
			local began, last = os.clock(), os.clock()
			while os.clock() - began < 1.3 do
				local now = os.clock()
				local dt = now - last
				last = now
				local a = (now - began) / 1.3
				for _, s in sparks do
					s.velocity = s.velocity * (1 - dt * 2) + Vector2.new(0, (if confetti then 500 else 120) * dt)
					local p = s.frame.Position
					s.frame.Position =
						UDim2.new(p.X.Scale, p.X.Offset + s.velocity.X * dt, p.Y.Scale, p.Y.Offset + s.velocity.Y * dt)
					s.frame.BackgroundTransparency = a * a
					s.frame.Rotation += 300 * dt
				end
				task.wait()
			end
			for _, s in sparks do
				s.frame:Destroy()
			end
		end)
	end

	-- A big clue: a small caption ("SERIES") over huge outlined words that slam in.
	local captionLabel = UI.label("", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.14),
		Size = UDim2.fromOffset(500, 34),
		FontFace = UI.fonts.heavy,
		TextColor3 = Color3.fromRGB(230, 230, 255),
		TextTransparency = 1,
		ZIndex = 20,
		Parent = stage,
	})
	captionLabel:FindFirstChildOfClass("UIStroke").Transparency = 1
	local clueLabel = UI.label("", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.24),
		Size = UDim2.fromOffset(900, 100),
		FontFace = UI.fonts.heavy,
		TextTransparency = 1,
		ZIndex = 20,
		Parent = stage,
	})
	clueLabel:FindFirstChildOfClass("UIStroke").Thickness = 5
	local clueScale = UI.new("UIScale", { Parent = clueLabel })
	local clueGradient = UI.new("UIGradient", { Enabled = false, Parent = clueLabel })

	local function slam(caption: string, text: string, color: Color3)
		captionLabel.Text = caption
		clueLabel.Text = text
		clueLabel.TextColor3 = color
		captionLabel.TextTransparency = 0
		captionLabel:FindFirstChildOfClass("UIStroke").Transparency = 0
		animate(0.2, function(a)
			clueScale.Scale = 2.6 - 1.6 * easeOut(a)
			clueLabel.TextTransparency = 1 - a
			clueLabel:FindFirstChildOfClass("UIStroke").Transparency = 1 - a
		end)
		state.shake = 16 + tier * 2
	end

	local function hideClue()
		animate(0.15, function(a)
			clueLabel.TextTransparency = a
			captionLabel.TextTransparency = a
			clueLabel:FindFirstChildOfClass("UIStroke").Transparency = a
			captionLabel:FindFirstChildOfClass("UIStroke").Transparency = a
		end)
	end

	-- 1. Lights down, the egg drops in.
	animate(0.45, function(a)
		stage.BackgroundTransparency = 1 - a * 0.97
		state.rayAlpha = a * 0.35
	end)
	local egg = UI.eggViewport(result.crate, 320)
	egg.AnchorPoint = Vector2.new(0.5, 0.5)
	egg.Size = UDim2.fromOffset(320, 320)
	egg.ZIndex = 10
	egg.Parent = stage
	animate(0.55, function(a)
		-- Falls, then a little bounce.
		local y = if a < 0.7 then -0.3 + 0.78 * (a / 0.7) ^ 2 else 0.48 - math.sin((a - 0.7) / 0.3 * math.pi) * 0.04
		egg.Position = UDim2.fromScale(0.5, y)
	end)
	state.shake = 10

	-- 2. The egg shakes harder and harder (longer for rarer Freeks).
	local shakeTime = 1 + tier * 0.15
	animate(shakeTime, function(a, t)
		egg.Rotation = math.sin(t * (14 + a * 22)) * (4 + 16 * a * a)
		local grow = 320 + 50 * a
		egg.Size = UDim2.fromOffset(grow, grow)
		state.rayAlpha = 0.35 + 0.4 * a
		state.raySpeed = 8 + 40 * a
	end)

	-- 3. Burst: a face-down card spins out of the light.
	flash(Color3.new(1, 1, 1), 0.45)
	burst(Color3.fromRGB(255, 245, 200), 26)
	egg:Destroy()
	state.raySpeed = 12

	local card = UI.new("Frame", {
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.56),
		Size = UDim2.fromOffset(CARD_W, CARD_H),
		BackgroundColor3 = Color3.fromRGB(28, 30, 70),
		ZIndex = 10,
		Parent = stage,
	}, { UI.corner(18), UI.gradient() })
	local cardStroke = UI.stroke(Color3.fromRGB(255, 205, 70), 5)
	cardStroke.Parent = card
	local cardScale = UI.new("UIScale", { Parent = card })

	-- The back: the game's emblem.
	local back = UI.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 11,
		Parent = card,
	})
	UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(170, 170),
		BackgroundColor3 = Color3.fromRGB(62, 128, 245),
		Rotation = 45,
		ZIndex = 11,
		Parent = back,
	}, { UI.corner(24), UI.stroke(Color3.fromRGB(255, 205, 70), 4), UI.gradient() })
	UI.label("F", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(120, 120),
		FontFace = UI.fonts.heavy,
		TextColor3 = Color3.fromRGB(255, 220, 80),
		ZIndex = 12,
		Parent = back,
	})
	UI.label("FUSE A FREEK", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.new(1, -30, 0, 26),
		FontFace = UI.fonts.heavy,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 12,
		Parent = back,
	})

	animate(0.5, function(a)
		local e = easeOut(a)
		cardScale.Scale = 0.2 + 0.8 * e
		card.Rotation = (1 - e) * -200
	end)
	card.Rotation = 0

	-- The card floats gently while the clues come in.
	local function floatCard(t: number)
		card.Position = UDim2.new(0.5, 0, 0.56, math.sin(t * 2.2) * 6)
	end

	-- 4. Clue one: the series.
	state.rayColor = series.color
	backdrop.Color = ColorSequence.new(series.color:Lerp(Color3.new(0, 0, 0), 0.55), Color3.fromRGB(10, 8, 26))
	slam("SERIES", series.icon .. " " .. string.upper(series.name), series.color)
	cardStroke.Color = series.color
	animate(1.3 + tier * 0.1, function(_, t)
		floatCard(t)
	end)
	hideClue()

	-- 5. Clue two: the rarity, with the lights turning its colour. The rarer it is, the
	-- longer the build-up and the wilder the lights.
	state.rayColor = Color3.new(1, 1, 1)
	state.raySpeed = 20 + tier * 12
	animate(0.35 + tier * 0.12, function(a, t)
		floatCard(t)
		-- Card glows brighter and brighter before the rarity lands.
		cardStroke.Thickness = 5 + 6 * a
		state.rayAlpha = 0.6 + 0.4 * a
	end)
	state.rayColor = rarityColor
	state.rainbow = tier >= 6
	backdrop.Color = ColorSequence.new(rarityColor:Lerp(Color3.new(0, 0, 0), 0.5), Color3.fromRGB(10, 8, 26))
	if tier >= 3 then
		flash(rarityColor:Lerp(Color3.new(1, 1, 1), 0.5), 0.35)
	end
	if state.rainbow then
		local keys = {}
		for k = 0, 6 do
			table.insert(keys, ColorSequenceKeypoint.new(k / 6, Color3.fromHSV(k / 6, 0.75, 1)))
		end
		clueGradient.Color = ColorSequence.new(keys)
		clueGradient.Enabled = true
	end
	slam(
		"RARITY",
		RARITY_WORDS[rarity] or string.upper(rarity),
		if state.rainbow then Color3.new(1, 1, 1) else rarityColor
	)
	cardStroke.Color = rarityColor
	if tier >= 4 then
		burst(rarityColor, 30 + tier * 6, true)
	end
	local lightning = tier >= 5
	local nextStrike = 0.3
	animate(1.2 + tier * 0.25, function(_, t)
		floatCard(t)
		cardStroke.Thickness = 8 + math.sin(t * 8) * 3
		if state.rainbow then
			cardStroke.Color = rainbow(os.clock())
			clueGradient.Offset = Vector2.new(math.sin(t * 2) * 0.5, 0)
		end
		if lightning and t >= nextStrike then
			nextStrike += 0.55
			flash(Color3.fromRGB(220, 200, 255), 0.18)
			state.shake = 14
		end
	end)
	hideClue()
	clueGradient.Enabled = false

	-- 6. The flip: the card turns over to show the Freek.
	animate(0.22, function(a, t)
		floatCard(t)
		card.Size = UDim2.fromOffset(CARD_W * (1 - a), CARD_H)
	end)
	back:Destroy()
	card.BackgroundColor3 = rarityColor:Lerp(Color3.new(0, 0, 0), 0.15)
	local front = UI.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 11,
		Parent = card,
	}, {
		UI.new("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
		UI.new("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
	})
	local chip = UI.label(series.icon .. " " .. string.upper(series.name), {
		Size = UDim2.new(1, 0, 0, 22),
		FontFace = UI.fonts.heavy,
		TextColor3 = series.color:Lerp(Color3.new(1, 1, 1), 0.35),
		LayoutOrder = 1,
		ZIndex = 12,
		Parent = front,
	})
	chip.Name = "Series"
	local picture = UI.viewport(result.freek.species, result.freek.mutations)
	picture.Size = UDim2.new(1, 0, 0, CARD_H - 110)
	local pictureCamera = picture:FindFirstChildOfClass("Camera")
	if pictureCamera then
		pictureCamera.FieldOfView = 29 -- zoom in so the Freek fills the card
	end
	picture.BackgroundTransparency = 0.6
	picture.BackgroundColor3 = Color3.fromRGB(20, 22, 48)
	picture.LayoutOrder = 2
	picture.ZIndex = 12
	UI.corner(12).Parent = picture
	picture.Parent = front
	UI.label(string.upper(rarity), {
		Size = UDim2.new(1, 0, 0, 30),
		FontFace = UI.fonts.heavy,
		TextColor3 = Color3.new(1, 1, 1),
		LayoutOrder = 3,
		ZIndex = 12,
		Parent = front,
	})
	animate(0.22, function(a, t)
		floatCard(t)
		card.Size = UDim2.fromOffset(CARD_W * easeOut(a), CARD_H)
	end)
	card.Size = UDim2.fromOffset(CARD_W, CARD_H)
	flash(Color3.new(1, 1, 1), 0.4)
	burst(rarityColor, 34)
	state.shake = 20

	-- 7. The name slams in under the card, with NEW! if it's new to them.
	local nameLabel = UI.label(string.upper(FreekUtil.displayName(result.freek)), {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.9),
		Size = UDim2.fromOffset(800, 64),
		FontFace = UI.fonts.heavy,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 20,
		Parent = stage,
	})
	nameLabel:FindFirstChildOfClass("UIStroke").Thickness = 4
	local nameScale = UI.new("UIScale", { Parent = nameLabel })
	animate(0.2, function(a)
		nameScale.Scale = 2.2 - 1.2 * easeOut(a)
	end)
	state.shake = 12
	if result.isNew then
		local stamp = UI.label("NEW!", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, CARD_W / 2 - 10, 0.56, -CARD_H / 2),
			Size = UDim2.fromOffset(120, 50),
			FontFace = UI.fonts.heavy,
			TextColor3 = Color3.new(1, 1, 1),
			BackgroundColor3 = UI.colors.red,
			BackgroundTransparency = 0,
			Rotation = 14,
			ZIndex = 22,
			Parent = stage,
		})
		UI.corner(12).Parent = stamp
		UI.stroke(nil, 3).Parent = stamp
		local stampScale = UI.new("UIScale", { Parent = stamp })
		animate(0.18, function(a)
			stampScale.Scale = 2 - easeOut(a)
		end)
	end
	UI.label("It's in your barn!", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.9, 42),
		Size = UDim2.fromOffset(400, 26),
		TextColor3 = Color3.fromRGB(220, 232, 255),
		ZIndex = 20,
		Parent = stage,
	})

	-- 8. Wait for them to tap Awesome!
	local closed = false
	UI.button("AWESOME!", UI.colors.green, function()
		closed = true
	end, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -90, 1, -70),
		Size = UDim2.fromOffset(220, 60),
		ZIndex = 25,
		Parent = stage,
	})
	speed = 1
	while not closed do
		animate(0.2, function(_, t)
			floatCard(t)
			if state.rainbow then
				cardStroke.Color = rainbow(os.clock())
			end
		end)
	end
	animate(0.3, function(a)
		stage.BackgroundTransparency = 0.03 + 0.97 * a
		state.rayAlpha = (1 - a) * 0.6
		cardScale.Scale = 1 - a * 0.6
	end)
	gui:Destroy()
	done()
end

return PackReveal
