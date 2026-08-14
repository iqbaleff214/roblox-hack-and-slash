--[[
	T-701's DoD ("missing/invalid mapId fails safely") is exercised at the
	pure-logic level by `BattlefieldMapResolution.spec.lua` — this service is
	a thin side-effecting wrapper (kick players, clone a map template) around
	that already-tested decision, so there's nothing further to unit-test
	without a live multi-player Studio session (kicking players, teleport
	join-data) — see S-1301.
]]
return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("BattlefieldBootstrap", function()
		it("exposes GetCurrentMap/GetCurrentMapId without erroring", function()
			local BattlefieldBootstrap = Knit.GetService("BattlefieldBootstrap")
			expect(function()
				BattlefieldBootstrap:GetCurrentMap()
				BattlefieldBootstrap:GetCurrentMapId()
			end).never.to.throw()
		end)
	end)
end
