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
		handle = { size = Vector3.new(0.7, 0.7, 4.2), color = Color3.fromRGB(150, 100, 60), material = "Wood" },
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
		handle = { size = Vector3.new(1, 1, 3), color = Color3.fromRGB(255, 150, 210), material = "SmoothPlastic" },
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
		handle = { size = Vector3.new(0.9, 1.2, 2.4), color = Color3.fromRGB(90, 200, 70), material = "SmoothPlastic" },
	},
}

return Weapons
