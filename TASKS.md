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

#### [ ] T-001 Verify toolchain end-to-end
**Depends on:** none
**Description:** Confirm `rojo build`, `wally install`, `selene .`, and the TestEZ runner all work against the current empty scaffold before any feature code lands.
**DoD:** `rojo build default.project.json -o build/place.rbxl` succeeds; `wally install` pulls all `wally.toml` deps into `Packages/`/`ServerPackages/`; `selene src` returns 0 issues on an empty tree; a placeholder TestEZ spec runs green via whatever runner is chosen (Studio plugin, `run-in-roblox`, or CI action — document the choice in this task's checkbox comment).
**Test cases:** N/A (tooling check).

#### [ ] T-002 Knit bootstrap
**Depends on:** T-001
**Description:** `src/server/init.server.lua` starts Knit and requires every module under `src/server/Services/*`; `src/client/init.client.lua` starts Knit and requires every module under `src/client/Controllers/*`.
**DoD:** Adding a new `Services/Foo.lua` / `Controllers/Foo.lua` file is auto-picked up with no edits to the init scripts (glob-require via `script:GetChildren()`/`require` loop, not a hardcoded list).
**Test cases:** N/A.

#### [ ] T-003 `src/shared/Constants.lua`
**Depends on:** T-001
**Description:** Central table of CollectionService tag names, attribute keys (per naming-contract table above), RemoteFolder name, Currency enum (`SoftCurrency`/`PremiumCurrency`), and a `PlaceIds` table (stub `nil` values, filled by T-1402 after S-001).
**DoD:** Every other module that needs a tag/attribute/currency-id string pulls it from here — zero magic strings duplicated elsewhere (spot-check via grep in T-1301).
**Test cases:** Schema test — every key referenced by name in this doc's naming-contract table exists in the module.

#### [ ] T-004 `src/shared/Types.lua`
**Depends on:** T-001
**Description:** `t`-library type checkers for `Profile`, `Item`, `EnemyDefinition`, `MapDefinition`, `QuestDefinition`, `Loadout`. Stub now, extended as Phase 1 fills in real schemas.
**DoD:** Each checker is a pure function `t.strict(shape)` importable from shared and server.
**Test cases:** For each checker, one passing fixture and one failing fixture (missing field / wrong type) asserted via TestEZ.

#### [ ] T-006 Multi-place Rojo project files
**Depends on:** T-001, architecture decision above
**Description:** Split `default.project.json` into `lobby.project.json` (Safe Lobby place tree) and `battlefield.project.json` (Battlefield place tree), sharing `src/shared` but with place-specific server bootstrap entrypoints (Lobby never loads EnemySpawnService et al.; Battlefield never loads ShopService/PortalService et al.).
**DoD:** Both project files build independently with `rojo build`; Lobby build contains no enemy/combat-instance code paths, Battlefield build contains no shop/social code paths (verified by a simple `grep` of the built script tree, or by service registration lists being disjoint).
**Test cases:** N/A (build-config check), but add a smoke test asserting `LobbyServices` and `BattlefieldServices` module lists (whatever you name them) have empty intersection.

---

## Phase 1 — Shared Data Definitions

#### [ ] T-101 `ItemDefinitions.lua` (accessories)
**Depends on:** T-004
**Description:** Catalog table for Head/Body/Arm/Leg accessories: `id`, `slot`, `rarity`, `statBonus`, `cosmeticOnly`, `price` (currency+amount), `meshAssetId` (placeholder until S-103).
**DoD:** Every entry validates against `Types.Item`.
**Test cases:** Validate full catalog array against `Types.Item` (T-004); assert no duplicate `id`s; assert every `slot` is one of `Head|Body|Arm|Leg`.

#### [ ] T-102 `WeaponDefinitions.lua`
**Depends on:** T-004
**Description:** `id`, `name`, `comboTreeId` (→ T-104), `baseDamage`, `rarity`, `animationIds` placeholder (filled by S-102), `price`.
**DoD:** Validates against `Types`; every `comboTreeId` referenced exists once T-104 lands (cross-check test added there).
**Test cases:** No duplicate ids; all required fields present.

#### [ ] T-103 `UltimateDefinitions.lua`
**Depends on:** T-004
**Description:** `id`, `name`, `damage`, `radiusOrShape`, `vfxAssetId` placeholder (S-104), `price`.
**DoD:** Validates against `Types`.
**Test cases:** No duplicate ids.

#### [ ] T-104 `ComboTrees.lua`
**Depends on:** T-102
**Description:** Per weapon, a node graph: each node has `{light=nextNodeId|nil, heavy=nextNodeId|nil, damageMult, poiseDamage, hitboxShape, isFinisher}`. Root node is the neutral/idle state. Must produce the branching described in GDD §6.4 (L-L-L vs L-L-H vs L-H yield different finishers).
**DoD:** Every `WeaponDefinitions.comboTreeId` has a matching tree; every tree has exactly one root; every `light`/`heavy` reference points at a node that exists in the same tree.
**Test cases:**
- Structural: no dangling node references, no orphaned nodes (unreachable from root), every tree has ≥1 `isFinisher` node.
- Branching: for a sample weapon, assert `L,L,L` → finisher A, `L,L,H` → finisher B, `L,H` → finisher C are three distinct node ids.

#### [ ] T-105 `EnemyDefinitions.lua`
**Depends on:** T-004
**Description:** One entry per Foot Soldier variant (Swordsman, Spearman, Shield Bearer, Rock/Javelin Thrower, Bomber, Swinger/Berserker, Treasure Carrier — GDD §7.1), plus Commander, and per-map Mid-Boss/Final Boss entries. Fields: `id`, `tier` (`FootSoldier|Commander|MidBoss|FinalBoss`), `hp`, `damage`, `poiseMax` (0 for Foot Soldiers), `behaviorModule` (string name resolved to `src/server/Services/EnemyBehaviors/<name>.lua`), `lootTableId`, `modelAssetId` placeholder (S-707/S-708).
**DoD:** Validates against `Types.EnemyDefinition`; every `behaviorModule` string has a matching file once Phase 7 lands (cross-check test added there).
**Test cases:** No duplicate ids; `poiseMax == 0` iff `tier == "FootSoldier"`; every `tier` is one of the four valid values.

#### [ ] T-106 `MapDefinitions.lua`
**Depends on:** T-004, T-105
**Description:** `id`, `displayName`, `recommendedLevel`, `mainRewardItemId` (→ T-101/102/103 catalog), `waveConfig` (`{spawnGroupId, enemyId, count, delaySeconds}[]`), `objectiveList`, `midBossIds`, `finalBossId`, `battlefieldPlaceId` placeholder (T-1402).
**DoD:** Every `waveConfig.enemyId` and `midBossIds`/`finalBossId` exists in `EnemyDefinitions`; every `mainRewardItemId` exists in some item catalog.
**Test cases:** Cross-reference integrity checks listed in DoD, run as TestEZ assertions over the full table.

#### [ ] T-107 `RewardTables.lua`
**Depends on:** T-004, T-101/102/103
**Description:** Weighted loot tables per source (`FootSoldier`, `Commander`, `MidBoss`, `FinalBoss`, `DestructibleBox`): currency ranges + rarity roll weights, referencing real item ids.
**DoD:** All weights sum to 1 (or a documented total) per table; all referenced item ids exist.
**Test cases:** Weight-sum assertion per table; statistical roll test (10k samples) lands within tolerance of expected distribution.

#### [ ] T-108 `XPCurve.lua`
**Depends on:** T-004
**Description:** Pure functions `XPForLevel(level): number` and `LevelForXP(xp): number`, diminishing-return curve (GDD §3.1).
**DoD:** Monotonically increasing; round-trip stable.
**Test cases:** `LevelForXP(XPForLevel(n)) == n` for a range of `n`; `XPForLevel` strictly increasing; `LevelForXP(0) == 1`.

#### [ ] T-109 `QuestDefinitions.lua`
**Depends on:** T-004
**Description:** Daily/weekly templates: `id`, `cadence` (`Daily|Weekly`), `goalType` (`DefeatEnemyTier|ClearMap|...`), `targetCount`, `rewards`.
**DoD:** Validates against `Types`.
**Test cases:** No duplicate ids; `cadence` is one of two valid values.

#### [ ] T-110 `ProductCatalog.lua`
**Depends on:** T-004
**Description:** Internal SKU keys → `{type = "DevProduct"|"GamePass", robloxId = nil, grants = {...}, cosmeticOnly = boolean}`. `robloxId` filled in by T-1401 once S-1001/S-1002 create the real products.
**DoD:** Every entry has `cosmeticOnly` explicitly set (no implicit default) — this field is load-bearing for T-1004's guardrail test.
**Test cases:** Every entry has `cosmeticOnly` as an explicit boolean (not nil).

---

## Phase 2 — Player Data & Currency

#### [ ] T-201 `DataService` (ProfileService integration)
**Depends on:** T-004, T-101–T-110 (template references catalog defaults)
**Description:** Wraps ProfileService. `ProfileTemplate` = `{version, Level, XP, SoftCurrency, PremiumCurrency, OwnedItems, Loadout, LoadoutPresets, QuestProgress, BattlePassProgress, MapStats, Settings}`. Handles `PlayerAdded`/`PlayerRemoving`, session-locking, release-on-leave.
**DoD:** New player gets a profile matching `Types.Profile`; profile survives a server restart in Studio (manual verification, see S-1301); session-lock prevents double-load across servers.
**Test cases:** Template shape matches `Types.Profile`; default values correct (Level 1, 0 XP/currency, empty inventory, default loadout).

#### [ ] T-202 `DataService.Client:GetProfile()`
**Depends on:** T-201
**Description:** Returns a client-safe snapshot (no server-internal fields like session-lock metadata).
**DoD:** Snapshot excludes any field not needed client-side.
**Test cases:** Snapshot never contains `_sessionLock`/version-migration internals (assert key list is a subset of an allowlist).

#### [ ] T-203 `CurrencyService`
**Depends on:** T-201
**Description:** `AddCurrency(player, type, amount, reason)`, `RemoveCurrency(player, type, amount)` with insufficient-funds guard, `Signal CurrencyChanged(player, type, newAmount)`.
**DoD:** Currency never goes negative; every mutation logged with `reason` for audit.
**Test cases:** `RemoveCurrency` beyond balance rejected, balance unchanged; `AddCurrency` then `RemoveCurrency` nets correctly; signal fires exactly once per mutation.

#### [ ] T-204 `InventoryService`
**Depends on:** T-201
**Description:** `GrantItem(player, itemId)`, `HasItem(player, itemId)`, `Signal ItemGranted`.
**DoD:** Non-stackable items can't be double-granted (idempotent).
**Test cases:** Second `GrantItem` call for an already-owned non-stackable item is a no-op and returns `false`; `HasItem` reflects grants immediately.

#### [ ] T-205 Profile versioning/migration stub
**Depends on:** T-201
**Description:** `version` field on the template + a `Migrations[version] = function(profile) ... end` table applied on load for future schema changes.
**DoD:** Loading a `version = 0` fixture profile through the migration chain produces a current-shape profile.
**Test cases:** Fixture-based migration test (old shape in → current shape out).

---

## Phase 3 — Stats & Leveling

#### [ ] T-301 `shared/StatMath.lua` + `StatsService`
**Depends on:** T-101, T-201
**Description:** Pure function `ComputeStats(level, equippedItemIds): Stats` (HP, Attack, Defense, Stamina, UltimateChargeRate) = base-by-level formula + sum of equipped item `statBonus`. `StatsService` wires it to a player's current profile and recomputes on level-up/loadout-change.
**DoD:** Pure calc lives in `shared/StatMath.lua`, importable and testable with no Roblox API calls.
**Test cases:** Known input → known output table (level X + item set Y → expected Stats); recompute triggered on `LoadoutChanged` and `LevelUp` signals (integration test/manual).

#### [ ] T-302 `LevelService`
**Depends on:** T-108, T-203, T-301
**Description:** `AwardXP(player, amount, source)` updates profile XP via `XPCurve`, fires `Signal LevelUp(player, newLevel)` on threshold crossing, triggers `StatsService` recompute.
**DoD:** Level-up fires exactly once per threshold crossing, even for a single large XP award that crosses multiple levels (fires once per level gained, not once total).
**Test cases:** XP exactly at threshold triggers level-up once, not twice; a jump spanning 3 levels fires `LevelUp` 3 times with correct intermediate levels.

#### [ ] T-303 Map-level gating
**Depends on:** T-106, T-302
**Description:** Pure function `IsMapUnlocked(playerLevel, map): boolean` — allow entry down to `recommendedLevel - tolerance` (tolerance constant, e.g. 3).
**DoD:** Documented tolerance constant lives in Constants.lua.
**Test cases:** Boundary tests at `recommendedLevel`, `recommendedLevel - tolerance`, and `recommendedLevel - tolerance - 1`.

---

## Phase 4 — Combat System

#### [ ] T-401 `InputController` (client, desktop baseline)
**Depends on:** T-002
**Description:** Maps M1/M2/Q/Shift/R/Tab to ability-intent events per GDD §6.4 table. Debounced; no server calls here, just intent → local event bus (gamepad/touch remapping added in Phase 11 on top of this).
**DoD:** Each of the six inputs fires exactly one intent event per press, no double-fire on key-repeat.
**Test cases:** Manual/visual (input simulation is awkward to unit-test in Roblox; cover via debounce logic extracted to a pure function and unit-test *that*).

#### [ ] T-402 `CombatService.Client:RequestAttack(attackType)`
**Depends on:** T-401, T-201
**Description:** Server validates: player alive, weapon equipped (T-501), not `Staggered`, respects a per-player combat state machine (`Idle|Attacking|Dashing|Staggered`).
**DoD:** Invalid-state requests are rejected server-side with no visible effect (no animation/damage).
**Test cases:** Request while `Staggered` rejected; request while `Idle` accepted and transitions state to `Attacking`.

#### [ ] T-403 `shared/ComboResolver.lua`
**Depends on:** T-104
**Description:** Pure function `Resolve(currentNodeId, comboTreeId, input: "Light"|"Heavy"): nextNodeId`. Server calls this on every attack input to determine the next combo node (and thus damage/hitbox).
**DoD:** No side effects, fully deterministic.
**Test cases:** Full branching coverage per T-104's sample weapon (`L,L,L` / `L,L,H` / `L,H` → three distinct finisher ids); invalid input at a node with no matching branch resets to root.

#### [ ] T-404 `HitboxService`
**Depends on:** T-403
**Description:** Spawns/attaches a hitbox per the resolved combo node's `hitboxShape`, resolves overlaps against the server's enemy registry (T-701), applies damage. **Server-authoritative only** — client never computes or reports damage.
**DoD:** No client RemoteEvent path exists that lets a client assert "I dealt N damage"; all damage numbers originate server-side.
**Test cases:** Given a mocked set of enemy positions and a hitbox shape, correct subset of enemies takes damage; enemies outside the shape are unaffected.

#### [ ] T-405 `DashService`
**Depends on:** T-402
**Description:** Server validates dash request, grants an i-frame window (flag on combat state), moves the character, cancels current attack recovery.
**DoD:** Damage taken during the i-frame window is voided (checked by whichever service applies enemy damage to the player).
**Test cases:** Damage event during active i-frame flag is discarded; damage event just after flag expires is applied normally.

#### [ ] T-406 `SpecialAttackService`
**Depends on:** T-402, T-104
**Description:** Per-weapon special move, server-tracked cooldown (`tick()`-based per player), flags bonus poise damage for `PoiseService`.
**DoD:** Cooldown enforced server-side regardless of client-side UI cooldown display.
**Test cases:** Request before cooldown elapses rejected; request after elapses accepted.

#### [ ] T-407 `UltimateGaugeService`
**Depends on:** T-402
**Description:** Tracks 0–100 gauge per player, gains on dealing/taking damage (rate constants in Constants.lua). `RequestUltimate()` only succeeds at 100, consumes to 0, applies AoE damage, `Signal UltimateUsed` for nearby-client VFX.
**DoD:** Request below 100 rejected; successful use resets to exactly 0.
**Test cases:** Gauge accumulation from mocked damage events sums correctly and clamps at 100; `RequestUltimate` at 99 rejected, at 100 accepted and resets to 0.

#### [ ] T-408 `PoiseService`
**Depends on:** T-105, T-403
**Description:** Tracks poise HP per enemy instance (Commander+ only — `poiseMax == 0` means immune/not-applicable, per T-105). Applies `poiseDamage` from hits/specials; on break, sets a `BreakWindow` flag (bonus-damage multiplier, enemy attacks disabled) for a configured duration, then auto-regenerates poise.
**DoD:** Foot Soldiers never enter a break state (they just die through combos, per GDD §6.4).
**Test cases:** Poise damage sums correctly across hits; break triggers exactly once at the threshold crossing (not re-triggered by further damage during the window); poise regenerates after window expiry if not re-broken; a `poiseMax == 0` enemy never produces a break event.

#### [ ] T-409 `shared/TargetSelect.lua` + `TargetLockController`
**Depends on:** T-105
**Description:** Pure function `SelectTarget(playerPosition, enemies, previousTargetId): targetId` — nearest-enemy by default, named-enemy (Mid-Boss/Final Boss) priority override. Client controller drives camera/UI only; no server authority needed here.
**DoD:** Deterministic given the same inputs.
**Test cases:** Nearest-enemy selection correctness; named-enemy override wins over a closer Foot Soldier; stable selection when distances tie (no flicker — deterministic tiebreak rule).

#### [ ] T-410 Combat rate-limiting / anti-exploit
**Depends on:** T-402, T-406, T-407
**Description:** Server rejects and logs impossible state transitions (e.g., attack while `Staggered`) and rate-limits `RequestAttack`/`RequestUltimate` per player (max N per second).
**DoD:** A scripted burst above the cap is rejected past the Nth call within the window; legitimate play (below cap) unaffected.
**Test cases:** Burst-under-cap allowed; burst-over-cap rejected past threshold; state-transition table exhaustively tested (every `(currentState, action)` pair has a defined allow/reject outcome — no undefined transitions).

---

## Phase 5 — Customization & Loadout

#### [ ] T-501 `LoadoutService`
**Depends on:** T-101–T-103, T-204
**Description:** `GetLoadout`, `SetLoadout(loadoutTable)` — validates ownership (`InventoryService.HasItem`) for every slot before accepting, persists, `Signal LoadoutChanged`.
**DoD:** Rejects any loadout referencing an unowned item id, whole-loadout (no partial apply).
**Test cases:** `SetLoadout` with one unowned accessory id rejected in full (no partial mutation of the other 4 valid slots); fully-owned loadout accepted and persisted.

#### [ ] T-502 Loadout lock during battlefield runs
**Depends on:** T-501
**Description:** Enforces GDD §4.2: weapon/ultimate/accessories fixed for the run. `SetLoadout` rejected server-side while the player's combat-state flag says `InBattlefield` (set by PortalService T-606 on teleport-in, cleared on return to Lobby).
**DoD:** No client-side-only enforcement — server rejects regardless of UI state.
**Test cases:** `SetLoadout` while `InBattlefield = true` rejected; same call while `false` accepted.

#### [ ] T-503 Loadout presets
**Depends on:** T-501, T-110
**Description:** `LoadoutPresets` array on profile (1 free slot default, +N via `ProductCatalog` purchase — T-1006). `SavePreset`/`LoadPreset`.
**DoD:** Preset count capped at the player's purchased limit.
**Test cases:** Save beyond current cap rejected; save within cap accepted; load applies via the same validated path as T-501 (re-validates ownership, in case an item was since sold/removed).

#### [ ] T-504 `CharacterAppearanceService`
**Depends on:** T-501
**Description:** On loadout change (Lobby only) or character spawn, welds Accessory (Head/Body/Arm/Leg) and Weapon models onto the character via Motor6D/Attachment, reading `meshAssetId`/`animationIds` from the catalogs.
**DoD:** Visuals match equipped loadout on every spawn, including respawn after death mid-run (re-applies the run-locked loadout, not whatever's currently in the profile if it somehow diverged).
**Test cases:** Manual/visual (rigging/welding is not meaningfully unit-testable) — verified in S-1301.

#### [ ] T-505 Stat recompute on loadout change
**Depends on:** T-504, T-301
**Description:** Hook `LoadoutChanged` → `StatsService.ComputeStats` recompute.
**DoD:** Equipping a higher-rarity accessory immediately reflects in the player's live stats.
**Test cases:** Integration test — `SetLoadout` with a known stat-bonus item set produces the expected `StatMath.ComputeStats` output.

---

## Phase 6 — Safe Lobby Systems

#### [ ] T-601 `ShopService`
**Depends on:** T-101–T-103, T-203, T-204
**Description:** `PurchaseItem(itemId)` — looks up price (soft or premium currency), `CurrencyService.RemoveCurrency`, on success `InventoryService.GrantItem`.
**DoD:** No partial-purchase state possible — currency deducted iff item granted.
**Test cases:** Insufficient funds → purchase fails, currency unchanged, item not granted; sufficient funds → exact price deducted, item granted exactly once.

#### [ ] T-602 `ShopUIController` + `LoadoutUIController`
**Depends on:** T-601, T-501, T-1103 (responsive scaling)
**Description:** Client UI wired to Shop/Loadout/Inventory remotes.
**DoD:** UI reflects server state after every remote round-trip (no client-optimistic desync left uncorrected).
**Test cases:** Manual/visual.

#### [ ] T-603 `MapSelectController` (CTR-style)
**Depends on:** T-106
**Description:** Tile list from `MapService:GetMapDefinitions()`; selecting a tile shows a preview panel with recommended level, party-up option, and the map's **Main Reward** (GDD §5).
**DoD:** Preview panel's Main Reward icon/name matches `MapDefinitions.mainRewardItemId` exactly (data-driven, not hardcoded per map in the UI script).
**Test cases:** Manual/visual + a data-binding unit test (given a mock `MapDefinitions` entry, the view-model function produces the expected preview fields).

#### [ ] T-604 `PartyService`
**Depends on:** T-201
**Description:** `CreateParty`/`InviteToParty`/`AcceptInvite`/`LeaveParty`/`KickMember` (leader-only), 8-player cap (GDD decision), `Signal PartyUpdated`.
**DoD:** Cap enforced server-side; only the leader can kick.
**Test cases:** 9th invite to a full party rejected; non-leader `KickMember` call rejected; leader `KickMember` succeeds and fires `PartyUpdated`.

#### [ ] T-605 `PartyUIController`
**Depends on:** T-604
**Description:** Member list, ready-toggle, invite flow, "waiting for players" vs "launch now" choice at the portal (manual-teleport decision, GDD §6.1).
**DoD:** UI never auto-triggers teleport — always requires an explicit player action.
**Test cases:** Manual/visual.

#### [ ] T-606 `PortalService`
**Depends on:** T-303, T-502, T-604, S-604/S-605 (physical portal parts)
**Description:** `CollectionService`-tagged `MapPortal` parts (Attribute `MapId`) trigger via `ProximityPrompt`. `RequestTeleport(mapId)` validates: requester is party leader (or solo), level gate (T-303), then reserves a private server for the Battlefield place and `TeleportToPrivateServer`s the whole party with `TeleportData = {mapId = ...}`. Sets `InBattlefield = true` on all teleported players' combat state (feeds T-502).
**DoD:** Debounced — one portal trigger produces exactly one reserve-server call, not one per party member.
**Test cases:** Non-leader `RequestTeleport` call rejected (unless solo); under-level party blocked or warned per T-303 tolerance; rapid double-trigger of the same portal produces only one `ReserveServer` call.

#### [ ] T-607 Progression board UI
**Depends on:** T-202, T-203, T-905
**Description:** Level, XP bar, currency balances, battle pass progress — live-updates on the relevant Signals.
**DoD:** No polling — purely signal-driven.
**Test cases:** Manual/visual.

#### [ ] T-608 Lobby combat lockout
**Depends on:** T-006
**Description:** Confirm (in code, not just by omission) that no `EnemySpawnService`/`CombatService` damage-application path is registered in the Lobby place bootstrap.
**DoD:** Lobby place's service registration list contains zero combat/enemy services.
**Test cases:** Assert Lobby bootstrap's service list has empty intersection with the Battlefield-only service list (same assertion style as T-006's smoke test).

---

## Phase 7 — Battlefield Core & Enemy Hierarchy

#### [ ] T-701 `BattlefieldBootstrap`
**Depends on:** T-106, T-006, S-701–S-708
**Description:** Reads `TeleportData.mapId`, loads `MapDefinitions[mapId]`, clones the map template from `ReplicatedStorage/Assets/Maps/<mapId>` into `Workspace`. Establishes the server-side enemy registry used by T-404/T-409.
**DoD:** Wrong/missing `mapId` in TeleportData fails safely (kick to Lobby with a message, never a silent broken instance).
**Test cases:** Missing-mapId and invalid-mapId fallback paths tested.

#### [ ] T-702 `EnemySpawnService` (wave director)
**Depends on:** T-701, T-105, S-702
**Description:** Reads `map.waveConfig`, spawns enemies at `EnemySpawnPoint`-tagged parts matching `SpawnGroupId`, staggers timing per wave, scales count by current party size in the server instance (GDD §6.1).
**DoD:** Enemy count scaling formula lives in `shared/EnemyScaling.lua` (pure, testable — see T-711).
**Test cases:** Given a mock `waveConfig` and spawn-point set, correct enemy count/type spawned per wave, in the documented order.

#### [ ] T-703 Immediate-aggro on spawn
**Depends on:** T-702
**Description:** Enemies path toward the nearest player the instant they spawn — no idle/patrol state (GDD requirement: "enemies should approach and attack each player").
**DoD:** No enemy ever sits in an `Idle` state once spawned; straight to `Seek`/`Attack`.
**Test cases:** Spawn-to-Seek transition happens on the same tick as spawn (state-machine unit test on the shared enemy FSM module).

#### [ ] T-704 Foot Soldier behavior modules
**Depends on:** T-105, T-703
**Description:** One module per variant under `src/server/Services/EnemyBehaviors/`: `Swordsman`, `Spearman`, `ShieldBearer`, `Thrower`, `Bomber`, `Swinger`, `TreasureCarrier` — matching GDD §7.1's behavior/role table exactly. Common `IEnemyBehavior` interface: `Update(enemy, dt)`.
**DoD:** Every `EnemyDefinitions.behaviorModule` string (T-105) resolves to a real file here — cross-reference test.
**Test cases:**
- Structural: every `behaviorModule` referenced in `EnemyDefinitions` has a matching module (closes the T-105 DoD note).
- `ShieldBearer`: frontal hit blocked, side/rear hit not blocked (pure geometry check given attacker/defender facing).
- `Thrower`: retreats when player distance < threshold, otherwise holds range and fires.
- `Bomber`: detonates on proximity or on expiry timer, whichever first — both paths tested.
- `TreasureCarrier`: flees rather than attacks; on-kill loot roll uses `RewardTables.DestructibleBox`-tier odds or its own table (decide and test whichever).

#### [ ] T-705 `CommanderBehavior`
**Depends on:** T-704, T-408
**Description:** Aura buff (damage/defense %) applied to nearby Foot Soldiers within a radius while the Commander is alive; removed the instant the Commander dies (GDD §7.2). Poise-wired to T-408.
**DoD:** No lingering buff after death (checked same-tick, not next-tick).
**Test cases:** Buff applied to in-radius Foot Soldiers, not out-of-radius ones; buff removed in the same update cycle the Commander's HP hits 0.

#### [ ] T-706 `MidBossController`
**Depends on:** T-704, S-705/S-707
**Description:** Named enemy with a unique moveset (reuse the combo-node pattern from T-104), HP bar with name/portrait client UI (`Signal MidBossEngaged`/`MidBossDefeated`), unlocks a side-objective reward on death (GDD §7.3).
**DoD:** Multiple Mid-Bosses per map supported (per-instance state, not a singleton).
**Test cases:** Engaged/Defeated signals fire exactly once each per Mid-Boss instance; side-objective reward granted on death, not before.

#### [ ] T-707 `FinalBossController`
**Depends on:** T-706, T-709, S-706
**Description:** Multi-phase state machine — phase thresholds by HP%, each phase swaps moveset/behavior params. Arena sealed by `FinalBossArenaGate` until pre-boss objectives complete (T-709). Death triggers map-clear (T-710).
**DoD:** Phase transitions are one-way and idempotent at the boundary (no flicker between phases if HP hovers near a threshold).
**Test cases:** Each phase threshold crossing fires exactly once; HP oscillating just above/below a threshold (simulated) doesn't re-trigger the transition; gate stays sealed until all pre-boss objectives report complete.

#### [ ] T-708 `DestructibleBoxService`
**Depends on:** T-107, S-703
**Description:** `DestructibleBox`-tagged parts, break on hit (folds into normal combo flow, GDD §6.3), rolls `RewardTables` on break, despawns, never respawns within the same server instance.
**DoD:** Box state (broken/unbroken) tracked per-instance only — no cross-instance persistence.
**Test cases:** Break triggers exactly one loot roll; re-touching an already-broken box's location produces nothing; `RandomPool`-flagged boxes only spawn a subset per instance (per S-703 placement convention) — verify the subset-selection function distributes evenly over many simulated instances.

#### [ ] T-709 `ObjectiveService`
**Depends on:** T-701, S-704
**Description:** Tracks camp-capture/side-objective state per server instance, `Signal ObjectiveUpdated`, gates `FinalBossArenaGate`.
**DoD:** Objective state never leaks between server instances (each Battlefield reserved server is fully isolated — verify no shared DataStore/global state is used here, only in-memory per-instance).
**Test cases:** Completing all required objectives (not side ones) flips the gate-open condition; a side objective alone does not.

#### [ ] T-710 `MapClearService`
**Depends on:** T-707, T-901–T-903
**Description:** On Final Boss defeat: halts further spawning, computes reward payout (Phase 9), shows results screen, teleports the party back to the Lobby place after a delay/confirmation.
**DoD:** Spawning halted before rewards computed (no enemies spawning into an already-cleared map during the results screen).
**Test cases:** `HaltSpawning` called exactly once on Final Boss death; return-to-Lobby teleport only fires after results-screen acknowledgment (or timeout), never immediately.

#### [ ] T-711 `shared/EnemyScaling.lua`
**Depends on:** T-004
**Description:** Pure function `ScaleForPartySize(baseValue, partySize): number` for enemy HP/damage multipliers.
**DoD:** Monotonically non-decreasing in `partySize`.
**Test cases:** Output at `partySize=1` equals `baseValue`; output at `partySize=8` matches the documented curve; monotonicity across the full 1–8 range.

---

## Phase 9 — Reward & Progression

#### [ ] T-901 Per-enemy reward hook
**Depends on:** T-105, T-302, T-203
**Description:** Subscribes to enemy `Died` events, grants XP+currency per the dying enemy's tier (GDD §8.1) via `LevelService.AwardXP` + `CurrencyService.AddCurrency`.
**DoD:** Exactly one reward grant per enemy death, regardless of how many players contributed damage (decide and document: killer-only vs damage-share — recommend damage-share for co-op fairness).
**Test cases:** Single-player kill grants full reward; co-op kill (mocked multi-source damage) splits/grants per the documented policy, summing to the same total either way (no reward inflation from party size).

#### [ ] T-902 `shared/RankFormula.lua`
**Depends on:** T-004
**Description:** Pure function computing D–S rank from `{comboCount, damageTaken, timeElapsedSeconds}` (GDD §8.2), tracked per-instance server-side.
**DoD:** Deterministic, documented weight formula.
**Test cases:** Table-driven: known stat combos → expected rank letter; boundary values between adjacent ranks tested on both sides.

#### [ ] T-903 `MapClearRewardService`
**Depends on:** T-710, T-107, T-902
**Description:** Guaranteed reward bundle (XP/currency/gear per map tier) + bonus roll (rare/legendary/cosmetic/battle-pass XP) scaled by rank. Grants the map's **Main Reward** guaranteed on the player's *first* clear of that map (tracked in `profile.MapStats`); repeat clears get the standard bonus roll only, not another guaranteed Main Reward.
**DoD:** Main Reward grant is idempotent per player per map.
**Test cases:** First clear grants Main Reward; second clear of the same map does not re-grant it but still grants the bonus roll; rank affects bonus-roll odds/amount per T-902's output.

#### [ ] T-904 `QuestService`
**Depends on:** T-109
**Description:** Tracks quest progress via event hooks (enemy kills by tier, maps cleared); daily/weekly reset via server timestamp check on login.
**DoD:** Reset boundary uses a single documented reset hour/timezone (e.g., reset at 00:00 UTC), applied consistently.
**Test cases:** Injected-clock test: login just before reset boundary doesn't reset; login just after does; weekly cadence resets on the correct day only.

#### [ ] T-905 `BattlePassService`
**Depends on:** T-904, T-110
**Description:** Seasonal XP fed by quest completions + map clears; tier-unlock table; free vs premium track gated by `ProductCatalog` ownership check (T-1002/T-1005).
**DoD:** Premium-track rewards inaccessible without the season's premium flag, even if tier XP threshold is met.
**Test cases:** Free track unlocks at XP thresholds regardless of premium flag; premium track items withheld until premium flag true, then retroactively available at already-passed thresholds.

---

## Phase 10 — Monetization

#### [ ] T-1001 `MonetizationService` — `ProcessReceipt`
**Depends on:** T-110, T-204, T-203
**Description:** Handles all Developer Products in `ProductCatalog`. Idempotent via receipt tracking (`PlayerId + ProductId + PurchaseId`) stored in the profile — required by Roblox so a retried receipt never double-grants.
**DoD:** Returns `Enum.ProductPurchaseDecision.PurchaseGranted` only after the grant actually succeeds; on failure returns `NotProcessedYet` so Roblox retries.
**Test cases:** Replaying an already-recorded `PurchaseId` grants nothing a second time but still returns `PurchaseGranted`; a novel receipt grants exactly once and is recorded.

#### [ ] T-1002 `GamePassService`
**Depends on:** T-110
**Description:** `UserOwnsGamePassAsync` check (cached, refreshed on `PlayerAdded` + `PromptGamePassPurchaseFinished`), applies passive effects: XP Boost %, Currency Boost %, VIP perks (GDD §9.2).
**DoD:** Boost percentages apply multiplicatively at the point of `AwardXP`/`AddCurrency`, not as a separate untracked bonus.
**Test cases:** `AwardXP` with boost owned yields `base * (1 + boostPct)`; without, yields `base`.

#### [ ] T-1003 Premium-currency purchase path
**Depends on:** T-601, T-1001
**Description:** `ShopService` premium-currency SKUs route to `MonetizationService:PromptProductPurchase`.
**DoD:** Purchase confirmation only reflects in `CurrencyService` after `ProcessReceipt` confirms — no client-optimistic currency credit.
**Test cases:** Manual/visual (Robux purchase flow requires a live/Studio-test environment) — covered in S-1301.

#### [ ] T-1004 Cosmetic-only monetization guardrail (automated)
**Depends on:** T-110
**Description:** Codifies GDD §9.5 as a test, not just policy: every `ItemDefinitions`/`WeaponDefinitions`/`UltimateDefinitions` entry that is premium-currency-exclusive (not obtainable via `SoftCurrency` or free play) must have `cosmeticOnly = true`.
**DoD:** This test is wired into the same suite run in T-1301, so it fails the build if a future item accidentally ships stat-affecting and premium-exclusive.
**Test cases:** Iterate every catalog entry; assert `not (premiumExclusive and statBonus ~= 0) or cosmeticOnly == true`. **This is the most important test in the backlog — flag it in code review.**

#### [ ] T-1005 Battle Pass premium unlock
**Depends on:** T-905, T-1002
**Description:** Game-Pass-based, one per season, seasonal id in `ProductCatalog`.
**DoD:** Owning a past season's pass doesn't unlock the current season (seasonal ids are distinct products).
**Test cases:** Ownership check scoped to current season's product id only.

#### [ ] T-1006 Loadout preset slot purchase
**Depends on:** T-503, T-1001
**Description:** Dev-product purchase increments `profile.LoadoutPresets` cap.
**DoD:** Cap increment applied exactly once per purchase (protected by the same idempotent-receipt mechanism as T-1001).
**Test cases:** Repeated receipt for the same purchase doesn't stack the cap increment twice.

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
