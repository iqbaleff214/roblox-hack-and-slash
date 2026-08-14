--!strict
--[[
	Thin Knit wrapper around LevelLedger (T-302) — resolves player -> live
	profile.Data, delegates the XP/level math to the pure ledger, fires
	`LevelUp` once per level actually gained. No `.Client`-callable `AwardXP`
	on purpose: XP is always server-initiated (T-901 enemy kills, T-903 map
	clears, T-904 quests — all Phase 9).

	Two `LevelUp` signals, deliberately: `Client.LevelUp` (Knit networked
	signal, for UI) and the plain `LevelUp` field below (server-internal
	`Signal`, for other server Services — e.g. StatsService — to react
	without going through client replication).

	T-1002: `amount` is run through `GamePassService`'s XP Boost check +
	`BoostMath.ApplyBoost` before the ledger ever sees it — the boost is
	applied at this single point of grant, not as a separate untracked bonus.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local LevelLedger = require(ReplicatedStorage.Shared.Formulas.LevelLedger)
local BoostMath = require(ReplicatedStorage.Shared.Formulas.BoostMath)

local LevelService = Knit.CreateService({
	Name = "LevelService",
	Client = {
		LevelUp = Knit.CreateSignal(),
	},
})

LevelService.LevelUp = Signal.new()

local DataService
local GamePassService

function LevelService:AwardXP(player: Player, amount: number, source: string)
	local profile = DataService:GetProfile(player)
	if not profile then
		return
	end

	local boostPercent = GamePassService:GetXPBoostPercent(player)
	local boostedAmount = BoostMath.ApplyBoost(amount, boostPercent)

	local levelsGained = LevelLedger.AwardXP(profile.Data, boostedAmount)
	print(
		("[LevelService] +%d XP -> %s (source: %s, new XP: %d, level: %d)"):format(
			boostedAmount,
			player.Name,
			source,
			profile.Data.XP,
			profile.Data.Level
		)
	)

	for _, level in levelsGained do
		self.Client.LevelUp:Fire(player, level)
		self.LevelUp:Fire(player, level)
	end
end

function LevelService:KnitInit()
	DataService = Knit.GetService("DataService")
	GamePassService = Knit.GetService("GamePassService")
end

return LevelService
