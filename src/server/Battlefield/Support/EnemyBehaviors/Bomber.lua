--!strict
--[[
	Bomber (GDD §7.1): rushes the player and detonates in an AoE. Detonation
	condition delegates to the pure `BomberDetonation` (proximity or fuse
	expiry, whichever first); the AoE itself hits every player in blast
	radius via `EnemyMovement.GetPlayersInRadius`, not just the current
	target.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local BomberDetonation = require(ReplicatedStorage.Shared.Formulas.BomberDetonation)
local EnemyMovement = require(script.Parent.Parent.EnemyMovement)
local EnemyRegistry = require(ServerScriptService.Server.Support.EnemyRegistry)
local EnemyInstanceType = require(script.Parent.Parent.EnemyInstanceType)

type EnemyInstance = EnemyInstanceType.EnemyInstance

local PlayerHealthService
local function getPlayerHealthService()
	if not PlayerHealthService then
		PlayerHealthService = Knit.GetService("PlayerHealthService")
	end
	return PlayerHealthService
end

local Bomber = {}

local function detonate(enemy: EnemyInstance)
	local healthService = getPlayerHealthService()
	for _, player in EnemyMovement.GetPlayersInRadius(enemy.rootPart.Position, Constants.Battlefield.BomberProximityThreshold * 2) do
		healthService:ApplyEnemyDamage(player, enemy.damage)
	end

	enemy.state = "Dead"
	EnemyRegistry.Unregister(enemy.id)
	enemy.model:Destroy()
end

function Bomber.Update(enemy: EnemyInstance, dt: number)
	if enemy.state == "Dead" then
		return
	end

	local target = enemy.target
	if not target or not target.Character then
		enemy.target = EnemyMovement.FindNearestPlayer(enemy.rootPart.Position)
		enemy.custom.fuseStartedAt = (enemy.custom.fuseStartedAt :: number?) or os.clock()
		return
	end

	local targetRoot = target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then
		enemy.target = nil
		return
	end

	enemy.custom.fuseStartedAt = (enemy.custom.fuseStartedAt :: number?) or os.clock()
	local distance = (targetRoot.Position - enemy.rootPart.Position).Magnitude
	local fuseElapsed = os.clock() - (enemy.custom.fuseStartedAt :: number)

	local shouldDetonate = BomberDetonation.ShouldDetonate(
		distance,
		Constants.Battlefield.BomberProximityThreshold,
		fuseElapsed,
		Constants.Battlefield.BomberFuseDurationSeconds
	)

	if shouldDetonate then
		detonate(enemy)
		return
	end

	EnemyMovement.MoveToward(enemy.rootPart, targetRoot.Position, Constants.Battlefield.EnemyMoveSpeed, dt)
end

return Bomber
