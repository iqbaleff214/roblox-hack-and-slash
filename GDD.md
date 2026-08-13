# Game Design Document

**Working Title:** (TBD)
**Genre:** Hack-and-Slash Action RPG
**Platform:** Roblox — cross-platform (Desktop, Mobile, Console, Tablet), full crossplay, single shared player base/economy across devices
**UI:** Fully responsive — HUD, shop/lobby menus, and map-select scale and re-layout per screen size/aspect ratio and input type (mouse/keyboard, gamepad, touch), so no cramped/cut-off UI on phone or tablet
**Inspiration:** Sengoku Basara: Heroes 2 (PS2) — large-scale one-vs-many battlefield combat, flashy combos, commander/general enemy hierarchy, map-clearing objectives.

---

## 1. Concept

Players fight through mob-filled battlefield maps, mowing down foot soldiers, breaking through commander-led squads, defeating named mid-bosses, and finally toppling a map's final boss to clear it. Between runs, players return to a **Safe Lobby** to shop, customize their character, socialize, and prepare for the next map.

Structure mirrors a menu/game-core split:
- **Safe Lobby** = social hub / main menu, replicated in-world (no combat, no enemies).
- **Battlefield Map** = core gameplay loop (combat, objectives, rewards).

---

## 2. Core Gameplay Loop

1. Player spawns in **Safe Lobby**.
2. Player shops / equips gear, weapon, ultimate, checks level & progression.
3. Player queues into a **Battlefield Map** (solo or party).
4. On arrival, enemies actively approach and engage — no passive waiting; the map is "live" from the moment players land.
5. Player fights through escalating enemy tiers (foot soldiers → commanders → mid-boss) to advance/clear sub-objectives (e.g., capture points, gates, camps).
6. Player defeats the **Final Boss** to clear the map.
7. Rewards (currency, XP, gear, cosmetics) granted; player returns to Safe Lobby.
8. Repeat with progression carried forward (level, unlocks, currency).

---

## 3. Character Progression

### 3.1 Leveling
- Players earn **XP** from defeating enemies (scaled by enemy tier) and clearing map objectives/bosses.
- Leveling up increases core combat stats: HP, Attack, Stamina/Combo capacity.
- Level also gates access to higher-tier weapons, ultimates, and harder maps (recommended level per map).
- No hard level cap initially; soft-cap via diminishing XP curve, later extended with Prestige/Rebirth system (future scope).

### 3.2 Stats (baseline)
- HP
- Attack Power
- Defense
- Stamina (combo/dodge resource)
- Ultimate Charge Rate

---

## 4. Customization System

Fully modular equipment system, cosmetic + stat-affecting.

### 4.1 Accessory Slots
- **Head** — helmets, masks, hairstyles/hats
- **Body** — armor/torso
- **Arm** — gauntlets, sleeves
- **Leg** — greaves, boots

Each slot has:
- Rarity tier (Common → Legendary)
- Minor stat bonus (defense/HP/attack, small %) tied to rarity
- Pure-cosmetic skins available via monetization (no stat impact, for balance integrity — see Section 8)

### 4.2 Weapon System
- Player selects one equipped **Weapon Type** (e.g., Katana, Spear/Yari, Naginata, Twin Blades, Fists, Bow) — Basara-style weapon variety.
- Each weapon type has its own combo string/moveset.
- Weapons have rarity/upgrade levels (damage scaling, added effects e.g. fire/bleed).
- Weapon skins sold separately as cosmetics.
- **Weapon is fixed for the duration of a battlefield run** — no mid-combat switching, matching Basara 2. Weapon choice (and Ultimate/accessories) is only made at the Safe Lobby loadout station before entering a map.

### 4.3 Ultimate Attack
- Player selects one **Ultimate Attack** (independent of weapon) — big screen-clearing move, Basara "Basara Art" style.
- Charges via an **Ultimate Gauge** filled by dealing/taking damage and landing combos.
- Ultimates are unlockable/purchasable and swappable in the lobby (loadout system, not permanently bound to a character).
- Visually flashy, large hitbox, meant for clearing groups of foot soldiers or breaking commander/mid-boss poise.

