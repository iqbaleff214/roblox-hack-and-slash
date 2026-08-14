return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local BattlefieldMapResolution = require(ReplicatedStorage.Shared.Formulas.BattlefieldMapResolution)

	local mapDefinitions = { Okehazama = { id = "Okehazama" } }

	describe("BattlefieldMapResolution.Resolve", function()
		it("fails with MissingMapId when TeleportData is nil", function()
			local result = BattlefieldMapResolution.Resolve(nil, mapDefinitions)
			expect(result.ok).to.equal(false)
			expect((result :: any).reason).to.equal("MissingMapId")
		end)

		it("fails with MissingMapId when TeleportData.mapId is absent", function()
			local result = BattlefieldMapResolution.Resolve({}, mapDefinitions)
			expect(result.ok).to.equal(false)
			expect((result :: any).reason).to.equal("MissingMapId")
		end)

		it("fails with UnknownMapId for a mapId not in MapDefinitions", function()
			local result = BattlefieldMapResolution.Resolve({ mapId = "NotARealMap" }, mapDefinitions)
			expect(result.ok).to.equal(false)
			expect((result :: any).reason).to.equal("UnknownMapId")
		end)

		it("succeeds for a valid mapId", function()
			local result = BattlefieldMapResolution.Resolve({ mapId = "Okehazama" }, mapDefinitions)
			expect(result.ok).to.equal(true)
			expect((result :: any).mapId).to.equal("Okehazama")
		end)
	end)
end
