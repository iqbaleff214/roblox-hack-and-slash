--!strict
--[[
	T-602 (shop half): minimal functional Shop UI (GDD §5 kiosks). Themed
	visual polish is still out of scope — S-1101/S-1102's art hasn't landed —
	but the panel is responsively scaled via `ResponsiveUIController:Apply`
	(T-1103) so it doesn't clip on a small phone viewport. Every purchase
	round-trips through the server, and the displayed state (currency,
	ownership) only ever updates from server signals (`CurrencyChanged`,
	`ItemGranted`) rather than being assumed locally — satisfying T-602's
	"no client-optimistic desync left uncorrected" DoD.

	Opened via a ProximityPrompt attached to any `ShopKiosk`-tagged part
	(Studio places the part in S-602; unlike portals, prompt-attachment
	isn't its own Studio task, so the controller does it — see
	`UIBuilder.AttachTriggerPrompt`).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local UIBuilder = require(script.Parent.UI.UIBuilder)

local ShopUIController = Knit.CreateController({ Name = "ShopUIController" })

local screenGui: ScreenGui
local listFrame: ScrollingFrame
local currencyLabel: TextLabel

local function refresh()
	local DataService = Knit.GetService("DataService")
	local ShopService = Knit.GetService("ShopService")

    local successProfile, profile = DataService:GetProfile():await()
    if not successProfile or not profile then
        warn("Failed to fetch profile data.")
        return
    end

	currencyLabel.Text = ("Soft: %d    Premium: %d"):format(profile.SoftCurrency, profile.PremiumCurrency)

	for _, child in listFrame:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local successCatalog, catalog = ShopService:GetCatalog():await()
    if not successCatalog or type(catalog) ~= "table" then
        warn("Failed to fetch catalog data.")
        return
    end

	local order = 0
	for itemId, item in catalog do
		order += 1
		local row = UIBuilder.CreateRow(listFrame, order)
		local owned = profile.OwnedItems[itemId] == true

		UIBuilder.CreateLabel(row, ("%s (%s)"):format(item.name or item.id, item.rarity or ""), UDim2.fromScale(0.5, 1))
		UIBuilder.CreateLabel(
			row,
			("%d %s"):format(item.price.amount, item.price.currency),
			UDim2.fromScale(0.25, 1),
			UDim2.fromScale(0.5, 0)
		)

		local buyButton = UIBuilder.CreateButton(
			row,
			if owned then "Owned" else "Buy",
			UDim2.fromScale(0.2, 0.8),
			UDim2.fromScale(0.78, 0.1)
		)
		if owned then
			buyButton.Active = false
			buyButton.AutoButtonColor = false
			buyButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		else
			buyButton.Activated:Connect(function()
                buyButton.Active = false 
                buyButton.Text = "..."

                ShopService:PurchaseItem(itemId):andThen(function()
                    buyButton.Active = true
                end):catch(function()
                    buyButton.Active = true
                    buyButton.Text = "Buy"
                end)
            end)
		end
	end
end

function ShopUIController:Open()
	screenGui.Enabled = true
	refresh()
end

function ShopUIController:Close()
	screenGui.Enabled = false
end

function ShopUIController:KnitStart()
	screenGui = UIBuilder.CreateScreenGui("ShopUI")
	local panel, content, closeButton = UIBuilder.CreatePanel(screenGui, "Shop")
	closeButton.Activated:Connect(function()
		self:Close()
	end)

	Knit.GetController("ResponsiveUIController"):Apply(panel) -- T-1103

	currencyLabel = UIBuilder.CreateLabel(content, "", UDim2.new(1, -16, 0, 24), UDim2.fromOffset(8, 4))

	local listContainer = Instance.new("Frame")
	listContainer.Name = "ListContainer"
	listContainer.BackgroundTransparency = 1
	listContainer.Size = UDim2.new(1, -16, 1, -36)
	listContainer.Position = UDim2.fromOffset(8, 32)
	listContainer.Parent = content
	listFrame = UIBuilder.CreateScrollingList(listContainer)

	local InventoryService = Knit.GetService("InventoryService")
	InventoryService.ItemGranted:Connect(refresh)

	local CurrencyService = Knit.GetService("CurrencyService")
	CurrencyService.CurrencyChanged:Connect(refresh)

	local function attachKiosk(part: Instance)
		UIBuilder.AttachTriggerPrompt(part, "ShopKioskPrompt", "Shop", function()
			self:Open()
		end)
	end

	for _, part in CollectionService:GetTagged(Constants.Tags.ShopKiosk) do
		attachKiosk(part)
	end
	CollectionService:GetInstanceAddedSignal(Constants.Tags.ShopKiosk):Connect(attachKiosk)
end

return ShopUIController