### 4.4 Loadout System
- Players configure a loadout in the Safe Lobby: Weapon + Ultimate + 4 Accessory slots.
- Loadouts save per-profile; multiple saved loadout presets (monetizable slot expansion — see Section 8).

---

## 5. Safe Lobby (Hub)

Non-combat social/menu space.

Features:
- **Shop NPCs/kiosks** — currency shop, gear shop, cosmetic shop, weapon dealer.
- **Loadout/Customization station** — equip accessories, weapon, ultimate.
- **Map Select terminal** — CTR-style map selection: a physical hub area/select screen where each battlefield map is represented by its own portal/icon (walk up to or click a map tile, no menu-diving). Selecting a map shows a preview panel with recommended level, party-up option, and the map's **Main Reward** (a guaranteed showcase item — e.g., a specific weapon skin, unique accessory, or exclusive gear piece tied to that map) so players can target-farm a specific map for a specific prize, not just "go fight something."
- **Social space** — free-roam, emotes, player housing/guild hall (stretch goal), photo-mode area.
- **Progression board** — displays level, XP bar, currency balances, battle pass progress.
- No enemies, no damage, safe to idle/socialize.

---

## 6. Battlefield Map (Core Gameplay)

### 6.1 Structure
- Large open battlefield, Basara-style: multiple capture points/camps leading toward an enemy stronghold.
- On player arrival, nearby enemy squads immediately notice and advance to engage — aggressive pacing from the start, no downtime.
- Maps are clearable solo or co-op, **party size cap: 8 players** (enemies scale with party size).
- Entry is manual, not automatic: after selecting a map, players stand at the map's portal in the Safe Lobby. Party leader/members can choose to wait for more players to join the party or trigger the portal to teleport whoever's currently in with them — no forced auto-teleport on selection.

### 6.2 Objectives
- Clear enemy camps/checkpoints to push toward the stronghold.
- Optional side objectives (rescue an ally officer, destroy siege equipment) for bonus rewards.
- Final objective: defeat the **Final Boss** to clear the map and trigger reward payout.

### 6.3 Destructible Boxes
- Crates/barrels scattered around the battlefield (camps, roadside, near objectives), Basara-style.
- Destroyed with any regular attack, no dedicated input needed — folds into normal combo flow.
- Contents on break (weighted random):
  - Soft currency
  - Small HP/stamina restore pickup
  - Ultimate Gauge charge
  - Rare gear/cosmetic chance (low odds, jackpot feel)
- Respawn per map instance only (not farmable by repeatedly re-entering same run); fixed placements plus a few random spawn points per playthrough to keep exploration relevant.

### 6.4 Combat Input System (Basara 2-style)

Core moveset, mapped to Basara 2's button-feel (adapted to Roblox PC/mobile input):

| Input | Action | Notes |
|---|---|---|
| **Light Attack** (M1 / tap) | Fast, low-damage swing | Base combo starter, short recovery |
| **Heavy Attack** (M2 / hold) | Slow, high-damage/knockback swing | Can end or redirect a combo, breaks poise faster |
| **Special Attack** (Q) | Weapon-unique move, short cooldown | Not tied to Ultimate Gauge; best poise-break tool, always available |
| **Dash/Evade** (Shift) | Short-range dash with i-frames | Cancels out of attack recovery; dashing into an attack input triggers a dash-attack opener |
| **Ultimate Attack** (R, gauge permitting) | Full-gauge screen-clearing super | Only usable at full Ultimate Gauge; see 4.3 |
| **Lock-On / Target Switch** (Tab / right-stick click) | Snaps camera/aim to nearest or named enemy | Important for tracking Commanders/Mid-Boss/Final Boss in large crowds |

**Combo branching:** Light and Heavy attacks chain in sequence (e.g., L-L-L vs L-L-H vs L-H) to produce different combo strings and finishers, Basara-style — mixing order changes hit count, knockback, and area coverage rather than being one fixed string. Encourages reading the crowd (wide Heavy-ended combos for groups, fast Light strings for single high-value targets).

