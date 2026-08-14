--!strict
--[[
	T-705: Commander — a basic melee attacker (GDD §7.2, reuses BasicMelee)
	that also buffs nearby Foot Soldiers' outgoing damage while alive.
	Implemented as a damage-only buff, not damage+defense — GDD §7.2 gives
	"damage/defense aura" as an example, not a requirement for both; a
	damage buff alone is enough to make "killing the commander weakens the
	squad" (GDD §7.2) meaningfully true, and keeps this from needing to
	thread a buff multiplier through every variant's *incoming*-damage path
	too.

	The buff itself is a pure per-tick radius query (`CommanderAura`), not a
	stateful "buff applied" flag anywhere — every tick, this sets
	`custom.buffed` on whichever Foot Soldiers are currently in range and
	implicitly leaves everyone else `nil`/unbuffed. Once this Commander
	dies, `EnemySpawnService` simply stops calling this Update function for
	it (dead enemies are skipped) — so no other Foot Soldier ever gets
	`buffed` set again after that point, which is what makes "no lingering
	buff after death" (T-705's DoD) true on the very same tick, not the next.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local CommanderAura = require(ReplicatedStorage.Shared.Formulas.CommanderAura)
local EnemyRegistry = require(ServerScriptService.Server.Support.EnemyRegistry)
local BasicMelee = require(script.Parent.BasicMelee)
local EnemyInstanceType = require(script.Parent.Parent.EnemyInstanceType)

type EnemyInstance = EnemyInstanceType.EnemyInstance

local meleeUpdate =
	BasicMelee.CreateUpdate(Constants.Battlefield.CommanderAttackRange, Constants.Battlefield.FootSoldierAttackCooldownSeconds)

local EnemySpawnService
local function getEnemySpawnService()
	if not EnemySpawnService then
		EnemySpawnService = Knit.GetService("EnemySpawnService")
	end
	return EnemySpawnService
end

local Commander = {}

function Commander.Update(enemy: EnemyInstance, dt: number)
	meleeUpdate(enemy, dt)

	if enemy.state == "Dead" then
		return
	end

	local position = enemy.rootPart.Position
	local commanderPosition = { x = position.X, y = position.Y, z = position.Z }

	local candidates = {}
	for _, other in EnemyRegistry.GetAll() do
		if other.id ~= enemy.id and other.tier == "FootSoldier" then
			table.insert(candidates, { id = other.id, position = other.position })
		end
	end

	local buffedIds = CommanderAura.GetBuffedIds(commanderPosition, candidates, Constants.Battlefield.CommanderAuraRadius)
	local buffedSet = {}
	for _, id in buffedIds do
		buffedSet[id] = true
	end

	local spawnService = getEnemySpawnService()
	for _, candidate in candidates do
		local otherInstance = spawnService:GetInstance(candidate.id)
		if otherInstance then
			otherInstance.custom.buffed = buffedSet[candidate.id] or false
		end
	end
end

return Commander
