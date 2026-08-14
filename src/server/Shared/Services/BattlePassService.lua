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

	`premiumOwned` is a profile-backed flag, NOT a real Robux Game Pass
	check — `GamePassService`/`MonetizationService` (T-1002, Phase 10) don't
	exist yet. `GrantPremium` is the forward-compatible seam T-1002 will call
	once it's built (the same pattern as `PlayerHealthService`/`CombatService`
	deferring T-405's i-frame check to a not-yet-built consumer back in
	Phase 4) — documented honestly as a stub, not a real purchase-gated
	check, rather than silently pretending this already validates ownership.

	`GrantPremium` re-evaluates already-crossed XP thresholds, not just
	future ones — T-905's DoD: a player who already passed tier 3's XP
	threshold before buying premium gets tier 3's premium reward
	retroactively the instant `premiumOwned` flips true, not only from
	whatever tier they're at next.

	A season rollover (`profile...seasonId ~= Constants.BattlePass.CurrentSeasonId`)
	resets `xp`/`premiumOwned`/both granted-tier sets for the new season —
	last season's premium ownership never carries over (T-1005's "owning a
	past season's pass doesn't unlock the current season," satisfied here
	since `premiumOwned` always starts false for a new `seasonId`).
]]

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

-- Server-internal only — never a `.Client` method. Forward-compatible seam
-- for T-1002's real Game Pass ownership check; see this file's header.
function BattlePassService:GrantPremium(player: Player)
	local profile = DataService:GetProfile(player)
	if not profile then
		return
	end
	ensureSeasonState(profile)

	profile.Data.BattlePassProgress.premiumOwned = true
	grantNewlyUnlockedTiers(player, profile) -- retroactive grant, see header
end

function BattlePassService:KnitInit()
	DataService = Knit.GetService("DataService")
	CurrencyService = Knit.GetService("CurrencyService")
	InventoryService = Knit.GetService("InventoryService")

	local QuestService = Knit.GetService("QuestService")
	QuestService.QuestCompleted:Connect(function(player: Player)
		self:AwardSeasonXP(player, Constants.BattlePass.XPPerQuestCompletion)
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
