return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local PoiseMath = require(ReplicatedStorage.Shared.Formulas.PoiseMath)

	describe("PoiseMath.ApplyDamage", function()
		it("sums damage correctly across hits", function()
			local poise = 50
			local didBreak
			poise, didBreak = PoiseMath.ApplyDamage(poise, 100, 20)
			expect(poise).to.equal(30)
			expect(didBreak).to.equal(false)
			poise, didBreak = PoiseMath.ApplyDamage(poise, 100, 20)
			expect(poise).to.equal(10)
			expect(didBreak).to.equal(false)
		end)

		it("triggers break exactly on the threshold-crossing hit", function()
			local poise, didBreak = PoiseMath.ApplyDamage(10, 100, 20)
			expect(poise).to.equal(0)
			expect(didBreak).to.equal(true)
		end)

		it("does not re-trigger break on further damage once already at 0", function()
			local poise, didBreak = PoiseMath.ApplyDamage(0, 100, 20)
			expect(poise).to.equal(0)
			expect(didBreak).to.equal(false)
		end)

		it("a poiseMax <= 0 enemy (Foot Soldier) is immune and never breaks", function()
			local poise, didBreak = PoiseMath.ApplyDamage(0, 0, 999)
			expect(poise).to.equal(0)
			expect(didBreak).to.equal(false)
		end)

		it("never goes negative", function()
			local poise = PoiseMath.ApplyDamage(5, 100, 999)
			expect(poise).to.equal(0)
		end)
	end)
end
