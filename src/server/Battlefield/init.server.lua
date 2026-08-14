--!strict
--[[
	Knit bootstrap for the Battlefield place (shared by all maps, GDD §6).
	Loads every Service under this folder's `Services` plus every Service under
	`ServerScriptService.SharedServer.Services` (profile/currency/inventory/etc,
	needed in both places). Deliberately never loads a Lobby-only Service
	(ShopService, PortalService, PartyService, ...) — see T-608 / the
	Phase-separation smoke test in scripts/check-place-separation.luau.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local requireAll = require(ReplicatedStorage.Shared.RequireAll)

requireAll(script.Services)

local sharedServer = ServerScriptService:FindFirstChild("SharedServer")
if sharedServer then
	local sharedServices = sharedServer:FindFirstChild("Services")
	if sharedServices then
		requireAll(sharedServices)
	end
end

Knit.Start():catch(function(err)
	warn("[Battlefield] Knit failed to start:", err)
end)
