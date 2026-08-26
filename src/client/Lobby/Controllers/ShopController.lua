--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)

local ShopController = Knit.CreateController({ Name = "ShopController" })

local function refresh()
	local DataService = Knit.GetService("DataService")
	local ShopService = Knit.GetService("ShopService")

	local successProfile, profile = DataService:GetProfile():await()
	if not successProfile or not profile then
		warn("Failed to fetch profile data.")
		return
	end
end

function ShopController:KnitStart()
	local InventoryService = Knit.GetService("InventoryService")
	InventoryService.ItemGranted:Connect(refresh)

	local CurrencyService = Knit.GetService("CurrencyService")
	CurrencyService.CurrencyChanged:Connect(refresh)
end

return ShopController
