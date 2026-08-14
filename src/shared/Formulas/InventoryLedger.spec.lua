return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local InventoryLedger = require(ReplicatedStorage.Shared.Formulas.InventoryLedger)

	describe("InventoryLedger.Grant", function()
		it("grants an unowned item and returns true", function()
			local ownedItems = {}
			local granted = InventoryLedger.Grant(ownedItems, "Kabuto")
			expect(granted).to.equal(true)
			expect(ownedItems.Kabuto).to.equal(true)
		end)

		it("is idempotent: a second grant of the same item is a no-op returning false", function()
			local ownedItems = { Kabuto = true }
			local granted = InventoryLedger.Grant(ownedItems, "Kabuto")
			expect(granted).to.equal(false)
			expect(ownedItems.Kabuto).to.equal(true)
		end)
	end)

	describe("InventoryLedger.Has", function()
		it("reflects a grant immediately", function()
			local ownedItems = {}
			expect(InventoryLedger.Has(ownedItems, "Kabuto")).to.equal(false)
			InventoryLedger.Grant(ownedItems, "Kabuto")
			expect(InventoryLedger.Has(ownedItems, "Kabuto")).to.equal(true)
		end)

		it("returns false for an item never granted", function()
			local ownedItems = { Kabuto = true }
			expect(InventoryLedger.Has(ownedItems, "DoMaru")).to.equal(false)
		end)
	end)
end
