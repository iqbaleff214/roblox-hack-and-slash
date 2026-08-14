--[[
	The damage-share split math itself is already genuinely verified in
	`DamageShareReward.spec.lua` (T-901's own pure formula, real `lune`
	execution, including the "sums to exactly totalAmount across many
	contributor counts" property). This exercises the Knit-wrapper
	integration: a solo kill grants the full flat reward to the one
	contributor. A true multi-player damage-share grant needs a live
	multi-player Studio session (Team Test, not Play Solo) — covered by
	S-1301/S-1303, not here.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("EnemyRewardService", function()
		it("grants the full flat FootSoldier reward to a solo contributor", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local Constants = require(ReplicatedStorage.Shared.Constants)
			local DataService = Knit.GetService("DataService")
			local EnemySpawnService = Knit.GetService("EnemySpawnService")

			local profile = DataService:GetProfile(player)
			local xpBefore = profile.Data.XP
			local currencyBefore = profile.Data.SoftCurrency

			EnemySpawnService.EnemyDied:Fire("Swordsman", "FootSoldier", { [player] = 25 })

			local reward = Constants.EnemyRewards.FootSoldier
			expect(profile.Data.XP).to.equal(xpBefore + reward.xp)
			expect(profile.Data.SoftCurrency).to.equal(currencyBefore + reward.currency)
		end)

		it("grants nothing for a FinalBoss-tier death (map-clear payout handles it instead)", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local DataService = Knit.GetService("DataService")
			local EnemySpawnService = Knit.GetService("EnemySpawnService")

			local profile = DataService:GetProfile(player)
			local xpBefore = profile.Data.XP
			local currencyBefore = profile.Data.SoftCurrency

			EnemySpawnService.EnemyDied:Fire("ImagawaYoshimoto", "FinalBoss", { [player] = 999 })

			expect(profile.Data.XP).to.equal(xpBefore)
			expect(profile.Data.SoftCurrency).to.equal(currencyBefore)
		end)
	end)
end
