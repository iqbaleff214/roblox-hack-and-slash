--!strict
--[[
	Pure fixed-window rate limiter (T-410): at most `maxPerWindow` calls
	within any trailing `windowSeconds` window. Takes the timestamp history
	as an explicit parameter (a plain array, mutated in place) rather than
	owning any state itself, so it doesn't need a Player or any Roblox API —
	`CombatService`/`UltimateGaugeService` each keep one such array per
	player per rate-limited action.
]]

local RateLimiter = {}

-- Prunes `timestamps` to only those within the trailing window, then — if
-- still under `maxPerWindow` — appends `now` and returns true. Returns false
-- (leaving `timestamps` pruned but not appended) if already at the cap.
function RateLimiter.TryConsume(timestamps: { number }, maxPerWindow: number, windowSeconds: number, now: number): boolean
	local i = 1
	while i <= #timestamps do
		if now - timestamps[i] > windowSeconds then
			table.remove(timestamps, i)
		else
			i += 1
		end
	end

	if #timestamps >= maxPerWindow then
		return false
	end

	table.insert(timestamps, now)
	return true
end

return RateLimiter
