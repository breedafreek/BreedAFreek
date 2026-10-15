-- Mutations multiply a Freek's income. They only enter the game on the conveyor belt
-- (chance is per belt Freek, times Belt.MUTATION_FACTOR); after that they're passed on by
-- breeding (see Breeding.luau). Rarest first.
--
-- A Freek can carry several mutations. They're saved as a list ({ "Rainbow", "Golden" }),
-- or nil for none, and their multipliers stack (Golden + Shadow = x6).

local Mutations = {}

Mutations.list = {
	{ id = "Rainbow", mult = 10, chance = 0.01, color = Color3.fromRGB(255, 120, 255) },
	{ id = "Golden", mult = 3, chance = 0.04, color = Color3.fromRGB(255, 200, 50) },
	{ id = "Shadow", mult = 2, chance = 0.07, color = Color3.fromRGB(160, 90, 255) },
}

Mutations.byId = {}
for index, mutation in Mutations.list do
	mutation.rank = index
	Mutations.byId[mutation.id] = mutation
end

-- A Freek's mutations as a list, rarest first. Accepts a list, a single id (old saves) or nil.
function Mutations.normalize(value): { string }
	local list = {}
	if type(value) == "string" then
		value = { value }
	end
	for _, id in value or {} do
		if Mutations.byId[id] and not table.find(list, id) then
			table.insert(list, id)
		end
	end
	table.sort(list, function(a, b)
		return Mutations.byId[a].rank < Mutations.byId[b].rank
	end)
	return list
end

-- The rarest mutation, which decides how the Freek looks and what colour its name is.
function Mutations.top(value): string?
	return Mutations.normalize(value)[1]
end

-- Combined income multiplier for all of a Freek's mutations.
function Mutations.mult(value): number
	local mult = 1
	for _, id in Mutations.normalize(value) do
		mult *= Mutations.byId[id].mult
	end
	return mult
end

-- The list to store on a Freek record (nil when there are none).
function Mutations.pack(value): { string }?
	local list = Mutations.normalize(value)
	return if #list > 0 then list else nil
end

return Mutations
