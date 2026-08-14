--!strict
--[[
	T-904: tracks daily/weekly quest progress (`QuestDefinitions`, T-109) via
	event hooks — enemy kills by tier, maps cleared — and resets on login
	once a UTC day/week boundary has passed (`QuestResetLedger`, T-904's own
	pure formula, single documented boundary: 00:00 UTC).

	Lives in `src/server/Shared/` (loaded in both places, like `DataService`)
	because the reset-on-login check has to run wherever a player's session
	starts, but its progress *hooks* (`EnemySpawnService.EnemyDied`,
	`MidBossController.Defeated`, `MapClearRewardService.MapCleared`) only
	exist in the Battlefield place. `tryGetService` wraps `Knit.GetService`
	in a `pcall` for exactly those three — `Knit.GetService` asserts (throws)
	on an unknown service name, which is what happens for any Battlefield-
	only service name when this code runs in the Lobby place, since Lobby's
	bootstrap never requires those modules at all (see
	`scripts/check-place-separation.luau`).

	`profile.Data.QuestProgress` internal shape (the type itself is just
	`t.table`, T-004/T-201 — unconstrained on purpose):
		{
			lastDailyResetAt: number?,
			lastWeeklyResetAt: number?,
			quests: { [questId]: { progress: number, completed: boolean } },
		}

	Rewards auto-grant the instant a quest's `targetCount` is reached — no
	separate manual-claim step, consistent with how every other reward path
	in this project (per-kill, map-clear) grants immediately rather than
	queuing an unclaimed state.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local QuestResetLedger = require(ReplicatedStorage.Shared.Formulas.QuestResetLedger)
local QuestDefinitions = require(ReplicatedStorage.Shared.Data.QuestDefinitions)

local QuestsById = {}
for _, quest in QuestDefinitions do
	QuestsById[quest.id] = quest
end

local QuestService = Knit.CreateService({
	Name = "QuestService",
	Client = {
		-- (player, questId) — targeted per-player (Fire, not FireAll).
		QuestCompleted = Knit.CreateSignal(),
	},
})

-- Server-internal — `BattlePassService` (T-905) feeds seasonal XP from this.
QuestService.QuestCompleted = Signal.new()

local DataService
local CurrencyService

local function tryGetService(name: string): any?
	local ok, service = pcall(Knit.GetService, name)
	if ok then
		return service
	end
	return nil
end

local function ensureQuestState(profile: any)
	local qp = profile.Data.QuestProgress
	if not qp.quests then
		qp.quests = {}
	end
end

local function resetCadence(qp: any, cadence: string)
	for _, quest in QuestDefinitions do
		if quest.cadence == cadence then
			qp.quests[quest.id] = { progress = 0, completed = false }
		end
	end
end

local function checkResets(profile: any)
	local qp = profile.Data.QuestProgress
	local now = os.time()

	if QuestResetLedger.HasCrossedDailyBoundary(qp.lastDailyResetAt, now) then
		resetCadence(qp, "Daily")
		qp.lastDailyResetAt = now
	end
	if QuestResetLedger.HasCrossedWeeklyBoundary(qp.lastWeeklyResetAt, now) then
		resetCadence(qp, "Weekly")
		qp.lastWeeklyResetAt = now
	end
end

local function grantRewards(player: Player, quest: any)
	for _, rewardEntry in quest.rewards do
		if rewardEntry.currency then
			CurrencyService:AddCurrency(player, rewardEntry.currency, rewardEntry.amount, "Quest:" .. quest.id)
		end
	end
end

function QuestService:IncrementProgress(player: Player, questId: string, amount: number)
	local profile = DataService:GetProfile(player)
	if not profile then
		return
	end
	ensureQuestState(profile)
	checkResets(profile)

	local quest = QuestsById[questId]
	local qp = profile.Data.QuestProgress
	local state = qp.quests[questId]
	if not quest or not state or state.completed then
		return
	end

	state.progress += amount
	if state.progress >= quest.targetCount then
		state.completed = true
		grantRewards(player, quest)
		self.Client.QuestCompleted:Fire(player, questId)
		self.QuestCompleted:Fire(player, questId)
	end
end

local function handleEnemyDied(_definitionId: string, tier: string, damageContributions: { [Player]: number })
	for _, quest in QuestDefinitions do
		if quest.goalType == "DefeatEnemyTier" and quest.tier == tier then
			for player in damageContributions do
				QuestService:IncrementProgress(player, quest.id, 1)
			end
		end
	end
end

local function handleMapCleared(_mapId: string, _rank: string, players: { Player })
	for _, quest in QuestDefinitions do
		if quest.goalType == "ClearMap" then
			for _, player in players do
				QuestService:IncrementProgress(player, quest.id, 1)
			end
		end
	end
end

local function onPlayerAdded(player: Player)
	while player:IsDescendantOf(Players) do
		local profile = DataService:GetProfile(player)
		if profile then
			ensureQuestState(profile)
			checkResets(profile)
			return
		end
		task.wait(0.5)
	end
end

function QuestService:KnitInit()
	DataService = Knit.GetService("DataService")
	CurrencyService = Knit.GetService("CurrencyService")

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	local enemySpawnService = tryGetService("EnemySpawnService")
	if enemySpawnService then
		enemySpawnService.EnemyDied:Connect(handleEnemyDied)
	end

	local midBossController = tryGetService("MidBossController")
	if midBossController then
		midBossController.Defeated:Connect(handleEnemyDied)
	end

	local mapClearRewardService = tryGetService("MapClearRewardService")
	if mapClearRewardService then
		mapClearRewardService.MapCleared:Connect(handleMapCleared)
	end
end

return QuestService
