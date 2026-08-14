--!strict
--[[
	T-1001: pure idempotency check for `MonetizationService:ProcessReceipt`.
	Roblox requires every `ProcessReceipt` handler to be safe against retries
	(a network hiccup after granting but before the callback returns
	`PurchaseGranted` means Roblox calls again with the same receipt) — this
	is the "have we already granted this exact purchase" decision.

	Keyed by `PurchaseId` alone, not `PlayerId + ProductId + PurchaseId` as a
	composite: the caller already scopes this to one player's own
	`processedPurchases` set (via their profile), and a `PurchaseId` GUID is
	already globally unique per transaction across every product — so
	`PlayerId`/`ProductId` add nothing a per-profile `PurchaseId` set doesn't
	already guarantee.
]]

local PurchaseLedger = {}

function PurchaseLedger.IsProcessed(processedPurchases: { [string]: boolean }, purchaseId: string): boolean
	return processedPurchases[purchaseId] == true
end

function PurchaseLedger.MarkProcessed(processedPurchases: { [string]: boolean }, purchaseId: string)
	processedPurchases[purchaseId] = true
end

return PurchaseLedger
