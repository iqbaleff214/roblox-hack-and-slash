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
}

-- Filled in by T-1402 once S-001 creates the real Lobby/Battlefield places.
Constants.PlaceIds = {
	Lobby = nil :: number?,
	Battlefield = nil :: number?,
}

return Constants
