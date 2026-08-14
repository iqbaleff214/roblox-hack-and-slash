--!strict
--[[
	Pure XP-award mutation logic (T-302), operating directly on
	`{XP: number, Level: number}` instead of a Player — no ProfileService/Player
	dependency. `LevelService` (Knit) is a thin wrapper: resolve player ->
	profile.Data, call this, fire `LevelUp` once per level actually gained
	(not once per award), letting `StatsService` react via the server-internal
	signal.
]]

local XPCurve = require(script.Parent.XPCurve)

local LevelLedger = {}

-- Mutates `data.XP`/`data.Level` in place. Returns the list of levels
-- gained, in order (e.g. `{6, 7, 8}` for a jump spanning 3 levels) — empty
-- if the award didn't cross a level threshold.
function LevelLedger.AwardXP(data: { XP: number, Level: number }, amount: number): { number }
	assert(amount >= 0, "amount must be >= 0")

	local oldLevel = XPCurve.LevelForXP(data.XP)
	data.XP += amount
	local newLevel = XPCurve.LevelForXP(data.XP)
	data.Level = newLevel

	local levelsGained = {}
	for level = oldLevel + 1, newLevel do
		table.insert(levelsGained, level)
	end
	return levelsGained
end

return LevelLedger
