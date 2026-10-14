-- Weapons players can bonk thieves with. Everyone spawns with the STARTER weapon.
-- range is in studs (in front of the player); cooldown is seconds between swings.
-- More weapons can be added here later (e.g. sold in the shop).

local Weapons = {}

Weapons.STARTER = "BonkBat"

Weapons.list = {
	BonkBat = {
		name = "Bonk Bat",
		range = 8,
		cooldown = 0.6,
		color = Color3.fromRGB(150, 100, 60),
		size = Vector3.new(0.7, 0.7, 4.2),
	},
}

return Weapons
