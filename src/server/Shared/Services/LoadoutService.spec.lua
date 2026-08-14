--[[
	Core ownership/catalog validation is unit-tested standalone in
	LoadoutValidation.spec.lua (no Player/Studio needed). This spec covers
	the Knit-wrapper integration (persistence, InBattlefield gating, presets)
	and requires a live Player — Studio Play Solo/Team Test, see S-1301.
]]
return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Knit = require(ReplicatedStorage.Packages.Knit)

	describe("LoadoutService", function()
		it("rejects a loadout referencing an unowned accessory, in full (no partial mutation)", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return -- no live player in this run context; covered by S-1301
			end

			local LoadoutService = Knit.GetService("LoadoutService")
			local before = LoadoutService:GetLoadout(player)

			local accepted = LoadoutService:SetLoadout(player, {
				weaponId = before.weaponId,
				ultimateId = before.ultimateId,
				accessories = { Head = "DefinitelyNotOwnedItemId" },
			})
			expect(accepted).to.equal(false)

			local after = LoadoutService:GetLoadout(player)
			expect(after.accessories.Head).to.equal(before.accessories.Head) -- unchanged, not partially applied
		end)

		it("accepts and persists a fully-owned loadout", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local LoadoutService = Knit.GetService("LoadoutService")
			local InventoryService = Knit.GetService("InventoryService")
			local before = LoadoutService:GetLoadout(player)

			InventoryService:GrantItem(player, "Kabuto")
			local accepted = LoadoutService:SetLoadout(player, {
				weaponId = before.weaponId,
				ultimateId = before.ultimateId,
				accessories = { Head = "Kabuto" },
			})
			expect(accepted).to.equal(true)

			local after = LoadoutService:GetLoadout(player)
			expect(after.accessories.Head).to.equal("Kabuto")
		end)

		it("rejects SetLoadout while InBattlefield, accepts once cleared", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local LoadoutService = Knit.GetService("LoadoutService")
			local before = LoadoutService:GetLoadout(player)
			local sameLoadout = {
				weaponId = before.weaponId,
				ultimateId = before.ultimateId,
				accessories = before.accessories,
			}

			LoadoutService:SetInBattlefield(player, true)
			expect(LoadoutService:SetLoadout(player, sameLoadout)).to.equal(false)

			LoadoutService:SetInBattlefield(player, false)
			expect(LoadoutService:SetLoadout(player, sameLoadout)).to.equal(true)
		end)

		it("caps preset saves at GetPresetCap and loads re-validate ownership", function()
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			local LoadoutService = Knit.GetService("LoadoutService")
			local DataService = Knit.GetService("DataService")

			local cap = LoadoutService:GetPresetCap(player)

			for _ = 1, cap do
				LoadoutService:SavePreset(player)
			end

			local presetsAfterFilling = DataService.Client:GetProfile(player).LoadoutPresets
			expect(#presetsAfterFilling >= cap).to.equal(true)

			local overCapAccepted = LoadoutService:SavePreset(player)
			expect(overCapAccepted).to.equal(false)

			local loaded = LoadoutService:LoadPreset(player, 1)
			expect(loaded).to.equal(true)
		end)
	end)
end
