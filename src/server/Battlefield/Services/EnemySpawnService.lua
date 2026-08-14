--!strict
--[[
	T-702 (wave director) + T-703 (immediate aggro): reads the current map's
	`waveConfig` (from BattlefieldBootstrap, T-701) and spawns enemies at
	`EnemySpawnPoint`-tagged parts whose `SpawnGroupId` attribute matches,
	staggered by each wave entry's `delaySeconds`, with count scaled by
	current party size (T-711's `EnemyScaling`, rounded to the nearest
	integer spawn count).

	Also owns the actual runtime instance table + per-tick update loop that
	every Foot Soldier/Commander behavior module (T-704/T-705) runs inside,
	and death handling (loot roll via RewardTables/WeightedRandom, granted
	to whoever landed the killing blow). Mid-Bosses/Final Boss (T-706/T-707)
	are NOT spawned here — they're triggered by `MidBossSpawn`/`FinalBossSpawn`
	tags via their own dedicated controllers, not `waveConfig`.

	No real rigged models exist yet (Studio work pending) — each enemy is a
	placeholder colored Part tagged `Enemy` (Constants.Tags.Enemy) so
	client-side systems (T-409 TargetLockController) can find live enemies
	the same way they will find real Studio-built models later.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Constants = require(ReplicatedStorage.Shared.Constants)
local EnemyScaling = require(ReplicatedStorage.Shared.Formulas.EnemyScaling)
local EnemyFSM = require(ReplicatedStorage.Shared.Formulas.EnemyFSM)
local ShieldBearerBlock = require(ReplicatedStorage.Shared.Formulas.ShieldBearerBlock)
local WeightedRandom = require(ReplicatedStorage.Shared.Formulas.WeightedRandom)
local EnemyDefinitions = require(ReplicatedStorage.Shared.Data.EnemyDefinitions)
local RewardTables = require(ReplicatedStorage.Shared.Data.RewardTables)
local EnemyRegistry = require(ServerScriptService.Server.Support.EnemyRegistry)
local EnemyInstanceType = require(script.Parent.Parent.Support.EnemyInstanceType)

type EnemyInstance = EnemyInstanceType.EnemyInstance

local EnemiesById = {}
for _, def in EnemyDefinitions do
	EnemiesById[def.id] = def
end

-- Foot Soldier + Commander behaviors only (T-704/T-705). Mid-Boss/Final
-- Boss `behaviorModule` values ("MidBossController"/"FinalBossController")
-- name separate Knit services, not entries here.
local BEHAVIOR_MODULES = {
	Swordsman = require(script.Parent.Parent.Support.EnemyBehaviors.Swordsman),
	Spearman = require(script.Parent.Parent.Support.EnemyBehaviors.Spearman),
	ShieldBearer = require(script.Parent.Parent.Support.EnemyBehaviors.ShieldBearer),
	Thrower = require(script.Parent.Parent.Support.EnemyBehaviors.Thrower),
	Bomber = require(script.Parent.Parent.Support.EnemyBehaviors.Bomber),
	Swinger = require(script.Parent.Parent.Support.EnemyBehaviors.Swinger),
	TreasureCarrier = require(script.Parent.Parent.Support.EnemyBehaviors.TreasureCarrier),
	Commander = require(script.Parent.Parent.Support.EnemyBehaviors.Commander),
}

local TIER_COLORS = {
	FootSoldier = Color3.fromRGB(150, 60, 60),
	Commander = Color3.fromRGB(180, 120, 40),
}

local EnemySpawnService = Knit.CreateService({
	Name = "EnemySpawnService",
	Client = {},
})

-- Server-internal (not networked) — Phase 9's `EnemyRewardService` (T-901)
-- connects here; fires (definitionId, tier, damageContributions: {[Player]:
-- number}) so the reward hook can split the kill's flat XP/currency
-- proportionally by damage dealt (co-op fairness) rather than killer-only.
EnemySpawnService.EnemyDied = Signal.new()

-- Server-internal — fires (spawnGroupId) once every enemy spawned under that
-- `SpawnGroupId` (T-702) has died. `groupRemaining` is computed up front
-- from `map.waveConfig`'s scaled counts at `StartWaves` time (not
-- incrementally as staggered waves spawn), so a group can only ever be
-- reported cleared after every one of its waves has actually spawned and
-- died — ObjectiveService (T-709) maps camp-capture objectives onto this by
-- naming convention (`CaptureCampA` objective <-> `CampA` spawn group).
EnemySpawnService.GroupCleared = Signal.new()

local PoiseService
local InventoryService
local CurrencyService
local MapClearService

local instances: { [string]: EnemyInstance } = {}
local nextInstanceNumber = 0
local wavesStarted = false
local groupRemaining: { [string]: number } = {}

local function getSpawnPointsByGroup(): { [string]: { BasePart } }
	local groups: { [string]: { BasePart } } = {}
	for _, part in CollectionService:GetTagged(Constants.Tags.EnemySpawnPoint) do
		if part:IsA("BasePart") then
			local groupId = part:GetAttribute(Constants.Attributes.SpawnGroupId)
			if typeof(groupId) == "string" then
				groups[groupId] = groups[groupId] or {}
				table.insert(groups[groupId], part)
			end
		end
	end
	return groups
end

local function getEnemiesFolder(): Folder
	local folder = Workspace:FindFirstChild("Enemies") :: Folder?
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Enemies"
		folder.Parent = Workspace
	end
	return folder :: Folder
end

local function createPlaceholderModel(def: any, instanceId: string, spawnCFrame: CFrame): (Model, BasePart)
	local model = Instance.new("Model")
	model.Name = instanceId

	local rootPart = Instance.new("Part")
	rootPart.Name = "RootPart"
	rootPart.Size = Vector3.new(2, 5, 1)
	rootPart.Anchored = false
	rootPart.CanCollide = true
	rootPart.TopSurface = Enum.SurfaceType.Smooth
	rootPart.BottomSurface = Enum.SurfaceType.Smooth
	rootPart.CFrame = spawnCFrame
	rootPart.Color = TIER_COLORS[def.tier] or Color3.fromRGB(120, 120, 120)
	rootPart.Parent = model

	model.PrimaryPart = rootPart
	model:SetAttribute(Constants.Attributes.EnemyId, instanceId)
	model:SetAttribute(Constants.Attributes.EnemyTier, def.tier)
	CollectionService:AddTag(model, Constants.Tags.Enemy)
	model.Parent = getEnemiesFolder()

	return model, rootPart
end

function EnemySpawnService:GetInstance(instanceId: string): EnemyInstance?
	return instances[instanceId]
end

function EnemySpawnService:HandleEnemyDeath(instance: EnemyInstance)
	if instance.state == "Dead" then
		return
	end
	instance.state = "Dead"

	local def = EnemiesById[instance.definitionId]
	local killer = instance.custom.lastDamager :: Player?

	-- Bonus gear-drop layer only (see RewardTables header) — flat XP/currency
	-- per kill is T-901's job, not this.
	if killer and def and RewardTables[def.lootTableId] then
		local roll = WeightedRandom.Pick(RewardTables[def.lootTableId], math.random())
		if roll.kind == "Item" and roll.itemId then
			InventoryService:GrantItem(killer, roll.itemId)
		elseif roll.kind == "Currency" and roll.amount then
			local amount = math.random(roll.amount.min, roll.amount.max)
			CurrencyService:AddCurrency(killer, Constants.Currency.Soft, amount, "EnemyKill:" .. instance.definitionId)
		end
	end

	EnemyRegistry.Unregister(instance.id)
	if instance.poiseMax > 0 then
		PoiseService:UnregisterEnemy(instance.id)
	end
	instances[instance.id] = nil
	instance.model:Destroy()

	local spawnGroupId = instance.custom.spawnGroupId :: string?
	if spawnGroupId and groupRemaining[spawnGroupId] then
		groupRemaining[spawnGroupId] -= 1
		if groupRemaining[spawnGroupId] <= 0 then
			groupRemaining[spawnGroupId] = nil
			EnemySpawnService.GroupCleared:Fire(spawnGroupId)
		end
	end

	EnemySpawnService.EnemyDied:Fire(instance.definitionId, instance.tier, instance.custom.damageContributions or {})
end

function EnemySpawnService:SpawnEnemy(enemyDefId: string, spawnCFrame: CFrame, spawnGroupId: string?): EnemyInstance?
	local def = EnemiesById[enemyDefId]
	if not def then
		warn("[EnemySpawnService] unknown enemy id: " .. enemyDefId)
		return nil
	end

	nextInstanceNumber += 1
	local instanceId = def.id .. "_" .. tostring(nextInstanceNumber)

	local partySize = math.max(1, #Players:GetPlayers())
	local hp = EnemyScaling.ScaleForPartySize(def.hp, partySize)
	local damage = EnemyScaling.ScaleForPartySize(def.damage, partySize)

	local model, rootPart = createPlaceholderModel(def, instanceId, spawnCFrame)

	local instance: EnemyInstance = {
		id = instanceId,
		definitionId = def.id,
		tier = def.tier,
		model = model,
		rootPart = rootPart,
		maxHealth = hp,
		health = hp,
		damage = damage,
		poiseMax = def.poiseMax,
		state = EnemyFSM.OnSpawn(),
		target = nil,
		spawnedAt = os.clock(),
		custom = { spawnGroupId = spawnGroupId },
	}
	instances[instanceId] = instance

	local registryEntry: EnemyRegistry.EnemyEntry = {
		id = instanceId,
		tier = def.tier,
		poiseMax = def.poiseMax,
		position = { x = rootPart.Position.X, y = rootPart.Position.Y, z = rootPart.Position.Z },
		takeDamage = function(amount: number, attacker: Player?)
			instance.health = math.max(0, instance.health - amount)
			if attacker then
				instance.custom.lastDamager = attacker
				local contributions = instance.custom.damageContributions :: { [Player]: number }?
				if not contributions then
					contributions = {}
					instance.custom.damageContributions = contributions
				end
				contributions[attacker] = (contributions[attacker] or 0) + amount
			end
			if instance.health <= 0 then
				self:HandleEnemyDeath(instance)
			end
		end,
	}

	if def.behaviorModule == "ShieldBearer" then
		registryEntry.canBeDamagedFrom = function(attackerPosition)
			local facing = rootPart.CFrame.LookVector
			local defenderPosition = { x = rootPart.Position.X, y = rootPart.Position.Y, z = rootPart.Position.Z }
			return not ShieldBearerBlock.IsBlocked(defenderPosition, { x = facing.X, y = facing.Y, z = facing.Z }, attackerPosition)
		end
	end

	EnemyRegistry.Register(registryEntry)
	if def.poiseMax > 0 then
		PoiseService:RegisterEnemy(instanceId, def.poiseMax)
	end

	return instance
end

local function spawnWaveEntry(entry: any, scaledCount: number, spawnPointsByGroup: { [string]: { BasePart } })
	if MapClearService:IsSpawningHalted() then
		return
	end

	local points = spawnPointsByGroup[entry.spawnGroupId]
	if not points or #points == 0 then
		warn(
			(
				"[EnemySpawnService] no EnemySpawnPoint tagged for group %s "
				.. "(Studio hasn't placed it yet) - skipping this wave entry"
			):format(entry.spawnGroupId)
		)
		return
	end

	for i = 1, scaledCount do
		local point = points[((i - 1) % #points) + 1]
		EnemySpawnService:SpawnEnemy(entry.enemyId, point.CFrame, entry.spawnGroupId)
	end
end

function EnemySpawnService:StartWaves(map: any)
	if wavesStarted or not map then
		return
	end
	wavesStarted = true

	-- Party size (and each wave's scaled count) is snapshotted once, here,
	-- and reused for both `groupRemaining`'s total and the actual spawn
	-- loop below — not recomputed per-wave at fire time — so a party
	-- member leaving mid-run can never desync the two counts and soft-lock
	-- an objective that's waiting on `GroupCleared`.
	local partySize = math.max(1, #Players:GetPlayers())
	local scaledCounts: { [any]: number } = {}
	for _, waveEntry in map.waveConfig do
		local scaledCount = math.floor(EnemyScaling.ScaleForPartySize(waveEntry.count, partySize) + 0.5)
		scaledCounts[waveEntry] = scaledCount
		groupRemaining[waveEntry.spawnGroupId] = (groupRemaining[waveEntry.spawnGroupId] or 0) + scaledCount
	end

	local spawnPointsByGroup = getSpawnPointsByGroup()
	for _, waveEntry in map.waveConfig do
		task.delay(waveEntry.delaySeconds, function()
			spawnWaveEntry(waveEntry, scaledCounts[waveEntry], spawnPointsByGroup)
		end)
	end
end

local function updateLoop(dt: number)
	for _, instance in instances do
		if instance.state ~= "Dead" and instance.rootPart.Parent then
			local def = EnemiesById[instance.definitionId]
			local behavior = def and BEHAVIOR_MODULES[def.behaviorModule]
			if behavior then
				local ok, err = pcall(behavior.Update, instance, dt)
				if not ok then
					warn(("[EnemySpawnService] behavior error for %s: %s"):format(instance.id, tostring(err)))
				end
			end
			local position = instance.rootPart.Position
			EnemyRegistry.UpdatePosition(instance.id, { x = position.X, y = position.Y, z = position.Z })
		end
	end
end

function EnemySpawnService:KnitInit()
	PoiseService = Knit.GetService("PoiseService")
	InventoryService = Knit.GetService("InventoryService")
	CurrencyService = Knit.GetService("CurrencyService")
	MapClearService = Knit.GetService("MapClearService")

	local BattlefieldBootstrap = Knit.GetService("BattlefieldBootstrap")
	BattlefieldBootstrap.MapLoaded:Connect(function(map)
		self:StartWaves(map)
	end)
	local existingMap = BattlefieldBootstrap:GetCurrentMap()
	if existingMap then
		self:StartWaves(existingMap)
	end

	RunService.Heartbeat:Connect(updateLoop)
end

return EnemySpawnService
