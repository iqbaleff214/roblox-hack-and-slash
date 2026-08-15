--!strict
--[[
	T-401 + T-1102: maps every bound input source for the six core actions
	(GDD §6.4) to local (non-networked) intent Signals, debounced.
	`CombatController` is what actually turns these into server requests.

	T-1102 (gamepad remap): the keycode/input-type dispatch tables below are
	built directly from `InputBindings.Desktop`/`InputBindings.Console`
	(T-1102's own single source of truth, also what the coverage test
	checks) rather than hand-duplicated here — a gamepad button press
	arrives as an ordinary `KeyCode`-bearing `InputObject`
	(`Enum.KeyCode.ButtonX` etc., `UserInputType.Gamepad1`) exactly like a
	keyboard key, so the same `InputBegan` handler and the same six Signals
	serve both without any gamepad-specific branching. Touch has no
	`KeyCode`/`UserInputType` binding at all (GDD's on-screen buttons aren't
	physical inputs) — `TouchControlsUIController` (T-1104) fires these same
	Signals directly from `Activated` events instead of going through this
	file.
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Constants = require(ReplicatedStorage.Shared.Constants)
local InputDebounce = require(ReplicatedStorage.Shared.Formulas.InputDebounce)
local InputBindings = require(ReplicatedStorage.Shared.Formulas.InputBindings)

local InputController = Knit.CreateController({ Name = "InputController" })

InputController.LightAttack = Signal.new()
InputController.HeavyAttack = Signal.new()
InputController.Special = Signal.new()
InputController.Dash = Signal.new()
InputController.Ultimate = Signal.new()
InputController.TargetSwitch = Signal.new()

local ACTION_SIGNALS: { [string]: any } = {
	LightAttack = InputController.LightAttack,
	HeavyAttack = InputController.HeavyAttack,
	Special = InputController.Special,
	Dash = InputController.Dash,
	Ultimate = InputController.Ultimate,
	TargetSwitch = InputController.TargetSwitch,
}

local lastFired: { [string]: number } = {}

local function fireDebounced(action: string)
	local signal = ACTION_SIGNALS[action]
	if not signal then
		return
	end
	local now = os.clock()
	if InputDebounce.ShouldFire(lastFired[action], now, Constants.Combat.InputDebounceSeconds) then
		lastFired[action] = now
		signal:Fire()
	end
end

local KEYCODE_ACTIONS: { [Enum.KeyCode]: string } = {}
local INPUTTYPE_ACTIONS: { [Enum.UserInputType]: string } = {}

for _, platformBindings in { InputBindings.Desktop, InputBindings.Console } do
	for action, binding in platformBindings do
		if binding.keyCode then
			KEYCODE_ACTIONS[Enum.KeyCode[binding.keyCode]] = action
		end
		if binding.altKeyCodes then
			for _, altKeyCode in binding.altKeyCodes do
				KEYCODE_ACTIONS[Enum.KeyCode[altKeyCode]] = action
			end
		end
		if binding.inputType then
			INPUTTYPE_ACTIONS[Enum.UserInputType[binding.inputType]] = action
		end
	end
end

local function onInputBegan(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end

	local action = INPUTTYPE_ACTIONS[input.UserInputType] or KEYCODE_ACTIONS[input.KeyCode]
	if action then
		fireDebounced(action)
	end
end

function InputController:KnitStart()
	UserInputService.InputBegan:Connect(onInputBegan)
end

return InputController
