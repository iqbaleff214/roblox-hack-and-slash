--!strict
--[[
	Type-only shared module: the runtime representation of one spawned
	enemy, used by `EnemySpawnService` and every `EnemyBehaviors/*.lua`
	module. Exists purely so this shape isn't duplicated per-file — the
	module itself has no logic, just the exported type.
]]

export type EnemyInstance = {
	id: string,
	definitionId: string,
	tier: string,
	model: Model,
	rootPart: BasePart,
	maxHealth: number,
	health: number,
	damage: number,
	poiseMax: number,
	state: string,
	target: Player?,
	spawnedAt: number,
	-- Variant-specific scratch data (e.g. Bomber's fuse start time, last
	-- attack timestamp) — kept generic so behavior modules don't need the
	-- type extended for every new field they want to track.
	custom: { [string]: any },
}

return {}
