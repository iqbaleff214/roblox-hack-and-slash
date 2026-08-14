--!strict
--[[
	ProfileService integration (T-201/T-202). Loaded in both places (Shared)
	since each Battlefield/Lobby server is its own process with its own
	PlayerAdded — ProfileService's session-lock plus "ForceLoad" is what makes
	teleporting between them safe (release-then-load, ForceLoad steals the
	lock if the old server's release hasn't landed yet by the time the new
	server asks).

	Other server Services read/write live data via `DataService:GetProfile(player).Data`
	directly (trusted server-to-server). `DataService.Client:GetProfile` is the
	client-safe path: a deep copy, so a caller can never mutate server state
	through the returned table, and it only ever contains `Types.Profile`'s
	fields — ProfileService keeps its own session-lock/meta bookkeeping
	entirely in `Profile.MetaData`, never in `Profile.Data`, so there's no
	server-internal field to accidentally leak here.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ProfileService = require(ServerScriptService.ServerPackages.ProfileService)

local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)
local ProfileTemplate = require(ReplicatedStorage.Shared.Data.ProfileTemplate)
local ProfileMigrations = require(ReplicatedStorage.Shared.Data.ProfileMigrations)

local DataService = Knit.CreateService({
	Name = "DataService",
	Client = {},
})

local profileStore = ProfileService.GetProfileStore(Constants.ProfileStoreName, ProfileTemplate)
local profiles = {} :: { [Player]: any }

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, nested in value do
		copy[key] = deepCopy(nested)
	end
	return copy
end

-- Server-internal: returns the live Profile (with the mutable `.Data` table),
-- trusted server code only. Returns nil if the profile hasn't finished
-- loading yet (or failed to load).
function DataService:GetProfile(player: Player): any?
	return profiles[player]
end

function DataService.Client:GetProfile(player: Player): { [string]: any }?
	local profile = profiles[player]
	if not profile then
		return nil
	end
	return deepCopy(profile.Data)
end

local function onPlayerAdded(player: Player)
	local profile = profileStore:LoadProfileAsync("Player_" .. player.UserId, "ForceLoad")

	if not profile then
		player:Kick("Failed to load your save data. Please rejoin.")
		return
	end

	profile:AddUserId(player.UserId)
	ProfileMigrations.Apply(profile.Data)
	profile:Reconcile()

	profile:ListenToRelease(function()
		profiles[player] = nil
		player:Kick("Your save data was loaded on another server.")
	end)

	if not player:IsDescendantOf(Players) then
		-- Player left while the profile was still loading.
		profile:Release()
		return
	end

	local isValid, validationError = pcall(function()
		Types.Profile(profile.Data)
	end)
	if not isValid then
		warn(("[DataService] profile for %s failed Types.Profile validation: %s"):format(player.Name, tostring(validationError)))
	end

	profiles[player] = profile
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile then
		profile:Release()
	end
end

function DataService:KnitInit()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return DataService
