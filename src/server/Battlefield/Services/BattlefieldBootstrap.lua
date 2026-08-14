--!strict
--[[
	T-701: resolves which map this Battlefield server hosts from the first
	player's `TeleportData.mapId` (every party member was teleported here
	with the same `TeleportData`, so the first to join is authoritative for
	the whole server) and clones its map template into Workspace.

	Missing/invalid mapId fails safely — every connected player is kicked
	back to the Lobby with a clear message, never left in a silently-broken
	instance (T-701's DoD). The decision itself is pure (`BattlefieldMapResolution`,
	genuinely tested without a live Player); this just carries it out.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local BattlefieldMapResolution = require(ReplicatedStorage.Shared.Formulas.BattlefieldMapResolution)
local MapDefinitions = require(ReplicatedStorage.Shared.Data.MapDefinitions)

local BattlefieldBootstrap = Knit.CreateService({
	Name = "BattlefieldBootstrap",
	Client = {},
})

-- Server-internal (not networked) — EnemySpawnService/ObjectiveService/
-- MidBossController/FinalBossController all wait on this to know the map
-- has resolved before they set anything up.
BattlefieldBootstrap.MapLoaded = Signal.new()

local currentMapId: string? = nil
local currentMap: any? = nil
local resolved = false

local function kickEveryone(message: string)
	warn("[BattlefieldBootstrap] " .. message)
	for _, player in Players:GetPlayers() do
		player:Kick(message)
	end
end

local function cloneMapTemplate(mapId: string)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local mapsFolder = assets and assets:FindFirstChild("Maps")
	local template = mapsFolder and mapsFolder:FindFirstChild(mapId)
	if not template then
		warn(
			(
				"[BattlefieldBootstrap] no map template at ReplicatedStorage.Assets.Maps.%s "
				.. "(Studio hasn't built it yet, S-701+) - continuing without physical geometry."
			):format(mapId)
		)
		return
	end

	local clone = template:Clone()
	clone.Name = mapId
	clone.Parent = workspace
end

function BattlefieldBootstrap:GetCurrentMap(): any?
	return currentMap
end

function BattlefieldBootstrap:GetCurrentMapId(): string?
	return currentMapId
end

local function initializeMap(mapId: string)
	if resolved then
		return
	end
	resolved = true

	currentMapId = mapId
	currentMap = MapDefinitions[mapId]
	cloneMapTemplate(mapId)

	BattlefieldBootstrap.MapLoaded:Fire(currentMap)
end

local function onPlayerAdded(player: Player)
	if resolved then
		return
	end

	local ok, joinData = pcall(function()
		return player:GetJoinData()
	end)

	local teleportData = if ok then joinData.TeleportData else nil
	local result = BattlefieldMapResolution.Resolve(teleportData, MapDefinitions)

	if not result.ok then
		local reason = (result :: any).reason
		local message = if reason == "MissingMapId"
			then "Battlefield failed to load: missing map data. Please rejoin from the Lobby."
			else "Battlefield failed to load: unknown map. Please rejoin from the Lobby."
		kickEveryone(message)
		return
	end

	initializeMap((result :: any).mapId)
end

function BattlefieldBootstrap:KnitInit()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return BattlefieldBootstrap
