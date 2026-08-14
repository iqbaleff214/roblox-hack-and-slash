return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Types = require(ReplicatedStorage.Shared.Types)
	local ProfileTemplate = require(ReplicatedStorage.Shared.Data.ProfileTemplate)
	local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
	local UltimateDefinitions = require(ReplicatedStorage.Shared.Data.UltimateDefinitions)

	describe("ProfileTemplate", function()
		it("validates against Types.Profile", function()
			expect(function()
				Types.Profile(ProfileTemplate)
			end).never.to.throw()
		end)

		it("defaults Level to 1 and XP/currencies to 0", function()
			expect(ProfileTemplate.Level).to.equal(1)
			expect(ProfileTemplate.XP).to.equal(0)
			expect(ProfileTemplate.SoftCurrency).to.equal(0)
			expect(ProfileTemplate.PremiumCurrency).to.equal(0)
		end)

		it("owns exactly the 0-price (starter) weapon and ultimate, nothing else", function()
			local ownedCount = 0
			for _ in ProfileTemplate.OwnedItems do
				ownedCount += 1
			end
			expect(ownedCount).to.equal(2)
		end)

		it("has a Loadout that validates against Types.Loadout and references owned items", function()
			expect(function()
				Types.Loadout(ProfileTemplate.Loadout)
			end).never.to.throw()

			expect(ProfileTemplate.OwnedItems[ProfileTemplate.Loadout.weaponId]).to.equal(true)
			expect(ProfileTemplate.OwnedItems[ProfileTemplate.Loadout.ultimateId]).to.equal(true)
		end)

		it("the starter weapon/ultimate are genuinely 0-price catalog entries", function()
			local weaponIsFree = false
			for _, weapon in WeaponDefinitions do
				if weapon.id == ProfileTemplate.Loadout.weaponId then
					weaponIsFree = weapon.price.amount == 0
				end
			end
			expect(weaponIsFree).to.equal(true)

			local ultimateIsFree = false
			for _, ultimate in UltimateDefinitions do
				if ultimate.id == ProfileTemplate.Loadout.ultimateId then
					ultimateIsFree = ultimate.price.amount == 0
				end
			end
			expect(ultimateIsFree).to.equal(true)
		end)
	end)
end
