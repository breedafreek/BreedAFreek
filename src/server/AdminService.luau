-- The admin panel's server side. Only admins (Config.ADMIN_NAMES / ADMIN_USER_IDS, or
-- anyone in Studio) get the IsAdmin attribute, and every command checks again here, so a
-- hacked client can't use it.
--
-- Commands (Admin remote, returns ok, message):
--   "event"    { id, minutes, everywhere }  start an event now (big, weather or Lucky Hour)
--   "stop"     { everywhere }               end whatever is running
--   "spawn"    { species, mutation }         fire that Freek from a cannon in this server
--   "announce" { text, everywhere }          a message on everyone's screen
--   "money"    { amount }                    give yourself coins (for testing)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Events = require(ReplicatedStorage.Shared.Events)
local Freeks = require(ReplicatedStorage.Shared.Freeks)
local Luck = require(ReplicatedStorage.Shared.Luck)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local CannonService = require(script.Parent.CannonService)
local DataService = require(script.Parent.DataService)
local EventService = require(script.Parent.EventService)

local AdminService = {}

function AdminService.isAdmin(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	return table.find(Config.ADMIN_NAMES, player.Name) ~= nil or table.find(Config.ADMIN_USER_IDS, player.UserId) ~= nil
end

-- Filters announcement text the way Roblox requires for text everyone sees.
local function filter(player: Player, text: string): string?
	local ok, result = pcall(function()
		return TextService:FilterStringAsync(text, player.UserId):GetNonChatStringForBroadcastAsync()
	end)
	if ok then
		return result
	end
	return if RunService:IsStudio() then text else nil
end

local commands = {}

function commands.event(_player: Player, args)
	local id = args.id
	if not (Events.BIG[id] or Events.WEATHER[id] or Luck.EVENTS[id]) then
		return false, "Unknown event"
	end
	local minutes = math.clamp(tonumber(args.minutes) or 15, 1, 180)
	local ends = Workspace:GetServerTimeNow() + minutes * 60
	EventService.send({ type = "event", id = id, ends = ends }, args.everywhere == true)
	return true, "Started for " .. minutes .. " min" .. (if args.everywhere then " in every server" else " here")
end

function commands.stop(_player: Player, args)
	-- Keep it ended until whatever's running now would have finished.
	local ends = math.max(
		ReplicatedStorage:GetAttribute("EventEnds") or 0,
		ReplicatedStorage:GetAttribute("WeatherEnds") or 0,
		Workspace:GetServerTimeNow() + 5
	)
	EventService.send({ type = "end", ends = ends }, args.everywhere == true)
	return true, "Events ended" .. (if args.everywhere then " in every server" else " here")
end

function commands.spawn(_player: Player, args)
	local species = Freeks.byId[args.species]
	if not species or species.look.hybrid then
		return false, "Unknown Freek"
	end
	local mutation = args.mutation
	local mutations = if mutation and Mutations.byId[mutation] then { mutation } else nil
	CannonService.fireNow(species.id, mutations)
	return true, "Fired " .. (if mutation then mutation .. " " else "") .. species.name .. "!"
end

function commands.announce(player: Player, args)
	local text = type(args.text) == "string" and string.sub(args.text, 1, 120) or ""
	if text == "" then
		return false, "Type a message first"
	end
	local filtered = filter(player, text)
	if not filtered then
		return false, "Couldn't check that message, try again"
	end
	EventService.send({ type = "announce", text = filtered }, args.everywhere == true)
	return true, "Sent"
end

function commands.money(player: Player, args)
	local data = DataService.get(player)
	if not data then
		return false, "Your data isn't loaded yet"
	end
	local amount = math.clamp(tonumber(args.amount) or 0, 0, 1e12)
	data.money += amount
	DataService.changed(player)
	return true, "Added coins"
end

function AdminService.init()
	local remote = Remotes.get("Admin")
	remote.OnServerInvoke = function(player: Player, command: any, args: any)
		if not AdminService.isAdmin(player) then
			return false, "Not allowed"
		end
		local handler = type(command) == "string" and commands[command]
		if not handler then
			return false, "Unknown command"
		end
		local ok, result, message = pcall(handler, player, type(args) == "table" and args or {})
		if not ok then
			warn("[AdminService] " .. tostring(result))
			return false, "Something went wrong"
		end
		return result, message
	end
	local function mark(player: Player)
		player:SetAttribute("IsAdmin", AdminService.isAdmin(player) or nil)
	end
	Players.PlayerAdded:Connect(mark)
	for _, player in Players:GetPlayers() do
		mark(player)
	end
end

return AdminService
