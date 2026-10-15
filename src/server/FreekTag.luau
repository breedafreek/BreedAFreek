-- The floating tag over a Freek, in the chunky cartoon style: rarity on top (in its colour),
-- the name big and bold (in its mutation's colour if it has one), the price in gold for
-- Freeks that are for sale, and the money it makes in green. Everything is outlined.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Rarities = require(ReplicatedStorage.Shared.Rarities)

local FreekTag = {}

local OUTLINE = Color3.fromRGB(20, 22, 48)

local function line(parent: Instance, text: string, color: Color3, top: number, height: number, font: Enum.Font)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0, top)
	label.Size = UDim2.fromScale(1, height)
	label.TextScaled = true
	label.Font = font
	label.Text = text
	label.TextColor3 = color
	label.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE
	stroke.Thickness = 2.5
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	return label
end

-- Adds the tag to anchor, `above` studs over it. price is shown when the Freek is for sale.
function FreekTag.add(anchor: BasePart, freek, above: number, maxDistance: number, price: number?): BillboardGui
	local species = FreekUtil.species(freek)
	local rarity = species and species.rarity or "Common"
	local top = Mutations.top(freek.mutations)
	local lines = if price then 4 else 3
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, lines * 21)
	gui.StudsOffsetWorldSpace = Vector3.new(0, above, 0)
	gui.MaxDistance = maxDistance
	gui.LightInfluence = 0
	local h = 1 / lines
	line(gui, string.upper(rarity), Rarities.info[rarity].color, 0, h * 0.85, Enum.Font.LuckiestGuy)
	line(
		gui,
		FreekUtil.displayName(freek),
		if top then Mutations.byId[top].color else Color3.new(1, 1, 1),
		h * 0.85,
		h * 1.3,
		Enum.Font.FredokaOne
	)
	if price then
		line(gui, Format.money(price), Color3.fromRGB(255, 215, 60), h * 2.15, h * 0.95, Enum.Font.LuckiestGuy)
	end
	line(
		gui,
		Format.money(FreekUtil.income(freek)) .. "/s",
		Color3.fromRGB(110, 240, 120),
		if price then h * 3.1 else h * 2.15,
		h * 0.9,
		Enum.Font.LuckiestGuy
	)
	gui.Parent = anchor
	return gui
end

return FreekTag
