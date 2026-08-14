--!strict
--[[
	Pure currency mutation rules (T-203), operating directly on a profile's
	`Data` table (`{ SoftCurrency: number, PremiumCurrency: number, ... }`)
	instead of a `Player` — no ProfileService/DataStore/Player dependency, so
	this is unit-testable without Studio. `CurrencyService` (Knit) is a thin
	wrapper: resolve player -> profile.Data, call these, fire the Client
	signal, log the reason.
]]

local CurrencyLedger = {}

function CurrencyLedger.Add(data: { [string]: number }, currencyType: string, amount: number): number
	assert(amount >= 0, "amount must be >= 0")
	data[currencyType] += amount
	return data[currencyType]
end

-- Returns false (and leaves `data` unchanged) if the balance would go negative.
function CurrencyLedger.Remove(data: { [string]: number }, currencyType: string, amount: number): boolean
	assert(amount >= 0, "amount must be >= 0")
	if data[currencyType] < amount then
		return false
	end
	data[currencyType] -= amount
	return true
end

return CurrencyLedger
