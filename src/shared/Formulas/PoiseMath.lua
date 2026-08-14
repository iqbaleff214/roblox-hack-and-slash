--!strict
--[[
	Pure poise-damage math (T-408). `poiseMax <= 0` means immune/not-applicable
	(Foot Soldiers, per T-105 — they have no poise/break state and just die
	through combos, GDD §6.4). `didBreak` is only ever true on the exact tick
	poise crosses from >0 to <=0 — once poise is already 0, further damage
	calls naturally return `didBreak = false` (currentPoise is already 0, so
	`currentPoise > 0` fails), which is what keeps the break event from
	re-triggering during the break window without `PoiseService` needing any
	extra bookkeeping for that specific guarantee.
]]

local PoiseMath = {}

-- Returns (newPoise, didBreak).
function PoiseMath.ApplyDamage(currentPoise: number, poiseMax: number, damage: number): (number, boolean)
	if poiseMax <= 0 then
		return 0, false
	end

	local newPoise = math.max(0, currentPoise - damage)
	local didBreak = newPoise <= 0 and currentPoise > 0
	return newPoise, didBreak
end

return PoiseMath
