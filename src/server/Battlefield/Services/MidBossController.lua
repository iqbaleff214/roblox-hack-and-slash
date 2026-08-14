--!strict
--[[
	T-706: generic controller for every Mid-Boss instance on a map (GDD §7.3).
	One controller, many instances — per-instance state lives in this
	module's own table keyed by instance id, not as singleton fields, so
	`Okehazama`'s two Mid-Bosses (MatsudairaMotoyasu, IioMichihiro) run fully
	independently.

	Reuses `EnemyMovement`/`EnemyRegistry`/`PoiseService` the same way T-704's
	Foot Soldier behaviors do, and a `BasicMelee`-style engage/attack loop —
	Mid-Bosses don't get a bespoke moveset system in this pass (no combo-node
	data exists for enemies, only players, T-104); "unique moveset" per
	GDD §7.3 is satisfied by per-boss `damage`/`hp`/attack range already
	varying via `EnemyDefinitions`, with room to extend later.

	Spawns from `MidBossSpawn`-tagged parts whose `MidBossId` attribute
	matches an id in `map.midBossIds` — independent of `EnemySpawnService`'s
	`waveConfig` loop, since Mid-Bosses are named/singular per the GDD, not
	wave-spawned trash.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Constants = require(ReplicatedStorage.Shared.Constants)
local EnemyFSM = require(ReplicatedStorage.Shared.Formulas.EnemyFSM)
local WeightedRandom = require(ReplicatedStorage.Shared.Formulas.WeightedRandom)
local EnemyDefinitions = require(ReplicatedStorage.Shared.Data.EnemyDefinitions)
local RewardTables = require(ReplicatedStorage.Shared.Data.RewardTables)
local EnemyMovement = require(script.Parent.Parent.Support.EnemyMovement)
local EnemyRegistry = require(ServerScriptService.Server.Support.EnemyRegistry)
local EnemyInstanceType = require(script.Parent.Parent.Support.EnemyInstanceType)

type EnemyInstance = EnemyInstanceType.EnemyInstance

local EnemiesById = {}
for _, def in EnemyDefinitions do
	EnemiesById[def.id] = def
end

local MidBossController = Knit.CreateService({
	Name = "MidBossController",
	Client = {
		-- Fired once per instance, never twice (T-706 DoD) — HUD/portrait UI.
		MidBossEngaged = Knit.CreateSignal(),
		MidBossDefeated = Knit.CreateSignal(),
	},
})

-- Server-internal — ObjectiveService (T-709) grants the side-objective
-- reward on this, not before.
MidBossController.Defeated = Signal.new()

local PoiseService
local InventoryService
local CurrencyService

local instances: { [string]: EnemyInstance } = {}
local engagedInstanceIds: { [string]: boolean } = {}
local spawned = false

local function getEnemiesFolder(): Folder
	local folder = Workspace:FindFirstChild("Enemies") :: Folder?
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Enemies"
		folder.Parent = Workspace
	end
	return folder :: Folder
end

local function createPlaceholderModel(instanceId: string, spawnCFrame: CFrame): (Model, BasePart)
	local model = Instance.new("Model")
	model.Name = instanceId

	local rootPart = Instance.new("Part")
	rootPart.Name = "RootPart"
	rootPart.Size = Vector3.new(4, 8, 3)
	rootPart.Anchored = false
	rootPart.CanCollide = true
	rootPart.CFrame = spawnCFrame
	rootPart.Color = Color3.fromRGB(90, 30, 100)
	rootPart.Parent = model

	model.PrimaryPart = rootPart
	model:SetAttribute(Constants.Attributes.EnemyId, instanceId)
	model:SetAttribute(Constants.Attributes.EnemyTier, "MidBoss")
	CollectionService:AddTag(model, Constants.Tags.Enemy)
	model.Parent = getEnemiesFolder()

	return model, rootPart
end

local function handleDeath(instance: EnemyInstance)
	if instance.state == "Dead" then
		return
	end
	instance.state = "Dead"

	local def = EnemiesById[instance.definitionId]
	local killer = instance.custom.lastDamager :: Player?

	if killer and def and RewardTables[def.lootTableId] then
		local roll = WeightedRandom.Pick(RewardTables[def.lootTableId], math.random())
		if roll.kind == "Item" and roll.itemId then
			InventoryService:GrantItem(killer, roll.itemId)
		elseif roll.kind == "Currency" and roll.amount then
			local amount = math.random(roll.amount.min, roll.amount.max)
			CurrencyService:AddCurrency(killer, Constants.Currency.Soft, amount, "MidBossKill:" .. instance.definitionId)
		end
	end

	EnemyRegistry.Unregister(instance.id)
	PoiseService:UnregisterEnemy(instance.id)
	instances[instance.id] = nil
	instance.model:Destroy()

	MidBossController.Client.MidBossDefeated:FireAll(instance.definitionId)
	MidBossController.Defeated:Fire(instance.definitionId, instance.id, killer)
end

local function spawnMidBoss(midBossId: string, spawnCFrame: CFrame)
	local def = EnemiesById[midBossId]
	if not def then
		warn("[MidBossController] unknown Mid-Boss id: " .. midBossId)
		return
	end

	local instanceId = def.id .. "_" .. tostring(os.clock())

	local model, rootPart = createPlaceholderModel(instanceId, spawnCFrame)
	local instance: EnemyInstance = {
		id = instanceId,
		definitionId = def.id,
		tier = def.tier,
		model = model,
		rootPart = rootPart,
		maxHealth = def.hp,
		health = def.hp,
		damage = def.damage,
		poiseMax = def.poiseMax,
		state = EnemyFSM.OnSpawn(),
		target = nil,
		spawnedAt = os.clock(),
		custom = {},
	}
	instances[instanceId] = instance

	EnemyRegistry.Register({
		id = instanceId,
		tier = def.tier,
		poiseMax = def.poiseMax,
		position = { x = rootPart.Position.X, y = rootPart.Position.Y, z = rootPart.Position.Z },
		takeDamage = function(amount: number, attacker: Player?)
			instance.health = math.max(0, instance.health - amount)
			if attacker then
				instance.custom.lastDamager = attacker
			end
			if instance.health <= 0 then
				handleDeath(instance)
			end
		end,
	})
	PoiseService:RegisterEnemy(instanceId, def.poiseMax)
end

function MidBossController:SpawnAll(map: any)
	if spawned or not map then
		return
	end
	spawned = true

	local spawnPointsById: { [string]: BasePart } = {}
	for _, part in CollectionService:GetTagged(Constants.Tags.MidBossSpawn) do
		if part:IsA("BasePart") then
			local midBossId = part:GetAttribute(Constants.Attributes.MidBossId)
			if typeof(midBossId) == "string" then
				spawnPointsById[midBossId] = part
			end
		end
	end

	for _, midBossId in map.midBossIds do
		local point = spawnPointsById[midBossId]
		if point then
			spawnMidBoss(midBossId, point.CFrame)
		else
			warn(
				("[MidBossController] no MidBossSpawn tagged for %s (Studio hasn't placed it yet) - skipping"):format(
					midBossId
				)
			)
		end
	end
end

local ATTACK_RANGE = 8
local ATTACK_COOLDOWN = Constants.Battlefield.BossAttackCooldownSeconds

local function updateInstance(instance: EnemyInstance, dt: number)
	if instance.state == "Dead" or not instance.rootPart.Parent then
		return
	end

	local target = instance.target
	if not target or not target.Parent or not target.Character then
		target = EnemyMovement.FindNearestPlayer(instance.rootPart.Position)
		instance.target = target
	end
	if not target then
		return
	end

	if not engagedInstanceIds[instance.id] then
		engagedInstanceIds[instance.id] = true
		MidBossController.Client.MidBossEngaged:FireAll(instance.definitionId)
	end

	local targetRoot = (target :: Player).Character and (target :: Player).Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then
		instance.target = nil
		return
	end

	local distance = (targetRoot.Position - instance.rootPart.Position).Magnitude
	if distance > ATTACK_RANGE then
		EnemyMovement.MoveToward(instance.rootPart, targetRoot.Position, Constants.Battlefield.EnemyMoveSpeed, dt)
		return
	end

	local lastAttack = (instance.custom.lastAttackTime :: number?) or 0
	if os.clock() - lastAttack < ATTACK_COOLDOWN then
		return
	end
	instance.custom.lastAttackTime = os.clock()

	local PlayerHealthService = Knit.GetService("PlayerHealthService")
	PlayerHealthService:ApplyEnemyDamage(target :: Player, instance.damage)
end

local function updateLoop(dt: number)
	for _, instance in instances do
		updateInstance(instance, dt)
		if instance.state ~= "Dead" and instance.rootPart.Parent then
			local position = instance.rootPart.Position
			EnemyRegistry.UpdatePosition(instance.id, { x = position.X, y = position.Y, z = position.Z })
		end
	end
end

function MidBossController:KnitInit()
	PoiseService = Knit.GetService("PoiseService")
	InventoryService = Knit.GetService("InventoryService")
	CurrencyService = Knit.GetService("CurrencyService")

	local BattlefieldBootstrap = Knit.GetService("BattlefieldBootstrap")
	BattlefieldBootstrap.MapLoaded:Connect(function(map)
		self:SpawnAll(map)
	end)
	local existingMap = BattlefieldBootstrap:GetCurrentMap()
	if existingMap then
		self:SpawnAll(existingMap)
	end

	RunService.Heartbeat:Connect(updateLoop)
end

return MidBossController
