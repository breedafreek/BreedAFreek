-- Every creature in the game: the pets you hatch (the Pet items in Items.luau, which use
-- the same ids) and the zones' giant guardians (Items.ZONES[...].guardian; the Gnome only
-- guards).
--
-- id    unique key saved in player data (as "Pet_<id>"); never rename one after release
-- name  shown to players
-- walk  how it moves: waddle, trot, prowl, slither, stomp, flap, bounce, strut, catwalk,
--       shamble or float (FreekAnimator.WALKS)
-- look  how the model is built: a part list in the crafted look (CraftedFreeks.luau)

local CraftedFreeks = require(script.Parent.CraftedFreeks)

local Freeks = {}

local function species(id: string, name: string, walk: string)
	return { id = id, name = name, walk = walk, look = CraftedFreeks[id]() }
end

Freeks.list = {
	species("GoldenRetriever", "Golden Retriever", "trot"),
	species("TabbyCat", "Orange Tabby Cat", "prowl"),
	species("PetBunny", "Pet Bunny", "bounce"),
	species("BeachCrab", "Beach Crab", "waddle"),
	species("BrownBear", "Brown Bear", "stomp"),
	species("RedFox", "Red Fox", "prowl"),
	species("BabyDeer", "Baby Deer", "trot"),
	species("RobotButler", "Robot Butler", "strut"),
	species("WhiteTiger", "White Tiger", "prowl"),
	species("BabyDragon", "Baby Dragon", "flap"),
	species("Unicorn", "Unicorn", "trot"),
	species("Alien", "Alien", "bounce"),
	species("AlienRobot", "Alien Robot", "stomp"),
	species("RainbowPhoenix", "Rainbow Phoenix", "flap"),
	species("Gnome", "Garden Gnome", "waddle"),
}

Freeks.byId = {}
for i, entry in Freeks.list do
	entry.order = i
	Freeks.byId[entry.id] = entry
end

return Freeks
