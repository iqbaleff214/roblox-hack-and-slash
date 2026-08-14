return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Cooldown = require(ReplicatedStorage.Shared.Formulas.Cooldown)

	describe("Cooldown.CanUse", function()
		it("allows use when never used before", function()
			expect(Cooldown.CanUse(nil, 4, 100)).to.equal(true)
		end)

		it("rejects use before the cooldown elapses", function()
			expect(Cooldown.CanUse(100, 4, 103)).to.equal(false)
		end)

		it("allows use exactly at the cooldown boundary", function()
			expect(Cooldown.CanUse(100, 4, 104)).to.equal(true)
		end)

		it("allows use well after the cooldown elapses", function()
			expect(Cooldown.CanUse(100, 4, 200)).to.equal(true)
		end)
	end)
end
