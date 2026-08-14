--!strict
--[[
	Pure hitbox geometry (T-404): given an origin, a facing direction, a
	hitboxShape name (from a ComboTrees node), and a list of candidate
	positions, returns which candidates are hit. Plain `{x,y,z}` tables
	instead of Vector3 on purpose — keeps this genuinely dependency-free
	(no Roblox APIs at all), matching the DoD's "given a mocked set of enemy
	positions" framing. `HitboxService` (server) converts real Vector3s to
	this shape when calling in, and applies the actual damage/poise/gauge
	side effects — this module only ever decides who's inside the shape.

	Shape params (radius + a front-facing cone half-angle) cover every
	`hitboxShape` string ComboTrees.lua produces: the six base shapes, their
	"...Wide" combo-finisher variants, "Slam" (heavy finishers - full circle,
	matches a ground-slam reading better than a narrow cone), and "None"
	(the tree's root/neutral node - never actually hits anything).
]]

export type Position = { x: number, y: number, z: number }
export type HitCandidate = { id: string, position: Position }

local HitboxGeometry = {}

local SHAPE_PARAMS: { [string]: { radius: number, coneAngleDegrees: number } } = {
	None = { radius = 0, coneAngleDegrees = 0 },
	Arc = { radius = 8, coneAngleDegrees = 120 },
	ArcWide = { radius = 9, coneAngleDegrees = 180 },
	Thrust = { radius = 10, coneAngleDegrees = 60 },
	ThrustWide = { radius = 11, coneAngleDegrees = 90 },
	Sweep = { radius = 9, coneAngleDegrees = 150 },
	SweepWide = { radius = 10, coneAngleDegrees = 220 },
	Punch = { radius = 6, coneAngleDegrees = 90 },
	PunchWide = { radius = 7, coneAngleDegrees = 120 },
	Line = { radius = 14, coneAngleDegrees = 20 },
	LineWide = { radius = 16, coneAngleDegrees = 30 },
	Slam = { radius = 10, coneAngleDegrees = 360 },
}

HitboxGeometry.ShapeParams = SHAPE_PARAMS

local function distance(a: Position, b: Position): number
	local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function normalize2D(x: number, z: number): (number, number)
	local magnitude = math.sqrt(x * x + z * z)
	if magnitude == 0 then
		return 0, 0
	end
	return x / magnitude, z / magnitude
end

function HitboxGeometry.GetHitTargets(
	origin: Position,
	facing: Position,
	hitboxShape: string,
	candidates: { HitCandidate }
): { string }
	local params = SHAPE_PARAMS[hitboxShape]
	if not params or params.radius <= 0 then
		return {}
	end

	local facingX, facingZ = normalize2D(facing.x, facing.z)
	local isFullCircle = params.coneAngleDegrees >= 360
	local halfAngle = params.coneAngleDegrees / 2

	local hitIds = {}
	for _, candidate in candidates do
		if distance(origin, candidate.position) <= params.radius then
			if isFullCircle then
				table.insert(hitIds, candidate.id)
			else
				local offsetX, offsetZ = candidate.position.x - origin.x, candidate.position.z - origin.z
				local dirX, dirZ = normalize2D(offsetX, offsetZ)
				if dirX == 0 and dirZ == 0 then
					-- Exactly on top of the origin - always considered hit.
					table.insert(hitIds, candidate.id)
				else
					local dot = math.clamp(facingX * dirX + facingZ * dirZ, -1, 1)
					local angleDegrees = math.deg(math.acos(dot))
					if angleDegrees <= halfAngle then
						table.insert(hitIds, candidate.id)
					end
				end
			end
		end
	end

	return hitIds
end

-- Full-circle radius check, no facing/cone involved — used for numeric-radius
-- Ultimates (Types.Ultimate.radiusOrShape as a plain number, T-407).
function HitboxGeometry.GetHitTargetsInRadius(origin: Position, radius: number, candidates: { HitCandidate }): { string }
	local hitIds = {}
	for _, candidate in candidates do
		if distance(origin, candidate.position) <= radius then
			table.insert(hitIds, candidate.id)
		end
	end
	return hitIds
end

return HitboxGeometry
