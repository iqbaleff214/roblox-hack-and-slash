--!strict
--[[
	Thin Knit wrapper around CurrencyLedger (T-203) — resolves player -> live
	profile.Data, delegates the actual mutation rules to the pure ledger, fires
	the Client signal, logs the reason. No Client-callable mutation methods on
	purpose: currency changes are always server-initiated (ShopService,
	QuestService, MonetizationService, ...), never a direct client request —
	that's the whole point of keeping this server-authoritative.

	T-1002: `AddCurrency` runs `amount` through `GamePassService`'s Currency
	Boost check + `BoostMath.ApplyBoost` before the ledger sees it, but only
	for `SoftCurrency` — the boost is applied at this single point of grant,
	not as a separate untracked bonus.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local CurrencyLedger = require(ReplicatedStorage.Shared.Formulas.CurrencyLedger)
local BoostMath = require(ReplicatedStorage.Shared.Formulas.BoostMath)

local CurrencyService = Knit.CreateService({
	Name = "CurrencyService",
	Client = {
		CurrencyChanged = Knit.CreateSignal(),
	},
})

local DataService
local GamePassService

function CurrencyService:AddCurrency(player: Player, currencyType: string, amount: number, reason: string): number?
	local profile = DataService:GetProfile(player)
	if not profile then
		return nil
	end

	-- T-1002: Currency Boost applies to SoftCurrency *gains* only (GDD §9.2)
	-- — never PremiumCurrency (buying gems isn't a "gain" to boost).
	local boostedAmount = amount
	if currencyType == Constants.Currency.Soft then
		local boostPercent = GamePassService:GetCurrencyBoostPercent(player)
		boostedAmount = BoostMath.ApplyBoost(amount, boostPercent)
	end

	local newAmount = CurrencyLedger.Add(profile.Data, currencyType, boostedAmount)
	print(("[CurrencyService] +%d %s -> %s (reason: %s, new balance: %d)"):format(boostedAmount, currencyType, player.Name, reason, newAmount))
	self.Client.CurrencyChanged:Fire(player, currencyType, newAmount)
	return newAmount
end

-- Returns false (no mutation, no signal fired) if the balance is insufficient.
function CurrencyService:RemoveCurrency(player: Player, currencyType: string, amount: number): boolean
	local profile = DataService:GetProfile(player)
	if not profile then
		return false
	end

	local removed = CurrencyLedger.Remove(profile.Data, currencyType, amount)
	if removed then
		print(("[CurrencyService] -%d %s -> %s (new balance: %d)"):format(amount, currencyType, player.Name, profile.Data[currencyType]))
		self.Client.CurrencyChanged:Fire(player, currencyType, profile.Data[currencyType])
	end
	return removed
end

function CurrencyService:KnitInit()
	DataService = Knit.GetService("DataService")
	GamePassService = Knit.GetService("GamePassService")
end

return CurrencyService
