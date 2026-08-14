--!strict
--[[ Spearman (GDD §7.1): melee thrust with slightly longer reach - punishes standing still at combo range. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)
local BasicMelee = require(script.Parent.BasicMelee)

return {
	Update = BasicMelee.CreateUpdate(
		Constants.Battlefield.SpearmanAttackRange,
		Constants.Battlefield.FootSoldierAttackCooldownSeconds
	),
}
