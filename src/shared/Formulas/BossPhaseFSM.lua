--!strict
--[[
	Pure boss phase resolution (T-707). `GetPhaseForHPPercent` is a pure
	function of current HP% — deterministic, not stateful, so it can't
	itself "flicker." The one-way/idempotent guarantee T-707's DoD wants
	("no flicker between phases if HP hovers near a threshold") comes from
	`ShouldAdvancePhase`: `FinalBossController` only ever applies a phase
	change when the freshly-computed phase is strictly greater than the
	last *applied* phase, so HP oscillating across a boundary re-computes
	the same or lower phase repeatedly without re-triggering anything.
]]

local BossPhaseFSM = {}

-- `thresholds` are HP-fraction (0-1) boundaries, e.g. `{0.66, 0.33}` for a
-- 3-phase boss. Order doesn't affect correctness (this just counts how many
-- thresholds `hpPercent` has crossed), but list them descending for
-- readability. Returns a 1-based phase index.
function BossPhaseFSM.GetPhaseForHPPercent(hpPercent: number, thresholds: { number }): number
	local phase = 1
	for _, threshold in thresholds do
		if hpPercent <= threshold then
			phase += 1
		end
	end
	return phase
end

-- One-way: only a strictly higher phase counts as an advance.
function BossPhaseFSM.ShouldAdvancePhase(currentPhase: number, computedPhase: number): boolean
	return computedPhase > currentPhase
end

return BossPhaseFSM
