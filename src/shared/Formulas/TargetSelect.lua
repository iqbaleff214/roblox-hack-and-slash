--!strict
--[[
	Pure target selection (T-409): nearest-enemy by default, with a
	named-enemy (Mid-Boss/Final Boss) priority pool per GDD §6.4 ("Important
	for tracking Commanders/Mid-Boss/Final Boss in large crowds"). Plain
	`{x,y,z}` positions, not Vector3 — dependency-free like HitboxGeometry.

	`previousTargetId` biases toward keeping the current lock when it's still
	tied for nearest, so equally-close candidates don't flicker the lock
	frame to frame; ties are otherwise broken deterministically by id string
	so selection is reproducible.
]]

export type Position = { x: number, y: number, z: number }
export type EnemyCandidate = { id: string, tier: string, position: Position }

local TargetSelect = {}

local PRIORITY_TIERS: { [string]: boolean } = { MidBoss = true, FinalBoss = true }

local function distance(a: Position, b: Position): number
	local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function TargetSelect.SelectTarget(
	playerPosition: Position,
	enemies: { EnemyCandidate },
	previousTargetId: string?
): string?
	if #enemies == 0 then
		return nil
	end

	local pool = {}
	for _, enemy in enemies do
		if PRIORITY_TIERS[enemy.tier] then
			table.insert(pool, enemy)
		end
	end
	if #pool == 0 then
		pool = enemies
	end

	local best: EnemyCandidate? = nil
	local bestDistance = math.huge
	local previousInPool: EnemyCandidate? = nil

	for _, enemy in pool do
		if enemy.id == previousTargetId then
			previousInPool = enemy
		end

		local d = distance(playerPosition, enemy.position)
		if d < bestDistance or (d == bestDistance and best ~= nil and enemy.id < (best :: EnemyCandidate).id) then
			bestDistance = d
			best = enemy
		end
	end

	if previousInPool and distance(playerPosition, previousInPool.position) == bestDistance then
		return previousInPool.id
	end

	return if best then best.id else nil
end

return TargetSelect
