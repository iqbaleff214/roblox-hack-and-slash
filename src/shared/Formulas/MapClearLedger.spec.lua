return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local MapClearLedger = require(ReplicatedStorage.Shared.Formulas.MapClearLedger)

	describe("MapClearLedger.RecordClear", function()
		it("first clear (no existing entry) is a first clear and grants the Main Reward", function()
			local entry, isFirstClear = MapClearLedger.RecordClear(nil)
			expect(isFirstClear).to.equal(true)
			expect(entry.clearCount).to.equal(1)
			expect(entry.mainRewardGranted).to.equal(true)
		end)

		it("second clear (existing entry, already granted) is not a first clear", function()
			local first = MapClearLedger.RecordClear(nil)
			local second, isFirstClear = MapClearLedger.RecordClear(first)
			expect(isFirstClear).to.equal(false)
			expect(second.clearCount).to.equal(2)
			expect(second.mainRewardGranted).to.equal(true)
		end)

		it("is idempotent: calling RecordClear many times never re-flags a first clear after the real first", function()
			local entry = MapClearLedger.RecordClear(nil)
			for _ = 1, 5 do
				local isFirstClear
				entry, isFirstClear = MapClearLedger.RecordClear(entry)
				expect(isFirstClear).to.equal(false)
			end
			expect(entry.clearCount).to.equal(6)
		end)
	end)
end
