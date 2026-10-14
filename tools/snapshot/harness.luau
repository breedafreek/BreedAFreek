-- Runs src/shared/FreekModel.luau against minimal stand-ins for Roblox types and prints
-- every part of each built model as JSON, for render.mjs to draw.
--
-- ARGS: harness.luau <src/shared dir> [speciesId[:Mutation] ...]   (no ids = every Freek)

local SHARED = ARGS[2]

--------------------------------------------------------------------------------
-- Vector3
--------------------------------------------------------------------------------

local V3 = {}
local function v3(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
end
V3.__add = function(a, b)
	return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
V3.__sub = function(a, b)
	return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
V3.__unm = function(a)
	return v3(-a.X, -a.Y, -a.Z)
end
V3.__mul = function(a, b)
	if type(a) == "number" then
		return v3(a * b.X, a * b.Y, a * b.Z)
	elseif type(b) == "number" then
		return v3(a.X * b, a.Y * b, a.Z * b)
	end
	return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	if type(b) == "number" then
		return v3(a.X / b, a.Y / b, a.Z / b)
	end
	return v3(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3.__index = function(self, key)
	if key == "Magnitude" then
		return math.sqrt(self.X ^ 2 + self.Y ^ 2 + self.Z ^ 2)
	elseif key == "Unit" then
		local m = math.sqrt(self.X ^ 2 + self.Y ^ 2 + self.Z ^ 2)
		return if m == 0 then v3() else v3(self.X / m, self.Y / m, self.Z / m)
	elseif key == "Lerp" then
		return function(a, b, t)
			return a + (b - a) * t
		end
	elseif key == "Dot" then
		return function(a, b)
			return a.X * b.X + a.Y * b.Y + a.Z * b.Z
		end
	elseif key == "Cross" then
		return function(a, b)
			return v3(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
		end
	end
	return nil
end
Vector3 = {
	new = v3,
	one = v3(1, 1, 1),
	zero = v3(0, 0, 0),
	xAxis = v3(1, 0, 0),
	yAxis = v3(0, 1, 0),
	zAxis = v3(0, 0, 1),
}

--------------------------------------------------------------------------------
-- CFrame: position p and rotation matrix r (row-major, 9 numbers)
--------------------------------------------------------------------------------

local CF = {}
local function cf(p, r)
	return setmetatable({ p = p, r = r or { 1, 0, 0, 0, 1, 0, 0, 0, 1 } }, CF)
end
local function matmul(a, b)
	local out = {}
	for i = 0, 2 do
		for j = 0, 2 do
			out[i * 3 + j + 1] = a[i * 3 + 1] * b[j + 1] + a[i * 3 + 2] * b[j + 4] + a[i * 3 + 3] * b[j + 7]
		end
	end
	return out
end
local function rotate(r, v)
	return v3(
		r[1] * v.X + r[2] * v.Y + r[3] * v.Z,
		r[4] * v.X + r[5] * v.Y + r[6] * v.Z,
		r[7] * v.X + r[8] * v.Y + r[9] * v.Z
	)
end
local function transpose(r)
	return { r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] }
end
CF.__mul = function(a, b)
	if getmetatable(b) == CF then
		return cf(a.p + rotate(a.r, b.p), matmul(a.r, b.r))
	end
	return a.p + rotate(a.r, b)
end
CF.__add = function(a, v)
	return cf(a.p + v, a.r)
end
CF.__sub = function(a, v)
	return cf(a.p - v, a.r)
end
CF.__index = function(self, key)
	if key == "Position" then
		return self.p
	elseif key == "X" then
		return self.p.X
	elseif key == "Y" then
		return self.p.Y
	elseif key == "Z" then
		return self.p.Z
	elseif key == "LookVector" then
		return v3(-self.r[3], -self.r[6], -self.r[9])
	elseif key == "RightVector" then
		return v3(self.r[1], self.r[4], self.r[7])
	elseif key == "UpVector" then
		return v3(self.r[2], self.r[5], self.r[8])
	elseif key == "Rotation" then
		return cf(v3(), self.r)
	elseif key == "Inverse" then
		return function(c)
			local rt = transpose(c.r)
			return cf(-rotate(rt, c.p), rt)
		end
	elseif key == "Lerp" then
		return function(a, b, t)
			return cf(a.p + (b.p - a.p) * t, if t < 0.5 then a.r else b.r)
		end
	end
	return nil
end
local function axis(name, angle)
	local c, s = math.cos(angle), math.sin(angle)
	if name == "x" then
		return { 1, 0, 0, 0, c, -s, 0, s, c }
	elseif name == "y" then
		return { c, 0, s, 0, 1, 0, -s, 0, c }
	end
	return { c, -s, 0, s, c, 0, 0, 0, 1 }
end
local function angles(rx, ry, rz)
	return cf(v3(), matmul(matmul(axis("x", rx or 0), axis("y", ry or 0)), axis("z", rz or 0)))
end
CFrame = {
	new = function(x, y, z)
		if x == nil then
			return cf(v3())
		elseif type(x) == "table" then
			return cf(x)
		end
		return cf(v3(x, y, z))
	end,
	Angles = angles,
	fromEulerAnglesXYZ = angles,
	fromOrientation = function(rx, ry, rz)
		return cf(v3(), matmul(matmul(axis("y", ry), axis("x", rx)), axis("z", rz)))
	end,
	lookAt = function(eye, target, up)
		up = up or v3(0, 1, 0)
		local back = (eye - target).Unit
		local right = up:Cross(back).Unit
		local newUp = back:Cross(right)
		return cf(eye, { right.X, newUp.X, back.X, right.Y, newUp.Y, back.Y, right.Z, newUp.Z, back.Z })
	end,
}
CFrame.identity = cf(v3())

--------------------------------------------------------------------------------
-- Color3, UDim, Enum, misc
--------------------------------------------------------------------------------

local C3 = {}
local function c3(r, g, b)
	return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3)
end
C3.__index = {
	Lerp = function(a, b, t)
		return c3(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
	end,
}
Color3 = {
	new = c3,
	fromRGB = function(r, g, b)
		return c3(r / 255, g / 255, b / 255)
	end,
	fromHSV = function(h, s, v)
		local i = math.floor(h * 6)
		local f = h * 6 - i
		local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
		local k = i % 6
		if k == 0 then
			return c3(v, t, p)
		elseif k == 1 then
			return c3(q, v, p)
		elseif k == 2 then
			return c3(p, v, t)
		elseif k == 3 then
			return c3(p, q, v)
		elseif k == 4 then
			return c3(t, p, v)
		end
		return c3(v, p, q)
	end,
}

local function passthrough(...)
	return { ... }
end
UDim = { new = passthrough }
UDim2 = { new = passthrough, fromScale = passthrough, fromOffset = passthrough }
NumberRange = { new = passthrough }
NumberSequence = { new = passthrough }
ColorSequence = { new = passthrough }

Enum = setmetatable({}, {
	__index = function(enums, enumType)
		local items = setmetatable({}, {
			__index = function(list, name)
				local item = { EnumType = enumType, Name = name }
				rawset(list, name, item)
				return item
			end,
		})
		rawset(enums, enumType, items)
		return items
	end,
})

--------------------------------------------------------------------------------
-- Instances
--------------------------------------------------------------------------------

local PART_CLASSES = { Part = true, WedgePart = true, CornerWedgePart = true, MeshPart = true, TrussPart = true }
local DEFAULTS = {
	Part = function()
		return {
			Size = v3(4, 1, 2),
			CFrame = cf(v3()),
			PivotOffset = cf(v3()),
			Color = Color3.fromRGB(163, 162, 165),
			Material = Enum.Material.Plastic,
			Transparency = 0,
			Shape = Enum.PartType.Block,
			Reflectance = 0,
		}
	end,
}
DEFAULTS.WedgePart = DEFAULTS.Part
DEFAULTS.CornerWedgePart = DEFAULTS.Part

local Inst = {}
local methods = {}

local function new(className)
	local props = if DEFAULTS[className] then DEFAULTS[className]() else {}
	props.Name = className
	props.ClassName = className
	local self = setmetatable({ _props = props, _children = {}, _tags = {}, _attrs = {} }, Inst)
	return self
end

Inst.__index = function(self, key)
	if methods[key] then
		return methods[key]
	end
	local props = rawget(self, "_props")
	if key == "Position" and props.CFrame then
		return props.CFrame.p
	end
	local value = props[key]
	if value ~= nil then
		return value
	end
	return methods.FindFirstChild(self, key)
end
Inst.__newindex = function(self, key, value)
	local props = rawget(self, "_props")
	if key == "Parent" then
		local old = props.Parent
		if old then
			local list = rawget(old, "_children")
			local i = table.find(list, self)
			if i then
				table.remove(list, i)
			end
		end
		props.Parent = value
		if value then
			table.insert(rawget(value, "_children"), self)
		end
	elseif key == "Position" then
		props.CFrame = cf(value, props.CFrame.r)
	else
		props[key] = value
	end
end

function methods.IsA(self, className)
	local own = self.ClassName
	return own == className
		or (className == "BasePart" and PART_CLASSES[own] == true)
		or (className == "PVInstance" and (PART_CLASSES[own] or own == "Model"))
		or className == "Instance"
end
function methods.GetChildren(self)
	return table.clone(rawget(self, "_children"))
end
function methods.GetDescendants(self)
	local out = {}
	local function walk(node)
		for _, child in rawget(node, "_children") do
			table.insert(out, child)
			walk(child)
		end
	end
	walk(self)
	return out
end
function methods.FindFirstChild(self, name, recursive)
	local list = if recursive then methods.GetDescendants(self) else rawget(self, "_children")
	for _, child in list do
		if child.Name == name then
			return child
		end
	end
	return nil
end
function methods.WaitForChild(self, name)
	return methods.FindFirstChild(self, name)
end
function methods.FindFirstChildWhichIsA(self, className, recursive)
	local list = if recursive then methods.GetDescendants(self) else rawget(self, "_children")
	for _, child in list do
		if child:IsA(className) then
			return child
		end
	end
	return nil
end
function methods.FindFirstChildOfClass(self, className)
	for _, child in rawget(self, "_children") do
		if child.ClassName == className then
			return child
		end
	end
	return nil
end
function methods.SetAttribute(self, key, value)
	rawget(self, "_attrs")[key] = value
end
function methods.GetAttribute(self, key)
	return rawget(self, "_attrs")[key]
end
function methods.Destroy(self)
	self.Parent = nil
end
function methods.ClearAllChildren(self)
	for _, child in methods.GetChildren(self) do
		child.Parent = nil
	end
end
function methods.Clone(self)
	local copy = new(self.ClassName)
	for key, value in rawget(self, "_props") do
		if key ~= "Parent" then
			rawget(copy, "_props")[key] = value
		end
	end
	for _, child in rawget(self, "_children") do
		methods.Clone(child).Parent = copy
	end
	return copy
end

local function parts(model)
	local out = {}
	if model:IsA("BasePart") then
		table.insert(out, model)
	end
	for _, d in methods.GetDescendants(model) do
		if d:IsA("BasePart") then
			table.insert(out, d)
		end
	end
	return out
end
function methods.GetPivot(self)
	if self:IsA("BasePart") then
		return self.CFrame * self.PivotOffset
	end
	local primary = self.PrimaryPart
	if primary then
		return primary.CFrame * primary.PivotOffset
	end
	return rawget(self, "_props").WorldPivot or cf(v3())
end
function methods.PivotTo(self, target)
	local delta = target * methods.GetPivot(self):Inverse()
	for _, part in parts(self) do
		rawget(part, "_props").CFrame = delta * part.CFrame
	end
	if not self:IsA("BasePart") and not self.PrimaryPart then
		rawget(self, "_props").WorldPivot = target
	end
end
function methods.GetBoundingBox(self)
	local lo, hi = v3(math.huge, math.huge, math.huge), v3(-math.huge, -math.huge, -math.huge)
	for _, part in parts(self) do
		local half = part.Size / 2
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local corner = part.CFrame * v3(half.X * sx, half.Y * sy, half.Z * sz)
					lo = v3(math.min(lo.X, corner.X), math.min(lo.Y, corner.Y), math.min(lo.Z, corner.Z))
					hi = v3(math.max(hi.X, corner.X), math.max(hi.Y, corner.Y), math.max(hi.Z, corner.Z))
				end
			end
		end
	end
	return cf((lo + hi) / 2), hi - lo
end
function methods.GetExtentsSize(self)
	local _, size = methods.GetBoundingBox(self)
	return size
end

Instance = { new = new }

--------------------------------------------------------------------------------
-- game, services, script/require
--------------------------------------------------------------------------------

local services = {}
local function service(name)
	if not services[name] then
		local s = new(name)
		services[name] = s
	end
	return services[name]
end
local CollectionService = service("CollectionService")
rawset(CollectionService, "AddTag", function(_, instance, tag)
	rawget(instance, "_tags")[tag] = true
end)
rawset(CollectionService, "HasTag", function(_, instance, tag)
	return rawget(instance, "_tags")[tag] == true
end)
rawset(CollectionService, "GetTagged", function()
	return {}
end)
local RunService = service("RunService")
rawset(RunService, "IsServer", function()
	return true
end)
rawset(RunService, "IsClient", function()
	return false
end)
rawset(RunService, "IsStudio", function()
	return false
end)

game = new("DataModel")
rawset(game, "GetService", function(_, name)
	return service(name)
end)
workspace = service("Workspace")

local cache = {}
local function moduleRef(path)
	return { __module = path }
end
local function folderFor(dir)
	return setmetatable({}, {
		__index = function(_, name)
			return moduleRef(dir .. "/" .. name .. ".luau")
		end,
	})
end

local realRequire = require
function require(ref)
	if type(ref) ~= "table" or not ref.__module then
		return realRequire(ref)
	end
	local path = ref.__module
	if cache[path] == nil then
		local fn = compile(readfile(path), path)
		local env = setmetatable({ script = { Parent = folderFor(SHARED), Name = path } }, { __index = _G })
		setfenv(fn, env)
		cache[path] = fn()
	end
	return cache[path]
end

--------------------------------------------------------------------------------
-- Build and export
--------------------------------------------------------------------------------

local function json(value)
	local t = type(value)
	if t == "table" then
		if #value > 0 or next(value) == nil then
			local items = {}
			for _, v in value do
				table.insert(items, json(v))
			end
			return "[" .. table.concat(items, ",") .. "]"
		end
		local items = {}
		for k, v in value do
			table.insert(items, string.format("%q:%s", tostring(k), json(v)))
		end
		return "{" .. table.concat(items, ",") .. "}"
	elseif t == "string" then
		return string.format("%q", value)
	elseif t == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			return "0"
		end
		return string.format("%.5g", value)
	elseif t == "boolean" then
		return tostring(value)
	end
	return "null"
end

local function color(c)
	return { c.R, c.G, c.B }
end

local function exportParts(root)
	local exported = {}
	for _, part in parts(root) do
		local effects = {}
		for _, child in methods.GetChildren(part) do
			if not child:IsA("BasePart") and child.ClassName ~= "WeldConstraint" then
				local props = {}
				for key, value in rawget(child, "_props") do
					if type(value) ~= "table" or getmetatable(value) == C3 then
						props[key] = if getmetatable(value) == C3 then color(value) else value
					end
				end
				props.Parent = nil
				table.insert(effects, props)
			end
		end
		table.insert(exported, {
			name = part.Name,
			class = part.ClassName,
			shape = part.Shape.Name,
			size = { part.Size.X, part.Size.Y, part.Size.Z },
			position = { part.CFrame.p.X, part.CFrame.p.Y, part.CFrame.p.Z },
			rotation = part.CFrame.r,
			color = color(part.Color),
			material = part.Material.Name,
			transparency = part.Transparency,
			rainbow = rawget(part, "_tags").RainbowFreek == true,
			effects = effects,
		})
	end
	return exported
end

-- Weapons mode: harness.luau <shared> --weapons [weaponId ...]
if ARGS[3] == "--weapons" then
	local Weapons = require(moduleRef(SHARED .. "/Weapons.luau"))
	local WeaponModel = require(moduleRef(SHARED .. "/WeaponModel.luau"))
	local ids = {}
	for i = 4, #ARGS do
		table.insert(ids, ARGS[i])
	end
	if #ids == 0 then
		ids = Weapons.order
	end
	local out = {}
	for _, id in ids do
		local weapon = Weapons.list[id]
		assert(weapon, "No weapon with id " .. id)
		local tool = WeaponModel.build(id)
		table.insert(out, {
			id = id,
			name = weapon.name,
			rarity = "",
			subtitle = if weapon.price then "Weapon · " .. weapon.price .. " coins" else "Weapon · Free",
			season = "",
			mutation = "",
			height = 1,
			parts = exportParts(tool),
		})
	end
	print(json(out))
	return
end

local Freeks = require(moduleRef(SHARED .. "/Freeks.luau"))
local FreekModel = require(moduleRef(SHARED .. "/FreekModel.luau"))

local requested = {}
for i = 3, #ARGS do
	local id, mutation = string.match(ARGS[i], "^([^:]+):?(.*)$")
	table.insert(requested, { id = id, mutation = if mutation ~= "" then mutation else nil })
end
if #requested == 0 then
	for _, species in Freeks.list do
		table.insert(requested, { id = species.id })
	end
end

local out = {}
for _, want in requested do
	local species = Freeks.byId[want.id]
	assert(species, "No Freek with id " .. want.id)
	local model, height = FreekModel.build(want.id, want.mutation)
	model:PivotTo(CFrame.new())

	local exported = {}
	for _, part in parts(model) do
		local effects = {}
		for _, child in methods.GetChildren(part) do
			if not child:IsA("BasePart") then
				local props = {}
				for key, value in rawget(child, "_props") do
					if type(value) ~= "table" or getmetatable(value) == C3 then
						props[key] = if getmetatable(value) == C3 then color(value) else value
					end
				end
				props.Parent = nil
				table.insert(effects, props)
			end
		end
		table.insert(exported, {
			name = part.Name,
			class = part.ClassName,
			shape = part.Shape.Name,
			size = { part.Size.X, part.Size.Y, part.Size.Z },
			position = { part.CFrame.p.X, part.CFrame.p.Y, part.CFrame.p.Z },
			rotation = part.CFrame.r,
			color = color(part.Color),
			material = part.Material.Name,
			transparency = part.Transparency,
			rainbow = rawget(part, "_tags").RainbowFreek == true,
			effects = effects,
		})
	end
	table.insert(out, {
		id = species.id,
		name = species.name,
		rarity = species.rarity,
		season = species.season or "",
		mutation = want.mutation or "",
		height = height,
		parts = exported,
	})
end

print(json(out))
