--!strict
--[[
	ShieldBearer (GDD §7.1): blocks frontal hits, must be hit from side/back
	— that defensive check is wired at spawn time (EnemySpawnService sets
	`canBeDamagedFrom` on this enemy's EnemyRegistry entry using
	`ShieldBearerBlock.IsBlocked`, consulted by HitboxService, T-404). This
	module only owns the *offensive* half: approach and attack like a basic
	melee unit.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)
local BasicMelee = require(script.Parent.BasicMelee)

return {
	Update = BasicMelee.CreateUpdate(
		Constants.Battlefield.BaselineMeleeAttackRange,
		Constants.Battlefield.FootSoldierAttackCooldownSeconds
	),
}
