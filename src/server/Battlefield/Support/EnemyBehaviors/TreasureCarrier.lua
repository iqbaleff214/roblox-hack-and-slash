--!strict
--[[
	TreasureCarrier (GDD §7.1): "passive/fleeing, no attack (or very weak),
	drops bonus loot/currency on kill." This module only owns the fleeing —
	it never attacks. The on-kill loot roll uses its own dedicated
	`RewardTables.TreasureCarrier` entry (T-704's own decision point:
	"decide and test whichever" table), applied generically at death by
	EnemySpawnService alongside every other variant, not here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)
local EnemyMovement = require(script.Parent.Parent.EnemyMovement)
local EnemyInstanceType = require(script.Parent.Parent.EnemyInstanceType)

type EnemyInstance = EnemyInstanceType.EnemyInstance

local TreasureCarrier = {}

function TreasureCarrier.Update(enemy: EnemyInstance, dt: number)
	if enemy.state == "Dead" then
		return
	end

	local target = enemy.target
	if not target or not target.Character then
		enemy.target = EnemyMovement.FindNearestPlayer(enemy.rootPart.Position)
		return
	end

	local targetRoot = target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then
		enemy.target = nil
		return
	end

	EnemyMovement.MoveAway(enemy.rootPart, targetRoot.Position, Constants.Battlefield.TreasureCarrierMoveSpeed, dt)
end

return TreasureCarrier
