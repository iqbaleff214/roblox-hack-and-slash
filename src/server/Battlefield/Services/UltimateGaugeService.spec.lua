--[[
	Core gauge math is unit-tested standalone in UltimateGauge.spec.lua (no
	Player/Studio needed). This spec covers the Knit-wrapper integration and
	requires a live Player with a spawned Character — Studio Play Solo/Team
	Test, see S-1301.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("UltimateGaugeService", function()
		it("rejects RequestUltimate below full gauge, accepts at full and resets to 0", function()
			local player = Players:GetPlayers()[1]
			if not player or not player.Character then
				return -- no live player/character in this run context; covered by S-1301
			end

			local UltimateGaugeService = Knit.GetService("UltimateGaugeService")
			local CombatService = Knit.GetService("CombatService")

			UltimateGaugeService:OnDamageDealt(player, 10) -- nowhere near full
			CombatService:GetOrCreateCombatState(player).state = "Idle"
			expect(UltimateGaugeService:HandleUltimateRequest(player)).to.equal(false)

			UltimateGaugeService:OnDamageDealt(player, 100000) -- clamp to full
			CombatService:GetOrCreateCombatState(player).state = "Idle"
			expect(UltimateGaugeService:HandleUltimateRequest(player)).to.equal(true)
			expect(UltimateGaugeService:GetGauge(player)).to.equal(0)
		end)
	end)
end
