--!strict
--[[
	T-601: GDD §5 shop kiosks. `PurchaseItem` looks an id up across all three
	grantable catalogs (accessories, weapons, ultimates — ids are globally
	unique across them, confirmed since Phase 1). "No partial-purchase state"
	(T-601's DoD) is enforced by ordering: reject up front if already owned
	(nothing to buy), then deduct currency, then grant — refunding
	immediately if the grant somehow still failed. Lobby-only: shopping is a
	Safe Lobby feature (GDD §5), never available in the Battlefield.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ItemDefinitions = require(ReplicatedStorage.Shared.Data.ItemDefinitions)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local UltimateDefinitions = require(ReplicatedStorage.Shared.Data.UltimateDefinitions)

local AllItemsById = {}
for _, item in ItemDefinitions do
	AllItemsById[item.id] = item
end
for _, weapon in WeaponDefinitions do
	AllItemsById[weapon.id] = weapon
end
for _, ultimate in UltimateDefinitions do
	AllItemsById[ultimate.id] = ultimate
end

local ShopService = Knit.CreateService({
	Name = "ShopService",
	Client = {},
})

local CurrencyService
local InventoryService

function ShopService:GetCatalog(): { [string]: any }
	return AllItemsById
end

function ShopService.Client:GetCatalog(): { [string]: any }
	return self.Server:GetCatalog()
end

function ShopService:PurchaseItem(player: Player, itemId: string): boolean
	local item = AllItemsById[itemId]
	if not item then
		return false
	end

	if InventoryService:HasItem(player, itemId) then
		return false -- already owned, nothing to buy
	end

	local removed = CurrencyService:RemoveCurrency(player, item.price.currency, item.price.amount)
	if not removed then
		return false -- insufficient funds; nothing deducted, nothing granted
	end

	local granted = InventoryService:GrantItem(player, itemId)
	if not granted then
		-- Shouldn't happen given the HasItem pre-check, but never leave the
		-- player short currency with nothing to show for it.
		CurrencyService:AddCurrency(player, item.price.currency, item.price.amount, "ShopPurchaseRefund")
		return false
	end

	return true
end

function ShopService.Client:PurchaseItem(player: Player, itemId: string): boolean
	return self.Server:PurchaseItem(player, itemId)
end

function ShopService:KnitInit()
	CurrencyService = Knit.GetService("CurrencyService")
	InventoryService = Knit.GetService("InventoryService")
end

return ShopService
