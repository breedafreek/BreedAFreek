-- One place that names every remote. The server creates them; clients wait for them.
--
-- Action          client -> server   (actionName, ...args)
-- State           server -> client   (snapshot of the player's own data)
-- Notify          server -> client   (message, kind?)
-- DiscoveryUpdate server -> client   (speciesId, discovery)
-- Trade           server -> client   ("Request" | "State" | "Closed", payload)
-- Knockback       server -> client   (direction: Vector3, strength: number, seconds: number)
-- LuckResult      server -> client   ({ kind = "crate" | "wheel", ... }) what a crate/spin gave
-- GetState        client -> server   returns snapshot once data has loaded
-- GetDiscoveries  client -> server   returns { [speciesId] = discovery }

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local KINDS = {
	Action = "RemoteEvent",
	State = "RemoteEvent",
	Notify = "RemoteEvent",
	DiscoveryUpdate = "RemoteEvent",
	Trade = "RemoteEvent",
	Knockback = "RemoteEvent",
	LuckResult = "RemoteEvent",
	GetState = "RemoteFunction",
	GetDiscoveries = "RemoteFunction",
}

local Remotes = {}

function Remotes.get(name: string): any
	local className = KINDS[name]
	assert(className, "Unknown remote " .. name)

	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild("Remotes")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "Remotes"
			folder.Parent = ReplicatedStorage
		end
		local remote = folder:FindFirstChild(name)
		if not remote then
			remote = Instance.new(className)
			remote.Name = name
			remote.Parent = folder
		end
		return remote
	end

	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(name)
end

return Remotes
