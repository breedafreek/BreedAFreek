# Steal a Home

A Roblox game: everyone starts with a plain little house. Train your Speed on the
treadmill, run out to the zones, steal house parts from under the noses of giant
guardians, carry them home and snap them onto your house. Better parts earn more money
every second, and other players can sneak into your yard and pry them off.

## Play it in Studio

1. Install [Roblox Studio](https://create.roblox.com/) (Windows or Mac).
2. Download `StealAHome.rbxlx` from this repo and double-click it.
3. Press **Play**. The town, the houses, the zones and the menus are all made by the
   scripts, so there's nothing to place by hand.

In Studio progress isn't saved unless the place is published and **Game Settings →
Security → Enable Studio Access to API Services** is on. To test with several players, use
**Test → Clients and Servers**.

## Publishing

1. **File → Publish to Roblox**.
2. **Game Settings → Places → Max Players: 8.** There are 8 homes per server, 4 on each side
   of the street (`Config.PLOT_COUNT`).
3. **Before launch, set `TEST_MONEY = nil`** in `src/shared/Config.luau` (it currently gives
   every player 1,000,000 coins for testing).

## Working on the code

The code lives in `src/` and is synced into Studio with [Rojo](https://rojo.space/):

```
rojo serve                        # live-sync into Studio (install the Rojo Studio plugin)
rojo build -o StealAHome.rbxlx    # or build a place file
```

| Folder | Becomes | What's in it |
|---|---|---|
| `src/shared` | ReplicatedStorage.Shared | Parts and zones, house models, tuning, luck, events |
| `src/server` | ServerScriptService.Server | Saving, homes, zones and guardians, stealing, speed, money |
| `src/client` | StarterPlayerScripts.Client | All the menus, the HUD, guardian animation |

## How the game works

- **Your home** (`src/server/PlotService.luau`): a yard with a fence, a gate, a treadmill and
  a house built by `src/shared/HouseModel.luau`. The house has 10 snap slots: Walls, Roof,
  Door, Windows, Tower, Chimney, Porch, Fence, Garden and Mailbox. Everyone starts with the
  free Basic part in every slot.
- **Parts** (`src/shared/Parts.luau`): every part is one slot in one style. Styles, worst to
  best: Scrap, Log Cabin, Stone, Sandstone, Ice, Candy, Lava, Royal, Crystal, Cloud, and the
  super-rare Rainbow. A part earns its style's income times its slot's weight (big pieces
  like walls and roofs earn more). Mutations (Shadow ×2, Golden ×3, Rainbow ×10) stack on top.
- **Speed** (`src/server/SpeedService.luau`): run on your treadmill to train ⚡ Speed, which
  makes you run faster (`Parts.walkSpeed`). Upgrade the treadmill in the Shop. Rebirths and
  the 2x Speed pass multiply it.
- **Zones** (`src/shared/ZoneLayout.luau`, `src/server/ZoneService.luau`,
  `src/server/ZoneDecor.luau`): ten zones in a row west of the town (Junkyard, Pine Woods,
  Rocky Quarry, Sunny Desert, Frosty Peaks, Candy Land, Lava Volcano, Royal Kingdom, Crystal
  Caves, Sky Islands). Each has a pile of pedestals growing parts in its style and a giant
  Freek guardian. Hold **Grab** on a part and run! The guardian chases anyone carrying a part
  in its zone. If your Speed meets the zone's requirement you can outrun it; if not, it
  catches you, flings you toward town and you drop the part. Guardians live on the server as
  plain data and every client animates its own copy (`src/client/GuardianFX.luau`).
- **Stealing** (`src/server/StealService.luau`): parts ride over your head while you carry
  them (a little slower, unless you have Strong Arms). Get inside your own yard and the part
  snaps onto your house if it beats what's there (the old one goes in your backpack), or
  into your backpack if not. While a home's gate is open, other players can walk in and hold
  **Steal** on any non-Basic part of its house. The owner can Snatch it back, anyone else can
  Snatch it for themselves, and a weapon hit makes the carrier drop it. A stolen part only
  leaves its owner's save once it's delivered.
- **Gate:** the owner holds **Lock Gate** on the padlock post inside the gate to put up a
  barrier for 3 minutes (5 with Longer Gate Lock). Invisible walls stop anyone climbing the
  fence. New arrivals start locked.
- **Backpack:** 40 parts (more with the Bigger Backpack passes). Install, take off or sell
  parts from the 🏠 House and 🎒 Bag windows; Install Best fills every slot with your best.
- **Catalog:** every part, shown as a black silhouette until you've owned it. The first
  player ever to get each Legendary-or-better part is saved forever and announced.
- **Luck** (`src/shared/Luck.luau`, `src/server/LuckService.luau`): **Mystery Boxes** (Robux:
  49 / 149 / 399) open into a random house part with the odds shown before buying, from the
  🍀 Luck tab or the box stand by the spawn, with a card-pack style reveal
  (`src/client/PackReveal.luau`). Players in countries where paid random items aren't
  allowed (PolicyService) can't buy them. The **Lucky Wheel** gives a free spin a day (every
  12 hours with VIP). **Lucky Hours** run every 20–35 minutes: Rainbow Hour, Lucky Zones, Fast
  Regrow and Box Luck.
- **Events** (`src/shared/Events.luau`, `src/server/EventService.luau`): **Guardian Nap**
  runs on a weekly timetable (guardians slow down, parts regrow faster, rarer parts turn up).
  **Weather** (Blood Moon, Gold Rush, Rainbow Rain) rolls in at half past most hours: parts on
  houses can catch its mutation and new parts in the piles often grow with it. The admin
  panel (owner only, or anyone in Studio) can start events and spawn parts.
- **Rebirth:** costs 100K coins, then 4× more each time. Resets coins, Speed and the
  treadmill; keeps your house, backpack, Catalog and weapons. Each rebirth adds +50% income
  and +50% treadmill speed forever.
- **Offline:** you earn 50% while away, up to 8 hours.
- **Seasonal themes** (`src/server/SeasonalService.luau`): Halloween dresses up the town with
  pumpkins, cobwebs, fog, a graveyard, ghosts and bats.
- **Game passes** (`src/shared/GamePasses.luau`): 2x Coins, 2x Speed, Longer Gate Lock, VIP,
  Strong Arms and three Bigger Backpack passes. They use the pass IDs first created for the
  old game; rename and re-describe them on the Creator Dashboard to match.
