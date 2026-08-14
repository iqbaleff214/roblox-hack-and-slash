return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local MapClearRewards = require(ReplicatedStorage.Shared.Data.MapClearRewards)
	local MapDefinitions = require(ReplicatedStorage.Shared.Data.MapDefinitions)
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

	describe("MapClearRewards", function()
		it("has one entry per MapDefinitions map id (no missing, no orphaned)", function()
			for mapId in MapDefinitions do
				expect(MapClearRewards[mapId]).to.be.ok()
			end
			for mapId in MapClearRewards do
				expect(MapDefinitions[mapId]).to.be.ok()
			end
		end)

		for mapId, reward in MapClearRewards do
			describe(mapId, function()
				it("guaranteed bundle references a real gearItemId", function()
					expect(grantableIds[reward.guaranteed.gearItemId]).to.equal(true)
				end)

				it("guaranteed bundle has positive xp/currency", function()
					expect(reward.guaranteed.xp > 0).to.equal(true)
					expect(reward.guaranteed.currency > 0).to.equal(true)
				end)

				it("bonusTable weights sum to 1.0", function()
					local total = 0
					for _, entry in reward.bonusTable do
						total += entry.weight
					end
					expect(math.abs(total - 1.0) < EPSILON).to.equal(true)
				end)

				it("bonusTable only references itemIds that exist in a real catalog", function()
					for _, entry in reward.bonusTable do
						if entry.kind == "Item" then
							expect(grantableIds[entry.itemId]).to.equal(true)
						end
					end
				end)

				it("bonusTable never rolls the map's own mainRewardItemId (guaranteed separately)", function()
					local mainRewardItemId = MapDefinitions[mapId].mainRewardItemId
					for _, entry in reward.bonusTable do
						if entry.kind == "Item" then
							expect(entry.itemId).never.to.equal(mainRewardItemId)
						end
					end
				end)
			end)
		end
	end)
end
