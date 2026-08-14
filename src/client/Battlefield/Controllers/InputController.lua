--!strict
--[[
	T-401: maps M1/M2/Q/Shift/R/Tab to ability-intent signals per GDD §6.4.
	No server calls here on purpose — just intent -> local (non-networked)
	Signal, debounced. `CombatController` is what actually turns these into
	server requests; gamepad/touch remapping (Phase 11, T-1102) layers on
	top of these same signals rather than replacing them.
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Constants = require(ReplicatedStorage.Shared.Constants)
local InputDebounce = require(ReplicatedStorage.Shared.Formulas.InputDebounce)

local InputController = Knit.CreateController({ Name = "InputController" })

InputController.LightAttack = Signal.new()
InputController.HeavyAttack = Signal.new()
InputController.Special = Signal.new()
InputController.Dash = Signal.new()
InputController.Ultimate = Signal.new()
InputController.TargetSwitch = Signal.new()

local lastFired: { [string]: number } = {}

local function fireDebounced(signal, actionKey: string)
	local now = os.clock()
	if InputDebounce.ShouldFire(lastFired[actionKey], now, Constants.Combat.InputDebounceSeconds) then
		lastFired[actionKey] = now
		signal:Fire()
	end
end

local KEYCODE_ACTIONS: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.Q] = "Special",
	[Enum.KeyCode.LeftShift] = "Dash",
	[Enum.KeyCode.RightShift] = "Dash",
	[Enum.KeyCode.R] = "Ultimate",
	[Enum.KeyCode.Tab] = "TargetSwitch",
}

local function onInputBegan(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		fireDebounced(InputController.LightAttack, "Light")
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		fireDebounced(InputController.HeavyAttack, "Heavy")
	else
		local action = KEYCODE_ACTIONS[input.KeyCode]
		if action == "Special" then
			fireDebounced(InputController.Special, "Special")
		elseif action == "Dash" then
			fireDebounced(InputController.Dash, "Dash")
		elseif action == "Ultimate" then
			fireDebounced(InputController.Ultimate, "Ultimate")
		elseif action == "TargetSwitch" then
			fireDebounced(InputController.TargetSwitch, "TargetSwitch")
		end
	end
end

function InputController:KnitStart()
	UserInputService.InputBegan:Connect(onInputBegan)
end

return InputController
