return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Knit = require(ReplicatedStorage.Packages.Knit)
	local MapDefinitions = require(ReplicatedStorage.Shared.Data.MapDefinitions)

	describe("MapService.GetMapDefinitions", function()
		it("returns the full MapDefinitions catalog", function()
			local MapService = Knit.GetService("MapService")
			local result = MapService:GetMapDefinitions()
			expect(result.Okehazama).to.be.ok()
			expect(result.Okehazama.id).to.equal(MapDefinitions.Okehazama.id)
		end)
	end)
end
