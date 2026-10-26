-- Checks which game passes each player owns and marks them with "Pass_<key>" attributes.
-- Purchases made in-game take effect right away.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)

local PassService = {}

-- Refreshes income, the house sign and the UI so a pass's perk shows immediately.
local function refresh(player: Player)
	if DataService.get(player) then
		DataService.changed(player)
	end
end

local function grant(player: Player, key: string)
	player:SetAttribute("Pass_" .. key, true)
	refresh(player)
end

local function checkOwnership(player: Player)
	player:SetAttribute("PassesChecked", false)
	for _, key in GamePasses.order do
		local pass = GamePasses.list[key]
		if RunService:IsStudio() and GamePasses.STUDIO_GRANT_ALL then
			grant(player, key)
		elseif pass.id ~= 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.id)
			if ok and owns then
				grant(player, key)
			elseif not ok then
				warn("Couldn't check pass", key, "for", player.Name, owns)
			end
		end
	end
	player:SetAttribute("PassesChecked", true)
	refresh(player)
end

function PassService.init()
	Players.PlayerAdded:Connect(checkOwnership)
	for _, player in Players:GetPlayers() do
		task.spawn(checkOwnership, player)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for _, key in GamePasses.order do
			local pass = GamePasses.list[key]
			if pass.id == passId then
				grant(player, key)
				Remotes.get("Notify"):FireClient(player, "Thanks! " .. pass.name .. " is now active.", "discovery")
			end
		end
	end)
end

return PassService