**Poise/Stagger:** Foot soldiers have no poise (die straight through combos, satisfies mob-mowing feel). Commanders, Mid-Bosses, and the Final Boss have a poise bar — sustained combo damage or a Special Attack breaks it, opening a **Break Window** (bonus damage, no enemy retaliation) before it regenerates. Mirrors Basara's officer-break-and-punish rhythm.

**No player block/parry** — defense is dash-evade based (i-frames), consistent with Basara 2's mobility-over-blocking philosophy; keeps combat fast and combo-focused rather than defensive.

**Cross-platform input mapping:** Same six actions above, remapped per device — Desktop (mouse/keyboard as listed), Console/Gamepad (face buttons + trigger for Ultimate + right-stick lock-on), Mobile/Tablet (on-screen attack/special/dash/ultimate buttons + auto-assist lock-on, since touch lacks a precise stick). Combo timing/hitboxes stay identical across devices — only input method changes — so crossplay stays fair.

---

## 7. Enemy System (Basara-style Hierarchy)

Four-tier enemy hierarchy, matching Sengoku Basara's mob structure:

### 7.1 Foot Soldiers (Ashigaru)
- Weakest, spawn in large numbers/waves.
- Simple attack patterns, low HP, meant to be mowed down in combos for power-fantasy feel.
- Primary XP/currency drip-feed source.
- Multiple variants mixed into spawn waves so groups aren't just visual reskins — each forces a different read/response from the player.

| Variant | Behavior | Threat/Role |
|---|---|---|
| **Swordsman** | Basic melee swing, short windup | Baseline filler, safe to combo through |
| **Spearman** | Melee thrust with slightly longer reach | Punishes standing still at combo range |
| **Shield Bearer** | Blocks frontal hits, must be hit from side/back or staggered | Combo-flow interrupt, forces positioning |
| **Rock/Javelin Thrower** | Ranged, lobs projectiles from range, retreats when approached | Forces player to close distance or dodge incoming, breaks turtling |
| **Bomber** | Carries a bomb, rushes player and detonates (AoE) or lobs bomb at telegraphed spot | High-priority kill-on-sight, punishes ignoring it, rewards ranged/ultimate interrupt |
| **Swinger/Berserker** | Wide sweeping melee swing, hits multiple targets in an arc (dangerous in co-op clumps) | Area-denial, discourages balling up |
| **Treasure Carrier** | Passive/fleeing, no attack (or very weak), drops bonus loot/currency on kill | Optional greed-vs-efficiency choice, rewards map awareness |

- Variant mix is tuned per map/wave (e.g., later waves add more Bombers/Shield Bearers to raise difficulty without just adding HP).
- Same variant concept can extend upward: Commanders can have variant flavors too (e.g., a Commander that buffs ranged throwers vs one that buffs melee swingers) — noted as future expansion.

### 7.2 Commanders
- Mid-tier officer leading a squad of foot soldiers.
- Higher HP/damage, has a stagger/poise bar.
- Buffs nearby foot soldiers while alive (e.g., damage/defense aura) — killing the commander weakens the squad, incentivizing priority targeting.
- Drops better loot than foot soldiers.

### 7.3 Mid-Boss (Named Character)
- Unique named enemy (Basara-style rival general), has own moveset, voice lines, HP bar with name/portrait UI.
- Guards a key point on the map or a camp; defeating one may unlock a side objective reward or shortcut.
- Multiple mid-bosses per map possible.

### 7.4 Final Boss
- Map's climactic named boss with multi-phase moveset, large HP bar, arena-style final encounter.
- Required to clear the map.
- Drops the map's best guaranteed rewards + clear-bonus payout.

---

## 8. Reward System

Layered rewards to drive both moment-to-moment satisfaction and long-term retention.

### 8.1 Per-Enemy Rewards
- Foot soldiers: small XP + soft currency (drip-feed, satisfies power-fantasy combo-mowing).
- Commanders: moderate XP + soft currency + chance for gear drop.
- Mid-bosses: guaranteed gear drop (weapon/accessory), larger XP/currency, chance at cosmetic drop.

