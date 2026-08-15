--!strict
--[[
	Necessary glue for T-1103, not its own task id — same framing as
	`CombatController`'s own header ("not itself a separate task id, but
	necessary for the phase to actually function"). T-1103 explicitly lists
	"HUD" among the UI surfaces the responsive framework must be "applied
	to," but no earlier phase built a combat HUD at all (Battlefield's
	Controllers were only `InputController`/`CombatController`/
	`TargetLockController` — none render anything). Rather than silently
	skip "HUD" from T-1103's DoD, this adds the minimal real HUD there is
	something to apply: an HP bar (`PlayerHealthService.Client.HealthChanged`,
	push-updated) and an Ultimate Gauge bar (`UltimateGaugeService`, polled —
	it exposes `GetGauge` but no gauge-changed signal to push from).

	Deliberately minimal: no poise bar (`PoiseService` has no `.Client`
	surface at all to read from — extending it is out of this phase's
	scope) and no target-lock portrait/name (would need enemy display-name
	data no earlier phase populated). Both are honest gaps, not silently
	invented.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local BattlefieldHUDController = Knit.CreateController({ Name = "BattlefieldHUDController" })

local GAUGE_POLL_INTERVAL_SECONDS = 0.25

local function createBar(parent: Instance, name: string, position: UDim2, fillColor: Color3): (Frame, Frame)
	local back = Instance.new("Frame")
	back.Name = name .. "Back"
	back.Size = UDim2.new(1, -16, 0, 18)
	back.Position = position
	back.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	back.BorderSizePixel = 0
	back.Parent = parent

	local fill = Instance.new("Frame")
	fill.Name = name .. "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = fillColor
	fill.BorderSizePixel = 0
	fill.Parent = back

	return back, fill
end

function BattlefieldHUDController:KnitStart()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BattlefieldHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromOffset(300, 60)
	panel.Position = UDim2.new(0, 12, 1, -72)
	panel.AnchorPoint = Vector2.new(0, 0)
	panel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	panel.BackgroundTransparency = 0.25
	panel.Parent = screenGui

	Knit.GetController("ResponsiveUIController"):Apply(panel) -- T-1103

	local _, hpFill = createBar(panel, "HP", UDim2.fromOffset(0, 6), Color3.fromRGB(180, 50, 50))
	local _, ultimateFill = createBar(panel, "Ultimate", UDim2.fromOffset(0, 32), Color3.fromRGB(90, 180, 250))

	local PlayerHealthService = Knit.GetService("PlayerHealthService")
	local UltimateGaugeService = Knit.GetService("UltimateGaugeService")
	local StatsService = Knit.GetService("StatsService")

	local ok, initialHealth, stats = pcall(function()
		return PlayerHealthService:GetHealth(), StatsService:GetStats()
	end)
	if ok and stats and stats.HP > 0 then
		hpFill.Size = UDim2.fromScale(math.clamp(initialHealth / stats.HP, 0, 1), 1)
	end

	PlayerHealthService.HealthChanged:Connect(function(newHealth: number, maxHealth: number)
		local progress = if maxHealth > 0 then math.clamp(newHealth / maxHealth, 0, 1) else 0
		hpFill.Size = UDim2.fromScale(progress, 1)
	end)

	local elapsedSinceLastPoll = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsedSinceLastPoll += dt
		if elapsedSinceLastPoll < GAUGE_POLL_INTERVAL_SECONDS then
			return
		end
		elapsedSinceLastPoll = 0

		local gaugeOk, gauge = pcall(function()
			return UltimateGaugeService:GetGauge()
		end)
		if gaugeOk and typeof(gauge) == "number" then
			ultimateFill.Size = UDim2.fromScale(math.clamp(gauge / 100, 0, 1), 1)
		end
	end)
end

return BattlefieldHUDController
