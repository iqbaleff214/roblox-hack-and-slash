return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local QuestResetLedger = require(ReplicatedStorage.Shared.Formulas.QuestResetLedger)

	local SECONDS_PER_DAY = 86400

	describe("QuestResetLedger.HasCrossedDailyBoundary", function()
		it("treats a nil lastResetTimestamp as always crossed (first login)", function()
			expect(QuestResetLedger.HasCrossedDailyBoundary(nil, 12345)).to.equal(true)
		end)

		it("login just before the UTC midnight boundary does not reset", function()
			local dayBoundary = 10 * SECONDS_PER_DAY
			expect(QuestResetLedger.HasCrossedDailyBoundary(dayBoundary - 1, dayBoundary - 1)).to.equal(false)
		end)

		it("login exactly at (just after) the UTC midnight boundary does reset", function()
			local dayBoundary = 10 * SECONDS_PER_DAY
			expect(QuestResetLedger.HasCrossedDailyBoundary(dayBoundary - 1, dayBoundary)).to.equal(true)
		end)

		it("same-day logins never reset", function()
			local dayStart = 10 * SECONDS_PER_DAY
			expect(QuestResetLedger.HasCrossedDailyBoundary(dayStart, dayStart + SECONDS_PER_DAY - 1)).to.equal(false)
		end)
	end)

	describe("QuestResetLedger.HasCrossedWeeklyBoundary", function()
		it("treats a nil lastResetTimestamp as always crossed (first login)", function()
			expect(QuestResetLedger.HasCrossedWeeklyBoundary(nil, 12345)).to.equal(true)
		end)

		it("resets on the correct day only (Sunday -> Monday, epoch-day 3 -> 4), not any other day", function()
			local sunday = 3 * SECONDS_PER_DAY
			local monday = 4 * SECONDS_PER_DAY
			local saturday = 2 * SECONDS_PER_DAY
			expect(QuestResetLedger.HasCrossedWeeklyBoundary(saturday, sunday)).to.equal(false)
			expect(QuestResetLedger.HasCrossedWeeklyBoundary(sunday, monday)).to.equal(true)
		end)

		it("does not reset again within the same Mon-Sun week (epoch-days 4 through 10)", function()
			local monday = 4 * SECONDS_PER_DAY
			local nextSunday = 10 * SECONDS_PER_DAY
			expect(QuestResetLedger.HasCrossedWeeklyBoundary(monday, nextSunday)).to.equal(false)
		end)

		it("resets at the next Monday (epoch-day 11)", function()
			local monday = 4 * SECONDS_PER_DAY
			local nextMonday = 11 * SECONDS_PER_DAY
			expect(QuestResetLedger.HasCrossedWeeklyBoundary(monday, nextMonday)).to.equal(true)
		end)
	end)
end
