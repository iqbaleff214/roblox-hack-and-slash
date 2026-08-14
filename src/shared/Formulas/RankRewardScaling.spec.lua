return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RankRewardScaling = require(ReplicatedStorage.Shared.Formulas.RankRewardScaling)

	describe("RankRewardScaling", function()
		it("increases both amount multiplier and roll count monotonically from D to S", function()
			local ranks = { "D", "C", "B", "A", "S" }
			local lastMultiplier = 0
			local lastRollCount = 0
			for _, rank in ranks do
				local multiplier = RankRewardScaling.GetAmountMultiplier(rank)
				local rollCount = RankRewardScaling.GetBonusRollCount(rank)
				expect(multiplier >= lastMultiplier).to.equal(true)
				expect(rollCount >= lastRollCount).to.equal(true)
				lastMultiplier = multiplier
				lastRollCount = rollCount
			end
		end)

		it("D rank is baseline (multiplier 1.0, roll count 1)", function()
			expect(RankRewardScaling.GetAmountMultiplier("D")).to.equal(1.0)
			expect(RankRewardScaling.GetBonusRollCount("D")).to.equal(1)
		end)

		it("falls back to baseline for an unrecognized rank", function()
			expect(RankRewardScaling.GetAmountMultiplier("Z")).to.equal(1.0)
			expect(RankRewardScaling.GetBonusRollCount("Z")).to.equal(1)
		end)
	end)
end
