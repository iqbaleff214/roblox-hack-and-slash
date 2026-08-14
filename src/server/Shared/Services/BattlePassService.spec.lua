--[[
	Tier-unlock resolution itself is already genuinely verified in
	`BattlePassLedger.spec.lua` (T-905's own pure formula, real `lune`
	execution). This exercises the Knit-wrapper integration: free-track
	tiers unlock at XP thresholds regardless of premium flag, and premium
	tiers are withheld until `GrantPremium` — then retroactively granted for
	already-crossed thresholds (T-905's DoD) — needs a live Player as the
	profile/grant target.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("BattlePassService", function()
		it("unlocks free-track tiers at XP thresholds regardless of premium flag, withholds premium until granted, then retroactively unlocks it", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local BattlePassService = Knit.GetService("BattlePassService")
			local DataService = Knit.GetService("DataService")
			local BattlePassTiers = require(ReplicatedStorage.Shared.Data.BattlePassTiers)
			local InventoryService = Knit.GetService("InventoryService")

			local profile = DataService:GetProfile(player)
			-- Isolate this test from any prior progress in this run.
			profile.Data.BattlePassProgress = {
				seasonId = require(ReplicatedStorage.Shared.Constants).BattlePass.CurrentSeasonId,
				xp = 0,
				premiumOwned = false,
				grantedFreeTiers = {},
				grantedPremiumTiers = {},
			}

			local tier1 = BattlePassTiers[1]
			BattlePassService:AwardSeasonXP(player, tier1.xpRequired)

			expect(profile.Data.BattlePassProgress.grantedFreeTiers[1]).to.equal(true)
			expect(profile.Data.BattlePassProgress.grantedPremiumTiers[1]).to.equal(nil)
			expect(InventoryService:HasItem(player, tier1.premiumReward.itemId)).to.equal(false)

			BattlePassService:GrantPremium(player)

			expect(profile.Data.BattlePassProgress.premiumOwned).to.equal(true)
			expect(profile.Data.BattlePassProgress.grantedPremiumTiers[1]).to.equal(true)
			expect(InventoryService:HasItem(player, tier1.premiumReward.itemId)).to.equal(true)
		end)
	end)
end
