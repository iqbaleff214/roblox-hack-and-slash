return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Types = require(ReplicatedStorage.Shared.Types)
	local ItemDefinitions = require(ReplicatedStorage.Shared.Data.ItemDefinitions)

	describe("ItemDefinitions", function()
		it("validates every entry against Types.Item", function()
			for _, item in ItemDefinitions do
				expect(function()
					Types.Item(item)
				end).never.to.throw()
			end
		end)

		it("has no duplicate ids", function()
			local seen = {}
			for _, item in ItemDefinitions do
				expect(seen[item.id]).to.equal(nil)
				seen[item.id] = true
			end
		end)

		it("only uses valid accessory slots", function()
			local validSlots = { Head = true, Body = true, Arm = true, Leg = true }
			for _, item in ItemDefinitions do
				expect(validSlots[item.slot]).to.equal(true)
			end
		end)

		it("never prices a stat-affecting item as cosmetic-exclusive without cosmeticOnly", function()
			-- Guardrail preview for T-1004: cosmetic-only items must have statBonus 0,
			-- and any item with a non-zero stat bonus must not be flagged cosmetic-only.
			for _, item in ItemDefinitions do
				if item.cosmeticOnly then
					expect(item.statBonus).to.equal(0)
				end
			end
		end)
	end)
end
