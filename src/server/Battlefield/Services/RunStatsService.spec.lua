--[[
	No live Player needed — this service is keyed by nothing at all (a
	single party-wide counter set), so it's fully exercisable in any running
	Knit server per T-001's runner choice.
]]
return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("RunStatsService", function()
		it("RecordHit/RecordDamageTaken accumulate into GetStats", function()
			local RunStatsService = Knit.GetService("RunStatsService")

			local before = RunStatsService:GetStats()
			RunStatsService:RecordHit()
			RunStatsService:RecordHit()
			RunStatsService:RecordDamageTaken(15)

			local after = RunStatsService:GetStats()
			expect(after.comboCount).to.equal(before.comboCount + 2)
			expect(after.damageTaken).to.equal(before.damageTaken + 15)
		end)

		it("GetStats never throws and returns a non-negative timeElapsedSeconds", function()
			local RunStatsService = Knit.GetService("RunStatsService")
			local stats = RunStatsService:GetStats()
			expect(stats.timeElapsedSeconds >= 0).to.equal(true)
		end)
	end)
end
