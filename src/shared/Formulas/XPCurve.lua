--!strict
--[[
	Level <-> XP conversion (GDD §3.1: "diminishing-return curve" — XP required
	per level grows, so raw grind speed naturally decelerates at higher
	levels; no hard level cap). Pure, no Roblox APIs. Exact tuning (the base
	constant) is a balancing-pass concern, not fixed here.
]]

local XPCurve = {}

local BASE_XP_PER_LEVEL = 50

-- Cumulative XP required to REACH `level` (i.e. XPForLevel(1) == 0).
function XPCurve.XPForLevel(level: number): number
	assert(level >= 1, "level must be >= 1")
	return BASE_XP_PER_LEVEL * (level - 1) * level
end

-- Highest level whose XPForLevel(level) <= xp.
function XPCurve.LevelForXP(xp: number): number
	assert(xp >= 0, "xp must be >= 0")

	-- Closed-form inverse of the quadratic as a starting estimate, corrected
	-- below for float error so the round-trip with XPForLevel is exact.
	local estimate = math.floor((1 + math.sqrt(1 + (4 * xp) / BASE_XP_PER_LEVEL)) / 2)
	local level = math.max(1, estimate)

	while XPCurve.XPForLevel(level + 1) <= xp do
		level += 1
	end
	while level > 1 and XPCurve.XPForLevel(level) > xp do
		level -= 1
	end

	return level
end

return XPCurve
