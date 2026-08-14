--!strict
--[[
	Thin passthrough backing T-603's `MapService:GetMapDefinitions()`. Static
	catalog data is already Shared and client-requirable directly, but a
	real Knit service keeps the door open for future server-side filtering
	(e.g. a map temporarily disabled) without the client needing to change
	how it asks for the map list. Lobby-only: Map Select is a Safe Lobby
	feature (GDD §5).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local MapDefinitions = require(ReplicatedStorage.Shared.Data.MapDefinitions)

local MapService = Knit.CreateService({
	Name = "MapService",
	Client = {},
})

function MapService:GetMapDefinitions(): { [string]: any }
	return MapDefinitions
end

function MapService.Client:GetMapDefinitions(): { [string]: any }
	return self.Server:GetMapDefinitions()
end

return MapService
