--!strict
--[[
	Small shared Instance-construction helpers used by every Lobby UI
	controller this phase (Shop/Loadout/MapSelect/Party). Deliberately
	minimal/unstyled — no theming, no animation, no responsive scaling.
	Visual polish is explicitly out of scope until T-1103 (Phase 11's
	responsive framework) and S-1101/S-1102 (Studio's UI art) land; this
	exists to keep each controller focused on correctness/wiring rather than
	repeating the same dozen lines of Instance.new() boilerplate.
]]

local Players = game:GetService("Players")

local UIBuilder = {}

function UIBuilder.CreateScreenGui(name: string): ScreenGui
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = name
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui
	return screenGui
end

-- Returns (panel, content, closeButton).
function UIBuilder.CreatePanel(screenGui: ScreenGui, title: string): (Frame, Frame, TextButton)
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromOffset(520, 420)
	panel.Position = UDim2.new(0.5, -260, 0.5, -210)
	panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	panel.Parent = screenGui

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 36)
	titleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	titleBar.Parent = panel

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -44, 1, 0)
	titleLabel.Position = UDim2.fromOffset(8, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 20
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.fromOffset(32, 32)
	closeButton.Position = UDim2.new(1, -34, 0, 2)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
	closeButton.Parent = titleBar

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 1, -36)
	content.Position = UDim2.fromOffset(0, 36)
	content.BackgroundTransparency = 1
	content.Parent = panel

	return panel, content, closeButton
end

function UIBuilder.CreateScrollingList(parent: Instance): ScrollingFrame
	local scrolling = Instance.new("ScrollingFrame")
	scrolling.Name = "List"
	scrolling.Size = UDim2.fromScale(1, 1)
	scrolling.BackgroundTransparency = 1
	scrolling.BorderSizePixel = 0
	scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrolling.ScrollBarThickness = 8
	scrolling.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = scrolling

	return scrolling
end

function UIBuilder.CreateRow(parent: Instance, layoutOrder: number): Frame
	local row = Instance.new("Frame")
	row.Name = "Row"
	row.Size = UDim2.new(1, -8, 0, 44)
	row.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	row.LayoutOrder = layoutOrder
	row.Parent = parent
	return row
end

function UIBuilder.CreateLabel(parent: Instance, text: string, size: UDim2, position: UDim2?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Size = size
	label.Position = position or UDim2.fromOffset(0, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

function UIBuilder.CreateButton(parent: Instance, text: string, size: UDim2, position: UDim2?): TextButton
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Size = size
	button.Position = position or UDim2.fromOffset(0, 0)
	button.Parent = parent
	return button
end

-- Attaches a ProximityPrompt to a CollectionService-tagged part/model
-- (idempotent — safe to call again if the same instance is seen twice) and
-- wires it to `onTriggered`. Used by kiosk/station UI toggles, which —
-- unlike portals (S-605) — aren't a dedicated Studio placement task, so the
-- controller attaches its own prompt once the part exists.
function UIBuilder.AttachTriggerPrompt(instance: Instance, promptName: string, actionText: string, onTriggered: () -> ())
	if not instance:IsA("BasePart") and not instance:IsA("Model") then
		return
	end
	local anchor: BasePart? = if instance:IsA("BasePart") then instance else (instance :: Model).PrimaryPart
	if not anchor then
		return
	end
	if anchor:FindFirstChild(promptName) then
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = promptName
	prompt.ActionText = actionText
	prompt.Parent = anchor
	prompt.Triggered:Connect(function(triggeringPlayer: Player)
		if triggeringPlayer == Players.LocalPlayer then
			onTriggered()
		end
	end)
end

return UIBuilder
