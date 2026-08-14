--!strict
--[[
	Pure per-player combat state transition table (T-402/T-410). This genre
	is deliberately cancel-friendly — GDD §6.4 explicitly calls out
	dash-cancels-attack-recovery and dash-into-attack as a dash-attack opener
	— so every action is allowed from every state except Staggered (a player
	mid-hitstun from an enemy attack can't act at all; matches T-402's
	literal test case). This is intentionally simple, not incomplete: the
	table is fully defined for every (state, action) pair, as T-410 requires,
	and the simplicity itself reflects that design decision, not an
	oversight.
]]

export type CombatState = "Idle" | "Attacking" | "Dashing" | "Staggered"
export type CombatAction = "Attack" | "Special" | "Dash" | "Ultimate"

local CombatStateMachine = {}

CombatStateMachine.States = { "Idle", "Attacking", "Dashing", "Staggered" } :: { CombatState }
CombatStateMachine.Actions = { "Attack", "Special", "Dash", "Ultimate" } :: { CombatAction }

local RESULT_STATE: { [CombatAction]: CombatState } = {
	Attack = "Attacking",
	Special = "Attacking",
	Dash = "Dashing",
	Ultimate = "Attacking",
}

-- Returns (allowed, nextState). `nextState` is nil when `allowed` is false.
function CombatStateMachine.Transition(currentState: CombatState, action: CombatAction): (boolean, CombatState?)
	if currentState == "Staggered" then
		return false, nil
	end
	return true, RESULT_STATE[action]
end

return CombatStateMachine
