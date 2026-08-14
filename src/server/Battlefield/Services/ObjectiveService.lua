--!strict
--[[
	T-709: tracks per-server-instance objective completion and gates
	`FinalBossArenaGate` (consumed by `FinalBossController`, T-707) via the
	pure `ObjectiveGate`. All state is a plain in-memory table local to this
	module — never a DataStore, never anything keyed by anything global — so
	it's automatically isolated per reserved server instance (T-709's DoD),
	the same guarantee every other Phase 7 service already relies on.

	Camp-capture objectives (`map.objectiveList` entries whose id is
	`"Capture" .. spawnGroupId`, e.g. `CaptureCampA` <-> spawn group `CampA`)
	complete via `EnemySpawnService.GroupCleared` — capturing a camp, Basara-
	style, means clearing every enemy stationed there. Any other objective id
	is driven by `ReportObjectiveComplete`, called by whichever system owns
	that objective type (e.g. a future `ObjectivePoint`-touch handler).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ObjectiveGate = require(ReplicatedStorage.Shared.Formulas.ObjectiveGate)

type Objective = ObjectiveGate.Objective

local CAMP_OBJECTIVE_PREFIX = "Capture"

local ObjectiveService = Knit.CreateService({
	Name = "ObjectiveService",
	Client = {
		-- (objectiveId: string, complete: boolean) — HUD objective tracker.
		ObjectiveUpdated = Knit.CreateSignal(),
	},
})

-- Server-internal — `FinalBossController` (T-707) waits on this rather than
-- polling, so the gate opens the instant the last required objective does.
ObjectiveService.ObjectiveUpdated = Signal.new()

local objectives: { [string]: Objective } = {}
local initialized = false

local function spawnGroupIdFor(objectiveId: string): string?
	if objectiveId:sub(1, #CAMP_OBJECTIVE_PREFIX) == CAMP_OBJECTIVE_PREFIX then
		return objectiveId:sub(#CAMP_OBJECTIVE_PREFIX + 1)
	end
	return nil
end

function ObjectiveService:ReportObjectiveComplete(objectiveId: string)
	local objective = objectives[objectiveId]
	if not objective or objective.complete then
		return
	end
	objective.complete = true
	self.Client.ObjectiveUpdated:FireAll(objectiveId, true)
	ObjectiveService.ObjectiveUpdated:Fire(objectiveId, true)
end

function ObjectiveService:IsGateOpen(): boolean
	local list = {}
	for _, objective in objectives do
		table.insert(list, objective)
	end
	return ObjectiveGate.IsGateOpen(list)
end

function ObjectiveService:GetObjectives(): { [string]: Objective }
	return objectives
end

function ObjectiveService:Initialize(map: any)
	if initialized or not map then
		return
	end
	initialized = true

	for _, entry in map.objectiveList do
		objectives[entry.id] = {
			id = entry.id,
			required = if entry.required == nil then true else entry.required,
			complete = false,
		}
	end
end

-- Test-only escape hatch (mirrors `EnemyRegistry._ClearAll`) — `Initialize`
-- is a real-map, once-per-server-instance singleton a spec can't reliably
-- re-trigger, so `ObjectiveService.spec.lua` injects a standalone objective
-- under its own id namespace instead of a whole map. Production code never
-- calls this.
function ObjectiveService:_InjectObjectiveForTest(objective: Objective)
	objectives[objective.id] = objective
end

function ObjectiveService:KnitInit()
	local BattlefieldBootstrap = Knit.GetService("BattlefieldBootstrap")
	BattlefieldBootstrap.MapLoaded:Connect(function(map)
		self:Initialize(map)
	end)
	local existingMap = BattlefieldBootstrap:GetCurrentMap()
	if existingMap then
		self:Initialize(existingMap)
	end

	local EnemySpawnService = Knit.GetService("EnemySpawnService")
	EnemySpawnService.GroupCleared:Connect(function(spawnGroupId: string)
		for objectiveId in objectives do
			if spawnGroupIdFor(objectiveId) == spawnGroupId then
				self:ReportObjectiveComplete(objectiveId)
			end
		end
	end)
end

return ObjectiveService
