return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CombatStateMachine = require(ReplicatedStorage.Shared.Formulas.CombatStateMachine)

	describe("CombatStateMachine.Transition", function()
		it("rejects every action while Staggered", function()
			for _, action in CombatStateMachine.Actions do
				local allowed = CombatStateMachine.Transition("Staggered", action)
				expect(allowed).to.equal(false)
			end
		end)

		it("accepts Attack from Idle and transitions to Attacking", function()
			local allowed, nextState = CombatStateMachine.Transition("Idle", "Attack")
			expect(allowed).to.equal(true)
			expect(nextState).to.equal("Attacking")
		end)

		it("exhaustively defines an outcome for every (state, action) pair", function()
			for _, state in CombatStateMachine.States do
				for _, action in CombatStateMachine.Actions do
					local allowed, nextState = CombatStateMachine.Transition(state, action)
					expect(type(allowed)).to.equal("boolean")
					if allowed then
						expect(nextState).never.to.equal(nil)
					else
						expect(nextState).to.equal(nil)
					end
				end
			end
		end)

		it("Dash allowed from Attacking (cancels attack recovery, GDD §6.4)", function()
			local allowed, nextState = CombatStateMachine.Transition("Attacking", "Dash")
			expect(allowed).to.equal(true)
			expect(nextState).to.equal("Dashing")
		end)

		it("Attack allowed from Dashing (dash-attack opener, GDD §6.4)", function()
			local allowed, nextState = CombatStateMachine.Transition("Dashing", "Attack")
			expect(allowed).to.equal(true)
			expect(nextState).to.equal("Attacking")
		end)
	end)
end
