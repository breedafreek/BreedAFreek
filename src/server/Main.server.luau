-- Server entry point. Order matters: remotes and the map exist before players load.

local Server = script.Parent
require(Server.Environment).init()
require(Server.PlotService).init()
require(Server.DiscoveryService).init()
require(Server.EconomyService).init()
require(Server.ActionService).init()
require(Server.TradeService).init()
require(Server.StealService).init()
require(Server.WeaponService).init()
require(Server.RebirthService).init()
require(Server.PassService).init()
require(Server.ConveyorService).init()
require(Server.SeasonalService).init() -- after the map and yards exist
require(Server.DataService).init()
