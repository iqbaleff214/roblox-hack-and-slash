--[[
	Requires a live Player with a spawned Character — Studio Play Solo/Team
	Test, see S-1301. The rate-limiting building block (RateLimiter) is
	unit-tested standalone in RateLimiter.spec.lua.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("DashService", function()
		it("grants an i-frame window on a successful dash", function()
			local player = Players:GetPlayers()[1]
			if not player or not player.Character then
				return -- no live player/character in this run context; covered by S-1301
			end

			local DashService = Knit.GetService("DashService")
			local CombatService = Knit.GetService("CombatService")

			local state = CombatService:GetOrCreateCombatState(player)
			state.state = "Idle"

			local accepted = DashService:HandleDashRequest(player)
			expect(accepted).to.equal(true)
			expect(CombatService:IsInvulnerable(player)).to.equal(true)
			expect(state.state).to.equal("Dashing")
		end)
	end)
end
