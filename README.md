# Fuse a Freek

A Roblox game: collect funny Freeks, fuse them in your barn to make new ones, earn
money every second, and get your name in the Discovery Book by being the first player
ever to fuse a new species.

## Play it in Studio

1. Install [Roblox Studio](https://create.roblox.com/) (Windows or Mac).
2. Download `FuseAFreek.rbxlx` from this repo and double-click it.
3. Press **Play**. The map, barns and menus are all made by the scripts, so there's nothing to place by hand.

In Studio progress isn't saved unless the place is published and **Game Settings → Security → Enable Studio Access to API Services** is on. To test with several players, use **Test → Clients and Servers**.

## Publishing

1. **File → Publish to Roblox**.
2. **Game Settings → Places → Max Players: 8.** There are 8 barns per server, 4 on each side of the town square (`Config.PLOT_COUNT`).
3. Saving and the Discovery Book work automatically on live servers.

## Working on the code

The code lives in `src/` and is synced into Studio with [Rojo](https://rojo.space/):

```
rojo serve                       # live-sync into Studio (install the Rojo Studio plugin)
rojo build -o FuseAFreek.rbxlx  # or build a place file
```

| Folder | Becomes | What's in it |
|---|---|---|
| `src/shared` | ReplicatedStorage.Shared | Freek list, rarities, mutations, tuning, 3D placeholder builder |
| `src/server` | ServerScriptService.Server | Saving, barns, money, fusing, trading, Discovery Book, fusion recipes |
| `src/client` | StarterPlayerScripts.Client | All the menus |

### Common changes

- **Add or rename Freeks:** edit `src/shared/Freeks.luau`. Never change an `id` once players own that Freek, because ids are what saves store.
- **Decide what two Freeks fuse into:** every pair automatically makes its own hybrid. The only hand-made results are Secrets: add Ultra pairs to `SECRETS` in `src/server/Recipes.luau` (server-only so players can't read them). The rules themselves (rarity, income bonus, mutation odds) live in `src/shared/Breeding.luau` (the code still calls fusing "breeding" internally).
- **Rarities:** Common, Uncommon, Rare, Legendary, Mystic, Ultra, Secret (`src/shared/Rarities.luau`).
- **Seasonal Freeks:** add `season = "Halloween"` to a Freek (or `Thanksgiving`, `Christmas`, `NewYears`, `Easter`, `America`). It can only be fused or bought during that event, but players keep it forever. Event dates are in `src/shared/Seasons.luau`; Thanksgiving and Easter are worked out for each year automatically.
- **Money, slots and limits:** edit `src/shared/Config.luau`. **Before launch, set `TEST_MONEY = nil`** (it currently gives every player 1,000,000 coins for testing).
- **Designing a Freek:** give it `look = { parts = {...}, effects = {...} }` in `Freeks.luau`. The format is described at the top of `src/shared/FreekModel.luau`.
- **Previewing Freeks without Studio:** `tools/snapshot/snapshot.sh out/ Blobby KingGoob:Golden` runs the real model code and saves a front and back picture of each Freek. Set it up once with `cd tools/snapshot && cargo build --release && npm install`. It needs Rust, Node and Chromium.
- **Real 3D models:** put a Model named after the species id (e.g. `Blobby`) in a `ReplicatedStorage.FreekModels` folder. Set its pivot at its feet and face it toward -Z. It replaces the placeholder automatically.

## How the game works

- **Barn:** 4 pads to start, buy up to 12. Only Freeks on pads earn money. Extra Freeks wait in your backpack (50 total).
- **Freek cannons** (`src/shared/Drops.luau`, `src/server/CannonService.luau`): a clear glass bubble covers the whole map, with 8 cannons hanging on it. Each cannon fires a random Freek every 30 seconds (they take turns, so one lands every ~4 seconds). It flies down into the town square between the barns, wanders around for a minute, then walks into the Freek House at the west end and disappears. Walk up and hold **Grab** to buy it, first come first served, and carry it home in your arms: as soon as you step inside your barn it takes the first free pad (you can't grab one if your barn is full, or while already carrying one). Grabbed Freeks can't be snatched and don't slow you down; if you die or leave on the way, it goes straight to your barn. Odds: Common 70%, Uncommon 22%, Rare 6.5%, Legendary 1.3%, Mystic 0.2%, Ultra 0.04%. Secrets never come out of a cannon. Any species of those rarities can show up, but Limited Freeks only during their event. Cannon Freeks can roll one mutation (Shadow ×2, Golden ×3, Rainbow ×10 income), which is the only way mutations enter the game. Legendary and up are announced to the server. Prices are the starter price, or 50 seconds of the Freek's income, times any mutation. Where each Freek is gets worked out from its seed and launch time, so the server and every client agree without sending positions.
- **Shop:** barn slots and weapons.
- **Fusing:** pick any two Freeks, put them in a Fusion Den and wait out the timer (the rarer one sets how long). Both are used up and become one new Freek. Two different species make a **hybrid** (`src/shared/Hybrids.luau`): its name is the parents' names mashed together (Blobby + Oinkle = Bloinkle) and its model is one parent's lower half (legs, snout, mouth) with the other's upper half (eyes, ears, antennae) on a body with both colours blended, so every pair has its own hybrid to discover. Hybrids can be fused again. The result is the rarer parent's rarity (fusing never raises it) and earns both parents' income added together plus 10% (`HYBRID_BONUS` in `src/shared/Breeding.luau`). The only way to get a Secret is from certain pairs of Ultras, listed in `SECRETS` in `src/server/Recipes.luau`. Each mutation is rolled on its own: 100% if both parents have it, 50% if only one does, so a fused Freek can carry several (their income multipliers stack, Golden + Shadow = ×6). The 🧪 Fuse window shows what a pair will make, and the Discovery Book lists the hybrids you've made and who made each one first.
- **Discovery Book:** every species, shown as a black "???" until someone finds it. The first finder in any server is saved forever and announced to everyone.
- **Offline:** you earn 50% while away, up to 8 hours.
- **Barns and stealing** (`src/server/Barn.luau`): every player gets a big red barn facing the town square, with their Freek pads and Fusion Dens inside. The barn doors always stand open; the owner holds **Lock Gate** on the padlock post just inside the doorway to put up a red barrier for 180 seconds (the on-screen chip only shows the status), then it drops until they lock it again (barns start locked for 180 seconds when you join). Owners can always walk through their own barrier. The roof fades out while you're inside so you can see. While a barn is open, other players can walk in and hold **Steal** on a Freek standing on a pad. The thief carries it in their arms and is slowed down: barely for a Common, down to well under half speed for a Secret (`carrySpeed` in `Rarities.luau`). While it's being carried, anyone can hit the carrier with a weapon to send it home (the owner can also Snatch it back), and any other player can **Snatch** it to carry it to their own barn instead. Whoever gets it inside their own barn keeps it. If the carrier dies or leaves, it goes home. Freeks in a Fusion Den or the backpack can't be stolen.
- **Rebirth:** costs 100K coins, then 4× more each time (`Config.luau`). Resets coins, Freeks and barn slots. Keeps the Discovery Book, Limited Freeks and weapons. Each rebirth adds +50% income forever, and rebirths show on the leaderboard.
- **Seasonal themes** (`src/server/SeasonalService.luau`): while an event runs, the map dresses up for it and switches back afterwards, checked every 2 minutes. Halloween switches to a spooky purple twilight, turns tree leaves orange and red and lamps orange, and adds glowing jack-o'-lanterns, hay bales, leaf piles, cobwebs and string lights on every barn doorway, string lights along the walkways and low fog over the town square, a witch hat on the Freek House, and a graveyard with a bubbling cauldron by the spawn. Ghosts drift and bats circle overhead (flown by each client in `src/client/Ambient.luau`). Other events can add a theme to `THEMES`.
- **Game passes** (`src/shared/GamePasses.luau`), sold in the 💎 Store tab: 2x Coins (499 R$), Fast Fusing (999), Longer Gate Lock (499), VIP (299), Extra Fusion Den (399, a second den so two pairs can fuse at once), and three Extra Barn Slot passes (299 each, +1 slot each, up to 15). Create each pass on the Creator Dashboard (Monetization → Passes) and paste its ID into `GamePasses.luau`. Until then it shows "Coming soon". Set `STUDIO_GRANT_ALL = true` to test every perk in Studio.
- **Door upgrades** (`src/shared/GateTiers.luau`): the frame around each barn's doors upgrades with rebirths, from Iron (0) to Bronze (1), Silver (2) and Gold (3+): chunkier posts, then finials, then a crest over the name sign, then glowing gems and sparkles.
- **Weapons** (`src/shared/Weapons.luau`): everyone has the **Bonk Bat** (hit up close). The **Candy Cannon** (shoots a candy ball) unlocks at Rebirth 1 and the **Glue Gun** (sticks the target to the nearest wall for 5 seconds) at Rebirth 2. Weapons hit anyone except a player standing inside their own barn. A bat or cannon hit on someone carrying a Freek makes them drop it, and it goes home to its owner. On anyone else, it knocks them back and over for about a second. After being stunned or glued, players are immune for 3 seconds.
- **Trading:** send a request to anyone in your server, each side offers up to 8 Freeks, and both press Ready. A 3 second countdown runs before the swap, and any change to an offer clears both Ready buttons, so nobody can switch Freeks at the last second. The server re-checks ownership at the moment of the swap and saves both players right away.
- **Saving:** session-locked so a fast rejoin into another server can't duplicate or wipe Freeks.
