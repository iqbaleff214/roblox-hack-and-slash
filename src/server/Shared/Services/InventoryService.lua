--!strict
--[[
	Thin Knit wrapper around InventoryLedger (T-204) — resolves player -> live
	profile.Data.OwnedItems, delegates to the pure ledger. No Client-callable
	`GrantItem` on purpose (would be a free-items exploit) — only trusted
	server code (ShopService, MonetizationService, MapClearRewardService, ...)
	grants items.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local InventoryLedger = require(ReplicatedStorage.Shared.Formulas.InventoryLedger)

local InventoryService = Knit.CreateService({
	Name = "InventoryService",
	Client = {
		ItemGranted = Knit.CreateSignal(),
	},
})

local DataService

-- Returns false if the profile isn't loaded yet, or the item was already
-- owned (idempotent no-op — see InventoryLedger).
function InventoryService:GrantItem(player: Player, itemId: string): boolean
	local profile = DataService:GetProfile(player)
	if not profile then
		return false
	end

	local granted = InventoryLedger.Grant(profile.Data.OwnedItems, itemId)
	if granted then
		self.Client.ItemGranted:Fire(player, itemId)
	end
	return granted
end

function InventoryService:HasItem(player: Player, itemId: string): boolean
	local profile = DataService:GetProfile(player)
	if not profile then
		return false
	end
	return InventoryLedger.Has(profile.Data.OwnedItems, itemId)
end

function InventoryService:KnitInit()
	DataService = Knit.GetService("DataService")
end

return InventoryService
