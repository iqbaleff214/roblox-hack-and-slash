return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Types = require(ReplicatedStorage.Shared.Types)
	local ProductCatalog = require(ReplicatedStorage.Shared.Data.ProductCatalog)

	describe("ProductCatalog", function()
		for sku, entry in ProductCatalog do
			describe(sku, function()
				it("validates against Types.ProductCatalogEntry", function()
					expect(function()
						Types.ProductCatalogEntry(entry)
					end).never.to.throw()
				end)

				it("has cosmeticOnly explicitly set as a boolean", function()
					expect(type(entry.cosmeticOnly)).to.equal("boolean")
				end)

				it("has robloxId nil until T-1401 fills it in", function()
					expect(entry.robloxId).to.equal(nil)
				end)
			end)
		end
	end)
end
