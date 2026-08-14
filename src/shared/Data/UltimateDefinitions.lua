--!strict
--[[
	Ultimate Attack catalog (GDD §4.3 — "Basara Art" style screen-clearer,
	independent of equipped weapon). An array of `Types.Ultimate` records.
	`vfxAssetId` is left `nil` until S-104 creates the real effects.
]]

local Constants = require(script.Parent.Parent.Constants)

local Soft = Constants.Currency.Soft

local UltimateDefinitions = {
	{
		id = "SkyRendingBlow",
		name = "Sky-Rending Blow",
		damage = 80,
		radiusOrShape = 16, -- studs, AoE radius centered on the player
		vfxAssetId = nil,
		price = { currency = Soft, amount = 0 }, -- starter ultimate, always owned
	},
	{
		id = "CrimsonWhirlwind",
		name = "Crimson Whirlwind",
		damage = 65,
		radiusOrShape = 20,
		vfxAssetId = nil,
		price = { currency = Soft, amount = 700 },
	},
	{
		id = "ThunderingCharge",
		name = "Thundering Charge",
		damage = 100,
		radiusOrShape = "Line",
		vfxAssetId = nil,
		price = { currency = Soft, amount = 900 },
	},
}

return UltimateDefinitions
