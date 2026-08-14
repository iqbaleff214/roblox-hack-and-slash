return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local BoostMath = require(ReplicatedStorage.Shared.Formulas.BoostMath)

	describe("BoostMath.ApplyBoost", function()
		it("returns the base amount unchanged at 0% boost", function()
			expect(BoostMath.ApplyBoost(100, 0)).to.equal(100)
		end)

		it("applies a positive boost multiplicatively", function()
			expect(BoostMath.ApplyBoost(100, 0.25)).to.equal(125)
		end)

		it("rounds to the nearest integer", function()
			expect(BoostMath.ApplyBoost(10, 0.25)).to.equal(13) -- 12.5 -> 13
			expect(BoostMath.ApplyBoost(9, 0.25)).to.equal(11) -- 11.25 -> 11
		end)
	end)
end
