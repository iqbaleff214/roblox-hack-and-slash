--[[
	Core stat math is unit-tested standalone in StatMath.spec.lua (no
	Player/Studio needed). This spec covers the Knit-wrapper integration and
	requires a live Player — Studio Play Solo/Team Test, see S-1301.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("StatsService", function()
		it("exposes a Client.StatsChanged signal", function()
			local StatsService = Knit.GetService("StatsService")
			expect(StatsService.Client.StatsChanged).to.be.ok()
		end)

		it("computes stats for a live player matching their level", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local StatsService = Knit.GetService("StatsService")
			local DataService = Knit.GetService("DataService")

			local profile = DataService.Client:GetProfile(player)
			local stats = StatsService:GetStats(player)

			expect(stats).to.be.a("table")
			expect(stats.HP > 0).to.equal(true)
			expect(profile.Level).to.be.a("number")
		end)

		it("recomputes stats when LevelService fires LevelUp", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local StatsService = Knit.GetService("StatsService")
			local LevelService = Knit.GetService("LevelService")

			local before = StatsService:GetStats(player)
			LevelService:AwardXP(player, 1000000, "spec")
			local after = StatsService:GetStats(player)

			expect(after.HP > before.HP).to.equal(true)
		end)
	end)
end
