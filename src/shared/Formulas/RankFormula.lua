--!strict
--[[
	T-902: pure D-S rank grading from a run's `{comboCount, damageTaken,
	timeElapsedSeconds}` (GDD §8.2, Basara-style rank grading). Party-wide,
	not per-player — `RunStatsService` tracks these three stats for the
	whole Battlefield server instance as one team-performance number, the
	same way "time taken" is inherently a whole-run stat regardless of party
	size; attributing combo count/damage taken per-player would need
	infrastructure this project doesn't have (per-player combo tracking) for
	a grade that's ultimately about the party's clear as a unit.

	Documented weight formula (a balancing-pass placeholder, same caveat as
	`XPCurve`/`StatMath` — not final-tuned values):
		score = comboCount * 10 - damageTaken * 1 - timeElapsedSeconds * 0.5
	Rewards landing more combo hits, taking less damage, and clearing faster.
	Thresholds are inclusive lower bounds, checked highest-first.
]]

local RankFormula = {}

local COMBO_WEIGHT = 10
local DAMAGE_WEIGHT = 1
local TIME_WEIGHT = 0.5

-- Checked in order; the first threshold `score` meets or exceeds wins.
local RANK_THRESHOLDS = {
	{ rank = "S", minScore = 800 },
	{ rank = "A", minScore = 500 },
	{ rank = "B", minScore = 250 },
	{ rank = "C", minScore = 100 },
}
local LOWEST_RANK = "D"

export type RunStats = { comboCount: number, damageTaken: number, timeElapsedSeconds: number }

function RankFormula.ComputeScore(stats: RunStats): number
	return stats.comboCount * COMBO_WEIGHT - stats.damageTaken * DAMAGE_WEIGHT - stats.timeElapsedSeconds * TIME_WEIGHT
end

function RankFormula.ComputeRank(stats: RunStats): string
	local score = RankFormula.ComputeScore(stats)
	for _, entry in RANK_THRESHOLDS do
		if score >= entry.minScore then
			return entry.rank
		end
	end
	return LOWEST_RANK
end

return RankFormula
