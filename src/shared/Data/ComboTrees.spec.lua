return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ComboTrees = require(ReplicatedStorage.Shared.Data.ComboTrees)
	local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)

	local function reachableNodeIds(tree): { [string]: boolean }
		local reachable = {}
		local queue = { tree.rootNodeId }
		while #queue > 0 do
			local nodeId = table.remove(queue) :: string
			if not reachable[nodeId] then
				reachable[nodeId] = true
				local node = tree.nodes[nodeId]
				if node then
					if node.light then
						table.insert(queue, node.light)
					end
					if node.heavy then
						table.insert(queue, node.heavy)
					end
				end
			end
		end
		return reachable
	end

	describe("ComboTrees", function()
		it("has a matching tree for every WeaponDefinitions.comboTreeId", function()
			for _, weapon in WeaponDefinitions do
				expect(ComboTrees[weapon.comboTreeId]).to.be.a("table")
			end
		end)

		for weaponId, tree in ComboTrees do
			describe(weaponId, function()
				it("has a root node present in its own node table", function()
					expect(tree.nodes[tree.rootNodeId]).to.be.a("table")
				end)

				it("has no dangling light/heavy references", function()
					for _, node in tree.nodes do
						if node.light then
							expect(tree.nodes[node.light]).to.be.a("table")
						end
						if node.heavy then
							expect(tree.nodes[node.heavy]).to.be.a("table")
						end
					end
				end)

				it("has no orphaned nodes (all reachable from root)", function()
					local reachable = reachableNodeIds(tree)
					for nodeId in tree.nodes do
						expect(reachable[nodeId]).to.equal(true)
					end
				end)

				it("has at least one finisher node", function()
					local hasFinisher = false
					for _, node in tree.nodes do
						if node.isFinisher then
							hasFinisher = true
							break
						end
					end
					expect(hasFinisher).to.equal(true)
				end)
			end)
		end
	end)

	describe("ComboTrees.Katana branching (sample weapon, GDD §6.4)", function()
		local tree = ComboTrees.Katana

		local function walk(inputs: { string }): string
			local nodeId = tree.rootNodeId
			for _, input in inputs do
				local node = tree.nodes[nodeId]
				nodeId = (input == "Light" and node.light or node.heavy) :: string
			end
			return nodeId
		end

		it("L,L,L reaches a distinct finisher from L,L,H and L,H", function()
			local finisherLLL = walk({ "Light", "Light", "Light" })
			local finisherLLH = walk({ "Light", "Light", "Heavy" })
			local finisherLH = walk({ "Light", "Heavy" })

			expect(tree.nodes[finisherLLL].isFinisher).to.equal(true)
			expect(tree.nodes[finisherLLH].isFinisher).to.equal(true)
			expect(tree.nodes[finisherLH].isFinisher).to.equal(true)

			expect(finisherLLL).never.to.equal(finisherLLH)
			expect(finisherLLL).never.to.equal(finisherLH)
			expect(finisherLLH).never.to.equal(finisherLH)

			expect(finisherLLL).to.equal("Katana_L3")
			expect(finisherLLH).to.equal("Katana_H2")
			expect(finisherLH).to.equal("Katana_H1")
		end)

		it("H alone reaches its own finisher, distinct from the others", function()
			local finisherH = walk({ "Heavy" })
			expect(tree.nodes[finisherH].isFinisher).to.equal(true)
			expect(finisherH).to.equal("Katana_H0")
		end)
	end)
end
