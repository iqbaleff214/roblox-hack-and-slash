return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ThrowerRangeLogic = require(ReplicatedStorage.Shared.Formulas.ThrowerRangeLogic)

	describe("ThrowerRangeLogic.Decide", function()
		it("retreats when the player is closer than the threshold", function()
			expect(ThrowerRangeLogic.Decide(5, 10)).to.equal("Retreat")
		end)

		it("holds and fires when the player is at or beyond the threshold", function()
			expect(ThrowerRangeLogic.Decide(10, 10)).to.equal("HoldAndFire")
			expect(ThrowerRangeLogic.Decide(20, 10)).to.equal("HoldAndFire")
		end)
	end)
end
