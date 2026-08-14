--!strict
--[[
	T-901: subscribes to enemy-death events and grants the dying enemy's
	flat per-kill XP + currency (GDD §8.1, `Constants.EnemyRewards`) via
	`LevelService.AwardXP` + `CurrencyService.AddCurrency`.

	Damage-share, not killer-only (documented DoD decision — see
	`DamageShareReward.lua`'s own header for the full reasoning): every
	player who landed damage on the kill gets a cut proportional to their
	contribution, computed once via the pure `DamageShareReward.Split` so the
	split always sums to exactly the flat reward regardless of party size —
	"no reward inflation from party size" is satisfied structurally by that
	formula, not by anything this file does.

	Only subscribes to `EnemySpawnService.EnemyDied` (Foot Soldier/Commander)
	and `MidBossController.Defeated` (Mid-Boss) — deliberately NOT
	`FinalBossController.Defeated`. GDD §8.1 has no Final Boss line; its
	reward is the map-clear payout (§8.2, `MapClearRewardService`/T-903)
	instead, since the Final Boss's death and the map clear are the same
	moment — a flat per-kill grant on top would double-pay it.

	This is the actual gear-drop-independent reward layer: the existing
	bonus gear-drop roll (`RewardTables`, Phase 7) already runs inside each
	controller's own death handler and is unaffected by this file.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local DamageShareReward = require(ReplicatedStorage.Shared.Formulas.DamageShareReward)

local EnemyRewardService = Knit.CreateService({
	Name = "EnemyRewardService",
	Client = {},
})

local LevelService
local CurrencyService

local function playerId(player: Player): string
	return tostring(player.UserId)
end

local function handleEnemyDied(definitionId: string, tier: string, damageContributions: { [Player]: number })
	local reward = Constants.EnemyRewards[tier]
	if not reward then
		return -- FinalBoss/unknown tiers: no flat per-kill grant, see header.
	end

	local contributions = {}
	local playersById: { [string]: Player } = {}
	for player, damage in damageContributions do
		table.insert(contributions, { id = playerId(player), damage = damage })
		playersById[playerId(player)] = player
	end
	if #contributions == 0 then
		return
	end

	local xpSplit = DamageShareReward.Split(reward.xp, contributions)
	local currencySplit = DamageShareReward.Split(reward.currency, contributions)

	for id, player in playersById do
		local xpAmount = xpSplit[id] or 0
		local currencyAmount = currencySplit[id] or 0
		if xpAmount > 0 then
			LevelService:AwardXP(player, xpAmount, "EnemyKill:" .. definitionId)
		end
		if currencyAmount > 0 then
			CurrencyService:AddCurrency(player, Constants.Currency.Soft, currencyAmount, "EnemyKill:" .. definitionId)
		end
	end
end

function EnemyRewardService:KnitInit()
	LevelService = Knit.GetService("LevelService")
	CurrencyService = Knit.GetService("CurrencyService")

	Knit.GetService("EnemySpawnService").EnemyDied:Connect(handleEnemyDied)
	Knit.GetService("MidBossController").Defeated:Connect(handleEnemyDied)
end

return EnemyRewardService
