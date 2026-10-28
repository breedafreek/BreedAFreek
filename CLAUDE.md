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

**UI:** removed on purpose (build life-25) and being rebuilt from scratch with the owner.
There is no screen UI right now: no HUD, menus, windows or reveals. Don't bring the old one
back (it's in git history before life-25 only for reference). Agree the look with the owner
(renders or their UI pack) before building screens. Gameplay that needs the UI (buying
upgrades, the Store, the Luck tab, the backpack) is waiting on the rebuild; the server
side of it is all still there (`ActionService`, `Remotes`).

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
