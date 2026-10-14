-- Weapons. Everyone has the STARTER weapon; the rest are bought in the shop (price).
-- Weapons hit anyone EXCEPT a player standing inside their own yard (their safe zone).
--
-- kind "melee": hits players within range in front of you.
-- kind "projectile": fires a ball toward where you aim; speed/range in studs.
-- effect "drop": a target carrying a Freek drops it (it goes home to its owner); anyone else
--   is knocked back (knockback strength) and falls over for stunSeconds.
-- effect "glue": the target is stuck to the nearest wall for glueSeconds.
--
-- After a stun or glue wears off, the target is immune for IMMUNE_SECONDS.
--
-- model is the weapon's look; the format is described in WeaponModel.luau.

local Weapons = {}

Weapons.STARTER = "BonkBat"
Weapons.IMMUNE_SECONDS = 3

Weapons.order = { "BonkBat", "CandyCannon", "GlueGun" }

Weapons.list = {
	BonkBat = {
		name = "Bonk Bat",
		description = "Bonk someone up close. Thieves drop the Freek they're carrying.",
		kind = "melee",
		effect = "drop",
		knockback = 45,
		stunSeconds = 1,
		range = 8,
		cooldown = 0.6,
		color = Color3.fromRGB(205, 150, 90),
		-- A chunky wooden club with a taped grip. The grip runs along Z; the fat end is +Z.
		model = {
			{
				shape = "Block",
				size = { 0.3, 0.3, 1.8 },
				pos = { 0, 0, 0 },
				color = Color3.fromRGB(190, 135, 80),
				material = "Wood",
			},
			{
				shape = "Cylinder",
				size = { 1.8, 0.45, 0.45 },
				pos = { 0, 0, 0 },
				rot = { 0, 90, 0 },
				color = Color3.fromRGB(190, 135, 80),
				material = "Wood",
			},
			{
				shape = "Cylinder",
				size = { 0.22, 0.75, 0.75 },
				pos = { 0, 0, -1 },
				rot = { 0, 90, 0 },
				color = Color3.fromRGB(120, 80, 45),
				material = "Wood",
			},
			{
				shape = "Cylinder",
				size = { 0.14, 0.52, 0.52 },
				pos = { 0, 0, -0.55 },
				rot = { 0, 90, 0 },
				color = Color3.fromRGB(210, 50, 50),
			},
			{
				shape = "Cylinder",
				size = { 0.14, 0.52, 0.52 },
				pos = { 0, 0, -0.1 },
				rot = { 0, 90, 0 },
				color = Color3.fromRGB(210, 50, 50),
			},
			{
				shape = "Cylinder",
				size = { 0.14, 0.52, 0.52 },
				pos = { 0, 0, 0.35 },
				rot = { 0, 90, 0 },
				color = Color3.fromRGB(210, 50, 50),
			},
			{
				shape = "Cylinder",
				size = { 1.1, 0.6, 0.6 },
				pos = { 0, 0, 1.4 },
				rot = { 0, 90, 0 },
				color = Color3.fromRGB(205, 150, 90),
				material = "Wood",
			},
			{
				shape = "Cylinder",
				size = { 1.1, 0.8, 0.8 },
				pos = { 0, 0, 2.4 },
				rot = { 0, 90, 0 },
				color = Color3.fromRGB(210, 155, 95),
				material = "Wood",
			},
			{
				shape = "Cylinder",
				size = { 1.3, 1.05, 1.05 },
				pos = { 0, 0, 3.55 },
				rot = { 0, 90, 0 },
				color = Color3.fromRGB(215, 160, 100),
				material = "Wood",
			},
			{
				shape = "Cylinder",
				size = { 0.18, 1.09, 1.09 },
				pos = { 0, 0, 3.2 },
				rot = { 0, 90, 0 },
				color = Color3.fromRGB(60, 40, 25),
			},
			{
				shape = "Ball",
				size = 1.05,
				pos = { 0, 0, 4.2 },
				color = Color3.fromRGB(215, 160, 100),
				material = "Wood",
			},
		},
	},
	CandyCannon = {
		name = "Candy Cannon",
		description = "Shoot a candy ball. Thieves drop the Freek they're carrying.",
		kind = "projectile",
		effect = "drop",
		knockback = 60,
		stunSeconds = 1.2,
		price = 2500,
		cooldown = 2.5,
		speed = 90,
		range = 120,
		ball = { size = 1.4, color = Color3.fromRGB(255, 110, 190) },
		color = Color3.fromRGB(255, 130, 200),
		-- A candy-striped barrel with a lollipop sight. Points toward -Z.
		model = {
			{ shape = "Block", size = { 0.4, 0.8, 0.4 }, pos = { 0, 0, 0 }, transparency = 1 },
			{
				shape = "Block",
				size = { 0.5, 1.1, 0.65 },
				pos = { 0, 0, 0 },
				rot = { -15, 0, 0 },
				color = Color3.fromRGB(200, 60, 140),
			},
			{
				shape = "Cylinder",
				size = { 3.2, 1.4, 1.4 },
				pos = { 0, 0.85, -0.9 },
				rot = { 0, 90, 0 },
				color = Color3.fromRGB(255, 130, 200),
			},
			{
				shape = "Cylinder",
				size = { 0.28, 1.46, 1.46 },
				pos = { 0, 0.85, 0.2 },
				rot = { 0, 90, 0 },
				color = Color3.new(1, 1, 1),
			},
			{
				shape = "Cylinder",
				size = { 0.28, 1.46, 1.46 },
				pos = { 0, 0.85, -0.6 },
				rot = { 0, 90, 0 },
				color = Color3.new(1, 1, 1),
			},
			{
				shape = "Cylinder",
				size = { 0.28, 1.46, 1.46 },
				pos = { 0, 0.85, -1.4 },
				rot = { 0, 90, 0 },
				color = Color3.new(1, 1, 1),
			},
			{
				shape = "Cylinder",
				size = { 0.5, 1.8, 1.8 },
				pos = { 0, 0.85, -2.6 },
				rot = { 0, 90, 0 },
				color = Color3.fromRGB(230, 40, 120),
			},
			{
				shape = "Ball",
				size = 1.15,
				pos = { 0, 0.85, -2.75 },
				color = Color3.fromRGB(255, 220, 90),
				material = "Neon",
			},
			{ shape = "Ball", size = 1.4, pos = { 0, 0.85, 0.7 }, color = Color3.fromRGB(255, 130, 200) },
			{
				shape = "Block",
				size = { 0.18, 0.4, 0.18 },
				pos = { 0, 0.2, -0.45 },
				color = Color3.fromRGB(255, 220, 90),
			},
			{
				shape = "Cylinder",
				size = { 0.9, 0.12, 0.12 },
				pos = { 0, 1.9, -0.7 },
				rot = { 0, 0, 90 },
				color = Color3.new(1, 1, 1),
			},
			{ shape = "Ball", size = 0.7, pos = { 0, 2.45, -0.7 }, color = Color3.fromRGB(120, 220, 255) },
		},
	},
	GlueGun = {
		name = "Glue Gun",
		description = "Glue anyone to the nearest wall for 5 seconds.",
		kind = "projectile",
		effect = "glue",
		price = 10000,
		cooldown = 8,
		speed = 70,
		range = 90,
		glueSeconds = 5,
		ball = { size = 1.2, color = Color3.fromRGB(120, 230, 80) },
		color = Color3.fromRGB(120, 230, 80),
		-- A hot-glue gun with a glue tank on top and a dripping nozzle. Points toward -Z.
		model = {
			{ shape = "Block", size = { 0.4, 0.8, 0.4 }, pos = { 0, 0, 0 }, transparency = 1 },
			{
				shape = "Block",
				size = { 0.6, 1.4, 0.7 },
				pos = { 0, 0, 0 },
				rot = { -15, 0, 0 },
				color = Color3.fromRGB(60, 150, 50),
			},
			{ shape = "Block", size = { 0.85, 1.1, 2.4 }, pos = { 0, 1, -0.6 }, color = Color3.fromRGB(90, 200, 70) },
			{
				shape = "Cylinder",
				size = { 0.8, 0.5, 0.5 },
				pos = { 0, 1.1, -2.2 },
				rot = { 0, 90, 0 },
				color = Color3.fromRGB(170, 170, 180),
				material = "Metal",
			},
			{
				shape = "Cylinder",
				size = { 0.45, 0.26, 0.26 },
				pos = { 0, 1.1, -2.8 },
				rot = { 0, 90, 0 },
				color = Color3.fromRGB(150, 150, 160),
				material = "Metal",
			},
			{
				shape = "Ball",
				size = 0.4,
				pos = { 0, 0.82, -3 },
				color = Color3.fromRGB(150, 255, 90),
				material = "Glass",
				transparency = 0.2,
			},
			{
				shape = "Cylinder",
				size = { 1.5, 0.5, 0.5 },
				pos = { 0, 1.1, 1.2 },
				rot = { 0, 90, 0 },
				color = Color3.fromRGB(255, 250, 200),
				material = "Glass",
				transparency = 0.25,
			},
			{
				shape = "Cylinder",
				size = { 0.9, 0.75, 0.75 },
				pos = { 0, 1.95, -0.4 },
				rot = { 0, 0, 90 },
				color = Color3.fromRGB(150, 255, 90),
				material = "Glass",
				transparency = 0.3,
			},
			{
				shape = "Cylinder",
				size = { 0.12, 0.8, 0.8 },
				pos = { 0, 2.42, -0.4 },
				rot = { 0, 0, 90 },
				color = Color3.fromRGB(60, 150, 50),
			},
			{
				shape = "Block",
				size = { 0.2, 0.45, 0.2 },
				pos = { 0, 0.3, -0.5 },
				color = Color3.fromRGB(255, 220, 60),
			},
		},
	},
}

return Weapons
