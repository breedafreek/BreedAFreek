# Breed a Freek

A Roblox game: collect funny Freeks, breed them in your yard to make rarer ones, earn
money every second, and get your name in the Discovery Book by being the first player
ever to breed a new species.

## Play it in Studio

1. Install [Roblox Studio](https://create.roblox.com/) (Windows or Mac).
2. Download `BreedAFreek.rbxlx` from this repo and double-click it.
3. Press **Play**. The map, yards and menus are all made by the scripts, so there's nothing to place by hand.

In Studio progress isn't saved unless the place is published and **Game Settings → Security → Enable Studio Access to API Services** is on. To test with several players, use **Test → Clients and Servers**.

## Publishing

1. **File → Publish to Roblox**.
2. **Game Settings → Places → Max Players: 8.** There are 8 yards per server, 4 on each side of the conveyor (`Config.PLOT_COUNT`).
3. Saving and the Discovery Book work automatically on live servers.

## Working on the code

The code lives in `src/` and is synced into Studio with [Rojo](https://rojo.space/):

```
rojo serve                       # live-sync into Studio (install the Rojo Studio plugin)
rojo build -o BreedAFreek.rbxlx  # or build a place file
```

| Folder | Becomes | What's in it |
|---|---|---|
| `src/shared` | ReplicatedStorage.Shared | Freek list, rarities, mutations, tuning, 3D placeholder builder |
| `src/server` | ServerScriptService.Server | Saving, yards, money, breeding, trading, Discovery Book, breeding recipes |
| `src/client` | StarterPlayerScripts.Client | All the menus |

### Common changes

- **Add or rename Freeks:** edit `src/shared/Freeks.luau`. Never change an `id` once players own that Freek, because ids are what saves store.
- **Decide what two Freeks breed into:** edit `src/server/Recipes.luau`. It's server-only so players can't read the secret combos.
- **Rarities:** Common, Uncommon, Rare, Legendary, Mystic, Ultra, Secret (`src/shared/Rarities.luau`).
- **Seasonal Freeks:** add `season = "Halloween"` to a Freek (or `Thanksgiving`, `Christmas`, `NewYears`, `Easter`, `America`). It can only be bred or bought during that event, but players keep it forever. Event dates are in `src/shared/Seasons.luau`; Thanksgiving and Easter are worked out for each year automatically.
- **Money, slots and limits:** edit `src/shared/Config.luau`.
- **Designing a Freek:** give it `look = { parts = {...}, effects = {...} }` in `Freeks.luau`. The format is described at the top of `src/shared/FreekModel.luau`.
- **Previewing Freeks without Studio:** `tools/snapshot/snapshot.sh out/ Blobby KingGoob:Golden` runs the real model code and saves a front and back picture of each Freek. Set it up once with `cd tools/snapshot && cargo build --release && npm install`. It needs Rust, Node and Chromium.
- **Real 3D models:** put a Model named after the species id (e.g. `Blobby`) in a `ReplicatedStorage.FreekModels` folder. Set its pivot at its feet and face it toward -Z. It replaces the placeholder automatically.

## How the game works

- **Yard:** 4 slots to start, buy up to 12. Only Freeks in the yard earn money. Extra Freeks wait in your backpack (50 total).
- **Conveyor belt:** two lanes run down the middle of the map between the two rows of 4 yards. Each lane comes out of its own Freek House at the west end, and a new Freek appears on each lane every 4 seconds and rides for about 40 seconds. Walk up and hold **Buy**, first come first served. Odds (`src/shared/Belt.luau`): Common 70%, Uncommon 22%, Rare 6.5%, Legendary 1.3%, Mystic 0.2%. Ultra and Secret are breeding-only. Only starter Commons and species someone has already discovered by breeding can appear, and Limited Freeks only during their event. Legendary and up are announced to the server. Prices are the starter price, or 50 seconds of the Freek's income, times any mutation.
- **Shop:** yard slots and weapons.
- **Breeding:** pick two Freeks and wait out the timer. The rarer parent sets how long it takes. A pair with a recipe has a chance to make the new species. Otherwise the baby copies a parent. Any baby can roll a mutation (Shadow ×2, Golden ×3, Rainbow ×10 income), and a parent's mutation makes that roll 4× more likely.
- **Discovery Book:** every species, shown as a black "???" until someone finds it. The first finder in any server is saved forever and announced to everyone.
- **Offline:** you earn 50% while away, up to 8 hours.
- **Gates and stealing:** every yard is fenced with one gate. The owner taps **Lock Gate** to close it for 180 seconds, then it opens again until they lock it again (yards start locked for 180 seconds when you join). Owners can always walk through their own gate. While a gate is open, other players can walk in and hold **Steal** on a Freek standing on a pad. It rides on the thief's head and slows them down: barely for a Common, down to well under half speed for a Secret (`carrySpeed` in `Rarities.luau`). While it's being carried, anyone can hit the carrier with a weapon to send it home (the owner can also Snatch it back), and any other player can **Snatch** it to carry it to their own yard instead. Whoever gets it inside their own fence keeps it. If the carrier dies or leaves, it goes home. Freeks in the breeding pen or the backpack can't be stolen.
- **Rebirth:** costs 100K coins, then 4× more each time (`Config.luau`). Resets coins, Freeks and yard slots. Keeps the Discovery Book, Limited Freeks and weapons. Each rebirth adds +50% income forever, and rebirths show on the leaderboard.
- **Seasonal themes** (`src/server/SeasonalService.luau`): while an event runs, the map dresses up for it and switches back afterwards, checked every 2 minutes. Halloween switches to a spooky purple twilight, turns tree leaves orange and red and lamps orange, and adds glowing jack-o'-lanterns, hay bales, leaf piles, cobwebs and string lights on every gate arch, string lights and low fog along the walkways, witch hats on the Freek Houses, and a graveyard with a bubbling cauldron by the spawn. Ghosts drift and bats circle overhead (flown by each client in `src/client/Ambient.luau`). Other events can add a theme to `THEMES`.
- **Game passes** (`src/shared/GamePasses.luau`), sold in the 💎 Store tab: 2x Coins (499 R$), Fast Breeding (999), Longer Gate Lock (499), VIP (299), Extra Breeding Pen (399, a second pen so two pairs can breed at once), and three Extra Yard Slot passes (299 each, +1 slot each, up to 15). Create each pass on the Creator Dashboard (Monetization → Passes) and paste its ID into `GamePasses.luau`. Until then it shows "Coming soon". Set `STUDIO_GRANT_ALL = true` to test every perk in Studio.
- **Weapons** (`src/shared/Weapons.luau`): everyone has the **Bonk Bat** (hit up close). The **Candy Cannon** (shoots a candy ball) unlocks at Rebirth 1 and the **Glue Gun** (sticks the target to the nearest wall for 5 seconds) at Rebirth 2. Weapons hit anyone except a player standing inside their own yard. A bat or cannon hit on someone carrying a Freek makes them drop it, and it goes home to its owner. On anyone else, it knocks them back and over for about a second. After being stunned or glued, players are immune for 3 seconds.
- **Trading:** send a request to anyone in your server, each side offers up to 8 Freeks, and both press Ready. A 3 second countdown runs before the swap, and any change to an offer clears both Ready buttons, so nobody can switch Freeks at the last second. The server re-checks ownership at the moment of the swap and saves both players right away.
- **Saving:** session-locked so a fast rejoin into another server can't duplicate or wipe Freeks.
