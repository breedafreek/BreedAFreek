# Steal a Life: notes for working on this project

A Roblox game (Rojo project): train Speed on a treadmill, steal eggs from guarded zones,
carry them home, grow them in nests and hatch house parts, pets, yard items and plants for
your home. No player-vs-player stealing. See README.md for how it all works. The owner
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
  eggs (`EggModel`), all 18 Freeks (`CraftedFreeks.luau` and its kit), yard items
  (`YardModel`), plants (`PlantModel`; both use the crafted helpers in `Bricks`: `glow`,
  `octo`, `ring`, `crafted`) and house parts (`HouseModel`: each style's `glow` colour, and
  `craftify` gives every slot smooth materials, angled blocks for round pieces, lit
  windows, roof shingles and glow strips). The town, zones and plots keep the LEGO look.
- The world around the models is LEGO (`Lego.part` does it automatically): big round pieces (balls, sphere
  meshes) become square bricks, so creatures, plants and props are brick-built; small round
  details (eyes, noses) stay round. Eggs stay egg-shaped (attribute "Round") and are covered
  in studs. Every brick is snapped to the LEGO colour palette (`Lego.PALETTE`); only
  checkerboard floors (attribute "AnyColor"), Neon and the UI keep their own colours.
- Keep floating text to a minimum: labels on eggs, nests and pets only show up close
  (short `MaxDistance`); put information in the UI or on physical signs instead.
- Zones are simple, like Steal an Egg (`ZoneDecor.build`): a big open checkerboard floor
  in the zone's own ground colour (`THEMES[...].ground`; neighbouring zones must differ,
  since the colour change is what separates them) with the eggs on it, and the zone's
  theme only along its walls (wall colours and a row of themed props against each wall).
  No arches or signs between zones. Keep the middle open.
- Floating text (eggs, plots, signs): Fredoka One (or Luckiest Guy for big signs)
  with a thick dark `UIStroke`. Eggs on pedestals show rarity, name, kind and hatch time.
- Models are built from simple parts (balls, blocks, cylinders, wedges) with bold, flat,
  saturated colours and chunky proportions. Neon for glowing bits.
- Items are built by `src/shared/ItemModel.luau` (house parts by `HouseModel.luau`, pets by
  `FreekModel.luau`, yard items by `YardModel.luau`, plants by `PlantModel.luau`, eggs by
  `EggModel.luau`; small builders share `Bricks.luau`). A new yard item or plant needs a
  builder there and an entry in `Items.luau`. Every item must look right on the home and
  in pictures and reveals.
- House parts are built by `src/shared/HouseModel.luau`: every style has a look (`LOOKS`:
  colours, materials, roof shape and signature details like candy stripes, icicles or lava
  cracks). A new style needs a look there and an entry in `Parts.STYLES`. Every part must
  work both full-size on a house and as a small item (pedestals, carrying, pictures).
- Guardians are giant Freeks (`Freeks.luau` / `CraftedFreeks.luau` / `FreekModel.luau` /
  `FreekAnimator.luau`): crafted low-poly creatures with glowing eyes, each with its
  signature item (bow, collar, bell, flower, top hat, shades, horn, horns, lightning, clown
  nose, glasses, sweatband, tiara, witch hat, bolts, bandages, cape, spiked collar).
- Seasonal themes (currently Halloween) dress things up: pumpkins, purples, oranges,
  cobwebs, glowing eyes, bats.

## Content rules
- Roblox rules: no casino-style gambling (betting currency to win currency). Paid random
  items (Mystery Boxes) must show their odds before buying and respect
  `PolicyService.ArePaidRandomItemsRestricted`.
- Items, eggs and zones are defined in `src/shared/Items.luau` (house styles and slots in
  `src/shared/Parts.luau`). Never rename an item, style or slot id once players own it:
  saves store item ids ("Candy_Roof", "Pet_Oinkle", "Yard_Pool", "Plant_Daisy").

## Checks before pushing
- `stylua src`, selene lint, `rojo build -o StealALife.rbxlx`, and the Lune emulator run.
- Commit `StealALife.rbxlx` with the source and push to `main`.
