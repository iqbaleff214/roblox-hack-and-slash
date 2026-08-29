--!strict
--[[
	Single source of truth for cross-module string constants: the CollectionService
	tag/attribute names that form the script <-> Studio naming contract (see
	TASKS.md / STUDIO_TASKS.md), the Comm/Knit remote folder name, currency ids,
	and per-place PlaceIds. Every other module should pull these from here rather
	than repeating the raw strings.
]]

local Constants = {}

Constants.RemoteFolderName = "HackAndSlashRemotes"

-- DataStore name for ProfileService (T-201). Schema changes go through
-- ProfileMigrations.lua (T-205), not a store-name bump.
Constants.ProfileStoreName = "PlayerProfile"

-- Map-level gate tolerance (T-303): a player can enter down to
-- `recommendedLevel - MapLevelTolerance`.
Constants.MapLevelTolerance = 3

Constants.Currency = {
	Soft = "SoftCurrency",
	Premium = "PremiumCurrency",
}

-- CollectionService tag names. Must match STUDIO_TASKS.md's placement tasks exactly.
Constants.Tags = {
	MapPortal = "MapPortal",
	ShopKiosk = "ShopKiosk",
	ShopZone = "ShopZone",
	LoadoutStation = "LoadoutStation",
	EnemySpawnPoint = "EnemySpawnPoint",
	DestructibleBox = "DestructibleBox",
	CampPoint = "CampPoint",
	ObjectivePoint = "ObjectivePoint",
	MidBossSpawn = "MidBossSpawn",
	FinalBossSpawn = "FinalBossSpawn",
	FinalBossArenaGate = "FinalBossArenaGate",

	-- Script <-> script contract (not a Studio placement task): applied at
	-- runtime by Phase 7's EnemySpawnService to every enemy Model it spawns,
	-- so client-side systems (T-409 TargetLockController) can find live
	-- enemies via CollectionService without a privileged server data channel.
	Enemy = "Enemy",
}

-- Instance:GetAttribute() keys used alongside the tags above.
Constants.Attributes = {
	MapId = "MapId",
	ShopId = "ShopId",
	SpawnGroupId = "SpawnGroupId",
	LootTableId = "LootTableId",
	RandomPool = "RandomPool",
	ObjectiveId = "ObjectiveId",
	ObjectiveType = "ObjectiveType",
	MidBossId = "MidBossId",

	-- Paired with Tags.Enemy.
	EnemyId = "EnemyId",
	EnemyTier = "EnemyTier",
}

-- Party tuning (T-604, GDD §6.1).
Constants.Party = {
	MaxSize = 8,
}

-- Loadout tuning (Phase 5).
Constants.Loadout = {
	-- Additional slots are purchased via ProductCatalog.LoadoutPresetSlot
	-- (T-1006) and tracked as profile.Settings.PurchasedLoadoutPresetSlots.
	FreePresetSlots = 1,
}

-- Combat tuning constants (Phase 4). Exact values are a balancing-pass
-- concern like XPCurve/StatMath — these are reasonable placeholders.
Constants.Combat = {
	InputDebounceSeconds = 0.05,
	RecoveryWindowSeconds = 1.5,

	DashSpeed = 50,
	DashIFrameSeconds = 0.3,

	SpecialCooldownSeconds = 4,
	SpecialDamageMult = 1.5,
	SpecialPoiseDamage = 25,

	UltimateGaugeMax = 100,
	UltimateGaugeGainPerDamageDealt = 0.5,
	UltimateGaugeGainPerDamageTaken = 1.0,

	PoiseBreakWindowSeconds = 3,

	RateLimitMaxPerSecond = 10,
	RateLimitWindowSeconds = 1,
}

-- Battlefield/enemy tuning (Phase 7).
Constants.Battlefield = {
	EnemyMoveSpeed = 12,
	BaselineMeleeAttackRange = 6, -- Swordsman, ShieldBearer
	SpearmanAttackRange = 8,
	SwingerAttackRange = 7,
	CommanderAttackRange = 7,
	FootSoldierAttackCooldownSeconds = 1.5,

	ThrowerRetreatThreshold = 12,
	ThrowerFireRange = 24,
	ThrowerFireCooldownSeconds = 2,

	BomberProximityThreshold = 4,
	BomberFuseDurationSeconds = 4,

	TreasureCarrierMoveSpeed = 9,

	-- T-705: Commander aura (GDD §7.2 — "damage/defense aura"; implemented
	-- as a damage buff only, see CommanderBehavior.lua's header for why).
	CommanderAuraRadius = 15,
	CommanderAuraDamageMultiplier = 1.3,

	-- T-706/707: boss phase thresholds (HP-fraction boundaries, descending).
	MidBossPhaseThresholds = { 0.5 },
	FinalBossPhaseThresholds = { 0.66, 0.33 },
	BossAttackCooldownSeconds = 2.5,

	-- T-708: fraction of `RandomPool = true` boxes selected per server
	-- instance (rounded up, minimum 1 if any pool boxes exist) — GDD §6.3's
	-- "a few random spawn points per playthrough," not all-or-nothing.
	DestructibleBoxRandomPoolFraction = 0.5,
}

-- T-901: flat per-kill XP/currency baseline per enemy tier (GDD §8.1 —
-- "small"/"moderate"/"larger" scale up the tiers). Split proportionally by
-- damage-contribution across every player who landed a hit (see
-- `DamageShareReward.lua`), not killer-only, for co-op fairness. No
-- `FinalBoss` entry on purpose — GDD §8.1 only lists Foot Soldier/Commander/
-- Mid-Boss; the Final Boss's reward is the map-clear payout (§8.2) instead,
-- since its death and the map clear are the same event — a separate flat
-- per-kill grant on top would double-pay it.
Constants.EnemyRewards = {
	FootSoldier = { xp = 5, currency = 2 },
	Commander = { xp = 25, currency = 10 },
	MidBoss = { xp = 150, currency = 75 },
}

-- T-905: seasonal Battle Pass tuning. `CurrentSeasonId` must match a real
-- `ProductCatalog` key suffix (`BattlePassPremium_<CurrentSeasonId>`, T-1005)
-- so `BattlePassService`'s eventual real ownership check (T-1002) can look
-- up the right product.
Constants.BattlePass = {
	CurrentSeasonId = "Season1",
	XPPerQuestCompletion = 20,
	XPPerMapClear = 50,
}

-- T-1101: platform enum, string-valued (matches `PlatformDetection.Platform`)
-- so callers get typo-safety the same way `Constants.Currency` gives
-- `CurrencyService` callers typo-safety for "SoftCurrency"/"PremiumCurrency".
Constants.Platform = {
	Desktop = "Desktop",
	Console = "Console",
	Mobile = "Mobile",
	Tablet = "Tablet",
}

-- Cross-file UI tuning (T-1102/T-1104): `TouchHeavyHoldSeconds` is read by
-- `TouchControlsUIController` (tap-vs-hold on the on-screen Attack button,
-- mirroring desktop's M1-tap/M2-hold split) and documented here rather than
-- inline since it's the touch equivalent of a desktop input-feel constant.
Constants.UI = {
	TouchHeavyHoldSeconds = 0.3,
}

-- Filled in by T-1402 once S-001 creates the real Lobby/Battlefield places.
Constants.PlaceIds = {
	Lobby = 128334109866704,
	Battlefield = nil :: number?,
}

return Constants
