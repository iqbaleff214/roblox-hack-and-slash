--!strict
--[[
	T-708: `DestructibleBox`-tagged parts (GDD §6.3). Fixed placements
	(no `RandomPool` attribute, or `RandomPool = false`) are always active;
	`RandomPool = true` boxes are subset-selected once per server instance
	via the pure `DestructibleBoxPool.SelectSubset` (T-708's own formula) —
	real `math.random()` draws feed the shuffle, one per candidate.

	Break state lives only in this module's own per-instance table (`broken`),
	never anywhere persistent — satisfies T-708's DoD ("no cross-instance
	persistence") the same way every other Phase 7 service's in-memory-only
	state does.

	Not a combo/hitbox target the way enemies are — boxes don't go through
	`EnemyRegistry`/`HitboxGeometry`'s cone-and-facing candidate system.
	Instead, `HitboxService` calls `TryBreakNear` with the same swing's
	origin + shape radius right after resolving enemy damage (GDD §6.3:
	breaking "folds into normal combo flow") — a flat-radius check is enough
	fidelity for a placeholder box with no real collision geometry yet.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local DestructibleBoxPool = require(ReplicatedStorage.Shared.Formulas.DestructibleBoxPool)
local WeightedRandom = require(ReplicatedStorage.Shared.Formulas.WeightedRandom)
local RewardTables = require(ReplicatedStorage.Shared.Data.RewardTables)

local DestructibleBoxService = Knit.CreateService({
	Name = "DestructibleBoxService",
	Client = {},
})

local InventoryService
local CurrencyService
local UltimateGaugeService
local PlayerHealthService

local broken: { [BasePart]: boolean } = {}
local activeBoxes: { [BasePart]: boolean } = {}
local initialized = false

local function grantReward(player: Player, lootTableId: string)
	local table_ = RewardTables[lootTableId]
	if not table_ then
		warn("[DestructibleBoxService] unknown LootTableId: " .. lootTableId)
		return
	end

	local roll = WeightedRandom.Pick(table_, math.random())
	if roll.kind == "Item" and roll.itemId then
		InventoryService:GrantItem(player, roll.itemId)
	elseif roll.kind == "Currency" and roll.amount then
		local amount = math.random(roll.amount.min, roll.amount.max)
		CurrencyService:AddCurrency(player, Constants.Currency.Soft, amount, "DestructibleBox:" .. lootTableId)
	elseif roll.kind == "UltimateCharge" and roll.amount then
		local amount = math.random(roll.amount.min, roll.amount.max)
		UltimateGaugeService:AddGauge(player, amount)
	elseif roll.kind == "StaminaRestore" then
		PlayerHealthService:Heal(player, 25)
	end
	-- "Nothing" (not present in DestructibleBox's table today, but handled
	-- defensively): no grant call, box still breaks.
end

-- Server-internal only — never a `.Client` method. `CombatService`/
-- `HitboxService` call this from the same server-authoritative hit
-- resolution that already validated the swing; a client can't request a
-- box break directly.
function DestructibleBoxService:TryBreak(part: BasePart, player: Player): boolean
	if not activeBoxes[part] or broken[part] then
		return false
	end
	broken[part] = true

	local lootTableId = part:GetAttribute(Constants.Attributes.LootTableId)
	if typeof(lootTableId) == "string" then
		grantReward(player, lootTableId)
	end

	part.Transparency = 1
	part.CanCollide = false
	CollectionService:RemoveTag(part, Constants.Tags.DestructibleBox)

	return true
end

-- Server-internal only. Called by `HitboxService` right after it resolves a
-- swing's enemy damage, with that same swing's origin + shape radius —
-- boxes within range of the same hit break too.
function DestructibleBoxService:TryBreakNear(player: Player, origin: { x: number, y: number, z: number }, radius: number)
	local originVector = Vector3.new(origin.x, origin.y, origin.z)
	for part in activeBoxes do
		if not broken[part] and (part.Position - originVector).Magnitude <= radius then
			self:TryBreak(part, player)
		end
	end
end

function DestructibleBoxService:Initialize()
	if initialized then
		return
	end
	initialized = true

	local fixedBoxes: { BasePart } = {}
	local poolBoxes: { BasePart } = {}

	for _, part in CollectionService:GetTagged(Constants.Tags.DestructibleBox) do
		if part:IsA("BasePart") then
			if part:GetAttribute(Constants.Attributes.RandomPool) == true then
				table.insert(poolBoxes, part)
			else
				table.insert(fixedBoxes, part)
			end
		end
	end

	for _, part in fixedBoxes do
		activeBoxes[part] = true
	end

	if #poolBoxes > 0 then
		local poolIds = {}
		local partsById: { [string]: BasePart } = {}
		for i, part in poolBoxes do
			local id = tostring(i)
			table.insert(poolIds, id)
			partsById[id] = part
		end

		local selectCount = math.max(1, math.ceil(#poolBoxes * Constants.Battlefield.DestructibleBoxRandomPoolFraction))
		local randomValues = {}
		for i = 1, #poolIds - 1 do
			randomValues[i] = math.random()
		end

		local selectedIds = DestructibleBoxPool.SelectSubset(poolIds, selectCount, randomValues)
		local selectedSet = {}
		for _, id in selectedIds do
			selectedSet[id] = true
		end

		for id, part in partsById do
			if selectedSet[id] then
				activeBoxes[part] = true
			else
				part:Destroy()
			end
		end
	end
end

-- Test-only escape hatch (mirrors `EnemyRegistry._ClearAll`) — `Initialize`
-- is a real-map, once-per-server-instance singleton that a spec can't
-- reliably re-trigger, so `DestructibleBoxService.spec.lua` registers a box
-- directly instead. Production code never calls this.
function DestructibleBoxService:_RegisterForTest(part: BasePart)
	activeBoxes[part] = true
end

function DestructibleBoxService:KnitInit()
	InventoryService = Knit.GetService("InventoryService")
	CurrencyService = Knit.GetService("CurrencyService")
	UltimateGaugeService = Knit.GetService("UltimateGaugeService")
	PlayerHealthService = Knit.GetService("PlayerHealthService")

	local BattlefieldBootstrap = Knit.GetService("BattlefieldBootstrap")
	BattlefieldBootstrap.MapLoaded:Connect(function()
		self:Initialize()
	end)
	if BattlefieldBootstrap:GetCurrentMap() then
		self:Initialize()
	end
end

return DestructibleBoxService
