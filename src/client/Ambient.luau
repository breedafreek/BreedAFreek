-- Flies event creatures (ghosts and bats placed by the server's seasonal themes) along their
-- circles, locally on each client so they move smoothly. Only nearby creatures animate.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Ambient = {}

local GHOST_TAG = "SpookyGhost"
local BAT_TAG = "SpookyBat"
local RANGE = 260

-- Position on the creature's circle at time t, facing the way it's flying.
local function pathCFrame(model: Model, t: number, bob: number): CFrame?
	local center = model:GetAttribute("Center")
	if typeof(center) ~= "Vector3" then
		return nil
	end
	local radius = model:GetAttribute("Radius") or 10
	local height = model:GetAttribute("Height") or 10
	local speed = model:GetAttribute("Speed") or 0.3
	local angle = t * speed + (model:GetAttribute("Phase") or 0)
	local position = center + Vector3.new(math.cos(angle) * radius, height + bob, math.sin(angle) * radius)
	-- Direction of travel is the tangent of the circle.
	local ahead = Vector3.new(-math.sin(angle), 0, math.cos(angle)) * math.sign(speed)
	return CFrame.lookAt(position, position + ahead)
end

function Ambient.start()
	RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera
		local eye = if camera then camera.CFrame.Position else Vector3.zero
		local t = os.clock()

		for _, ghost in CollectionService:GetTagged(GHOST_TAG) do
			local phase = ghost:GetAttribute("Phase") or 0
			local where = pathCFrame(ghost, t, math.sin(t * 1.4 + phase) * 1.5)
			if where and (where.Position - eye).Magnitude < RANGE then
				-- Gentle side-to-side wobble while drifting.
				ghost:PivotTo(where * CFrame.Angles(0, 0, math.sin(t * 2 + phase) * math.rad(8)))
			end
		end

		for _, bat in CollectionService:GetTagged(BAT_TAG) do
			local phase = bat:GetAttribute("Phase") or 0
			local where = pathCFrame(bat, t, math.sin(t * 3 + phase) * 0.8)
			local body = bat.PrimaryPart
			if where and body and (where.Position - eye).Magnitude < RANGE then
				bat:PivotTo(where)
				local flap = math.sin(t * 18 + phase) * math.rad(40)
				local left, right = bat:FindFirstChild("WingL"), bat:FindFirstChild("WingR")
				if left and right then
					left.CFrame = body.CFrame
						* CFrame.new(-0.45, 0, 0)
						* CFrame.Angles(0, 0, -flap)
						* CFrame.new(-1.1, 0, 0)
					right.CFrame = body.CFrame
						* CFrame.new(0.45, 0, 0)
						* CFrame.Angles(0, 0, flap)
						* CFrame.new(1.1, 0, 0)
				end
			end
		end
	end)
end

return Ambient
