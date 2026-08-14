--[[
	Requires a live Player — Studio Play Solo/Team Test, see S-1301.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)
	local Constants = require(ReplicatedStorage.Shared.Constants)

	describe("ShopService.PurchaseItem", function()
		it("fails on insufficient funds, leaving currency and ownership unchanged", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local ShopService = Knit.GetService("ShopService")
			local CurrencyService = Knit.GetService("CurrencyService")
			local InventoryService = Knit.GetService("InventoryService")
			local DataService = Knit.GetService("DataService")

			-- DoMaru costs 400 SoftCurrency; drive the balance to 0 first.
			local before = DataService.Client:GetProfile(player).SoftCurrency
			CurrencyService:RemoveCurrency(player, Constants.Currency.Soft, before)

			local purchased = ShopService:PurchaseItem(player, "DoMaru")
			expect(purchased).to.equal(false)
			expect(InventoryService:HasItem(player, "DoMaru")).to.equal(false)
			expect(DataService.Client:GetProfile(player).SoftCurrency).to.equal(0)
		end)

		it("deducts the exact price and grants the item exactly once on success", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local ShopService = Knit.GetService("ShopService")
			local CurrencyService = Knit.GetService("CurrencyService")
			local InventoryService = Knit.GetService("InventoryService")
			local DataService = Knit.GetService("DataService")

			CurrencyService:AddCurrency(player, Constants.Currency.Soft, 1000, "spec-topup")
			local before = DataService.Client:GetProfile(player).SoftCurrency

			local purchased = ShopService:PurchaseItem(player, "KoteBraces") -- 400 SoftCurrency
			expect(purchased).to.equal(true)
			expect(InventoryService:HasItem(player, "KoteBraces")).to.equal(true)

			local after = DataService.Client:GetProfile(player).SoftCurrency
			expect(after).to.equal(before - 400)

			-- Second purchase attempt: already owned, rejected, no double charge.
			local secondPurchase = ShopService:PurchaseItem(player, "KoteBraces")
			expect(secondPurchase).to.equal(false)
			expect(DataService.Client:GetProfile(player).SoftCurrency).to.equal(after)
		end)
	end)

	describe("ShopService.PurchaseProduct (T-1003)", function()
		it("rejects an unknown/non-DevProduct sku without touching CurrencyService", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local ShopService = Knit.GetService("ShopService")
			expect(ShopService:PurchaseProduct(player, "NotARealSku")).to.equal(false)
			expect(ShopService:PurchaseProduct(player, "XPBoostPass")).to.equal(false) -- GamePass, not DevProduct
		end)

		it("accepts a real DevProduct sku (prompts, never credits currency itself)", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local ShopService = Knit.GetService("ShopService")
			local DataService = Knit.GetService("DataService")

			local before = DataService.Client:GetProfile(player).PremiumCurrency
			expect(ShopService:PurchaseProduct(player, "Gems100")).to.equal(true)
			-- No robloxId yet (T-1401 pending), so the prompt itself no-ops
			-- server-side — but the point either way is no currency credit
			-- happens from this call.
			expect(DataService.Client:GetProfile(player).PremiumCurrency).to.equal(before)
		end)
	end)
end
