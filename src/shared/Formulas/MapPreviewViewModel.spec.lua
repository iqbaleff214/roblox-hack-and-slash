return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local MapPreviewViewModel = require(ReplicatedStorage.Shared.Formulas.MapPreviewViewModel)

	describe("MapPreviewViewModel.BuildPreview", function()
		local map = {
			id = "Okehazama",
			displayName = "Battle of Okehazama",
			recommendedLevel = 5,
			mainRewardItemId = "OniMenpo",
		}

		it("produces the expected preview fields given a resolved reward item", function()
			local rewardItem = { id = "OniMenpo", name = "Oni Menpo Mask" }
			local preview = MapPreviewViewModel.BuildPreview(map, rewardItem)

			expect(preview.mapId).to.equal("Okehazama")
			expect(preview.displayName).to.equal("Battle of Okehazama")
			expect(preview.recommendedLevel).to.equal(5)
			expect(preview.mainRewardId).to.equal("OniMenpo")
			expect(preview.mainRewardName).to.equal("Oni Menpo Mask")
		end)

		it("falls back to the raw id if the reward item couldn't be resolved", function()
			local preview = MapPreviewViewModel.BuildPreview(map, nil)
			expect(preview.mainRewardName).to.equal("OniMenpo")
		end)

		it("is data-driven — a different map's fields produce a different preview, no hardcoding", function()
			local otherMap = {
				id = "OtherMap",
				displayName = "Other Map",
				recommendedLevel = 12,
				mainRewardItemId = "Katana",
			}
			local preview = MapPreviewViewModel.BuildPreview(otherMap, { id = "Katana", name = "Katana" })
			expect(preview.mapId).to.equal("OtherMap")
			expect(preview.recommendedLevel).to.equal(12)
			expect(preview.mainRewardName).to.equal("Katana")
		end)
	end)
end
