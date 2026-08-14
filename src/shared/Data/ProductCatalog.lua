--!strict
--[[
	Monetization SKU catalog (GDD §9). Dict keyed by internal SKU. `robloxId`
	is `nil` until S-1001/S-1002 create the real Developer Products/Game
	Passes in the Creator Dashboard; T-1401 fills these in.

	`cosmeticOnly` must be set explicitly on every entry (not left to default)
	— it's the field T-1004's guardrail test cross-checks against granted
	items' own `cosmeticOnly` flags to keep monetization pay-to-win-free per
	GDD §9.5. Boost/VIP passes are marked `false`: they're not cosmetic, but
	they're also not stat *items* the T-1004 scan covers — they're the
	explicitly-designed rate-boost/convenience monetization from GDD §9.2.
]]

local ProductCatalog = {
	-- Premium currency bundles (GDD §9.1)
	Gems100 = {
		type = "DevProduct",
		robloxId = nil,
		grants = { premiumCurrency = 100 },
		cosmeticOnly = true,
	},
	Gems550 = {
		type = "DevProduct",
		robloxId = nil,
		grants = { premiumCurrency = 550 },
		cosmeticOnly = true,
	},
	Gems1200 = {
		type = "DevProduct",
		robloxId = nil,
		grants = { premiumCurrency = 1200 },
		cosmeticOnly = true,
	},

	-- Direct cosmetic bundle purchase (GDD §9.4)
	CosmeticBundle_OniWarlord = {
		type = "DevProduct",
		robloxId = nil,
		grants = { items = { "OniMenpo", "TigerFurDo", "DragonKote", "StormSuneAte" } },
		cosmeticOnly = true,
	},

	-- Loadout preset slot (GDD §4.4, T-1006)
	LoadoutPresetSlot = {
		type = "DevProduct",
		robloxId = nil,
		grants = { loadoutPresetSlots = 1 },
		cosmeticOnly = true,
	},

	-- Game Passes (GDD §9.2)
	XPBoostPass = {
		type = "GamePass",
		robloxId = nil,
		grants = { xpBoostPercent = 0.25 },
		cosmeticOnly = false,
	},
	CurrencyBoostPass = {
		type = "GamePass",
		robloxId = nil,
		grants = { currencyBoostPercent = 0.25 },
		cosmeticOnly = false,
	},
	VIPPass = {
		type = "GamePass",
		robloxId = nil,
		grants = { cosmeticTrail = "VIPAura", dailyCurrencyBonus = 50 },
		cosmeticOnly = false,
	},
	AutoLootInventoryPass = {
		type = "GamePass",
		robloxId = nil,
		grants = { autoLoot = true, extraInventorySlots = 20 },
		cosmeticOnly = true,
	},

	-- Battle Pass premium track, one per season (GDD §9.3, T-1005)
	BattlePassPremium_Season1 = {
		type = "GamePass",
		robloxId = nil,
		grants = { battlePassPremiumTrack = "Season1" },
		cosmeticOnly = true,
	},
}

return ProductCatalog
