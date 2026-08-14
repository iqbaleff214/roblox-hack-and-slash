return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ProfileMigrations = require(ReplicatedStorage.Shared.Data.ProfileMigrations)
	local ProfileTemplate = require(ReplicatedStorage.Shared.Data.ProfileTemplate)

	describe("ProfileMigrations.Apply", function()
		it("migrates a version-0 fixture (missing MapStats) to the current version", function()
			local fixture = {
				version = 0,
				Level = 5,
				XP = 1000,
				SoftCurrency = 200,
				PremiumCurrency = 0,
				OwnedItems = { Katana = true },
				Loadout = { weaponId = "Katana", ultimateId = "SkyRendingBlow", accessories = {} },
				LoadoutPresets = {},
				QuestProgress = {},
				BattlePassProgress = {},
				-- MapStats intentionally omitted, as a pre-v1 profile would be.
				Settings = {},
			}

			local migrated = ProfileMigrations.Apply(fixture)

			expect(migrated.version).to.equal(ProfileMigrations.CurrentVersion)
			expect(migrated.MapStats).to.be.a("table")
			-- Fields untouched by the migration are preserved.
			expect(migrated.Level).to.equal(5)
			expect(migrated.OwnedItems.Katana).to.equal(true)
		end)

		it("is a no-op for a profile already at the current version", function()
			local fixture = table.clone(ProfileTemplate)
			local migrated = ProfileMigrations.Apply(fixture)
			expect(migrated.version).to.equal(ProfileMigrations.CurrentVersion)
		end)

		it("errors if a required migration is missing from the chain", function()
			local fixture = { version = -1 }
			expect(function()
				ProfileMigrations.Apply(fixture)
			end).to.throw()
		end)
	end)
end
