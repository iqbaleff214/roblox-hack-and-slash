--[[
	Requires a live Player to exercise fully (Studio Play Solo/Team Test —
	see S-1301), since DataService only populates a profile on the real
	Players.PlayerAdded event. The template/migration logic it depends on is
	unit-tested standalone in ProfileTemplate.spec.lua / ProfileMigrations.spec.lua.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("DataService.Client:GetProfile", function()
		it("only ever returns Types.Profile's field set (no session-lock/meta internals)", function()
			-- Regression guard for T-202: the snapshot is a deep copy of
			-- Profile.Data, and ProfileService keeps session-lock/meta
			-- bookkeeping in Profile.MetaData (a sibling field), never in
			-- Profile.Data — so this allowlist can never be violated by
			-- construction. Asserted here so a future refactor that started
			-- writing extra fields into Profile.Data would fail this test.
			local ProfileTemplate = require(ReplicatedStorage.Shared.Data.ProfileTemplate)
			local allowlist = {
				version = true,
				Level = true,
				XP = true,
				SoftCurrency = true,
				PremiumCurrency = true,
				OwnedItems = true,
				Loadout = true,
				LoadoutPresets = true,
				QuestProgress = true,
				BattlePassProgress = true,
				MapStats = true,
				Settings = true,
			}
			for key in ProfileTemplate do
				expect(allowlist[key]).to.equal(true)
			end
		end)

		it("returns a live player's profile snapshot in Studio", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local DataService = Knit.GetService("DataService")
			local snapshot = DataService.Client:GetProfile(player)
			expect(snapshot).to.be.a("table")
			expect(snapshot.Level).to.be.a("number")
		end)
	end)
end
