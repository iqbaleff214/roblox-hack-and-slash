--!strict
--[[
	Accessory catalog (Head/Body/Arm/Leg — GDD §4.1). An array of `Types.Item`
	records; each carries its own `id`. `meshAssetId` is left `nil` until
	S-103 creates the real models. Stat-affecting items price in SoftCurrency
	(always free-to-earn); cosmetic-only items price in PremiumCurrency — the
	GDD §9.5 guardrail (T-1004) requires that split to hold for every item that
	is ever premium-exclusive.
]]

local Constants = require(script.Parent.Parent.Constants)

local Soft = Constants.Currency.Soft
local Premium = Constants.Currency.Premium

local ItemDefinitions = {
	-- Head
	{
		id = "Kabuto",
		slot = "Head",
		rarity = "Common",
		statBonus = 1,
		cosmeticOnly = false,
		price = { currency = Soft, amount = 100 },
		meshAssetId = nil,
	},
	{
		id = "HanEiKabuto",
		slot = "Head",
		rarity = "Rare",
		statBonus = 3,
		cosmeticOnly = false,
		price = { currency = Soft, amount = 400 },
		meshAssetId = nil,
	},
	{
		id = "OniMenpo",
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
		slot = "Body",
		rarity = "Common",
		statBonus = 1,
		cosmeticOnly = false,
		price = { currency = Soft, amount = 100 },
		meshAssetId = nil,
	},
	{
		id = "DoMaru",
		slot = "Body",
		rarity = "Rare",
		statBonus = 3,
		cosmeticOnly = false,
		price = { currency = Soft, amount = 400 },
		meshAssetId = nil,
	},
	{
		id = "TigerFurDo",
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
		slot = "Arm",
		rarity = "Common",
		statBonus = 1,
		cosmeticOnly = false,
		price = { currency = Soft, amount = 100 },
		meshAssetId = nil,
	},
	{
		id = "KoteBraces",
		slot = "Arm",
		rarity = "Rare",
		statBonus = 3,
		cosmeticOnly = false,
		price = { currency = Soft, amount = 400 },
		meshAssetId = nil,
	},
	{
		id = "DragonKote",
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
		slot = "Leg",
		rarity = "Common",
		statBonus = 1,
		cosmeticOnly = false,
		price = { currency = Soft, amount = 100 },
		meshAssetId = nil,
	},
	{
		id = "SuneAteGreaves",
		slot = "Leg",
		rarity = "Rare",
		statBonus = 3,
		cosmeticOnly = false,
		price = { currency = Soft, amount = 400 },
		meshAssetId = nil,
	},
	{
		id = "StormSuneAte",
		slot = "Leg",
		rarity = "Epic",
		statBonus = 0,
		cosmeticOnly = true,
		price = { currency = Premium, amount = 350 },
		meshAssetId = nil,
	},
}

return ItemDefinitions
