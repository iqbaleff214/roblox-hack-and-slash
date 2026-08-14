return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ComboResolver = require(ReplicatedStorage.Shared.Formulas.ComboResolver)
	local ComboTrees = require(ReplicatedStorage.Shared.Data.ComboTrees)

	describe("ComboResolver.Resolve (Katana, sample weapon per T-104)", function()
		local root = ComboTrees.Katana.rootNodeId

		local function walk(inputs: { string }): string
			local nodeId = root
			for _, input in inputs do
				nodeId = ComboResolver.Resolve(nodeId, "Katana", input :: any)
			end
			return nodeId
		end

		it("L,L,L / L,L,H / L,H reach three distinct finisher ids", function()
			local lll = walk({ "Light", "Light", "Light" })
			local llh = walk({ "Light", "Light", "Heavy" })
			local lh = walk({ "Light", "Heavy" })

			expect(lll).to.equal("Katana_L3")
			expect(llh).to.equal("Katana_H2")
			expect(lh).to.equal("Katana_H1")
			expect(lll).never.to.equal(llh)
			expect(lll).never.to.equal(lh)
			expect(llh).never.to.equal(lh)
		end)

		it("an input with no matching branch at a finisher resets to root", function()
			local finisher = walk({ "Light", "Light", "Light" }) -- Katana_L3, both branches nil
			local afterFinisher = ComboResolver.Resolve(finisher, "Katana", "Light")
			expect(afterFinisher).to.equal(root)
		end)

		it("is deterministic for the same input", function()
			expect(walk({ "Light", "Heavy" })).to.equal(walk({ "Light", "Heavy" }))
		end)
	end)
end
