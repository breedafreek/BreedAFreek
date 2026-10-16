# Fuse a Freek: notes for working on this project

A Roblox game (Rojo project). The owner tests in Roblox Studio and approves designs from
rendered pictures, so render a picture of anything visual before calling it done.

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
  colour for Freeks), white title on top, a big 3D picture (Freek/egg/item viewport) on a
  glowing disc, `UI.tag` corner tags ("NEW", "x2"), and black price pills
  (`UI.pricePill`) for prices. Big offers get a wide banner card (Store VIP).
- HUD panels (`UI.glass`): bright saturated fill, thick dark outline (3–3.5 px), rounded
  corners, shaded top-to-bottom. No dark/frosted/transparent panels.
- Buttons (`UI.button`): bright fill, thick dark outline, Luckiest Guy text, squish when
  pressed. Green = buy/go, red = close/danger, gray = disabled.
- No uploaded images: pictures are our own 3D models in ViewportFrames (ItemPictures,
  UI.viewport) and emoji icons.
- Colours: saturated and cheerful. Money is green (#6EEB8C), prices gold (#FFD73C),
  rarities use `Rarities.info[r].color`.

**World:**
- Floating text uses `src/server/FreekTag.luau` style: Luckiest Guy / Fredoka One with a
  thick dark `UIStroke`. Freeks show rarity, name, price (if for sale) and $/s.
- Models are built from simple parts (balls, blocks, cylinders, wedges) with bold, flat,
  saturated colours, big googly eyes and chunky proportions. Neon for glowing bits.
- Every species has a signature accessory (`signature` in `Freeks.luau`, built by
  `src/shared/Accessories.luau`: glasses, a bow, a top hat, a collar...). Fused Freeks wear
  both parents' signatures, so give any new species one.
- Seasonal themes (currently Halloween) dress things up: pumpkins, purples, oranges,
  cobwebs, glowing eyes, bats.

## Content rules
- Roblox rules: no casino-style gambling (betting currency to win currency). Paid random
  items (Monster Eggs) must show their odds before buying and respect
  `PolicyService.ArePaidRandomItemsRestricted`.
- Freeks are defined in `src/shared/Freeks.luau`; Monster-line Freeks are `exclusive`.

## Checks before pushing
- `stylua src`, selene lint, `rojo build -o FuseAFreek.rbxlx`, and the Lune emulator run.
- Commit `FuseAFreek.rbxlx` with the source and push to `main`.
