--!strict
--[[
	T-905: seasonal Battle Pass XP fed by quest completions
	(`QuestService.QuestCompleted`) and map clears
	(`MapClearRewardService.MapCleared`, Battlefield-only — same
	`pcall`-guarded `tryGetService` pattern as `QuestService`, and for the
	same reason: this lives in `src/server/Shared/` since Battle Pass
	progress/premium-flag state needs to exist in both places, but one of
	its two XP sources is Battlefield-only).

	`profile.Data.BattlePassProgress` internal shape:
		{
			seasonId: string,
			xp: number,
			premiumOwned: boolean,
			grantedFreeTiers: { [tier: number]: boolean },
			grantedPremiumTiers: { [tier: number]: boolean },
		}

	`premiumOwned` is a profile-backed flag, set by `GrantPremium` — which
	T-1005 now wires to a *real* ownership check, `GamePassService:OwnsGamePass`
	(T-1002), rather than sitting as an unconsumed stub. `GamePassService`'s
	own ownership check still fails safe against `ProductCatalog`'s `nil`
	`robloxId`s until T-1401, so nothing here can grant premium from an id
	that doesn't exist yet — the seam this file exposes doesn't change,
	only what now actually calls it.

	`GrantPremium` re-evaluates already-crossed XP thresholds, not just
	future ones — T-905's DoD: a player who already passed tier 3's XP
	threshold before buying premium gets tier 3's premium reward
	retroactively the instant `premiumOwned` flips true, not only from
	whatever tier they're at next.

	T-1005: the ownership check is always for `"BattlePassPremium_" ..
	Constants.BattlePass.CurrentSeasonId` specifically — never a bare
	`"BattlePassPremium"` or any other season's sku — so owning a past
	season's Game Pass can never unlock the current season (seasonal ids are
	distinct `ProductCatalog` products, T-1005's DoD). A season rollover
	(`profile...seasonId ~= Constants.BattlePass.CurrentSeasonId`) also
	resets `xp`/`premiumOwned`/both granted-tier sets for the new season, so
	even a stale `premiumOwned = true` from a prior season's profile state
	can't survive into the new one either way — two independent guarantees
	of the same rule.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local BattlePassLedger = require(ReplicatedStorage.Shared.Formulas.BattlePassLedger)
local BattlePassTiers = require(ReplicatedStorage.Shared.Data.BattlePassTiers)

local TiersByNumber = {}
for _, tierEntry in BattlePassTiers do
	TiersByNumber[tierEntry.tier] = tierEntry
end

local BattlePassService = Knit.CreateService({
	Name = "BattlePassService",
	Client = {},
})

local DataService
local CurrencyService
local InventoryService
local GamePassService

local function tryGetService(name: string): any?
	local ok, service = pcall(Knit.GetService, name)
	if ok then
		return service
	end
	return nil
end

local function ensureSeasonState(profile: any)
	local bp = profile.Data.BattlePassProgress
	if bp.seasonId ~= Constants.BattlePass.CurrentSeasonId then
		bp.seasonId = Constants.BattlePass.CurrentSeasonId
		bp.xp = 0
		bp.premiumOwned = false
		bp.grantedFreeTiers = {}
		bp.grantedPremiumTiers = {}
	end
end

local function grantNewlyUnlockedTiers(player: Player, profile: any)
	local bp = profile.Data.BattlePassProgress
	local unlockedTiers = BattlePassLedger.GetUnlockedTiers(bp.xp, BattlePassTiers)

	for _, tier in unlockedTiers do
		local tierData = TiersByNumber[tier]
		if not bp.grantedFreeTiers[tier] then
			CurrencyService:AddCurrency(player, tierData.freeReward.currency, tierData.freeReward.amount, "BattlePassTier:" .. tier)
			bp.grantedFreeTiers[tier] = true
		end
		if bp.premiumOwned and not bp.grantedPremiumTiers[tier] then
			InventoryService:GrantItem(player, tierData.premiumReward.itemId)
			bp.grantedPremiumTiers[tier] = true
		end
	end
end

function BattlePassService:AwardSeasonXP(player: Player, amount: number)
	local profile = DataService:GetProfile(player)
	if not profile then
		return
	end
	ensureSeasonState(profile)

	profile.Data.BattlePassProgress.xp += amount
	grantNewlyUnlockedTiers(player, profile)
end

-- Server-internal only — never a `.Client` method. Called once
-- `GamePassService` confirms real ownership of the *current season's*
-- premium sku (T-1005) — see `CheckPremiumOwnership` below.
function BattlePassService:GrantPremium(player: Player)
	local profile = DataService:GetProfile(player)
	if not profile then
		return
	end
	ensureSeasonState(profile)

	profile.Data.BattlePassProgress.premiumOwned = true
	grantNewlyUnlockedTiers(player, profile) -- retroactive grant, see header
end

-- T-1005: always checks THIS season's product id — never a bare
-- "BattlePassPremium" or a hardcoded past season's sku.
local function currentSeasonPremiumSku(): string
	return "BattlePassPremium_" .. Constants.BattlePass.CurrentSeasonId
end

function BattlePassService:CheckPremiumOwnership(player: Player)
	if GamePassService:OwnsGamePass(player, currentSeasonPremiumSku()) then
		self:GrantPremium(player)
	end
end

local function onPlayerAdded(player: Player)
	while player:IsDescendantOf(Players) do
		if DataService:GetProfile(player) then
			BattlePassService:CheckPremiumOwnership(player)
			return
		end
		task.wait(0.5)
	end
end

function BattlePassService:KnitInit()
	DataService = Knit.GetService("DataService")
	CurrencyService = Knit.GetService("CurrencyService")
	InventoryService = Knit.GetService("InventoryService")
	GamePassService = Knit.GetService("GamePassService")

	local QuestService = Knit.GetService("QuestService")
	QuestService.QuestCompleted:Connect(function(player: Player)
		self:AwardSeasonXP(player, Constants.BattlePass.XPPerQuestCompletion)
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, _gamePassId: number, wasPurchased: boolean)
		if wasPurchased then
			self:CheckPremiumOwnership(player)
		end
	end)

	local mapClearRewardService = tryGetService("MapClearRewardService")
	if mapClearRewardService then
		mapClearRewardService.MapCleared:Connect(function(_mapId: string, _rank: string, players: { Player })
			for _, player in players do
				self:AwardSeasonXP(player, Constants.BattlePass.XPPerMapClear)
			end
		end)
	end
end

return BattlePassService
