-- Builds the Tool for a weapon from its part list in Weapons.luau.
--
-- Part list format (same as Freeks), in studs, relative to the grip:
--   { shape = "Ball" | "Block" | "Cylinder" | "Wedge", size = { x, y, z } (or one number),
--     pos = { x, y, z }, rot = { x, y, z } (degrees), color = Color3,
--     material = "Neon" etc. (optional), transparency = 0-1 (optional) }
-- The first part becomes the Handle (where the hand holds it). It must not be rotated, since
-- its orientation decides how the weapon sits in the hand; hide a plain block inside the
-- visible grip if needed. Guns point toward -Z; melee weapons extend toward +Z.

local Weapons = require(script.Parent.Weapons)

local WeaponModel = {}

local SHAPES = {
	Ball = Enum.PartType.Ball,
	Block = Enum.PartType.Block,
	Cylinder = Enum.PartType.Cylinder,
}

local function vector(value): Vector3
	if type(value) == "number" then
		return Vector3.one * value
	end
	return Vector3.new(value[1], value[2], value[3])
end

function WeaponModel.build(weaponId: string): Tool
	local weapon = Weapons.list[weaponId]
	local tool = Instance.new("Tool")
	tool.Name = weapon.name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = weapon.description
	if weapon.kind == "melee" then
		-- Held like Roblox's classic sword: pointing up and forward from the hand.
		tool.GripForward = Vector3.new(-1, 0, 0)
		tool.GripRight = Vector3.new(0, 1, 0)
		tool.GripUp = Vector3.new(0, 0, 1)
		tool.GripPos = Vector3.zero
	end
	tool:SetAttribute("WeaponId", weaponId)

	local handle
	for i, spec in weapon.model do
		local part
		if spec.shape == "Wedge" then
			part = Instance.new("WedgePart")
		else
			part = Instance.new("Part")
			part.Shape = SHAPES[spec.shape or "Block"] or Enum.PartType.Block
		end
		part.Name = if i == 1 then "Handle" else "Part" .. i
		part.Size = vector(spec.size)
		local rot = spec.rot or { 0, 0, 0 }
		-- Every part is placed in the tool's own space (not relative to the handle's rotation).
		part.CFrame = CFrame.new(vector(spec.pos)) * CFrame.Angles(math.rad(rot[1]), math.rad(rot[2]), math.rad(rot[3]))
		part.Color = spec.color or Color3.new(1, 1, 1)
		part.Material = Enum.Material[spec.material or "SmoothPlastic"]
		part.Transparency = spec.transparency or 0
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.CanCollide = false
		part.CanTouch = false
		part.Massless = true
		part.Anchored = false
		if handle then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = part
			weld.Parent = part
		else
			handle = part
		end
		part.Parent = tool
	end
	return tool
end

return WeaponModel
