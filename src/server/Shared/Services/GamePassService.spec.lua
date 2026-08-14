--[[
	Every real `ProductCatalog` Game Pass `robloxId` is `nil` until T-1401,
	so `UserOwnsGamePassAsync` can never return true in this sandbox — this
	exercises the boost-application code path through the test-only
	`_SetOwnershipForTest` hook (mirrors `EnemyRegistry._ClearAll`). Needs a
	live Player as the profile/grant target.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("GamePassService boost wiring (T-1002)", function()
		it("AwardXP yields base*(1+boostPct) with XPBoostPass owned, base without", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local GamePassService = Knit.GetService("GamePassService")
			local LevelService = Knit.GetService("LevelService")
			local DataService = Knit.GetService("DataService")
			local ProductCatalog = require(ReplicatedStorage.Shared.Data.ProductCatalog)

			local profile = DataService:GetProfile(player)

			GamePassService:_SetOwnershipForTest(player, "XPBoostPass", false)
			local xpBefore = profile.Data.XP
			LevelService:AwardXP(player, 100, "Test")
			expect(profile.Data.XP).to.equal(xpBefore + 100)

			GamePassService:_SetOwnershipForTest(player, "XPBoostPass", true)
			local xpBeforeBoosted = profile.Data.XP
			LevelService:AwardXP(player, 100, "Test")
			local expectedBoosted = math.floor(100 * (1 + ProductCatalog.XPBoostPass.grants.xpBoostPercent) + 0.5)
			expect(profile.Data.XP).to.equal(xpBeforeBoosted + expectedBoosted)

			GamePassService:_SetOwnershipForTest(player, "XPBoostPass", false)
		end)

		it("AddCurrency(SoftCurrency) yields base*(1+boostPct) with CurrencyBoostPass owned, base without", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local GamePassService = Knit.GetService("GamePassService")
			local CurrencyService = Knit.GetService("CurrencyService")
			local DataService = Knit.GetService("DataService")
			local Constants = require(ReplicatedStorage.Shared.Constants)
			local ProductCatalog = require(ReplicatedStorage.Shared.Data.ProductCatalog)

			local profile = DataService:GetProfile(player)

			GamePassService:_SetOwnershipForTest(player, "CurrencyBoostPass", false)
			local before = profile.Data.SoftCurrency
			CurrencyService:AddCurrency(player, Constants.Currency.Soft, 100, "Test")
			expect(profile.Data.SoftCurrency).to.equal(before + 100)

			GamePassService:_SetOwnershipForTest(player, "CurrencyBoostPass", true)
			local beforeBoosted = profile.Data.SoftCurrency
			CurrencyService:AddCurrency(player, Constants.Currency.Soft, 100, "Test")
			local expectedBoosted = math.floor(100 * (1 + ProductCatalog.CurrencyBoostPass.grants.currencyBoostPercent) + 0.5)
			expect(profile.Data.SoftCurrency).to.equal(beforeBoosted + expectedBoosted)

			GamePassService:_SetOwnershipForTest(player, "CurrencyBoostPass", false)
		end)

		it("Currency Boost never applies to PremiumCurrency grants", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local GamePassService = Knit.GetService("GamePassService")
			local CurrencyService = Knit.GetService("CurrencyService")
			local DataService = Knit.GetService("DataService")
			local Constants = require(ReplicatedStorage.Shared.Constants)

			local profile = DataService:GetProfile(player)
			GamePassService:_SetOwnershipForTest(player, "CurrencyBoostPass", true)

			local before = profile.Data.PremiumCurrency
			CurrencyService:AddCurrency(player, Constants.Currency.Premium, 100, "Test")
			expect(profile.Data.PremiumCurrency).to.equal(before + 100)

			GamePassService:_SetOwnershipForTest(player, "CurrencyBoostPass", false)
		end)
	end)
end
