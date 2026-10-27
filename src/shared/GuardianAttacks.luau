-- Each zone's guardian has a signature attack, on top of catching anyone it runs into.
-- The server decides when an attack happens and whether it hits (ZoneService); every client
-- draws it (client GuardianAttackFX). Attacks can be dodged and only start in range, so a
-- player with the zone's Speed still gets away.
--
-- kinds:
--   dash       a burst of speed at the target (mult x normal speed for `time` seconds); lift
--              raises the guardian off the ground on the way (a swoop or a leap).
--   projectile thrown or shot at where the target is heading (`lead` of its travel); flies
--              at `speed`, hits anyone within `radius` of it. homing steers it after them.
--              pull: a hit yanks the player back toward the guardian.
--   teleport   vanishes and reappears `ahead` studs in front of the target.
--   beam       aims at the target for `windup` seconds (a thin warning line), then fires a
--              laser `width` wide down that line.
--   strike     marks a circle where the target is heading, and after `windup` seconds
--              lightning hits everything within `radius` of it.

local GuardianAttacks = {}

GuardianAttacks.list = {
	charge = { kind = "dash", name = "Charge", range = 28, mult = 2.2, time = 0.9, cooldown = 3 },
	pounce = { kind = "dash", name = "Pounce", range = 22, mult = 2.8, time = 0.6, cooldown = 2.6, lift = 6 },
	swoop = { kind = "dash", name = "Swoop", range = 36, mult = 2.4, time = 1, cooldown = 3.4, lift = 16 },
	pie = {
		kind = "projectile",
		name = "Pie Throw",
		range = 40,
		speed = 60,
		radius = 3.5,
		lead = 0.7,
		cooldown = 2.4,
		color = Color3.fromRGB(240, 205, 150),
	},
	bandage = {
		kind = "projectile",
		name = "Bandage Lash",
		range = 34,
		speed = 75,
		radius = 3,
		lead = 0.6,
		cooldown = 2.8,
		pull = true,
		color = Color3.fromRGB(245, 240, 225),
	},
	magic = {
		kind = "projectile",
		name = "Magic Orb",
		range = 44,
		speed = 42,
		radius = 4,
		lead = 0.3,
		homing = 1.4,
		cooldown = 3,
		color = Color3.fromRGB(255, 120, 220),
	},
	blink = { kind = "teleport", name = "Vanish", range = 70, ahead = 12, cooldown = 4.5 },
	bats = {
		kind = "projectile",
		name = "Bat Swarm",
		range = 46,
		speed = 46,
		radius = 5.5,
		lead = 0.4,
		homing = 1.6,
		cooldown = 3.4,
		color = Color3.fromRGB(60, 45, 80),
	},
	laser = { kind = "beam", name = "Eye Laser", range = 60, windup = 0.9, width = 3, cooldown = 3.6 },
	lightning = { kind = "strike", name = "Lightning", range = 70, windup = 1.1, radius = 7, lead = 1, cooldown = 3 },
}

-- Which attack each guardian (by species) uses.
GuardianAttacks.bySpecies = {
	Oinkle = "charge",
	Woofles = "pounce",
	Hootsworth = "swoop",
	Chuckles = "pie",
	Mumbles = "bandage",
	Glamora = "magic",
	BooBoo = "blink",
	CountFangula = "bats",
	Blinky = "laser",
	Stormy = "lightning",
}

function GuardianAttacks.forSpecies(species: string)
	local id = GuardianAttacks.bySpecies[species] or "charge"
	return id, GuardianAttacks.list[id]
end

return GuardianAttacks
