--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local XPCurve = require(ReplicatedStorage.Shared.Formulas.XPCurve)

local HUDPlayerController = Knit.CreateController({ Name = "HUDPlayerController" })

local levelLabel: TextLabel
local xpLabel: TextLabel
local xpPercentageLeft: UIGradient
local xpPercentageRight: UIGradient
local currencyFrame: Frame

local function updateLevelAndXP(level: number, xp: number)
	levelLabel.Text = ("%d"):format(level)

	local levelStartXP: number = XPCurve.XPForLevel(level)
	local nextLevelXP: number = XPCurve.XPForLevel(level + 1)
	local span: number = nextLevelXP - levelStartXP

	xpLabel.Text = ("%d/%d xp"):format(xp, nextLevelXP)

	local progress: number = if span > 0 then math.clamp((xp - levelStartXP) / span, 0, 1) else 1

	local xpRotation: number = math.floor(progress * 360)
	xpPercentageRight.Rotation = math.clamp(xpRotation, 0, 180)
	xpPercentageLeft.Rotation = math.clamp(xpRotation, 180, 360)
end

local function updateCurrency(currencyType: string, newAmount: number)
	local currencyMainFrame: Frame? =
		currencyFrame:WaitForChild(currencyType .. "Frame"):WaitForChild("CurrencyContainer") :: Frame
	if currencyMainFrame == nil then
		return
	end

	local currency: string = if currencyType == "SoftCurrency" then "Rp" else "Ryō"

	local currencyText: TextLabel = currencyMainFrame:WaitForChild("TextLabel") :: TextLabel
	local oldAmount: number = tonumber(currencyText.Text:sub(#currency + 2)) or 0

	if newAmount == oldAmount then
		print("[Currency " .. currencyType .. "] old amount and new amount is the same, not changing anything")
		return
	end

	currencyText.Text = currency .. " " .. tostring(newAmount)
end

function HUDPlayerController:KnitStart()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local hudGui: ScreenGui = playerGui:WaitForChild("HUD")

	local levelFrame: Frame = hudGui:WaitForChild("LevelFrame") :: Frame
	local menuBarFrame: Frame = hudGui:WaitForChild("MenuBarFrame") :: Frame
	currencyFrame = hudGui:WaitForChild("CurrencyFrame") :: Frame

	levelLabel = levelFrame:WaitForChild("LevelOfCurrentPlayer") :: TextLabel
	xpLabel = levelFrame:WaitForChild("XPProgressText") :: TextLabel

	local xpProgressFrame: Frame = levelFrame:WaitForChild("XPProgressFrame") :: Frame
	xpPercentageLeft =
		xpProgressFrame:WaitForChild("Left"):WaitForChild("Circle"):WaitForChild("UIGradient") :: UIGradient
	xpPercentageRight =
		xpProgressFrame:WaitForChild("Right"):WaitForChild("Circle"):WaitForChild("UIGradient") :: UIGradient

	local DataService = Knit.GetService("DataService")
	DataService.ProfileLoaded:Connect(function(profile: any)
		updateLevelAndXP(profile.Level, profile.XP)

		for _, value in Constants.Currency do
			updateCurrency(value :: string, profile[value])
		end
	end)

	local LevelService = Knit.GetService("LevelService")
	LevelService.LevelUp:Connect(function(newLevel: number)
		local s, currentProfile = DataService:GetProfile():await()
		if s and type(currentProfile) == "table" then
			updateLevelAndXP(newLevel, currentProfile.XP)
		else
			updateLevelAndXP(newLevel, 0)
		end
	end)

	local CurrencyService = Knit.GetService("CurrencyService")
	CurrencyService.CurrencyChanged:Connect(updateCurrency)
end

return HUDPlayerController
