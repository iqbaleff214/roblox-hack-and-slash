--!strict
--[[
	Minimal in-memory registry of live enemies in the current Battlefield
	server instance. T-404 (HitboxService) and future Phase 7 code both need
	"the current list of enemies and where they are" — this is that list.

	Deliberately placed under `src/server/Battlefield/Support/`, NOT
	`src/shared/` — it holds live enemy positions and a direct damage
	callback per entry. If this lived in `src/shared/` it would sync to
	ReplicatedStorage and any client could `require()` it directly, reading
	every enemy's live position (a wallhack/ESP) or calling `takeDamage`
	straight through, bypassing HitboxService's server-authoritative
	geometry/validation entirely. Not a Knit Service (no player ever
	"requests" registry access) — a plain module other Battlefield-only
	server code requires directly.

	Phase 7's EnemySpawnService (T-702) is what actually calls
	Register/Unregister as enemies spawn/die; this module doesn't spawn or
	manage enemies itself, just tracks who's alive and where. Pure/stateful
	but Roblox-API-free (positions are plain `{x,y,z}` tables, `takeDamage`
	is just a function reference), so it's genuinely unit-testable too.

	`UpdatePosition` (Phase 7 addition): enemies move (T-703's Seek state),
	so the position captured at `Register` time goes stale immediately —
	each enemy behavior module calls this every tick instead of re-Registering
	(which would also replace the `takeDamage` closure for no reason).
]]

local EnemyRegistry = {}

export type EnemyEntry = {
	id: string,
	tier: string,
	poiseMax: number,
	position: { x: number, y: number, z: number },
	-- `attacker` (Phase 7 addition) is who dealt the hit, when known — used
	-- to attribute the loot roll on death to whoever landed the kill.
	takeDamage: (amount: number, attacker: Player?) -> (),
	-- Optional (T-704, ShieldBearer): if present, HitboxService consults
	-- this before applying damage — a frontal hit returns false ("blocked").
	-- Absent for every other variant, which is always damageable.
	canBeDamagedFrom: ((attackerPosition: { x: number, y: number, z: number }) -> boolean)?,
}

local entries: { [string]: EnemyEntry } = {}

function EnemyRegistry.Register(entry: EnemyEntry)
	entries[entry.id] = entry
end

function EnemyRegistry.Unregister(enemyId: string)
	entries[enemyId] = nil
end

function EnemyRegistry.UpdatePosition(enemyId: string, position: { x: number, y: number, z: number })
	local entry = entries[enemyId]
	if entry then
		entry.position = position
	end
end

function EnemyRegistry.Get(enemyId: string): EnemyEntry?
	return entries[enemyId]
end

function EnemyRegistry.GetAll(): { EnemyEntry }
	local all = {}
	for _, entry in entries do
		table.insert(all, entry)
	end
	return all
end

-- Test-only escape hatch (used by EnemyRegistry.spec.lua to avoid cross-test
-- pollution of the shared module-level table); production code never calls
-- this.
function EnemyRegistry._ClearAll()
	entries = {}
end

return EnemyRegistry
