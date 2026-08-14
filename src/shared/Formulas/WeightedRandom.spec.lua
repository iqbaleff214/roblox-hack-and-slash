return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local WeightedRandom = require(ReplicatedStorage.Shared.Formulas.WeightedRandom)

	describe("WeightedRandom.Pick", function()
		local entries = {
			{ weight = 0.5, id = "A" },
			{ weight = 0.3, id = "B" },
			{ weight = 0.2, id = "C" },
		}

		it("picks the first entry whose cumulative weight exceeds the roll", function()
			expect(WeightedRandom.Pick(entries, 0.0).id).to.equal("A")
			expect(WeightedRandom.Pick(entries, 0.49).id).to.equal("A")
			expect(WeightedRandom.Pick(entries, 0.5).id).to.equal("B")
			expect(WeightedRandom.Pick(entries, 0.79).id).to.equal("B")
			expect(WeightedRandom.Pick(entries, 0.8).id).to.equal("C")
			expect(WeightedRandom.Pick(entries, 0.99).id).to.equal("C")
		end)

		it("works with weights that don't sum to 1 by normalizing against their total", function()
			local unnormalized = {
				{ weight = 1, id = "A" },
				{ weight = 3, id = "B" },
			}
			expect(WeightedRandom.Pick(unnormalized, 0.0).id).to.equal("A")
			expect(WeightedRandom.Pick(unnormalized, 0.99).id).to.equal("B")
		end)
	end)
end
