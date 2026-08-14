--[[
	The idempotency decision itself is already genuinely verified in
	`PurchaseLedger.spec.lua` (T-1001's own pure formula, real `lune`
	execution). Every real `ProductCatalog.robloxId` is `nil` until T-1401,
	so the normal `ProcessReceipt` path is unreachable here without the
	test-only `_RegisterSkuForTest` hook (mirrors `EnemyRegistry._ClearAll`)
	— this exercises the actual grant + idempotency code path through it.
	Needs a live Player as the profile/grant target.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("MonetizationService", function()
		it("returns NotProcessedYet for a player not currently in this server, without throwing", function()
			local MonetizationService = Knit.GetService("MonetizationService")
			local decision
			expect(function()
				decision = MonetizationService:ProcessReceipt({ PlayerId = -1, ProductId = -999, PurchaseId = "nonexistent" })
			end).never.to.throw()
			expect(decision).to.equal(Enum.ProductPurchaseDecision.NotProcessedYet)
		end)

		it("returns NotProcessedYet for an unrecognized ProductId on a real player, without throwing", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local MonetizationService = Knit.GetService("MonetizationService")
			local decision
			expect(function()
				decision = MonetizationService:ProcessReceipt({ PlayerId = player.UserId, ProductId = -999, PurchaseId = "nonexistent-product" })
			end).never.to.throw()
			expect(decision).to.equal(Enum.ProductPurchaseDecision.NotProcessedYet)
		end)

		it("grants a novel receipt exactly once; replaying it grants nothing more but still confirms", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local MonetizationService = Knit.GetService("MonetizationService")
			local DataService = Knit.GetService("DataService")

			local fakeRobloxId = 424242
			MonetizationService:_RegisterSkuForTest(fakeRobloxId, "Gems100")

			local profile = DataService:GetProfile(player)
			local premiumBefore = profile.Data.PremiumCurrency
			local purchaseId = "test-purchase-" .. tostring(os.clock())
			local receiptInfo = { PlayerId = player.UserId, ProductId = fakeRobloxId, PurchaseId = purchaseId }

			local first = MonetizationService:ProcessReceipt(receiptInfo)
			expect(first).to.equal(Enum.ProductPurchaseDecision.PurchaseGranted)
			expect(profile.Data.PremiumCurrency).to.equal(premiumBefore + 100)

			local second = MonetizationService:ProcessReceipt(receiptInfo)
			expect(second).to.equal(Enum.ProductPurchaseDecision.PurchaseGranted)
			expect(profile.Data.PremiumCurrency).to.equal(premiumBefore + 100) -- not granted twice
		end)

		it("T-1006: LoadoutPresetSlot receipt increments the cap exactly once, even if replayed", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local MonetizationService = Knit.GetService("MonetizationService")
			local DataService = Knit.GetService("DataService")
			local LoadoutService = Knit.GetService("LoadoutService")

			local fakeRobloxId = 424243
			MonetizationService:_RegisterSkuForTest(fakeRobloxId, "LoadoutPresetSlot")

			local profile = DataService:GetProfile(player)
			local capBefore = LoadoutService:GetPresetCap(player)
			local purchaseId = "test-preset-purchase-" .. tostring(os.clock())
			local receiptInfo = { PlayerId = player.UserId, ProductId = fakeRobloxId, PurchaseId = purchaseId }

			MonetizationService:ProcessReceipt(receiptInfo)
			expect(LoadoutService:GetPresetCap(player)).to.equal(capBefore + 1)

			-- Replayed receipt (Roblox retry semantics): cap must not stack.
			MonetizationService:ProcessReceipt(receiptInfo)
			expect(LoadoutService:GetPresetCap(player)).to.equal(capBefore + 1)

			profile.Data.Settings.PurchasedLoadoutPresetSlots = (profile.Data.Settings.PurchasedLoadoutPresetSlots or 1) - 1
		end)
	end)
end
