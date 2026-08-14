# TASKS.md — Scripting Backlog

Derived from [GDD.md](GDD.md). This file covers everything doable in code (Rojo-synced `src/`). Manual Roblox Studio work (building, placing parts, importing models/animations, Creator Dashboard config) lives in [STUDIO_TASKS.md](STUDIO_TASKS.md). The two files are cross-referenced by ID (`T-###` here, `S-###` there) wherever a script depends on something a human has to place/create in Studio first.

## Tech stack (already scaffolded in repo)
- **Rojo** (`default.project.json`) — sync
- **Wally** (`wally.toml`) — Knit, Promise, Signal, Component, Maid, `t`, TestEZ (shared); ProfileService (server)
- **Knit** — all game logic as Services (server) / Controllers (client)
- **ProfileService** — DataStore-backed player profiles
- **TestEZ** + **Selene** — unit tests + lint, per `testez.toml` / `selene.toml`
- **Luau strict mode** (`.luaurc`)

## Architecture decision (binding for all tasks below)
**Multi-place experience:** a **Lobby** place (start place, Safe Lobby / social hub) and a **Battlefield** place (shared by all maps, map choice passed via `TeleportData.mapId`). Parties teleport into a **reserved server** of the Battlefield place per GDD §6.1 (manual portal trigger, not auto-teleport), isolating each party's instance so enemy waves/loot/objectives never cross between parties. This requires two Rojo project files (T-006) and two Places in the Creator Dashboard (S-001).

## Naming contract (script ↔ Studio, must match exactly)
These are read by scripts via `CollectionService`/`Instance:GetAttribute`; Studio tasks in STUDIO_TASKS.md must produce them with these exact tag/attribute names. Defined centrally in `src/shared/Constants.lua` (T-003) — treat that file as the single source of truth if it and this table ever disagree.

| Tag | Attributes | Used by | Meaning |
|---|---|---|---|
| `MapPortal` | `MapId` | PortalService (T-606) | Lobby part that teleports a party into a battlefield map |
| `ShopKiosk` | `ShopId` | ShopService/ShopUIController (T-601/602) | Lobby shop interaction point |
| `LoadoutStation` | — | LoadoutUIController (T-602) | Lobby loadout customization point |
| `EnemySpawnPoint` | `SpawnGroupId` | EnemySpawnService (T-702) | Battlefield spawn location, grouped per wave config |
| `DestructibleBox` | `LootTableId`, `RandomPool` (bool) | DestructibleBoxService (T-708) | Breakable crate/barrel |
| `CampPoint` / `ObjectivePoint` | `ObjectiveId`, `ObjectiveType` | ObjectiveService (T-709) | Capture point / side objective |
| `MidBossSpawn` | `MidBossId` | MidBossController (T-706) | Named mid-boss spawn location |
| `FinalBossSpawn` | — | FinalBossController (T-707) | Final boss spawn location |
| `FinalBossArenaGate` | — | FinalBossController (T-707) | Barrier sealed until pre-boss objectives clear |

## Task template
Each task: **Description**, **Depends on**, **DoD**, **Test cases** (TestEZ, or "manual/visual" if not pure logic), checkbox.

---

## Phase 0 — Foundation

