--!strict
--[[
	Enabling infrastructure T-902/T-903 need but no earlier task explicitly
	created: something that actually tracks the `{comboCount, damageTaken,
	timeElapsedSeconds}` triple `RankFormula.ComputeRank` (T-902) takes as
	input. Party-wide, single counter set per Battlefield server instance —
	see `RankFormula.lua`'s header for why this is a team stat, not a
	per-player one.

	`comboCount` increments once per landed hit (`HitboxService`, every
	successful `ApplyDamageToTargets` application). `damageTaken` increments
	only by damage that actually reduced a player's HP (`PlayerHealthService`,
	after the i-frame/invulnerability check — damage voided by a Dash was
	correctly evaded and shouldn't be penalized). `timeElapsedSeconds` is
	measured from `BattlefieldBootstrap.MapLoaded` to whenever
	`MapClearRewardService` reads it at Final Boss defeat.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local RunStatsService = Knit.CreateService({
	Name = "RunStatsService",
	Client = {},
})

local comboCount = 0
local damageTaken = 0
local runStartedAt: number? = nil

function RunStatsService:RecordHit()
	comboCount += 1
end

function RunStatsService:RecordDamageTaken(amount: number)
	damageTaken += amount
end

function RunStatsService:GetStats(): { comboCount: number, damageTaken: number, timeElapsedSeconds: number }
	local timeElapsedSeconds = if runStartedAt then os.clock() - runStartedAt else 0
	return {
		comboCount = comboCount,
		damageTaken = damageTaken,
		timeElapsedSeconds = timeElapsedSeconds,
	}
end

function RunStatsService:KnitInit()
	local BattlefieldBootstrap = Knit.GetService("BattlefieldBootstrap")
	BattlefieldBootstrap.MapLoaded:Connect(function()
		if not runStartedAt then
			runStartedAt = os.clock()
		end
	end)
	if BattlefieldBootstrap:GetCurrentMap() and not runStartedAt then
		runStartedAt = os.clock()
	end
end

return RunStatsService
