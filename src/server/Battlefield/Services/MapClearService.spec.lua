--[[
	The results-screen-timing/teleport flow needs `Constants.PlaceIds.Lobby`
	(T-1402, not filled in yet) and a live multi-player Studio session to
	observe end-to-end (S-1301/S-1303). This exercises what's testable
	without those: `HandleFinalBossDefeated` halts spawning and is
	idempotent, and neither client-facing method throws.
]]
return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("MapClearService", function()
		it("halts spawning on Final Boss defeat and stays idempotent on a second call", function()
			local MapClearService = Knit.GetService("MapClearService")

			expect(function()
				MapClearService:HandleFinalBossDefeated("Okehazama")
				MapClearService:HandleFinalBossDefeated("Okehazama")
			end).never.to.throw()

			expect(MapClearService:IsSpawningHalted()).to.equal(true)
		end)

		it("AcknowledgeResults never throws, whether or not the map has cleared", function()
			local MapClearService = Knit.GetService("MapClearService")

			expect(function()
				MapClearService:AcknowledgeResults()
			end).never.to.throw()
		end)
	end)
end
