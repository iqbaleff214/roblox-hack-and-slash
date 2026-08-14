return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local MapGating = require(ReplicatedStorage.Shared.Formulas.MapGating)
	local Constants = require(ReplicatedStorage.Shared.Constants)

	describe("MapGating.IsMapUnlocked", function()
		local map = { recommendedLevel = 5 }
		local tolerance = Constants.MapLevelTolerance

		it("unlocked exactly at recommendedLevel", function()
			expect(MapGating.IsMapUnlocked(5, map, tolerance)).to.equal(true)
		end)

		it("unlocked exactly at recommendedLevel - tolerance (boundary)", function()
			expect(MapGating.IsMapUnlocked(5 - tolerance, map, tolerance)).to.equal(true)
		end)

		it("locked one level below recommendedLevel - tolerance", function()
			expect(MapGating.IsMapUnlocked(5 - tolerance - 1, map, tolerance)).to.equal(false)
		end)

		it("always unlocked well above recommendedLevel", function()
			expect(MapGating.IsMapUnlocked(50, map, tolerance)).to.equal(true)
		end)
	end)
end
