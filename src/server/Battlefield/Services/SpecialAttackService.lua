--!strict
--[[
	T-406: per-weapon special move. Cooldown is server-tracked per player
	(`os.clock()`-based, per the task) regardless of whatever cooldown
	display the client shows. Always hits with the "Slam" hitbox shape
	(full-circle, matches GDD's "best poise-break tool" framing better than
	a narrow directional cone) with bonus poise damage.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local Cooldown = require(ReplicatedStorage.Shared.Formulas.Cooldown)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)

local WeaponsById = {}
for _, weapon in WeaponDefinitions do
	WeaponsById[weapon.id] = weapon
end

local SpecialAttackService = Knit.CreateService({
	Name = "SpecialAttackService",
	Client = {},
})

local CombatService
local HitboxService
local DataService

local lastSpecialUse: { [Player]: number } = {}

function SpecialAttackService:HandleSpecialRequest(player: Player): boolean
	local now = os.clock()
	if not Cooldown.CanUse(lastSpecialUse[player], Constants.Combat.SpecialCooldownSeconds, now) then
		return false
	end

	if not CombatService:TryTransition(player, "Special") then
		return false
	end

	local profile = DataService:GetProfile(player)
	if not profile then
		return false
	end
	local weapon = WeaponsById[profile.Data.Loadout.weaponId]
	if not weapon then
		return false
	end

	lastSpecialUse[player] = now

	local damage = weapon.baseDamage * Constants.Combat.SpecialDamageMult
	HitboxService:ResolveAndApplyHit(player, "Slam", damage, Constants.Combat.SpecialPoiseDamage)

	return true
end

function SpecialAttackService.Client:RequestSpecial(player: Player): boolean
	return self.Server:HandleSpecialRequest(player)
end

function SpecialAttackService:KnitInit()
	CombatService = Knit.GetService("CombatService")
	HitboxService = Knit.GetService("HitboxService")
	DataService = Knit.GetService("DataService")

	game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
		lastSpecialUse[player] = nil
	end)
end

return SpecialAttackService
