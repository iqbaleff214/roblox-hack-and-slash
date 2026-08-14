return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Types = require(ReplicatedStorage.Shared.Types)
	local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)

	describe("WeaponDefinitions", function()
		it("validates every entry against Types.Weapon", function()
			for _, weapon in WeaponDefinitions do
				expect(function()
					Types.Weapon(weapon)
				end).never.to.throw()
			end
		end)

		it("has no duplicate ids", function()
			local seen = {}
			for _, weapon in WeaponDefinitions do
				expect(seen[weapon.id]).to.equal(nil)
				seen[weapon.id] = true
			end
		end)

		it("has all required fields present and non-empty", function()
			for _, weapon in WeaponDefinitions do
				expect(weapon.id).to.be.a("string")
				expect(weapon.name).to.be.a("string")
				expect(weapon.comboTreeId).to.be.a("string")
				expect(weapon.baseDamage > 0).to.equal(true)
			end
		end)
	end)
end
