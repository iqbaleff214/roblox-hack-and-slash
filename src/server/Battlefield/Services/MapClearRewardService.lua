--!strict
--[[
	T-903: on Final Boss defeat, grants the guaranteed map-clear bundle
	(XP/currency/gear, GDD §8.2) to every player present, grants the map's
	Main Reward guaranteed-once-per-player (via `MapClearLedger`, idempotent
	per T-903's DoD), and rolls the rank-scaled bonus layer
	(`MapClearRewards.bonusTable`, rank from `RankFormula` fed by
	`RunStatsService`'s party-wide run stats).

	Independently subscribes to `FinalBossController.Defeated` alongside
	`MapClearService` (T-710) — both react to the same raw event, decoupled,
	the same pattern already used elsewhere in this codebase (e.g.
	`ObjectiveService`/`EnemySpawnService` both independently listening to
	`BattlefieldBootstrap.MapLoaded`). Reward computation never blocks or
	depends on the results-screen/teleport flow, and vice versa.

	Every player currently in the server at the moment of defeat gets the
	guaranteed bundle + a Main-Reward check + a bonus roll — a genuine party
	clear reward, not attributed to whoever landed the killing blow (unlike
	T-901's per-kill damage-share; the Final Boss's death has no equivalent
	"who contributed" nuance worth tracking for a flat, guaranteed grant).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Constants = require(ReplicatedStorage.Shared.Constants)
local RankFormula = require(ReplicatedStorage.Shared.Formulas.RankFormula)
local RankRewardScaling = require(ReplicatedStorage.Shared.Formulas.RankRewardScaling)
local MapClearLedger = require(ReplicatedStorage.Shared.Formulas.MapClearLedger)
local WeightedRandom = require(ReplicatedStorage.Shared.Formulas.WeightedRandom)
local MapDefinitions = require(ReplicatedStorage.Shared.Data.MapDefinitions)
local MapClearRewards = require(ReplicatedStorage.Shared.Data.MapClearRewards)

local MapClearRewardService = Knit.CreateService({
	Name = "MapClearRewardService",
	Client = {},
})

-- Server-internal — `QuestService` (T-904, "maps cleared" hook) and
-- `BattlePassService` (T-905, seasonal XP from map clears) both connect
-- here. Fires (mapId, rank, players: {Player}).
MapClearRewardService.MapCleared = Signal.new()

local DataService
local LevelService
local CurrencyService
local InventoryService
local RunStatsService
local BattlePassService

local function grantBonusRoll(player: Player, mapId: string, roll: any, multiplier: number)
	if roll.kind == "Item" and roll.itemId then
		InventoryService:GrantItem(player, roll.itemId)
	elseif roll.kind == "Currency" and roll.amount then
		local amount = math.floor(math.random(roll.amount.min, roll.amount.max) * multiplier + 0.5)
		CurrencyService:AddCurrency(player, roll.currency or Constants.Currency.Soft, amount, "MapClearBonus:" .. mapId)
	elseif roll.kind == "BattlePassXP" and roll.amount then
		local amount = math.floor(math.random(roll.amount.min, roll.amount.max) * multiplier + 0.5)
		BattlePassService:AwardSeasonXP(player, amount)
	end
	-- "Nothing": no grant, bonus roll simply yields nothing this time.
end

local function grantToPlayer(player: Player, mapId: string, map: any, reward: any, rank: string)
	local profile = DataService:GetProfile(player)
	if not profile then
		return
	end

	LevelService:AwardXP(player, reward.guaranteed.xp, "MapClear:" .. mapId)
	CurrencyService:AddCurrency(player, Constants.Currency.Soft, reward.guaranteed.currency, "MapClear:" .. mapId)
	InventoryService:GrantItem(player, reward.guaranteed.gearItemId)

	local mapStats = profile.Data.MapStats :: { [string]: MapClearLedger.MapStatsEntry }
	local newEntry, isFirstClear = MapClearLedger.RecordClear(mapStats[mapId])
	mapStats[mapId] = newEntry
	if isFirstClear then
		InventoryService:GrantItem(player, map.mainRewardItemId)
	end

	local multiplier = RankRewardScaling.GetAmountMultiplier(rank)
	local rollCount = RankRewardScaling.GetBonusRollCount(rank)
	for _ = 1, rollCount do
		local roll = WeightedRandom.Pick(reward.bonusTable, math.random())
		grantBonusRoll(player, mapId, roll, multiplier)
	end
end

function MapClearRewardService:HandleMapCleared(mapId: string)
	local map = MapDefinitions[mapId]
	local reward = MapClearRewards[mapId]
	if not map or not reward then
		warn("[MapClearRewardService] no MapClearRewards entry for mapId: " .. tostring(mapId))
		return
	end

	local rank = RankFormula.ComputeRank(RunStatsService:GetStats())
	local players = Players:GetPlayers()

	for _, player in players do
		grantToPlayer(player, mapId, map, reward, rank)
	end

	self.MapCleared:Fire(mapId, rank, players)
end

function MapClearRewardService:KnitInit()
	DataService = Knit.GetService("DataService")
	LevelService = Knit.GetService("LevelService")
	CurrencyService = Knit.GetService("CurrencyService")
	InventoryService = Knit.GetService("InventoryService")
	RunStatsService = Knit.GetService("RunStatsService")
	BattlePassService = Knit.GetService("BattlePassService")

	local BattlefieldBootstrap = Knit.GetService("BattlefieldBootstrap")
	local FinalBossController = Knit.GetService("FinalBossController")
	FinalBossController.Defeated:Connect(function()
		local mapId = BattlefieldBootstrap:GetCurrentMapId()
		if mapId then
			self:HandleMapCleared(mapId)
		end
	end)
end

return MapClearRewardService
