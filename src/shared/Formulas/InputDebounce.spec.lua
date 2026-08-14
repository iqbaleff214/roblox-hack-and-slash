return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local InputDebounce = require(ReplicatedStorage.Shared.Formulas.InputDebounce)

	describe("InputDebounce.ShouldFire", function()
		it("fires on the first press (no prior fire time)", function()
			expect(InputDebounce.ShouldFire(nil, 100, 0.05)).to.equal(true)
		end)

		it("does not double-fire within the debounce interval", function()
			expect(InputDebounce.ShouldFire(100, 100.01, 0.05)).to.equal(false)
		end)

		it("fires again once the debounce interval has elapsed", function()
			expect(InputDebounce.ShouldFire(100, 100.06, 0.05)).to.equal(true)
		end)
	end)
end
