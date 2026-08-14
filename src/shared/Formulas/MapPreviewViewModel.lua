--!strict
--[[
	Pure view-model for the Map Select preview panel (T-603). Takes the map
	definition and its already-resolved Main Reward catalog entry (the
	caller looks that up — this module doesn't know about ItemDefinitions/
	WeaponDefinitions/UltimateDefinitions, keeping it genuinely
	dependency-free) and produces exactly the fields the preview panel
	shows. This is what makes the panel data-driven off
	`MapDefinitions.mainRewardItemId` (T-603's DoD) instead of any
	per-map hardcoding in the UI script.
]]

export type PreviewFields = {
	mapId: string,
	displayName: string,
	recommendedLevel: number,
	mainRewardId: string,
	mainRewardName: string,
}

local MapPreviewViewModel = {}

function MapPreviewViewModel.BuildPreview(map: any, mainRewardItem: any): PreviewFields
	return {
		mapId = map.id,
		displayName = map.displayName,
		recommendedLevel = map.recommendedLevel,
		mainRewardId = map.mainRewardItemId,
		mainRewardName = if mainRewardItem then mainRewardItem.name else map.mainRewardItemId,
	}
end

return MapPreviewViewModel
