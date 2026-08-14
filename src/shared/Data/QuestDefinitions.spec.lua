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
	end)
end
