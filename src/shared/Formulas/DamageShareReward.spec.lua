return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local DamageShareReward = require(ReplicatedStorage.Shared.Formulas.DamageShareReward)

	describe("DamageShareReward.Split", function()
		it("gives the sole contributor the full amount (solo kill)", function()
			local result = DamageShareReward.Split(10, { { id = "A", damage = 25 } })
			expect(result.A).to.equal(10)
		end)

		it("splits evenly for equal damage contributions", function()
			local result = DamageShareReward.Split(10, { { id = "A", damage = 5 }, { id = "B", damage = 5 } })
			expect(result.A).to.equal(5)
			expect(result.B).to.equal(5)
		end)

		it("splits proportionally and the largest remainder gets the rounding leftover", function()
			local result = DamageShareReward.Split(10, { { id = "A", damage = 2 }, { id = "B", damage = 1 } })
			expect(result.A).to.equal(7)
			expect(result.B).to.equal(3)
			expect(result.A + result.B).to.equal(10)
		end)

		it("always sums to exactly totalAmount across many contributor counts (no reward inflation)", function()
			for contributorCount = 1, 8 do
				local contributions = {}
				for i = 1, contributorCount do
					table.insert(contributions, { id = tostring(i), damage = i * 7 % 13 + 1 })
				end
				local result = DamageShareReward.Split(37, contributions)
				local sum = 0
				for _, amount in result do
					sum += amount
				end
				expect(sum).to.equal(37)
			end
		end)

		it("returns an empty split for a zero or negative totalAmount", function()
			local result = DamageShareReward.Split(0, { { id = "A", damage = 10 } })
			expect(next(result)).to.equal(nil)
		end)

		it("returns an empty split for no contributions", function()
			local result = DamageShareReward.Split(10, {})
			expect(next(result)).to.equal(nil)
		end)
	end)
end
