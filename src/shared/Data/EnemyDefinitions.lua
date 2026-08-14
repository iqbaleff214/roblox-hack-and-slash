--!strict
--[[
	Enemy hierarchy catalog (GDD §7). An array of `Types.EnemyDefinition`
	records: the seven Foot Soldier variants (§7.1), Commander (§7.2), and the
	Mid-Boss/Final Boss roster for the first Battlefield map (§7.3/§7.4,
	Okehazama — see MapDefinitions.lua, T-106).

	`behaviorModule` for Foot Soldiers/Commander names a per-variant file under
	`src/server/Battlefield/Support/EnemyBehaviors/<name>.lua` (T-704/T-705,
	Phase 7 — the cross-reference test that those files actually exist lives
	there, not here; note this path differs from the plain
	`src/server/Services/EnemyBehaviors/` originally sketched in TASKS.md,
	since enemy behavior is inherently Battlefield-only under this project's
	actual multi-place split, decided back in T-006/Phase 0). Mid-Bosses/Final
	Bosses share one generic controller each (`MidBossController` /
	`FinalBossController`, T-706/T-707) driven by per-boss moveset data
	rather than one file per boss.

	`poiseMax = 0` for every Foot Soldier — they have no poise/break state and
	just die through combos (GDD §6.4); Commander+ tiers have real poise bars.
]]

local EnemyDefinitions = {
	-- Foot Soldiers (Ashigaru) — GDD §7.1
	{
		id = "Swordsman",
		tier = "FootSoldier",
		hp = 25,
		damage = 5,
		poiseMax = 0,
		behaviorModule = "Swordsman",
		lootTableId = "FootSoldier",
		modelAssetId = nil,
	},
	{
		id = "Spearman",
		tier = "FootSoldier",
		hp = 25,
		damage = 6,
		poiseMax = 0,
		behaviorModule = "Spearman",
		lootTableId = "FootSoldier",
		modelAssetId = nil,
	},
	{
		id = "ShieldBearer",
		tier = "FootSoldier",
		hp = 35,
		damage = 4,
		poiseMax = 0,
		behaviorModule = "ShieldBearer",
		lootTableId = "FootSoldier",
		modelAssetId = nil,
	},
	{
		id = "Thrower",
		tier = "FootSoldier",
		hp = 18,
		damage = 5,
		poiseMax = 0,
		behaviorModule = "Thrower",
		lootTableId = "FootSoldier",
		modelAssetId = nil,
	},
	{
		id = "Bomber",
		tier = "FootSoldier",
		hp = 22,
		damage = 12,
		poiseMax = 0,
		behaviorModule = "Bomber",
		lootTableId = "FootSoldier",
		modelAssetId = nil,
	},
	{
		id = "Swinger",
		tier = "FootSoldier",
		hp = 28,
		damage = 7,
		poiseMax = 0,
		behaviorModule = "Swinger",
		lootTableId = "FootSoldier",
		modelAssetId = nil,
	},
	{
		id = "TreasureCarrier",
		tier = "FootSoldier",
		hp = 15,
		damage = 1,
		poiseMax = 0,
		behaviorModule = "TreasureCarrier",
		lootTableId = "TreasureCarrier",
		modelAssetId = nil,
	},

	-- Commander — GDD §7.2
	{
		id = "Commander",
		tier = "Commander",
		hp = 150,
		damage = 15,
		poiseMax = 50,
		behaviorModule = "Commander",
		lootTableId = "Commander",
		modelAssetId = nil,
	},

	-- Mid-Bosses (Okehazama) — GDD §7.3
	{
		id = "MatsudairaMotoyasu",
		tier = "MidBoss",
		hp = 800,
		damage = 25,
		poiseMax = 150,
		behaviorModule = "MidBossController",
		lootTableId = "MidBoss",
		modelAssetId = nil,
	},
	{
		id = "IioMichihiro",
		tier = "MidBoss",
		hp = 800,
		damage = 25,
		poiseMax = 150,
		behaviorModule = "MidBossController",
		lootTableId = "MidBoss",
		modelAssetId = nil,
	},

	-- Final Boss (Okehazama) — GDD §7.4
	{
		id = "ImagawaYoshimoto",
		tier = "FinalBoss",
		hp = 3000,
		damage = 40,
		poiseMax = 400,
		behaviorModule = "FinalBossController",
		lootTableId = "FinalBoss",
		modelAssetId = nil,
	},
}

return EnemyDefinitions
