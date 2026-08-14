--!strict
--[[
	`t`-library shape checkers for data that crosses a server/client or
	server/DataStore boundary. Each export is `t.strict(t.strictInterface(...))`:
	call it with a value and it throws (via `assert`) on any mismatch — missing
	field, wrong type, or unexpected extra field — instead of returning (ok, err).

	Shapes here mirror the fields already spelled out for their owning task in
	TASKS.md (Profile: T-201, Item: T-101, EnemyDefinition: T-105, MapDefinition:
	T-106, QuestDefinition: T-109, Loadout: T-501/GDD §4.4) so Phase 1+ can fill
	the catalogs in without renaming anything defined here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Packages.t)

local Types = {}

Types.Loadout = t.strict(t.strictInterface({
	weaponId = t.string,
	ultimateId = t.string,
	accessories = t.strictInterface({
		Head = t.optional(t.string),
		Body = t.optional(t.string),
		Arm = t.optional(t.string),
		Leg = t.optional(t.string),
	}),
}))

Types.Profile = t.strict(t.strictInterface({
	version = t.integer,
	Level = t.integer,
	XP = t.number,
	SoftCurrency = t.number,
	PremiumCurrency = t.number,
	OwnedItems = t.table,
	Loadout = t.table,
	LoadoutPresets = t.table,
	QuestProgress = t.table,
	BattlePassProgress = t.table,
	MapStats = t.table,
	Settings = t.table,
}))

local priceShape = t.strictInterface({
	currency = t.string,
	amount = t.number,
})

Types.Item = t.strict(t.strictInterface({
	id = t.string,
	name = t.string,
	slot = t.literal("Head", "Body", "Arm", "Leg"),
	rarity = t.string,
	statBonus = t.number,
	cosmeticOnly = t.boolean,
	price = priceShape,
	meshAssetId = t.optional(t.string),
}))

Types.EnemyDefinition = t.strict(t.strictInterface({
	id = t.string,
	tier = t.literal("FootSoldier", "Commander", "MidBoss", "FinalBoss"),
	hp = t.number,
	damage = t.number,
	poiseMax = t.number,
	behaviorModule = t.string,
	lootTableId = t.string,
	modelAssetId = t.optional(t.string),
}))

Types.MapDefinition = t.strict(t.strictInterface({
	id = t.string,
	displayName = t.string,
	recommendedLevel = t.integer,
	mainRewardItemId = t.string,
	waveConfig = t.table,
	objectiveList = t.table,
	midBossIds = t.table,
	finalBossId = t.string,
	battlefieldPlaceId = t.optional(t.number),
}))

Types.QuestDefinition = t.strict(t.strictInterface({
	id = t.string,
	cadence = t.literal("Daily", "Weekly"),
	goalType = t.string,
	targetCount = t.integer,
	rewards = t.table,
}))

-- Added in Phase 1 (T-102/T-103/T-110) — see this file's header note: stubbed in
-- Phase 0, extended here as the catalogs that need them get filled in.
Types.Weapon = t.strict(t.strictInterface({
	id = t.string,
	name = t.string,
	comboTreeId = t.string,
	baseDamage = t.number,
	rarity = t.string,
	animationIds = t.table,
	price = priceShape,
	-- Added in Phase 5 (T-504) — CharacterAppearanceService needs a weapon
	-- model to weld, same "placeholder until Studio provides it" pattern as
	-- Types.Item.meshAssetId.
	weaponModelAssetId = t.optional(t.string),
}))

Types.Ultimate = t.strict(t.strictInterface({
	id = t.string,
	name = t.string,
	damage = t.number,
	radiusOrShape = t.union(t.number, t.string),
	vfxAssetId = t.optional(t.string),
	price = priceShape,
}))

Types.ProductCatalogEntry = t.strict(t.strictInterface({
	type = t.literal("DevProduct", "GamePass"),
	robloxId = t.optional(t.number),
	grants = t.table,
	cosmeticOnly = t.boolean,
}))

return Types
