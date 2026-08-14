return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local BomberDetonation = require(ReplicatedStorage.Shared.Formulas.BomberDetonation)

	describe("BomberDetonation.ShouldDetonate", function()
		it("detonates on proximity, well before the fuse expires", function()
			local should, reason = BomberDetonation.ShouldDetonate(2, 5, 0, 10)
			expect(should).to.equal(true)
			expect(reason).to.equal("Proximity")
		end)

		it("detonates on fuse expiry even if never close enough", function()
			local should, reason = BomberDetonation.ShouldDetonate(50, 5, 10, 10)
			expect(should).to.equal(true)
			expect(reason).to.equal("FuseExpired")
		end)

		it("does not detonate when neither condition is met", function()
			local should = BomberDetonation.ShouldDetonate(50, 5, 3, 10)
			expect(should).to.equal(false)
		end)
	end)
end
