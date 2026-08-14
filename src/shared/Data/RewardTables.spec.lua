return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RewardTables = require(ReplicatedStorage.Shared.Data.RewardTables)
	local WeightedRandom = require(ReplicatedStorage.Shared.Formulas.WeightedRandom)
	local ItemDefinitions = require(ReplicatedStorage.Shared.Data.ItemDefinitions)
	local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
	local UltimateDefinitions = require(ReplicatedStorage.Shared.Data.UltimateDefinitions)

	local grantableIds = {}
	for _, item in ItemDefinitions do
		grantableIds[item.id] = true
	end
	for _, weapon in WeaponDefinitions do
		grantableIds[weapon.id] = true
	end
	for _, ultimate in UltimateDefinitions do
		grantableIds[ultimate.id] = true
	end

	local EPSILON = 1e-9

	describe("RewardTables", function()
		for tableName, entries in RewardTables do
			describe(tableName, function()
				it("has weights that sum to 1.0", function()
					local total = 0
					for _, entry in entries do
						total += entry.weight
					end
					expect(math.abs(total - 1.0) < EPSILON).to.equal(true)
				end)

				it("only references itemIds that exist in a real catalog", function()
					for _, entry in entries do
						if entry.kind == "Item" then
							expect(grantableIds[entry.itemId]).to.equal(true)
						end
					end
				end)
			end)
		end

		it("MidBoss and FinalBoss have no Nothing entry (guaranteed gear drop, GDD §8.1)", function()
			for _, entry in RewardTables.MidBoss do
				expect(entry.kind).never.to.equal("Nothing")
			end
			for _, entry in RewardTables.FinalBoss do
				expect(entry.kind).never.to.equal("Nothing")
			end
		end)

		it("DestructibleBox has no Nothing entry (always yields one of the four kinds, GDD §6.3)", function()
			for _, entry in RewardTables.DestructibleBox do
				expect(entry.kind).never.to.equal("Nothing")
			end
		end)

		it("TreasureCarrier has no Nothing entry (always drops loot/currency, GDD §7.1)", function()
			for _, entry in RewardTables.TreasureCarrier do
				expect(entry.kind).never.to.equal("Nothing")
			end
		end)

		it("rolls FootSoldier's table ~10k times and lands within tolerance of its weights", function()
			local entries = RewardTables.FootSoldier
			local counts = { Nothing = 0, Item = 0 }
			local sampleCount = 10000

			for i = 1, sampleCount do
				-- Deterministic low-discrepancy sequence in [0, 1) instead of
				-- math.random(), so this test is reproducible.
				local randomValue01 = (i * 0.61803398875) % 1
				local picked = WeightedRandom.Pick(entries, randomValue01)
				counts[picked.kind] += 1
			end

			local nothingRatio = counts.Nothing / sampleCount
			local itemRatio = counts.Item / sampleCount

			expect(math.abs(nothingRatio - 0.97) < 0.02).to.equal(true)
			expect(math.abs(itemRatio - 0.03) < 0.02).to.equal(true)
		end)
	end)
end
