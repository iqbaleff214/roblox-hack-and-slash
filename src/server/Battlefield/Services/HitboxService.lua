--!strict
--[[
	T-404: resolves a combo/special/ultimate hit into actual damage.
	Server-authoritative only — no `.Client` methods at all. A hit is always
	the *result* of an already-validated action (CombatService/DashService/
	SpecialAttackService/UltimateGaugeService each validate their own request
	before calling in here), never something a client can trigger directly
	or report the outcome of. Geometry is delegated to the pure
	`HitboxGeometry`; live enemy data comes from the server-only
	`EnemyRegistry` (see its own header for why that can't live in
	`src/shared/`).

	`ApplyDamageToTargets` takes the attacker's origin (Phase 7 addition) so
	it can consult a target's optional `canBeDamagedFrom` check —
	ShieldBearer (T-704) is the only variant that sets it, blocking frontal
	hits.

	Also forwards every hit's origin + shape radius to
	`DestructibleBoxService:TryBreakNear` (T-708) — box-breaking "folds into
	normal combo flow" (GDD §6.3) by riding the same swing resolution as
	enemy damage, not a separate hitbox pass.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local HitboxGeometry = require(ReplicatedStorage.Shared.Formulas.HitboxGeometry)
local EnemyRegistry = require(ServerScriptService.Server.Support.EnemyRegistry)

local HitboxService = Knit.CreateService({
	Name = "HitboxService",
	Client = {},
})

local PoiseService
local UltimateGaugeService
local DestructibleBoxService

local function characterOriginAndFacing(player: Player): (HitboxGeometry.Position?, HitboxGeometry.Position?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return nil, nil
	end

	local position = rootPart.Position
	local look = rootPart.CFrame.LookVector
	return { x = position.X, y = position.Y, z = position.Z }, { x = look.X, y = look.Y, z = look.Z }
end

local function enemyCandidates(): { HitboxGeometry.HitCandidate }
	local candidates = {}
	for _, enemy in EnemyRegistry.GetAll() do
		table.insert(candidates, { id = enemy.id, position = enemy.position })
	end
	return candidates
end

-- Directional hit (combo swings, specials): geometry cone + radius per
-- `hitboxShape`, facing the player's current look direction.
function HitboxService:ResolveAndApplyHit(player: Player, hitboxShape: string, damage: number, poiseDamage: number): { string }
	local origin, facing = characterOriginAndFacing(player)
	if not origin or not facing then
		return {}
	end

	local hitIds = HitboxGeometry.GetHitTargets(origin, facing, hitboxShape, enemyCandidates())
	self:ApplyDamageToTargets(player, hitIds, damage, poiseDamage, origin)
	DestructibleBoxService:TryBreakNear(player, origin, self:GetShapeRadius(hitboxShape))
	return hitIds
end

-- Full-radius hit, no facing/cone (Ultimates, T-407 — "big, screen-clearing").
function HitboxService:ResolveAndApplyRadiusHit(player: Player, radius: number, damage: number): { string }
	local origin = characterOriginAndFacing(player)
	if not origin then
		return {}
	end

	local hitIds = HitboxGeometry.GetHitTargetsInRadius(origin, radius, enemyCandidates())
	self:ApplyDamageToTargets(player, hitIds, damage, 0, origin)
	DestructibleBoxService:TryBreakNear(player, origin, radius)
	return hitIds
end

function HitboxService:ApplyDamageToTargets(
	player: Player,
	hitIds: { string },
	damage: number,
	poiseDamage: number,
	attackerOrigin: HitboxGeometry.Position?
)
	for _, enemyId in hitIds do
		local enemy = EnemyRegistry.Get(enemyId)
		if enemy then
			local canDamage = not enemy.canBeDamagedFrom or not attackerOrigin or enemy.canBeDamagedFrom(attackerOrigin)
			if canDamage then
				enemy.takeDamage(damage, player)
				if poiseDamage > 0 then
					PoiseService:ApplyPoiseDamage(enemyId, poiseDamage)
				end
				UltimateGaugeService:OnDamageDealt(player, damage)
			end
		end
	end
end

function HitboxService:GetShapeRadius(hitboxShape: string): number
	local params = HitboxGeometry.ShapeParams[hitboxShape]
	return if params then params.radius else 0
end

function HitboxService:KnitInit()
	PoiseService = Knit.GetService("PoiseService")
	UltimateGaugeService = Knit.GetService("UltimateGaugeService")
	DestructibleBoxService = Knit.GetService("DestructibleBoxService")
end

return HitboxService
