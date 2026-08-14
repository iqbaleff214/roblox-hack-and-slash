--!strict
--[[
	Weighted loot tables per source (GDD §8.1 per-enemy rewards + §6.3
	destructible boxes). Dict keyed by source tier name. Each table is an
	array of weighted entries (consumed via `WeightedRandom.Pick`); weights
	within a table sum to exactly 1.0 (see each table's spec test).

	This is deliberately just the *bonus gear-drop* layer — flat per-kill
	XP/currency is T-901's job (LevelService.AwardXP + CurrencyService.AddCurrency),
	not modeled here. Entry `kind`:
		"Nothing"        -- no drop this roll
		"Item"           -- itemId, drawn from Item/Weapon/Ultimate catalogs
		"Currency"       -- amount = { min, max }, SoftCurrency
		"StaminaRestore" -- flat HP/stamina pickup, no extra fields
		"UltimateCharge" -- amount = { min, max }, gauge points (see T-407)

	FootSoldier: no gear-drop chance in GDD §8.1, just a rare bonus for feel.
	Commander: "chance for gear drop" (§8.1) -> weighted Nothing/Item.
	MidBoss: "guaranteed gear drop ... chance at cosmetic drop" (§8.1) -> no
		Nothing entry, weighted between regular gear and cosmetic bonus.
	FinalBoss: always rewards well, weighted toward higher-value gear.
	DestructibleBox: always yields one of the four kinds listed in §6.3 (no
		Nothing) — currency most common, item rarest ("low odds, jackpot feel").
]]

local RewardTables = {
	FootSoldier = {
		{ kind = "Nothing", weight = 0.97 },
		{ kind = "Item", weight = 0.03, itemId = "Kabuto" },
	},

	Commander = {
		{ kind = "Nothing", weight = 0.70 },
		{ kind = "Item", weight = 0.20, itemId = "DoMaru" },
		{ kind = "Item", weight = 0.10, itemId = "Fists" },
	},

	MidBoss = {
		{ kind = "Item", weight = 0.45, itemId = "SuneAteGreaves" },
		{ kind = "Item", weight = 0.40, itemId = "Yari" },
		{ kind = "Item", weight = 0.15, itemId = "TigerFurDo" },
	},

	FinalBoss = {
		{ kind = "Item", weight = 0.50, itemId = "HanEiKabuto" },
		{ kind = "Item", weight = 0.35, itemId = "Naginata" },
		{ kind = "Item", weight = 0.15, itemId = "OniMenpo" },
	},

	DestructibleBox = {
		{ kind = "Currency", weight = 0.55, amount = { min = 5, max = 15 } },
		{ kind = "StaminaRestore", weight = 0.25 },
		{ kind = "UltimateCharge", weight = 0.15, amount = { min = 5, max = 10 } },
		{ kind = "Item", weight = 0.05, itemId = "KoteBraces" },
	},
}

return RewardTables
