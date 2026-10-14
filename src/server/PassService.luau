-- Checks which game passes each player owns and marks them with "Pass_<key>" attributes.
-- Purchases made in-game take effect right away.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FreekUtil = require(ReplicatedStorage.Shared.FreekUtil)
local GamePasses = require(ReplicatedStorage.Shared.GamePasses)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)

local PassService = {}

-- Keeps the save's passSlots in step with the Extra Yard Slot passes the player owns, and
-- moves any Freek off a pad the player no longer has (e.g. after a refund).
local function syncSlots(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	data.passSlots = GamePasses.passSlots(player)
	local total = FreekUtil.totalSlots(data)
	for _, freek in data.freeks do
		if freek.slot and freek.slot > total then
			freek.slot = nil
		end
	end
	DataService.changed(player)
end

local function grant(player: Player, key: string)
	player:SetAttribute("Pass_" .. key, true)
	-- Refresh income, yard and UI so the perk shows immediately.
	syncSlots(player)
end

local function checkOwnership(player: Player)
	-- Ownership is re-checked every join, so start from zero pass slots until confirmed.
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
	syncSlots(player)
end

function PassService.init()
	Players.PlayerAdded:Connect(checkOwnership)
	for _, player in Players:GetPlayers() do
		task.spawn(checkOwnership, player)
	end

	DataService.onLoaded(function(player)
		if player:GetAttribute("PassesChecked") then
			syncSlots(player)
		end
	end)

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
