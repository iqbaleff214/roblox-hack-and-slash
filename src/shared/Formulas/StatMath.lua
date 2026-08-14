--!strict
--[[
	Pure stat calculation (T-301): base-by-level formula + the sum of equipped
	accessories' statBonus. Takes pre-resolved statBonus numbers, not item ids
	— resolving an id to its catalog entry is `StatsService`'s job (it already
	has to touch `ReplicatedStorage.Shared.Data`), which keeps this module
	genuinely dependency-free and testable with zero Roblox APIs, per its own
	DoD ("importable and testable with no Roblox API calls").

	Per GDD §4.1, accessory stat bonuses apply to HP/Attack/Defense only
	("Minor stat bonus (defense/HP/attack, small %)") — Stamina and Ultimate
	Charge Rate come from the level curve alone. Exact curve constants are a
	balancing-pass concern, same as XPCurve.lua.
]]

export type Stats = {
	HP: number,
	Attack: number,
	Defense: number,
	Stamina: number,
	UltimateChargeRate: number,
}

local StatMath = {}

local function baseHP(level: number): number
	return 100 + (level - 1) * 15
end

local function baseAttack(level: number): number
	return 10 + (level - 1) * 2
end

local function baseDefense(level: number): number
	return 5 + (level - 1) * 1
end

local function baseStamina(level: number): number
	return 100 + (level - 1) * 3
end

local function baseUltimateChargeRate(_level: number): number
	return 1.0
end

function StatMath.ComputeStats(level: number, accessoryStatBonuses: { number }): Stats
	assert(level >= 1, "level must be >= 1")

	local totalBonus = 0
	for _, bonus in accessoryStatBonuses do
		totalBonus += bonus
	end

	return {
		HP = baseHP(level) + totalBonus,
		Attack = baseAttack(level) + totalBonus,
		Defense = baseDefense(level) + totalBonus,
		Stamina = baseStamina(level),
		UltimateChargeRate = baseUltimateChargeRate(level),
	}
end

return StatMath
