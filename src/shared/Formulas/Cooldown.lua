--!strict
--[[
	Pure cooldown check (T-406 special-attack cooldown; also the "is a
	rate-limit window still active" building block conceptually shared with
	T-410, though T-410's actual burst-limiting uses RateLimiter.lua since
	that's a max-N-per-window problem rather than a single-timer one).
]]

local Cooldown = {}

function Cooldown.CanUse(lastUsedTime: number?, cooldownSeconds: number, now: number): boolean
	return lastUsedTime == nil or (now - lastUsedTime) >= cooldownSeconds
end

return Cooldown
