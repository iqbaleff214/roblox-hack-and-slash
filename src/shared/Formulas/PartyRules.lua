--!strict
--[[
	Pure party-rule checks (T-604): the cap check and the leader-only check,
	pulled out of PartyService so they're genuinely testable without a live
	multi-player Studio session — same rigor as the rest of this backlog's
	stateful services. Player identity is typed `any` on purpose: production
	code passes real `Player` instances, tests pass plain strings, since
	these functions only ever compare identity (`==`), never touch any
	Player-specific API.
]]

local PartyRules = {}

function PartyRules.CanAddMember(currentSize: number, maxSize: number): boolean
	return currentSize < maxSize
end

-- Only the leader can kick, and never themselves (use LeaveParty for that).
function PartyRules.CanKick(leader: any, requester: any, target: any): boolean
	if requester ~= leader then
		return false
	end
	if target == leader then
		return false
	end
	return true
end

return PartyRules
