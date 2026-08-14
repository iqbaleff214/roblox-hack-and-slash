--!strict
--[[
	T-603: CTR-style Map Select (GDD §5) — a tile list of every map from
	`MapService:GetMapDefinitions()`, with a preview panel (recommended
	level, Main Reward, a "Party Up" shortcut into PartyUIController) built
	by the pure `MapPreviewViewModel` so it's data-driven off
	`MapDefinitions.mainRewardItemId`, never hardcoded per map (T-603's DoD).

	Opened by interacting with any `MapPortal`-tagged part — matches the
	GDD's "walk up to or click a map tile" framing: interacting with a
	specific portal opens this panel pre-selecting that portal's map, and
	once open, any tile can be clicked to preview a different map without
	walking to its physical portal.

	The actual "wait for more" vs "launch now" decision is T-605's job
	(PartyUIController) — this controller only tracks *which* map is
	currently selected (`GetSelectedMapId`), which PartyUIController reads
	when its "Launch Now" button fires.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local UIBuilder = require(script.Parent.UI.UIBuilder)
local MapPreviewViewModel = require(ReplicatedStorage.Shared.Formulas.MapPreviewViewModel)
local ItemDefinitions = require(ReplicatedStorage.Shared.Data.ItemDefinitions)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local UltimateDefinitions = require(ReplicatedStorage.Shared.Data.UltimateDefinitions)

local AllRewardsById = {}
for _, item in ItemDefinitions do
	AllRewardsById[item.id] = item
end
for _, weapon in WeaponDefinitions do
	AllRewardsById[weapon.id] = weapon
end
for _, ultimate in UltimateDefinitions do
	AllRewardsById[ultimate.id] = ultimate
end

local MapSelectController = Knit.CreateController({ Name = "MapSelectController" })

local screenGui: ScreenGui
local tileListFrame: ScrollingFrame
local previewNameLabel: TextLabel
local previewLevelLabel: TextLabel
local previewRewardLabel: TextLabel

local selectedMapId: string? = nil

local function showPreview(mapId: string)
	local MapService = Knit.GetService("MapService")
	local maps = MapService:GetMapDefinitions()
	local map = maps[mapId]
	if not map then
		return
	end

	selectedMapId = mapId
	local preview = MapPreviewViewModel.BuildPreview(map, AllRewardsById[map.mainRewardItemId])

	previewNameLabel.Text = preview.displayName
	previewLevelLabel.Text = ("Recommended Level: %d"):format(preview.recommendedLevel)
	previewRewardLabel.Text = ("Main Reward: %s"):format(preview.mainRewardName)
end

function MapSelectController:GetSelectedMapId(): string?
	return selectedMapId
end

local function rebuildTiles()
	local MapService = Knit.GetService("MapService")
	local maps = MapService:GetMapDefinitions()

	for _, child in tileListFrame:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local order = 0
	for mapId, map in maps do
		order += 1
		local row = UIBuilder.CreateRow(tileListFrame, order)
		UIBuilder.CreateLabel(row, map.displayName, UDim2.fromScale(0.6, 1))
		local previewButton = UIBuilder.CreateButton(row, "Preview", UDim2.fromScale(0.3, 0.8), UDim2.fromScale(0.68, 0.1))
		previewButton.Activated:Connect(function()
			showPreview(mapId)
		end)
	end
end

function MapSelectController:Open(preselectMapId: string?)
	screenGui.Enabled = true
	rebuildTiles()
	if preselectMapId then
		showPreview(preselectMapId)
	end
end

function MapSelectController:Close()
	screenGui.Enabled = false
end

function MapSelectController:KnitStart()
	screenGui = UIBuilder.CreateScreenGui("MapSelectUI")
	local _, content, closeButton = UIBuilder.CreatePanel(screenGui, "Map Select")
	closeButton.Activated:Connect(function()
		self:Close()
	end)

	local tileContainer = Instance.new("Frame")
	tileContainer.Name = "TileContainer"
	tileContainer.BackgroundTransparency = 1
	tileContainer.Size = UDim2.new(0.5, -12, 1, -8)
	tileContainer.Position = UDim2.fromOffset(8, 4)
	tileContainer.Parent = content
	tileListFrame = UIBuilder.CreateScrollingList(tileContainer)

	local previewContainer = Instance.new("Frame")
	previewContainer.Name = "PreviewContainer"
	previewContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	previewContainer.Size = UDim2.new(0.5, -12, 1, -8)
	previewContainer.Position = UDim2.new(0.5, 4, 0, 4)
	previewContainer.Parent = content

	previewNameLabel = UIBuilder.CreateLabel(previewContainer, "Select a map", UDim2.new(1, -16, 0, 28), UDim2.fromOffset(8, 8))
	previewLevelLabel = UIBuilder.CreateLabel(previewContainer, "", UDim2.new(1, -16, 0, 24), UDim2.fromOffset(8, 40))
	previewRewardLabel = UIBuilder.CreateLabel(previewContainer, "", UDim2.new(1, -16, 0, 24), UDim2.fromOffset(8, 68))

	local partyUpButton = UIBuilder.CreateButton(previewContainer, "Party Up", UDim2.new(1, -16, 0, 32), UDim2.new(0, 8, 1, -40))
	partyUpButton.Activated:Connect(function()
		local PartyUIController = Knit.GetController("PartyUIController")
		PartyUIController:Open()
	end)

	local function attachPortal(part: Instance)
		local mapId = part:GetAttribute(Constants.Attributes.MapId)
		if typeof(mapId) ~= "string" then
			return
		end
		UIBuilder.AttachTriggerPrompt(part, "MapSelectPrompt", "Select Map", function()
			self:Open(mapId)
		end)
	end

	for _, part in CollectionService:GetTagged(Constants.Tags.MapPortal) do
		attachPortal(part)
	end
	CollectionService:GetInstanceAddedSignal(Constants.Tags.MapPortal):Connect(attachPortal)
end

return MapSelectController
