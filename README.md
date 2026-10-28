# Steal a Life

A Roblox game: everyone starts with a plain little house on a big empty lawn. Train your
Speed on the treadmill, run out to the zones, steal eggs from under the noses of giant
guardians and carry them home. Eggs grow in the nests in your yard (rarer eggs take longer)
and hatch into house parts, pets, yard items and plants. Everything you put out earns money
every second. There is no stealing from other players.

## Play it in Studio

1. Install [Roblox Studio](https://create.roblox.com/) (Windows or Mac).
2. Download `StealALife.rbxlx` from this repo and double-click it.
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
rojo build -o StealALife.rbxlx    # or build a place file
```

| Folder | Becomes | What's in it |
|---|---|---|
| `src/shared` | ReplicatedStorage.Shared | Items, eggs and zones, models, tuning, luck, events |
| `src/server` | ServerScriptService.Server | Saving, homes, zones and guardians, carrying, nests, speed, money |
| `src/client` | StarterPlayerScripts.Client | Guardian, pet and world effects (the screen UI is being rebuilt from scratch) |

## How the game works

- **Your home** (`src/server/PlotService.luau`): a 96×96 fenced yard with your house (built
  by `src/shared/HouseModel.luau`), a treadmill, a row of nests by the gate, six garden beds,
  six yard spots and a front lawn where your pets roam. Everything shown comes from your
  save (`src/shared/LifeUtil.luau`).
- **Items** (`src/shared/Items.luau`): four kinds, each in seven rarities (Common to Secret):
  - **House parts** (`src/shared/Parts.luau`): 10 snap slots (Walls, Roof, Door, Windows,
    Tower, Chimney, Porch, Fence, Garden, Mailbox) in 11 styles (Scrap up to Rainbow).
    Everyone starts with the free Basic part in every slot.
  - **Pets**: 18 Freeks (`Freeks.luau` / `FreekModel.luau`), up to 8 roaming your lawn
    (drawn by each client, `src/client/PetFX.luau`).
  - **Yard items** (`src/shared/YardModel.luau`): Garden Gnome up to the Rocket Ship, on 6
    yard spots.
  - **Plants** (`src/shared/PlantModel.luau`): Daisy up to the Rainbow Tree, in 6 garden beds.
  Mutations (Shadow ×2, Golden ×3, Rainbow ×10) multiply an item's income.
- **Weights** (`Items.luau`), like Steal an Egg: every egg in a zone has a random weight
  in kg (deeper zones lay heavier eggs). There's no top limit: most land near normal and
  each step heavier is rarer. In a nest the egg grows a random amount in random spurts
  (you can watch the kg climb), and what hatches keeps the final weight. An item's weight
  over its egg's normal weight multiplies its income, and heavier things are drawn bigger.
  Counting growth, about 1 in 14 items is 3x normal, 1 in 190 is 10x, 1 in 2,000 is 30x,
  1 in 35,000 is 100x. House parts keep their normal size on the house but still earn by
  weight. Boxes and the wheel roll a weight too; 10x-or-heavier finds are announced.
- **Speed** (`src/server/SpeedService.luau`): run on your treadmill to train ⚡ Speed, which
  makes you run faster (`Parts.walkSpeed`). Upgrade the treadmill in the Shop. The 2x Speed
  pass doubles it.
- **Zones** (`Items.ZONES`, `src/shared/ZoneLayout.luau`, `src/server/ZoneService.luau`,
  `src/server/ZoneDecor.luau`): ten zones in a row west of the town (140 studs wide; the
  first is 130 long and each one after is 25 studs longer), each growing one kind of
  egg: Backyard Garden (plants), Junkyard (house), Pine Woods (pets), Toy Town (yard), Sunny
  Desert (plants), Candy Land (house), Frosty Peaks (pets), Royal Kingdom (yard), Crystal
  Caves (house), Sky Islands (pets). Deeper zones need more Speed and grow rarer eggs. Eggs
  lie scattered on the ground all over each zone (rarer ones deeper in, near the guardian)
  and each is coloured by the item inside (`src/shared/EggModel.luau`): a plain egg covered
  in LEGO studs, in the item's colours, with a stud pattern for its kind. Its rarity, name ("Woofles Egg"), weight and hatch time float above it, and hatching
  gives exactly that item. Hold **Grab** and run! Each zone's giant Freek guardian sleeps at the back of its
  zone (💤) until someone grabs one of its eggs; then it wakes and chases whoever carries an
  egg from its zone (only its own eggs: carrying another zone's egg past it is safe), and
  walks home to sleep again once nobody does; if your Speed meets the zone's requirement you can outrun it, if
  not it catches you, flings you toward town and you drop the egg. Guardians live on the
  server as plain data and every client animates its own copy (`src/client/GuardianFX.luau`).
- **Carrying** (`src/server/StealService.luau`): you need a free nest to grab an egg. You
  carry it in your arms, slower the heavier it is (a normal egg -8% speed, a 2x egg -20%,
  4x -32%, 8x -44%, never below half speed; `Items.carrySpeed`); get inside your own yard
  and it goes into a nest. Caught by its
  guardian in the egg's own zone (or if you die or leave), the egg goes back exactly where
  you took it; caught after you've run into a zone nearer town, it drops on the ground
  right there for anyone to grab (it vanishes after a minute and a new one grows back home).
- **Guardian attacks** (`src/shared/GuardianAttacks.luau`, drawn by
  `src/client/GuardianAttackFX.luau`): guardians chase thieves out of their zone toward
  town, and each has a signature attack on top of grabbing you: Oinkle charges, Woofles
  pounces, Hootsworth swoops, Chuckles throws pies, Mumbles lashes a bandage that yanks you
  back, Glamora fires homing magic orbs, BooBoo vanishes and reappears in front of you,
  Count Fangula sends a homing bat swarm, Blinky charges up an eye laser and Stormy calls
  lightning where you're running. Thrown things aim where you're heading (zig-zag to dodge);
  the laser and lightning show a warning first.
- **Nests and hatching** (`src/server/NestService.luau`): 3 nests (5 with Extra Nests). An egg
  grows for 20 s (Common) up to 15 min (Secret), half with Fast Hatching, even while you're
  offline. When it's ready hold **Hatch** on the nest (or press HATCH in 🏡 My Life): out
  comes a random item of the egg's kind and rarity, keeping the egg's mutation, with a
  reveal (the screen UI is being rebuilt; see CLAUDE.md). It goes straight out if it beats what you
  have (the old one goes to your backpack), otherwise into the backpack.
- **Upgrades** (coins, in the 🛒 Shop; `Config.luau`):
  - **Treadmill** (20 levels): more ⚡ Speed a second.
  - **Plot** (5 levels): level 1 has room for 2 yard items, 2 plants and 4 pets; each level
    adds a yard spot, a garden bed and a pet place (up to 6, 6 and 8). Locked spots show as
    grey pads with a 🔒 in the yard.
  - **House** (8 levels): the house grows a little each level (up to 1.25x), and the Porch,
    Chimney, Garden and Tower slots open at levels 2, 3, 4 and 5. Older saves start at the
    levels that fit what they already have.
- **Backpack:** 40 items (more with the Bigger Backpack passes). The 🏡 My Life window shows
  your nests, house, pets, yard and garden; the 🎒 Bag window puts items out or sells them;
  Put Out Best does everything at once.
- **Catalog:** every item, shown as a black silhouette until you've owned it. The first
  player ever to get each Legendary-or-better item is saved forever and announced.
- **Luck** (`src/shared/Luck.luau`, `src/server/LuckService.luau`): **Mystery Boxes** (Robux:
  49 / 149 / 399) open into a random item of any kind, with each rarity's odds shown before
  buying, from the 🍀 Luck tab or the box stand by the spawn. Players in countries where paid
  random items aren't allowed (PolicyService) can't buy them. The **Lucky Wheel** gives a
  free spin a day (every 12 hours with VIP), with Golden and Rainbow eggs that hatch on the
  spot. **Lucky Hours** run every 20–35 minutes: Rainbow Hour, Lucky Zones, Fast Regrow and
  Box Luck.
- **Events** (`src/shared/Events.luau`, `src/server/EventService.luau`): **Guardian Nap**
  runs on a weekly timetable (guardians slow down, eggs regrow faster, rarer eggs turn up).
  **Weather** (Blood Moon, Gold Rush, Rainbow Rain) rolls in at half past most hours:
  everything you have out can catch its mutation and new eggs often grow with it. The admin
  panel (owner only, or anyone in Studio) can start events and spawn eggs.
- **Offline:** you earn 50% while away, up to 8 hours.
- **Seasonal themes** (`src/server/SeasonalService.luau`): Halloween dresses up the town with
  pumpkins, cobwebs, fog, a graveyard, ghosts and bats.
- **Game passes** (`src/shared/GamePasses.luau`): 2x Coins, 2x Speed, Fast Hatching, Extra
  Nests, VIP and three Bigger Backpack passes. They use the pass IDs first created for the
  old game; rename and re-describe them on the Creator Dashboard to match.
- **Saves** go to a new DataStore (`StealALife_Players_v1`), so everyone starts fresh.
