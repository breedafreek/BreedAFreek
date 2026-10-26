# Steal a Home: notes for working on this project

A Roblox game (Rojo project): train Speed on a treadmill, steal house parts from guarded
zones, carry them home and snap them onto your house (and steal from other players'
houses). See README.md for how it all works. The owner tests in Roblox Studio and approves
designs from rendered pictures, so render a picture of anything visual before calling it
done.

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
- Floating text (zone piles, gates, signs): Luckiest Guy / Fredoka One with a thick dark
  `UIStroke`. Parts on pedestals show rarity, name and $/s.
- Models are built from simple parts (balls, blocks, cylinders, wedges) with bold, flat,
  saturated colours and chunky proportions. Neon for glowing bits.
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
- Parts, styles and zones are defined in `src/shared/Parts.luau`. Never rename a style or
  slot id once players own it: saves store part ids ("Candy_Roof").

## Checks before pushing
- `stylua src`, selene lint, `rojo build -o StealAHome.rbxlx`, and the Lune emulator run.
- Commit `StealAHome.rbxlx` with the source and push to `main`.
