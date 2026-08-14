return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local PurchaseLedger = require(ReplicatedStorage.Shared.Formulas.PurchaseLedger)

	describe("PurchaseLedger", function()
		it("a novel purchaseId is not processed until marked", function()
			local processed = {}
			expect(PurchaseLedger.IsProcessed(processed, "abc-123")).to.equal(false)
			PurchaseLedger.MarkProcessed(processed, "abc-123")
			expect(PurchaseLedger.IsProcessed(processed, "abc-123")).to.equal(true)
		end)

		it("marking an already-processed id twice is a safe no-op", function()
			local processed = {}
			PurchaseLedger.MarkProcessed(processed, "abc-123")
			PurchaseLedger.MarkProcessed(processed, "abc-123")
			expect(PurchaseLedger.IsProcessed(processed, "abc-123")).to.equal(true)
		end)

		it("different purchaseIds are tracked independently", function()
			local processed = {}
			PurchaseLedger.MarkProcessed(processed, "abc-123")
			expect(PurchaseLedger.IsProcessed(processed, "xyz-789")).to.equal(false)
		end)
	end)
end
