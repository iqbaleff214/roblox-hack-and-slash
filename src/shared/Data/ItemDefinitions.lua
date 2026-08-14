--!strict
--[[
	Accessory catalog (Head/Body/Arm/Leg — GDD §4.1). An array of `Types.Item`
	records; each carries its own `id`. `meshAssetId` is left `nil` until
	S-103 creates the real models. Stat-affecting items price in SoftCurrency
	(always free-to-earn); cosmetic-only items price in PremiumCurrency — the
	GDD §9.5 guardrail (T-1004) requires that split to hold for every item that
	is ever premium-exclusive.

	`name` (Phase 6 addition): unlike Weapon/Ultimate, this catalog originally
	had no player-facing display name — a real gap once Shop/Loadout UI (T-602)
	and the Main Reward preview (T-603) actually needed to show these to a
	player instead of a raw id like "OniMenpo".
]]

local Constants = require(script.Parent.Parent.Constants)

local Soft = Constants.Currency.Soft
local Premium = Constants.Currency.Premium

local ItemDefinitions = {
	-- Head
	{
		id = "Kabuto",
		name = "Kabuto Helmet",
		slot = "Head",
		rarity = "Common",
		statBonus = 1,
		cosmeticOnly = false,
		price = { currency = Soft, amount = 100 },
		meshAssetId = nil,
	},
	{
		id = "HanEiKabuto",
		name = "Han'ei Kabuto",
		slot = "Head",
		rarity = "Rare",
		statBonus = 3,
		cosmeticOnly = false,
		price = { currency = Soft, amount = 400 },
		meshAssetId = nil,
	},
	{
		id = "OniMenpo",
		name = "Oni Menpo Mask",
		slot = "Head",
		rarity = "Legendary",
		statBonus = 0,
		cosmeticOnly = true,
		price = { currency = Premium, amount = 500 },
		meshAssetId = nil,
	},

	-- Body
	{
		id = "AshigaruDo",
		name = "Ashigaru Dō",
		slot = "Body",
		rarity = "Common",
		statBonus = 1,
		cosmeticOnly = false,
		price = { currency = Soft, amount = 100 },
		meshAssetId = nil,
	},
	{
		id = "DoMaru",
		name = "Dō-maru Armor",
		slot = "Body",
		rarity = "Rare",
		statBonus = 3,
		cosmeticOnly = false,
		price = { currency = Soft, amount = 400 },
		meshAssetId = nil,
	},
	{
		id = "TigerFurDo",
		name = "Tiger Fur Dō",
		slot = "Body",
		rarity = "Epic",
		statBonus = 0,
		cosmeticOnly = true,
		price = { currency = Premium, amount = 350 },
		meshAssetId = nil,
	},

	-- Arm
	{
		id = "TekkoGauntlets",
		name = "Tekko Gauntlets",
		slot = "Arm",
		rarity = "Common",
		statBonus = 1,
		cosmeticOnly = false,
		price = { currency = Soft, amount = 100 },
		meshAssetId = nil,
	},
	{
		id = "KoteBraces",
		name = "Kote Braces",
		slot = "Arm",
		rarity = "Rare",
		statBonus = 3,
		cosmeticOnly = false,
		price = { currency = Soft, amount = 400 },
		meshAssetId = nil,
	},
	{
		id = "DragonKote",
		name = "Dragon Kote",
		slot = "Arm",
		rarity = "Epic",
		statBonus = 0,
		cosmeticOnly = true,
		price = { currency = Premium, amount = 350 },
		meshAssetId = nil,
	},

	-- Leg
	{
		id = "WarazoriSandals",
		name = "Warazori Sandals",
		slot = "Leg",
		rarity = "Common",
		statBonus = 1,
		cosmeticOnly = false,
		price = { currency = Soft, amount = 100 },
		meshAssetId = nil,
	},
	{
		id = "SuneAteGreaves",
		name = "Sune-ate Greaves",
		slot = "Leg",
		rarity = "Rare",
		statBonus = 3,
		cosmeticOnly = false,
		price = { currency = Soft, amount = 400 },
		meshAssetId = nil,
	},
	{
		id = "StormSuneAte",
		name = "Storm Sune-ate",
		slot = "Leg",
		rarity = "Epic",
		statBonus = 0,
		cosmeticOnly = true,
		price = { currency = Premium, amount = 350 },
		meshAssetId = nil,
	},
}

return ItemDefinitions
