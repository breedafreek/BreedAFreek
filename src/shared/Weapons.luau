-- Weapons for defending your Freeks. Everyone has the STARTER weapon; the rest are bought in
-- the shop (price). Weapons only affect players carrying one of your Freeks, except the Glue
-- Gun, which also works on anyone inside your yard.
--
-- kind "melee": hits players within range in front of you.
-- kind "projectile": fires a ball toward where you aim; speed/range in studs.
-- effect "drop": the target drops your Freek and it goes home.
-- effect "glue": the target is stuck to the nearest wall for glueSeconds.

local Weapons = {}

Weapons.STARTER = "BonkBat"

Weapons.order = { "BonkBat", "CandyCannon", "GlueGun" }

Weapons.list = {
	BonkBat = {
		name = "Bonk Bat",
		description = "Bonk a thief up close to make them drop your Freek.",
		kind = "melee",
		effect = "drop",
		range = 8,
		cooldown = 0.6,
		handle = { size = Vector3.new(0.7, 0.7, 4.2), color = Color3.fromRGB(150, 100, 60), material = "Wood" },
	},
	CandyCannon = {
		name = "Candy Cannon",
		description = "Shoot a candy ball at a thief to make them drop your Freek.",
		kind = "projectile",
		effect = "drop",
		price = 2500,
		cooldown = 2.5,
		speed = 90,
		range = 120,
		ball = { size = 1.4, color = Color3.fromRGB(255, 110, 190) },
		handle = { size = Vector3.new(1, 1, 3), color = Color3.fromRGB(255, 150, 210), material = "SmoothPlastic" },
	},
	GlueGun = {
		name = "Glue Gun",
		description = "Glue a thief or intruder to the nearest wall for 5 seconds.",
		kind = "projectile",
		effect = "glue",
		price = 10000,
		cooldown = 8,
		speed = 70,
		range = 90,
		glueSeconds = 5,
		ball = { size = 1.2, color = Color3.fromRGB(120, 230, 80) },
		handle = { size = Vector3.new(0.9, 1.2, 2.4), color = Color3.fromRGB(90, 200, 70), material = "SmoothPlastic" },
	},
}

return Weapons
