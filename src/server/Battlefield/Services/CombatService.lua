--!strict
--[[
	T-402: owns the per-player combat state machine (Idle|Attacking|Dashing|
	Staggered) and combo-node position — the single source of truth other
	combat services (Dash/Special/Ultimate) transition through via
	`:TryTransition`, rather than each keeping their own copy. Reads the
	player's current weapon straight from their profile
	(`Loadout.weaponId`) instead of depending on LoadoutService, which
	doesn't exist until Phase 5 — loadout is locked for the whole run
	anyway (GDD §4.2), and nothing in the Battlefield place can change it
	(ShopUI/LoadoutUI are Lobby-only, Phase 6), so this is safe and
	forward-compatible.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local CombatStateMachine = require(ReplicatedStorage.Shared.Formulas.CombatStateMachine)
local ComboResolver = require(ReplicatedStorage.Shared.Formulas.ComboResolver)
local RateLimiter = require(ReplicatedStorage.Shared.Formulas.RateLimiter)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local ComboTrees = require(ReplicatedStorage.Shared.Data.ComboTrees)

local WeaponsById = {}
for _, weapon in WeaponDefinitions do
	WeaponsById[weapon.id] = weapon
end

local CombatService = Knit.CreateService({
	Name = "CombatService",
	Client = {},
})

type CombatStateEntry = {
	state: CombatStateMachine.CombatState,
	comboNodeId: string,
	invulnerableUntil: number,
	actionId: number,
	attackTimestamps: { number },
}

local combatStates: { [Player]: CombatStateEntry } = {}
local DataService
local HitboxService

local function weaponForPlayer(player: Player)
	local profile = DataService:GetProfile(player)
	if not profile then
		return nil
	end
	return WeaponsById[profile.Data.Loadout.weaponId]
end

function CombatService:GetOrCreateCombatState(player: Player): CombatStateEntry
	local existing = combatStates[player]
	if existing then
		return existing
	end

	local weapon = weaponForPlayer(player)
	local rootNodeId = if weapon then ComboTrees[weapon.comboTreeId].rootNodeId else "Root"

	local entry: CombatStateEntry = {
		state = "Idle",
		comboNodeId = rootNodeId,
		invulnerableUntil = 0,
		actionId = 0,
		attackTimestamps = {},
	}
	combatStates[player] = entry
	return entry
end

function CombatService:IsPlayerAlive(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

function CombatService:IsInvulnerable(player: Player): boolean
	local state = combatStates[player]
	return state ~= nil and os.clock() < state.invulnerableUntil
end

function CombatService:SetInvulnerable(player: Player, durationSeconds: number)
	local state = self:GetOrCreateCombatState(player)
	state.invulnerableUntil = os.clock() + durationSeconds
end

-- Server-internal: validates + applies a state transition against the
-- shared CombatStateMachine table. Called by CombatService itself (Attack)
-- and by DashService/SpecialAttackService/UltimateGaugeService (Dash/
-- Special/Ultimate) after their own cooldown/gauge checks pass.
function CombatService:TryTransition(player: Player, action: CombatStateMachine.CombatAction): boolean
	local state = self:GetOrCreateCombatState(player)
	local allowed, nextState = CombatStateMachine.Transition(state.state, action)
	if not allowed then
		warn(("[CombatService] rejected %s while %s for %s"):format(action, state.state, player.Name))
		return false
	end

	state.state = nextState :: CombatStateMachine.CombatState
	self:ScheduleRecovery(player)
	return true
end

-- Reverts to Idle (and resets the combo to root) after RecoveryWindowSeconds
-- of no further action — a stale timer no-ops via the actionId check, which
-- is also how a Dash mid-combo "cancels attack recovery" (GDD §6.4): the
-- Dash's own TryTransition call bumps actionId, invalidating the pending
-- Attack-recovery timer.
function CombatService:ScheduleRecovery(player: Player)
	local state = combatStates[player]
	if not state then
		return
	end
	state.actionId += 1
	local myActionId = state.actionId

	task.delay(Constants.Combat.RecoveryWindowSeconds, function()
		local current = combatStates[player]
		if current and current.actionId == myActionId and current.state ~= "Staggered" then
			current.state = "Idle"
			local weapon = weaponForPlayer(player)
			if weapon then
				current.comboNodeId = ComboTrees[weapon.comboTreeId].rootNodeId
			end
		end
	end)
end

function CombatService:HandleAttackRequest(player: Player, attackType: "Light" | "Heavy"): boolean
	if attackType ~= "Light" and attackType ~= "Heavy" then
		return false
	end

	local state = self:GetOrCreateCombatState(player)
	if not RateLimiter.TryConsume(state.attackTimestamps, Constants.Combat.RateLimitMaxPerSecond, Constants.Combat.RateLimitWindowSeconds, os.clock()) then
		return false
	end

	if not self:IsPlayerAlive(player) then
		return false
	end

	local weapon = weaponForPlayer(player)
	if not weapon then
		return false
	end

	if not self:TryTransition(player, "Attack") then
		return false
	end

	local nextNodeId = ComboResolver.Resolve(state.comboNodeId, weapon.comboTreeId, attackType)
	state.comboNodeId = nextNodeId

	local node = ComboTrees[weapon.comboTreeId].nodes[nextNodeId]
	local damage = weapon.baseDamage * node.damageMult
	HitboxService:ResolveAndApplyHit(player, node.hitboxShape, damage, node.poiseDamage)

	return true
end

function CombatService.Client:RequestAttack(player: Player, attackType: "Light" | "Heavy"): boolean
	return self.Server:HandleAttackRequest(player, attackType)
end

function CombatService:KnitInit()
	DataService = Knit.GetService("DataService")
	HitboxService = Knit.GetService("HitboxService")

	Players.PlayerRemoving:Connect(function(player: Player)
		combatStates[player] = nil
	end)
end

return CombatService
