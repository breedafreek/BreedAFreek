-- Server entry point. Order matters: remotes and the map exist before players load.

local Lighting = game:GetService("Lighting")

Lighting.ClockTime = 14
Lighting.Brightness = 2.5
Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)

local Server = script.Parent
require(Server.PlotService).init()
require(Server.DiscoveryService).init()
require(Server.EconomyService).init()
require(Server.ActionService).init()
require(Server.TradeService).init()
require(Server.StealService).init()
require(Server.DataService).init()
