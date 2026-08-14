return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RateLimiter = require(ReplicatedStorage.Shared.Formulas.RateLimiter)

	describe("RateLimiter.TryConsume", function()
		it("allows a burst under the cap", function()
			local timestamps = {}
			for _ = 1, 5 do
				expect(RateLimiter.TryConsume(timestamps, 5, 1, 100)).to.equal(true)
			end
			expect(#timestamps).to.equal(5)
		end)

		it("rejects a burst over the cap within the same window", function()
			local timestamps = {}
			for _ = 1, 5 do
				RateLimiter.TryConsume(timestamps, 5, 1, 100)
			end
			expect(RateLimiter.TryConsume(timestamps, 5, 1, 100.5)).to.equal(false)
		end)

		it("allows calls again once old timestamps age out of the window", function()
			local timestamps = {}
			for _ = 1, 5 do
				RateLimiter.TryConsume(timestamps, 5, 1, 100)
			end
			expect(RateLimiter.TryConsume(timestamps, 5, 1, 101.5)).to.equal(true)
		end)

		it("legitimate play spaced out over time is never blocked", function()
			local timestamps = {}
			for i = 1, 20 do
				expect(RateLimiter.TryConsume(timestamps, 5, 1, i * 1.0)).to.equal(true)
			end
		end)
	end)
end
