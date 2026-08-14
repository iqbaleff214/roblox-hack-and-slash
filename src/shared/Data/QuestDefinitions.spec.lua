return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Types = require(ReplicatedStorage.Shared.Types)
	local QuestDefinitions = require(ReplicatedStorage.Shared.Data.QuestDefinitions)

	describe("QuestDefinitions", function()
		it("validates every entry against Types.QuestDefinition", function()
			for _, quest in QuestDefinitions do
				expect(function()
					Types.QuestDefinition(quest)
				end).never.to.throw()
			end
		end)

		it("has no duplicate ids", function()
			local seen = {}
			for _, quest in QuestDefinitions do
				expect(seen[quest.id]).to.equal(nil)
				seen[quest.id] = true
			end
		end)

		it("only uses valid cadences", function()
			local validCadences = { Daily = true, Weekly = true }
			for _, quest in QuestDefinitions do
				expect(validCadences[quest.cadence]).to.equal(true)
			end
		end)

		it("every DefeatEnemyTier quest has a tier matching a real EnemyDefinitions.tier; ClearMap has none", function()
			local EnemyDefinitions = require(ReplicatedStorage.Shared.Data.EnemyDefinitions)
			local validTiers = {}
			for _, enemy in EnemyDefinitions do
				validTiers[enemy.tier] = true
			end

			for _, quest in QuestDefinitions do
				if quest.goalType == "DefeatEnemyTier" then
					expect(validTiers[quest.tier]).to.equal(true)
				elseif quest.goalType == "ClearMap" then
					expect(quest.tier).to.equal(nil)
				end
			end
		end)
	end)
end
