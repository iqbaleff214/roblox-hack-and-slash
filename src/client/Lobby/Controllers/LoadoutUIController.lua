--!strict
--[[
	T-602 (loadout half): minimal functional Loadout UI (GDD §4.4 — Weapon +
	Ultimate + 4 Accessory slots), scoped the same way as ShopUIController
	(correctness over visual polish, which is Phase 11/Studio's job).

	Selecting an item only stages it locally; nothing reaches the server
	until "Apply", which calls `LoadoutService:SetLoadout` with the whole
	loadout at once — mirroring T-501's whole-loadout, no-partial-apply
	design instead of firing a remote per slot.

	Opened via a ProximityPrompt attached to any `LoadoutStation`-tagged
	part (Studio places it in S-603).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local UIBuilder = require(script.Parent.UI.UIBuilder)
local ItemDefinitions = require(ReplicatedStorage.Shared.Data.ItemDefinitions)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local UltimateDefinitions = require(ReplicatedStorage.Shared.Data.UltimateDefinitions)

local ACCESSORY_SLOTS = { "Head", "Body", "Arm", "Leg" }

local LoadoutUIController = Knit.CreateController({ Name = "LoadoutUIController" })

local screenGui: ScreenGui
local listFrame: ScrollingFrame
local statusLabel: TextLabel

local staged = {
	weaponId = nil :: string?,
	ultimateId = nil :: string?,
	accessories = {} :: { [string]: string? },
}

local function rebuildList(profile: any)
	for _, child in listFrame:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local order = 0

	local function header(text: string)
		order += 1
		local label = Instance.new("TextLabel")
		label.Name = "Header"
		label.Size = UDim2.new(1, -8, 0, 24)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.fromRGB(210, 200, 120)
		label.Font = Enum.Font.SourceSansBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.LayoutOrder = order
		label.Parent = listFrame
	end

	local function row(label: string, isSelected: boolean, onClick: () -> ())
		order += 1
		local r = UIBuilder.CreateRow(listFrame, order)
		UIBuilder.CreateLabel(r, label, UDim2.fromScale(0.65, 1))
		local button = UIBuilder.CreateButton(
			r,
			if isSelected then "Selected" else "Select",
			UDim2.fromScale(0.3, 0.8),
			UDim2.fromScale(0.68, 0.1)
		)
		if isSelected then
			button.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
		end
		button.Activated:Connect(onClick)
	end

	header("Weapon")
	for _, weapon in WeaponDefinitions do
		if profile.OwnedItems[weapon.id] then
			row(weapon.name, staged.weaponId == weapon.id, function()
				staged.weaponId = weapon.id
				rebuildList(profile)
			end)
		end
	end

	header("Ultimate")
	for _, ultimate in UltimateDefinitions do
		if profile.OwnedItems[ultimate.id] then
			row(ultimate.name, staged.ultimateId == ultimate.id, function()
				staged.ultimateId = ultimate.id
				rebuildList(profile)
			end)
		end
	end

	for _, slot in ACCESSORY_SLOTS do
		header(slot)
		row("(None)", staged.accessories[slot] == nil, function()
			staged.accessories[slot] = nil
			rebuildList(profile)
		end)
		for _, item in ItemDefinitions do
			if item.slot == slot and profile.OwnedItems[item.id] then
				row(item.name, staged.accessories[slot] == item.id, function()
					staged.accessories[slot] = item.id
					rebuildList(profile)
				end)
			end
		end
	end
end

function LoadoutUIController:Open()
	local DataService = Knit.GetService("DataService")
	local success, profile = DataService:GetProfile():await()
	if not success or not profile then
		return
	end

	staged.weaponId = profile.Loadout.weaponId
	staged.ultimateId = profile.Loadout.ultimateId
	staged.accessories = table.clone(profile.Loadout.accessories)

	statusLabel.Text = ""
	screenGui.Enabled = true
	rebuildList(profile)
end

function LoadoutUIController:Close()
	screenGui.Enabled = false
end

function LoadoutUIController:KnitStart()
	screenGui = UIBuilder.CreateScreenGui("LoadoutUI")
	local panel, content, closeButton = UIBuilder.CreatePanel(screenGui, "Loadout")
	closeButton.Activated:Connect(function()
		self:Close()
	end)

	Knit.GetController("ResponsiveUIController"):Apply(panel) -- T-1103

	local listContainer = Instance.new("Frame")
	listContainer.Name = "ListContainer"
	listContainer.BackgroundTransparency = 1
	listContainer.Size = UDim2.new(1, -16, 1, -76)
	listContainer.Position = UDim2.fromOffset(8, 4)
	listContainer.Parent = content
	listFrame = UIBuilder.CreateScrollingList(listContainer)

	statusLabel = UIBuilder.CreateLabel(content, "", UDim2.new(1, -16, 0, 20), UDim2.new(0, 8, 1, -36))

	local applyButton = UIBuilder.CreateButton(content, "Apply", UDim2.new(1, -16, 0, 32), UDim2.new(0, 8, 1, -68))
	applyButton.Activated:Connect(function()
		local LoadoutService = Knit.GetService("LoadoutService")
		if not staged.weaponId or not staged.ultimateId then
			statusLabel.Text = "Select a weapon and an ultimate first."
			return
		end

		local accepted = LoadoutService:SetLoadout({
			weaponId = staged.weaponId,
			ultimateId = staged.ultimateId,
			accessories = staged.accessories,
		})
		statusLabel.Text = if accepted then "Loadout saved." else "Couldn't save loadout (locked during a run, or invalid)."
	end)

	local function attachStation(part: Instance)
		UIBuilder.AttachTriggerPrompt(part, "LoadoutStationPrompt", "Loadout", function()
			self:Open()
		end)
	end

	for _, part in CollectionService:GetTagged(Constants.Tags.LoadoutStation) do
		attachStation(part)
	end
	CollectionService:GetInstanceAddedSignal(Constants.Tags.LoadoutStation):Connect(attachStation)
end

return LoadoutUIController
