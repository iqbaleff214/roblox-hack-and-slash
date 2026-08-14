--[[
	Core state-transition rules are unit-tested standalone in
	CombatStateMachine.spec.lua / ComboResolver.spec.lua (no Player/Studio
	needed). This spec covers the Knit-wrapper integration and requires a
	live Player with a spawned Character — Studio Play Solo/Team Test, see
	S-1301.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("CombatService", function()
		it("rejects an attack request while the player is Staggered", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local CombatService = Knit.GetService("CombatService")
			local state = CombatService:GetOrCreateCombatState(player)
			state.state = "Staggered"

			local accepted = CombatService:HandleAttackRequest(player, "Light")
			expect(accepted).to.equal(false)

			state.state = "Idle" -- reset for other specs
		end)

		it("accepts an attack request from Idle and transitions to Attacking", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local CombatService = Knit.GetService("CombatService")
			local state = CombatService:GetOrCreateCombatState(player)
			state.state = "Idle"

			local accepted = CombatService:HandleAttackRequest(player, "Light")
			expect(accepted).to.equal(true)
			expect(state.state).to.equal("Attacking")
		end)
	end)
end
