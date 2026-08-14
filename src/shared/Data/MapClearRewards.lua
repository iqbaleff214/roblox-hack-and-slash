--!strict
--[[
	T-903: per-map clear-reward bundles (GDD §8.2). Dict keyed by map id,
	mirroring `MapDefinitions`/`RewardTables`'s own keying conventions.

	`guaranteed` is the flat XP/currency/gear grant every clear gets
	(scaled to the map's tier by simply being a per-map entry — this project
	only has one map so far, so "per map tier" collapses to "per map").

	`bonusTable` is a weighted roll (`WeightedRandom.Pick`, same shape as
	`RewardTables`, weights summing to 1.0) for the rank-scaled bonus layer:
	rare/legendary gear, cosmetic currency, or Battle Pass XP (GDD §8.2).
	Rolled `RankRewardScaling.GetBonusRollCount(rank)` times, each amount
	scaled by `RankRewardScaling.GetAmountMultiplier(rank)`, by
	`MapClearRewardService`.

	`OniMenpo` (the map's `mainRewardItemId`, T-106) deliberately does NOT
	appear in `bonusTable` — it's granted separately, guaranteed-once, by
	`MapClearRewardService` via `MapClearLedger`, not as a repeat-roll
	chance.
]]

local Constants = require(script.Parent.Parent.Constants)

local Soft = Constants.Currency.Soft

local MapClearRewards = {
	Okehazama = {
		guaranteed = { xp = 200, currency = 100, gearItemId = "TekkoGauntlets" },
		bonusTable = {
			{ kind = "Nothing", weight = 0.30 },
			{ kind = "Currency", weight = 0.30, currency = Soft, amount = { min = 50, max = 150 } },
			{ kind = "Item", weight = 0.15, itemId = "DoMaru" },
			{ kind = "Item", weight = 0.05, itemId = "TigerFurDo" },
			{ kind = "BattlePassXP", weight = 0.20, amount = { min = 50, max = 100 } },
		},
	},
}

return MapClearRewards
