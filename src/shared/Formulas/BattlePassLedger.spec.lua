return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local BattlePassLedger = require(ReplicatedStorage.Shared.Formulas.BattlePassLedger)

	local tiers = {
		{ tier = 1, xpRequired = 100 },
		{ tier = 2, xpRequired = 250 },
		{ tier = 3, xpRequired = 450 },
	}

	describe("BattlePassLedger.GetUnlockedTiers", function()
		it("returns no tiers below the first threshold", function()
			expect(#BattlePassLedger.GetUnlockedTiers(50, tiers)).to.equal(0)
		end)

		it("returns exactly the tiers whose threshold is met, inclusive", function()
			local unlocked = BattlePassLedger.GetUnlockedTiers(250, tiers)
			expect(#unlocked).to.equal(2)
			expect(unlocked[1]).to.equal(1)
			expect(unlocked[2]).to.equal(2)
		end)

		it("returns every tier once XP exceeds the highest threshold", function()
			expect(#BattlePassLedger.GetUnlockedTiers(1000, tiers)).to.equal(3)
		end)
	end)
end
