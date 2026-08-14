--!strict
--[[
	Pure party-size scaling (T-711) — generic over any base value; used for
	both enemy count-per-wave (T-702, rounded to an integer there) and enemy
	HP/damage (applied at spawn time, T-702). GDD §6.1: "enemies scale with
	party size." Linear with a flat per-extra-member increment, so
	`partySize=1` returns `baseValue` exactly (no scaling for solo play) and
	scaling is strictly monotonic non-decreasing as the party grows. Exact
	rate is a balancing-pass constant, like XPCurve/StatMath.
]]

local EnemyScaling = {}

local SCALE_PER_EXTRA_MEMBER = 0.15

function EnemyScaling.ScaleForPartySize(baseValue: number, partySize: number): number
	assert(partySize >= 1, "partySize must be >= 1")
	return baseValue * (1 + (partySize - 1) * SCALE_PER_EXTRA_MEMBER)
end

return EnemyScaling
