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
- Panels (`UI.glass`): bright saturated fill (default blue #3E80F5), thick dark outline
  (3–3.5 px), rounded corners (14–22), shaded top-to-bottom with `UI.gradient()`.
  No dark/frosted/transparent panels.
- Buttons (`UI.button`): bright fill, thick dark outline, Luckiest Guy text, squish when
  pressed. Green = buy/go, red = close/danger, gray = disabled.
- Windows have a gold title ribbon across the top edge and a round red X.
- Colours: saturated and cheerful. Money is green (#6EEB8C), prices gold (#FFD73C),
  rarities use `Rarities.info[r].color`.

**World:**
- Floating text uses `src/server/FreekTag.luau` style: Luckiest Guy / Fredoka One with a
  thick dark `UIStroke`. Freeks show rarity, name, price (if for sale) and $/s.
- Models are built from simple parts (balls, blocks, cylinders, wedges) with bold, flat,
  saturated colours, big googly eyes and chunky proportions. Neon for glowing bits.
- **Freeks are voxel style**: they are designed as part lists in `Freeks.luau`, and
  `FreekModel` (`STYLE = "voxel"`, grid `VOXEL` studs) rebuilds them out of cubes, with
  faces as flat pixel blocks. Design new Freeks the same way and check them rendered.
- Freeks animate with `src/shared/FreekAnimator.luau` (idle: breathe, blink, look around,
  wag, ear twitch, wave, hop; walking: per-species gait). Tag new moving parts (swing
  hinges, `rig = "ear" | "arm"`, a part named "Head") so they join in.
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
