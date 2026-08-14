--!strict
--[[ Swinger/Berserker (GDD §7.1): wide sweeping melee swing - area-denial, discourages balling up. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)
local BasicMelee = require(script.Parent.BasicMelee)

return {
	Update = BasicMelee.CreateUpdate(
		Constants.Battlefield.SwingerAttackRange,
		Constants.Battlefield.FootSoldierAttackCooldownSeconds
	),
}
