--!strict
--[[
	T-905: pure tier-unlock resolution from accumulated seasonal XP. Given
	the current XP total and the season's tier table, returns every tier
	number whose `xpRequired` has been met — `BattlePassService` diffs this
	against what's already been granted (free/premium tracked separately)
	to know what's newly grantable, including retroactively: if a player's
	XP already crossed tier 3 before they owned premium, granting premium
	afterward re-evaluates from the same XP total and correctly includes
	tier 3's premium reward (T-905's DoD).
]]

local BattlePassLedger = {}

export type Tier = { tier: number, xpRequired: number }

function BattlePassLedger.GetUnlockedTiers(xp: number, tiers: { Tier }): { number }
	local unlocked = {}
	for _, tierEntry in tiers do
		if xp >= tierEntry.xpRequired then
			table.insert(unlocked, tierEntry.tier)
		end
	end
	return unlocked
end

return BattlePassLedger
