--!strict
--[[
	T-707: Final Boss — multi-phase state machine gated by `FinalBossArenaGate`
	until `ObjectiveService` (T-709) reports all required objectives complete.
	Phase transitions use the pure `BossPhaseFSM` (T-707's own formula):
	`ShouldAdvancePhase` only accepts a strictly-higher computed phase, so HP
	oscillating near a threshold (heals, poise-break invulnerability windows,
	etc.) can never re-trigger or flicker a transition — the DoD requirement.

	Each phase swaps `damage`/attack-range/attack-cooldown via
	`Constants.Battlefield.FinalBossPhaseThresholds`-indexed multipliers, kept
	deliberately simple (a flat damage multiplier per phase) rather than a
	full bespoke moveset system, for the same reason `MidBossController`
	doesn't build one: no combo-node data exists for enemies (T-104 is
	player-only).

	Death fires `Defeated`, which `MapClearService` (T-710) listens for.
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
local BossPhaseFSM = require(ReplicatedStorage.Shared.Formulas.BossPhaseFSM)
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

-- Phase-index -> outgoing damage multiplier (phase 1 = pre-first-threshold,
-- last phase = enraged). One entry per phase, i.e. `#thresholds + 1` long.
local PHASE_DAMAGE_MULTIPLIERS = { 1, 1.25, 1.6 }

local FinalBossController = Knit.CreateService({
	Name = "FinalBossController",
	Client = {
		FinalBossEngaged = Knit.CreateSignal(),
		FinalBossPhaseChanged = Knit.CreateSignal(),
		FinalBossDefeated = Knit.CreateSignal(),
	},
})

-- Server-internal — MapClearService (T-710) listens for this to halt
-- spawning and start the results-screen flow; `MapClearRewardService`
-- (T-903) listens for the same event to compute/grant the map-clear
-- payout. Fires (definitionId, tier, damageContributions: {[Player]:
-- number}) for signature parity with `EnemySpawnService.EnemyDied`/
-- `MidBossController.Defeated` — `damageContributions` isn't consumed for
-- reward purposes here (the Final Boss's reward is the flat, party-wide
-- map-clear bundle, not a damage-share per-kill grant, since GDD §8.1 omits
-- Final Boss from per-enemy rewards on purpose — see `EnemyRewardService`).
FinalBossController.Defeated = Signal.new()

local PoiseService
local InventoryService
local CurrencyService
local ObjectiveService

local instance: EnemyInstance? = nil
local currentPhase = 1
local engaged = false
local spawned = false
local gateOpened = false

local function getEnemiesFolder(): Folder
	local folder = Workspace:FindFirstChild("Enemies") :: Folder?
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Enemies"
		folder.Parent = Workspace
	end
	return folder :: Folder
end

local function setGateSealed(sealed: boolean)
	for _, part in CollectionService:GetTagged(Constants.Tags.FinalBossArenaGate) do
		if part:IsA("BasePart") then
			part.CanCollide = sealed
			part.Transparency = if sealed then 0.3 else 1
		end
	end
end

local function handleDeath(boss: EnemyInstance)
	if boss.state == "Dead" then
		return
	end
	boss.state = "Dead"

	local def = EnemiesById[boss.definitionId]
	local killer = boss.custom.lastDamager :: Player?

	if killer and def and RewardTables[def.lootTableId] then
		local roll = WeightedRandom.Pick(RewardTables[def.lootTableId], math.random())
		if roll.kind == "Item" and roll.itemId then
			InventoryService:GrantItem(killer, roll.itemId)
		elseif roll.kind == "Currency" and roll.amount then
			local amount = math.random(roll.amount.min, roll.amount.max)
			CurrencyService:AddCurrency(killer, Constants.Currency.Soft, amount, "FinalBossKill:" .. boss.definitionId)
		end
	end

	EnemyRegistry.Unregister(boss.id)
	PoiseService:UnregisterEnemy(boss.id)
	instance = nil
	boss.model:Destroy()

	FinalBossController.Client.FinalBossDefeated:FireAll(boss.definitionId)
	FinalBossController.Defeated:Fire(boss.definitionId, boss.tier, boss.custom.damageContributions or {})
end

local function createPlaceholderModel(instanceId: string, spawnCFrame: CFrame): (Model, BasePart)
	local model = Instance.new("Model")
	model.Name = instanceId

	local rootPart = Instance.new("Part")
	rootPart.Name = "RootPart"
	rootPart.Size = Vector3.new(6, 12, 4)
	rootPart.Anchored = false
	rootPart.CanCollide = true
	rootPart.CFrame = spawnCFrame
	rootPart.Color = Color3.fromRGB(120, 10, 10)
	rootPart.Parent = model

	model.PrimaryPart = rootPart
	model:SetAttribute(Constants.Attributes.EnemyId, instanceId)
	model:SetAttribute(Constants.Attributes.EnemyTier, "FinalBoss")
	CollectionService:AddTag(model, Constants.Tags.Enemy)
	model.Parent = getEnemiesFolder()

	return model, rootPart
end

function FinalBossController:TrySpawn(map: any)
	if spawned or not map then
		return
	end
	if not gateOpened then
		return
	end
	spawned = true

	local spawnPoint: BasePart? = nil
	for _, part in CollectionService:GetTagged(Constants.Tags.FinalBossSpawn) do
		if part:IsA("BasePart") then
			spawnPoint = part
			break
		end
	end
	if not spawnPoint then
		warn("[FinalBossController] no FinalBossSpawn tagged (Studio hasn't placed it yet) - skipping")
		spawned = false
		return
	end

	local def = EnemiesById[map.finalBossId]
	if not def then
		warn("[FinalBossController] unknown finalBossId: " .. tostring(map.finalBossId))
		return
	end

	local instanceId = def.id .. "_1"
	local model, rootPart = createPlaceholderModel(instanceId, spawnPoint.CFrame)

	local newInstance: EnemyInstance = {
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
	instance = newInstance

	EnemyRegistry.Register({
		id = instanceId,
		tier = def.tier,
		poiseMax = def.poiseMax,
		position = { x = rootPart.Position.X, y = rootPart.Position.Y, z = rootPart.Position.Z },
		takeDamage = function(amount: number, attacker: Player?)
			newInstance.health = math.max(0, newInstance.health - amount)
			if attacker then
				newInstance.custom.lastDamager = attacker
				local contributions = newInstance.custom.damageContributions :: { [Player]: number }?
				if not contributions then
					contributions = {}
					newInstance.custom.damageContributions = contributions
				end
				contributions[attacker] = (contributions[attacker] or 0) + amount
			end
			if newInstance.health <= 0 then
				handleDeath(newInstance)
			end
		end,
	})
	PoiseService:RegisterEnemy(instanceId, def.poiseMax)
end

local ATTACK_RANGE = 10
local ATTACK_COOLDOWN = Constants.Battlefield.BossAttackCooldownSeconds

local function updateInstance(boss: EnemyInstance, dt: number)
	if boss.state == "Dead" or not boss.rootPart.Parent then
		return
	end

	local hpPercent = boss.health / boss.maxHealth
	local computedPhase = BossPhaseFSM.GetPhaseForHPPercent(hpPercent, Constants.Battlefield.FinalBossPhaseThresholds)
	if BossPhaseFSM.ShouldAdvancePhase(currentPhase, computedPhase) then
		currentPhase = computedPhase
		FinalBossController.Client.FinalBossPhaseChanged:FireAll(boss.definitionId, currentPhase)
	end

	local target = boss.target
	if not target or not target.Parent or not target.Character then
		target = EnemyMovement.FindNearestPlayer(boss.rootPart.Position)
		boss.target = target
	end
	if not target then
		return
	end

	if not engaged then
		engaged = true
		FinalBossController.Client.FinalBossEngaged:FireAll(boss.definitionId)
	end

	local character = (target :: Player).Character
	local targetRoot = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then
		boss.target = nil
		return
	end

	local distance = (targetRoot.Position - boss.rootPart.Position).Magnitude
	if distance > ATTACK_RANGE then
		EnemyMovement.MoveToward(boss.rootPart, targetRoot.Position, Constants.Battlefield.EnemyMoveSpeed, dt)
		return
	end

	local lastAttack = (boss.custom.lastAttackTime :: number?) or 0
	if os.clock() - lastAttack < ATTACK_COOLDOWN then
		return
	end
	boss.custom.lastAttackTime = os.clock()

	local multiplier = PHASE_DAMAGE_MULTIPLIERS[currentPhase] or PHASE_DAMAGE_MULTIPLIERS[#PHASE_DAMAGE_MULTIPLIERS]
	local PlayerHealthService = Knit.GetService("PlayerHealthService")
	PlayerHealthService:ApplyEnemyDamage(target :: Player, boss.damage * multiplier)
end

local function updateLoop(dt: number)
	if instance then
		updateInstance(instance, dt)
		if instance and instance.state ~= "Dead" and instance.rootPart.Parent then
			local position = instance.rootPart.Position
			EnemyRegistry.UpdatePosition(instance.id, { x = position.X, y = position.Y, z = position.Z })
		end
	end
end

function FinalBossController:KnitInit()
	PoiseService = Knit.GetService("PoiseService")
	InventoryService = Knit.GetService("InventoryService")
	CurrencyService = Knit.GetService("CurrencyService")

	local BattlefieldBootstrap = Knit.GetService("BattlefieldBootstrap")
	local currentMap = nil

	BattlefieldBootstrap.MapLoaded:Connect(function(map)
		currentMap = map
		setGateSealed(true)
		self:TrySpawn(map)
	end)
	local existingMap = BattlefieldBootstrap:GetCurrentMap()
	if existingMap then
		currentMap = existingMap
		setGateSealed(true)
	end

	ObjectiveService = Knit.GetService("ObjectiveService")
	ObjectiveService.ObjectiveUpdated:Connect(function()
		if ObjectiveService:IsGateOpen() then
			gateOpened = true
			setGateSealed(false)
			if currentMap then
				self:TrySpawn(currentMap)
			end
		end
	end)

	RunService.Heartbeat:Connect(updateLoop)
end

return FinalBossController
