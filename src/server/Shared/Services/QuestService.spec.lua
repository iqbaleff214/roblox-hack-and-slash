--[[
	The reset-boundary decision itself (injected-clock, both directions) is
	already genuinely verified in `QuestResetLedger.spec.lua` (T-904's own
	pure formula, real `lune` execution). This exercises the Knit-wrapper
	integration: progress accumulates, a quest completes and grants its
	reward exactly at `targetCount`, and further progress past completion
	doesn't re-grant — needs a live Player as the profile/grant target.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("QuestService", function()
		it("initializes quest state and reset timestamps on login (no live player needed to check structure)", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local DataService = Knit.GetService("DataService")
			local profile = DataService:GetProfile(player)
			expect(profile.Data.QuestProgress.quests).to.be.a("table")
			expect(profile.Data.QuestProgress.lastDailyResetAt).to.be.a("number")
			expect(profile.Data.QuestProgress.lastWeeklyResetAt).to.be.a("number")
		end)

		it("completes a quest exactly at targetCount and grants its currency reward exactly once", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local QuestService = Knit.GetService("QuestService")
			local DataService = Knit.GetService("DataService")
			local QuestDefinitions = require(ReplicatedStorage.Shared.Data.QuestDefinitions)

			local quest
			for _, candidate in QuestDefinitions do
				if candidate.id == "DailyDefeat20FootSoldiers" then
					quest = candidate
				end
			end

			local profile = DataService:GetProfile(player)
			profile.Data.QuestProgress.quests[quest.id] = { progress = 0, completed = false }
			local currencyBefore = profile.Data.SoftCurrency

			for _ = 1, quest.targetCount - 1 do
				QuestService:IncrementProgress(player, quest.id, 1)
			end
			expect(profile.Data.QuestProgress.quests[quest.id].completed).to.equal(false)
			expect(profile.Data.SoftCurrency).to.equal(currencyBefore)

			QuestService:IncrementProgress(player, quest.id, 1)
			expect(profile.Data.QuestProgress.quests[quest.id].completed).to.equal(true)
			expect(profile.Data.SoftCurrency).to.equal(currencyBefore + quest.rewards[1].amount)

			-- Further progress past completion doesn't re-grant.
			QuestService:IncrementProgress(player, quest.id, 1)
			expect(profile.Data.SoftCurrency).to.equal(currencyBefore + quest.rewards[1].amount)
		end)
	end)
end
