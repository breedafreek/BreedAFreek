-- The frame around each barn's doors upgrades with rebirths: Iron, then Bronze, Silver and
-- Gold. The doorway stays the same size; the frame gets chunkier and fancier.
--
-- postWidth: post thickness; finials: balls on the posts; crest: an arch over the name
-- sign; gems: glowing gems and sparkles. (height is no longer used.)

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

function GateTiers.forRebirths(rebirths: number): number
	return math.clamp((rebirths or 0) + 1, 1, #GateTiers.list)
end

return GateTiers
