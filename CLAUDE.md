# Steal a Life: notes for working on this project

A Roblox game (Rojo project): train Speed on a treadmill, steal eggs from guarded zones,
carry them home, grow them in nests and hatch pets, yard items and plants for your home
(80 items in ten zones, from the owner's reference sheet). No player-vs-player stealing. See README.md for how it all works. The owner
tests in Roblox Studio and approves designs from rendered pictures, so render a picture of
anything visual before calling it done.

## Graphic style (keep this for everything new)

The game imitates the bright, chunky cartoon look of the big Roblox simulators (Steal a
Brainrot, Grow a Garden, Pet Simulator). Every new screen, label, model and effect must
match it.

**UI (from the owner's two reference screenshots: a top simulator's HUD and a "Daily
Rewards" window): clean simulator look. Build every screen with `src/client/UI.luau`;
render each screen for the owner before calling it done.**
- Fonts: Luckiest Guy (`UI.heavy`) for buttons, titles and big numbers; Fredoka One
  (`UI.text`) for small labels. White or a bright colour, black outline. Short labels, no
  paragraphs.
- HUD (`Hud.luau`), with no panels behind anything:
  - top centre: wide travel buttons (HOME, ZONES, SPIN)
  - left: wide menu buttons (SHOP, MY HOME, BAG, INDEX) and the event timer under them
  - right: square tiles (STORE, LUCK, and ADMIN for admins)
  - bottom left: Speed (gold) and money (green) as big outlined numbers with 3D icons,
    "Earning $x/s" under them, and "+$" pops
  - bottom right: a dark bar with the next egg's hatch timer
  - top right: the day / night clock (`Hud.dayClock`)
  - a dark pill at the top (zone / carrying) and messages under it
  - Wide buttons and tiles (`UI.wideButton`, `UI.tile`) are bright, top half lighter,
    with stud dots, a thin black outline, an icon and a red count badge (`UI.badge`).
- Windows (`UI.window`): dark see-through body (`UI.colors.body`, 0.2 transparency),
  thin black outline, nearly square corners (6 px); a flat coloured header bar (the
  button's colour) with an icon, a white title and a red square X. The windows are Shop,
  My Home, Bag, Index, Store, Luck and Admin (all in `Main.client.luau`).
- Slots (`UI.cell`, `slot` in Main): dark cells with a thin outline: a white label on
  top, a big 3D picture, coloured lines at the bottom (money green, Speed gold) and
  buttons under them. The one that matters (affordable, best, ready) gets the gold
  outline.
- Buttons (`UI.button`): bright, top half lighter, black outline, white outlined text.
  Green = buy/go, gray = can't, red = close/sell, orange = open.
- Reveals: hatching and Mystery Boxes play the card-pack reveal (`PackReveal.luau`); the
  Lucky Wheel spins (`LuckyWheel.luau`) and shows its prize in a small window.
- Upgrades: a House or Plot upgrade plays the build animation for everyone
  (`BuildAnim.luau`, played by `BuildFX.luau` when PlotService bumps the plot's
  "BuildAnim" attribute): the new house (or the fence, pads and yard items) drops in piece
  by piece, going up and round, each piece landing with a bounce and a dust puff, then a
  flash, a shockwave ring and sparkles. It's worked out from the time alone, so offline
  videos match the game.
- Motion is subtle: things you can press grow a little on hover and dip when pressed
  (`UI.hover`); windows pop open. No sparkles, glimmers or bouncing text.
- No uploaded images: pictures are our own 3D models (ItemPictures) or emoji.

**World:**
- The classic Roblox studs look, like Steal an Egg (`src/shared/Lego.luau`): everything is
  shiny Plastic with the stud texture on every face (inlets underneath). Floors are big
  checkerboards of two shades (`Decor.checkerFloor`; bright greens in town), zones are
  walled by tall flat saturated walls with a coloured strip along the top, and lighting is
  bright and clear (little haze). Neon, Glass, Foil and ForceField keep their look; roads,
  sidewalks and paths are smooth "tiles" (the SMOOTH list). House walls get brick seams;
  trees are stacked bricks. Build new things as bricks (blocks) where you can.
- **Models are in the "crafted" look** (the owner's references: a plated egg and a
  low-poly cat): detailed low-poly models of many slightly offset or angled blocks and
  wedges, smooth (no studs), a muted main colour with a bright Neon accent (glowing eyes,
  seams, strips, toes, windows), small gold details, sparks and lights. Mark a model with
  the attribute "Crafted" and Lego leaves it alone (no studs, no palette snapping). Done:
  eggs (`EggModel`), all 15 creatures (`CraftedFreeks.luau` and its kit), all 53 yard items
  (`YardModel`), all 13 plants (`PlantModel`; both use the crafted helpers in `Bricks`:
  `glow`, `octo`, `ring`, `crafted`) and the house styles (`HouseModel`: each style's `glow`
  colour, and `craftify` gives every piece smooth materials, angled blocks for round
  pieces, lit windows, roof shingles and glow strips). The town, zones and plots keep the
  LEGO look.
- The world around the models is LEGO (`Lego.part` does it automatically): big round pieces (balls, sphere
  meshes) become square bricks, so creatures, plants and props are brick-built; small round
  details (eyes, noses) stay round. Eggs stay egg-shaped (attribute "Round") and are covered
  in studs. Every brick is snapped to the LEGO colour palette (`Lego.PALETTE`); only
  checkerboard floors (attribute "AnyColor"), Neon and the UI keep their own colours.
- Keep floating text to a minimum: labels on eggs, nests and pets only show up close
  (short `MaxDistance`); put information in the UI or on physical signs instead.
- Zones follow the owner's reference sheet (`ZoneDecor.build`, one `THEMES[i]` per zone):
  a big open checkerboard floor in the zone's own ground colour (neighbouring zones must
  differ, since the colour change is what separates them) with the eggs on it, low walls
  (an invisible barrier goes all the way up), a row of props along each wall (mostly the
  zone's own item models, `item()`) and a big backdrop beyond the walls that sets the scene
  (houses, giant flowers, the sea, forest and mountains, a skyline, mansions, giant
  crystals, UFOs and a ringed planet, floating islands and rainbows; giant item models are
  the cheapest way to build it). The Dream Home is a tall hall with windows instead. No
  arches or signs between zones. Keep the middle open.
- Floating text: always `FloatText.new` (`src/shared/FloatText.luau`): one or two short
  lines at a fixed size on screen (it doesn't grow as you walk up), Luckiest Guy for the
  top line and Fredoka One under it, white or a bright colour with a thin black outline,
  no backgrounds, and a short `maxDistance`. Zone eggs show rarity and name (weight and
  hatch time are on the Grab prompt); nests show rarity and time left (nothing when
  empty); pets and guardians one name line; the box stand shows name and price (holding
  E opens the Luck window with the odds).
- Models are built from simple parts (balls, blocks, cylinders, wedges) with bold, flat,
  saturated colours and chunky proportions. Neon for glowing bits.
- Items are built by `src/shared/ItemModel.luau` (pets by `FreekModel.luau`, yard items by
  `YardModel.luau`, plants by `PlantModel.luau`, eggs by `EggModel.luau`; small builders
  share `Bricks.luau`). A new item needs an entry in its zone in `Items.ZONES` and a
  builder named after its id (a creature in `CraftedFreeks.luau` and `Freeks.luau` for a
  pet). Every item must look right on the home and in pictures and reveals.
- There are no house parts any more: the house comes from the House level
  (`Config.HOUSE_STYLES`, `Config.houseBonus`), built by `src/shared/HouseModel.luau` from a
  style's look (`LOOKS`: colours, materials, roof shape and signature details like candy
  stripes, icicles or lava cracks; styles in `Parts.STYLES`).
- Houses have an inside: the full-size walls are a hollow shell with a walk-in doorway (the
  door hangs open) and a ceiling, and `HouseModel.interior(style, level)` furnishes it
  (plank floor, striped wallpaper, inside windows, pictures, a ceiling light and Dream Home
  furniture that gets fancier with the House level; PlotService builds it as the house's
  "Interior" model).
- Guardians are giant versions of each zone's creature (`Items.ZONES[i].guardian`, a species
  in `Freeks.luau`; the Garden's is a gnome that only guards), drawn by `FreekModel.luau` and
  animated by `FreekAnimator.luau`; each has its attack in `GuardianAttacks.bySpecies`.
- Day and night (`DayNight.luau`, the same clock in every server): 5 minutes of day, 15
  seconds of night. At nightfall every zone's eggs re-roll (`ZoneService.restock`) and
  while it's night nest eggs grow x30 (`DayNightService`); clients darken the sky and tint
  the picture blue (`DayNightFX`) on top of the server's daytime lighting.
- Seasonal themes (currently Halloween) dress things up: pumpkins, purples, oranges,
  cobwebs, glowing eyes, bats.

## Content rules
- Roblox rules: no casino-style gambling (betting currency to win currency). Paid random
  items (Mystery Boxes) must show their odds before buying and respect
  `PolicyService.ArePaidRandomItemsRestricted`.
- Items, eggs and zones are defined in `src/shared/Items.luau` (house styles in
  `src/shared/Parts.luau`). Never rename an item id once players own it: saves store item
  ids ("Pet_GoldenRetriever", "Yard_RedMailbox", "Plant_AppleTree"). Replacing the whole
  catalogue again means bumping `ITEMS_VERSION` in DataService (it wipes old items).

## Checks before pushing
- `stylua src`, selene lint, `rojo build -o StealALife.rbxlx`, and the Lune emulator run.
- Commit `StealALife.rbxlx` with the source and push to `main`.
