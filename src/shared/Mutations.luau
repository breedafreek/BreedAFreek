-- Mutations a bred Freek can roll. Rarest first: breeding checks them in this order.
-- chance is per breed; it is multiplied by INHERIT_BOOST when a parent has that mutation.

local Mutations = {}

Mutations.INHERIT_BOOST = 4

Mutations.list = {
	{ id = "Rainbow", mult = 10, chance = 0.01, color = Color3.fromRGB(255, 120, 255) },
	{ id = "Golden", mult = 3, chance = 0.04, color = Color3.fromRGB(255, 200, 50) },
	{ id = "Shadow", mult = 2, chance = 0.07, color = Color3.fromRGB(160, 90, 255) },
}

Mutations.byId = {}
for _, mutation in Mutations.list do
	Mutations.byId[mutation.id] = mutation
end

function Mutations.mult(id: string?): number
	local mutation = id and Mutations.byId[id]
	return if mutation then mutation.mult else 1
end

return Mutations
