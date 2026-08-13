# Game Design Document

**Working Title:** (TBD)
**Genre:** Hack-and-Slash Action RPG
**Platform:** Roblox
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
- **Map Select terminal** — choose battlefield map, view recommended level, party up.
- **Social space** — free-roam, emotes, player housing/guild hall (stretch goal), photo-mode area.
- **Progression board** — displays level, XP bar, currency balances, battle pass progress.
- No enemies, no damage, safe to idle/socialize.

---

## 6. Battlefield Map (Core Gameplay)

### 6.1 Structure
- Large open battlefield, Basara-style: multiple capture points/camps leading toward an enemy stronghold.
- On player arrival, nearby enemy squads immediately notice and advance to engage — aggressive pacing from the start, no downtime.
- Maps are clearable solo or co-op (party of players share the instance, enemies scale with party size).

### 6.2 Objectives
- Clear enemy camps/checkpoints to push toward the stronghold.
- Optional side objectives (rescue an ally officer, destroy siege equipment) for bonus rewards.
- Final objective: defeat the **Final Boss** to clear the map and trigger reward payout.

---

## 7. Enemy System (Basara-style Hierarchy)

Four-tier enemy hierarchy, matching Sengoku Basara's mob structure:

### 7.1 Foot Soldiers (Ashigaru)
- Weakest, spawn in large numbers/waves.
- Simple attack patterns, low HP, meant to be mowed down in combos for power-fantasy feel.
- Primary XP/currency drip-feed source.

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
- Party size cap for co-op instances?
- PvP mode (Basara had versus battles) — future consideration.
- Guild/clan system for social layer expansion.
- Weapon-switching mid-combat (multi-weapon loadout) vs single fixed weapon — TBD based on combo system complexity.
