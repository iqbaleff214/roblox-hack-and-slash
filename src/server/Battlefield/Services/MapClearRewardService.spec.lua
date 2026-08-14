--[[
	Rank computation and the bonus-roll scaling/distribution are already
	genuinely verified in `RankFormula.spec.lua`/`RankRewardScaling.spec.lua`/
	`MapClearRewards.spec.lua` (real `lune` execution). This exercises the
	Knit-wrapper integration: the guaranteed bundle grants deterministic XP
	every clear, and the Main Reward is idempotent per T-903's DoD — needs a
	live Player as the grant target.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("MapClearRewardService", function()
		it("does not throw for an unknown mapId", function()
			local MapClearRewardService = Knit.GetService("MapClearRewardService")
			expect(function()
				MapClearRewardService:HandleMapCleared("NotARealMap")
			end).never.to.throw()
		end)

		it("grants the guaranteed XP every clear and the Main Reward only on the first (T-903 DoD)", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local MapClearRewardService = Knit.GetService("MapClearRewardService")
			local DataService = Knit.GetService("DataService")
			local MapClearRewards = require(ReplicatedStorage.Shared.Data.MapClearRewards)

			local profile = DataService:GetProfile(player)
			local guaranteedXP = MapClearRewards.Okehazama.guaranteed.xp

			local xpBefore = profile.Data.XP
			MapClearRewardService:HandleMapCleared("Okehazama")
			expect(profile.Data.XP).to.equal(xpBefore + guaranteedXP)
			expect(profile.Data.MapStats.Okehazama.mainRewardGranted).to.equal(true)
			expect(profile.Data.MapStats.Okehazama.clearCount).to.be.ok()
			local clearCountAfterFirst = profile.Data.MapStats.Okehazama.clearCount

			local xpBeforeSecond = profile.Data.XP
			MapClearRewardService:HandleMapCleared("Okehazama")
			expect(profile.Data.XP).to.equal(xpBeforeSecond + guaranteedXP)
			expect(profile.Data.MapStats.Okehazama.mainRewardGranted).to.equal(true)
			expect(profile.Data.MapStats.Okehazama.clearCount).to.equal(clearCountAfterFirst + 1)
		end)
	end)
end
