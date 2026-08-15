--!strict
--[[
	T-1101: thin Knit wrapper around the pure `PlatformDetection.DetectPlatform`
	— the actual classification logic lives there and is genuinely
	`lune`-tested; this just supplies live `UserInputService`/`GuiService`/
	viewport-size values and re-fires `PlatformChanged` whenever the
	computed platform actually changes.

	Lives in `src/client/Shared/Controllers/` (loaded in both places,
	per this folder's own README) — platform detection is relevant in the
	Lobby (which UI layout to show) just as much as the Battlefield (which
	input scheme to wire up, T-1102), so it can't be place-scoped to either.

	"Switching input mid-session updates the signal live" (T-1101's DoD) is
	satisfied by `UserInputService.LastInputTypeChanged` — the one
	live-updating signal Roblox actually fires when the player's active
	input method changes (e.g. plugging in a gamepad, or picking the mouse
	back up). `GuiService:IsTenFootInterface()` has no changed-signal of its
	own (it's effectively static for a session), so it's just re-read
	synchronously alongside every recompute — cheap, and correct either way.
]]

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local PlatformDetection = require(ReplicatedStorage.Shared.Formulas.PlatformDetection)

local PlatformDetectionController = Knit.CreateController({ Name = "PlatformDetectionController" })

PlatformDetectionController.PlatformChanged = Signal.new()

local currentPlatform: PlatformDetection.Platform = "Desktop"

local function getViewportSize(): Vector2
	local camera = Workspace.CurrentCamera
	return if camera then camera.ViewportSize else Vector2.new(1920, 1080)
end

local function recompute()
	local viewportSize = getViewportSize()
	local platform = PlatformDetection.DetectPlatform({
		lastInputTypeName = UserInputService:GetLastInputType().Name,
		isTenFootInterface = GuiService:IsTenFootInterface(),
		viewportWidth = viewportSize.X,
		viewportHeight = viewportSize.Y,
	})

	if platform ~= currentPlatform then
		currentPlatform = platform
		PlatformDetectionController.PlatformChanged:Fire(platform)
	end
end

function PlatformDetectionController:GetPlatform(): PlatformDetection.Platform
	return currentPlatform
end

function PlatformDetectionController:KnitStart()
	recompute()
	UserInputService.LastInputTypeChanged:Connect(recompute)
end

return PlatformDetectionController
