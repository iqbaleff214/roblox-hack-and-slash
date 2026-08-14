return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Types = require(ReplicatedStorage.Shared.Types)
	local MapDefinitions = require(ReplicatedStorage.Shared.Data.MapDefinitions)
	local EnemyDefinitions = require(ReplicatedStorage.Shared.Data.EnemyDefinitions)
	local ItemDefinitions = require(ReplicatedStorage.Shared.Data.ItemDefinitions)
	local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
	local UltimateDefinitions = require(ReplicatedStorage.Shared.Data.UltimateDefinitions)

	local enemyIds = {}
	for _, enemy in EnemyDefinitions do
		enemyIds[enemy.id] = true
	end

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

	describe("MapDefinitions", function()
		for mapId, map in MapDefinitions do
			describe(mapId, function()
				it("validates against Types.MapDefinition", function()
					expect(function()
						Types.MapDefinition(map)
					end).never.to.throw()
				end)

				it("has an id matching its dict key", function()
					expect(map.id).to.equal(mapId)
				end)

				it("only references enemyIds that exist in EnemyDefinitions", function()
					for _, wave in map.waveConfig do
						expect(enemyIds[wave.enemyId]).to.equal(true)
					end
				end)

				it("only references midBossIds that exist in EnemyDefinitions", function()
					for _, midBossId in map.midBossIds do
						expect(enemyIds[midBossId]).to.equal(true)
					end
				end)

				it("references a finalBossId that exists in EnemyDefinitions", function()
					expect(enemyIds[map.finalBossId]).to.equal(true)
				end)

				it("references a mainRewardItemId that exists in some catalog", function()
					expect(grantableIds[map.mainRewardItemId]).to.equal(true)
				end)
			end)
		end
	end)
end
