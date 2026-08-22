# STUDIO_TASKS.md — Manual Roblox Studio / Creator Dashboard Backlog

Everything here can't be done through `src/` code — Studio building, model/animation import, CollectionService tagging by hand, and Creator Dashboard configuration (products, passes, publishing). Cross-referenced against [TASKS.md](TASKS.md) by ID (`S-###` here, `T-###` there). Read TASKS.md's **Architecture decision** and **Naming contract** sections first — every tag/attribute placed here must match those exactly, or the corresponding script silently does nothing.

## Task template
Each task: **Description**, **Depends on**, **DoD**, **Verification** (how to confirm it's actually right), checkbox.

---

## Phase 0 — Experience Setup

#### [x] S-001 Create Experience + two Places
**Depends on:** none
**Description:** Create the Roblox Experience. Create two Places inside it: **Lobby** (set as the start place) and **Battlefield** (game place, shared by all maps per the multi-place architecture decision in TASKS.md).
**DoD:** Both places exist in the Creator Dashboard; their PlaceIds are recorded and handed off to T-1402 (`Constants.lua`).
**Verification:** Both places launchable individually from Studio's "Open in Studio" per-place picker.

#### [x] S-002 Enable Studio Access to API Services
**Depends on:** S-001
**Description:** Game Settings → Security → enable "Studio Access to API Services" so ProfileService/DataStore calls (T-201) work while testing in Studio.
**DoD:** Toggle enabled on both places (DataStore is only actually used from the place(s) that run `DataService` — Lobby at minimum; enable on both for safety).
**Verification:** A test script calling `DataStoreService:GetDataStore(...):SetAsync(...)` in Studio doesn't throw a permission error.

#### [ ] S-003 Game Settings baseline
**Depends on:** S-001
**Description:** Set Avatar Type to **R15** (required for the combo/weapon animation rigging in S-102). Enable `Workspace.StreamingEnabled` on the Battlefield place if map size warrants it (decide once S-701 blockouts exist). Set reasonable `MaxPlayers`/`PreferredPlayers` per place (Lobby: social cap, e.g. 20–50; Battlefield: matches the 8-player party cap from T-604, since each server is a reserved instance for one party).
**DoD:** Settings applied per place, documented here once decided (avoid re-deciding later).
**Verification:** Spawn-test in both places confirms R15 rig loads correctly with default avatar.

#### [ ] S-004 Rojo sync workflow for two places
**Depends on:** S-001, T-006 (lobby.project.json / battlefield.project.json)
**Description:** Document (in this repo's README or here) the two-terminal workflow: `rojo serve lobby.project.json` connected to the Lobby place's Studio session, `rojo serve battlefield.project.json` connected to the Battlefield place's session (different ports if run simultaneously).
**DoD:** A contributor can follow the documented steps and get both places live-syncing without guessing port numbers.
**Verification:** Edit a file in `src/shared`, confirm it live-updates in both open Studio sessions.

#### [ ] S-005 Group ownership (optional)
**Depends on:** S-001
**Description:** If revenue split / team collaboration is wanted, create or select a Roblox Group to own the Experience instead of a personal account. Skip if solo-dev with no payout-splitting need.
**DoD:** Decision recorded here (Group vs personal); if Group, experience transferred/created under it before any monetization products are added (S-1001+), since payout configuration is group-level.
**Verification:** Experience owner shown as the Group in the Creator Dashboard.

---

## Phase 1 — Character & Animation Assets

#### [ ] S-101 Base character rig + accessory attach points
**Depends on:** S-003 (R15)
**Description:** Confirm/import the base character mesh with R15-compatible attach points for Head/Body/Arm/Leg accessories, matching the slot naming in `ItemDefinitions.lua` (T-101) exactly (`Head|Body|Arm|Leg`).
**DoD:** A sample accessory can be welded to each of the four slots without manual per-item socket hacking.
**Verification:** Manually weld one placeholder item per slot in Studio, confirm correct attachment/orientation on a moving character.

#### [ ] S-102 Weapon models + combo animations
**Depends on:** S-101
**Description:** For each weapon in `WeaponDefinitions.lua` (T-102): (1) create/import a weapon model (a physical mesh to weld into the character's hand — CharacterAppearanceService, T-504, has nothing to attach without one); (2) create/import animations: 3× Light, 1× Heavy (or per your combo tree's finisher count from T-104), Special, Dash, Ultimate. Publish each as a Roblox Animation asset.
**DoD:** One model + one animation id per required move, per weapon, all ids collected.
**Verification:** Hand the collected ids back — `WeaponDefinitions.lua`'s `weaponModelAssetId` and `animationIds` fields have no `nil`s left. Preview each animation in Studio's Animation Editor before publishing; confirm the model's handle orientation looks right gripped in a test character's hand.

#### [ ] S-103 Accessory models
**Depends on:** S-101
**Description:** Create/import a model per accessory catalog entry in `ItemDefinitions.lua` (T-101) — Head/Body/Arm/Leg, across the defined rarity tiers.
**DoD:** One `meshAssetId` per catalog entry.
**Verification:** Feeds T-101 — no `nil` `meshAssetId` remains; spot-check a handful equipped in-game via T-504.

#### [ ] S-104 Ultimate VFX
**Depends on:** none (parallel to S-101–103)
**Description:** Create particle/beam/screen effects per entry in `UltimateDefinitions.lua` (T-103) — "big, flashy, screen-clearing" per GDD §4.3.
**DoD:** One `vfxAssetId` (or effect-instance template in `ReplicatedStorage/Assets`) per Ultimate.
**Verification:** Feeds T-103; trigger each Ultimate manually once T-407 exists and confirm visual reads clearly against a crowd of enemies.

---

## Phase 6 — Safe Lobby Build

#### [ ] S-601 Block out Safe Lobby layout
**Depends on:** S-001
**Description:** Build the social-hub layout per GDD §5: shop area, loadout station, map-select area, open social plaza. No combat geometry, no enemy spawn points anywhere in this place (this is later cross-checked by T-608).
**DoD:** Walkable, collision-correct blockout; distinct zones for each feature below.
**Verification:** Walk the full space in Studio's Play Solo, confirm no fall-through/collision gaps.

#### [ ] S-602 Place Shop Kiosk(s)
**Depends on:** S-601
**Description:** Place kiosk model(s), tag `ShopKiosk` with Attribute `ShopId` (matching however `ShopService`/T-601 groups its catalog — e.g. one kiosk for gear, one for cosmetics, or a single unified kiosk — decide and keep consistent with the shop UI's categories).
**DoD:** Tag + attribute present and spelled exactly per the naming contract in TASKS.md.
**Verification:** In-game, interacting with the kiosk opens the Shop UI (T-602) once that script exists.

#### [ ] S-603 Place Loadout Station
**Depends on:** S-601
**Description:** Place the loadout station model/part, tag `LoadoutStation`.
**DoD:** Tag present, one station minimum.
**Verification:** Interacting opens the Loadout UI (T-602) once that script exists.

#### [ ] S-604 Place Map Portals (CTR-style)
**Depends on:** S-601, T-106 (needs final `MapDefinitions` id list)
**Description:** One physical portal/tile per battlefield map, tag `MapPortal` with Attribute `MapId` matching the corresponding `MapDefinitions` entry id exactly. Give each portal a distinct visual (banner/thumbnail display) so players can tell maps apart at a glance, per GDD §5's CTR-style requirement.
**DoD:** Portal count == `MapDefinitions` entry count; every `MapId` attribute matches a real id (typo here silently breaks T-606).
**Verification:** Cross-check the placed `MapId` attributes against `MapDefinitions.lua` line by line before marking done.

#### [ ] S-605 Add portal interaction triggers
**Depends on:** S-604
**Description:** Add a `ProximityPrompt` (or equivalent touch trigger) to each `MapPortal` part, per `PortalService`'s (T-606) expected interaction method.
**DoD:** Every portal has exactly one trigger, consistent prompt text/style across all portals.
**Verification:** Trigger fires reliably in Play Solo without needing pixel-perfect positioning.

#### [ ] S-606 Lobby lighting/atmosphere pass
**Depends on:** S-601
**Description:** Non-combat, welcoming tone lighting pass — this is the social hub, should read distinctly calmer than the Battlefield.
**DoD:** Lighting settings finalized and saved.
**Verification:** Visual review.

#### [ ] S-607 Verify zero enemy content in Lobby
**Depends on:** S-601–S-606
**Description:** Manual sweep confirming no `EnemySpawnPoint`, `DestructibleBox`, `CampPoint`, `MidBossSpawn`, or `FinalBossSpawn` tagged instances exist anywhere in the Lobby place — this place must stay 100% combat-free per GDD §5.
**DoD:** Zero matches when checking the place's tagged-instance list against the Battlefield-only tag set.
**Verification:** Use the CollectionService tag browser (or a one-off `game:GetService("CollectionService"):GetTagged(...)` check run in the Command Bar) for each Battlefield-only tag — all return empty in the Lobby place.

---

## Phase 7 — Battlefield Map Build

Repeat this whole block (S-701–S-708) once per entry in `MapDefinitions.lua` (T-106). Use the first map as the template map; subsequent maps get their own checklist copy.

#### [ ] S-701 Block out battlefield terrain/layout
**Depends on:** S-001
**Description:** Stronghold path + multiple capture-point camps leading toward it, per GDD §6.1. Scale for up to 8 concurrent players (reserved-server party cap).
**DoD:** Walkable, collision-correct blockout; camps are visually/spatially distinct.
**Verification:** Walk the full path in Play Solo; confirm no geometry gaps enemies could get stuck in.

#### [ ] S-702 Place Enemy Spawn Points
**Depends on:** S-701, T-106 (final `waveConfig`)
**Description:** Place `EnemySpawnPoint`-tagged parts at each camp, Attribute `SpawnGroupId` matching the `spawnGroupId` strings used in that map's `waveConfig` (T-106/T-702) — this is the single most failure-prone naming-contract link in the whole project; double check spelling.
**DoD:** Every `spawnGroupId` referenced in `waveConfig` has at least one matching spawn point placed.
**Verification:** Cross-check placed `SpawnGroupId` attributes against `MapDefinitions.lua`'s `waveConfig` entries for this map, one-to-one.

#### [ ] S-703 Place Destructible Boxes
**Depends on:** S-701
**Description:** Place crate/barrel models around camps and paths, tag `DestructibleBox` with Attribute `LootTableId` (matching `RewardTables.lua`, T-107). Mark a subset with Attribute `RandomPool = true` for the "a few random spawn points per playthrough" behavior from GDD §6.3 — fixed placements stay untagged-random (always present), pool-marked ones are randomly subset-selected per instance by T-708.
**DoD:** Mix of fixed and `RandomPool` boxes placed per GDD §6.3's intent (not 100% fixed, not 100% random).
**Verification:** Visual placement review; confirm `LootTableId` values match real `RewardTables` keys.

#### [ ] S-704 Place Objective points
**Depends on:** S-701
**Description:** Place `CampPoint`/`ObjectivePoint`-tagged parts (Attributes `ObjectiveId`, `ObjectiveType`) plus any side-objective set pieces (rescue cage, siege equipment prop) matching `ObjectiveService`'s (T-709) expected ids for this map.
**DoD:** Every objective referenced in this map's design has a matching tagged part.
**Verification:** Cross-check against the map's objective list.

#### [ ] S-705 Build Mid-Boss arena(s) + spawn points
**Depends on:** S-701
**Description:** Sub-area per named Mid-Boss guarding a key point/camp (GDD §7.3), place `MidBossSpawn`-tagged point per boss, Attribute `MidBossId` matching `EnemyDefinitions`/`MapDefinitions.midBossIds`.
**DoD:** One arena + spawn point per Mid-Boss on this map.
**Verification:** Cross-check `MidBossId` attributes against `MapDefinitions.midBossIds` for this map.

#### [ ] S-706 Build Final Boss arena + gate
**Depends on:** S-701, S-704 (pre-boss objectives must exist to gate against)
**Description:** Arena for the climactic encounter (GDD §7.4), place `FinalBossSpawn` point and a `FinalBossArenaGate`-tagged sealable barrier that stays shut until pre-boss objectives clear (T-707/T-709).
**DoD:** Gate physically blocks arena entry when closed; open state is visually obvious.
**Verification:** Manually toggle the gate's open/closed state in Studio and confirm it actually blocks/allows player movement.

#### [ ] S-707 Named enemy models (Mid-Boss, Final Boss)
**Depends on:** S-705, S-706
**Description:** Distinct silhouette/character model per named Mid-Boss and this map's Final Boss (GDD §7.3/§7.4 — must read as unique, not a reskinned Foot Soldier), plus a portrait image asset for the HP-bar UI (feeds T-706's client UI).
**DoD:** One model + one portrait per named enemy on this map.
**Verification:** Feeds `EnemyDefinitions.lua`'s `modelAssetId` (T-105) — no `nil` left for these entries.

#### [ ] S-708 Foot Soldier + Commander NPC models
**Depends on:** S-701
**Description:** One model per variant referenced in `EnemyDefinitions.lua` (T-105): Swordsman, Spearman, Shield Bearer, Rock/Javelin Thrower, Bomber, Swinger/Berserker, Treasure Carrier, Commander. Model naming/animation sockets must match whatever each variant's behavior module (T-704) expects for its attack animations (e.g. a Bomber needs a visible bomb prop, a Thrower needs a throw animation + projectile model).
**DoD:** Every `EnemyDefinitions` entry with `tier ∈ {FootSoldier, Commander}` has a `modelAssetId` filled in.
**Verification:** Spot-spawn each variant in Studio once T-704 exists, confirm its animation/behavior reads correctly against its model.

#### [ ] S-709 Repeat for additional maps
**Depends on:** S-701–S-708 (template map complete)
**Description:** Duplicate the S-701–S-708 checklist as a new block per additional `MapDefinitions` entry. Don't reuse the template map's tagged instances directly — each map needs its own spawn points/objectives/portals with ids matching its own `MapDefinitions` entry.
**DoD:** One full S-701–S-708 pass completed per map planned for launch.
**Verification:** Same per-map checks as above, run independently per map.

---

## Phase 10 — Monetization Setup (Creator Dashboard)

#### [ ] S-1001 Create Developer Products
**Depends on:** T-110 (`ProductCatalog.lua` SKU list finalized), S-005 (if using a Group)
**Description:** Create one Developer Product per premium-currency bundle and per direct-purchase cosmetic SKU listed in `ProductCatalog.lua`. Name/price them clearly (internal SKU name should be traceable back to the catalog key for future maintenance).
**DoD:** One Roblox `productId` per Dev Product SKU.
**Verification:** Feeds T-1401 — hand the ids back for `ProductCatalog.lua`; confirm each product shows correct price in the Dashboard before going live.

#### [ ] S-1002 Create Game Passes
**Depends on:** T-110
**Description:** Create: XP Boost, Currency Boost, VIP, Auto-loot/Extra Inventory, and one Battle-Pass-Premium pass per planned season (GDD §9.2/§9.3).
**DoD:** One Roblox `gamePassId` per Game Pass SKU.
**Verification:** Feeds T-1401; confirm each pass's icon/description is set (required before it can go on sale).

#### [ ] S-1003 Payout/revenue configuration
**Depends on:** S-005, S-1001, S-1002
**Description:** Configure payout destination (personal account or Group funds, per S-005's decision).
**DoD:** Payout settings confirmed correct in account/Group settings before launch.
**Verification:** Roblox Creator Dashboard payout summary shows the expected destination.

#### [ ] S-1004 Monetization policy sign-off
**Depends on:** T-1004 (automated guardrail test), S-1001, S-1002
**Description:** Human sign-off pass: manually confirm every stat-affecting purchasable also has a genuine free-earn path (GDD §9.5's guardrail — this is the manual counterpart to T-1004's automated test, not a replacement for it).
**DoD:** Written sign-off note here once reviewed; both the automated test (T-1004) and this manual review must pass before any product goes live.
**Verification:** Cross-check the Dev Product/Game Pass list against `ProductCatalog.lua`'s `cosmeticOnly` flags.

---

## Phase 11 — UI Art

#### [ ] S-1101 HUD art
**Depends on:** S-101
**Description:** HP/Stamina/Ultimate gauge/Poise bar visuals, designed against the responsive breakpoints defined in T-1103.
**DoD:** Art assets sized/exported for at least the smallest and largest reference resolutions from T-1103's test set.
**Verification:** Visual review at both extremes, no illegible/cramped elements.

#### [ ] S-1102 Shop/Loadout/MapSelect/Party UI skins + map thumbnails
**Depends on:** S-604 (portal visuals), T-603 (MapSelect preview panel)
**Description:** UI skins for the four lobby panels, plus a thumbnail/banner per map matching each portal placed in S-604.
**DoD:** One thumbnail per `MapDefinitions` entry, consistent style.
**Verification:** Preview each thumbnail in the actual MapSelect UI once T-603 exists.

#### [ ] S-1103 Touch control button art
**Depends on:** T-1104
**Description:** On-screen virtual button art for the mobile/tablet control layer.
**DoD:** Buttons legible and appropriately sized for touch targets (finger-sized hit areas, not mouse-sized).
**Verification:** Test on an actual phone-sized viewport, not just a resized desktop window.

---

## Phase 13 — QA

#### [ ] S-1301 Multi-device manual playtest
**Depends on:** T-1101–T-1105
**Description:** Playtest across Desktop, Mobile (or emulated touch), and Console/gamepad input, verifying input remapping (T-1102) and responsive UI (T-1103) actually behave correctly on each — not just in theory.
**DoD:** Pass/fail logged per device type per core flow (combat, shop, loadout, map select, portal teleport).
**Verification:** This task's own checklist output.

#### [ ] S-1302 Co-op playtest with a second real account
**Depends on:** T-604, T-606
**Description:** Playtest the full party → portal → reserved-server → battlefield → map-clear → return-to-lobby loop with a genuine second player (friend/alt account), not just Studio's test-server simulation.
**DoD:** Full loop completes with no desync, no duplicate/missing rewards between the two accounts.
**Verification:** This task's own checklist output.

---

## Phase 14 — Publish / Release

#### [ ] S-1401 Publish both Places
**Depends on:** T-1401, T-1402, T-1301 (script suite green)
**Description:** File → Publish to Roblox for both the Lobby and Battlefield places, after the final Rojo sync of each.
**DoD:** Both places published and playable via the live Experience link.
**Verification:** Launch the Experience from a fresh account (not logged in as the developer) and confirm the full loop works.

#### [ ] S-1402 Store page
**Depends on:** S-104, S-1101/S-1102 (art assets to draw from)
**Description:** Experience icon, thumbnails, description, genre tags. Copy should be consistent with the GDD's pitch (Basara-inspired hack-and-slash, customization, co-op).
**DoD:** Store page complete and reviewed for typos/accuracy.
**Verification:** Visual review of the live store page.

#### [ ] S-1403 Visibility + compliance
**Depends on:** S-1004, S-1401
**Description:** Flip Experience visibility from Private (dev) to Public at launch; complete Roblox's age-rating questionnaire (required given monetization + social/party features).
**DoD:** Questionnaire submitted and approved; visibility set intentionally, not left on a default.
**Verification:** Age rating badge visible on the live store page.

#### [ ] S-1404 Post-launch monitoring setup
**Depends on:** S-1401
**Description:** Bookmark the Creator Dashboard analytics view (revenue, DAU, retention) for ongoing monitoring.
**DoD:** Monitoring habit/cadence noted somewhere the team will actually see it (not required to be in this repo).
**Verification:** N/A.

---

## Phase index

| Phase | Scope |
|---|---|
| 0 | Experience/place creation, API access, Rojo sync setup, group ownership |
| 1 | Character rig, weapon/combo animations, accessory models, ultimate VFX |
| 6 | Safe Lobby build: shop, loadout station, portals, lighting, combat-free check |
| 7 | Per-map battlefield build: terrain, spawn points, boxes, objectives, boss arenas, NPC models |
| 10 | Developer Products, Game Passes, payout config, policy sign-off |
| 11 | HUD/UI art, map thumbnails, touch control art |
| 13 | Multi-device and co-op manual playtests |
| 14 | Publish, store page, compliance, monitoring |
