--!strict
--[[
	Pure subset selection for `RandomPool`-flagged destructible boxes
	(T-708, GDD §6.3: "fixed placements plus a few random spawn points per
	playthrough"). Given every `RandomPool` candidate id and how many should
	actually spawn this instance, picks a subset via Fisher-Yates. Takes the
	shuffle's random draws as an injected parameter (one `[0,1)` value per
	swap step) instead of calling `math.random()` itself, so it's
	deterministic and testable — production code passes real random draws.
]]

local DestructibleBoxPool = {}

function DestructibleBoxPool.SelectSubset(candidateIds: { string }, count: number, randomValues: { number }): { string }
	local pool = table.clone(candidateIds)
	local n = #pool
	for i = n, 2, -1 do
		local randomValue = randomValues[n - i + 1] or 0
		local j = math.floor(randomValue * i) + 1
		pool[i], pool[j] = pool[j], pool[i]
	end

	local selected = {}
	for i = 1, math.min(count, #pool) do
		table.insert(selected, pool[i])
	end
	return selected
end

return DestructibleBoxPool
