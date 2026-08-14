--!strict
--[[
	Pure objective-gate check (T-709). The Final Boss arena gate opens only
	once every *required* objective is complete — side objectives are
	optional/bonus-only per GDD §6.2 and never gate it.
]]

export type Objective = { id: string, required: boolean, complete: boolean }

local ObjectiveGate = {}

function ObjectiveGate.IsGateOpen(objectives: { Objective }): boolean
	for _, objective in objectives do
		if objective.required and not objective.complete then
			return false
		end
	end
	return true
end

return ObjectiveGate