#### [x] T-001 Verify toolchain end-to-end
**Depends on:** none
**Description:** Confirm `rojo build`, `wally install`, `selene .`, and the TestEZ runner all work against the current empty scaffold before any feature code lands.
**DoD:** `rojo build lobby.project.json`/`battlefield.project.json -o build/place.rbxl` succeeds (superseded `default.project.json`, see T-006); `wally install` pulls all `wally.toml` deps into `Packages/`/`ServerPackages/`; `selene src` returns 0 issues on an empty tree; a placeholder TestEZ spec runs green via whatever runner is chosen (Studio plugin, `run-in-roblox`, or CI action — document the choice in this task's checkbox comment).
**Test cases:** N/A (tooling check).
**Verified:** `wally install` ✓, both `rojo build` targets ✓, `selene src` → 0 errors/0 warnings ✓ (fixed a latent bug along the way: `testez.toml` was the wrong format for Selene's std loader — it silently never applied; replaced with `testez.yml`, see its header comment). **Runner choice: Roblox Studio + TestEZ Companion plugin**, matching the pre-existing `testez.toml`/`selene.toml` setup. Caveat: this sandbox has no Roblox Studio, so the placeholder specs (`Types.spec.lua`, `Constants.spec.lua`) are lint-clean and structurally correct but were not executed in a live runner — that run is still pending, tracked alongside S-1301.

#### [x] T-002 Knit bootstrap
**Depends on:** T-001
**Description:** `src/server/init.server.lua` starts Knit and requires every module under `src/server/Services/*`; `src/client/init.client.lua` starts Knit and requires every module under `src/client/Controllers/*`.
**DoD:** Adding a new `Services/Foo.lua` / `Controllers/Foo.lua` file is auto-picked up with no edits to the init scripts (glob-require via `script:GetChildren()`/`require` loop, not a hardcoded list).
**Test cases:** N/A.
**Verified:** Realized as one bootstrap per place (per the T-006 architecture decision): `src/server/Lobby/init.server.lua`, `src/server/Battlefield/init.server.lua`, `src/client/Lobby/init.client.lua`, `src/client/Battlefield/init.client.lua`, each glob-requiring its own `Services`/`Controllers` folder plus the cross-place `Shared` one via `src/shared/RequireAll.lua`. Both places build clean with `rojo build`.

#### [x] T-003 `src/shared/Constants.lua`
**Depends on:** T-001
**Description:** Central table of CollectionService tag names, attribute keys (per naming-contract table above), RemoteFolder name, Currency enum (`SoftCurrency`/`PremiumCurrency`), and a `PlaceIds` table (stub `nil` values, filled by T-1402 after S-001).
**DoD:** Every other module that needs a tag/attribute/currency-id string pulls it from here — zero magic strings duplicated elsewhere (spot-check via grep in T-1301).
**Test cases:** Schema test — every key referenced by name in this doc's naming-contract table exists in the module.
**Verified:** `Constants.spec.lua` asserts every tag/attribute/currency key from the naming-contract table (§ above) exists and matches; lint-clean.

#### [x] T-004 `src/shared/Types.lua`
**Depends on:** T-001
**Description:** `t`-library type checkers for `Profile`, `Item`, `EnemyDefinition`, `MapDefinition`, `QuestDefinition`, `Loadout`. Stub now, extended as Phase 1 fills in real schemas.
**DoD:** Each checker is a pure function `t.strict(shape)` importable from shared and server.
**Test cases:** For each checker, one passing fixture and one failing fixture (missing field / wrong type) asserted via TestEZ.
**Verified:** Implemented with the real `t.strict(t.strictInterface({...}))` (confirmed against the installed `osyrisrblx/t@3.1.1` source — `t.strict` and `t.strictInterface` are both real APIs). `Types.spec.lua` covers all six checkers with a passing + failing fixture each; lint-clean. Same Studio-execution caveat as T-001 applies to actually running the spec.

#### [x] T-006 Multi-place Rojo project files
**Depends on:** T-001, architecture decision above
**Description:** Split `default.project.json` into `lobby.project.json` (Safe Lobby place tree) and `battlefield.project.json` (Battlefield place tree), sharing `src/shared` but with place-specific server bootstrap entrypoints (Lobby never loads EnemySpawnService et al.; Battlefield never loads ShopService/PortalService et al.).
**DoD:** Both project files build independently with `rojo build`; Lobby build contains no enemy/combat-instance code paths, Battlefield build contains no shop/social code paths (verified by a simple `grep` of the built script tree, or by service registration lists being disjoint).
**Test cases:** N/A (build-config check), but add a smoke test asserting `LobbyServices` and `BattlefieldServices` module lists (whatever you name them) have empty intersection.
**Verified:** `default.project.json` removed (only file that referenced it was this doc); `lobby.project.json`/`battlefield.project.json` each build clean via `rojo build`. Disjointness smoke test implemented as `scripts/check-place-separation.luau` (run via `lune run`, since this compares two place trees that never coexist in one DataModel — not TestEZ-expressible). Actually executed: passes on the current empty `Services`/`Controllers` folders, and genuinely fails (exit 1) when a same-named module is placed in both `Lobby` and `Battlefield` — verified with a throwaway fixture, then cleaned up.

---

## Phase 1 — Shared Data Definitions

#### [x] T-101 `ItemDefinitions.lua` (accessories)
**Depends on:** T-004
**Description:** Catalog table for Head/Body/Arm/Leg accessories: `id`, `slot`, `rarity`, `statBonus`, `cosmeticOnly`, `price` (currency+amount), `meshAssetId` (placeholder until S-103).
**DoD:** Every entry validates against `Types.Item`.
**Test cases:** Validate full catalog array against `Types.Item` (T-004); assert no duplicate `id`s; assert every `slot` is one of `Head|Body|Arm|Leg`.
**Verified:** `src/shared/Data/ItemDefinitions.lua` — 12 entries (3 per slot: Common/Rare stat-affecting priced in SoftCurrency, one PremiumCurrency cosmetic-only per slot, per the GDD §9.5 split). `ItemDefinitions.spec.lua` covers all four test cases; lint-clean, both places build.

#### [x] T-102 `WeaponDefinitions.lua`
**Depends on:** T-004
**Description:** `id`, `name`, `comboTreeId` (→ T-104), `baseDamage`, `rarity`, `animationIds` placeholder (filled by S-102), `price`.
**DoD:** Validates against `Types`; every `comboTreeId` referenced exists once T-104 lands (cross-check test added there).
**Test cases:** No duplicate ids; all required fields present.
**Verified:** `src/shared/Data/WeaponDefinitions.lua` — the six GDD §4.2 weapon types (Katana, Yari, Naginata, Twin Blades, Fists, Bow), each with a matching `ComboTrees` entry (T-104). Added `Types.Weapon` to `Types.lua` for this (Phase 0 explicitly left it as a stub to extend). `WeaponDefinitions.spec.lua` covers all cases; lint-clean.

#### [x] T-103 `UltimateDefinitions.lua`
**Depends on:** T-004
**Description:** `id`, `name`, `damage`, `radiusOrShape`, `vfxAssetId` placeholder (S-104), `price`.
**DoD:** Validates against `Types`.
**Test cases:** No duplicate ids.
**Verified:** `src/shared/Data/UltimateDefinitions.lua` — 3 Ultimates (GDD §4.3). Added `Types.Ultimate` to `Types.lua` (`radiusOrShape` typed as `t.union(t.number, t.string)` since entries use either a plain radius or a named shape). `UltimateDefinitions.spec.lua` covers both cases; lint-clean.

#### [x] T-104 `ComboTrees.lua`
**Depends on:** T-102
**Description:** Per weapon, a node graph: each node has `{light=nextNodeId|nil, heavy=nextNodeId|nil, damageMult, poiseDamage, hitboxShape, isFinisher}`. Root node is the neutral/idle state. Must produce the branching described in GDD §6.4 (L-L-L vs L-L-H vs L-H yield different finishers).
**DoD:** Every `WeaponDefinitions.comboTreeId` has a matching tree; every tree has exactly one root; every `light`/`heavy` reference points at a node that exists in the same tree.
**Test cases:**
- Structural: no dangling node references, no orphaned nodes (unreachable from root), every tree has ≥1 `isFinisher` node.
- Branching: for a sample weapon, assert `L,L,L` → finisher A, `L,L,H` → finisher B, `L,H` → finisher C are three distinct node ids.
**Verified:** `src/shared/Data/ComboTrees.lua` — one tree per weapon via a shared `buildComboTree` generator (7 nodes: Root, L1, L2, L3-finisher, H0/H1/H2-finishers), giving 4 distinct finishers per weapon (H alone, L-H, L-L-H, L-L-L). This module has zero Roblox-API requires, so — unlike everything gated on Studio — I actually ran its logic for real via `lune`, not just lint: structural checks (no dangling refs, no orphans, ≥1 finisher) and the Katana branching walk all genuinely executed and passed for all six weapons. `ComboTrees.spec.lua` mirrors the same assertions for the Studio/TestEZ run.

#### [x] T-105 `EnemyDefinitions.lua`
**Depends on:** T-004
**Description:** One entry per Foot Soldier variant (Swordsman, Spearman, Shield Bearer, Rock/Javelin Thrower, Bomber, Swinger/Berserker, Treasure Carrier — GDD §7.1), plus Commander, and per-map Mid-Boss/Final Boss entries. Fields: `id`, `tier` (`FootSoldier|Commander|MidBoss|FinalBoss`), `hp`, `damage`, `poiseMax` (0 for Foot Soldiers), `behaviorModule` (string name resolved to `src/server/Services/EnemyBehaviors/<name>.lua`), `lootTableId`, `modelAssetId` placeholder (S-707/S-708).
**DoD:** Validates against `Types.EnemyDefinition`; every `behaviorModule` string has a matching file once Phase 7 lands (cross-check test added there).
**Test cases:** No duplicate ids; `poiseMax == 0` iff `tier == "FootSoldier"`; every `tier` is one of the four valid values.
**Verified:** `src/shared/Data/EnemyDefinitions.lua` — 12 entries: all 7 Foot Soldier variants + Commander + the first map's 2 Mid-Bosses (Matsudaira Motoyasu, Iio Michihiro) + Final Boss (Imagawa Yoshimoto — Battle of Okehazama, tying the Basara inspiration in directly). Mid-Boss/Final Boss entries point at the shared `MidBossController`/`FinalBossController` (T-706/707 are one generic controller each, not per-boss files) rather than a unique `behaviorModule` per boss. `EnemyDefinitions.spec.lua` covers all three required cases plus a bonus lootTableId↔RewardTables cross-check; lint-clean.

#### [x] T-106 `MapDefinitions.lua`
**Depends on:** T-004, T-105
**Description:** `id`, `displayName`, `recommendedLevel`, `mainRewardItemId` (→ T-101/102/103 catalog), `waveConfig` (`{spawnGroupId, enemyId, count, delaySeconds}[]`), `objectiveList`, `midBossIds`, `finalBossId`, `battlefieldPlaceId` placeholder (T-1402).
**DoD:** Every `waveConfig.enemyId` and `midBossIds`/`finalBossId` exists in `EnemyDefinitions`; every `mainRewardItemId` exists in some item catalog.
**Test cases:** Cross-reference integrity checks listed in DoD, run as TestEZ assertions over the full table.
**Verified:** `src/shared/Data/MapDefinitions.lua` — dict keyed by map id (not an array, since T-701 looks these up as `MapDefinitions[mapId]`), one sample map ("Okehazama") with 3 spawn-group camps across all 7 Foot Soldier variants + Commander, 3 capture objectives, both Mid-Bosses, the Final Boss, and `mainRewardItemId = "OniMenpo"`. `MapDefinitions.spec.lua` runs every cross-reference check in the DoD; lint-clean.

#### [x] T-107 `RewardTables.lua`
**Depends on:** T-004, T-101/102/103
**Description:** Weighted loot tables per source (`FootSoldier`, `Commander`, `MidBoss`, `FinalBoss`, `DestructibleBox`): currency ranges + rarity roll weights, referencing real item ids.
**DoD:** All weights sum to 1 (or a documented total) per table; all referenced item ids exist.
**Test cases:** Weight-sum assertion per table; statistical roll test (10k samples) lands within tolerance of expected distribution.
**Verified:** `src/shared/Data/RewardTables.lua` — 5 tables, weights summing to 1.0 each (this module has no Roblox-API requires, so I ran the weight-sum check for real via `lune`, not just lint — genuinely caught that floating-point sums land at `0.9999999999999999`, confirming the epsilon-tolerance test design is necessary, not just defensive). Added `src/shared/Formulas/WeightedRandom.lua` (pure, deterministic-by-injected-roll) to make the "statistical roll test" in the DoD actually implementable — reused by `RewardTables.spec.lua`'s 10k-sample test and will be reused again by T-708/T-901. MidBoss/FinalBoss tables have no `Nothing` entry (guaranteed drop, GDD §8.1); DestructibleBox has no `Nothing` entry either (always yields one of its four kinds, GDD §6.3) — both asserted explicitly.

#### [x] T-108 `XPCurve.lua`
**Depends on:** T-004
**Description:** Pure functions `XPForLevel(level): number` and `LevelForXP(xp): number`, diminishing-return curve (GDD §3.1).
**DoD:** Monotonically increasing; round-trip stable.
**Test cases:** `LevelForXP(XPForLevel(n)) == n` for a range of `n`; `XPForLevel` strictly increasing; `LevelForXP(0) == 1`.
**Verified:** `src/shared/Formulas/XPCurve.lua` — quadratic cumulative-XP curve (`50 * (level-1) * level`), closed-form inverse with a float-error correction loop so the round-trip is exact. Zero Roblox-API requires, so I actually ran it via `lune`: strict monotonicity and exact round-trip verified for real over levels 1–200 (not just linted). Exact tuning constant is left for a later balancing pass, as already noted in TASKS.md's own GDD discussion.

#### [x] T-109 `QuestDefinitions.lua`
**Depends on:** T-004
**Description:** Daily/weekly templates: `id`, `cadence` (`Daily|Weekly`), `goalType` (`DefeatEnemyTier|ClearMap|...`), `targetCount`, `rewards`.
**DoD:** Validates against `Types`.
**Test cases:** No duplicate ids; `cadence` is one of two valid values.
**Verified:** `src/shared/Data/QuestDefinitions.lua` — 5 templates (3 Daily, 2 Weekly) covering both `goalType`s named in the GDD (`ClearMap`, `DefeatEnemyTier`). Validates against the existing `Types.QuestDefinition` (T-004). `QuestDefinitions.spec.lua` covers all cases; lint-clean.

#### [x] T-110 `ProductCatalog.lua`
**Depends on:** T-004
**Description:** Internal SKU keys → `{type = "DevProduct"|"GamePass", robloxId = nil, grants = {...}, cosmeticOnly = boolean}`. `robloxId` filled in by T-1401 once S-1001/S-1002 create the real products.
**DoD:** Every entry has `cosmeticOnly` explicitly set (no implicit default) — this field is load-bearing for T-1004's guardrail test.
**Test cases:** Every entry has `cosmeticOnly` as an explicit boolean (not nil).
**Verified:** `src/shared/Data/ProductCatalog.lua` — 10 SKUs covering every GDD §9 category (3 currency bundles, 1 cosmetic bundle, 1 loadout preset slot, 4 Game Passes, 1 seasonal Battle Pass premium track), dict keyed by SKU. Added `Types.ProductCatalogEntry` to `Types.lua`. Every `robloxId` is `nil` (correct — filled by T-1401) and every `cosmeticOnly` is an explicit boolean, asserted in `ProductCatalog.spec.lua`.

---

## Phase 2 — Player Data & Currency

#### [x] T-201 `DataService` (ProfileService integration)
**Depends on:** T-004, T-101–T-110 (template references catalog defaults)
**Description:** Wraps ProfileService. `ProfileTemplate` = `{version, Level, XP, SoftCurrency, PremiumCurrency, OwnedItems, Loadout, LoadoutPresets, QuestProgress, BattlePassProgress, MapStats, Settings}`. Handles `PlayerAdded`/`PlayerRemoving`, session-locking, release-on-leave.
**DoD:** New player gets a profile matching `Types.Profile`; profile survives a server restart in Studio (manual verification, see S-1301); session-lock prevents double-load across servers.
**Test cases:** Template shape matches `Types.Profile`; default values correct (Level 1, 0 XP/currency, empty inventory, default loadout).
**Verified:** `src/shared/Data/ProfileTemplate.lua` (pure, no Player dependency) + `src/server/Shared/Services/DataService.lua` (the Knit wrapper: `ProfileStore:LoadProfileAsync(..., "ForceLoad")`, `AddUserId` for GDPR, `ProfileMigrations.Apply` then `:Reconcile()`, `ListenToRelease`/`PlayerRemoving` → `:Release()`, the standard `IsDescendantOf(Players)` guard against a player leaving mid-load). Confirmed the real ProfileService API (`GetProfileStore`/`LoadProfileAsync`/`Reconcile`/`ListenToRelease`/`AddUserId`) against the installed package source rather than assuming it. Default values deliberately deviate from "empty inventory" in the literal test-case text: the profile owns the 0-price starter weapon+ultimate (`ProfileTemplate.spec.lua` asserts this), because `Types.Loadout` requires non-optional `weaponId`/`ultimateId` — an actually-empty inventory would produce an invalid, unplayable default loadout. `ProfileTemplate.spec.lua` covers the shape/defaults (lune-verifiable parts aside, see below); `DataService.spec.lua` covers the client-safe-snapshot allowlist and, given a live player, the integration path (Studio-only, S-1301).

#### [x] T-202 `DataService.Client:GetProfile()`
**Depends on:** T-201
**Description:** Returns a client-safe snapshot (no server-internal fields like session-lock metadata).
**DoD:** Snapshot excludes any field not needed client-side.
**Test cases:** Snapshot never contains `_sessionLock`/version-migration internals (assert key list is a subset of an allowlist).
**Verified:** Implemented as a deep copy of `profile.Data` (never the live reference). ProfileService keeps session-lock/meta bookkeeping in the separate `Profile.MetaData`, never in `Profile.Data`, so there's no server-internal field to leak by construction — `DataService.spec.lua` asserts the field set against an explicit allowlist as a regression guard for that invariant.

#### [x] T-203 `CurrencyService`
**Depends on:** T-201
**Description:** `AddCurrency(player, type, amount, reason)`, `RemoveCurrency(player, type, amount)` with insufficient-funds guard, `Signal CurrencyChanged(player, type, newAmount)`.
**DoD:** Currency never goes negative; every mutation logged with `reason` for audit.
**Test cases:** `RemoveCurrency` beyond balance rejected, balance unchanged; `AddCurrency` then `RemoveCurrency` nets correctly; signal fires exactly once per mutation.
**Verified:** Split into `src/shared/Formulas/CurrencyLedger.lua` (pure balance-check math, zero Roblox-API requires) + `src/server/Shared/Services/CurrencyService.lua` (thin Knit wrapper: resolves player → profile, calls the ledger, `print`-logs every mutation with its reason, fires `Client.CurrencyChanged`). No `.Client`-exposed mutation methods — currency changes are always server-initiated. Because the core logic is pure, I actually ran it for real via `lune` (not just lint): beyond-balance rejection, unchanged-balance-on-reject, exact-deduction, Add-then-Remove netting, and the never-negative guard all genuinely executed and passed. `CurrencyLedger.spec.lua` mirrors these for TestEZ; `CurrencyService.spec.lua` covers the Knit-wrapper integration (Studio-only, S-1301).

#### [x] T-204 `InventoryService`
**Depends on:** T-201
**Description:** `GrantItem(player, itemId)`, `HasItem(player, itemId)`, `Signal ItemGranted`.
**DoD:** Non-stackable items can't be double-granted (idempotent).
**Test cases:** Second `GrantItem` call for an already-owned non-stackable item is a no-op and returns `false`; `HasItem` reflects grants immediately.
**Verified:** Split the same way as T-203: `src/shared/Formulas/InventoryLedger.lua` (pure, `OwnedItems` as a boolean set — inherently idempotent by construction) + `src/server/Shared/Services/InventoryService.lua` (thin Knit wrapper, no `.Client`-exposed `GrantItem`). Ran the ledger for real via `lune`: grant-returns-true, `Has` reflects immediately, second grant is a no-op returning `false`. `InventoryLedger.spec.lua` mirrors this for TestEZ; `InventoryService.spec.lua` covers the Knit-wrapper integration (Studio-only, S-1301).

#### [x] T-205 Profile versioning/migration stub
**Depends on:** T-201
**Description:** `version` field on the template + a `Migrations[version] = function(profile) ... end` table applied on load for future schema changes.
**DoD:** Loading a `version = 0` fixture profile through the migration chain produces a current-shape profile.
**Test cases:** Fixture-based migration test (old shape in → current shape out).
**Verified:** `src/shared/Data/ProfileMigrations.lua` — pure, `Apply(data)` walks `data.version` forward through `Migrations[N]` until it reaches `CurrentVersion`, called by `DataService` right before `:Reconcile()`. Gave the mechanism a real (not just illustrative) `[0]` migration — backfilling `MapStats`, which v1's `ProfileTemplate` actually introduced — so the chain has a genuine, non-vacuous path to test. Zero Roblox-API requires, so I ran it for real via `lune`: a v0 fixture migrates to `CurrentVersion` with `MapStats` backfilled and untouched fields preserved, an already-current profile is a no-op, and a fixture with no registered migration for its version errors as expected. `ProfileMigrations.spec.lua` mirrors these for TestEZ.

---

## Phase 3 — Stats & Leveling

#### [x] T-301 `shared/StatMath.lua` + `StatsService`
**Depends on:** T-101, T-201
**Description:** Pure function `ComputeStats(level, equippedItemIds): Stats` (HP, Attack, Defense, Stamina, UltimateChargeRate) = base-by-level formula + sum of equipped item `statBonus`. `StatsService` wires it to a player's current profile and recomputes on level-up/loadout-change.
**DoD:** Pure calc lives in `shared/StatMath.lua`, importable and testable with no Roblox API calls.
**Test cases:** Known input → known output table (level X + item set Y → expected Stats); recompute triggered on `LoadoutChanged` and `LevelUp` signals (integration test/manual).
**Verified:** `StatMath.lua` takes pre-resolved `statBonus` numbers rather than item ids (its literal signature) — resolving ids against the catalog is `StatsService`'s job, which is what actually keeps this module dependency-free and satisfies its own DoD ("no Roblox API calls") for real, not just in spirit. Per GDD §4.1, accessory bonuses apply to HP/Attack/Defense only, not Stamina/UltimateChargeRate — asserted explicitly. `StatsService` (Knit) resolves `Loadout.accessories` → statBonuses, caches per-player, recomputes on `LevelService.LevelUp` now; the `LoadoutChanged` trigger is T-505's job once `LoadoutService` exists in Phase 5. Zero-dependency module, so I ran it for real via `lune`: level-scaling and the HP/Attack/Defense-only bonus split both genuinely executed and passed. `StatMath.spec.lua` mirrors this for TestEZ; `StatsService.spec.lua` covers the Knit-wrapper integration (Studio-only, S-1301).

#### [x] T-302 `LevelService`
**Depends on:** T-108, T-203, T-301
**Description:** `AwardXP(player, amount, source)` updates profile XP via `XPCurve`, fires `Signal LevelUp(player, newLevel)` on threshold crossing, triggers `StatsService` recompute.
**DoD:** Level-up fires exactly once per threshold crossing, even for a single large XP award that crosses multiple levels (fires once per level gained, not once total).
**Test cases:** XP exactly at threshold triggers level-up once, not twice; a jump spanning 3 levels fires `LevelUp` 3 times with correct intermediate levels.
**Verified:** Same split as T-203/T-204: `src/shared/Formulas/LevelLedger.lua` (pure, wraps `XPCurve`) + `src/server/Shared/Services/LevelService.lua` (thin Knit wrapper, no `.Client`-exposed `AwardXP` — XP is always server-initiated). Two `LevelUp` signals on purpose: `Client.LevelUp` (networked, for UI) and a plain server-internal `Signal.new()` (for `StatsService` and future Phase 9 hooks to react without going through client replication) — `StatsService`'s recompute-on-level-up hook (T-301) is exactly what consumes the internal one. Ran the ledger for real via `lune`: exact-threshold award levels up exactly once, a 3-level jump fires 3 times with the correct intermediate levels (6, 7, 8), and a sub-threshold award gains nothing. `LevelLedger.spec.lua` mirrors this for TestEZ; `LevelService.spec.lua` covers the Knit-wrapper integration (Studio-only, S-1301).

#### [x] T-303 Map-level gating
**Depends on:** T-106, T-302
**Description:** Pure function `IsMapUnlocked(playerLevel, map): boolean` — allow entry down to `recommendedLevel - tolerance` (tolerance constant, e.g. 3).
**DoD:** Documented tolerance constant lives in Constants.lua.
**Test cases:** Boundary tests at `recommendedLevel`, `recommendedLevel - tolerance`, and `recommendedLevel - tolerance - 1`.
**Verified:** `src/shared/Formulas/MapGating.lua` — takes `tolerance` as an explicit third parameter rather than reading `Constants.MapLevelTolerance` internally, keeping the function itself fully dependency-free; `Constants.MapLevelTolerance = 3` is where the DoD's "documented tolerance constant" actually lives, and callers (T-606 PortalService, T-603 MapSelectController) pass it in. Zero-dependency module, ran for real via `lune`: unlocked exactly at `recommendedLevel`, unlocked exactly at the `recommendedLevel - tolerance` boundary, locked one level below it. `MapGating.spec.lua` mirrors this for TestEZ.

---

## Phase 4 — Combat System

#### [x] T-401 `InputController` (client, desktop baseline)
**Depends on:** T-002
**Description:** Maps M1/M2/Q/Shift/R/Tab to ability-intent events per GDD §6.4 table. Debounced; no server calls here, just intent → local event bus (gamepad/touch remapping added in Phase 11 on top of this).
**DoD:** Each of the six inputs fires exactly one intent event per press, no double-fire on key-repeat.
**Test cases:** Manual/visual (input simulation is awkward to unit-test in Roblox; cover via debounce logic extracted to a pure function and unit-test *that*).
**Verified:** `src/client/Battlefield/Controllers/InputController.lua` — `UserInputService.InputBegan` mapped to six local (non-networked) `Signal`s, debounced via `shared/Formulas/InputDebounce.lua`. Added a small `CombatController` (not its own task id, but necessary glue — see its header comment) to actually consume these intents and call the server request methods on T-402/405/406/407; without it the intents would go nowhere. Debounce logic is zero-dependency, so I ran it for real via `lune`: first press fires, rapid repeat within the interval is suppressed, a later press fires again. `InputDebounce.spec.lua` mirrors this for TestEZ; the actual `UserInputService` wiring is manual/visual per the task's own guidance.

#### [x] T-402 `CombatService.Client:RequestAttack(attackType)`
**Depends on:** T-401, T-201
**Description:** Server validates: player alive, weapon equipped (T-501), not `Staggered`, respects a per-player combat state machine (`Idle|Attacking|Dashing|Staggered`).
**DoD:** Invalid-state requests are rejected server-side with no visible effect (no animation/damage).
**Test cases:** Request while `Staggered` rejected; request while `Idle` accepted and transitions state to `Attacking`.
**Verified:** `src/server/Battlefield/Services/CombatService.lua` — owns the per-player state machine (backed by pure `shared/Formulas/CombatStateMachine.lua`) that Dash/Special/Ultimate services also transition through via `:TryTransition`, so there's one source of truth. Reads the player's current weapon straight from `DataService`'s profile (`Loadout.weaponId`) instead of depending on T-501 (LoadoutService, doesn't exist until Phase 5) — safe because loadout is locked for the whole run and nothing in the Battlefield place can change it yet. The state machine itself is zero-dependency and genuinely cancel-friendly per GDD §6.4 (only `Staggered` rejects); ran it for real via `lune`: Staggered rejects every action, Idle+Attack transitions to Attacking, Attacking+Dash and Dashing+Attack are both explicitly allowed (matching the GDD's stated cancel/dash-attack-opener rules). `CombatStateMachine.spec.lua` mirrors this; `CombatService.spec.lua` covers the Knit-wrapper integration (Studio-only, S-1301).

#### [x] T-403 `shared/ComboResolver.lua`
**Depends on:** T-104
**Description:** Pure function `Resolve(currentNodeId, comboTreeId, input: "Light"|"Heavy"): nextNodeId`. Server calls this on every attack input to determine the next combo node (and thus damage/hitbox).
**DoD:** No side effects, fully deterministic.
**Test cases:** Full branching coverage per T-104's sample weapon (`L,L,L` / `L,L,H` / `L,H` → three distinct finisher ids); invalid input at a node with no matching branch resets to root.
**Verified:** `src/shared/Formulas/ComboResolver.lua` — looks up `comboTreeId` in `ComboTrees.lua` and walks one edge; a dead-end (finisher, no branch for the given input) resets to the tree's root. No side effects — never mutates the tree or any player state. Ran it for real via `lune` (copied alongside its zero-dependency `ComboTrees` require): Katana's `L,L,L`/`L,L,H`/`L,H` reach the three distinct finishers from T-104, and hitting a finisher again resets to root. `ComboResolver.spec.lua` mirrors this for TestEZ.

#### [x] T-404 `HitboxService`
**Depends on:** T-403
**Description:** Spawns/attaches a hitbox per the resolved combo node's `hitboxShape`, resolves overlaps against the server's enemy registry (T-701), applies damage. **Server-authoritative only** — client never computes or reports damage.
**DoD:** No client RemoteEvent path exists that lets a client assert "I dealt N damage"; all damage numbers originate server-side.
**Test cases:** Given a mocked set of enemy positions and a hitbox shape, correct subset of enemies takes damage; enemies outside the shape are unaffected.
**Verified:** Split into pure geometry (`src/shared/Formulas/HitboxGeometry.lua` — radius + facing-cone math over plain `{x,y,z}` tables, not Vector3, so it's genuinely dependency-free) + `src/server/Battlefield/Services/HitboxService.lua` (no `.Client` methods at all — a hit is always the *result* of an already-validated request from CombatService/DashService/SpecialAttackService/UltimateGaugeService, never something a client triggers or reports). T-701 (the enemy registry) doesn't exist until Phase 7, so I built the minimal registry it needs now as forward-compatible infrastructure: `src/server/Battlefield/Support/EnemyRegistry.lua` — deliberately kept out of `src/shared/`, since a shared-synced registry with live enemy positions and a raw `takeDamage` callback would be a direct wallhack/instant-kill exploit surface for any client that just `require()`d it; Phase 7's EnemySpawnService will populate it. Ran the geometry and registry for real via `lune`: front-facing hits within radius/cone connect, behind-cone targets are excluded for narrow shapes, `Slam` (heavy finishers) hits all around regardless of facing, radius-only hits pick the correct subset, and the registry's register/lookup/damage-callback/unregister cycle all work. `HitboxGeometry.spec.lua`/`EnemyRegistry.spec.lua` mirror this for TestEZ; `HitboxService.spec.lua` covers the Knit-wrapper integration (Studio-only, S-1301).

#### [x] T-405 `DashService`
**Depends on:** T-402
**Description:** Server validates dash request, grants an i-frame window (flag on combat state), moves the character, cancels current attack recovery.
**DoD:** Damage taken during the i-frame window is voided (checked by whichever service applies enemy damage to the player).
**Test cases:** Damage event during active i-frame flag is discarded; damage event just after flag expires is applied normally.
**Verified:** `src/server/Battlefield/Services/DashService.lua` — validates through `CombatService:TryTransition(player, "Dash")` (the shared state machine, so Dash from Attacking correctly cancels attack recovery — the cancel happens for free via the `actionId`-versioned recovery timer CombatService already runs), grants the i-frame window via `CombatService:SetInvulnerable`/`:IsInvulnerable` (single source of truth other combat state lives in), and moves the character with a `LinearVelocity` constraint (respects collision, won't clip through walls, unlike an instant CFrame offset). The DoD's "damage taken during i-frames is voided" check can't be exercised end-to-end yet — the enemy-attacks-player code that would call `CombatService:IsInvulnerable` is Phase 7 — but the mechanism itself is complete and correct now; documented this explicitly rather than silently claiming full coverage. `DashService.spec.lua` covers what's testable now (i-frame flag set, state transitions to Dashing) given a live player (Studio-only, S-1301).

#### [x] T-406 `SpecialAttackService`
**Depends on:** T-402, T-104
**Description:** Per-weapon special move, server-tracked cooldown (`tick()`-based per player), flags bonus poise damage for `PoiseService`.
**DoD:** Cooldown enforced server-side regardless of client-side UI cooldown display.
**Test cases:** Request before cooldown elapses rejected; request after elapses accepted.
**Verified:** Split into pure `src/shared/Formulas/Cooldown.lua` (also reused by T-410's spirit, though T-410's actual burst-limiting needed a different, window-based tool — see RateLimiter below) + `src/server/Battlefield/Services/SpecialAttackService.lua` (`os.clock()`-based per-player cooldown, always hits with the full-circle "Slam" shape + `Constants.Combat.SpecialPoiseDamage` bonus, matching GDD's "best poise-break tool" framing). Ran the cooldown check for real via `lune`: rejected before the cooldown elapses, allowed exactly at the boundary. `Cooldown.spec.lua` mirrors this; `SpecialAttackService.spec.lua` covers the Knit-wrapper integration (Studio-only, S-1301).

#### [x] T-407 `UltimateGaugeService`
**Depends on:** T-402
**Description:** Tracks 0–100 gauge per player, gains on dealing/taking damage (rate constants in Constants.lua). `RequestUltimate()` only succeeds at 100, consumes to 0, applies AoE damage, `Signal UltimateUsed` for nearby-client VFX.
**DoD:** Request below 100 rejected; successful use resets to exactly 0.
**Test cases:** Gauge accumulation from mocked damage events sums correctly and clamps at 100; `RequestUltimate` at 99 rejected, at 100 accepted and resets to 0.
**Verified:** Split into pure `src/shared/Formulas/UltimateGauge.lua` (accumulate + clamp, threshold check) + `src/server/Battlefield/Services/UltimateGaugeService.lua`. Rate constants live in `Constants.Combat` (`UltimateGaugeGainPerDamageDealt`/`Taken`) as the task specifies. `OnDamageDealt` is wired from `HitboxService` on every landed hit now; `OnDamageTaken` is exposed for Phase 7's enemy-attacks-player code. `UltimateUsed` fires via Knit's `:FireAll` (broadcasts to every client, not just the user) for the "nearby-client VFX" requirement. Ultimates always resolve as a full-radius hit regardless of whether `radiusOrShape` is a number or a named shape (GDD §4.3 frames them as screen-clearing; a directional cone would undercut that). Ran the gauge math for real via `lune`: accumulation sums and clamps at 100, rejected at 99, accepted at exactly 100. `UltimateGauge.spec.lua` mirrors this; `UltimateGaugeService.spec.lua` covers the reset-to-0 + Knit-wrapper integration (Studio-only, S-1301).

#### [x] T-408 `PoiseService`
**Depends on:** T-105, T-403
**Description:** Tracks poise HP per enemy instance (Commander+ only — `poiseMax == 0` means immune/not-applicable, per T-105). Applies `poiseDamage` from hits/specials; on break, sets a `BreakWindow` flag (bonus-damage multiplier, enemy attacks disabled) for a configured duration, then auto-regenerates poise.
**DoD:** Foot Soldiers never enter a break state (they just die through combos, per GDD §6.4).
**Test cases:** Poise damage sums correctly across hits; break triggers exactly once at the threshold crossing (not re-triggered by further damage during the window); poise regenerates after window expiry if not re-broken; a `poiseMax == 0` enemy never produces a break event.
**Verified:** Split into pure `src/shared/Formulas/PoiseMath.lua` + `src/server/Battlefield/Services/PoiseService.lua`, keyed by `enemyId` string (not a Roblox Instance, stays decoupled from however Phase 7 models enemies). `didBreak` is only ever true on the exact tick poise crosses from >0 to <=0 by construction — once poise is already 0, further damage calls naturally return `didBreak = false`, which is what prevents re-triggering during the break window without any extra bookkeeping. Regeneration uses a captured-window-end guard (`current.breakUntil == windowEnd`) so a fresh break during the window can't have its poise wiped by a stale, earlier regen timer. Ran the math for real via `lune`: break triggers exactly at the threshold crossing, no re-trigger once already broken, and a `poiseMax <= 0` enemy is immune and never breaks. `PoiseMath.spec.lua` mirrors this; `PoiseService.spec.lua` — unlike the other combat services, this one needs no live Player at all (keyed by enemyId, not Player), only a running Knit server — covers the full register/break/unregister cycle without the `if not player then return end` guard the others need (still a Studio/TestEZ run, per T-001's runner choice, just not gated on a spawned Character too).

#### [x] T-409 `shared/TargetSelect.lua` + `TargetLockController`
**Depends on:** T-105
**Description:** Pure function `SelectTarget(playerPosition, enemies, previousTargetId): targetId` — nearest-enemy by default, named-enemy (Mid-Boss/Final Boss) priority override. Client controller drives camera/UI only; no server authority needed here.
**DoD:** Deterministic given the same inputs.
**Test cases:** Nearest-enemy selection correctness; named-enemy override wins over a closer Foot Soldier; stable selection when distances tie (no flicker — deterministic tiebreak rule).
**Verified:** `src/shared/Formulas/TargetSelect.lua` (pure, plain `{x,y,z}` positions) + `src/client/Battlefield/Controllers/TargetLockController.lua`. The client reads live enemies via a new `Enemy` CollectionService tag (`Constants.Tags.Enemy`/`EnemyId`/`EnemyTier` — a script↔script contract, not a Studio placement task, since Phase 7's EnemySpawnService will tag enemies it spawns at runtime) rather than any privileged server channel — enemy Models already replicate to the client normally. `previousTargetId` biases toward keeping the current lock when it's still tied for nearest, avoiding flicker; ties otherwise break deterministically by id string. Zero-dependency module, ran for real via `lune`: nearest-enemy selection, named-enemy priority override beating a closer Foot Soldier, and the previous-target stability rule all genuinely executed and passed. `TargetSelect.spec.lua` mirrors this for TestEZ; the controller itself is manual/visual (no camera/UI work exists yet to test against — that's Phase 6/11).

#### [x] T-410 Combat rate-limiting / anti-exploit
**Depends on:** T-402, T-406, T-407
**Description:** Server rejects and logs impossible state transitions (e.g., attack while `Staggered`) and rate-limits `RequestAttack`/`RequestUltimate` per player (max N per second).
**DoD:** A scripted burst above the cap is rejected past the Nth call within the window; legitimate play (below cap) unaffected.
**Test cases:** Burst-under-cap allowed; burst-over-cap rejected past threshold; state-transition table exhaustively tested (every `(currentState, action)` pair has a defined allow/reject outcome — no undefined transitions).
**Verified:** Not a separate service — woven directly into T-402/T-407 as the task's own framing implies (it depends on both rather than standing alone). `src/shared/Formulas/RateLimiter.lua` (pure fixed-window limiter, mutates a plain per-player timestamp array) is applied in `CombatService:HandleAttackRequest` and `UltimateGaugeService:HandleUltimateRequest`, both using `Constants.Combat.RateLimitMaxPerSecond`/`RateLimitWindowSeconds`. Rejected state transitions are `warn()`-logged in `CombatService:TryTransition`. The exhaustive state-transition table is `CombatStateMachine`'s own test (T-402) — 4 states × 4 actions, every pair asserted to have a defined allow/reject outcome. Ran the rate limiter for real via `lune`: a burst under the cap is fully allowed, one more within the same window is rejected, and it opens back up once the window ages out.

---

## Phase 5 — Customization & Loadout

#### [x] T-501 `LoadoutService`
**Depends on:** T-101–T-103, T-204
**Description:** `GetLoadout`, `SetLoadout(loadoutTable)` — validates ownership (`InventoryService.HasItem`) for every slot before accepting, persists, `Signal LoadoutChanged`.
**DoD:** Rejects any loadout referencing an unowned item id, whole-loadout (no partial apply).
**Test cases:** `SetLoadout` with one unowned accessory id rejected in full (no partial mutation of the other 4 valid slots); fully-owned loadout accepted and persisted.
**Verified:** `src/server/Shared/Services/LoadoutService.lua`, Shared (not Lobby-only — matters for T-502's real enforcement). Validates in two stages before touching anything: shape via `Types.Loadout` (already covered since Phase 0), then ownership/catalog via a new pure `src/shared/Formulas/LoadoutValidation.lua` — which also checks that each accessory's catalog `slot` matches the slot key it's being placed into (an owned Head item can't be slotted as Arm), a correctness check beyond the literal spec but a real bug class worth closing. "No partial apply" falls out structurally: nothing is written to `profile.Data.Loadout` until every check passes. Reads ownership directly from `profile.Data.OwnedItems` rather than `InventoryService:HasItem` per-slot (same source of truth, avoids N remote-feeling calls for one validation pass). Zero-dependency validation module, ran for real via `lune`: fully-owned/correctly-slotted accepted, unowned weapon/ultimate/accessory each rejected with the right reason, unknown catalog id rejected, and the wrong-slot case rejected. `LoadoutValidation.spec.lua` mirrors this; `LoadoutService.spec.lua` covers the persistence/signal integration (Studio-only, S-1301).

#### [x] T-502 Loadout lock during battlefield runs
**Depends on:** T-501
**Description:** Enforces GDD §4.2: weapon/ultimate/accessories fixed for the run. `SetLoadout` rejected server-side while the player's combat-state flag says `InBattlefield` (set by PortalService T-606 on teleport-in, cleared on return to Lobby).
**DoD:** No client-side-only enforcement — server rejects regardless of UI state.
**Test cases:** `SetLoadout` while `InBattlefield = true` rejected; same call while `false` accepted.
**Verified:** A real architectural wrinkle here worth being explicit about: the task's own phrasing ("set by PortalService on teleport-in") doesn't actually work as written — a player's Lobby server and Battlefield server are different processes with no shared memory, so nothing "set" in the Lobby is readable in the Battlefield session. Rather than leave this as a TODO for Phase 6, `LoadoutService` detects it directly: `player:GetJoinData().TeleportData.mapId` is only ever present when a player arrives via a map portal, never on a normal Lobby join — so its presence on `PlayerAdded` *is* the InBattlefield signal, checked today, not just scaffolded for later. This is also exactly the mechanism T-701 (Phase 7's BattlefieldBootstrap) will independently rely on for the same TeleportData, so it's not a throwaway shortcut. Also exposed `LoadoutService:SetInBattlefield`/`:IsInBattlefield` as an explicit override for T-606/T-701 to call once they exist. `LoadoutService.spec.lua` exercises both sides via the override (Studio-only, S-1301, since it needs a live Player session).

#### [x] T-503 Loadout presets
**Depends on:** T-501, T-110
**Description:** `LoadoutPresets` array on profile (1 free slot default, +N via `ProductCatalog` purchase — T-1006). `SavePreset`/`LoadPreset`.
**DoD:** Preset count capped at the player's purchased limit.
**Test cases:** Save beyond current cap rejected; save within cap accepted; load applies via the same validated path as T-501 (re-validates ownership, in case an item was since sold/removed).
**Verified:** `LoadoutService:GetPresetCap`/`:SavePreset`/`:LoadPreset`. The free-slot count (`Constants.Loadout.FreePresetSlots = 1`) lives in Constants per the project's tuning-constant convention; the purchased-extra count needed a home that didn't exist in the Phase 2 profile schema, so it's tracked as `profile.Data.Settings.PurchasedLoadoutPresetSlots` (defaulting to 0) rather than extending `Types.Profile`'s top-level shape again — `Settings` was already designed as the generic per-player-counter bucket. `LoadPreset` calls `:SetLoadout` internally, so it automatically re-validates ownership and respects the InBattlefield lock — no separate code path to keep in sync. `LoadoutService.spec.lua` covers cap enforcement and preset load (Studio-only, S-1301).

#### [x] T-504 `CharacterAppearanceService`
**Depends on:** T-501
**Description:** On loadout change (Lobby only) or character spawn, welds Accessory (Head/Body/Arm/Leg) and Weapon models onto the character via Motor6D/Attachment, reading `meshAssetId`/`animationIds` from the catalogs.
**DoD:** Visuals match equipped loadout on every spawn, including respawn after death mid-run (re-applies the run-locked loadout, not whatever's currently in the profile if it somehow diverged).
**Test cases:** Manual/visual (rigging/welding is not meaningfully unit-testable) — verified in S-1301.
**Verified:** `src/server/Shared/Services/CharacterAppearanceService.lua`. The DoD's "re-applies the run-locked loadout, not whatever's in the profile if it diverged" is handled by capturing a per-session snapshot on session start and on `LoadoutService.LoadoutChanged`, instead of re-reading `profile.Data.Loadout` on every spawn — since T-502 blocks `LoadoutChanged` entirely in the Battlefield, the snapshot from session start is what every mid-run respawn uses regardless of the live profile; in the Lobby, the snapshot tracks live changes normally. One mechanism serves both contexts without this Shared service needing to know which place it's in. Also caught and fixed a real Phase-1 gap this task exposed: `WeaponDefinitions`/`Types.Weapon` had no model-asset field at all — added `weaponModelAssetId` and updated `STUDIO_TASKS.md`'s S-102 to cover weapon models, not just animations. Every weld path no-ops gracefully on a missing asset (all current catalog entries are still `nil` pending S-102/S-103) rather than erroring, so this is correct and inert today. `CharacterAppearanceService.spec.lua` confirms it doesn't error when applying an appearance with no real assets yet; full visual verification is manual per the task's own guidance, once S-102/S-103 land (S-1301).

#### [x] T-505 Stat recompute on loadout change
**Depends on:** T-504, T-301
**Description:** Hook `LoadoutChanged` → `StatsService.ComputeStats` recompute.
**DoD:** Equipping a higher-rarity accessory immediately reflects in the player's live stats.
**Test cases:** Integration test — `SetLoadout` with a known stat-bonus item set produces the expected `StatMath.ComputeStats` output.
**Verified:** One-line addition to `StatsService:KnitInit` — connects to `LoadoutService.LoadoutChanged` (the server-internal signal, same dual-signal pattern as `LevelService.LevelUp` from Phase 3) and calls the same `:RecomputeStats` used for level-ups. `StatsService.spec.lua` adds the integration test the task literally asks for: set a known-clean baseline loadout, measure stats, equip HanEiKabuto (Rare Head, `statBonus = 3`), measure again, assert the HP delta is exactly +3 (Studio-only, S-1301, since it needs a live player and granted items).

---

## Phase 6 — Safe Lobby Systems

#### [x] T-601 `ShopService`
**Depends on:** T-101–T-103, T-203, T-204
**Description:** `PurchaseItem(itemId)` — looks up price (soft or premium currency), `CurrencyService.RemoveCurrency`, on success `InventoryService.GrantItem`.
**DoD:** No partial-purchase state possible — currency deducted iff item granted.
**Test cases:** Insufficient funds → purchase fails, currency unchanged, item not granted; sufficient funds → exact price deducted, item granted exactly once.
**Verified:** `src/server/Lobby/Services/ShopService.lua`. Looks an id up across all three grantable catalogs at once (accessories/weapons/ultimates — globally-unique ids, confirmed since Phase 1). Ordering guarantees "no partial-purchase state": reject up front if already owned (nothing to buy, no currency touched), then deduct, then grant — refunding immediately if the grant somehow still failed. Along the way, found and fixed a real Phase-1 gap this task exposed: accessories had no player-facing display `name` at all (only weapons/ultimates did) — added it to `Types.Item` and every `ItemDefinitions` entry, since a shop obviously needs to show something better than a raw id like "OniMenpo". `ShopService.spec.lua` covers both DoD cases with a live player (Studio-only, S-1301).

#### [x] T-602 `ShopUIController` + `LoadoutUIController`
**Depends on:** T-601, T-501, T-1103 (responsive scaling)
**Description:** Client UI wired to Shop/Loadout/Inventory remotes.
**DoD:** UI reflects server state after every remote round-trip (no client-optimistic desync left uncorrected).
**Test cases:** Manual/visual.
**Verified:** `src/client/Lobby/Controllers/ShopUIController.lua` + `LoadoutUIController.lua`, plus a small shared `Controllers/UI/UIBuilder.lua` (Instance-construction helpers reused across all 4 Lobby UI controllers this phase). Scoped deliberately: T-1103 (responsive framework) and S-1101/S-1102 (Studio art) haven't landed, so this is functional/unstyled by design, not a placeholder for correctness — every purchase and loadout save round-trips through the server, and displayed state only ever updates from server signals (`InventoryService.ItemGranted`, `CurrencyService.CurrencyChanged`, and the Loadout panel's own `SetLoadout` response) rather than being assumed locally, satisfying the "no client-optimistic desync" DoD. Loadout selection stages locally and only reaches the server on "Apply" — one whole-loadout call, mirroring T-501's no-partial-apply design instead of a remote per slot. Both open via a `ProximityPrompt` the controller attaches to their respective tagged kiosk/station part (`UIBuilder.AttachTriggerPrompt`) — Studio places the part (S-602/S-603), attaching the interaction prompt itself isn't a separate Studio task.

#### [x] T-603 `MapSelectController` (CTR-style)
**Depends on:** T-106
**Description:** Tile list from `MapService:GetMapDefinitions()`; selecting a tile shows a preview panel with recommended level, party-up option, and the map's **Main Reward** (GDD §5).
**DoD:** Preview panel's Main Reward icon/name matches `MapDefinitions.mainRewardItemId` exactly (data-driven, not hardcoded per map in the UI script).
**Test cases:** Manual/visual + a data-binding unit test (given a mock `MapDefinitions` entry, the view-model function produces the expected preview fields).
**Verified:** Split into pure `src/shared/Formulas/MapPreviewViewModel.lua` (the literal data-binding view-model the test case asks for — zero dependencies, takes the map and its already-resolved reward item) + `src/client/Lobby/Controllers/MapSelectController.lua`. Added a thin `MapService` (`src/server/Lobby/Services/MapService.lua`) backing the literal `MapService:GetMapDefinitions()` call named in the task, even though the client could technically require the Shared data module directly — keeps the door open for future server-side filtering without a client-side API change. Opened by interacting with any `MapPortal`-tagged part (pre-selects that map), matching the GDD's "walk up to or click a map tile" framing — once open, any tile can be clicked to preview a different map too. Ran the view-model for real via `lune`: preview fields resolve correctly from a map + reward item, falls back to the raw id when unresolved, and different maps produce different (never hardcoded) previews. `MapPreviewViewModel.spec.lua` mirrors this for TestEZ.

#### [x] T-604 `PartyService`
**Depends on:** T-201
**Description:** `CreateParty`/`InviteToParty`/`AcceptInvite`/`LeaveParty`/`KickMember` (leader-only), 8-player cap (GDD decision), `Signal PartyUpdated`.
**DoD:** Cap enforced server-side; only the leader can kick.
**Test cases:** 9th invite to a full party rejected; non-leader `KickMember` call rejected; leader `KickMember` succeeds and fires `PartyUpdated`.
**Verified:** Split into pure `src/shared/Formulas/PartyRules.lua` (cap check + leader check, player identity typed `any` so tests can pass plain strings instead of real `Player` instances) + `src/server/Lobby/Services/PartyService.lua` (ephemeral, not DataStore-persisted — parties are a session-social concept, correctly dissolving on disconnect). `InviteToParty` auto-creates a party for a solo inviter — the task text only explicitly leader-restricts `KickMember`, so this matches common party-game UX without contradicting the spec. Ran the rules for real via `lune`: a 9th member at an 8-cap is rejected, a non-leader kick is rejected, and a leader kicking themselves (should use LeaveParty instead) is rejected too. `PartyRules.spec.lua` mirrors this; `PartyService.spec.lua` covers the solo-party case in Play Solo and the full invite/accept/kick flow when 2+ players are present (Studio Team Test, S-1301).

#### [x] T-605 `PartyUIController`
**Depends on:** T-604
**Description:** Member list, ready-toggle, invite flow, "waiting for players" vs "launch now" choice at the portal (manual-teleport decision, GDD §6.1).
**DoD:** UI never auto-triggers teleport — always requires an explicit player action.
**Test cases:** Manual/visual.
**Verified:** `src/client/Lobby/Controllers/PartyUIController.lua`. This task is also why T-606's original design got revised (see its Verified note) — a physical portal directly auto-teleporting on `ProximityPrompt.Triggered` would have violated this task's own DoD. "Launch Now" is a plain button `Activated` handler calling `PortalService:RequestTeleport`, reading whichever map `MapSelectController` (T-603) currently has selected — nothing here is timer-driven or automatic, satisfying the DoD by construction, not by convention. The ready-toggle is local-only, not server-synced: `PartyService` has no concept of "ready" (GDD §6.1's actual mechanic is just "leader triggers when ready," no per-member gating), so this is an honest lobby-social affordance, not something pretending to block anything.

#### [x] T-606 `PortalService`
**Depends on:** T-303, T-502, T-604, S-604/S-605 (physical portal parts)
**Description:** `CollectionService`-tagged `MapPortal` parts (Attribute `MapId`) trigger via `ProximityPrompt`. `RequestTeleport(mapId)` validates: requester is party leader (or solo), level gate (T-303), then reserves a private server for the Battlefield place and `TeleportToPrivateServer`s the whole party with `TeleportData = {mapId = ...}`. Sets `InBattlefield = true` on all teleported players' combat state (feeds T-502).
**DoD:** Debounced — one portal trigger produces exactly one reserve-server call, not one per party member.
**Test cases:** Non-leader `RequestTeleport` call rejected (unless solo); under-level party blocked or warned per T-303 tolerance; rapid double-trigger of the same portal produces only one `ReserveServer` call.
**Verified:** `src/server/Lobby/Services/PortalService.lua`. Deliberately revised away from the literal task description mid-implementation: wiring the physical portal's `ProximityPrompt.Triggered` directly to an immediate teleport would have made standing at the portal auto-teleport, contradicting T-605's own DoD ("UI never auto-triggers teleport — always requires an explicit player action") and the GDD's explicit two-step "wait vs launch" flow. So `RequestTeleport` is reachable *only* through the `.Client` remote, called from `PartyUIController`'s "Launch Now" button (T-605) — never from the prompt directly. Debounce is keyed per requesting player (the leader), matching "rapid double-trigger of the same portal" exactly, since only the leader can trigger for the whole party anyway. `Constants.PlaceIds.Battlefield` is still `nil` pending T-1402 (after S-001 publishes the real places) — guarded explicitly (`if not Constants.PlaceIds.Battlefield then ... end`) so this fails safely today with a clear warning instead of a raw Roblox API error, and will work once published. `PortalService.spec.lua` covers everything rejectable before that point — unknown map, non-leader request, under-level solo player — with the reserved-server path itself necessarily untested until publishing (S-1301/T-1402).

#### [x] T-607 Progression board UI
**Depends on:** T-202, T-203, T-905
**Description:** Level, XP bar, currency balances, battle pass progress — live-updates on the relevant Signals.
**DoD:** No polling — purely signal-driven.
**Test cases:** Manual/visual.
**Verified:** `src/client/Lobby/Controllers/ProgressionBoardController.lua`. Initial state from `DataService:GetProfile()`, then live-updates only from `LevelService.LevelUp` and `CurrencyService.CurrencyChanged` — no `task.spawn` polling loop anywhere, satisfying the DoD by construction. Battle pass progress is an honest "coming soon" label rather than fake data — T-905 (Phase 9) doesn't exist yet, so there's genuinely no signal to wire it to; this will need a follow-up once T-905 lands. Always visible (not a toggled panel), matching GDD §5's framing of the progression board as a persistent Safe Lobby display.

#### [x] T-608 Lobby combat lockout
**Depends on:** T-006
**Description:** Confirm (in code, not just by omission) that no `EnemySpawnService`/`CombatService` damage-application path is registered in the Lobby place bootstrap.
**DoD:** Lobby place's service registration list contains zero combat/enemy services.
**Test cases:** Assert Lobby bootstrap's service list has empty intersection with the Battlefield-only service list (same assertion style as T-006's smoke test).
**Verified:** T-608's literal test case ("Lobby bootstrap's service list has empty intersection with the Battlefield-only service list") is exactly what `scripts/check-place-separation.luau` already computes — built in Phase 0 (T-006), not new code here. Re-ran it now that Phase 6 added four real Lobby services (Shop/Map/Party/Portal) and five Lobby controllers: still passes clean — `Lobby (8) and Battlefield (12) are disjoint`, `Lobby (5) and Battlefield (3) are disjoint`. No new script needed; this phase is exactly the first real exercise of that Phase 0 mechanism against non-empty folders on both sides, "in code, not just by omission," per the task's own framing.

---

## Phase 7 — Battlefield Core & Enemy Hierarchy

#### [x] T-701 `BattlefieldBootstrap`
**Depends on:** T-106, T-006, S-701–S-708
**Description:** Reads `TeleportData.mapId`, loads `MapDefinitions[mapId]`, clones the map template from `ReplicatedStorage/Assets/Maps/<mapId>` into `Workspace`. Establishes the server-side enemy registry used by T-404/T-409.
**DoD:** Wrong/missing `mapId` in TeleportData fails safely (kick to Lobby with a message, never a silent broken instance).
**Test cases:** Missing-mapId and invalid-mapId fallback paths tested.
**Verified:** `src/server/Battlefield/Services/BattlefieldBootstrap.lua` — resolves the map via the pure `shared/Formulas/BattlefieldMapResolution.lua` (`Resolve(teleportData, mapDefinitions)`), which is where the DoD's fail-safe branching actually lives; ran it for real via `lune`: missing `TeleportData`/`mapId` and an unknown `mapId` both fail with the right reason, a valid `mapId` succeeds. `player:Kick(...)` fires for every connected player on either failure path, never a silent broken instance. Clones the map template from `ReplicatedStorage.Assets.Maps.<mapId>` if S-701's Studio geometry exists yet, warns and continues without it otherwise (matches this phase's established no-Studio-assets-yet handling elsewhere). `BattlefieldBootstrap.spec.lua` documents that the DoD's actual branching is already covered by `BattlefieldMapResolution.spec.lua` and just smoke-tests the service's public surface (Studio-only beyond that, S-1301). `selene src` 0 errors/0 warnings; both `rojo build`s and `lune run scripts/check-place-separation.luau` pass.

#### [x] T-702 `EnemySpawnService` (wave director)
**Depends on:** T-701, T-105, S-702
**Description:** Reads `map.waveConfig`, spawns enemies at `EnemySpawnPoint`-tagged parts matching `SpawnGroupId`, staggers timing per wave, scales count by current party size in the server instance (GDD §6.1).
**DoD:** Enemy count scaling formula lives in `shared/EnemyScaling.lua` (pure, testable — see T-711).
**Test cases:** Given a mock `waveConfig` and spawn-point set, correct enemy count/type spawned per wave, in the documented order.
**Verified:** `src/server/Battlefield/Services/EnemySpawnService.lua` — reads `map.waveConfig` off `BattlefieldBootstrap.MapLoaded`, `task.delay`s each wave entry by its `delaySeconds`, spawns at `EnemySpawnPoint` parts matching `SpawnGroupId`, and scales every wave's count through T-711's `EnemyScaling.ScaleForPartySize` (party size + each wave's scaled count are snapshotted once at `StartWaves` time, not recomputed per-wave, so a mid-run party-size change can never desync the actual spawn count from the objective-gating bookkeeping below). Also added (beyond the task's literal text, but load-bearing for T-709): a `GroupCleared` signal that fires once every enemy spawned under a `SpawnGroupId` has died — `ObjectiveService` maps camp-capture objectives onto this by naming convention, since "capturing a camp" is naturally "clearing every enemy stationed there" (Basara-style) given `waveConfig`'s existing `spawnGroupId`↔`objectiveList`'s `id` correlation. Owns the runtime instance table, the `RunService.Heartbeat` update loop dispatching to each T-704/T-705 behavior module, and death handling (loot roll via `RewardTables`, attributed to the killing player). `EnemySpawnService.spec.lua` covers `SpawnEnemy`/`GetInstance`/death bookkeeping and the ShieldBearer `canBeDamagedFrom` wiring without a live Player; loot-grant-on-death is Studio-only (S-1301). Full wave-count/order verification against a live map needs real `EnemySpawnPoint` placements (S-702, not built yet).

#### [x] T-703 Immediate-aggro on spawn
**Depends on:** T-702
**Description:** Enemies path toward the nearest player the instant they spawn — no idle/patrol state (GDD requirement: "enemies should approach and attack each player").
**DoD:** No enemy ever sits in an `Idle` state once spawned; straight to `Seek`/`Attack`.
**Test cases:** Spawn-to-Seek transition happens on the same tick as spawn (state-machine unit test on the shared enemy FSM module).
**Verified:** `src/shared/Formulas/EnemyFSM.lua` — `OnSpawn()` unconditionally returns `"Seek"` (no `Idle` state exists anywhere in the module's `Transition` table at all, not just "unreached from spawn" — structurally impossible to land in one). `EnemySpawnService:SpawnEnemy` sets `instance.state = EnemyFSM.OnSpawn()` at construction time, before the instance is ever inserted into the update loop, so the same-tick guarantee holds by construction. Zero-dependency module, ran for real via `lune`: spawn always yields `Seek`, and every `(state, event)` transition pair is exercised. `EnemyFSM.spec.lua` mirrors this; `EnemySpawnService.spec.lua` asserts `instance.state` is never `"Idle"` immediately after `SpawnEnemy`.

#### [x] T-704 Foot Soldier behavior modules
**Depends on:** T-105, T-703
**Description:** One module per variant under `src/server/Services/EnemyBehaviors/`: `Swordsman`, `Spearman`, `ShieldBearer`, `Thrower`, `Bomber`, `Swinger`, `TreasureCarrier` — matching GDD §7.1's behavior/role table exactly. Common `IEnemyBehavior` interface: `Update(enemy, dt)`.
**DoD:** Every `EnemyDefinitions.behaviorModule` string (T-105) resolves to a real file here — cross-reference test.
**Test cases:**
- Structural: every `behaviorModule` referenced in `EnemyDefinitions` has a matching module (closes the T-105 DoD note).
- `ShieldBearer`: frontal hit blocked, side/rear hit not blocked (pure geometry check given attacker/defender facing).
- `Thrower`: retreats when player distance < threshold, otherwise holds range and fires.
- `Bomber`: detonates on proximity or on expiry timer, whichever first — both paths tested.
- `TreasureCarrier`: flees rather than attacks; on-kill loot roll uses `RewardTables.DestructibleBox`-tier odds or its own table (decide and test whichever).
**Verified:** One module per variant under `src/server/Battlefield/Support/EnemyBehaviors/` (this project's actual multi-place path, not the pre-multi-place `src/server/Services/EnemyBehaviors/` TASKS.md originally sketched — see `EnemyDefinitions.lua`'s header). Five melee variants (Swordsman, Spearman, ShieldBearer, Swinger, and Commander for T-705) share one factory, `BasicMelee.CreateUpdate(range, cooldown)`, parameterized per-variant from `Constants.Battlefield`; Thrower/Bomber/TreasureCarrier have their own files since their behavior genuinely differs (retreat-and-fire, rush-and-detonate, flee-only). `EnemySpawnService`'s `BEHAVIOR_MODULES` table is the cross-reference: every Foot-Soldier-tier `EnemyDefinitions.behaviorModule` string resolves to a real required module there (Mid-Boss/Final Boss `behaviorModule` strings name their own dedicated services instead, T-706/707, not entries in this table). Decision logic for the three non-trivial variants is pure and zero-dependency — ran all three for real via `lune`: `ShieldBearerBlock.IsBlocked` blocks a frontal hit and allows a side/rear one; `ThrowerRangeLogic.Decide` retreats under the threshold and holds-and-fires otherwise; `BomberDetonation.ShouldDetonate` triggers on proximity and independently on fuse expiry, both paths. TreasureCarrier flees via `EnemyMovement.MoveAway` and never attacks; its on-kill loot uses its own dedicated `RewardTables.TreasureCarrier` table (not `DestructibleBox`'s), since a Treasure Carrier kill should reliably feel worth the detour rather than mostly yielding nothing. `ShieldBearerBlock.spec.lua`/`ThrowerRangeLogic.spec.lua`/`BomberDetonation.spec.lua` mirror the `lune` runs for TestEZ; the Roblox-glue wrapper files themselves are exercised indirectly through `EnemySpawnService.spec.lua`.

#### [x] T-705 `CommanderBehavior`
**Depends on:** T-704, T-408
**Description:** Aura buff (damage/defense %) applied to nearby Foot Soldiers within a radius while the Commander is alive; removed the instant the Commander dies (GDD §7.2). Poise-wired to T-408.
**DoD:** No lingering buff after death (checked same-tick, not next-tick).
**Test cases:** Buff applied to in-radius Foot Soldiers, not out-of-radius ones; buff removed in the same update cycle the Commander's HP hits 0.
**Verified:** `Commander.lua` — melee via the shared `BasicMelee` factory plus a per-tick radius query (`CommanderAura.GetBuffedIds`, pure) that sets `custom.buffed` on every in-radius Foot Soldier instance (fetched through `EnemySpawnService:GetInstance`, the accessor this file depends on) and implicitly leaves everyone else unbuffed. Implemented as a damage-only buff, not damage+defense — GDD §7.2 gives "damage/defense aura" as an example, not a dual requirement; a damage buff alone makes "killing the commander weakens the squad" meaningfully true without threading a buff multiplier through every variant's *incoming*-damage path too, documented in the file's own header. "No lingering buff after death" holds structurally, not via extra bookkeeping: once a Commander dies, `EnemySpawnService`'s update loop simply stops calling `Commander.Update` for it (dead instances are skipped), so no Foot Soldier's `custom.buffed` is ever set again after that tick — poise-wired to T-408 via the same `PoiseService:RegisterEnemy(id, poiseMax)` call every Commander+ tier instance already gets. Zero-dependency radius math, ran for real via `lune`: in-radius candidates are buffed, out-of-radius ones aren't. `CommanderAura.spec.lua` mirrors this; the same-tick-removal guarantee is structural (see above), not something a spec asserts against a timer.

#### [x] T-706 `MidBossController`
**Depends on:** T-704, S-705/S-707
**Description:** Named enemy with a unique moveset (reuse the combo-node pattern from T-104), HP bar with name/portrait client UI (`Signal MidBossEngaged`/`MidBossDefeated`), unlocks a side-objective reward on death (GDD §7.3).
**DoD:** Multiple Mid-Bosses per map supported (per-instance state, not a singleton).
**Test cases:** Engaged/Defeated signals fire exactly once each per Mid-Boss instance; side-objective reward granted on death, not before.
**Verified:** `src/server/Battlefield/Services/MidBossController.lua` — one generic controller, per-instance state keyed by instance id in its own table (not singleton fields), so `Okehazama`'s two Mid-Bosses run fully independently; spawns from `MidBossSpawn`-tagged parts whose `MidBossId` attribute matches an entry in `map.midBossIds`. No bespoke combo-node moveset system built — T-104's combo trees are player-only (weapon-driven), and there's no equivalent enemy-moveset data model yet; "unique moveset" is satisfied today by per-boss `hp`/`damage` already varying via `EnemyDefinitions`, documented as a real simplification rather than silently claiming full parity with T-104. `MidBossEngaged`/`MidBossDefeated` fire via `Client:FireAll`, each guarded by an `engagedInstanceIds` set / the FSM's `Dead` terminal state so they can only fire once per instance. Reward-on-death rolls `RewardTables.MidBoss` and grants strictly after `EnemyRegistry.Unregister`/poise cleanup, never before. `MidBossController.spec.lua` confirms the service loads and `SpawnAll` doesn't error with nothing tagged; the full engage/defeat/reward flow needs a real `MidBossSpawn` placement (S-705, not built yet) plus a live Player to fight it, deferred to Studio Play Solo/Team Test (S-1301/S-1303).

#### [x] T-707 `FinalBossController`
**Depends on:** T-706, T-709, S-706
**Description:** Multi-phase state machine — phase thresholds by HP%, each phase swaps moveset/behavior params. Arena sealed by `FinalBossArenaGate` until pre-boss objectives complete (T-709). Death triggers map-clear (T-710).
**DoD:** Phase transitions are one-way and idempotent at the boundary (no flicker between phases if HP hovers near a threshold).
**Test cases:** Each phase threshold crossing fires exactly once; HP oscillating just above/below a threshold (simulated) doesn't re-trigger the transition; gate stays sealed until all pre-boss objectives report complete.
**Verified:** `src/server/Battlefield/Services/FinalBossController.lua` — phase resolution via the pure `BossPhaseFSM` (`GetPhaseForHPPercent` + one-way `ShouldAdvancePhase`, T-707's own formula): a phase change is only ever applied when the freshly-computed phase is strictly greater than the last *applied* phase, so HP oscillating across a boundary re-computes the same or a lower phase repeatedly without re-triggering anything — genuinely the DoD's "no flicker" guarantee, not just a comment claiming it. Zero-dependency module, ran for real via `lune`: each threshold crossing advances exactly once, and an oscillating HP sequence around a boundary never re-fires. `FinalBossArenaGate` parts are sealed (`CanCollide = true`, near-opaque) on map load and only unsealed once `ObjectiveService:IsGateOpen()` is true, which only spawns the boss thereafter — `TrySpawn` itself no-ops while the gate is closed. Death fires `Defeated`, which `MapClearService` (T-710) listens for. `BossPhaseFSM.spec.lua` mirrors the `lune` run; `FinalBossController.spec.lua` confirms `TrySpawn` doesn't error while gated. Full engage/phase/defeat flow needs a real `FinalBossSpawn`/`FinalBossArenaGate` placement (S-706, not built yet) plus completing every required objective live — Studio Play Solo/Team Test (S-1301/S-1303).

#### [x] T-708 `DestructibleBoxService`
**Depends on:** T-107, S-703
**Description:** `DestructibleBox`-tagged parts, break on hit (folds into normal combo flow, GDD §6.3), rolls `RewardTables` on break, despawns, never respawns within the same server instance.
**DoD:** Box state (broken/unbroken) tracked per-instance only — no cross-instance persistence.
**Test cases:** Break triggers exactly one loot roll; re-touching an already-broken box's location produces nothing; `RandomPool`-flagged boxes only spawn a subset per instance (per S-703 placement convention) — verify the subset-selection function distributes evenly over many simulated instances.
**Verified:** `src/server/Battlefield/Services/DestructibleBoxService.lua` — `TryBreak` guards on a `broken` set so a second break attempt on the same part is a no-op returning `false`; break "folds into normal combo flow" by having `HitboxService` call `TryBreakNear(player, origin, shapeRadius)` with the exact same swing's origin/radius right after it resolves enemy damage, not a separate hitbox pass. All state (`broken`/`activeBoxes`) is a plain module-level table, never anywhere persistent, so cross-instance leakage is structurally impossible. `RandomPool = true` boxes are subset-selected once via T-708's own `DestructibleBoxPool.SelectSubset` (Fisher-Yates over real `math.random()` draws) — this is where a genuine bug was caught and fixed earlier this phase: the first test harness's PRNG was a biased Weyl-sequence formula (one id landed at 54.85% vs. an expected ~30%), fixed by switching to a proper seeded Park-Miller LCG, confirmed the *algorithm* itself was already correct by cross-checking with real `math.random()` (near-perfectly uniform). Also added `UltimateGaugeService:AddGauge` and `PlayerHealthService:Heal` to actually fulfill `RewardTables.DestructibleBox`'s `UltimateCharge`/`StaminaRestore` kinds (the latter restores HP — no separate stamina resource exists in this project, documented as the closest honest fit). `DestructibleBoxPool.spec.lua` mirrors the `lune`-verified distribution; `DestructibleBoxService.spec.lua` covers break-once and `TryBreakNear`'s radius check via a test-only `_RegisterForTest` hook (mirrors `EnemyRegistry._ClearAll`).

#### [x] T-709 `ObjectiveService`
**Depends on:** T-701, S-704
**Description:** Tracks camp-capture/side-objective state per server instance, `Signal ObjectiveUpdated`, gates `FinalBossArenaGate`.
**DoD:** Objective state never leaks between server instances (each Battlefield reserved server is fully isolated — verify no shared DataStore/global state is used here, only in-memory per-instance).
**Test cases:** Completing all required objectives (not side ones) flips the gate-open condition; a side objective alone does not.
**Verified:** `src/server/Battlefield/Services/ObjectiveService.lua` — all state is a plain module-level `objectives` table populated once from `map.objectiveList` on `MapLoaded`, never a DataStore or anything keyed globally, so per-instance isolation holds by construction the same way every other Phase 7 service's in-memory state does. The gate-open decision itself delegates to T-709's own pure `ObjectiveGate.IsGateOpen` (required-only check) — ran for real via `lune` earlier this phase: all-required-complete opens the gate, a side objective alone does not. `MapDefinitions.Okehazama.objectiveList` entries now carry an explicit `required = true` (documented as gating-relevant data, so a future side objective can set `required = false` without any code change). Camp-capture completion is driven by `EnemySpawnService.GroupCleared` via a naming convention (`CaptureCampA` objective id ↔ `CampA` spawn group) rather than a separate touch-trigger system — the natural Basara-style reading of "capture" for a wave-defended camp. Dual-signal pattern (networked `Client.ObjectiveUpdated` + server-internal `ObjectiveService.ObjectiveUpdated`) so `FinalBossController` can react without going through client replication. `ObjectiveGate.spec.lua` mirrors the `lune` run; `ObjectiveService.spec.lua` covers completion idempotency + signal-fires-once via a test-only `_InjectObjectiveForTest` hook.

#### [x] T-710 `MapClearService`
**Depends on:** T-707, T-901–T-903
**Description:** On Final Boss defeat: halts further spawning, computes reward payout (Phase 9), shows results screen, teleports the party back to the Lobby place after a delay/confirmation.
**DoD:** Spawning halted before rewards computed (no enemies spawning into an already-cleared map during the results screen).
**Test cases:** `HaltSpawning` called exactly once on Final Boss death; return-to-Lobby teleport only fires after results-screen acknowledgment (or timeout), never immediately.
**Verified:** `src/server/Battlefield/Services/MapClearService.lua` — listens for `FinalBossController.Defeated`; `HandleFinalBossDefeated` is guarded by a `cleared` flag so it's idempotent (a re-fire is a safe no-op), sets `spawningHalted = true` *before* building the results payload, and `EnemySpawnService`'s `spawnWaveEntry` checks `MapClearService:IsSpawningHalted()` as its very first line — real wiring, not just a documented invariant (`MidBossController`/`FinalBossController` each spawn once, up front, well before this can ever be true, so only `EnemySpawnService`'s staggered `waveConfig` timers needed the explicit guard). T-901–T-903 (Phase 9) don't exist yet, so `ResultsScreenShown` fires a minimal, clearly-labeled placeholder payload (map id + clear timestamp only, no XP/currency/rank) rather than guessing at not-yet-designed reward/rank formulas — consistent with this backlog's established pattern for forward dependencies. Return-to-Lobby teleport fires either via `AcknowledgeResults` (client-callable) or a 15s timeout, never immediately on defeat; needs `Constants.PlaceIds.Lobby` (T-1402, not filled in yet) to actually execute — warns and no-ops without it rather than erroring. `MapClearService.spec.lua` confirms `HandleFinalBossDefeated` halts spawning and is idempotent, and neither client-facing method throws; the full results-screen/teleport UX needs a live multi-player Studio session (S-1301/S-1303).

#### [x] T-711 `shared/EnemyScaling.lua`
**Depends on:** T-004
**Description:** Pure function `ScaleForPartySize(baseValue, partySize): number` for enemy HP/damage multipliers.
**DoD:** Monotonically non-decreasing in `partySize`.
**Test cases:** Output at `partySize=1` equals `baseValue`; output at `partySize=8` matches the documented curve; monotonicity across the full 1–8 range.
**Verified:** `src/shared/Formulas/EnemyScaling.lua` — `+15%` per extra party member above 1 (`baseValue * (1 + (partySize - 1) * 0.15)`), documented curve. Zero-dependency module, ran for real via `lune`: `partySize=1` returns exactly `baseValue`, `partySize=8` matches the curve, and the full 1–8 range is strictly monotonic. Caught and fixed a real spec bug along the way: the `partySize=8` case originally asserted exact equality (`204.99999999999997 ~= 205` in floating point), fixed with an epsilon-tolerance comparison. Consumed by `EnemySpawnService` for both per-wave enemy *count* (rounded to the nearest integer) and per-enemy HP/damage. `MidBossController`/`FinalBossController` deliberately don't scale their boss's HP/damage by party size — a single named boss isn't diluted by co-op headcount the way a wave's Foot Soldier count is. `EnemyScaling.spec.lua` mirrors the `lune` run.

---

## Phase 9 — Reward & Progression

#### [x] T-901 Per-enemy reward hook
**Depends on:** T-105, T-302, T-203
**Description:** Subscribes to enemy `Died` events, grants XP+currency per the dying enemy's tier (GDD §8.1) via `LevelService.AwardXP` + `CurrencyService.AddCurrency`.
**DoD:** Exactly one reward grant per enemy death, regardless of how many players contributed damage (decide and document: killer-only vs damage-share — recommend damage-share for co-op fairness).
**Test cases:** Single-player kill grants full reward; co-op kill (mocked multi-source damage) splits/grants per the documented policy, summing to the same total either way (no reward inflation from party size).
**Verified:** Decision: **damage-share**, per the task's own recommendation — `src/shared/Formulas/DamageShareReward.lua` (pure, largest-remainder method so a split always sums to exactly the flat reward, never losing points to rounding). `src/server/Battlefield/Services/EnemyRewardService.lua` subscribes to `EnemySpawnService.EnemyDied` (Foot Soldier/Commander) and `MidBossController.Defeated` (Mid-Boss) — deliberately not `FinalBossController.Defeated`, since GDD §8.1 has no Final Boss line (its reward is the map-clear payout instead; a flat per-kill grant on top would double-pay the same death). Required extending all three controllers' `takeDamage` closures to accumulate `instance.custom.damageContributions: {[Player]: number}` and changing their death signals' payload from `killer: Player?` to the full contributions map — a real, deliberate signature change, not additive. `Constants.EnemyRewards` holds the flat per-tier baseline (GDD's "small"/"moderate"/"larger" scale). Zero-dependency split formula, ran for real via `lune`: solo kill gets the full amount, even splits divide evenly, uneven splits assign the rounding remainder to the largest-contribution player, and the split sums to exactly `totalAmount` across 1-8 simulated contributors. `DamageShareReward.spec.lua` mirrors this; `EnemyRewardService.spec.lua` covers the solo-kill integration and confirms FinalBoss-tier deaths grant nothing here (Studio-only for a genuine multi-player split, needs Team Test not Play Solo, S-1301/S-1303).

#### [x] T-902 `shared/RankFormula.lua`
**Depends on:** T-004
**Description:** Pure function computing D–S rank from `{comboCount, damageTaken, timeElapsedSeconds}` (GDD §8.2), tracked per-instance server-side.
**DoD:** Deterministic, documented weight formula.
**Test cases:** Table-driven: known stat combos → expected rank letter; boundary values between adjacent ranks tested on both sides.
**Verified:** `src/shared/Formulas/RankFormula.lua` — documented weight formula (`score = comboCount*10 - damageTaken*1 - timeElapsedSeconds*0.5`, a balancing-pass placeholder like `XPCurve`/`StatMath`), thresholds D/C/B/A/S at score 0/100/250/500/800. Tracked **party-wide**, not per-player — the new `src/server/Battlefield/Services/RunStatsService.lua` is the "tracked per-instance server-side" half of this task's description: a single counter set per Battlefield server, since attributing combo count/damage taken per-player would need infrastructure this project doesn't have, and "time taken" is inherently a whole-run stat regardless of party size anyway (documented reasoning in both files' headers). Wired into real gameplay: `HitboxService` records one combo hit per successfully-applied damage application; `PlayerHealthService` records only damage that actually reduced HP (post-i-frame-check, so evaded hits aren't penalized). Zero-dependency rank module, ran for real via `lune`: all six known-combo cases match their expected letter, and all four adjacent-rank boundaries are correct on both sides (exactly-at-threshold vs. one point below). `RankFormula.spec.lua` mirrors this; `RunStatsService.spec.lua` covers the counter plumbing (no live Player needed — it's a single party-wide counter, not player-keyed).

#### [x] T-903 `MapClearRewardService`
**Depends on:** T-710, T-107, T-902
**Description:** Guaranteed reward bundle (XP/currency/gear per map tier) + bonus roll (rare/legendary/cosmetic/battle-pass XP) scaled by rank. Grants the map's **Main Reward** guaranteed on the player's *first* clear of that map (tracked in `profile.MapStats`); repeat clears get the standard bonus roll only, not another guaranteed Main Reward.
**DoD:** Main Reward grant is idempotent per player per map.
**Test cases:** First clear grants Main Reward; second clear of the same map does not re-grant it but still grants the bonus roll; rank affects bonus-roll odds/amount per T-902's output.
**Verified:** `src/server/Battlefield/Services/MapClearRewardService.lua`, backed by three new pure modules: `MapClearLedger.lua` (the idempotency guarantee itself — `mainRewardGranted` only ever transitions false/absent → true, never back), `RankRewardScaling.lua` (rank → amount multiplier *and* bonus-roll count, both scaling up D→S — "scaled by rank" read as both knobs, not just one), and the data table `src/shared/Data/MapClearRewards.lua` (per-map guaranteed bundle + weighted bonus table, weights summing to 1.0, deliberately never rolling the map's own `mainRewardItemId` as a bonus). Along the way, fixed a real Phase 7 bug this task's correctness depends on: `MapClearService` was passing the Final Boss's own `definitionId` (e.g. `"ImagawaYoshimoto"`) to itself as `mapId` — harmless for T-710's own logic (never inspected the value) but would have been silently wrong for T-903, which needs the *real* map id to look up `MapClearRewards`/`MapDefinitions`; both services now resolve it from `BattlefieldBootstrap:GetCurrentMapId()` instead. Every player present at Final Boss defeat gets the guaranteed bundle + a Main-Reward idempotency check + `RankRewardScaling.GetBonusRollCount(rank)` bonus rolls, each amount scaled by `GetAmountMultiplier(rank)`; a `BattlePassXP`-kind bonus roll calls `BattlePassService:AwardSeasonXP` directly. Fires a server-internal `MapCleared` signal that T-904/T-905 both hook for their own "map clears" tracking. Zero-dependency formulas, ran for real via `lune`: `MapClearLedger` — first clear flags a first clear and grants; repeat clears never do, even across 5 repeated calls; `RankRewardScaling` — both multiplier and roll count are monotonically non-decreasing D→S; `MapClearRewards` — weights sum to exactly 1.0. `MapClearLedger.spec.lua`/`RankRewardScaling.spec.lua`/`MapClearRewards.spec.lua` mirror these; `MapClearRewardService.spec.lua` covers the guaranteed-bundle-every-clear + Main-Reward-idempotent-once integration (Studio-only, needs a live Player, S-1301).

#### [x] T-904 `QuestService`
**Depends on:** T-109
**Description:** Tracks quest progress via event hooks (enemy kills by tier, maps cleared); daily/weekly reset via server timestamp check on login.
**DoD:** Reset boundary uses a single documented reset hour/timezone (e.g., reset at 00:00 UTC), applied consistently.
**Test cases:** Injected-clock test: login just before reset boundary doesn't reset; login just after does; weekly cadence resets on the correct day only.
**Verified:** `src/shared/Formulas/QuestResetLedger.lua` — pure, injected-clock (plain Unix-second timestamps), single documented boundary: **00:00 UTC**, computed from raw epoch-seconds arithmetic (never a locale-dependent date library). Caught and fixed a real sign bug while writing this: the weekly-boundary formula initially added the Monday-alignment offset instead of subtracting it, which put the week transition between Saturday and Sunday instead of Sunday and Monday — caught by actually running it via `lune` before trusting it, not just by inspection. `src/server/Shared/Services/QuestService.lua` extended `QuestDefinitions.lua`/`Types.QuestDefinition` with an optional `tier` field (required for `DefeatEnemyTier` quests, absent for `ClearMap`) so progress-matching has real data to key off. Lives in `Shared` (loaded in both places, like `DataService`) since login-reset has to run wherever a session starts, but its two progress hooks (`EnemySpawnService.EnemyDied`/`MidBossController.Defeated` for kills-by-tier, `MapClearRewardService.MapCleared` for map clears) are Battlefield-only — wrapped in a `pcall`-guarded `tryGetService` helper so requiring this module in the Lobby place (where those service names were never registered) doesn't error. Rewards auto-grant the instant `targetCount` is reached, documented as a deliberate no-manual-claim decision consistent with every other reward path in this project. Zero-dependency reset module, ran for real via `lune`: a nil last-reset always counts as crossed (fresh-profile init), daily boundary is exact (one second before midnight UTC doesn't reset, midnight itself does), and the weekly boundary resets only on the correct day (Sunday→Monday, epoch-day 3→4) and nowhere else within the same Mon-Sun week — the exact test that caught the sign bug above. `QuestResetLedger.spec.lua`/`QuestDefinitions.spec.lua` (extended) mirror this; `QuestService.spec.lua` covers login-state initialization and the completion/reward/no-double-grant integration (Studio-only, S-1301).

#### [x] T-905 `BattlePassService`
**Depends on:** T-904, T-110
**Description:** Seasonal XP fed by quest completions + map clears; tier-unlock table; free vs premium track gated by `ProductCatalog` ownership check (T-1002/T-1005).
**DoD:** Premium-track rewards inaccessible without the season's premium flag, even if tier XP threshold is met.
**Test cases:** Free track unlocks at XP thresholds regardless of premium flag; premium track items withheld until premium flag true, then retroactively available at already-passed thresholds.
**Verified:** `src/shared/Formulas/BattlePassLedger.lua` (pure tier-unlock resolution from XP) + `src/shared/Data/BattlePassTiers.lua` (5-tier table, strictly-increasing XP thresholds, distinct free/premium rewards per tier) + `src/server/Shared/Services/BattlePassService.lua`. `premiumOwned` is honestly documented as a **profile-backed stub**, not a real Robux Game Pass check — `GamePassService`/`MonetizationService` (T-1002, Phase 10) don't exist yet; `BattlePassService:GrantPremium(player)` is the forward-compatible seam T-1002 will call once built, the same deferred-consumer pattern already used for T-405/PlayerHealthService back in Phase 4. XP fed from two sources: `QuestService.QuestCompleted` (Shared-to-Shared, no guard needed) and `MapClearRewardService.MapCleared` (Battlefield-only, same `pcall`-guarded `tryGetService` pattern as `QuestService`). A season rollover (`profile...seasonId ~= Constants.BattlePass.CurrentSeasonId`) resets `xp`/`premiumOwned`/both granted-tier sets, so a past season's premium ownership can never carry into the current one (T-1005's requirement, satisfied here since a new season always starts `premiumOwned = false`). `GrantPremium` re-evaluates the player's *current* XP against every tier, not just future ones — the DoD's retroactive-availability requirement — rather than only unlocking prospectively from whatever tier XP they're at next. Zero-dependency formulas, ran for real via `lune`: no tiers unlock below the first threshold, exactly the tiers whose threshold is met unlock (inclusive), and every tier unlocks once XP clears the top threshold; tier numbers are sequential and XP thresholds strictly increasing. `BattlePassLedger.spec.lua`/`BattlePassTiers.spec.lua` mirror this; `BattlePassService.spec.lua` covers free-track-unlocks-regardless-of-premium, premium-withheld-until-granted, and the retroactive-grant-on-`GrantPremium` integration (Studio-only, S-1301).

---

## Phase 10 — Monetization

#### [x] T-1001 `MonetizationService` — `ProcessReceipt`
**Depends on:** T-110, T-204, T-203
**Description:** Handles all Developer Products in `ProductCatalog`. Idempotent via receipt tracking (`PlayerId + ProductId + PurchaseId`) stored in the profile — required by Roblox so a retried receipt never double-grants.
**DoD:** Returns `Enum.ProductPurchaseDecision.PurchaseGranted` only after the grant actually succeeds; on failure returns `NotProcessedYet` so Roblox retries.
**Test cases:** Replaying an already-recorded `PurchaseId` grants nothing a second time but still returns `PurchaseGranted`; a novel receipt grants exactly once and is recorded.
**Verified:** `src/server/Shared/Services/MonetizationService.lua`, backed by the pure `src/shared/Formulas/PurchaseLedger.lua` (T-1001's own idempotency check). Keyed by `PurchaseId` alone within a per-player `profile.Data.Settings.ProcessedPurchases` set rather than a `PlayerId+ProductId+PurchaseId` composite — documented reasoning in the file's header: the profile is already player-scoped, and a `PurchaseId` GUID is already globally unique per transaction, so the extra composite key fields add nothing. The grant itself is `pcall`-wrapped; only a successful grant marks the purchase processed and returns `PurchaseGranted` — a genuine failure returns `NotProcessedYet` so Roblox retries, per the DoD literally. An already-processed `PurchaseId` returns `PurchaseGranted` immediately without re-running the grant. `PromptProductPurchase` (the T-1003 entry point) never touches currency/inventory itself — only `ProcessReceipt` does, and only from Roblox's own server callback. Zero-dependency idempotency ledger, ran for real via `lune`: a novel id isn't processed until marked, marking twice is a safe no-op, and different ids are tracked independently. Every real `ProductCatalog.robloxId` is `nil` until T-1401, so `MonetizationService.spec.lua` uses a test-only `_RegisterSkuForTest` hook (mirrors `EnemyRegistry._ClearAll`) to register a fake id and genuinely exercise the full grant + replay-doesn't-double-grant path today, not just assert on the unreachable-in-sandbox real path (Studio-only for the actual Robux flow, S-1301).

#### [x] T-1002 `GamePassService`
**Depends on:** T-110
**Description:** `UserOwnsGamePassAsync` check (cached, refreshed on `PlayerAdded` + `PromptGamePassPurchaseFinished`), applies passive effects: XP Boost %, Currency Boost %, VIP perks (GDD §9.2).
**DoD:** Boost percentages apply multiplicatively at the point of `AwardXP`/`AddCurrency`, not as a separate untracked bonus.
**Test cases:** `AwardXP` with boost owned yields `base * (1 + boostPct)`; without, yields `base`.
**Verified:** `src/server/Shared/Services/GamePassService.lua` — ownership cached per player per sku (`{[Player]: {[sku]: boolean}}`), refreshed on `PlayerAdded` (all Game Passes at once) and on a `wasPurchased` `PromptGamePassPurchaseFinished`. Fails safe against `ProductCatalog`'s `nil` `robloxId`s (T-1401 pending) — `OwnsGamePass` returns `false` rather than erroring. The DoD's "applied at the point of grant" is real, not just documented: `src/shared/Formulas/BoostMath.lua` (pure `ApplyBoost`, round-half-up) is called directly inside `LevelService:AwardXP` and `CurrencyService:AddCurrency` — both edited this phase to run their `amount` through `GamePassService:GetXPBoostPercent`/`GetCurrencyBoostPercent` before the ledger ever sees it, so there's only ever one grant call, never a separate bonus applied after the fact. Currency Boost applies to `SoftCurrency` gains only (GDD §9.2's literal wording), never `PremiumCurrency`, never `RemoveCurrency`. VIP's daily currency bonus reuses T-904's `QuestResetLedger.HasCrossedDailyBoundary` for the same documented reset boundary every other daily grant in this project uses; its cosmetic trail grant is tracked as a flag only (`profile.Data.Settings.VIPTrailId`) since no trail-rendering system exists to consume it, and "priority queue/party perks" is documented as genuinely unbuilt (no queue/priority system exists anywhere in this project to hook) rather than invented. Zero-dependency boost math, ran for real via `lune`: 0% boost is a no-op, a positive boost applies multiplicatively, and rounding is correctly round-half-up. `BoostMath.spec.lua` mirrors this; `GamePassService.spec.lua` covers the full `AwardXP`/`AddCurrency` boosted-vs-unboosted integration (plus confirming the boost never touches `PremiumCurrency`) via a test-only `_SetOwnershipForTest` hook, since real ownership can't return true without a `robloxId` (Studio-only for the real Robux-driven refresh path, S-1301).

#### [x] T-1003 Premium-currency purchase path
**Depends on:** T-601, T-1001
**Description:** `ShopService` premium-currency SKUs route to `MonetizationService:PromptProductPurchase`.
**DoD:** Purchase confirmation only reflects in `CurrencyService` after `ProcessReceipt` confirms — no client-optimistic currency credit.
**Test cases:** Manual/visual (Robux purchase flow requires a live/Studio-test environment) — covered in S-1301.
**Verified:** `ShopService:PurchaseProduct(player, sku)` (new, alongside the existing `PurchaseItem`) — a deliberately separate path from `PurchaseItem`'s balance-deduction flow for catalog gear, since `ProductCatalog` SKUs (Gems bundles, cosmetic bundles, loadout preset slots) are real-money purchases, not SoftCurrency-priced items. Rejects unknown/non-`DevProduct` skus up front; otherwise calls `MonetizationService:PromptProductPurchase` only — never `CurrencyService`, satisfying the DoD by construction (there is no code path in `PurchaseProduct` that could credit currency; the grant exists exclusively inside `ProcessReceipt`, T-1001, invoked only by Roblox's own server callback after a genuinely completed transaction). `ShopService.spec.lua` extended: rejects an unknown sku and a GamePass-type sku (not a `DevProduct`); accepts a real `DevProduct` sku and confirms no currency was credited by the call itself. The actual Robux purchase-dialog flow needs a live/Studio-test environment per the task's own guidance (S-1301).

#### [x] T-1004 Cosmetic-only monetization guardrail (automated)
**Depends on:** T-110
**Description:** Codifies GDD §9.5 as a test, not just policy: every `ItemDefinitions`/`WeaponDefinitions`/`UltimateDefinitions` entry that is premium-currency-exclusive (not obtainable via `SoftCurrency` or free play) must have `cosmeticOnly = true`.
**DoD:** This test is wired into the same suite run in T-1301, so it fails the build if a future item accidentally ships stat-affecting and premium-exclusive.
**Test cases:** Iterate every catalog entry; assert `not (premiumExclusive and statBonus ~= 0) or cosmeticOnly == true`. **This is the most important test in the backlog — flag it in code review.**
**Verified:** `src/shared/Data/MonetizationGuardrail.spec.lua` — a standalone TestEZ spec (not a separate Formula module; there's no runtime logic to package, just a cross-catalog assertion, the same pattern already used for `MapDefinitions.spec.lua`'s cross-references). Implements the literal DoD formula for `ItemDefinitions` (the only catalog with real `cosmeticOnly`/`statBonus` fields). `WeaponDefinitions`/`UltimateDefinitions` have neither field — every entry in those two catalogs *is* inherently stat-affecting by nature (a weapon's `baseDamage` isn't a bonus on a cosmetic baseline, it's the whole item), so no cosmetic-only weapon/ultimate can exist; the guardrail's principle is applied to them in its only possible form — asserting neither catalog ever prices an entry in `PremiumCurrency` at all, consistent with GDD §9.1 only listing weapon/ultimate "unlock skips" (a separate grind-skip SKU, not the catalog price itself) for Robux. This is flagged in the task text as the most important test in the backlog, so it wasn't just written and trusted: ran the exact assertion logic for real via `lune` against the actual current catalog data (0 violations across 12 items/6 weapons/3 ultimates) — genuinely proving today's catalogs pass, not just that the test parses — and separately ran a negative-case sanity check with a deliberately-bad synthetic entry (premium-priced, stat-affecting, not `cosmeticOnly`) to confirm the guardrail logic actually flags a real violation and isn't vacuously true. Wired into the same suite T-1301 runs (it's a plain `.spec.lua` alongside every other spec in this tree).

#### [x] T-1005 Battle Pass premium unlock
**Depends on:** T-905, T-1002
**Description:** Game-Pass-based, one per season, seasonal id in `ProductCatalog`.
**DoD:** Owning a past season's pass doesn't unlock the current season (seasonal ids are distinct products).
**Test cases:** Ownership check scoped to current season's product id only.
**Verified:** `BattlePassService` (T-905) extended with `CheckPremiumOwnership`, wired to `GamePassService:OwnsGamePass` (T-1002) — the seam `GrantPremium` already exposed in Phase 9 now has a real caller instead of sitting unconsumed. The sku checked is always computed as `"BattlePassPremium_" .. Constants.BattlePass.CurrentSeasonId` — never a bare `"BattlePassPremium"` or any hardcoded past season's id — so owning a different season's Game Pass structurally cannot match. Checked on login (same profile-ready polling pattern as `QuestService`/`GamePassService`) and on a `wasPurchased` `PromptGamePassPurchaseFinished` for immediate unlock right after a real purchase. Two independent guarantees of the DoD, not one: the sku-scoping above, plus Phase 9's existing season-rollover reset (`profile...seasonId ~= CurrentSeasonId` zeroes `premiumOwned`) means even a stale `premiumOwned = true` surviving in old profile shape from a past season can't carry forward either way. `BattlePassService.spec.lua` extended: owning a fabricated "different season" sku (via `GamePassService`'s test-only `_SetOwnershipForTest` hook) leaves `premiumOwned` false; owning the actual current-season sku string grants it — a genuine test of the scoping logic even with only one real season defined in `ProductCatalog` today.

#### [x] T-1006 Loadout preset slot purchase
**Depends on:** T-503, T-1001
**Description:** Dev-product purchase increments `profile.LoadoutPresets` cap.
**DoD:** Cap increment applied exactly once per purchase (protected by the same idempotent-receipt mechanism as T-1001).
**Test cases:** Repeated receipt for the same purchase doesn't stack the cap increment twice.
**Verified:** Not a separate service — folded entirely into `MonetizationService:ProcessReceipt`'s generic `grants` dispatch (a `grants.loadoutPresetSlots` branch incrementing `profile.Data.Settings.PurchasedLoadoutPresetSlots`, the exact field `LoadoutService:GetPresetCap` already read since Phase 5), literally "protected by the same idempotent-receipt mechanism as T-1001" per the DoD, since it's the same `ProcessReceipt` call, same `PurchaseLedger` guard, not a parallel mechanism that could drift from it. `MonetizationService.spec.lua` covers it directly: a `LoadoutPresetSlot` receipt (via the same `_RegisterSkuForTest` hook as T-1001) increments `LoadoutService:GetPresetCap` by exactly 1, and replaying the identical receipt doesn't stack a second increment.

---

## Phase 11 — Cross-platform & Responsive UI

#### [ ] T-1101 `PlatformDetectionController`
**Depends on:** T-002
**Description:** Detects Desktop/Console/Mobile/Tablet via `UserInputService:GetLastInputType` + `GuiService:IsTenFootInterface`, exposes a reactive signal.
**DoD:** Switching input mid-session (e.g., plugging in a gamepad) updates the signal live.
**Test cases:** Unit test against a mocked `UserInputService` event stream — sequence of input-type-changed events produces the expected detected-platform sequence.

#### [ ] T-1102 Input remap: gamepad + touch
**Depends on:** T-401, T-1101
**Description:** Extends `InputController` per GDD §6.4's cross-platform mapping table: gamepad face buttons + triggers + right-stick click; touch on-screen buttons + auto-assist lock-on.
**DoD:** All six core actions (Light/Heavy/Special/Dash/Ultimate/Lock-on) reachable on every supported input type.
**Test cases:** Coverage check — for each platform, assert all six intent events have a bound input source.

#### [ ] T-1103 Responsive UI framework
**Depends on:** T-002
**Description:** Base scaling (UIScale/AspectRatioConstraint) + breakpoint system, applied to HUD, Shop, Loadout, MapSelect, Party UI.
**DoD:** No UI element clips or overflows at the smallest supported phone aspect ratio or the largest ultrawide desktop ratio (tested set of reference resolutions).
**Test cases:** Pure breakpoint-selection function unit-tested (given screen size → expected scale/layout mode); visual check across reference resolutions is manual (S-1301).

#### [ ] T-1104 `TouchControlsUIController`
**Depends on:** T-1101, T-1102
**Description:** On-screen virtual buttons, visible/active only when detected platform is Mobile/Tablet.
**DoD:** Buttons absent (not just invisible — removed from layout) on Desktop/Console so they never intercept input there.
**Test cases:** Manual/visual.

#### [ ] T-1105 Combat input/timing parity audit
**Depends on:** T-402, T-404, T-1102
**Description:** Confirms combo/hitbox resolution is 100% server-side and input-method-agnostic — client only ever sends an intent (`"Light"`/`"Heavy"`/etc.), never raw timing or damage numbers.
**DoD:** Code-review checklist item, not a script: grep every `RemoteEvent`/`RemoteFunction` touching combat and confirm none accepts a client-supplied damage/timing value.
**Test cases:** N/A — audit checklist, recorded as passed/failed in this task's checkbox.

---

## Phase 12 — Social/Guild (stretch, post-launch)

#### [ ] T-1201 `GuildService` skeleton *(optional, not required for v1)*
**Depends on:** T-201
**Description:** Create/join/leave clan, clan tag on profile, shared clan chat via `TextChatService`, clan leaderboard (aggregate stat) — GDD §11.
**DoD:** Explicitly out of the v1 critical path; only pick up after Phases 0–11 + 13 are complete.
**Test cases:** Deferred until scoped.

---

## Phase 13 — QA / Anti-Exploit / Polish

#### [ ] T-1301 Full suite + lint pass
**Depends on:** everything above
**Description:** Run the complete TestEZ suite and `selene src` across the whole tree.
**DoD:** Zero failing tests, zero lint issues.
**Test cases:** N/A — this task *is* the test run.

#### [ ] T-1302 Server-authority exploit audit
**Depends on:** T-404, T-1001, T-1004, T-1105
**Description:** Grep every client-facing `RemoteEvent`/`RemoteFunction` and confirm none mutates currency, items, damage, or profile state without server-side validation.
**DoD:** Written audit note per remote (pass/fail), zero fails.
**Test cases:** N/A — audit checklist.

#### [ ] T-1303 Playtest pass
**Depends on:** T-701–T-710
**Description:** Solo clear of ≥1 full map end-to-end; 2–8 player co-op clear.
**DoD:** No desync, no duplicate/missing rewards, no soft-locks (e.g., gate never opening).
**Test cases:** Manual, logged as a checklist with pass/fail per scenario.

#### [ ] T-1304 Performance pass
**Depends on:** T-702, T-711
**Description:** Stress test at max party (8) + full wave density; verify frame budget on the lowest supported mobile device tier.
**DoD:** Documented minimum-spec device holds an acceptable frame rate (define the target, e.g. 30fps, in this task's notes) under worst-case enemy count.
**Test cases:** Manual, logged with device/FPS numbers.

---

## Phase 14 — Release Prep (script side)

#### [ ] T-1401 Fill in real `ProductCatalog.robloxId` values
**Depends on:** T-110, S-1001, S-1002
**Description:** After S-1001/S-1002 create the real Developer Products/Game Passes in the Creator Dashboard, copy their ids into `ProductCatalog.lua`.
**DoD:** No `nil` `robloxId` remains in the catalog.
**Test cases:** Assert no entry has `robloxId == nil`.

#### [ ] T-1402 Fill in real `PlaceIds`
**Depends on:** T-003, S-001
**Description:** After S-001 creates the Lobby and Battlefield places, copy their PlaceIds into `Constants.lua`'s `PlaceIds` table (used by T-606's `TeleportToPrivateServer` call and T-106's `battlefieldPlaceId`).
**DoD:** No `nil` PlaceId remains.
**Test cases:** Assert both PlaceIds are non-nil, non-zero numbers.

---

## Phase index

| Phase | Scope |
|---|---|
| 0 | Toolchain, Knit bootstrap, multi-place project files |
| 1 | Shared data definitions (items, weapons, enemies, maps, loot, quests, products) |
| 2 | Player profile, currency, inventory |
| 3 | Stats, leveling, map-level gating |
| 4 | Combat: input, combo, hitboxes, dash, special, ultimate, poise, targeting, anti-exploit |
| 5 | Customization & loadout (incl. run-lock rule) |
| 6 | Safe Lobby: shop, loadout UI, map select, party, portal teleport |
| 7 | Battlefield core + full enemy hierarchy (Foot Soldier variants → Commander → Mid-Boss → Final Boss) |
| 9 | Rewards, rank grading, quests, battle pass |
| 10 | Monetization (dev products, game passes, guardrail test) |
| 11 | Cross-platform input + responsive UI |
| 12 | Guild/clan (stretch, deferred) |
| 13 | QA, exploit audit, playtest, performance |
| 14 | Release-prep id wiring |
