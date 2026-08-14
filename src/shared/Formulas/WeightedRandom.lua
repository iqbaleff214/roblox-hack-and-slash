--!strict
--[[
	Pure weighted-random pick over a list of `{ weight: number, ... }` entries.
	Takes the random draw as a parameter instead of calling math.random()
	itself, so it's deterministic and testable — callers pass math.random()
	(or a seeded generator) in production. Used by RewardTables (T-107) and,
	later, DestructibleBoxService (T-708) / enemy loot rolls (T-901).
]]

local WeightedRandom = {}

export type WeightedEntry = { weight: number, [string]: any }

function WeightedRandom.Pick<T>(entries: { T & WeightedEntry }, randomValue01: number): T
	assert(#entries > 0, "WeightedRandom.Pick requires at least one entry")
	assert(randomValue01 >= 0 and randomValue01 < 1, "randomValue01 must be in [0, 1)")

	local total = 0
	for _, entry in entries do
		total += entry.weight
	end

	local roll = randomValue01 * total
	local cumulative = 0
	for _, entry in entries do
		cumulative += entry.weight
		if roll < cumulative then
			return entry
		end
	end

	return entries[#entries]
end

return WeightedRandom
