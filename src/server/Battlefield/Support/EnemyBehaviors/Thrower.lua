--!strict
--[[
	Thrower (GDD §7.1): ranged, lobs projectiles from range, retreats when
	approached. Decision (`Retreat` vs `HoldAndFire`) delegates to the pure
	`ThrowerRangeLogic`; this just carries out whichever it returns.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local ThrowerRangeLogic = require(ReplicatedStorage.Shared.Formulas.ThrowerRangeLogic)
local EnemyMovement = require(script.Parent.Parent.EnemyMovement)
local EnemyInstanceType = require(script.Parent.Parent.EnemyInstanceType)

type EnemyInstance = EnemyInstanceType.EnemyInstance

local PlayerHealthService
local function getPlayerHealthService()
	if not PlayerHealthService then
		PlayerHealthService = Knit.GetService("PlayerHealthService")
	end
	return PlayerHealthService
end

local Thrower = {}

function Thrower.Update(enemy: EnemyInstance, dt: number)
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

	local distance = (targetRoot.Position - enemy.rootPart.Position).Magnitude
	local action = ThrowerRangeLogic.Decide(distance, Constants.Battlefield.ThrowerRetreatThreshold)

	if action == "Retreat" then
		EnemyMovement.MoveAway(enemy.rootPart, targetRoot.Position, Constants.Battlefield.EnemyMoveSpeed, dt)
		return
	end

	if distance > Constants.Battlefield.ThrowerFireRange then
		EnemyMovement.MoveToward(enemy.rootPart, targetRoot.Position, Constants.Battlefield.EnemyMoveSpeed, dt)
		return
	end

	local lastAttack = (enemy.custom.lastAttackTime :: number?) or 0
	if os.clock() - lastAttack < Constants.Battlefield.ThrowerFireCooldownSeconds then
		return
	end
	enemy.custom.lastAttackTime = os.clock()
	getPlayerHealthService():ApplyEnemyDamage(target, enemy.damage)
end

return Thrower
