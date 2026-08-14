--!strict
--[[
	T-606: `MapPortal`-tagged parts (Attribute `MapId`) back a party teleport
	into a reserved Battlefield server. Teleport happens *only* through the
	Client-exposed `RequestTeleport` — deliberately not wired to the
	physical portal's `ProximityPrompt.Triggered` directly. GDD §6.1 and
	T-605 both describe a two-step flow (stand at the portal, then
	explicitly choose "wait for more" vs "launch now"), and T-605's DoD is
	explicit: "UI never auto-triggers teleport — always requires an
	explicit player action." So the physical prompt (client-side,
	MapSelectController) opens that choice UI; only its "Launch Now" button
	calls this. Standing at the portal alone never teleports anyone.

	Debounce (T-606's DoD) is keyed per requesting player, not per portal —
	rapid re-triggering by the same leader is what the test case describes
	("rapid double-trigger of the same portal"), and since only the leader
	can trigger for the whole party, per-leader keying is exactly right.

	Constants.PlaceIds.Battlefield is `nil` until T-1402 (after S-001
	publishes the real places) — `TeleportService:ReserveServer` is guarded
	against that explicitly rather than left to throw a raw Roblox API
	error, so this fails safely today and will "just work" once published.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local MapGating = require(ReplicatedStorage.Shared.Formulas.MapGating)
local MapDefinitions = require(ReplicatedStorage.Shared.Data.MapDefinitions)

local PortalService = Knit.CreateService({
	Name = "PortalService",
	Client = {},
})

local PartyService
local DataService
local LoadoutService

local teleportInFlight: { [Player]: boolean } = {}

function PortalService:HandleTeleportRequest(player: Player, mapId: string): boolean
	local map = MapDefinitions[mapId]
	if not map then
		return false
	end

	local party = PartyService:GetParty(player)
	local leader = if party then (party :: any).leader else player
	local members = if party then (party :: any).members else { player }

	if leader ~= player then
		return false -- only the party leader (or a solo player) can trigger
	end

	if teleportInFlight[player] then
		return false -- already mid-teleport; debounces rapid double-trigger
	end
	teleportInFlight[player] = true

	local ok = self:_tryTeleport(mapId, map, members)
	teleportInFlight[player] = nil
	return ok
end

function PortalService:_tryTeleport(mapId: string, map: any, members: { Player }): boolean
	for _, member in members do
		local profile = DataService:GetProfile(member)
		local level = if profile then profile.Data.Level else 1
		if not MapGating.IsMapUnlocked(level, map, Constants.MapLevelTolerance) then
			return false
		end
	end

	if not Constants.PlaceIds.Battlefield then
		warn("[PortalService] Constants.PlaceIds.Battlefield is not set yet (pending T-1402) - cannot teleport.")
		return false
	end

	local reserveOk, accessCode = pcall(function()
		return TeleportService:ReserveServer(Constants.PlaceIds.Battlefield :: number)
	end)
	if not reserveOk or not accessCode then
		warn(("[PortalService] failed to reserve a Battlefield server: %s"):format(tostring(accessCode)))
		return false
	end

	for _, member in members do
		LoadoutService:SetInBattlefield(member, true)
	end

	local teleportOk, teleportErr = pcall(function()
		TeleportService:TeleportToPrivateServer(
			Constants.PlaceIds.Battlefield :: number,
			accessCode :: string,
			members,
			nil,
			{ mapId = mapId }
		)
	end)
	if not teleportOk then
		warn(("[PortalService] TeleportToPrivateServer failed: %s"):format(tostring(teleportErr)))
		for _, member in members do
			LoadoutService:SetInBattlefield(member, false)
		end
		return false
	end

	return true
end

function PortalService.Client:RequestTeleport(player: Player, mapId: string): boolean
	return self.Server:HandleTeleportRequest(player, mapId)
end

function PortalService:KnitInit()
	PartyService = Knit.GetService("PartyService")
	DataService = Knit.GetService("DataService")
	LoadoutService = Knit.GetService("LoadoutService")
end

return PortalService
