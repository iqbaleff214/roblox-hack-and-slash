--!strict
--[[
	T-1102: per-platform input bindings for the six core actions (GDD §6.4's
	cross-platform mapping table). This is the single source of truth both
	the coverage test AND the real input wiring consume — `InputController`
	builds its `Enum.KeyCode` lookup directly from `Desktop`/`Console` below,
	and `TouchControlsUIController` builds its on-screen buttons directly
	from `Mobile` — so a declared binding and the code that implements it
	can never drift apart into two competing lists.

	Desktop matches the pre-existing T-401 mapping exactly (M1/M2/Q/Shift/R/
	Tab). Console assigns GDD's two explicit callouts (trigger for Ultimate,
	right-stick click for lock-on) plus sensible face-button defaults for the
	rest (no jump/dodge-adjacent mechanic exists in this game to conflict
	with ButtonA, so Dash claims it). Mobile/Tablet share one control scheme
	(GDD groups them identically) — a single "Attack" button plays the
	M1/M2 tap-vs-hold role from GDD's own desktop row (`Light Attack (M1/
	tap)` / `Heavy Attack (M2/hold)`) rather than needing two buttons, and
	`TargetSwitch` has no dedicated button at all: GDD explicitly calls
	touch lock-on "auto-assist," so it's marked `autoAssist = true` and
	fired automatically alongside the Attack button rather than needing its
	own tap target (see `TouchControlsUIController`'s header for exactly
	when it fires) — it still counts as "reachable" per T-1102's DoD, just
	not via a manual, separate input.
]]

local InputBindings = {}

export type Action = "LightAttack" | "HeavyAttack" | "Special" | "Dash" | "Ultimate" | "TargetSwitch"

InputBindings.Actions = { "LightAttack", "HeavyAttack", "Special", "Dash", "Ultimate", "TargetSwitch" } :: { Action }

export type Binding = {
	inputType: string?, -- Enum.UserInputType name, e.g. "MouseButton1"
	keyCode: string?, -- Enum.KeyCode name, e.g. "Q", "ButtonX"
	altKeyCodes: { string }?, -- additional Enum.KeyCode names bound to the same action
	touchButton: string?, -- on-screen touch button name
	autoAssist: boolean?, -- fires automatically alongside another binding, no dedicated input
}

InputBindings.Desktop = {
	LightAttack = { inputType = "MouseButton1" },
	HeavyAttack = { inputType = "MouseButton2" },
	Special = { keyCode = "Q" },
	Dash = { keyCode = "LeftShift", altKeyCodes = { "RightShift" } },
	Ultimate = { keyCode = "R" },
	TargetSwitch = { keyCode = "Tab" },
} :: { [Action]: Binding }

InputBindings.Console = {
	LightAttack = { keyCode = "ButtonX" },
	HeavyAttack = { keyCode = "ButtonY" },
	Special = { keyCode = "ButtonB" },
	Dash = { keyCode = "ButtonA" },
	Ultimate = { keyCode = "ButtonR2" }, -- right trigger
	TargetSwitch = { keyCode = "ButtonR3" }, -- right-stick click
} :: { [Action]: Binding }

InputBindings.Mobile = {
	LightAttack = { touchButton = "Attack" }, -- tap
	HeavyAttack = { touchButton = "Attack" }, -- hold
	Special = { touchButton = "Special" },
	Dash = { touchButton = "Dash" },
	Ultimate = { touchButton = "Ultimate" },
	TargetSwitch = { touchButton = "Attack", autoAssist = true },
} :: { [Action]: Binding }

InputBindings.Tablet = InputBindings.Mobile -- identical control scheme per GDD §6.4

function InputBindings.HasFullCoverage(platformBindings: { [Action]: Binding }): boolean
	for _, action in InputBindings.Actions do
		if not platformBindings[action] then
			return false
		end
	end
	return true
end

return InputBindings
