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

**UI (built in code with `src/client/UI.luau` helpers; always use them):**
- Fonts: **Luckiest Guy** (`UI.fonts.heavy`) for titles, buttons and big numbers;
  **Fredoka One** (`UI.fonts.bold`) for everything else. Never Builder Sans/Gotham.
- Every piece of text has a dark outline (`UI.textStroke`, colour `UI.OUTLINE`
  #141630). Text is white or a bright colour, never dark-on-light.
- Windows: a light lavender body (`UI.colors.sheet`) under a header bar in the window's
  own colour, a slanted purple-to-pink title tab (`UI.colors.fusion` to `fusion2`) sticking
  out over the top-left corner, and a red X. Like Pet Simulator / PLS DONATE shops.
- Cards (`UI.card`): bright glossy gradient in the card's colour (`accent`, or rarity
  colour for parts), white title on top, a big 3D picture (part/box/item viewport) on a
  glowing disc, `UI.tag` corner tags ("NEW", "x2"), and black price pills
  (`UI.pricePill`) for prices. Big offers get a wide banner card (Store VIP).
- HUD panels (`UI.glass`): bright saturated fill, thick dark outline (3–3.5 px), rounded
  corners, shaded top-to-bottom. No dark/frosted/transparent panels.
- Buttons (`UI.button`): bright fill, thick dark outline, Luckiest Guy text, squish when
  pressed. Green = buy/go, red = close/danger, gray = disabled.
- No uploaded images: pictures are our own 3D models in ViewportFrames (ItemPictures,
  UI.boxViewport) and emoji icons.
- Colours: saturated and cheerful. Money is green (#6EEB8C), prices gold (#FFD73C),
  rarities use `Rarities.info[r].color`.

**World:**
- The classic Roblox studs look, like Steal an Egg (`src/shared/Lego.luau`): everything is
  shiny Plastic with the stud texture on every face (inlets underneath). Floors are big
  checkerboards of two shades (`Decor.checkerFloor`; bright greens in town), zones are
  walled by tall flat saturated walls with a coloured strip along the top, and lighting is
  bright and clear (little haze). Neon, Glass, Foil and ForceField keep their look; roads,
  sidewalks and paths are smooth "tiles" (the SMOOTH list). House walls get brick seams;
  trees are stacked bricks. Build new things as bricks (blocks) where you can.
- Everything is LEGO (`Lego.part` does it automatically): big round pieces (balls, sphere
  meshes) become square bricks, so creatures, plants and props are brick-built; small round
  details (eyes, noses) stay round. Eggs stay egg-shaped (attribute "Round") and are covered
  in studs. Every brick is snapped to the LEGO colour palette (`Lego.PALETTE`); only
  checkerboard floors (attribute "AnyColor"), Neon and the UI keep their own colours.
- Keep floating text to a minimum: labels on eggs, nests and pets only show up close
  (short `MaxDistance`); put information in the UI or on physical signs instead.
- Zones are laid out on purpose (`ZoneDecor.build`): a winding path to the guardian's lair,
  rows of props along the walls, and raised feature plates with a landmark each.
- Floating text (zone piles, gates, signs): Luckiest Guy / Fredoka One with a thick dark
  `UIStroke`. Eggs on pedestals show rarity, name, kind and hatch time.
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
- Guardians are giant Freeks (`Freeks.luau` / `FreekModel.luau` / `FreekAnimator.luau`,
  kept as the creature library): big googly eyes, chunky, each with a signature accessory.
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
