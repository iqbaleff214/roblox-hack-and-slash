return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ShieldBearerBlock = require(ReplicatedStorage.Shared.Formulas.ShieldBearerBlock)

	describe("ShieldBearerBlock.IsBlocked", function()
		local defenderPosition = { x = 0, y = 0, z = 0 }
		local facingForward = { x = 0, y = 0, z = -1 } -- facing -Z

		it("blocks a frontal hit", function()
			local attacker = { x = 0, y = 0, z = -5 } -- in front
			expect(ShieldBearerBlock.IsBlocked(defenderPosition, facingForward, attacker)).to.equal(true)
		end)

		it("does not block a hit from directly behind", function()
			local attacker = { x = 0, y = 0, z = 5 } -- behind
			expect(ShieldBearerBlock.IsBlocked(defenderPosition, facingForward, attacker)).to.equal(false)
		end)

		it("does not block a hit from the side", function()
			local attacker = { x = 5, y = 0, z = 0 } -- directly to the side (90 degrees)
			expect(ShieldBearerBlock.IsBlocked(defenderPosition, facingForward, attacker)).to.equal(false)
		end)

		it("blocks a hit just inside the frontal arc boundary", function()
			-- 55 degrees off dead-ahead, within the 60-degree half-arc.
			local angle = math.rad(55)
			local attacker = { x = math.sin(angle) * 5, y = 0, z = -math.cos(angle) * 5 }
			expect(ShieldBearerBlock.IsBlocked(defenderPosition, facingForward, attacker)).to.equal(true)
		end)
	end)
end
