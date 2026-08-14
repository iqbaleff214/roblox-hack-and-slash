return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CommanderAura = require(ReplicatedStorage.Shared.Formulas.CommanderAura)

	describe("CommanderAura.GetBuffedIds", function()
		local commanderPosition = { x = 0, y = 0, z = 0 }

		it("buffs candidates within radius, not candidates outside it", function()
			local candidates = {
				{ id = "InRange", position = { x = 5, y = 0, z = 0 } },
				{ id = "OutOfRange", position = { x = 50, y = 0, z = 0 } },
			}
			local buffed = CommanderAura.GetBuffedIds(commanderPosition, candidates, 10)
			expect(#buffed).to.equal(1)
			expect(buffed[1]).to.equal("InRange")
		end)

		it("includes a candidate exactly at the radius boundary", function()
			local candidates = { { id = "AtBoundary", position = { x = 10, y = 0, z = 0 } } }
			local buffed = CommanderAura.GetBuffedIds(commanderPosition, candidates, 10)
			expect(#buffed).to.equal(1)
		end)

		it("returns an empty list when no candidates are in range", function()
			local candidates = { { id = "Far", position = { x = 100, y = 0, z = 0 } } }
			expect(#CommanderAura.GetBuffedIds(commanderPosition, candidates, 10)).to.equal(0)
		end)
	end)
end
