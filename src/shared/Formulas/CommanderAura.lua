--!strict
--[[
	Pure aura-radius check (T-705 — GDD §7.2: buffs nearby Foot Soldiers
	while alive). `CommanderBehavior` calls `GetBuffedIds` every tick to
	decide who's currently in range; because it's a pure function of
	current positions (not a stateful "buff applied" flag), the buff
	disappears the instant the Commander stops being queried — which is
	exactly what "no lingering buff after death" (T-705's DoD) needs: once
	the Commander is removed from the enemy registry, nothing calls this for
	it anymore, same tick.
]]

export type Position = { x: number, y: number, z: number }

local CommanderAura = {}

local function distance(a: Position, b: Position): number
	local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function CommanderAura.IsInRange(commanderPosition: Position, candidatePosition: Position, radius: number): boolean
	return distance(commanderPosition, candidatePosition) <= radius
end

function CommanderAura.GetBuffedIds(
	commanderPosition: Position,
	candidates: { { id: string, position: Position } },
	radius: number
): { string }
	local buffed = {}
	for _, candidate in candidates do
		if CommanderAura.IsInRange(commanderPosition, candidate.position, radius) then
			table.insert(buffed, candidate.id)
		end
	end
	return buffed
end

return CommanderAura
