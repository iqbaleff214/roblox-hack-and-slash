--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local XPCurve = require(ReplicatedStorage.Shared.Formulas.XPCurve)

local HUDPlayerController = Knit.CreateController({ Name = "HUDPlayerController" })

local levelLabel: TextLabel
local xpPercentageLeft: UIGradient
local xpPercentageRight: UIGradient

local function updateLevelAndXP(level: number, xp: number)
	levelLabel.Text = ("%d"):format(level)

	local levelStartXP: number = XPCurve.XPForLevel(level)
	local nextLevelXP: number = XPCurve.XPForLevel(level + 1)
	local span: number = nextLevelXP - levelStartXP

	local progress: number = if span > 0 then math.clamp((xp - levelStartXP) / span, 0, 1) else 1

	local xpRotation: number = math.floor(progress * 360)
	xpPercentageRight.Rotation = math.clamp(xpRotation, 0, 180)
	xpPercentageLeft.Rotation = math.clamp(xpRotation, 180, 360)
end

function HUDPlayerController:KnitStart()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local levelGui: ScreenGui = playerGui:WaitForChild("LevelGui")
	levelLabel = levelGui:WaitForChild("LevelFrame"):WaitForChild("LevelOfCurrentPlayer") :: TextLabel

	local xpProgressFrame: Frame = levelGui:WaitForChild("LevelFrame"):WaitForChild("XPProgressFrame") :: Frame
	xpPercentageLeft =
		xpProgressFrame:WaitForChild("Left"):WaitForChild("Circle"):WaitForChild("UIGradient") :: UIGradient
	xpPercentageRight =
		xpProgressFrame:WaitForChild("Right"):WaitForChild("Circle"):WaitForChild("UIGradient") :: UIGradient

	local DataService = Knit.GetService("DataService")
	DataService.ProfileLoaded:Connect(function(profile: any)
		updateLevelAndXP(profile.Level, profile.XP)
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
end

return HUDPlayerController
