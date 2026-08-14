--!strict
--[[
	Pure "which map does this Battlefield server host" resolution (T-701).
	Takes TeleportData (or nil) and the MapDefinitions catalog, and decides:
	load this map, or fail with a reason. Extracted so the missing-mapId and
	invalid-mapId fallback paths are genuinely testable without a live
	Player — `Player:Kick()` can't be meaningfully unit-tested, but the
	*decision* of whether to kick can be.
]]

export type TeleportData = { mapId: string? }?
export type Result = { ok: true, mapId: string } | { ok: false, reason: string }

local BattlefieldMapResolution = {}

function BattlefieldMapResolution.Resolve(teleportData: TeleportData, mapDefinitions: { [string]: any }): Result
	if not teleportData or typeof(teleportData.mapId) ~= "string" then
		return { ok = false, reason = "MissingMapId" }
	end

	local mapId = teleportData.mapId :: string
	if not mapDefinitions[mapId] then
		return { ok = false, reason = "UnknownMapId" }
	end

	return { ok = true, mapId = mapId }
end

return BattlefieldMapResolution
