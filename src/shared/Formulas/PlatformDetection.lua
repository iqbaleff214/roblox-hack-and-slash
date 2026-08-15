--!strict
--[[
	T-1101: pure platform-classification decision from raw
	`UserInputService`/`GuiService`/viewport-size signals — takes plain
	strings/numbers/booleans (never `Enum.UserInputType` directly) so it's
	genuinely testable against a scripted "event stream" without a live
	`UserInputService` (T-1101's own test-case wording).

	`isTenFootInterface` wins outright over input type: it's Roblox's own
	"this is a console/TV session" signal and is more authoritative than
	whatever button happened to be pressed last (a console player could
	still have a keyboard plugged in).

	Touch splits into Mobile/Tablet by viewport size — Roblox has no direct
	"is this a tablet" API, so this is a documented heuristic (shorter
	viewport dimension, orientation-agnostic), not a guaranteed-accurate
	device class. GDD §6.4 treats Mobile and Tablet identically for control
	scheme purposes regardless, so the split matters for `PlatformChanged`
	consumers that want it, not for anything gameplay-critical.
]]

local PlatformDetection = {}

export type Platform = "Desktop" | "Console" | "Mobile" | "Tablet"

local TABLET_MIN_SHORT_DIMENSION = 1000

export type DetectionInput = {
	lastInputTypeName: string,
	isTenFootInterface: boolean,
	viewportWidth: number,
	viewportHeight: number,
}

function PlatformDetection.DetectPlatform(input: DetectionInput): Platform
	if input.isTenFootInterface then
		return "Console"
	end

	if input.lastInputTypeName:match("^Gamepad") then
		return "Console"
	end

	if input.lastInputTypeName == "Touch" then
		local shortDimension = math.min(input.viewportWidth, input.viewportHeight)
		if shortDimension >= TABLET_MIN_SHORT_DIMENSION then
			return "Tablet"
		end
		return "Mobile"
	end

	return "Desktop" -- Keyboard, MouseButton1/2/3, MouseMovement, MouseWheel, Focus, ...
end

return PlatformDetection
