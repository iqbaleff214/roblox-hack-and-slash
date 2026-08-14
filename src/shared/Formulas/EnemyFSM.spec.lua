return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local EnemyFSM = require(ReplicatedStorage.Shared.Formulas.EnemyFSM)

	describe("EnemyFSM", function()
		it("OnSpawn always returns Seek, never Idle", function()
			expect(EnemyFSM.OnSpawn()).to.equal("Seek")
		end)

		it("transitions Seek -> Attack on InRange", function()
			expect(EnemyFSM.Transition("Seek", "InRange")).to.equal("Attack")
		end)

		it("transitions Attack -> Seek on OutOfRange", function()
			expect(EnemyFSM.Transition("Attack", "OutOfRange")).to.equal("Seek")
		end)

		it("Died moves any state to Dead", function()
			expect(EnemyFSM.Transition("Seek", "Died")).to.equal("Dead")
			expect(EnemyFSM.Transition("Attack", "Died")).to.equal("Dead")
		end)

		it("Dead is terminal - no event moves it back out", function()
			expect(EnemyFSM.Transition("Dead", "InRange")).to.equal("Dead")
			expect(EnemyFSM.Transition("Dead", "OutOfRange")).to.equal("Dead")
		end)
	end)
end
