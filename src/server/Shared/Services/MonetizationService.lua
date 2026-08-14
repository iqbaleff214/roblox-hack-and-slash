--!strict
--[[
	T-1001: `MarketplaceService.ProcessReceipt` handler for every Developer
	Product in `ProductCatalog` (Game Passes are never processed here — see
	`GamePassService`, they're checked via `UserOwnsGamePassAsync`, not
	granted via a receipt). Lives in `Shared` (like `DataService`) since a
	Robux purchase can complete while a player is in either place, and every
	service it grants through (`CurrencyService`/`InventoryService`) is
	Shared too.

	Idempotent via `PurchaseLedger` (T-1001's own pure formula) over
	`profile.Data.Settings.ProcessedPurchases` — a set of every `PurchaseId`
	already granted for that player. Reusing the generic `Settings` field
	(already `t.table`-typed, unconstrained) avoids a `Types.Profile` schema
	change for what's fundamentally still per-player settings-adjacent state.

	`ProcessReceipt` returns `Enum.ProductPurchaseDecision.PurchaseGranted`
	ONLY once the grant has actually completed (wrapped in `pcall` so a
	genuine failure mid-grant returns `NotProcessedYet` instead, letting
	Roblox retry) — and returns `PurchaseGranted` immediately, without
	re-granting, for an already-processed `PurchaseId` (T-1001's DoD: a
	replayed receipt "grants nothing a second time but still returns
	PurchaseGranted").

	Generic `grants` dispatch reads whichever fields a `ProductCatalog` entry
	sets (`premiumCurrency`, `items`, `loadoutPresetSlots` — T-1006's whole
	implementation is this one branch, "protected by the same idempotent-
	receipt mechanism as T-1001" exactly because it's the same code path).
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local PurchaseLedger = require(ReplicatedStorage.Shared.Formulas.PurchaseLedger)
local ProductCatalog = require(ReplicatedStorage.Shared.Data.ProductCatalog)

local SkuByRobloxId: { [number]: string } = {}
for sku, product in ProductCatalog do
	if product.type == "DevProduct" and product.robloxId then
		SkuByRobloxId[product.robloxId] = sku
	end
end

local MonetizationService = Knit.CreateService({
	Name = "MonetizationService",
	Client = {},
})

local DataService
local CurrencyService
local InventoryService

-- Client-callable request to open the native purchase dialog for a
-- Developer Product SKU — never touches currency/inventory itself (T-1003's
-- DoD: no client-optimistic credit). The actual grant only ever happens
-- inside `ProcessReceipt`, driven by Roblox's own server-to-server callback
-- after a genuinely completed transaction, never by anything client-called.
function MonetizationService:PromptProductPurchase(player: Player, sku: string)
	local product = ProductCatalog[sku]
	if not product or product.type ~= "DevProduct" then
		warn("[MonetizationService] PromptProductPurchase: unknown DevProduct sku: " .. tostring(sku))
		return
	end
	if not product.robloxId then
		warn(("[MonetizationService] %s has no robloxId yet (T-1401 pending) - cannot prompt purchase"):format(sku))
		return
	end
	MarketplaceService:PromptProductPurchase(player, product.robloxId)
end

function MonetizationService.Client:PromptProductPurchase(player: Player, sku: string)
	self.Server:PromptProductPurchase(player, sku)
end

local function grantProduct(player: Player, profile: any, product: any, sku: string)
	local grants = product.grants

	if grants.premiumCurrency then
		CurrencyService:AddCurrency(player, Constants.Currency.Premium, grants.premiumCurrency, "Purchase:" .. sku)
	end
	if grants.softCurrency then
		CurrencyService:AddCurrency(player, Constants.Currency.Soft, grants.softCurrency, "Purchase:" .. sku)
	end
	if grants.items then
		for _, itemId in grants.items do
			InventoryService:GrantItem(player, itemId)
		end
	end
	if grants.loadoutPresetSlots then
		local settings = profile.Data.Settings
		settings.PurchasedLoadoutPresetSlots = (settings.PurchasedLoadoutPresetSlots or 0) + grants.loadoutPresetSlots
	end
end

function MonetizationService:ProcessReceipt(receiptInfo: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- player not in this server; retry later
	end

	local profile = DataService:GetProfile(player)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- profile not loaded yet; retry later
	end

	local settings = profile.Data.Settings
	if not settings.ProcessedPurchases then
		settings.ProcessedPurchases = {}
	end

	if PurchaseLedger.IsProcessed(settings.ProcessedPurchases, receiptInfo.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- already granted; confirm without re-granting
	end

	local sku = SkuByRobloxId[receiptInfo.ProductId]
	local product = sku and ProductCatalog[sku]
	if not product then
		warn("[MonetizationService] ProcessReceipt: no ProductCatalog entry for ProductId " .. tostring(receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local granted = pcall(grantProduct, player, profile, product, sku)
	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	PurchaseLedger.MarkProcessed(settings.ProcessedPurchases, receiptInfo.PurchaseId)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Test-only escape hatch (mirrors `EnemyRegistry._ClearAll`) — every
-- `ProductCatalog` entry's `robloxId` is `nil` until T-1401 fills in real
-- Developer Product ids, so `SkuByRobloxId` (built once from those ids at
-- module load) is empty in this sandbox and the normal `ProcessReceipt`
-- grant path is otherwise unreachable from a spec. Registers a fake
-- `robloxId -> sku` mapping so `MonetizationService.spec.lua` can genuinely
-- exercise the real grant/idempotency code path today. Production code
-- never calls this.
function MonetizationService:_RegisterSkuForTest(robloxId: number, sku: string)
	SkuByRobloxId[robloxId] = sku
end

function MonetizationService:KnitInit()
	DataService = Knit.GetService("DataService")
	CurrencyService = Knit.GetService("CurrencyService")
	InventoryService = Knit.GetService("InventoryService")

	MarketplaceService.ProcessReceipt = function(receiptInfo: any)
		return self:ProcessReceipt(receiptInfo)
	end
end

return MonetizationService
