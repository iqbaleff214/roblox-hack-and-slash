--!strict
--[[
	Weapon catalog (GDD §4.2). An array of `Types.Weapon` records. `comboTreeId`
	points at a matching key in `ComboTrees.lua` (T-104) — one tree per weapon,
	same id. `animationIds` is a placeholder table (keys filled with real
	animation ids by S-102); left empty here on purpose. Weapon is fixed for
	the whole battlefield run (GDD §4.2) — chosen only in the Lobby loadout.
]]

local Constants = require(script.Parent.Parent.Constants)

local Soft = Constants.Currency.Soft

local WeaponDefinitions = {
	{
		id = "Katana",
		name = "Katana",
		comboTreeId = "Katana",
		baseDamage = 10,
		rarity = "Common",
		animationIds = {},
		price = { currency = Soft, amount = 0 }, -- starter weapon, always owned
	},
	{
		id = "Yari",
		name = "Yari Spear",
		comboTreeId = "Yari",
		baseDamage = 11,
		rarity = "Rare",
		animationIds = {},
		price = { currency = Soft, amount = 500 },
	},
	{
		id = "Naginata",
		name = "Naginata",
		comboTreeId = "Naginata",
		baseDamage = 12,
		rarity = "Rare",
		animationIds = {},
		price = { currency = Soft, amount = 600 },
	},
	{
		id = "TwinBlades",
		name = "Twin Blades",
		comboTreeId = "TwinBlades",
		baseDamage = 8,
		rarity = "Epic",
		animationIds = {},
		price = { currency = Soft, amount = 800 },
	},
	{
		id = "Fists",
		name = "Iron Fists",
		comboTreeId = "Fists",
		baseDamage = 9,
		rarity = "Common",
		animationIds = {},
		price = { currency = Soft, amount = 300 },
	},
	{
		id = "Bow",
		name = "War Bow",
		comboTreeId = "Bow",
		baseDamage = 8,
		rarity = "Epic",
		animationIds = {},
		price = { currency = Soft, amount = 800 },
	},
}

return WeaponDefinitions
