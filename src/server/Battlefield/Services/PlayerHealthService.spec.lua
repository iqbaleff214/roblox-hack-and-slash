--[[
	Requires a live Player with a spawned Character — Studio Play Solo/Team
	Test, see S-1301.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("PlayerHealthService", function()
		it("applies enemy damage and clamps at 0", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local PlayerHealthService = Knit.GetService("PlayerHealthService")
			local CombatService = Knit.GetService("CombatService")

			-- Ensure not mid-dash for this test.
			CombatService:GetOrCreateCombatState(player).invulnerableUntil = 0

			local before = PlayerHealthService:GetHealth(player)
			PlayerHealthService:ApplyEnemyDamage(player, 10)
			expect(PlayerHealthService:GetHealth(player)).to.equal(before - 10)

			PlayerHealthService:ApplyEnemyDamage(player, 100000)
			expect(PlayerHealthService:GetHealth(player)).to.equal(0)
		end)

		it("voids damage during a Dash i-frame window (T-405)", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local PlayerHealthService = Knit.GetService("PlayerHealthService")
			local CombatService = Knit.GetService("CombatService")

			CombatService:SetInvulnerable(player, 5)
			local before = PlayerHealthService:GetHealth(player)
			PlayerHealthService:ApplyEnemyDamage(player, 10)
			expect(PlayerHealthService:GetHealth(player)).to.equal(before)

			CombatService:GetOrCreateCombatState(player).invulnerableUntil = 0
		end)
	end)
end
