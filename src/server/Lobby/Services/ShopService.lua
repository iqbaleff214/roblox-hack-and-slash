--!strict
--[[
	T-601: GDD §5 shop kiosks. `PurchaseItem` looks an id up across all three
	grantable catalogs (accessories, weapons, ultimates — ids are globally
	unique across them, confirmed since Phase 1). "No partial-purchase state"
	(T-601's DoD) is enforced by ordering: reject up front if already owned
	(nothing to buy), then deduct currency, then grant — refunding
	immediately if the grant somehow still failed. Lobby-only: shopping is a
	Safe Lobby feature (GDD §5), never available in the Battlefield.

	T-1003: `PurchaseProduct` is a separate path for `ProductCatalog`
	Developer Product SKUs (Gems bundles, cosmetic bundles, loadout preset
	slots) — real-money purchases, distinct from `PurchaseItem`'s
	balance-deduction flow for catalog gear. Only ever opens the native
	purchase dialog via `MonetizationService:PromptProductPurchase`; never
	touches `CurrencyService` itself (T-1003's DoD: no client-optimistic
	currency credit — the actual grant happens entirely inside
	`MonetizationService:ProcessReceipt`, T-1001, driven by Roblox's own
	server callback after a real completed transaction).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ItemDefinitions = require(ReplicatedStorage.Shared.Data.ItemDefinitions)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local UltimateDefinitions = require(ReplicatedStorage.Shared.Data.UltimateDefinitions)
local ProductCatalog = require(ReplicatedStorage.Shared.Data.ProductCatalog)

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
local MonetizationService

function ShopService:GetCatalog(category: string?): { [string]: any }
	category = if category ~= nil then category:lower() else category

	if category == "item" then
		local items = {}
		for _, item in ItemDefinitions do
			items[item.id] = item
		end
		return items
	elseif category == "weapon" then
		local items = {}
		for _, item in WeaponDefinitions do
			items[item.id] = item
		end
		return items
	else
		return AllItemsById
	end
end

function ShopService.Client:GetCatalog(_: Player, category: string?): { [string]: any }
	return self.Server:GetCatalog(category)
end

function ShopService:PurchaseItem(player: Player, itemId: string): boolean
	local ToastService = Knit.GetService("ToastService")

	local item = AllItemsById[itemId]
	if not item then
		ToastService:Show(player, "Pembelian gagal: Uang tidak cukup!", true)
		return false
	end

	if InventoryService:HasItem(player, itemId) then
		ToastService:Show(player, "Pembelian gagal: Uang tidak cukup!", true)
		return false -- already owned, nothing to buy
	end

	local removed = CurrencyService:RemoveCurrency(player, item.price.currency, item.price.amount)
	if not removed then
		ToastService:Show(player, "Pembelian gagal: Uang tidak cukup!", true)
		return false -- insufficient funds; nothing deducted, nothing granted
	end

	local granted = InventoryService:GrantItem(player, itemId)
	if not granted then
		-- Shouldn't happen given the HasItem pre-check, but never leave the
		-- player short currency with nothing to show for it.
		CurrencyService:AddCurrency(player, item.price.currency, item.price.amount, "ShopPurchaseRefund")
		return false
	end

	ToastService:Show(player, "Pembelian berhasil!")

	return true
end

function ShopService.Client:PurchaseItem(player: Player, itemId: string): boolean
	return self.Server:PurchaseItem(player, itemId)
end

-- Real-money path (T-1003): opens the native purchase dialog for a
-- `ProductCatalog` Developer Product SKU. Returns false immediately for an
-- unknown/non-DevProduct sku; true means the prompt was shown, not that
-- anything was granted (that's `MonetizationService:ProcessReceipt`'s job).
function ShopService:PurchaseProduct(player: Player, sku: string): boolean
	local product = ProductCatalog[sku]
	if not product or product.type ~= "DevProduct" then
		return false
	end
	MonetizationService:PromptProductPurchase(player, sku)
	return true
end

function ShopService.Client:PurchaseProduct(player: Player, sku: string): boolean
	return self.Server:PurchaseProduct(player, sku)
end

function ShopService:KnitInit()
	CurrencyService = Knit.GetService("CurrencyService")
	InventoryService = Knit.GetService("InventoryService")
	MonetizationService = Knit.GetService("MonetizationService")
end

return ShopService
