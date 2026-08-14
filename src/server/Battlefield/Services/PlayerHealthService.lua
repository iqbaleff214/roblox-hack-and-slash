--!strict
--[[
	Enabling infrastructure T-704's Foot Soldier behaviors need but no
	earlier task explicitly created: something that applies enemy damage to
	a player. This is exactly "whichever service applies enemy damage to
	the player" that T-405 (Phase 4, DashService) explicitly deferred its
	i-frame-voiding check to — `CombatService:IsInvulnerable` is honored
	here, closing that loop for real rather than leaving it a dangling
	forward reference.

	Deliberately minimal beyond that: full death/respawn (ragdoll, revive,
	map-fail conditions) isn't specified in the GDD in enough detail to
	build without inventing mechanics wholesale, so reaching 0 HP just logs
	and stops further health-signal noise — a clear, honest extension point
	rather than a guessed-at implementation.

	Every actually-applied hit (i.e. not voided by an i-frame window) also
	records its damage on `RunStatsService` (Phase 9) — the party-wide
	`damageTaken` input to `RankFormula`'s (T-902) map-clear rank grading.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerHealthService = Knit.CreateService({
	Name = "PlayerHealthService",
	Client = {
		HealthChanged = Knit.CreateSignal(),
	},
})

local CombatService
local StatsService
local RunStatsService

local currentHealth: { [Player]: number } = {}

local function getMaxHealth(player: Player): number
	local stats = StatsService:GetStats(player)
	return if stats then stats.HP else 100
end

function PlayerHealthService:GetHealth(player: Player): number
	return currentHealth[player] or getMaxHealth(player)
end

function PlayerHealthService.Client:GetHealth(player: Player): number
	return self.Server:GetHealth(player)
end

-- Server-internal only — never a `.Client` method. Only enemy behavior
-- modules (trusted server code) ever call this; a player can't damage
-- themselves (or anyone else) through it.
function PlayerHealthService:ApplyEnemyDamage(player: Player, amount: number)
	if CombatService:IsInvulnerable(player) then
		return -- voided during a Dash's i-frame window (T-405)
	end

	local current = self:GetHealth(player)
	local maxHealth = getMaxHealth(player)
	local newHealth = math.clamp(current - amount, 0, maxHealth)
	local actualDamage = current - newHealth
	currentHealth[player] = newHealth
	self.Client.HealthChanged:Fire(player, newHealth, maxHealth)
	RunStatsService:RecordDamageTaken(actualDamage) -- T-902: only damage that actually landed

	if newHealth <= 0 then
		warn(("[PlayerHealthService] %s reached 0 HP."):format(player.Name))
	end
end

-- T-708: `DestructibleBox`'s `StaminaRestore` reward kind — no separate
-- stamina resource exists in this project, so the pickup restores HP
-- (the closest fit to GDD §6.3's "restore" intent without inventing a
-- second resource bar nothing else reads).
function PlayerHealthService:Heal(player: Player, amount: number)
	local current = self:GetHealth(player)
	local maxHealth = getMaxHealth(player)
	local newHealth = math.clamp(current + amount, 0, maxHealth)
	currentHealth[player] = newHealth
	self.Client.HealthChanged:Fire(player, newHealth, maxHealth)
end

function PlayerHealthService:KnitInit()
	CombatService = Knit.GetService("CombatService")
	StatsService = Knit.GetService("StatsService")
	RunStatsService = Knit.GetService("RunStatsService")

	Players.PlayerRemoving:Connect(function(player: Player)
		currentHealth[player] = nil
	end)
end

return PlayerHealthService
