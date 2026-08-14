--!strict
--[[
	Battlefield map catalog (GDD §6). Dict keyed by map id — `BattlefieldBootstrap`
	(T-701) looks these up as `MapDefinitions[mapId]`, so this is a dict, not
	an array like the other Phase 1 catalogs. `battlefieldPlaceId` is a
	placeholder (all maps share the one Battlefield place, T-1402 fills in the
	real PlaceId in Constants.lua, not per-map here).

	`mainRewardItemId` is the map's CTR-style guaranteed showcase item (GDD §5),
	shown in the Lobby's Map Select preview panel and granted once per player
	on that map's first clear (T-903).
]]

local MapDefinitions = {
	Okehazama = {
		id = "Okehazama",
		displayName = "Battle of Okehazama",
		recommendedLevel = 5,
		mainRewardItemId = "OniMenpo",
		waveConfig = {
			{ spawnGroupId = "CampA", enemyId = "Swordsman", count = 6, delaySeconds = 0 },
			{ spawnGroupId = "CampA", enemyId = "Spearman", count = 3, delaySeconds = 5 },
			{ spawnGroupId = "CampA", enemyId = "Commander", count = 1, delaySeconds = 10 },

			{ spawnGroupId = "CampB", enemyId = "ShieldBearer", count = 4, delaySeconds = 0 },
			{ spawnGroupId = "CampB", enemyId = "Thrower", count = 3, delaySeconds = 5 },
			{ spawnGroupId = "CampB", enemyId = "Bomber", count = 2, delaySeconds = 8 },

			{ spawnGroupId = "CampC", enemyId = "Swinger", count = 4, delaySeconds = 0 },
			{ spawnGroupId = "CampC", enemyId = "TreasureCarrier", count = 1, delaySeconds = 3 },
			{ spawnGroupId = "CampC", enemyId = "Commander", count = 1, delaySeconds = 10 },
		},
		objectiveList = {
			{ id = "CaptureCampA", type = "Capture" },
			{ id = "CaptureCampB", type = "Capture" },
			{ id = "CaptureCampC", type = "Capture" },
		},
		midBossIds = { "MatsudairaMotoyasu", "IioMichihiro" },
		finalBossId = "ImagawaYoshimoto",
		battlefieldPlaceId = nil,
	},
}

return MapDefinitions
