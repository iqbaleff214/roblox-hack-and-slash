--[[
	Cooldown math is unit-tested standalone in Cooldown.spec.lua. This spec
	covers the Knit-wrapper integration and requires a live Player with a
	spawned Character — Studio Play Solo/Team Test, see S-1301.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("SpecialAttackService", function()
		it("enforces its cooldown server-side regardless of repeated requests", function()
			local player = Players:GetPlayers()[1]
			if not player or not player.Character then
				return -- no live player/character in this run context; covered by S-1301
			end

			local SpecialAttackService = Knit.GetService("SpecialAttackService")
			local CombatService = Knit.GetService("CombatService")
			CombatService:GetOrCreateCombatState(player).state = "Idle"

			local first = SpecialAttackService:HandleSpecialRequest(player)
			expect(first).to.equal(true)

			CombatService:GetOrCreateCombatState(player).state = "Idle"
			local second = SpecialAttackService:HandleSpecialRequest(player)
			expect(second).to.equal(false) -- still on cooldown
		end)
	end)
end
