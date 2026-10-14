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
2. **Game Settings → Places → Max Players: 6.** There are 6 yards per server (`Config.PLOT_COUNT`).
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
- **Shop:** sells the four starter Freeks.
- **Breeding:** pick two Freeks and wait out the timer. The rarer parent sets how long it takes. A pair with a recipe has a chance to make the new species. Otherwise the baby copies a parent. Any baby can roll a mutation (Shadow ×2, Golden ×3, Rainbow ×10 income), and a parent's mutation makes that roll 4× more likely.
- **Discovery Book:** every species, shown as a black "???" until someone finds it. The first finder in any server is saved forever and announced to everyone.
- **Offline:** you earn 50% while away, up to 8 hours.
- **Trading:** send a request to anyone in your server, each side offers up to 8 Freeks, and both press Ready. A 3 second countdown runs before the swap, and any change to an offer clears both Ready buttons, so nobody can switch Freeks at the last second. The server re-checks ownership at the moment of the swap and saves both players right away.
- **Saving:** session-locked so a fast rejoin into another server can't duplicate or wipe Freeks.
