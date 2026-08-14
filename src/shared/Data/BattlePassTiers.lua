--!strict
--[[
	T-905: seasonal Battle Pass tier-unlock table (GDD §8.3/§9.3). Array of
	tiers with cumulative XP thresholds (`Constants.BattlePass.XPPerQuestCompletion`/
	`XPPerMapClear` feed the XP this is checked against). Free-track rewards
	are available to everyone; premium-track rewards need
	`profile.Data.BattlePassProgress.premiumOwned` — see `BattlePassService`'s
	own header for why that flag is a forward-compatible stub for T-1002's
	real Game Pass ownership check, not a real Robux check yet.

	Same-season only (this file has no `seasonId` per tier — it's the whole
	table for `Constants.BattlePass.CurrentSeasonId`; a new season replaces
	this file's contents, it doesn't append to it, matching T-1005's "owning
	a past season's pass doesn't unlock the current season" requirement).
]]

local Constants = require(script.Parent.Parent.Constants)

local Soft = Constants.Currency.Soft

local BattlePassTiers = {
	{ tier = 1, xpRequired = 100, freeReward = { currency = Soft, amount = 50 }, premiumReward = { itemId = "TekkoGauntlets" } },
	{ tier = 2, xpRequired = 250, freeReward = { currency = Soft, amount = 75 }, premiumReward = { itemId = "HanEiKabuto" } },
	{ tier = 3, xpRequired = 450, freeReward = { currency = Soft, amount = 100 }, premiumReward = { itemId = "KoteBraces" } },
	{ tier = 4, xpRequired = 700, freeReward = { currency = Soft, amount = 125 }, premiumReward = { itemId = "SuneAteGreaves" } },
	{ tier = 5, xpRequired = 1000, freeReward = { currency = Soft, amount = 200 }, premiumReward = { itemId = "DragonKote" } },
}

return BattlePassTiers
