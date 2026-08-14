--!strict
--[[
	Pure map-level gate check (T-303). Takes `tolerance` explicitly rather
	than reading `Constants.MapLevelTolerance` itself, keeping this fully
	dependency-free/testable — callers (PortalService T-606, MapSelectController
	T-603) pass `Constants.MapLevelTolerance`, which is where the DoD's
	"documented tolerance constant" actually lives.
]]

local MapGating = {}

function MapGating.IsMapUnlocked(playerLevel: number, map: { recommendedLevel: number }, tolerance: number): boolean
	return playerLevel >= (map.recommendedLevel - tolerance)
end

return MapGating
