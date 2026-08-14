return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local DestructibleBoxPool = require(ReplicatedStorage.Shared.Formulas.DestructibleBoxPool)

	describe("DestructibleBoxPool.SelectSubset", function()
		it("selects exactly `count` ids from the pool", function()
			local candidates = { "A", "B", "C", "D", "E" }
			local selected = DestructibleBoxPool.SelectSubset(candidates, 2, { 0.1, 0.9, 0.3, 0.7 })
			expect(#selected).to.equal(2)
		end)

		it("never selects more than the pool actually has", function()
			local candidates = { "A", "B" }
			local selected = DestructibleBoxPool.SelectSubset(candidates, 5, { 0.5 })
			expect(#selected).to.equal(2)
		end)

		it("only ever returns ids that were in the candidate pool", function()
			local candidates = { "A", "B", "C", "D" }
			local selected = DestructibleBoxPool.SelectSubset(candidates, 2, { 0.2, 0.8, 0.4 })
			for _, id in selected do
				local found = false
				for _, candidate in candidates do
					if candidate == id then
						found = true
					end
				end
				expect(found).to.equal(true)
			end
		end)

		it("distributes selection roughly evenly across ~2000 simulated instances", function()
			-- Each simulated instance needs *multiple* random draws (one per
			-- Fisher-Yates step) consumed in sequence. A per-step formula
			-- recomputed from (instance, step) — e.g. a golden-ratio Weyl
			-- sequence keyed that way — turned out to correlate badly across
			-- steps within the same instance (verified: swapping in real
			-- math.random() made the very same distribution uniform, so the
			-- bias was in the test's number generator, not SelectSubset).
			-- A seeded LCG consumed as one continuous stream avoids that.
			local state = 42
			local function nextRandom(): number
				state = (state * 16807) % 2147483647
				return state / 2147483647
			end

			local candidates = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J" }
			local selectCount = 3
			local sampleCount = 2000
			local appearances = {}
			for _, id in candidates do
				appearances[id] = 0
			end

			for _ = 1, sampleCount do
				local randomValues = {}
				for _ = 1, #candidates - 1 do
					table.insert(randomValues, nextRandom())
				end

				local selected = DestructibleBoxPool.SelectSubset(candidates, selectCount, randomValues)
				for _, id in selected do
					appearances[id] += 1
				end
			end

			local expectedRatio = selectCount / #candidates
			for _, id in candidates do
				local actualRatio = appearances[id] / sampleCount
				expect(math.abs(actualRatio - expectedRatio) < 0.05).to.equal(true)
			end
		end)
	end)
end
