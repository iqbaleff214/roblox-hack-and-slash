--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)
local XPCurve = require(ReplicatedStorage.Shared.Formulas.XPCurve)

local HUDPlayerController = Knit.CreateController({ Name = "HUDPlayerController" })

local levelLabel: TextLabel

local function updateLevelAndXP(level: number, xp: number)
	levelLabel.Text = ("%d"):format(level)
	print("Level and XP updated!")
end

function HUDPlayerController:KnitStart()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local levelGui: ScreenGui = playerGui:WaitForChild("LevelGui")

	levelLabel = levelGui:WaitForChild("LevelFrame"):WaitForChild("LevelOfCurrentPlayer") :: TextLabel

	local DataService = Knit.GetService("DataService")
	local success, profile = DataService:GetProfile():await()
	if success and type(profile) == "table" then
		updateLevelAndXP(profile.Level, profile.XP)
	end

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
