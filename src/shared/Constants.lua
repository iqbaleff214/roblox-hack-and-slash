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

-- Filled in by T-1402 once S-001 creates the real Lobby/Battlefield places.
Constants.PlaceIds = {
	Lobby = nil :: number?,
	Battlefield = nil :: number?,
}

return Constants
