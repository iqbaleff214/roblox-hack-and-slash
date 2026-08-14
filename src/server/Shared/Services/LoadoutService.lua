--!strict
--[[
	T-501/502/503: GDD §4.4 loadout system (Weapon + Ultimate + 4 Accessory
	slots) with saved presets. Shared (not Lobby-only) so T-502's "reject
	while InBattlefield" guard is real server-side enforcement, not just an
	absent Lobby-only UI (T-502's own DoD: "No client-side-only enforcement").

	InBattlefield detection (T-502): a player's Battlefield server is always
	a *different process* than their Lobby server, so this can't be "set by
	PortalService in the Lobby, read in the Battlefield" via shared memory —
	there is no shared memory between them. Instead this detects it the same
	way T-701 (Phase 7's BattlefieldBootstrap) will: `TeleportData.mapId` is
	only ever present when a player arrives via PortalService's map portal,
	never on a normal Lobby join, so its presence on join IS the signal.
	`SetInBattlefield` is also exposed as an explicit override for Phase 6/7
	to call once PortalService/BattlefieldBootstrap exist, but the join-data
	check already makes the guard real today, not just a placeholder.

	Whole-loadout validation (shape via Types.Loadout, then ownership/catalog
	via the pure LoadoutValidation) runs completely before any mutation —
	"no partial apply" per T-501's DoD.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)
local LoadoutValidation = require(ReplicatedStorage.Shared.Formulas.LoadoutValidation)
local ItemDefinitions = require(ReplicatedStorage.Shared.Data.ItemDefinitions)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local UltimateDefinitions = require(ReplicatedStorage.Shared.Data.UltimateDefinitions)

local ItemsById = {}
for _, item in ItemDefinitions do
	ItemsById[item.id] = item
end
local WeaponsById = {}
for _, weapon in WeaponDefinitions do
	WeaponsById[weapon.id] = weapon
end
local UltimatesById = {}
for _, ultimate in UltimateDefinitions do
	UltimatesById[ultimate.id] = ultimate
end

local LoadoutService = Knit.CreateService({
	Name = "LoadoutService",
	Client = {
		LoadoutChanged = Knit.CreateSignal(),
	},
})

-- Server-internal signal (not networked) — for other Shared services
-- (StatsService T-505, CharacterAppearanceService T-504) to react without
-- going through client replication. Same dual-signal pattern as LevelService.
LoadoutService.LoadoutChanged = Signal.new()

local DataService

local inBattlefield: { [Player]: boolean } = {}

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

function LoadoutService:SetInBattlefield(player: Player, isInBattlefield: boolean)
	inBattlefield[player] = isInBattlefield
end

function LoadoutService:IsInBattlefield(player: Player): boolean
	return inBattlefield[player] == true
end

function LoadoutService:GetLoadout(player: Player): any?
	local profile = DataService:GetProfile(player)
	return profile and profile.Data.Loadout
end

function LoadoutService.Client:GetLoadout(player: Player): any?
	local loadout = self.Server:GetLoadout(player)
	return loadout and deepCopy(loadout)
end

local function buildValidationContext(player: Player): LoadoutValidation.Context
	local owned: { [string]: boolean } = {}
	local profile = DataService:GetProfile(player)
	if profile then
		for itemId in profile.Data.OwnedItems do
			owned[itemId] = true
		end
	end

	return {
		weaponsById = WeaponsById,
		ultimatesById = UltimatesById,
		itemsById = ItemsById,
		ownedItemIds = owned,
	}
end

function LoadoutService:SetLoadout(player: Player, loadout: any): boolean
	if self:IsInBattlefield(player) then
		return false
	end

	local shapeOk = pcall(Types.Loadout, loadout)
	if not shapeOk then
		warn(("[LoadoutService] rejected SetLoadout for %s: InvalidShape"):format(player.Name))
		return false
	end

	local valid, reason = LoadoutValidation.ValidateOwnershipAndCatalog(loadout, buildValidationContext(player))
	if not valid then
		warn(("[LoadoutService] rejected SetLoadout for %s: %s"):format(player.Name, reason or "unknown"))
		return false
	end

	local profile = DataService:GetProfile(player)
	if not profile then
		return false
	end

	profile.Data.Loadout = deepCopy(loadout)
	self.Client.LoadoutChanged:Fire(player, profile.Data.Loadout)
	self.LoadoutChanged:Fire(player, profile.Data.Loadout)
	return true
end

function LoadoutService.Client:SetLoadout(player: Player, loadout: any): boolean
	return self.Server:SetLoadout(player, loadout)
end

function LoadoutService:GetPresetCap(player: Player): number
	local profile = DataService:GetProfile(player)
	if not profile then
		return Constants.Loadout.FreePresetSlots
	end
	local purchased = profile.Data.Settings.PurchasedLoadoutPresetSlots or 0
	return Constants.Loadout.FreePresetSlots + purchased
end

function LoadoutService.Client:GetPresetCap(player: Player): number
	return self.Server:GetPresetCap(player)
end

-- Saves a snapshot of the player's CURRENT loadout as a new preset.
function LoadoutService:SavePreset(player: Player): boolean
	local profile = DataService:GetProfile(player)
	if not profile then
		return false
	end

	if #profile.Data.LoadoutPresets >= self:GetPresetCap(player) then
		return false
	end

	table.insert(profile.Data.LoadoutPresets, deepCopy(profile.Data.Loadout))
	return true
end

function LoadoutService.Client:SavePreset(player: Player): boolean
	return self.Server:SavePreset(player)
end

-- Re-validates ownership via the same path as SetLoadout (in case an item
-- was since sold/removed) — never trusts a saved preset blindly.
function LoadoutService:LoadPreset(player: Player, presetIndex: number): boolean
	local profile = DataService:GetProfile(player)
	if not profile then
		return false
	end
	local preset = profile.Data.LoadoutPresets[presetIndex]
	if not preset then
		return false
	end
	return self:SetLoadout(player, preset)
end

function LoadoutService.Client:LoadPreset(player: Player, presetIndex: number): boolean
	return self.Server:LoadPreset(player, presetIndex)
end

local function detectBattlefieldSession(player: Player)
	local ok, joinData = pcall(function()
		return player:GetJoinData()
	end)
	if ok and joinData and joinData.TeleportData and (joinData.TeleportData :: any).mapId then
		inBattlefield[player] = true
	end
end

function LoadoutService:KnitInit()
	DataService = Knit.GetService("DataService")

	Players.PlayerAdded:Connect(detectBattlefieldSession)
	for _, player in Players:GetPlayers() do
		detectBattlefieldSession(player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		inBattlefield[player] = nil
	end)
end

return LoadoutService
