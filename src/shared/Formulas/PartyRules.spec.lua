return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local PartyRules = require(ReplicatedStorage.Shared.Formulas.PartyRules)

	describe("PartyRules.CanAddMember", function()
		it("allows adding below the cap", function()
			expect(PartyRules.CanAddMember(7, 8)).to.equal(true)
		end)

		it("rejects a 9th member at an 8-cap (full party)", function()
			expect(PartyRules.CanAddMember(8, 8)).to.equal(false)
		end)
	end)

	describe("PartyRules.CanKick", function()
		it("allows the leader to kick a member", function()
			expect(PartyRules.CanKick("Leader", "Leader", "Member")).to.equal(true)
		end)

		it("rejects a non-leader kick attempt", function()
			expect(PartyRules.CanKick("Leader", "Member", "OtherMember")).to.equal(false)
		end)

		it("rejects the leader kicking themselves", function()
			expect(PartyRules.CanKick("Leader", "Leader", "Leader")).to.equal(false)
		end)
	end)
end
