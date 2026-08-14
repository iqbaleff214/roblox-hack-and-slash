--[[
	Full spawn -> Engaged -> Defeated flow needs a real `MidBossSpawn`-tagged
	placement (S-705, not built yet — no Studio work has been done for
	Okehazama beyond what these scripts assume) plus a live Player to
	engage/kill it, so it's exercised by Studio Play Solo/Team Test
	(S-1301/S-1303), not here. This just confirms the service loads and its
	public surface doesn't error with no Mid-Bosses placed.
]]
return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("MidBossController", function()
		it("loads without erroring when no MidBossSpawn points are tagged", function()
			local MidBossController = Knit.GetService("MidBossController")
			expect(function()
				MidBossController:SpawnAll({ midBossIds = { "MatsudairaMotoyasu" } })
			end).never.to.throw()
		end)
	end)
end
