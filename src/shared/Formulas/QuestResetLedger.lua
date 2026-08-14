--!strict
--[[
	T-904: pure reset-boundary decisions, injected-clock (both timestamps are
	plain Unix seconds, so this is genuinely testable without `os.time()`).
	Single documented boundary: **00:00 UTC** (T-904's DoD) — a daily reset
	is "crossed a UTC calendar day," a weekly reset is "crossed into a new
	UTC week," both computed from the raw epoch-seconds difference, never
	from a wall-clock/locale-dependent date library.

	A `nil` `lastResetTimestamp` (never reset before — a brand-new profile)
	always counts as crossed, so a fresh player's first login initializes
	cleanly rather than needing separate first-login handling.
]]

local QuestResetLedger = {}

local SECONDS_PER_DAY = 86400

-- Unix epoch (1970-01-01) was a UTC Thursday, i.e. epoch-day 0 = Thursday.
-- The first UTC Monday is epoch-day 4; subtracting 4 before dividing by 7
-- lines up day-of-epoch // 7 with Monday-starting week boundaries (verified
-- in the spec: the bucket changes between epoch-day 3 (Sunday) and 4
-- (Monday), and again between day 10 (Sunday) and 11 (Monday)).
local EPOCH_WEEKDAY_OFFSET_DAYS = 4

function QuestResetLedger.HasCrossedDailyBoundary(lastResetTimestamp: number?, now: number): boolean
	if not lastResetTimestamp then
		return true
	end
	local lastDay = math.floor(lastResetTimestamp / SECONDS_PER_DAY)
	local nowDay = math.floor(now / SECONDS_PER_DAY)
	return nowDay > lastDay
end

function QuestResetLedger.HasCrossedWeeklyBoundary(lastResetTimestamp: number?, now: number): boolean
	if not lastResetTimestamp then
		return true
	end
	local lastWeek = math.floor((lastResetTimestamp / SECONDS_PER_DAY - EPOCH_WEEKDAY_OFFSET_DAYS) / 7)
	local nowWeek = math.floor((now / SECONDS_PER_DAY - EPOCH_WEEKDAY_OFFSET_DAYS) / 7)
	return nowWeek > lastWeek
end

return QuestResetLedger
