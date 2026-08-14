--!strict
--[[
	Pure Bomber detonation decision (T-704 — GDD §7.1: "carries a bomb,
	rushes player and detonates (AoE) or lobs bomb at telegraphed spot").
	Detonates on proximity OR fuse expiry, whichever comes first — both
	paths are independently checked so the test cases can exercise each.
]]

export type Reason = "Proximity" | "FuseExpired"

local BomberDetonation = {}

function BomberDetonation.ShouldDetonate(
	distanceToPlayer: number,
	proximityThreshold: number,
	fuseElapsedSeconds: number,
	fuseDurationSeconds: number
): (boolean, Reason?)
	if distanceToPlayer <= proximityThreshold then
		return true, "Proximity"
	end
	if fuseElapsedSeconds >= fuseDurationSeconds then
		return true, "FuseExpired"
	end
	return false, nil
end

return BomberDetonation
