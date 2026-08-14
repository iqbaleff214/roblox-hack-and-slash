--!strict
--[[
	Pure ownership/catalog validation for a loadout table (T-501), assuming
	shape has already been validated separately (`Types.Loadout` — already
	covered by Types.spec.lua since Phase 0; that check needs the `t`
	library, this one doesn't). Checks: does the weapon/ultimate/accessory
	id actually exist in its catalog, is it owned, and — for accessories —
	does the catalog entry's own `slot` match the slot key it's being placed
	into (an owned Head item can't be slotted as an Arm). Takes ownership as
	a plain set and the catalogs as plain id-keyed tables instead of calling
	InventoryService/requiring the Data modules directly, so this is
	testable without a Player or Studio. `LoadoutService` builds the
	`Context` from live data and calls this before mutating anything —
	"no partial apply" (T-501's DoD) falls out naturally from validating
	everything before any write happens.
]]

local LoadoutValidation = {}

local ACCESSORY_SLOTS = { "Head", "Body", "Arm", "Leg" }
LoadoutValidation.AccessorySlots = ACCESSORY_SLOTS

export type CatalogEntry = { id: string, slot: string? }
export type Context = {
	weaponsById: { [string]: CatalogEntry },
	ultimatesById: { [string]: CatalogEntry },
	itemsById: { [string]: CatalogEntry },
	ownedItemIds: { [string]: boolean },
}
export type ShapeValidLoadout = {
	weaponId: string,
	ultimateId: string,
	accessories: { [string]: string? },
}

-- Returns (valid, reason?) — reason is one of "UnknownWeapon"/"UnownedWeapon"/
-- "UnknownUltimate"/"UnownedUltimate"/"InvalidAccessorySlot"/"UnownedAccessory".
function LoadoutValidation.ValidateOwnershipAndCatalog(loadout: ShapeValidLoadout, context: Context): (boolean, string?)
	if not context.weaponsById[loadout.weaponId] then
		return false, "UnknownWeapon"
	end
	if not context.ownedItemIds[loadout.weaponId] then
		return false, "UnownedWeapon"
	end

	if not context.ultimatesById[loadout.ultimateId] then
		return false, "UnknownUltimate"
	end
	if not context.ownedItemIds[loadout.ultimateId] then
		return false, "UnownedUltimate"
	end

	for _, slot in ACCESSORY_SLOTS do
		local itemId = loadout.accessories[slot]
		if itemId ~= nil then
			local item = context.itemsById[itemId]
			if not item or item.slot ~= slot then
				return false, "InvalidAccessorySlot"
			end
			if not context.ownedItemIds[itemId] then
				return false, "UnownedAccessory"
			end
		end
	end

	return true, nil
end

return LoadoutValidation
