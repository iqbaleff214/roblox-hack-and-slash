--!strict
--[[
	Pure input-debounce check (T-401). `UserInputService.InputBegan` only
	fires once per physical press already (no OS-style key-repeat events),
	so this mainly guards against the same action being bound to more than
	one input source firing "simultaneously" (e.g. Phase 11's gamepad/touch
	remap layered on top). Extracted so the actual `UserInputService` wiring
	— which can't be meaningfully unit-tested outside a live client — stays a
	thin shell around this.
]]

local InputDebounce = {}

function InputDebounce.ShouldFire(lastFiredTime: number?, now: number, minIntervalSeconds: number): boolean
	return lastFiredTime == nil or (now - lastFiredTime) >= minIntervalSeconds
end

return InputDebounce
