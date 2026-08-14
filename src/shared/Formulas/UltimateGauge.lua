--!strict
--[[
	Pure Ultimate Gauge math (T-407): accumulation with clamping, and the
	full-gauge check. `UltimateGaugeService` (server) owns the actual
	per-player number and resets it to 0 on successful use — that reset is a
	trivial one-line mutation, not worth a function here.
]]

local UltimateGauge = {}

UltimateGauge.MaxGauge = 100

function UltimateGauge.Add(currentGauge: number, amount: number): number
	return math.clamp(currentGauge + amount, 0, UltimateGauge.MaxGauge)
end

function UltimateGauge.CanUseUltimate(currentGauge: number): boolean
	return currentGauge >= UltimateGauge.MaxGauge
end

return UltimateGauge
