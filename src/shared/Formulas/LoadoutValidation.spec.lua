return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local LoadoutValidation = require(ReplicatedStorage.Shared.Formulas.LoadoutValidation)

	local function context(overrides: { [string]: any }?)
		local base = {
			weaponsById = { Katana = { id = "Katana" } },
			ultimatesById = { SkyRendingBlow = { id = "SkyRendingBlow" } },
			itemsById = {
				Kabuto = { id = "Kabuto", slot = "Head" },
				DoMaru = { id = "DoMaru", slot = "Body" },
			},
			ownedItemIds = { Katana = true, SkyRendingBlow = true, Kabuto = true },
		}
		if overrides then
			for key, value in overrides do
				(base :: any)[key] = value
			end
		end
		return base
	end

	local function loadout(overrides: { [string]: any }?)
		local base = {
			weaponId = "Katana",
			ultimateId = "SkyRendingBlow",
			accessories = { Head = "Kabuto" },
		}
		if overrides then
			for key, value in overrides do
				(base :: any)[key] = value
			end
		end
		return base
	end

	describe("LoadoutValidation.ValidateOwnershipAndCatalog", function()
		it("accepts a fully-owned, correctly-slotted loadout", function()
			local valid = LoadoutValidation.ValidateOwnershipAndCatalog(loadout(), context())
			expect(valid).to.equal(true)
		end)

		it("accepts a loadout with no accessories equipped", function()
			local valid = LoadoutValidation.ValidateOwnershipAndCatalog(loadout({ accessories = {} }), context())
			expect(valid).to.equal(true)
		end)

		it("rejects an unowned weapon", function()
			local valid, reason = LoadoutValidation.ValidateOwnershipAndCatalog(
				loadout(),
				context({ ownedItemIds = { SkyRendingBlow = true, Kabuto = true } })
			)
			expect(valid).to.equal(false)
			expect(reason).to.equal("UnownedWeapon")
		end)

		it("rejects an unknown weapon id (not in any catalog)", function()
			local valid, reason = LoadoutValidation.ValidateOwnershipAndCatalog(loadout({ weaponId = "GhostSword" }), context())
			expect(valid).to.equal(false)
			expect(reason).to.equal("UnknownWeapon")
		end)

		it("rejects an unowned ultimate", function()
			local valid, reason = LoadoutValidation.ValidateOwnershipAndCatalog(
				loadout(),
				context({ ownedItemIds = { Katana = true, Kabuto = true } })
			)
			expect(valid).to.equal(false)
			expect(reason).to.equal("UnownedUltimate")
		end)

		it("rejects an unowned accessory", function()
			local valid, reason = LoadoutValidation.ValidateOwnershipAndCatalog(
				loadout(),
				context({ ownedItemIds = { Katana = true, SkyRendingBlow = true } })
			)
			expect(valid).to.equal(false)
			expect(reason).to.equal("UnownedAccessory")
		end)

		it("rejects an accessory placed in the wrong slot (owned Head item slotted as Body)", function()
			local valid, reason = LoadoutValidation.ValidateOwnershipAndCatalog(
				loadout({ accessories = { Body = "Kabuto" } }),
				context({ ownedItemIds = { Katana = true, SkyRendingBlow = true, Kabuto = true } })
			)
			expect(valid).to.equal(false)
			expect(reason).to.equal("InvalidAccessorySlot")
		end)

		it("does not partially validate — the first failing check wins, no mutation implied either way", function()
			local valid1, reason1 = LoadoutValidation.ValidateOwnershipAndCatalog(loadout({ weaponId = "GhostSword" }), context())
			local valid2, reason2 = LoadoutValidation.ValidateOwnershipAndCatalog(loadout(), context())
			expect(valid1).to.equal(false)
			expect(reason1).never.to.equal(nil)
			expect(valid2).to.equal(true)
			expect(reason2).to.equal(nil)
		end)
	end)
end
