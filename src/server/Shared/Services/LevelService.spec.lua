--[[
	Core XP/level-crossing rules are unit-tested standalone in
	LevelLedger.spec.lua (no Player/Studio needed). This spec covers the
	Knit-wrapper integration and requires a live Player — Studio Play
	Solo/Team Test, see S-1301.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("LevelService", function()
		it("exposes a Client.LevelUp signal and a server-internal LevelUp signal", function()
			local LevelService = Knit.GetService("LevelService")
			expect(LevelService.Client.LevelUp).to.be.ok()
			expect(LevelService.LevelUp).to.be.ok()
		end)

		it("awards XP to a live player and updates their profile", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local LevelService = Knit.GetService("LevelService")
			local DataService = Knit.GetService("DataService")

			local before = DataService.Client:GetProfile(player).XP
			LevelService:AwardXP(player, 100, "spec")
			local after = DataService.Client:GetProfile(player).XP
			expect(after).to.equal(before + 100)
		end)
	end)
end
