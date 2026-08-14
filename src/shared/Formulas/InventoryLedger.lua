--!strict
--[[
	Pure inventory mutation rules (T-204), operating directly on a profile's
	`OwnedItems` set (`{ [itemId]: true }`) instead of a `Player`. All items in
	this catalog are non-stackable (a boolean-set is inherently idempotent) —
	granting an already-owned item is a no-op. `InventoryService` (Knit) is a
	thin wrapper around this: resolve player -> profile.Data.OwnedItems, call
	these, fire the Client signal.
]]

local InventoryLedger = {}

-- Returns false if the item was already owned (no-op, idempotent).
function InventoryLedger.Grant(ownedItems: { [string]: boolean }, itemId: string): boolean
	if ownedItems[itemId] then
		return false
	end
	ownedItems[itemId] = true
	return true
end

function InventoryLedger.Has(ownedItems: { [string]: boolean }, itemId: string): boolean
	return ownedItems[itemId] == true
end

return InventoryLedger
