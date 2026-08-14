return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local BossPhaseFSM = require(ReplicatedStorage.Shared.Formulas.BossPhaseFSM)

	local thresholds = { 0.66, 0.33 }

	describe("BossPhaseFSM.GetPhaseForHPPercent", function()
		it("is phase 1 at full HP", function()
			expect(BossPhaseFSM.GetPhaseForHPPercent(1.0, thresholds)).to.equal(1)
		end)

		it("is phase 2 between the two thresholds", function()
			expect(BossPhaseFSM.GetPhaseForHPPercent(0.5, thresholds)).to.equal(2)
		end)

		it("is phase 3 below the lowest threshold", function()
			expect(BossPhaseFSM.GetPhaseForHPPercent(0.2, thresholds)).to.equal(3)
		end)

		it("boundary values land on the higher phase (<=), tested on both sides", function()
			expect(BossPhaseFSM.GetPhaseForHPPercent(0.66, thresholds)).to.equal(2)
			expect(BossPhaseFSM.GetPhaseForHPPercent(0.67, thresholds)).to.equal(1)
		end)
	end)

	describe("BossPhaseFSM.ShouldAdvancePhase", function()
		it("advances to a strictly higher phase", function()
			expect(BossPhaseFSM.ShouldAdvancePhase(1, 2)).to.equal(true)
		end)

		it("does not re-trigger for the same phase", function()
			expect(BossPhaseFSM.ShouldAdvancePhase(2, 2)).to.equal(false)
		end)

		it("does not go backwards if HP (impossibly) recomputes lower", function()
			expect(BossPhaseFSM.ShouldAdvancePhase(2, 1)).to.equal(false)
		end)

		it("HP oscillating around a threshold never re-triggers once applied", function()
			-- Once phase 2 has been applied, repeated computations landing on
			-- phase 1 or 2 (HP wobbling near the 0.66 boundary) never advance.
			expect(BossPhaseFSM.ShouldAdvancePhase(2, BossPhaseFSM.GetPhaseForHPPercent(0.67, thresholds))).to.equal(false)
			expect(BossPhaseFSM.ShouldAdvancePhase(2, BossPhaseFSM.GetPhaseForHPPercent(0.65, thresholds))).to.equal(false)
		end)
	end)
end
