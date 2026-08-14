return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RankFormula = require(ReplicatedStorage.Shared.Formulas.RankFormula)

	describe("RankFormula.ComputeRank", function()
		local knownCombos = {
			{ stats = { comboCount = 100, damageTaken = 0, timeElapsedSeconds = 0 }, expected = "S" },
			{ stats = { comboCount = 50, damageTaken = 0, timeElapsedSeconds = 0 }, expected = "A" },
			{ stats = { comboCount = 25, damageTaken = 0, timeElapsedSeconds = 0 }, expected = "B" },
			{ stats = { comboCount = 10, damageTaken = 0, timeElapsedSeconds = 0 }, expected = "C" },
			{ stats = { comboCount = 0, damageTaken = 0, timeElapsedSeconds = 0 }, expected = "D" },
			{ stats = { comboCount = 5, damageTaken = 200, timeElapsedSeconds = 600 }, expected = "D" },
		}

		for _, case in knownCombos do
			it(("rates comboCount=%d damageTaken=%d timeElapsedSeconds=%d as %s"):format(
				case.stats.comboCount,
				case.stats.damageTaken,
				case.stats.timeElapsedSeconds,
				case.expected
			), function()
				expect(RankFormula.ComputeRank(case.stats)).to.equal(case.expected)
			end)
		end

		local boundaries = {
			{ minScore = 800, at = "S", below = "A" },
			{ minScore = 500, at = "A", below = "B" },
			{ minScore = 250, at = "B", below = "C" },
			{ minScore = 100, at = "C", below = "D" },
		}

		for _, boundary in boundaries do
			it(("exactly at score %d is %s, one damage point below is %s"):format(boundary.minScore, boundary.at, boundary.below), function()
				local atThreshold = { comboCount = boundary.minScore / 10, damageTaken = 0, timeElapsedSeconds = 0 }
				local belowThreshold = { comboCount = boundary.minScore / 10, damageTaken = 1, timeElapsedSeconds = 0 }
				expect(RankFormula.ComputeRank(atThreshold)).to.equal(boundary.at)
				expect(RankFormula.ComputeRank(belowThreshold)).to.equal(boundary.below)
			end)
		end
	end)
end
