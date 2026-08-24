--!strict
--[[
	Knit bootstrap for the Lobby place's client. Loads every Controller under
	this folder's `Controllers` plus every Controller under
	`StarterPlayerScripts.SharedClient.Controllers` (platform detection, input,
	responsive UI, ...). Never loads a Battlefield-only Controller (combat HUD,
	target-lock, ...).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local requireAll = require(ReplicatedStorage.Shared.RequireAll)

requireAll(script.Controllers)

local playerScripts: PlayerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts") :: PlayerScripts
local sharedClient = playerScripts:FindFirstChild("SharedClient")
if sharedClient then
	local sharedControllers = sharedClient:FindFirstChild("Controllers")
	if sharedControllers then
		requireAll(sharedControllers)
	end
end

Knit.Start():catch(function(err)
	warn("[Lobby] Knit failed to start:", err)
end)
