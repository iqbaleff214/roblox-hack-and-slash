return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TargetSelect = require(ReplicatedStorage.Shared.Formulas.TargetSelect)

	describe("TargetSelect.SelectTarget", function()
		local playerPosition = { x = 0, y = 0, z = 0 }

		it("returns nil when there are no enemies", function()
			expect(TargetSelect.SelectTarget(playerPosition, {}, nil)).to.equal(nil)
		end)

		it("selects the nearest enemy", function()
			local enemies = {
				{ id = "Far", tier = "FootSoldier", position = { x = 20, y = 0, z = 0 } },
				{ id = "Near", tier = "FootSoldier", position = { x = 3, y = 0, z = 0 } },
			}
			expect(TargetSelect.SelectTarget(playerPosition, enemies, nil)).to.equal("Near")
		end)

		it("a named enemy (MidBoss/FinalBoss) always wins over a closer Foot Soldier", function()
			local enemies = {
				{ id = "CloseFootSoldier", tier = "FootSoldier", position = { x = 1, y = 0, z = 0 } },
				{ id = "FarMidBoss", tier = "MidBoss", position = { x = 30, y = 0, z = 0 } },
			}
			expect(TargetSelect.SelectTarget(playerPosition, enemies, nil)).to.equal("FarMidBoss")
		end)

		it("picks the nearest among multiple named enemies", function()
			local enemies = {
				{ id = "FarBoss", tier = "FinalBoss", position = { x = 50, y = 0, z = 0 } },
				{ id = "NearBoss", tier = "MidBoss", position = { x = 5, y = 0, z = 0 } },
			}
			expect(TargetSelect.SelectTarget(playerPosition, enemies, nil)).to.equal("NearBoss")
		end)

		it("breaks exact ties deterministically by id (no flicker) when there's no previous target", function()
			local enemies = {
				{ id = "Zeta", tier = "FootSoldier", position = { x = 5, y = 0, z = 0 } },
				{ id = "Alpha", tier = "FootSoldier", position = { x = 0, y = 5, z = 0 } },
			}
			expect(TargetSelect.SelectTarget(playerPosition, enemies, nil)).to.equal("Alpha")
		end)

		it("keeps the previous target when it's still tied for nearest (stability)", function()
			local enemies = {
				{ id = "Zeta", tier = "FootSoldier", position = { x = 5, y = 0, z = 0 } },
				{ id = "Alpha", tier = "FootSoldier", position = { x = 0, y = 5, z = 0 } },
			}
			expect(TargetSelect.SelectTarget(playerPosition, enemies, "Zeta")).to.equal("Zeta")
		end)

		it("switches off the previous target once it's no longer nearest", function()
			local enemies = {
				{ id = "Old", tier = "FootSoldier", position = { x = 30, y = 0, z = 0 } },
				{ id = "New", tier = "FootSoldier", position = { x = 2, y = 0, z = 0 } },
			}
			expect(TargetSelect.SelectTarget(playerPosition, enemies, "Old")).to.equal("New")
		end)
	end)
end
