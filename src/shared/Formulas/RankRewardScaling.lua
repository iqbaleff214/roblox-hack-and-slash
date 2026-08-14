--!strict
--[[
	T-903: pure rank -> bonus-reward scaling. Two independent knobs so a
	better rank both hits harder (amount multiplier, for Currency/
	BattlePassXP bonus-roll kinds) and rolls more times (roll count, giving
	more chances at a rare/legendary Item kind) — "Bonus roll ... scaled by
	rank" (GDD §8.2) read as both, not just one. Balancing-pass placeholder
	values, same caveat as `XPCurve`/`StatMath`/`RankFormula`.
]]

local RankRewardScaling = {}

local AMOUNT_MULTIPLIER_BY_RANK = { D = 1.0, C = 1.15, B = 1.35, A = 1.6, S = 2.0 }
local BONUS_ROLL_COUNT_BY_RANK = { D = 1, C = 1, B = 2, A = 2, S = 3 }

function RankRewardScaling.GetAmountMultiplier(rank: string): number
	return AMOUNT_MULTIPLIER_BY_RANK[rank] or 1.0
end

function RankRewardScaling.GetBonusRollCount(rank: string): number
	return BONUS_ROLL_COUNT_BY_RANK[rank] or 1
end

return RankRewardScaling
