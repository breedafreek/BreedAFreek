-- The frame around each barn's doors upgrades with rebirths: Iron, then Bronze, Silver,
-- Gold, Diamond, Emerald, Ruby, Amethyst and finally Rainbow (rebirth 8). The doorway stays the same size; the frame gets chunkier and fancier.
--
-- postWidth: post thickness; finials: balls on the posts; crest: an arch over the name
-- plaque; gems: glowing gems and sparkles; rainbow: the metal cycles through the rainbow.
-- (height is no longer used.)

local GateTiers = {}

GateTiers.list = {
	{
		name = "Iron",
		color = Color3.fromRGB(38, 38, 44),
		material = "Metal",
		height = 11,
		postWidth = 1.6,
	},
	{
		name = "Bronze",
		color = Color3.fromRGB(180, 112, 58),
		material = "Foil",
		height = 12.5,
		postWidth = 2.1,
		finials = true,
	},
	{
		name = "Silver",
		color = Color3.fromRGB(205, 210, 222),
		material = "Foil",
		height = 14,
		postWidth = 2.5,
		finials = true,
		crest = true,
	},
	{
		name = "Gold",
		color = Color3.fromRGB(255, 196, 55),
		material = "Foil",
		height = 15.5,
		postWidth = 2.9,
		finials = true,
		crest = true,
		gems = true,
	},
}

-- The jewel tiers past Gold all share Gold's shape.
for _, jewel in
	{
		{ "Diamond", Color3.fromRGB(170, 235, 255), "Glass" },
		{ "Emerald", Color3.fromRGB(50, 205, 110), "Glass" },
		{ "Ruby", Color3.fromRGB(230, 40, 70), "Glass" },
		{ "Amethyst", Color3.fromRGB(165, 85, 240), "Glass" },
		{ "Rainbow", Color3.fromRGB(255, 90, 160), "Neon" },
	}
do
	table.insert(GateTiers.list, {
		name = jewel[1],
		color = jewel[2],
		material = jewel[3],
		height = 15.5,
		postWidth = 3.1,
		finials = true,
		crest = true,
		gems = true,
		rainbow = jewel[1] == "Rainbow",
	})
end

function GateTiers.forRebirths(rebirths: number): number
	return math.clamp((rebirths or 0) + 1, 1, #GateTiers.list)
end

return GateTiers
