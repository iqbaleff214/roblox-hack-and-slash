--!strict
--[[
	T-1103: pure breakpoint selection from a viewport size. Uses the
	*shorter* viewport dimension rather than raw width, so it's orientation-
	agnostic — a phone in landscape (e.g. 667x375) is constrained by its
	375px height exactly as much as the same phone in portrait is
	constrained by its 375px width, and a fixed-size panel (`UIBuilder`'s
	520x420) needs to shrink either way.

	`scale` is applied via a `UIScale` on every panel this framework manages
	(`ResponsiveUIController`); every existing Lobby panel is a fixed
	520x420 (T-601-605/607) — at `scale = 0.6` that's 312x252, comfortably
	inside even the smallest supported phone viewport (T-1103's DoD: no
	clipping at the smallest phone or largest ultrawide desktop, checked
	against the reference resolutions in this spec's own test table).

	Breakpoint thresholds/scales are a balancing-pass placeholder, same
	caveat as `XPCurve`/`StatMath`/`RankFormula` — not final-tuned values,
	just a real, working default.
]]

local ResponsiveBreakpoints = {}

export type BreakpointName = "Compact" | "Medium" | "Standard" | "Wide"

export type Breakpoint = {
	name: BreakpointName,
	scale: number,
}

-- Checked in order; the first breakpoint whose `maxShortDimension` the
-- viewport's shorter side fits under wins. `Medium`'s ceiling is
-- deliberately kept below 1080 — 1920x1080 (the single most common desktop
-- resolution, short dimension 1080) must land in `Standard` at full scale,
-- not get needlessly shrunk as if it were a tablet. A caught-and-fixed bug
-- during this task: the ceiling was originally 1200, which put every
-- 1080p desktop into `Medium` — found by actually running this reference
-- resolution through the function, not just by inspection.
local BREAKPOINTS: { { name: BreakpointName, maxShortDimension: number, scale: number } } = {
	{ name = "Compact", maxShortDimension = 700, scale = 0.6 },
	{ name = "Medium", maxShortDimension = 900, scale = 0.85 },
	{ name = "Standard", maxShortDimension = 2560, scale = 1.0 },
}
local WIDE_FALLBACK: Breakpoint = { name = "Wide", scale = 1.0 }

function ResponsiveBreakpoints.SelectBreakpoint(viewportWidth: number, viewportHeight: number): Breakpoint
	local shortDimension = math.min(viewportWidth, viewportHeight)
	for _, breakpoint in BREAKPOINTS do
		if shortDimension <= breakpoint.maxShortDimension then
			return { name = breakpoint.name, scale = breakpoint.scale }
		end
	end
	return WIDE_FALLBACK
end

return ResponsiveBreakpoints
