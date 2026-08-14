--!strict
--[[
	Pure enemy state machine (T-703). `OnSpawn` always returns `"Seek"` —
	there is no `Idle`/patrol state at all, matching the GDD requirement
	literally ("enemies should approach and attack each player" the instant
	they arrive, GDD §6.1/§7.1). `Dead` is terminal: once an enemy dies, no
	further event moves it out of that state.
]]

export type EnemyState = "Seek" | "Attack" | "Dead"
export type EnemyEvent = "InRange" | "OutOfRange" | "Died"

local EnemyFSM = {}

function EnemyFSM.OnSpawn(): EnemyState
	return "Seek"
end

function EnemyFSM.Transition(currentState: EnemyState, event: EnemyEvent): EnemyState
	if event == "Died" then
		return "Dead"
	end
	if currentState == "Dead" then
		return "Dead"
	end
	if event == "InRange" then
		return "Attack"
	end
	-- event == "OutOfRange"
	return "Seek"
end

return EnemyFSM
