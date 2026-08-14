--[[
	Core balance-check/idempotency rules are unit-tested standalone in
	CurrencyLedger.spec.lua (no Player/Studio needed). This spec covers the
	thin Knit-wrapper integration and requires a live Player — Studio Play
	Solo/Team Test, see S-1301.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)
	local Constants = require(ReplicatedStorage.Shared.Constants)

	describe("CurrencyService", function()
		it("exposes a Client.CurrencyChanged signal", function()
			local CurrencyService = Knit.GetService("CurrencyService")
			expect(CurrencyService.Client.CurrencyChanged).to.be.ok()
		end)

		it("AddCurrency then RemoveCurrency nets correctly for a live player", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local CurrencyService = Knit.GetService("CurrencyService")
			local DataService = Knit.GetService("DataService")

			local before = DataService.Client:GetProfile(player).SoftCurrency
			CurrencyService:AddCurrency(player, Constants.Currency.Soft, 500, "spec")
			local afterAdd = DataService.Client:GetProfile(player).SoftCurrency
			expect(afterAdd).to.equal(before + 500)

			local removed = CurrencyService:RemoveCurrency(player, Constants.Currency.Soft, 200)
			expect(removed).to.equal(true)
			local afterRemove = DataService.Client:GetProfile(player).SoftCurrency
			expect(afterRemove).to.equal(before + 300)
		end)

		it("rejects RemoveCurrency beyond balance for a live player", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local CurrencyService = Knit.GetService("CurrencyService")
			local DataService = Knit.GetService("DataService")

			local before = DataService.Client:GetProfile(player).SoftCurrency
			local removed = CurrencyService:RemoveCurrency(player, Constants.Currency.Soft, before + 1000000)
			expect(removed).to.equal(false)
			local after = DataService.Client:GetProfile(player).SoftCurrency
			expect(after).to.equal(before)
		end)
	end)
end
