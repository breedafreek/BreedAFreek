-- One model for any item (see Items.luau), standing on its pivot: a house part as a small
-- item (HouseModel.item), a pet (FreekModel), a yard item (YardModel) or a plant
-- (PlantModel). Mutated items sparkle in their mutation's colour.

local FreekModel = require(script.Parent.FreekModel)
local HouseModel = require(script.Parent.HouseModel)
local Items = require(script.Parent.Items)
local Mutations = require(script.Parent.Mutations)
local PlantModel = require(script.Parent.PlantModel)
local YardModel = require(script.Parent.YardModel)

local ItemModel = {}

-- A sparkle on mutated models, in the mutation's colour.
function ItemModel.addMutationEffect(model: Model, mutations)
	local top = Mutations.top(mutations)
	local base = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if top and base and not base:FindFirstChildOfClass("Sparkles") then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Mutations.byId[top].color
		sparkles.Parent = base
	end
end

-- record = { id, mutations, weight?, baseWeight? }. Heavier items are drawn bigger
-- (Items.weightScale); house parts stay their normal size (they have to fit their slot).
function ItemModel.build(record): Model
	local model = ItemModel.buildNormal(record.id, record.mutations)
	local item = Items.byId[record.id]
	if item and item.kind ~= "House" then
		Items.scaleModel(model, Items.weightScale(Items.weightFactor(record)))
	end
	return model
end

function ItemModel.buildNormal(itemId: string, mutations): Model
	local item = Items.byId[itemId]
	local model
	if not item then
		model = Instance.new("Model")
	elseif item.kind == "House" then
		model = HouseModel.item(itemId)
	elseif item.kind == "Pet" then
		-- Pets show their mutations with FreekModel's own effects.
		model = FreekModel.build(item.species, mutations)
		model:SetAttribute("Item", itemId)
		return model
	elseif item.kind == "Yard" then
		model = YardModel.build(itemId)
	else
		model = PlantModel.build(itemId)
	end
	ItemModel.addMutationEffect(model, mutations)
	return model
end

return ItemModel
