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

	describe("Constants.PlaceIds", function()
		it("stubs Lobby and Battlefield as nil until T-1402 fills them in", function()
			expect(Constants.PlaceIds.Lobby).to.equal(nil)
			expect(Constants.PlaceIds.Battlefield).to.equal(nil)
		end)
	end)
end
