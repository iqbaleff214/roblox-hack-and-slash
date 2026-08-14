--!strict
--[[
	Pure ranged-retreat decision (T-704, Thrower — GDD §7.1: "Ranged, lobs
	projectiles from range, retreats when approached"). Below
	`retreatThreshold` studs, retreat; at or beyond it, hold position and
	fire.
]]

export type Action = "Retreat" | "HoldAndFire"

local ThrowerRangeLogic = {}

function ThrowerRangeLogic.Decide(distanceToPlayer: number, retreatThreshold: number): Action
	if distanceToPlayer < retreatThreshold then
		return "Retreat"
	end
	return "HoldAndFire"
end

return ThrowerRangeLogic
