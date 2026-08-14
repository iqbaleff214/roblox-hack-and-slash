--!strict
--[[
	Shared "seek target, attack when in range" update-loop factory (T-704).
	Swordsman/Spearman/Swinger/Commander (T-705) only differ in
	range/cooldown tuning per GDD §7.1/§7.2, not underlying behavior, so
	they're each a one-line `CreateUpdate(range, cooldown)` call rather than
	four near-duplicate files.

	`enemy.custom.buffed` (set externally by CommanderBehavior, T-705) scales
	outgoing damage — this is how the Commander's aura actually affects
	combat, not just a cosmetic flag.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local EnemyFSM = require(ReplicatedStorage.Shared.Formulas.EnemyFSM)
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

local BasicMelee = {}

function BasicMelee.CreateUpdate(attackRange: number, attackCooldownSeconds: number): (EnemyInstance, number) -> ()
	return function(enemy: EnemyInstance, dt: number)
		if enemy.state == "Dead" then
			return
		end

		local target = enemy.target
		if not target or not target.Parent or not target.Character then
			enemy.target = EnemyMovement.FindNearestPlayer(enemy.rootPart.Position)
			return
		end

		local targetRoot = target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not targetRoot then
			enemy.target = nil
			return
		end

		local distance = (targetRoot.Position - enemy.rootPart.Position).Magnitude
		if distance > attackRange then
			enemy.state = EnemyFSM.Transition(enemy.state :: EnemyFSM.EnemyState, "OutOfRange")
			EnemyMovement.MoveToward(enemy.rootPart, targetRoot.Position, Constants.Battlefield.EnemyMoveSpeed, dt)
			return
		end

		enemy.state = EnemyFSM.Transition(enemy.state :: EnemyFSM.EnemyState, "InRange")

		local lastAttack = (enemy.custom.lastAttackTime :: number?) or 0
		if os.clock() - lastAttack < attackCooldownSeconds then
			return
		end
		enemy.custom.lastAttackTime = os.clock()

		local outgoingDamage = enemy.damage
		if enemy.custom.buffed then
			outgoingDamage *= Constants.Battlefield.CommanderAuraDamageMultiplier
		end

		getPlayerHealthService():ApplyEnemyDamage(target, outgoingDamage)
	end
end

return BasicMelee
