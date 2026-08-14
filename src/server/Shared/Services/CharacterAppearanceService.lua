--!strict
--[[
	T-504: welds equipped Accessory (Head/Body/Arm/Leg) and Weapon models onto
	the character on spawn/respawn and on loadout change. No `.Client`
	methods — purely reactive.

	"Re-applies the run-locked loadout, not whatever's currently in the
	profile if it somehow diverged" (T-504's DoD) is handled by capturing a
	per-session `runLoadoutSnapshot` instead of re-reading `profile.Data.Loadout`
	on every spawn:
		- The snapshot is taken once when a player's session in this server
		  starts, and again whenever `LoadoutService.LoadoutChanged` fires.
		- In the Lobby, SetLoadout can fire freely, so the snapshot tracks the
		  live loadout — spawn/respawn always shows the current gear.
		- In the Battlefield, T-502 blocks SetLoadout entirely, so
		  LoadoutChanged never fires there — the snapshot from session start
		  (i.e. the run's locked loadout) is what every mid-run respawn uses,
		  even if `profile.Data.Loadout` were somehow read differently.
	One mechanism serves both contexts correctly without needing this Shared
	service to know which place it's running in.

	Assets: `meshAssetId`/`weaponModelAssetId` are `nil` for every current
	catalog entry (S-102/S-103 haven't produced real models yet) — every
	weld path below no-ops gracefully on a missing asset rather than
	erroring, so this is correct and inert today and will "just work" once
	Studio provides real assets.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ItemDefinitions = require(ReplicatedStorage.Shared.Data.ItemDefinitions)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)

local ItemsById = {}
for _, item in ItemDefinitions do
	ItemsById[item.id] = item
end
local WeaponsById = {}
for _, weapon in WeaponDefinitions do
	WeaponsById[weapon.id] = weapon
end

local CharacterAppearanceService = Knit.CreateService({
	Name = "CharacterAppearanceService",
	Client = {},
})

local ACCESSORY_SLOTS = { "Head", "Body", "Arm", "Leg" }
local SLOT_TO_BODY_PART: { [string]: string } = {
	Head = "Head",
	Body = "UpperTorso",
	Arm = "RightUpperArm",
	Leg = "RightUpperLeg",
}
local APPEARANCE_ATTRIBUTE = "LoadoutAppearance"

local DataService
local runLoadoutSnapshot: { [Player]: any } = {}

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

local function tryLoadAsset(assetId: string): Instance?
	local numericId = tonumber(assetId)
	if not numericId then
		return nil
	end

	local ok, result = pcall(function()
		return InsertService:LoadAsset(numericId)
	end)
	if not ok then
		warn(("[CharacterAppearanceService] failed to load asset %s: %s"):format(assetId, tostring(result)))
		return nil
	end
	return result
end

local function tagAsAppearance(instance: Instance)
	instance:SetAttribute(APPEARANCE_ATTRIBUTE, true)
end

local function clearAppearance(character: Model)
	for _, child in character:GetChildren() do
		if child:GetAttribute(APPEARANCE_ATTRIBUTE) then
			child:Destroy()
		end
	end
end

local function weldModelToBodyPart(character: Model, model: Model, bodyPartName: string, weldName: string)
	local bodyPart = character:FindFirstChild(bodyPartName) :: BasePart?
	local handle = model.PrimaryPart or (model:FindFirstChild("Handle") :: BasePart?)
	if not bodyPart or not handle then
		model:Destroy()
		return
	end

	handle.CFrame = bodyPart.CFrame
	model.Parent = character
	tagAsAppearance(model)

	local motor = Instance.new("Motor6D")
	motor.Name = weldName
	motor.Part0 = bodyPart
	motor.Part1 = handle
	motor.Parent = bodyPart
end

local function applyAccessory(character: Model, humanoid: Humanoid, slot: string, item: any)
	if not item or not item.meshAssetId then
		return
	end

	local container = tryLoadAsset(item.meshAssetId)
	if not container then
		return
	end

	local accessory = container:FindFirstChildWhichIsA("Accessory")
	if accessory then
		tagAsAppearance(accessory)
		humanoid:AddAccessory(accessory)
		container:Destroy()
		return
	end

	local model = container:FindFirstChildWhichIsA("Model")
	local bodyPartName = SLOT_TO_BODY_PART[slot]
	if model and bodyPartName then
		model.Parent = nil
		weldModelToBodyPart(character, model, bodyPartName, slot .. "Weld")
	end
	container:Destroy()
end

local function applyWeapon(character: Model, weapon: any)
	if not weapon or not weapon.weaponModelAssetId then
		return
	end

	local container = tryLoadAsset(weapon.weaponModelAssetId)
	if not container then
		return
	end

	local model = container:FindFirstChildWhichIsA("Model")
	if model then
		model.Parent = nil
		weldModelToBodyPart(character, model, "RightHand", "WeaponWeld")
	end
	container:Destroy()
end

local function applyAppearance(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	clearAppearance(character)

	local loadout = runLoadoutSnapshot[player]
	if not loadout then
		return
	end

	for _, slot in ACCESSORY_SLOTS do
		local itemId = loadout.accessories[slot]
		if itemId then
			applyAccessory(character, humanoid, slot, ItemsById[itemId])
		end
	end

	applyWeapon(character, WeaponsById[loadout.weaponId])
end

local function captureLoadoutSnapshot(player: Player)
	local profile = DataService:GetProfile(player)
	if profile then
		runLoadoutSnapshot[player] = deepCopy(profile.Data.Loadout)
	end
end

local function onCharacterAdded(player: Player, character: Model)
	applyAppearance(player, character)
end

function CharacterAppearanceService:KnitInit()
	DataService = Knit.GetService("DataService")
	local LoadoutService = Knit.GetService("LoadoutService")

	LoadoutService.LoadoutChanged:Connect(function(player: Player)
		captureLoadoutSnapshot(player)
		local character = player.Character
		if character then
			applyAppearance(player, character)
		end
	end)

	local function onPlayerAdded(player: Player)
		captureLoadoutSnapshot(player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		runLoadoutSnapshot[player] = nil
	end)
end

return CharacterAppearanceService