### 8.2 Map Clear Rewards (Final Boss down)
- Guaranteed: XP chunk, soft currency chunk, gear piece appropriate to map tier.
- Bonus: chance at rare/legendary gear, cosmetic currency, battle pass XP.
- Performance-based bonus multiplier: time taken, combo rank/style score (Basara-style rank grading: e.g., D–S rank based on combo count, damage taken, time), side objectives completed.

### 8.3 Progression Systems
- **Soft Currency** — earned via play, spent on gear/weapon upgrades (stat-affecting, free-to-earn).
- **Premium Currency** — purchased with real money (see Monetization), spent on cosmetics, loadout slots, convenience.
- **Battle Pass** (seasonal) — free + premium track, cosmetic-focused rewards, tied to map clears/daily quests.
- **Daily/Weekly Quests** — "clear 3 maps," "defeat 20 commanders," reward soft currency + battle pass XP, drives daily login.

---

## 9. Monetization System

Design goal: **profitable, but stat-power stays earnable for free** (cosmetic/convenience-first monetization to keep long-term retention and avoid pay-to-win backlash on Roblox).

### 9.1 Premium Currency (Robux → in-game gems)
Sold in bundles via Robux developer products. Spent on:
- Cosmetic skins (weapon skins, accessory skins, character outfits) — no stat difference from base gear.
- Loadout preset slots (extra saved loadouts beyond free default).
- Extra character/profile slots (if multi-character supported).
- Ultimate/weapon unlock skips (buy access instantly instead of grinding — grind-skip, not power beyond what's earnable).
- Cosmetic emotes/victory poses for lobby socializing.

### 9.2 Game Pass (one-time purchases)
- **XP Boost Pass** — permanent +% XP gain.
- **Currency Boost Pass** — permanent +% soft currency gain.
- **VIP Pass** — exclusive cosmetic trail/aura + small daily currency bonus + priority queue/party perks.
- **Auto-loot / Extra Inventory Space Pass** — quality-of-life.

### 9.3 Battle Pass (seasonal subscription-style)
- Premium track purchasable with Robux per season.
- Cosmetic rewards, exclusive weapon skins, exclusive ultimate visual effects (VFX-only, not stat).
- Free track available to all players for retention.

### 9.4 Direct Purchases
- Bundled cosmetic sets (themed skins: head+body+arm+leg+weapon skin bundle at a discount vs individual).
- Limited-time/seasonal cosmetic items (rotating shop, FOMO-light — cosmetic only, no power).

### 9.5 Monetization Guardrails
- All Robux-purchasable stat-affecting items must also be earnable through free play (grind path always exists) to stay compliant with Roblox monetization policy and maintain trust/retention.
- Pure power purchases (e.g., "instant +10 levels") avoided or heavily limited to prevent pay-to-win perception common in hack-and-slash live-service fatigue.

---

## 10. Systems Summary (Quick Reference)

| System | Where | Notes |
|---|---|---|
| Shopping | Safe Lobby | Gear, cosmetics, currency |
| Loadout customization | Safe Lobby | Weapon, Ultimate, 4 accessory slots |
| Map select | Safe Lobby | Solo/party, recommended level shown |
| Combat | Battlefield Map | Enemies actively approach on arrival |
| Enemy tiers | Battlefield Map | Foot Soldier → Commander → Mid-Boss → Final Boss |
| XP/Leveling | Both | Earned in map, spent/viewed in lobby |
| Rewards | Battlefield Map | Per-kill + map-clear payout, rank-graded bonus |
| Monetization | Safe Lobby (shop) | Cosmetic/convenience-first, Robux-driven |

---

## 11. Open Questions / Future Scope
- PvP mode: **not planned**, out of scope.
- Guild/clan system for social layer expansion — desired, planned for post-launch if scope allows (clan tag, shared clan chat/lobby space, possibly clan-based leaderboard).
