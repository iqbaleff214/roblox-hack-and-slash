return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local LevelLedger = require(ReplicatedStorage.Shared.Formulas.LevelLedger)
	local XPCurve = require(ReplicatedStorage.Shared.Formulas.XPCurve)

	describe("LevelLedger.AwardXP", function()
		it("an award landing exactly on a level threshold triggers level-up exactly once", function()
			local data = { XP = 0, Level = 1 }
			local levelsGained = LevelLedger.AwardXP(data, XPCurve.XPForLevel(2))
			expect(#levelsGained).to.equal(1)
			expect(levelsGained[1]).to.equal(2)
			expect(data.Level).to.equal(2)
		end)

		it("an award spanning 3 levels fires LevelUp 3 times with correct intermediate levels", function()
			local data = { XP = XPCurve.XPForLevel(5), Level = 5 }
			local xpNeededFor8 = XPCurve.XPForLevel(8) - data.XP
			local levelsGained = LevelLedger.AwardXP(data, xpNeededFor8)
			expect(#levelsGained).to.equal(3)
			expect(levelsGained[1]).to.equal(6)
			expect(levelsGained[2]).to.equal(7)
			expect(levelsGained[3]).to.equal(8)
			expect(data.Level).to.equal(8)
		end)

		it("an award not crossing a threshold gains no levels", function()
			local data = { XP = XPCurve.XPForLevel(3), Level = 3 }
			local levelsGained = LevelLedger.AwardXP(data, 1)
			expect(#levelsGained).to.equal(0)
			expect(data.Level).to.equal(3)
		end)
	end)
end
