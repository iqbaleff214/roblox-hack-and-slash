return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local XPCurve = require(ReplicatedStorage.Shared.Formulas.XPCurve)

	describe("XPCurve", function()
		it("requires 0 XP for level 1", function()
			expect(XPCurve.XPForLevel(1)).to.equal(0)
		end)

		it("is strictly increasing", function()
			local previous = XPCurve.XPForLevel(1)
			for level = 2, 100 do
				local current = XPCurve.XPForLevel(level)
				expect(current > previous).to.equal(true)
				previous = current
			end
		end)

		it("LevelForXP(0) == 1", function()
			expect(XPCurve.LevelForXP(0)).to.equal(1)
		end)

		it("round-trips LevelForXP(XPForLevel(n)) == n", function()
			for level = 1, 100 do
				local xp = XPCurve.XPForLevel(level)
				expect(XPCurve.LevelForXP(xp)).to.equal(level)
			end
		end)

		it("LevelForXP is stable partway between two level thresholds", function()
			local xpAtLevel5 = XPCurve.XPForLevel(5)
			local xpAtLevel6 = XPCurve.XPForLevel(6)
			local midpoint = math.floor((xpAtLevel5 + xpAtLevel6) / 2)
			expect(XPCurve.LevelForXP(midpoint)).to.equal(5)
		end)
	end)
end
