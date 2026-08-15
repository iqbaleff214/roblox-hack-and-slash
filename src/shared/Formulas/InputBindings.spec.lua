return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local InputBindings = require(ReplicatedStorage.Shared.Formulas.InputBindings)

	describe("InputBindings coverage (T-1102 DoD)", function()
		for _, platformName in { "Desktop", "Console", "Mobile", "Tablet" } do
			it(("%s has a bound input source for all six core actions"):format(platformName), function()
				expect(InputBindings.HasFullCoverage(InputBindings[platformName])).to.equal(true)
			end)
		end

		it("Mobile and Tablet share the identical control scheme (GDD §6.4)", function()
			expect(InputBindings.Mobile).to.equal(InputBindings.Tablet)
		end)

		it("HasFullCoverage correctly fails when an action is missing (sanity check)", function()
			local incomplete = { LightAttack = { keyCode = "X" } }
			expect(InputBindings.HasFullCoverage(incomplete)).to.equal(false)
		end)

		it("Mobile's TargetSwitch is auto-assist, not a dedicated manual input (GDD §6.4)", function()
			expect(InputBindings.Mobile.TargetSwitch.autoAssist).to.equal(true)
		end)
	end)
end
