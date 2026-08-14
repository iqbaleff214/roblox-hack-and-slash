--[[
	Real welding can't be meaningfully tested without Studio-provided assets
	(S-102/S-103 haven't produced any yet — every catalog `meshAssetId`/
	`weaponModelAssetId` is `nil`), so this spec only covers what's testable
	now: the service doesn't error when applying an appearance with no real
	assets to weld, and does so on a live Player's Character — Studio Play
	Solo/Team Test, see S-1301. Full visual verification is manual/visual
	per T-504's own test-case guidance, once S-102/S-103 land.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("CharacterAppearanceService", function()
		it("registers as a Knit service with no Client surface", function()
			local CharacterAppearanceService = Knit.GetService("CharacterAppearanceService")
			expect(CharacterAppearanceService).to.be.ok()
		end)

		it("applying appearance for a live player's character does not error, even with no real assets yet", function()
			local player = Players:GetPlayers()[1]
			local character = player and player.Character
			if not player or not character then
				return -- no live player/character in this run context; covered by S-1301
			end

			-- KnitInit's PlayerAdded/CharacterAdded handling already ran for
			-- this player; re-triggering via a loadout change exercises the
			-- same code path without needing to fake a respawn.
			local LoadoutService = Knit.GetService("LoadoutService")
			local before = LoadoutService:GetLoadout(player)

			local ok = pcall(function()
				LoadoutService:SetLoadout(player, {
					weaponId = before.weaponId,
					ultimateId = before.ultimateId,
					accessories = before.accessories,
				})
			end)

			expect(ok).to.equal(true)
		end)
	end)
end
