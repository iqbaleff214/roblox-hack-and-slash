return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Types = require(ReplicatedStorage.Shared.Types)
	local EnemyDefinitions = require(ReplicatedStorage.Shared.Data.EnemyDefinitions)

	describe("EnemyDefinitions", function()
		it("validates every entry against Types.EnemyDefinition", function()
			for _, enemy in EnemyDefinitions do
				expect(function()
					Types.EnemyDefinition(enemy)
				end).never.to.throw()
			end
		end)

		it("has no duplicate ids", function()
			local seen = {}
			for _, enemy in EnemyDefinitions do
				expect(seen[enemy.id]).to.equal(nil)
				seen[enemy.id] = true
			end
		end)

		it("has poiseMax == 0 iff tier == FootSoldier", function()
			for _, enemy in EnemyDefinitions do
				if enemy.tier == "FootSoldier" then
					expect(enemy.poiseMax).to.equal(0)
				else
					expect(enemy.poiseMax > 0).to.equal(true)
				end
			end
		end)

		it("only uses valid tiers", function()
			local validTiers = { FootSoldier = true, Commander = true, MidBoss = true, FinalBoss = true }
			for _, enemy in EnemyDefinitions do
				expect(validTiers[enemy.tier]).to.equal(true)
			end
		end)

		it("references a lootTableId that exists in RewardTables", function()
			local RewardTables = require(ReplicatedStorage.Shared.Data.RewardTables)
			for _, enemy in EnemyDefinitions do
				expect(RewardTables[enemy.lootTableId]).to.be.a("table")
			end
		end)
	end)
end
