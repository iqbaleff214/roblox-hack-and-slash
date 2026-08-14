--!strict
--[[ Swordsman (GDD §7.1): basic melee swing, short windup - baseline filler. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)
local BasicMelee = require(script.Parent.BasicMelee)

return {
	Update = BasicMelee.CreateUpdate(
		Constants.Battlefield.BaselineMeleeAttackRange,
		Constants.Battlefield.FootSoldierAttackCooldownSeconds
	),
}
