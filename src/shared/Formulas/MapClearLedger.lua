--!strict
--[[
	T-903: pure "is this the player's first clear of this map" decision,
	operating on a `profile.Data.MapStats[mapId]` entry. This is the DoD's
	actual idempotency guarantee — `mainRewardGranted` only ever transitions
	false/absent -> true, never back, so calling `RecordClear` again after a
	first clear can never re-grant the Main Reward, no matter how many times
	`MapClearRewardService` calls it (e.g. a retried grant after a partial
	failure).
]]

local MapClearLedger = {}

export type MapStatsEntry = { clearCount: number, mainRewardGranted: boolean }

function MapClearLedger.RecordClear(existingEntry: MapStatsEntry?): (MapStatsEntry, boolean)
	local isFirstClear = not existingEntry or not existingEntry.mainRewardGranted
	local newEntry: MapStatsEntry = {
		clearCount = (if existingEntry then existingEntry.clearCount else 0) + 1,
		mainRewardGranted = true,
	}
	return newEntry, isFirstClear
end

return MapClearLedger
