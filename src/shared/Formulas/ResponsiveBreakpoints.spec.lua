return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ResponsiveBreakpoints = require(ReplicatedStorage.Shared.Formulas.ResponsiveBreakpoints)

	describe("ResponsiveBreakpoints.SelectBreakpoint", function()
		local referenceResolutions = {
			{ name = "iPhone SE (portrait)", width = 375, height = 667, expected = "Compact" },
			{ name = "iPhone SE (landscape)", width = 667, height = 375, expected = "Compact" },
			{ name = "iPad (portrait)", width = 768, height = 1024, expected = "Medium" },
			{ name = "iPad Pro (landscape)", width = 1366, height = 1024, expected = "Standard" },
			{ name = "1080p desktop", width = 1920, height = 1080, expected = "Standard" },
			{ name = "1440p desktop", width = 2560, height = 1440, expected = "Standard" },
			{ name = "Ultrawide desktop", width = 3440, height = 1440, expected = "Standard" },
			{ name = "Super ultrawide desktop", width = 5120, height = 1440, expected = "Standard" },
		}

		for _, res in referenceResolutions do
			it(("%s (%dx%d) selects %s"):format(res.name, res.width, res.height, res.expected), function()
				local breakpoint = ResponsiveBreakpoints.SelectBreakpoint(res.width, res.height)
				expect(breakpoint.name).to.equal(res.expected)
			end)
		end

		it("scale never exceeds 1.0 and is always positive", function()
			for _, res in referenceResolutions do
				local breakpoint = ResponsiveBreakpoints.SelectBreakpoint(res.width, res.height)
				expect(breakpoint.scale > 0).to.equal(true)
				expect(breakpoint.scale <= 1.0).to.equal(true)
			end
		end)

		it("is orientation-agnostic (uses the shorter dimension)", function()
			local portrait = ResponsiveBreakpoints.SelectBreakpoint(375, 667)
			local landscape = ResponsiveBreakpoints.SelectBreakpoint(667, 375)
			expect(portrait.name).to.equal(landscape.name)
		end)

		it("boundary: exactly at a threshold stays in the smaller breakpoint, one pixel over advances", function()
			expect(ResponsiveBreakpoints.SelectBreakpoint(700, 2000).name).to.equal("Compact")
			expect(ResponsiveBreakpoints.SelectBreakpoint(701, 2000).name).to.equal("Medium")
			expect(ResponsiveBreakpoints.SelectBreakpoint(900, 2000).name).to.equal("Medium")
			expect(ResponsiveBreakpoints.SelectBreakpoint(901, 2000).name).to.equal("Standard")
			expect(ResponsiveBreakpoints.SelectBreakpoint(2560, 2560).name).to.equal("Standard")
			expect(ResponsiveBreakpoints.SelectBreakpoint(2561, 2561).name).to.equal("Wide")
		end)

		it("regression: a 1920x1080 desktop (the most common resolution) is Standard, not Medium", function()
			expect(ResponsiveBreakpoints.SelectBreakpoint(1920, 1080).name).to.equal("Standard")
		end)
	end)
end
