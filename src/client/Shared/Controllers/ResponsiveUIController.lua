--!strict
--[[
	T-1103: the actual scaling half of the responsive UI framework — the
	breakpoint *decision* is the pure, `lune`-tested `ResponsiveBreakpoints.
	SelectBreakpoint`; this is the thin Roblox-API layer that applies its
	result to real `GuiObject`s and keeps it live as the window resizes.

	`:Apply(guiObject)` is called once by every panel-owning controller
	right after it builds its panel (`ShopUIController`, `LoadoutUIController`,
	`MapSelectController`, `PartyUIController`, `ProgressionBoardController`,
	and Battlefield's `BattlefieldHUDController`) — attaches a `UIScale` sized
	for the current breakpoint and starts tracking that instance for future
	resize events. Every existing Lobby panel is a fixed 520x420
	(`UIBuilder.CreatePanel`); a `UIScale` is the correct primitive for
	"shrink this fixed-size thing to fit," rather than fighting `UIBuilder`'s
	fixed-offset layout with relative sizes throughout (T-1103's DoD is about
	not clipping/overflowing, not about a from-scratch relative-layout
	rewrite of every panel).

	Lives in `src/client/Shared/Controllers/` (loaded in both places) since
	both Lobby panels and the Battlefield HUD need it — reached via the
	standard `Knit.GetController("ResponsiveUIController")` cross-controller
	pattern already used throughout this codebase (`CombatController`/
	`TargetLockController` reach `InputController` the same way), not a
	relative `require()` across a place boundary that wouldn't resolve.

	Tracked instances are held in a weak-keyed table so a destroyed
	`GuiObject` (e.g. a rebuilt panel) is naturally forgotten rather than
	leaking a permanent per-panel entry.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ResponsiveBreakpoints = require(ReplicatedStorage.Shared.Formulas.ResponsiveBreakpoints)

local ResponsiveUIController = Knit.CreateController({ Name = "ResponsiveUIController" })

local managed: { [GuiObject]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function getViewportSize(): Vector2
	local camera = Workspace.CurrentCamera
	return if camera then camera.ViewportSize else Vector2.new(1920, 1080)
end

local function currentScale(): number
	local viewportSize = getViewportSize()
	return ResponsiveBreakpoints.SelectBreakpoint(viewportSize.X, viewportSize.Y).scale
end

local function applyScaleTo(guiObject: GuiObject, scale: number)
	local uiScale = guiObject:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = guiObject
	end
	uiScale.Scale = scale
end

-- Attaches/refreshes a `UIScale` on `guiObject` for the current breakpoint
-- and starts tracking it for future viewport-resize updates. Safe to call
-- multiple times on the same instance (idempotent — reuses the existing
-- `UIScale` rather than stacking a second one).
function ResponsiveUIController:Apply(guiObject: GuiObject)
	applyScaleTo(guiObject, currentScale())
	managed[guiObject] = true
end

local function refreshAllManaged()
	local scale = currentScale()
	for guiObject in managed do
		if guiObject.Parent then
			applyScaleTo(guiObject, scale)
		else
			managed[guiObject] = nil
		end
	end
end

function ResponsiveUIController:KnitStart()
	local function hookCamera(camera: Camera?)
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshAllManaged)
		end
	end

	hookCamera(Workspace.CurrentCamera)
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		hookCamera(Workspace.CurrentCamera)
		refreshAllManaged()
	end)
end

return ResponsiveUIController
