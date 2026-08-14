--!strict
--[[
	T-408: poise/stagger tracking, keyed by enemyId (not a Roblox Instance —
	stays decoupled from however Phase 7 ends up modeling enemy instances).
	No `.Client` methods — poise is never a client action, only a side effect
	of hits landing (applied via HitboxService). Phase 7's EnemySpawnService
	calls RegisterEnemy/UnregisterEnemy as enemies spawn/die.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local PoiseMath = require(ReplicatedStorage.Shared.Formulas.PoiseMath)

local PoiseService = Knit.CreateService({
	Name = "PoiseService",
	Client = {},
})

type PoiseEntry = {
	poise: number,
	poiseMax: number,
	breakUntil: number?,
}

local poiseStates: { [string]: PoiseEntry } = {}

function PoiseService:RegisterEnemy(enemyId: string, poiseMax: number)
	poiseStates[enemyId] = { poise = poiseMax, poiseMax = poiseMax, breakUntil = nil }
end

function PoiseService:UnregisterEnemy(enemyId: string)
	poiseStates[enemyId] = nil
end

function PoiseService:ApplyPoiseDamage(enemyId: string, damage: number)
	local state = poiseStates[enemyId]
	if not state or state.poiseMax <= 0 then
		return
	end

	local newPoise, didBreak = PoiseMath.ApplyDamage(state.poise, state.poiseMax, damage)
	state.poise = newPoise

	if didBreak then
		local windowEnd = os.clock() + Constants.Combat.PoiseBreakWindowSeconds
		state.breakUntil = windowEnd

		task.delay(Constants.Combat.PoiseBreakWindowSeconds, function()
			local current = poiseStates[enemyId]
			-- Only regenerate if this is still the same break window (a
			-- fresh break during the window would have set a newer one).
			if current and current.breakUntil == windowEnd then
				current.poise = current.poiseMax
				current.breakUntil = nil
			end
		end)
	end
end

function PoiseService:IsBroken(enemyId: string): boolean
	local state = poiseStates[enemyId]
	return state ~= nil and state.breakUntil ~= nil and os.clock() < (state.breakUntil :: number)
end

function PoiseService:GetPoise(enemyId: string): number?
	local state = poiseStates[enemyId]
	return state and state.poise
end

return PoiseService
