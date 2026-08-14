--!strict
--[[
	T-407: 0-100 gauge per player, gained on dealing/taking damage (rate
	constants in Constants.lua, as the task specifies). `OnDamageDealt` is
	called by HitboxService whenever a hit lands; `OnDamageTaken` is exposed
	for Phase 7's enemy-attacks-player code to call once it exists. Ultimates
	always hit in a full radius, ignoring shape/cone entirely (even for a
	string `radiusOrShape`) — GDD §4.3 frames Ultimates as "big, flashy,
	screen-clearing," which a directional cone would undercut.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local UltimateGauge = require(ReplicatedStorage.Shared.Formulas.UltimateGauge)
local RateLimiter = require(ReplicatedStorage.Shared.Formulas.RateLimiter)
local UltimateDefinitions = require(ReplicatedStorage.Shared.Data.UltimateDefinitions)

local UltimatesById = {}
for _, ultimate in UltimateDefinitions do
	UltimatesById[ultimate.id] = ultimate
end

local UltimateGaugeService = Knit.CreateService({
	Name = "UltimateGaugeService",
	Client = {
		UltimateUsed = Knit.CreateSignal(),
	},
})

local CombatService
local HitboxService
local DataService

local gauges: { [Player]: number } = {}
local ultimateTimestamps: { [Player]: { number } } = {}

function UltimateGaugeService:OnDamageDealt(player: Player, damageAmount: number)
	local current = gauges[player] or 0
	gauges[player] = UltimateGauge.Add(current, damageAmount * Constants.Combat.UltimateGaugeGainPerDamageDealt)
end

function UltimateGaugeService:OnDamageTaken(player: Player, damageAmount: number)
	local current = gauges[player] or 0
	gauges[player] = UltimateGauge.Add(current, damageAmount * Constants.Combat.UltimateGaugeGainPerDamageTaken)
end

function UltimateGaugeService:GetGauge(player: Player): number
	return gauges[player] or 0
end

-- Flat gauge grant, not damage-scaled (T-708: `DestructibleBox`'s
-- `UltimateCharge` reward kind — a pickup, not a combat event).
function UltimateGaugeService:AddGauge(player: Player, amount: number)
	local current = gauges[player] or 0
	gauges[player] = UltimateGauge.Add(current, amount)
end

function UltimateGaugeService:HandleUltimateRequest(player: Player): boolean
	local timestamps = ultimateTimestamps[player]
	if not timestamps then
		timestamps = {}
		ultimateTimestamps[player] = timestamps
	end
	if not RateLimiter.TryConsume(timestamps, Constants.Combat.RateLimitMaxPerSecond, Constants.Combat.RateLimitWindowSeconds, os.clock()) then
		return false
	end

	local current = gauges[player] or 0
	if not UltimateGauge.CanUseUltimate(current) then
		return false
	end

	if not CombatService:TryTransition(player, "Ultimate") then
		return false
	end

	local profile = DataService:GetProfile(player)
	if not profile then
		return false
	end
	local ultimate = UltimatesById[profile.Data.Loadout.ultimateId]
	if not ultimate then
		return false
	end

	gauges[player] = 0

	local radius = if typeof(ultimate.radiusOrShape) == "number"
		then ultimate.radiusOrShape :: number
		else HitboxService:GetShapeRadius(ultimate.radiusOrShape :: string)
	HitboxService:ResolveAndApplyRadiusHit(player, radius, ultimate.damage)

	self.Client.UltimateUsed:FireAll(player, ultimate.id)

	return true
end

function UltimateGaugeService.Client:RequestUltimate(player: Player): boolean
	return self.Server:HandleUltimateRequest(player)
end

function UltimateGaugeService.Client:GetGauge(player: Player): number
	return self.Server:GetGauge(player)
end

function UltimateGaugeService:KnitInit()
	CombatService = Knit.GetService("CombatService")
	HitboxService = Knit.GetService("HitboxService")
	DataService = Knit.GetService("DataService")

	Players.PlayerRemoving:Connect(function(player: Player)
		gauges[player] = nil
		ultimateTimestamps[player] = nil
	end)
end

return UltimateGaugeService
