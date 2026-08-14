--!strict
--[[
	T-710: on Final Boss defeat, halts further spawning (before anything else
	— T-710's DoD: no enemy spawns into an already-cleared map during the
	results screen), shows a results screen, then teleports the party back
	to the Lobby place after the player acknowledges or a timeout elapses.

	Real reward computation is explicitly T-901-T-903's job (Phase 9, not
	yet built) — `HandleFinalBossDefeated` fires `ResultsScreenShown` with a
	minimal, clearly-labeled placeholder payload (map id + clear time only,
	no XP/currency/rank) rather than guessing at Phase 9's not-yet-designed
	rank/reward formulas. Phase 9 extends that payload's contents, not this
	service's flow.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)

local RESULTS_SCREEN_TIMEOUT_SECONDS = 15

local MapClearService = Knit.CreateService({
	Name = "MapClearService",
	Client = {
		-- (payload: { mapId: string, clearedAt: number }) — Phase 9 extends
		-- this payload's contents once T-901-T-903 exist.
		ResultsScreenShown = Knit.CreateSignal(),
	},
})

local spawningHalted = false
local cleared = false

-- Server-internal — `EnemySpawnService` checks this before every wave entry
-- spawn (its own `waveConfig` timers are the only spawn path still capable
-- of firing after the map is already cleared; `MidBossController`/
-- `FinalBossController` each spawn once, up front, well before this can
-- ever be true).
function MapClearService:IsSpawningHalted(): boolean
	return spawningHalted
end

local function returnPartyToLobby()
	local lobbyPlaceId = Constants.PlaceIds.Lobby
	if not lobbyPlaceId then
		warn("[MapClearService] Constants.PlaceIds.Lobby not set (T-1402 pending) - cannot teleport party back")
		return
	end

	local players = Players:GetPlayers()
	if #players == 0 then
		return
	end

	local ok, err = pcall(function()
		TeleportService:TeleportAsync(lobbyPlaceId, players)
	end)
	if not ok then
		warn("[MapClearService] return-to-Lobby teleport failed: " .. tostring(err))
	end
end

function MapClearService:HandleFinalBossDefeated(mapId: string)
	if cleared then
		return
	end
	cleared = true
	spawningHalted = true

	local payload = { mapId = mapId, clearedAt = os.time() }
	self.Client.ResultsScreenShown:FireAll(payload)

	task.delay(RESULTS_SCREEN_TIMEOUT_SECONDS, returnPartyToLobby)
end

-- Lets a player skip the results-screen timeout once everyone in the party
-- has seen it. Any single acknowledgment triggers the party-wide teleport
-- (no vote/wait-for-all gate specified by the GDD).
function MapClearService:AcknowledgeResults()
	if not cleared then
		return
	end
	returnPartyToLobby()
end

function MapClearService.Client:AcknowledgeResults(_player: Player)
	self.Server:AcknowledgeResults()
end

function MapClearService:KnitInit()
	local BattlefieldBootstrap = Knit.GetService("BattlefieldBootstrap")
	local FinalBossController = Knit.GetService("FinalBossController")
	FinalBossController.Defeated:Connect(function()
		-- The real map id, not the boss's own `definitionId` (a past bug —
		-- `FinalBossController.Defeated`'s first argument is the boss id,
		-- e.g. "ImagawaYoshimoto", never the map id; `BattlefieldBootstrap`
		-- is this server's single source of truth for which map it's hosting).
		local mapId = BattlefieldBootstrap:GetCurrentMapId() or "Unknown"
		self:HandleFinalBossDefeated(mapId)
	end)
end

return MapClearService
