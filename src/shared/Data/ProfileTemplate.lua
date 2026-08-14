--!strict
--[[
	ProfileService template (T-201) — new players default-copy this table.
	Shape matches `Types.Profile` exactly (T-004/T-201).

	The starter weapon/ultimate aren't hardcoded here: they're looked up as
	whichever `WeaponDefinitions`/`UltimateDefinitions` entry is priced at 0
	("always owned" per those catalogs' comments), so a new profile's default
	Loadout is genuinely valid against `Types.Loadout` (weaponId/ultimateId are
	required, non-optional strings) rather than an empty, unplayable stub.
]]

local WeaponDefinitions = require(script.Parent.WeaponDefinitions)
local UltimateDefinitions = require(script.Parent.UltimateDefinitions)

local function findStarterId(catalog: { { id: string, price: { amount: number } } }): string
	for _, entry in catalog do
		if entry.price.amount == 0 then
			return entry.id
		end
	end
	error("ProfileTemplate: no 0-price (starter) entry found in catalog")
end

local starterWeaponId = findStarterId(WeaponDefinitions)
local starterUltimateId = findStarterId(UltimateDefinitions)

local ProfileTemplate = {
	version = 1,
	Level = 1,
	XP = 0,
	SoftCurrency = 0,
	PremiumCurrency = 0,
	OwnedItems = {
		[starterWeaponId] = true,
		[starterUltimateId] = true,
	},
	Loadout = {
		weaponId = starterWeaponId,
		ultimateId = starterUltimateId,
		accessories = {},
	},
	LoadoutPresets = {},
	QuestProgress = {},
	BattlePassProgress = {},
	MapStats = {},
	Settings = {},
}

return ProfileTemplate
