--!strict
--[[
	T-1002: pure multiplicative boost application. `LevelService:AwardXP`/
	`CurrencyService:AddCurrency` call this at the exact point of grant (the
	DoD's "not a separate untracked bonus") rather than `GamePassService`
	applying a bonus on top afterward — there's only ever one grant call, its
	amount is just already-boosted by the time the ledger sees it.

	Rounds to the nearest integer (round-half-up) since every amount this
	project grants — XP, currency — is an integer everywhere else.
]]

local BoostMath = {}

function BoostMath.ApplyBoost(baseAmount: number, boostPercent: number): number
	return math.floor(baseAmount * (1 + boostPercent) + 0.5)
end

return BoostMath
