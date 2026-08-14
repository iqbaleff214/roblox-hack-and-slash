--[[
	Core idempotency rules are unit-tested standalone in
	InventoryLedger.spec.lua (no Player/Studio needed). This spec covers the
	thin Knit-wrapper integration and requires a live Player — Studio Play
	Solo/Team Test, see S-1301.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("InventoryService", function()
		it("exposes a Client.ItemGranted signal", function()
			local InventoryService = Knit.GetService("InventoryService")
			expect(InventoryService.Client.ItemGranted).to.be.ok()
		end)

		it("grants an item once, and a second grant is a no-op, for a live player", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local InventoryService = Knit.GetService("InventoryService")

			expect(InventoryService:HasItem(player, "Kabuto")).to.equal(false)

			local firstGrant = InventoryService:GrantItem(player, "Kabuto")
			expect(firstGrant).to.equal(true)
			expect(InventoryService:HasItem(player, "Kabuto")).to.equal(true)

			local secondGrant = InventoryService:GrantItem(player, "Kabuto")
			expect(secondGrant).to.equal(false)
		end)
	end)
end
