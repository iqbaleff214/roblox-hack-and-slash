--!strict
--[[
	T-1104: on-screen virtual buttons (GDD §6.4 — "Mobile/Tablet: on-screen
	attack/special/dash/ultimate buttons + auto-assist lock-on"), visible
	only when `PlatformDetectionController` (T-1101) reports Mobile/Tablet.

	"Buttons absent (not just invisible — removed from layout) on Desktop/
	Console" (T-1104's DoD) is satisfied by construction, not by toggling
	`Visible`/`Enabled`: the `ScreenGui` is only ever *built* when the
	platform is Mobile/Tablet, and `:Destroy()`'d the instant it changes
	away from either — there is no dormant-but-present instance on
	Desktop/Console that could ever intercept a click there.

	The single Attack button plays the M1-tap/M2-hold role from GDD's own
	desktop row (mirrors `InputBindings.Mobile`'s documented reasoning):
	released quickly fires `LightAttack`, held past
	`Constants.UI.TouchHeavyHoldSeconds` fires `HeavyAttack` instead. Every
	Attack press also fires `TargetSwitch` — GDD calls touch lock-on
	"auto-assist," i.e. not a separate manual input, so tying it to the
	moment the player commits to attacking (re-acquiring whatever's nearest
	right before the hit lands) is the closest honest reading of that
	phrase without inventing a continuous auto-tracking system this project
	has no camera-control hook for.

	Buttons fire `InputController`'s existing Signals directly (never
	`UserInputService` — touch buttons are `Activated` events, not physical
	inputs `InputController` would see), so `CombatController`/
	`TargetLockController` need no touch-specific handling at all.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)

local TouchControlsUIController = Knit.CreateController({ Name = "TouchControlsUIController" })

local screenGui: ScreenGui? = nil

local function createButton(parent: Instance, text: string, position: UDim2, anchorPoint: Vector2): TextButton
	local button = Instance.new("TextButton")
	button.Name = text .. "Button"
	button.Size = UDim2.fromOffset(80, 80)
	button.Position = position
	button.AnchorPoint = anchorPoint
	button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	button.BackgroundTransparency = 0.3
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button
	return button
end

local function buildUI()
	local InputController = Knit.GetController("InputController")

	local gui = Instance.new("ScreenGui")
	gui.Name = "TouchControlsUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local attackButton = createButton(gui, "Attack", UDim2.new(1, -24, 1, -24), Vector2.new(1, 1))
	local specialButton = createButton(gui, "Special", UDim2.new(1, -132, 1, -24), Vector2.new(1, 1))
	local dashButton = createButton(gui, "Dash", UDim2.new(1, -24, 1, -132), Vector2.new(1, 1))
	local ultimateButton = createButton(gui, "Ultimate", UDim2.new(1, -132, 1, -132), Vector2.new(1, 1))

	local pressStartedAt: number? = nil
	attackButton.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		pressStartedAt = os.clock()
		InputController.TargetSwitch:Fire() -- auto-assist, see header
	end)
	attackButton.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if not pressStartedAt then
			return
		end
		local heldFor = os.clock() - pressStartedAt
		pressStartedAt = nil
		if heldFor >= Constants.UI.TouchHeavyHoldSeconds then
			InputController.HeavyAttack:Fire()
		else
			InputController.LightAttack:Fire()
		end
	end)

	specialButton.Activated:Connect(function()
		InputController.Special:Fire()
	end)
	dashButton.Activated:Connect(function()
		InputController.Dash:Fire()
	end)
	ultimateButton.Activated:Connect(function()
		InputController.Ultimate:Fire()
	end)

	return gui
end

local function applyPlatform(platform: string)
	local isTouchPlatform = platform == Constants.Platform.Mobile or platform == Constants.Platform.Tablet
	if isTouchPlatform and not screenGui then
		screenGui = buildUI()
	elseif not isTouchPlatform and screenGui then
		screenGui:Destroy()
		screenGui = nil
	end
end

function TouchControlsUIController:KnitStart()
	local PlatformDetectionController = Knit.GetController("PlatformDetectionController")
	applyPlatform(PlatformDetectionController:GetPlatform())
	PlatformDetectionController.PlatformChanged:Connect(applyPlatform)
end

return TouchControlsUIController
