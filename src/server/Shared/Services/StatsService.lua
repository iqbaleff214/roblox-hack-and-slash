--!strict
--[[
	Thin Knit wrapper around StatMath (T-301) — resolves a player's equipped
	accessory ids to statBonus numbers, calls the pure calc, caches the
	result, fires `Client.StatsChanged`. Recomputes on `LevelService.LevelUp`
	(server-internal signal); T-505 (Phase 5) wires the other recompute
	trigger, `LoadoutService.LoadoutChanged`, once that service exists.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local StatMath = require(ReplicatedStorage.Shared.Formulas.StatMath)
local ItemDefinitions = require(ReplicatedStorage.Shared.Data.ItemDefinitions)

local ItemsById = {}
for _, item in ItemDefinitions do
	ItemsById[item.id] = item
end

local StatsService = Knit.CreateService({
	Name = "StatsService",
	Client = {
		StatsChanged = Knit.CreateSignal(),
	},
})

local DataService
local cachedStats = {} :: { [Player]: StatMath.Stats }

local function accessoryStatBonuses(accessories: { [string]: string? }): { number }
	local bonuses = {}
	for _, itemId in accessories do
		local item = ItemsById[itemId]
		if item then
			table.insert(bonuses, item.statBonus)
		end
	end
	return bonuses
end

function StatsService:RecomputeStats(player: Player): StatMath.Stats?
	local profile = DataService:GetProfile(player)
	if not profile then
		return nil
	end

	local stats = StatMath.ComputeStats(profile.Data.Level, accessoryStatBonuses(profile.Data.Loadout.accessories))
	cachedStats[player] = stats
	self.Client.StatsChanged:Fire(player, stats)
	return stats
end

function StatsService:GetStats(player: Player): StatMath.Stats?
	return cachedStats[player] or self:RecomputeStats(player)
end

function StatsService.Client:GetStats(player: Player): StatMath.Stats?
	return self.Server:GetStats(player)
end

function StatsService:KnitInit()
	DataService = Knit.GetService("DataService")

	local LevelService = Knit.GetService("LevelService")
	LevelService.LevelUp:Connect(function(player: Player)
		self:RecomputeStats(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		cachedStats[player] = nil
	end)
end

return StatsService
