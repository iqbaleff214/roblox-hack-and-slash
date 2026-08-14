--!strict
--[[
	T-1002: `UserOwnsGamePassAsync` ownership check for every Game Pass in
	`ProductCatalog`, cached per player (refreshed on `PlayerAdded` and on
	`PromptGamePassPurchaseFinished`), applying GDD §9.2's passive effects:
	XP Boost %, Currency Boost %, VIP daily currency bonus.

	Boost percentages apply multiplicatively at the exact point of grant —
	`LevelService:AwardXP`/`CurrencyService:AddCurrency` each call
	`GetXPBoostPercent`/`GetCurrencyBoostPercent` and run the result through
	the pure `BoostMath.ApplyBoost` before the ledger ever sees the amount
	(T-1002's DoD: "not a separate untracked bonus" — there's only ever the
	one grant call, its amount is already boosted).

	Every `ProductCatalog` Game Pass entry's `robloxId` is `nil` until T-1401
	creates the real passes (S-1002) — `OwnsGamePass` fails safe (treats a
	missing `robloxId` as not-owned) rather than erroring, the same
	forward-dependency handling used throughout this project for anything
	still waiting on a Studio/Dashboard id.

	Currency Boost applies to `SoftCurrency` gains only (GDD §9.2: "permanent
	+% soft currency gain") — never to `PremiumCurrency` grants (buying gems
	isn't a "gain" the boost is meant to apply to) and never to
	`RemoveCurrency` (a boost multiplies what you earn, not what you spend).

	VIP's "priority queue/party perks" (GDD §9.2) has no queue/priority
	system anywhere in this project to hook — not built, documented here
	rather than invented. The cosmetic trail grant is tracked as a flag
	(`profile.Data.Settings.VIPTrailId`) for a future avatar-effects system
	to read; no trail-rendering exists yet either.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local QuestResetLedger = require(ReplicatedStorage.Shared.Formulas.QuestResetLedger)
local ProductCatalog = require(ReplicatedStorage.Shared.Data.ProductCatalog)

local SkuByRobloxId: { [number]: string } = {}
for sku, product in ProductCatalog do
	if product.type == "GamePass" and product.robloxId then
		SkuByRobloxId[product.robloxId] = sku
	end
end

local GamePassService = Knit.CreateService({
	Name = "GamePassService",
	Client = {},
})

local DataService
local CurrencyService

local ownershipCache: { [Player]: { [string]: boolean } } = {}

local function checkOwnership(player: Player, sku: string): boolean
	local product = ProductCatalog[sku]
	if not product or product.type ~= "GamePass" or not product.robloxId then
		return false
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, product.robloxId)
	end)
	return ok and owns == true
end

function GamePassService:RefreshOwnership(player: Player, sku: string): boolean
	local cache = ownershipCache[player]
	if not cache then
		cache = {}
		ownershipCache[player] = cache
	end
	local owns = checkOwnership(player, sku)
	cache[sku] = owns
	return owns
end

function GamePassService:OwnsGamePass(player: Player, sku: string): boolean
	local cache = ownershipCache[player]
	if cache and cache[sku] ~= nil then
		return cache[sku]
	end
	return self:RefreshOwnership(player, sku)
end

function GamePassService.Client:OwnsGamePass(player: Player, sku: string): boolean
	return self.Server:OwnsGamePass(player, sku)
end

function GamePassService:GetXPBoostPercent(player: Player): number
	if self:OwnsGamePass(player, "XPBoostPass") then
		return ProductCatalog.XPBoostPass.grants.xpBoostPercent
	end
	return 0
end

function GamePassService:GetCurrencyBoostPercent(player: Player): number
	if self:OwnsGamePass(player, "CurrencyBoostPass") then
		return ProductCatalog.CurrencyBoostPass.grants.currencyBoostPercent
	end
	return 0
end

-- Grants VIP's "small daily currency bonus" (GDD §9.2) once per UTC day,
-- reusing T-904's `QuestResetLedger` for the same documented boundary every
-- other daily reset in this project uses.
function GamePassService:GrantVIPDailyBonusIfDue(player: Player)
	if not self:OwnsGamePass(player, "VIPPass") then
		return
	end
	local profile = DataService:GetProfile(player)
	if not profile then
		return
	end

	local settings = profile.Data.Settings
	local now = os.time()
	if not QuestResetLedger.HasCrossedDailyBoundary(settings.LastVIPBonusAt, now) then
		return
	end
	settings.LastVIPBonusAt = now
	settings.VIPTrailId = ProductCatalog.VIPPass.grants.cosmeticTrail

	CurrencyService:AddCurrency(player, Constants.Currency.Soft, ProductCatalog.VIPPass.grants.dailyCurrencyBonus, "VIPDailyBonus")
end

-- Test-only escape hatch (mirrors `EnemyRegistry._ClearAll`) — every
-- `ProductCatalog` Game Pass's `robloxId` is `nil` until T-1401, so
-- `checkOwnership` can never return true in this sandbox; this forces the
-- cache directly so `GamePassService.spec.lua` can genuinely exercise the
-- boost-application code path today. Production code never calls this.
function GamePassService:_SetOwnershipForTest(player: Player, sku: string, owns: boolean)
	local cache = ownershipCache[player]
	if not cache then
		cache = {}
		ownershipCache[player] = cache
	end
	cache[sku] = owns
end

local function onPlayerAdded(player: Player)
	for sku, product in ProductCatalog do
		if product.type == "GamePass" then
			GamePassService:RefreshOwnership(player, sku)
		end
	end

	while player:IsDescendantOf(Players) do
		if DataService:GetProfile(player) then
			GamePassService:GrantVIPDailyBonusIfDue(player)
			return
		end
		task.wait(0.5)
	end
end

function GamePassService:KnitInit()
	DataService = Knit.GetService("DataService")
	CurrencyService = Knit.GetService("CurrencyService")

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		ownershipCache[player] = nil
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, gamePassId: number, wasPurchased: boolean)
		if not wasPurchased then
			return
		end
		local sku = SkuByRobloxId[gamePassId]
		if sku then
			self:RefreshOwnership(player, sku)
			if sku == "VIPPass" then
				self:GrantVIPDailyBonusIfDue(player)
			end
		end
	end)
end

return GamePassService
