# Fuse a Freek: notes for working on this project

A Roblox game (Rojo project). The owner tests in Roblox Studio and approves designs from
rendered pictures, so render a picture of anything visual before calling it done.

## Graphic style (keep this for everything new)

The game imitates the bright, chunky cartoon look of the big Roblox simulators (Steal a
Brainrot, Grow a Garden, Pet Simulator). Every new screen, label, model and effect must
match it.

**UI (built in code with `src/client/UI.luau` helpers; always use them).** The look is
today's big simulators (wooden shop windows, 3D icons):
- Fonts: **Luckiest Guy** (`UI.fonts.heavy`) for titles, buttons and big numbers;
  **Fredoka One** (`UI.fonts.bold`) for everything else. Never Builder Sans/Gotham.
- Windows (`UI.wood`): a chunky wooden frame (wood grain, dark brown outline) around a
  cream parchment page. The tab's 3D icon breaks out of the top-left corner, the title is
  big white Luckiest Guy with a thick outline, a cream subtitle sits under it on the top
  plank, and the close button is a red rounded square with an X on the right.
- On the parchment: brown captions (`UI.colors.caption`, no outline) for sentences, and
  big `UI.section("Weapons", color)` headers ("— WEAPONS —") between groups.
- Cards (`UI.card`): bright saturated fill with a darker border of the same hue. Freek
  cards take their rarity colour; others take a fitting colour (`opts.color`). Text on
  cards is white or bright with a dark outline. `opts.ribbon = { "POPULAR", color }` adds
  a tag on the top edge.
- Buttons (`UI.button`): glossy two-tone fill (`UI.glossy`), thick dark outline,
  Luckiest Guy text, squish when pressed. Green = buy/go, red = close/danger,
  gray = owned/disabled.
- Icons are 3D models from `src/client/Icons.luau` shown with `UI.modelIcon` (never
  emoji tiles). The menu is those icons with outlined labels down the left and right
  screen edges, no tile behind them.
- HUD: money is a big green number with a 3D cash icon at the bottom left; small panels
  (`UI.glass`) are wood. Colours are saturated and cheerful: money green (#6EEB8C),
  prices gold (#FFD73C), rarities `Rarities.info[r].color`.
- Render UI to check it before calling it done (dump the real PlayerGui from an emulator
  run and draw it), not a hand-made mockup.

**World:**
- Floating text uses `src/server/FreekTag.luau` style: Luckiest Guy / Fredoka One with a
  thick dark `UIStroke`. Freeks show rarity, name, price (if for sale) and $/s.
- Models are built from simple parts (balls, blocks, cylinders, wedges) with bold, flat,
  saturated colours, big googly eyes and chunky proportions. Neon for glowing bits.
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
