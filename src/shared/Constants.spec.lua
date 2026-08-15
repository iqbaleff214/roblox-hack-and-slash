return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Constants = require(ReplicatedStorage.Shared.Constants)

	describe("Constants.Tags", function()
		-- Mirrors the naming-contract table in TASKS.md / STUDIO_TASKS.md exactly.
		local expectedTags = {
			"MapPortal",
			"ShopKiosk",
			"LoadoutStation",
			"EnemySpawnPoint",
			"DestructibleBox",
			"CampPoint",
			"ObjectivePoint",
			"MidBossSpawn",
			"FinalBossSpawn",
			"FinalBossArenaGate",
			"Enemy",
		}

		for _, tagKey in expectedTags do
			it(("defines %s"):format(tagKey), function()
				expect(Constants.Tags[tagKey]).to.be.a("string")
				expect(Constants.Tags[tagKey]).to.equal(tagKey)
			end)
		end
	end)

	describe("Constants.Attributes", function()
		local expectedAttributes = {
			"MapId",
			"ShopId",
			"SpawnGroupId",
			"LootTableId",
			"RandomPool",
			"ObjectiveId",
			"ObjectiveType",
			"MidBossId",
			"EnemyId",
			"EnemyTier",
		}

		for _, attrKey in expectedAttributes do
			it(("defines %s"):format(attrKey), function()
				expect(Constants.Attributes[attrKey]).to.be.a("string")
				expect(Constants.Attributes[attrKey]).to.equal(attrKey)
			end)
		end
	end)

	describe("Constants.Currency", function()
		it("defines Soft and Premium currency ids", function()
			expect(Constants.Currency.Soft).to.equal("SoftCurrency")
			expect(Constants.Currency.Premium).to.equal("PremiumCurrency")
		end)
	end)

	describe("Constants.ProfileStoreName", function()
		it("is a non-empty string", function()
			expect(Constants.ProfileStoreName).to.be.a("string")
			expect(#Constants.ProfileStoreName > 0).to.equal(true)
		end)
	end)

	describe("Constants.MapLevelTolerance", function()
		it("is a non-negative number", function()
			expect(Constants.MapLevelTolerance).to.be.a("number")
			expect(Constants.MapLevelTolerance >= 0).to.equal(true)
		end)
	end)

	describe("Constants.Party", function()
		it("defines MaxSize matching GDD §6.1's 8-player cap", function()
			expect(Constants.Party.MaxSize).to.equal(8)
		end)
	end)

	describe("Constants.Loadout", function()
		it("defines a positive FreePresetSlots", function()
			expect(Constants.Loadout.FreePresetSlots).to.be.a("number")
			expect(Constants.Loadout.FreePresetSlots > 0).to.equal(true)
		end)
	end)

	describe("Constants.Combat", function()
		local expectedKeys = {
			"InputDebounceSeconds",
			"RecoveryWindowSeconds",
			"DashSpeed",
			"DashIFrameSeconds",
			"SpecialCooldownSeconds",
			"SpecialDamageMult",
			"SpecialPoiseDamage",
			"UltimateGaugeMax",
			"UltimateGaugeGainPerDamageDealt",
			"UltimateGaugeGainPerDamageTaken",
			"PoiseBreakWindowSeconds",
			"RateLimitMaxPerSecond",
			"RateLimitWindowSeconds",
		}

		for _, key in expectedKeys do
			it(("defines a positive number for %s"):format(key), function()
				expect(Constants.Combat[key]).to.be.a("number")
				expect(Constants.Combat[key] > 0).to.equal(true)
			end)
		end
	end)

	describe("Constants.Battlefield", function()
		local expectedNumberKeys = {
			"EnemyMoveSpeed",
			"BaselineMeleeAttackRange",
			"SpearmanAttackRange",
			"SwingerAttackRange",
			"CommanderAttackRange",
			"FootSoldierAttackCooldownSeconds",
			"ThrowerRetreatThreshold",
			"ThrowerFireRange",
			"ThrowerFireCooldownSeconds",
			"BomberProximityThreshold",
			"BomberFuseDurationSeconds",
			"TreasureCarrierMoveSpeed",
			"CommanderAuraRadius",
			"CommanderAuraDamageMultiplier",
			"BossAttackCooldownSeconds",
			"DestructibleBoxRandomPoolFraction",
		}

		for _, key in expectedNumberKeys do
			it(("defines a positive number for %s"):format(key), function()
				expect(Constants.Battlefield[key]).to.be.a("number")
				expect(Constants.Battlefield[key] > 0).to.equal(true)
			end)
		end

		it("defines non-empty, descending phase threshold lists", function()
			expect(#Constants.Battlefield.MidBossPhaseThresholds > 0).to.equal(true)
			expect(#Constants.Battlefield.FinalBossPhaseThresholds > 0).to.equal(true)
		end)
	end)

	describe("Constants.EnemyRewards", function()
		it("defines positive xp/currency for FootSoldier, Commander, MidBoss (not FinalBoss)", function()
			for _, tier in { "FootSoldier", "Commander", "MidBoss" } do
				expect(Constants.EnemyRewards[tier].xp > 0).to.equal(true)
				expect(Constants.EnemyRewards[tier].currency > 0).to.equal(true)
			end
			expect(Constants.EnemyRewards.FinalBoss).to.equal(nil)
		end)
	end)

	describe("Constants.BattlePass", function()
		it("defines a non-empty CurrentSeasonId and positive XP tuning", function()
			expect(Constants.BattlePass.CurrentSeasonId).to.be.a("string")
			expect(#Constants.BattlePass.CurrentSeasonId > 0).to.equal(true)
			expect(Constants.BattlePass.XPPerQuestCompletion > 0).to.equal(true)
			expect(Constants.BattlePass.XPPerMapClear > 0).to.equal(true)
		end)

		it("CurrentSeasonId matches a real ProductCatalog premium-track SKU", function()
			local ProductCatalog = require(ReplicatedStorage.Shared.Data.ProductCatalog)
			local key = "BattlePassPremium_" .. Constants.BattlePass.CurrentSeasonId
			expect(ProductCatalog[key]).to.be.ok()
		end)
	end)

	describe("Constants.Platform", function()
		it("defines all four platform strings (matching PlatformDetection.lua's Platform type values)", function()
			for _, key in { "Desktop", "Console", "Mobile", "Tablet" } do
				expect(Constants.Platform[key]).to.equal(key)
			end
		end)
	end)

	describe("Constants.UI", function()
		it("defines a positive TouchHeavyHoldSeconds", function()
			expect(Constants.UI.TouchHeavyHoldSeconds > 0).to.equal(true)
		end)
	end)

	describe("Constants.PlaceIds", function()
		it("stubs Lobby and Battlefield as nil until T-1402 fills them in", function()
			expect(Constants.PlaceIds.Lobby).to.equal(nil)
			expect(Constants.PlaceIds.Battlefield).to.equal(nil)
		end)
	end)
end
