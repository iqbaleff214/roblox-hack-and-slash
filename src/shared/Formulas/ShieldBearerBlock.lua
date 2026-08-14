--!strict
--[[
	Pure frontal-block geometry (T-704, ShieldBearer — GDD §7.1: "Blocks
	frontal hits, must be hit from side/back or staggered"). A hit is
	blocked if the attacker is within the defender's frontal arc; side/rear
	hits bypass the shield. Plain `{x,y,z}` positions, consistent with
	HitboxGeometry/TargetSelect.
]]

export type Position = { x: number, y: number, z: number }

local ShieldBearerBlock = {}

local FRONTAL_ARC_DEGREES = 120 -- +/- 60 degrees from dead-ahead

local function normalize2D(x: number, z: number): (number, number)
	local magnitude = math.sqrt(x * x + z * z)
	if magnitude == 0 then
		return 0, 0
	end
	return x / magnitude, z / magnitude
end

function ShieldBearerBlock.IsBlocked(defenderPosition: Position, defenderFacing: Position, attackerPosition: Position): boolean
	local facingX, facingZ = normalize2D(defenderFacing.x, defenderFacing.z)
	local offsetX, offsetZ = attackerPosition.x - defenderPosition.x, attackerPosition.z - defenderPosition.z
	local dirX, dirZ = normalize2D(offsetX, offsetZ)

	if dirX == 0 and dirZ == 0 then
		return true -- attacker exactly on top of defender - treat as frontal
	end

	local dot = math.clamp(facingX * dirX + facingZ * dirZ, -1, 1)
	local angleDegrees = math.deg(math.acos(dot))
	return angleDegrees <= FRONTAL_ARC_DEGREES / 2
end

return ShieldBearerBlock
