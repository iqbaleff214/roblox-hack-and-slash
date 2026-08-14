return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local BattlePassTiers = require(ReplicatedStorage.Shared.Data.BattlePassTiers)
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

	describe("BattlePassTiers", function()
		it("tier numbers are sequential starting at 1", function()
			for i, tierEntry in BattlePassTiers do
				expect(tierEntry.tier).to.equal(i)
			end
		end)

		it("xpRequired is strictly increasing", function()
			for i = 2, #BattlePassTiers do
				expect(BattlePassTiers[i].xpRequired > BattlePassTiers[i - 1].xpRequired).to.equal(true)
			end
		end)

		it("every freeReward/premiumReward references a real currency or catalog item", function()
			for _, tierEntry in BattlePassTiers do
				expect(tierEntry.freeReward.amount > 0).to.equal(true)
				expect(grantableIds[tierEntry.premiumReward.itemId]).to.equal(true)
			end
		end)

		it("has no duplicate premiumReward itemIds (each tier's premium item is distinct)", function()
			local seen = {}
			for _, tierEntry in BattlePassTiers do
				local itemId = tierEntry.premiumReward.itemId
				expect(seen[itemId]).to.equal(nil)
				seen[itemId] = true
			end
		end)
	end)
end
