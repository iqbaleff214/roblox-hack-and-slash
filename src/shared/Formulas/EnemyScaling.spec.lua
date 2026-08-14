return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local EnemyScaling = require(ReplicatedStorage.Shared.Formulas.EnemyScaling)

	describe("EnemyScaling.ScaleForPartySize", function()
		it("returns the base value unchanged at partySize=1", function()
			expect(EnemyScaling.ScaleForPartySize(100, 1)).to.equal(100)
		end)

		it("matches the documented curve at partySize=8", function()
			-- 100 * (1 + 7 * 0.15) = 205, within float-precision epsilon
			-- (0.15 isn't exactly representable in binary floating point).
			expect(math.abs(EnemyScaling.ScaleForPartySize(100, 8) - 205) < 1e-9).to.equal(true)
		end)

		it("is monotonically non-decreasing across the full 1-8 range", function()
			local previous = EnemyScaling.ScaleForPartySize(100, 1)
			for partySize = 2, 8 do
				local current = EnemyScaling.ScaleForPartySize(100, partySize)
				expect(current >= previous).to.equal(true)
				previous = current
			end
		end)
	end)
end
