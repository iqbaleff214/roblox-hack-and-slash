return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CurrencyLedger = require(ReplicatedStorage.Shared.Formulas.CurrencyLedger)

	describe("CurrencyLedger.Remove", function()
		it("rejects removal beyond balance and leaves it unchanged", function()
			local data = { SoftCurrency = 100 }
			local ok = CurrencyLedger.Remove(data, "SoftCurrency", 150)
			expect(ok).to.equal(false)
			expect(data.SoftCurrency).to.equal(100)
		end)

		it("accepts removal within balance and deducts exactly", function()
			local data = { SoftCurrency = 100 }
			local ok = CurrencyLedger.Remove(data, "SoftCurrency", 40)
			expect(ok).to.equal(true)
			expect(data.SoftCurrency).to.equal(60)
		end)

		it("never lets balance go negative", function()
			local data = { SoftCurrency = 0 }
			local ok = CurrencyLedger.Remove(data, "SoftCurrency", 1)
			expect(ok).to.equal(false)
			expect(data.SoftCurrency).to.equal(0)
		end)
	end)

	describe("CurrencyLedger.Add then Remove", function()
		it("nets correctly", function()
			local data = { SoftCurrency = 0 }
			CurrencyLedger.Add(data, "SoftCurrency", 500)
			expect(data.SoftCurrency).to.equal(500)

			local ok = CurrencyLedger.Remove(data, "SoftCurrency", 200)
			expect(ok).to.equal(true)
			expect(data.SoftCurrency).to.equal(300)
		end)
	end)
end
