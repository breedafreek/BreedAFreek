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

**UI (built in code with `src/client/UI.luau` helpers; always use them):** the flat,
chunky look of Steal an Egg's shop dialogs. No glossy gradients, shine strips or slanted
ribbons.
- Font: **Fredoka One** everywhere (`UI.fonts.bold`; `UI.fonts.heavy` is the same font).
  Never Builder Sans/Gotham.
- Windows: a plain white body (`UI.colors.sheet`) with a thick black outline (`UI.OUTLINE`,
  4–4.5 px), a small dark title tab (`UI.colors.tab`) centred on the top edge with white
  outlined text ("Shop!"), and a red rounded-square X on the top-right corner.
- Text in windows and cards is dark (`UI.text`, `UI.colors.dark`; hints `UI.colors.muted`)
  with no outline. White or bright text (on buttons, coloured panels, money, rarity
  colours) always has a black outline; `UI.label` adds or drops it by colour.
- Buttons (`UI.button`): flat bright fill with a darker lip along the bottom
  (`UI.gradient`), thick black outline, rounded corners, white outlined text, squish when
  pressed. Green = buy/go (prices too: `UI.pricePill` is a green button), red =
  close/danger, gray = disabled.
- Cards (`UI.card`): white with a thick black outline, dark title, a big 3D picture on a
  rounded tile in the card's colour (`accent`, or rarity colour for items), dark text
  lines, buttons, and `UI.tag` corner tags ("NEW", "x2"). Wide offers are white banners
  with the picture on a coloured tile on the left (Shop upgrades, Store VIP).
- HUD panels and side buttons (`UI.glass`, `Hud.menu`): flat bright fill with a darker
  lip, thick black outline, rounded corners, white outlined text. No dark, frosted or
  transparent panels.
- No uploaded images: pictures are our own 3D models in ViewportFrames (ItemPictures,
  UI.boxViewport) and emoji icons.
- Colours: saturated and cheerful. Money is green (#6EEB8C), prices on green buttons,
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
- Zones are simple, like Steal an Egg (`ZoneDecor.build`): a big open bright green studded
  floor (the same greens as the town) with the eggs on it, and the zone's theme only along
  its walls (wall colours, the entrance arch and a row of themed props against each wall).
  Keep the middle open.
- Floating text (zone piles, gates, signs): Fredoka One (or Luckiest Guy for big signs)
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
