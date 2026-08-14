--[[
	Core poise math is unit-tested standalone in PoiseMath.spec.lua (no
	Player/Studio needed). PoiseService itself is keyed by enemyId strings,
	not Player, so — unlike the other combat services — this spec doesn't
	need a live player at all; it runs fully in any TestEZ pass.
]]
return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("PoiseService", function()
		it("registers an enemy at full poise", function()
			local PoiseService = Knit.GetService("PoiseService")
			PoiseService:RegisterEnemy("SpecEnemy1", 100)
			expect(PoiseService:GetPoise("SpecEnemy1")).to.equal(100)
			PoiseService:UnregisterEnemy("SpecEnemy1")
		end)

		it("breaks exactly once at the threshold crossing and is not broken beforehand", function()
			local PoiseService = Knit.GetService("PoiseService")
			PoiseService:RegisterEnemy("SpecEnemy2", 50)

			PoiseService:ApplyPoiseDamage("SpecEnemy2", 30)
			expect(PoiseService:IsBroken("SpecEnemy2")).to.equal(false)

			PoiseService:ApplyPoiseDamage("SpecEnemy2", 30)
			expect(PoiseService:IsBroken("SpecEnemy2")).to.equal(true)
			expect(PoiseService:GetPoise("SpecEnemy2")).to.equal(0)

			PoiseService:UnregisterEnemy("SpecEnemy2")
		end)

		it("a poiseMax 0 enemy (Foot Soldier) is immune and never breaks", function()
			local PoiseService = Knit.GetService("PoiseService")
			PoiseService:RegisterEnemy("SpecEnemy3", 0)
			PoiseService:ApplyPoiseDamage("SpecEnemy3", 9999)
			expect(PoiseService:IsBroken("SpecEnemy3")).to.equal(false)
			PoiseService:UnregisterEnemy("SpecEnemy3")
		end)

		it("unregistering drops all tracked state", function()
			local PoiseService = Knit.GetService("PoiseService")
			PoiseService:RegisterEnemy("SpecEnemy4", 50)
			PoiseService:UnregisterEnemy("SpecEnemy4")
			expect(PoiseService:GetPoise("SpecEnemy4")).to.equal(nil)
		end)
	end)
end
