return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Types = require(ReplicatedStorage.Shared.Types)
	local UltimateDefinitions = require(ReplicatedStorage.Shared.Data.UltimateDefinitions)

	describe("UltimateDefinitions", function()
		it("validates every entry against Types.Ultimate", function()
			for _, ultimate in UltimateDefinitions do
				expect(function()
					Types.Ultimate(ultimate)
				end).never.to.throw()
			end
		end)

		it("has no duplicate ids", function()
			local seen = {}
			for _, ultimate in UltimateDefinitions do
				expect(seen[ultimate.id]).to.equal(nil)
				seen[ultimate.id] = true
			end
		end)
	end)
end
