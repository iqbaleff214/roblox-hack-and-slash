return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UltimateGauge = require(ReplicatedStorage.Shared.Formulas.UltimateGauge)

	describe("UltimateGauge.Add", function()
		it("sums correctly", function()
			expect(UltimateGauge.Add(0, 30)).to.equal(30)
			expect(UltimateGauge.Add(30, 40)).to.equal(70)
		end)

		it("clamps at the max (100)", function()
			expect(UltimateGauge.Add(90, 50)).to.equal(100)
		end)

		it("clamps at 0 for a negative result", function()
			expect(UltimateGauge.Add(10, -50)).to.equal(0)
		end)
	end)

	describe("UltimateGauge.CanUseUltimate", function()
		it("rejects at 99", function()
			expect(UltimateGauge.CanUseUltimate(99)).to.equal(false)
		end)

		it("accepts at exactly 100", function()
			expect(UltimateGauge.CanUseUltimate(100)).to.equal(true)
		end)
	end)
end
