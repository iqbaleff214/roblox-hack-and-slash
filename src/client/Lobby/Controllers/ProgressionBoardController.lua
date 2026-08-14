--!strict
--[[
	T-607: GDD §5 progression board — Level, XP bar, currency balances,
	battle pass progress. Purely signal-driven (T-607's DoD: "No polling"):
	initial state from `DataService:GetProfile()`, then live-updates from
	`LevelService.LevelUp` and `CurrencyService.CurrencyChanged`. Battle
	pass progress is an honest stub, not fake data — T-905 (Phase 9)
	doesn't exist yet, so there's no real signal to wire it to.

	Always visible (not a toggled panel) — GDD §5 lists it as a persistent
	Safe Lobby display, not something you walk up to a kiosk for.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local XPCurve = require(ReplicatedStorage.Shared.Formulas.XPCurve)
local UIBuilder = require(script.Parent.UI.UIBuilder)

local ProgressionBoardController = Knit.CreateController({ Name = "ProgressionBoardController" })

local levelLabel: TextLabel
local xpBarFill: Frame
local currencyLabel: TextLabel

local function updateLevelAndXP(level: number, xp: number)
	levelLabel.Text = ("Level %d"):format(level)

	local levelStartXP = XPCurve.XPForLevel(level)
	local nextLevelXP = XPCurve.XPForLevel(level + 1)
	local span = nextLevelXP - levelStartXP
	local progress = if span > 0 then math.clamp((xp - levelStartXP) / span, 0, 1) else 1
	xpBarFill.Size = UDim2.fromScale(progress, 1)
end

local function updateCurrency(soft: number, premium: number)
	currencyLabel.Text = ("Soft: %d    Premium: %d"):format(soft, premium)
end

function ProgressionBoardController:KnitStart()
	local screenGui = UIBuilder.CreateScreenGui("ProgressionBoard")
	screenGui.Enabled = true

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromOffset(260, 92)
	panel.Position = UDim2.fromOffset(12, 12)
	panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	panel.BackgroundTransparency = 0.2
	panel.Parent = screenGui

	levelLabel = UIBuilder.CreateLabel(panel, "Level 1", UDim2.new(1, -16, 0, 20), UDim2.fromOffset(8, 4))

	local xpBarBack = Instance.new("Frame")
	xpBarBack.Name = "XPBarBack"
	xpBarBack.Size = UDim2.new(1, -16, 0, 10)
	xpBarBack.Position = UDim2.fromOffset(8, 26)
	xpBarBack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	xpBarBack.BorderSizePixel = 0
	xpBarBack.Parent = panel

	xpBarFill = Instance.new("Frame")
	xpBarFill.Name = "XPBarFill"
	xpBarFill.Size = UDim2.fromScale(0, 1)
	xpBarFill.BackgroundColor3 = Color3.fromRGB(90, 180, 250)
	xpBarFill.BorderSizePixel = 0
	xpBarFill.Parent = xpBarBack

	currencyLabel = UIBuilder.CreateLabel(panel, "", UDim2.new(1, -16, 0, 20), UDim2.fromOffset(8, 44))
	UIBuilder.CreateLabel(panel, "Battle Pass: coming soon", UDim2.new(1, -16, 0, 20), UDim2.fromOffset(8, 66))

	local DataService = Knit.GetService("DataService")
	local profile = DataService:GetProfile()
	if profile then
		updateLevelAndXP(profile.Level, profile.XP)
		updateCurrency(profile.SoftCurrency, profile.PremiumCurrency)
	end

	local LevelService = Knit.GetService("LevelService")
	LevelService.LevelUp:Connect(function(newLevel: number)
		local currentProfile = DataService:GetProfile()
		updateLevelAndXP(newLevel, if currentProfile then currentProfile.XP else 0)
	end)

	local CurrencyService = Knit.GetService("CurrencyService")
	CurrencyService.CurrencyChanged:Connect(function(currencyType: string, newAmount: number)
		local currentProfile = DataService:GetProfile()
		if not currentProfile then
			return
		end
		if currencyType == Constants.Currency.Soft then
			updateCurrency(newAmount, currentProfile.PremiumCurrency)
		else
			updateCurrency(currentProfile.SoftCurrency, newAmount)
		end
	end)
end

return ProgressionBoardController
