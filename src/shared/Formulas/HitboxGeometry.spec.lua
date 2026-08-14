return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local HitboxGeometry = require(ReplicatedStorage.Shared.Formulas.HitboxGeometry)

	describe("HitboxGeometry.GetHitTargets", function()
		local origin = { x = 0, y = 0, z = 0 }
		local facingForward = { x = 0, y = 0, z = -1 } -- Roblox -Z is "forward" by convention

		it("hits a candidate directly in front, within radius and cone", function()
			local candidates = { { id = "InFront", position = { x = 0, y = 0, z = -5 } } }
			local hitIds = HitboxGeometry.GetHitTargets(origin, facingForward, "Arc", candidates)
			expect(#hitIds).to.equal(1)
			expect(hitIds[1]).to.equal("InFront")
		end)

		it("does not hit a candidate outside the shape's radius", function()
			local candidates = { { id = "TooFar", position = { x = 0, y = 0, z = -100 } } }
			local hitIds = HitboxGeometry.GetHitTargets(origin, facingForward, "Arc", candidates)
			expect(#hitIds).to.equal(0)
		end)

		it("does not hit a candidate behind the attacker (outside a narrow cone)", function()
			local candidates = { { id = "Behind", position = { x = 0, y = 0, z = 5 } } }
			local hitIds = HitboxGeometry.GetHitTargets(origin, facingForward, "Thrust", candidates)
			expect(#hitIds).to.equal(0)
		end)

		it("hits all-around for a full-circle shape (Slam) regardless of facing", function()
			local candidates = {
				{ id = "Front", position = { x = 0, y = 0, z = -5 } },
				{ id = "Behind", position = { x = 0, y = 0, z = 5 } },
			}
			local hitIds = HitboxGeometry.GetHitTargets(origin, facingForward, "Slam", candidates)
			expect(#hitIds).to.equal(2)
		end)

		it("returns only the correct subset when candidates are mixed in/out of range", function()
			local candidates = {
				{ id = "Close", position = { x = 0, y = 0, z = -3 } },
				{ id = "Far", position = { x = 0, y = 0, z = -50 } },
				{ id = "SideBehind", position = { x = 10, y = 0, z = 10 } },
			}
			local hitIds = HitboxGeometry.GetHitTargets(origin, facingForward, "Arc", candidates)
			expect(#hitIds).to.equal(1)
			expect(hitIds[1]).to.equal("Close")
		end)

		it("the None shape (tree root) never hits anything", function()
			local candidates = { { id = "OnTopOfOrigin", position = { x = 0, y = 0, z = 0 } } }
			local hitIds = HitboxGeometry.GetHitTargets(origin, facingForward, "None", candidates)
			expect(#hitIds).to.equal(0)
		end)
	end)

	describe("HitboxGeometry.GetHitTargetsInRadius", function()
		it("hits everything within radius regardless of direction", function()
			local origin = { x = 0, y = 0, z = 0 }
			local candidates = {
				{ id = "Front", position = { x = 0, y = 0, z = -5 } },
				{ id = "Behind", position = { x = 0, y = 0, z = 8 } },
				{ id = "TooFar", position = { x = 0, y = 0, z = 100 } },
			}
			local hitIds = HitboxGeometry.GetHitTargetsInRadius(origin, 10, candidates)
			expect(#hitIds).to.equal(2)
		end)
	end)
end
